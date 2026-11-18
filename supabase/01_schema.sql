-- =====================================================================
-- Booking system backend: Phase 1
-- Run in the Supabase SQL Editor. Safe to read top to bottom.
-- Assumes a single provider (one booking at a time). See notes at end.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Extensions
-- ---------------------------------------------------------------------
create extension if not exists btree_gist;

-- ---------------------------------------------------------------------
-- 1. Tables
-- ---------------------------------------------------------------------

-- Single-row business settings
create table public.settings (
  id                    boolean primary key default true check (id),  -- forces one row
  timezone              text    not null default 'Africa/Johannesburg',
  slot_interval_minutes int     not null default 30  check (slot_interval_minutes > 0),
  min_notice_hours      int     not null default 12  check (min_notice_hours >= 0),
  max_advance_days      int     not null default 60  check (max_advance_days > 0)
);

create table public.services (
  id               uuid primary key default gen_random_uuid(),
  name             text    not null,
  description      text,
  duration_minutes int     not null check (duration_minutes > 0),
  price            numeric(10,2) not null default 0 check (price >= 0),
  active           boolean not null default true,
  created_at       timestamptz not null default now()
);

create table public.clients (
  id         uuid primary key default gen_random_uuid(),
  full_name  text not null,
  email      text not null unique,          -- always stored lowercase (see create_booking)
  phone      text,
  notes      text,
  created_at timestamptz not null default now()
);

create table public.bookings (
  id         uuid primary key default gen_random_uuid(),
  client_id  uuid not null references public.clients(id)  on delete restrict,
  service_id uuid not null references public.services(id) on delete restrict,
  start_time timestamptz not null,
  end_time   timestamptz not null,
  status     text not null default 'pending'
             check (status in ('pending','confirmed','completed','cancelled')),
  notes      text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (end_time > start_time),

  -- Core guarantee: no two active bookings can overlap, even under concurrency.
  -- '[)' means back-to-back bookings (10:00-11:00 and 11:00-12:00) are allowed.
  constraint no_overlapping_bookings
    exclude using gist (tstzrange(start_time, end_time, '[)') with &&)
    where (status in ('pending','confirmed'))
);

create index bookings_start_time_idx on public.bookings (start_time);
create index bookings_client_id_idx  on public.bookings (client_id);

-- Weekly opening hours, local time. weekday: 0 = Sunday ... 6 = Saturday.
-- A day with no row is treated as closed.
create table public.business_hours (
  weekday    smallint primary key check (weekday between 0 and 6),
  open_time  time not null,
  close_time time not null,
  check (close_time > open_time)
);

-- Holidays, days off, appointments elsewhere, etc.
create table public.blocked_times (
  id         uuid primary key default gen_random_uuid(),
  start_time timestamptz not null,
  end_time   timestamptz not null,
  reason     text,
  check (end_time > start_time)
);

-- Who counts as an admin (Flutter app users)
create table public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

-- Keep bookings.updated_at fresh
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

create trigger bookings_set_updated_at
  before update on public.bookings
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------
-- 2. Helper: is the current user an admin?
-- ---------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

-- ---------------------------------------------------------------------
-- 3. Public function: available time slots for a service on a date
--    Returns ONLY free slots, never exposes booking data.
-- ---------------------------------------------------------------------
create or replace function public.get_available_slots(p_service_id uuid, p_date date)
returns table (slot_start timestamptz, slot_end timestamptz)
language plpgsql stable security definer set search_path = public
as $$
declare
  v_duration int;
  v_cfg      public.settings%rowtype;
  v_hours    public.business_hours%rowtype;
  v_open     timestamptz;
  v_close    timestamptz;
  v_today    date;
begin
  select s.duration_minutes into v_duration
  from public.services s
  where s.id = p_service_id and s.active;
  if not found then return; end if;

  select * into v_cfg from public.settings where id;

  -- Date limits, evaluated in the business's timezone
  v_today := (now() at time zone v_cfg.timezone)::date;
  if p_date < v_today or p_date > v_today + v_cfg.max_advance_days then
    return;
  end if;

  select * into v_hours
  from public.business_hours
  where weekday = extract(dow from p_date)::int;
  if not found then return; end if;  -- closed that day

  v_open  := (p_date + v_hours.open_time)  at time zone v_cfg.timezone;
  v_close := (p_date + v_hours.close_time) at time zone v_cfg.timezone;

  return query
  select g.s,
         g.s + make_interval(mins => v_duration)
  from generate_series(
         v_open,
         v_close - make_interval(mins => v_duration),
         make_interval(mins => v_cfg.slot_interval_minutes)
       ) as g(s)
  where g.s >= now() + make_interval(hours => v_cfg.min_notice_hours)
    and not exists (
      select 1 from public.bookings b
      where b.status in ('pending','confirmed')
        and tstzrange(b.start_time, b.end_time, '[)')
            && tstzrange(g.s, g.s + make_interval(mins => v_duration), '[)')
    )
    and not exists (
      select 1 from public.blocked_times bt
      where tstzrange(bt.start_time, bt.end_time, '[)')
            && tstzrange(g.s, g.s + make_interval(mins => v_duration), '[)')
    )
  order by g.s;
end $$;

-- ---------------------------------------------------------------------
-- 4. Public function: create a booking
--    Validates input, re-checks the slot, upserts the client, inserts.
--    The exclusion constraint is the final safety net against races.
-- ---------------------------------------------------------------------
create or replace function public.create_booking(
  p_service_id uuid,
  p_start_time timestamptz,
  p_full_name  text,
  p_email      text,
  p_phone      text default null,
  p_notes      text default null
)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  v_name     text := trim(coalesce(p_full_name, ''));
  v_email    text := lower(trim(coalesce(p_email, '')));
  v_duration int;
  v_tz       text;
  v_client   uuid;
  v_booking  uuid;
begin
  -- Input validation
  if length(v_name) < 2 or length(v_name) > 100 then
    raise exception 'invalid_name' using errcode = 'P0001';
  end if;
  if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' or length(v_email) > 254 then
    raise exception 'invalid_email' using errcode = 'P0001';
  end if;
  if length(coalesce(p_notes, '')) > 1000 or length(coalesce(p_phone, '')) > 30 then
    raise exception 'input_too_long' using errcode = 'P0001';
  end if;

  select s.duration_minutes into v_duration
  from public.services s
  where s.id = p_service_id and s.active;
  if not found then
    raise exception 'service_not_available' using errcode = 'P0001';
  end if;

  select timezone into v_tz from public.settings where id;

  -- The requested time must be a genuinely free slot
  if not exists (
    select 1
    from public.get_available_slots(p_service_id, (p_start_time at time zone v_tz)::date) a
    where a.slot_start = p_start_time
  ) then
    raise exception 'slot_unavailable' using errcode = 'P0001';
  end if;

  -- Find or create the client. Existing clients are NOT updated, so a
  -- stranger can't overwrite someone's details by booking with their email.
  insert into public.clients (full_name, email, phone)
  values (v_name, v_email, nullif(trim(p_phone), ''))
  on conflict (email) do nothing;

  select id into v_client from public.clients where email = v_email;

  begin
    insert into public.bookings (client_id, service_id, start_time, end_time, notes)
    values (v_client, p_service_id, p_start_time,
            p_start_time + make_interval(mins => v_duration),
            nullif(trim(p_notes), ''))
    returning id into v_booking;
  exception when exclusion_violation then
    -- Someone else grabbed the slot between our check and the insert
    raise exception 'slot_unavailable' using errcode = 'P0001';
  end;

  return v_booking;
end $$;

-- ---------------------------------------------------------------------
-- 5. Row Level Security
-- ---------------------------------------------------------------------
alter table public.settings       enable row level security;
alter table public.services       enable row level security;
alter table public.clients        enable row level security;
alter table public.bookings       enable row level security;
alter table public.business_hours enable row level security;
alter table public.blocked_times  enable row level security;
alter table public.admins         enable row level security;

-- Public (website) can read active services, opening hours and settings
create policy "public reads active services" on public.services
  for select to anon, authenticated using (active);
create policy "public reads business hours" on public.business_hours
  for select to anon, authenticated using (true);
create policy "public reads settings" on public.settings
  for select to anon, authenticated using (true);

-- Admins can do everything on every table
create policy "admin all services"       on public.services       for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "admin all business hours" on public.business_hours for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "admin all settings"       on public.settings       for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "admin all clients"        on public.clients        for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "admin all bookings"       on public.bookings       for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "admin all blocked times"  on public.blocked_times  for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

-- Users can see only their own row in admins (no write access via the API)
create policy "read own admin row" on public.admins
  for select to authenticated using (user_id = auth.uid());

-- Defense in depth: anonymous users get no direct access to private tables
revoke all on public.clients, public.bookings, public.blocked_times, public.admins from anon;
revoke insert, update, delete on public.services, public.business_hours, public.settings from anon;
revoke insert, update, delete on public.admins from authenticated;

-- ---------------------------------------------------------------------
-- 6. Function permissions
-- ---------------------------------------------------------------------
revoke all on function public.get_available_slots(uuid, date) from public;
revoke all on function public.create_booking(uuid, timestamptz, text, text, text, text) from public;
revoke all on function public.is_admin() from public;

grant execute on function public.get_available_slots(uuid, date) to anon, authenticated;
grant execute on function public.create_booking(uuid, timestamptz, text, text, text, text) to anon, authenticated;
grant execute on function public.is_admin() to authenticated;

-- ---------------------------------------------------------------------
-- 7. Realtime (for the Flutter admin app in Phase 3)
--    Realtime respects RLS, so only admins will receive these events.
-- ---------------------------------------------------------------------
alter publication supabase_realtime add table public.bookings;

-- ---------------------------------------------------------------------
-- 8. Seed data (edit freely)
-- ---------------------------------------------------------------------
insert into public.settings default values;

insert into public.services (name, description, duration_minutes, price) values
  ('Discovery Call',        'Free 30-minute chat about your project.',                30,    0),
  ('UI/UX Design Session',  'Wireframes and Figma screens for your app or website.',  60,  450),
  ('App Consultation',      'Architecture and tech-stack advice for your idea.',      90,  650);

-- Mon-Fri 08:00-17:00, Sat 09:00-13:00, Sunday closed
insert into public.business_hours (weekday, open_time, close_time) values
  (1, '08:00', '17:00'),
  (2, '08:00', '17:00'),
  (3, '08:00', '17:00'),
  (4, '08:00', '17:00'),
  (5, '08:00', '17:00'),
  (6, '09:00', '13:00');

-- ---------------------------------------------------------------------
-- 9. Make yourself an admin (run AFTER creating your user)
--    Dashboard > Authentication > Users > Add user, then:
-- ---------------------------------------------------------------------
-- insert into public.admins (user_id)
-- select id from auth.users where email = 'you@example.com';

-- ---------------------------------------------------------------------
-- 10. Quick tests (uncomment and run one at a time)
-- ---------------------------------------------------------------------
-- select id, name from public.services;
--
-- select * from public.get_available_slots(
--   (select id from public.services where name = 'Discovery Call'),
--   current_date + 1
-- );
--
-- select public.create_booking(
--   (select id from public.services where name = 'Discovery Call'),
--   (select slot_start from public.get_available_slots(
--      (select id from public.services where name = 'Discovery Call'), current_date + 1
--   ) limit 1),
--   'Test Client', 'test@example.com', '0821234567', 'First test booking'
-- );
--
-- -- Run the get_available_slots query again: that slot should now be gone.
-- -- Run the create_booking call twice with the same time: second call
-- -- should fail with "slot_unavailable".

-- ---------------------------------------------------------------------
-- Notes
-- * One provider assumed: any two active bookings can't overlap. For
--   multiple staff, add a staff_id column and include it in the exclusion
--   constraint: exclude using gist (staff_id with =, tstzrange(...) with &&).
-- * In Dashboard > Authentication, DISABLE public sign-ups so only users
--   you create manually can ever log in to the admin app.
-- * Consider adding CAPTCHA (e.g. Cloudflare Turnstile) on the website
--   booking form later to stop spam bookings.
-- =====================================================================

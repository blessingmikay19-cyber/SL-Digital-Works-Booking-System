-- =====================================================================
-- Phase 1 patch: align the backend with the Figma design
-- Run once in the Supabase SQL Editor, after phase1_backend.sql.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Hourly slots (the design shows 09:00, 10:00, 11:00 ...)
-- ---------------------------------------------------------------------
update public.settings set slot_interval_minutes = 60;

-- ---------------------------------------------------------------------
-- 2. Opening hours: Mon-Fri 09:00-16:00, Sat 09:00-13:00, Sun closed.
--    With hourly slots and a 12:00-13:00 lunch block, a 60-minute
--    service shows 09, 10, 11, 13, 14, 15, as in the mockups.
--    Adjust the times below if your real hours differ.
-- ---------------------------------------------------------------------
delete from public.business_hours;
insert into public.business_hours (weekday, open_time, close_time) values
  (1, '09:00', '16:00'),
  (2, '09:00', '16:00'),
  (3, '09:00', '16:00'),
  (4, '09:00', '16:00'),
  (5, '09:00', '16:00'),
  (6, '09:00', '13:00');

-- ---------------------------------------------------------------------
-- 3. Auto-confirm bookings (the design's confirmation screen says
--    "Confirmed"). Set to false in settings to require manual approval.
-- ---------------------------------------------------------------------
alter table public.settings
  add column if not exists auto_confirm boolean not null default true;

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
  v_auto     boolean;
  v_client   uuid;
  v_booking  uuid;
begin
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

  select timezone, auto_confirm into v_tz, v_auto from public.settings where id;

  if not exists (
    select 1
    from public.get_available_slots(p_service_id, (p_start_time at time zone v_tz)::date) a
    where a.slot_start = p_start_time
  ) then
    raise exception 'slot_unavailable' using errcode = 'P0001';
  end if;

  insert into public.clients (full_name, email, phone)
  values (v_name, v_email, nullif(trim(p_phone), ''))
  on conflict (email) do nothing;

  select id into v_client from public.clients where email = v_email;

  begin
    insert into public.bookings (client_id, service_id, start_time, end_time, status, notes)
    values (v_client, p_service_id, p_start_time,
            p_start_time + make_interval(mins => v_duration),
            case when v_auto then 'confirmed' else 'pending' end,
            nullif(trim(p_notes), ''))
    returning id into v_booking;
  exception when exclusion_violation then
    raise exception 'slot_unavailable' using errcode = 'P0001';
  end;

  return v_booking;
end $$;

-- ---------------------------------------------------------------------
-- 4. Lunch blocks via blocked_times
--    Creates a 'Lunch' block for each Mon-Fri over the next p_days days.
--    Safe to re-run: existing lunch blocks are skipped.
--    Edit or delete individual blocks any time (holidays, long lunches).
-- ---------------------------------------------------------------------
create or replace function public.seed_lunch_blocks(
  p_days  int  default 90,
  p_start time default '12:00',
  p_end   time default '13:00'
)
returns int
language plpgsql set search_path = public
as $$
declare
  v_tz    text;
  v_count int;
begin
  select timezone into v_tz from public.settings where id;

  insert into public.blocked_times (start_time, end_time, reason)
  select (d::date + p_start) at time zone v_tz,
         (d::date + p_end)   at time zone v_tz,
         'Lunch'
  from generate_series(
         (now() at time zone v_tz)::date::timestamp,
         (now() at time zone v_tz)::date::timestamp + make_interval(days => p_days),
         interval '1 day'
       ) as d
  where extract(dow from d) between 1 and 5
    and not exists (
      select 1 from public.blocked_times b
      where b.reason = 'Lunch'
        and b.start_time = (d::date + p_start) at time zone v_tz
    );

  get diagnostics v_count = row_count;
  return v_count;
end $$;

-- Only you (via the SQL editor) should run this
revoke all on function public.seed_lunch_blocks(int, time, time) from public, anon, authenticated;

-- Create the lunch blocks now
select public.seed_lunch_blocks(90);

-- ---------------------------------------------------------------------
-- 5. Quick checks (run one at a time)
-- ---------------------------------------------------------------------
-- Lunch blocks created (should be about 64 rows for 90 days):
-- select count(*) from public.blocked_times where reason = 'Lunch';
--
-- 60-minute service on a weekday: expect 09, 10, 11, 13, 14, 15 SAST
-- (times display in UTC: 07, 08, 09, 11, 12, 13):
-- select * from public.get_available_slots(
--   (select id from public.services where name = 'Design Consultation' or name = 'UI/UX Design Session' limit 1),
--   -- pick the next weekday date:
--   (select d::date from generate_series(current_date + 1, current_date + 7, interval '1 day') d
--    where extract(dow from d) between 1 and 5 limit 1)
-- );
--
-- 90-minute service: the 11:00 slot should NOT appear (it would run to 12:30):
-- select * from public.get_available_slots(
--   (select id from public.services where name = 'App Consultation'),
--   (select d::date from generate_series(current_date + 1, current_date + 7, interval '1 day') d
--    where extract(dow from d) between 1 and 5 limit 1)
-- );
-- =====================================================================

-- ---------------------------------------------------------------------
-- 6. Service names and prices used in the design
-- ---------------------------------------------------------------------
update public.services set name = 'Design consultation' where name = 'UI/UX Design Session';
update public.services set name = 'Project planning'    where name = 'App Consultation';
update public.services set price = 950 where name = 'Project planning';

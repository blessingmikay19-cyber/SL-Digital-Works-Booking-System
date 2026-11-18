-- =====================================================================
-- Phase 4: booking emails via a Google Apps Script relay
-- Run in the Supabase SQL Editor AFTER you have deployed email_relay.gs.
-- =====================================================================

-- 1. pg_net lets the database make HTTP requests.
--    If this line errors, enable it in Dashboard > Database > Extensions.
create extension if not exists pg_net;

-- 2. Private settings. RLS is on and there are NO policies, so the website
--    and the Flutter app can never read this table. Only the trigger
--    below (security definer) and you (SQL editor) can.
create table if not exists public.app_secrets (
  key   text primary key,
  value text not null default ''
);
alter table public.app_secrets enable row level security;
revoke all on public.app_secrets from anon, authenticated;

insert into public.app_secrets (key) values ('email_webhook_url'), ('email_webhook_secret')
on conflict (key) do nothing;

-- 3. Fill in your two values (replace the placeholders, then run):
-- update public.app_secrets set value = 'PASTE_YOUR_APPS_SCRIPT_WEB_APP_URL' where key = 'email_webhook_url';
-- update public.app_secrets set value = 'PASTE_THE_SAME_SECRET_AS_IN_APPS_SCRIPT' where key = 'email_webhook_secret';

-- 4. Trigger function: runs after every new booking.
--    It never blocks a booking: if the email call fails, the booking still saves.
create or replace function public.notify_new_booking()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  v_url     text;
  v_secret  text;
  v_tz      text;
  v_payload jsonb;
begin
  select value into v_url    from public.app_secrets where key = 'email_webhook_url';
  select value into v_secret from public.app_secrets where key = 'email_webhook_secret';
  if coalesce(v_url, '') = '' then
    return new;  -- emails not configured yet
  end if;

  select timezone into v_tz from public.settings where id;

  select jsonb_build_object(
           'secret',           v_secret,
           'booking_id',       new.id,
           'status',           new.status,
           'service',          s.name,
           'price',            s.price,
           'duration_minutes', s.duration_minutes,
           'date_label',       to_char(new.start_time at time zone v_tz, 'FMDay, FMDD FMMonth YYYY'),
           'time_label',       to_char(new.start_time at time zone v_tz, 'HH24:MI') || '–' ||
                               to_char(new.end_time   at time zone v_tz, 'HH24:MI'),
           'client_name',      c.full_name,
           'client_email',     c.email,
           'client_phone',     c.phone,
           'notes',            new.notes
         )
  into v_payload
  from public.services s, public.clients c
  where s.id = new.service_id and c.id = new.client_id;

  perform net.http_post(
    url     := v_url,
    body    := v_payload,
    headers := '{"Content-Type": "application/json"}'::jsonb
  );
  return new;
exception when others then
  return new;
end $$;

drop trigger if exists bookings_notify on public.bookings;
create trigger bookings_notify
  after insert on public.bookings
  for each row execute function public.notify_new_booking();

-- 5. Troubleshooting: the last few calls the database made.
-- select id, status_code, error_msg, created from net._http_response order by created desc limit 5;

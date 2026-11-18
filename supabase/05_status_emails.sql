-- =====================================================================
-- Phase 4b: email the client when a booking's status changes
-- Run in the Supabase SQL Editor (after phase4_email.sql).
-- Replaces the insert-only trigger with one function that handles both
-- new bookings and status changes. Your app_secrets values are kept.
-- =====================================================================

create or replace function public.notify_booking_event()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  v_url     text;
  v_secret  text;
  v_tz      text;
  v_prev    text;
  v_event   text := case when tg_op = 'INSERT' then 'created' else 'status_changed' end;
  v_payload jsonb;
begin
  select value into v_url    from public.app_secrets where key = 'email_webhook_url';
  select value into v_secret from public.app_secrets where key = 'email_webhook_secret';
  if coalesce(v_url, '') = '' then
    return new;  -- emails not configured
  end if;

  if tg_op = 'UPDATE' then
    v_prev := old.status;
  end if;

  select timezone into v_tz from public.settings where id;

  select jsonb_build_object(
           'secret',           v_secret,
           'event',            v_event,
           'previous_status',  v_prev,
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
  return new;  -- never block a booking or a status change because email failed
end $$;

drop trigger if exists bookings_notify on public.bookings;
create trigger bookings_notify
  after insert on public.bookings
  for each row execute function public.notify_booking_event();

drop trigger if exists bookings_status_notify on public.bookings;
create trigger bookings_status_notify
  after update of status on public.bookings
  for each row
  when (old.status is distinct from new.status)
  execute function public.notify_booking_event();

drop function if exists public.notify_new_booking();

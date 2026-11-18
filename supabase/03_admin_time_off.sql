-- =====================================================================
-- Phase 3 patch: let the admin app extend lunch breaks
-- Run once in the Supabase SQL Editor.
-- Same function as before, but it now checks that the caller is an
-- admin, so it is safe to expose to signed-in users.
-- =====================================================================
create or replace function public.seed_lunch_blocks(
  p_days  int  default 90,
  p_start time default '12:00',
  p_end   time default '13:00'
)
returns int
language plpgsql security definer set search_path = public
as $$
declare
  v_tz    text;
  v_count int;
begin
  if not public.is_admin() then
    raise exception 'not_admin' using errcode = '42501';
  end if;

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

revoke all on function public.seed_lunch_blocks(int, time, time) from public, anon;
grant execute on function public.seed_lunch_blocks(int, time, time) to authenticated;

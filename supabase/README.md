# Backend (Supabase)

Run the SQL files **in order** in the Supabase SQL Editor.

| File | What it does |
|---|---|
| `01_schema.sql` | Tables, overlap constraint, row level security, the two public booking functions, realtime, seed data |
| `02_design_alignment.sql` | Hourly slots, opening hours, auto-confirm, lunch-break helper, service names and prices |
| `03_admin_time_off.sql` | Lets signed-in admins call the lunch-break helper from the app |
| `04_booking_emails.sql` | Private secrets table and the trigger that calls the email relay on new bookings |
| `05_status_emails.sql` | Also emails the client when a booking is confirmed or cancelled |
| `email_relay.gs` | Google Apps Script that sends the emails from your Gmail |

## First-time setup

1. Create a Supabase project and run `01` and `02`, then `03`.
2. **Create your admin user:** Authentication, Users, Add user. Then run, with your email:
   ```sql
   insert into public.admins (user_id)
   select id from auth.users where email = 'you@example.com';
   ```
3. **Disable public sign-ups** under Authentication so only users you create can sign in.
4. Check the tests listed at the bottom of `01` and `02` return what the comments say.
5. In **Settings, API**, copy the project URL and publishable key. Never use the `service_role` key in any app.

## Emails (optional)

1. At script.google.com create a project, paste `email_relay.gs`, and add a script property `SECRET` (a long random value).
2. Run `authorize` once, then `testBooking` to preview the emails.
3. Deploy as a **Web app**: execute as **Me**, access **Anyone**. Copy the `/exec` URL. Requests without the secret are rejected.
4. Run `04` and `05`, then store the URL and secret:
   ```sql
   update public.app_secrets set value = 'YOUR_EXEC_URL' where key = 'email_webhook_url';
   update public.app_secrets set value = 'YOUR_SECRET'   where key = 'email_webhook_secret';
   ```
5. After editing the script later, redeploy with **Manage deployments, New version**.

## How availability works

`get_available_slots(service, date)` builds start times from `business_hours` at the `slot_interval_minutes` interval, then removes anything that is too soon (`min_notice_hours`), too far ahead (`max_advance_days`), overlaps an active booking, or overlaps a row in `blocked_times`. `create_booking(...)` re-checks the slot, creates or finds the client by email, and inserts the booking; the exclusion constraint is the final guard against races.

## Free-tier note

Free Supabase projects are paused after a quiet week. `.github/workflows/keepalive.yml` pings the API every two days. Add `SUPABASE_URL` and `SUPABASE_KEY` as repository secrets.

# Case study: a booking system for a freelance studio

**Role:** design, front end, back end, deployment  ·  **Stack:** Figma, HTML/CSS/JS, Flutter, Supabase (Postgres)  ·  **Status:** concept project, live demo

## The problem
Small businesses lose clients to phone tag and spreadsheets. Scheduling competes with doing the work, and clients drop off when booking takes too many steps.

## The goal
Let a client book in under a minute, and let the owner manage everything from one app. The one-minute target is a design goal I did not formally test; I verified the flow works end to end by hand.

## Process
1. **Structure first.** Wireframes for every page and every booking step, mobile first.
2. **A reusable design system.** Colour, type and spacing tokens, plus components with all their states (buttons, inputs, date chips, time slots, stepper, status badges).
3. **Mockups and states.** Mobile and desktop for each screen, including loading, empty, validation, connection error and "slot just taken".
4. **A connected prototype** in Figma to test the flow before writing code.
5. **Backend before front end.** Schema, security rules and booking functions, tested in SQL before any screen existed.
6. **Website, then the admin app,** both reading the same database.

## Key decisions
- **One page, four steps.** The booking shell keeps context while the content changes: service, date and time, details, confirmation.
- **Local time, no guessing.** Every time is labelled South Africa time (SAST), and the database does the time-zone conversion so no screen can get it wrong.
- **Recovery is part of the design.** Each failure has a visible way forward.
- **Double-booking is impossible by construction.** A Postgres exclusion constraint on time ranges guarantees it even under simultaneous requests.
- **The public site can do almost nothing.** Visitors can list services and call two functions. Bookings and clients are locked down with Row Level Security.
- **Availability is data, not code.** Hours, lunch breaks and days off are rows the owner edits from the admin app.
- **Email without a domain.** A database trigger calls a Google Apps Script that sends from Gmail. It never blocks a booking if email fails.

## Architecture
_Insert the diagram from the README (Mermaid) or a Figma version of it._

## Outcome
A working public booking site, a live-updating admin app (bookings, calendar, clients with notes, services, time off), and automatic emails to client and owner. No usage or conversion metrics have been measured.

## What I learned
- Putting rules in the database (constraints, RLS, functions) removes whole classes of bugs from the screens.
- Designing the failure states early made the build smoother, because the booking flow already had somewhere to go when things went wrong.
- Free-tier limits are part of the design: projects pause when quiet, and email has daily caps.

## Limits and next steps
Prices are not stored per booking; clients cannot yet cancel themselves; no online payment. Next: website reviews, day-before reminders, and showing time off on the calendar.

**Live website:** _link_  ·  **Admin app:** _link_  ·  **Code:** _link_  ·  **Figma:** _link_

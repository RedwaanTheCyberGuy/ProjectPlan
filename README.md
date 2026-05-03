# Beyond Code Project Plan

A polished shared planning app for Beyond Code. It keeps the original dark/light toggle, three core sections, filters and card-style plan layout, then adds Supabase Auth, database storage, RLS, realtime task updates, assignment, CRUD, notes, dashboard metrics and brand assets.

## Setup

1. Create a Supabase project.
2. In `supabase/schema.sql`, replace:
   - `redwaan@example.com` with your email
   - `partner@example.com` with your partner's email
3. Run `supabase/schema.sql` in the Supabase SQL editor.
4. In Supabase Auth, invite both users or create both users with email/password.
5. Open each invited user once so the `profiles` trigger creates their profile, then make sure their `profiles.full_name` values are `Redwaan` and `Tarik` so the owner dashboard and seed assignments line up.
6. Update `supabase-config.js` with your Supabase project URL and anon key.
7. Seed tasks:
   - easiest: open the app, sign in, press `Seed tasks`
   - SQL option: run `supabase/seed.sql` after both profiles exist

## Local preview

Open `index.html` directly in a browser. If Supabase is not configured, the app runs in local preview mode with localStorage.

## Files

- `index.html` - frontend app
- `supabase-config.js` - Supabase browser config
- `supabase/schema.sql` - tables, triggers, RLS and realtime setup
- `supabase/seed.sql` - generated default tasks
- `Beyond Code/` - copied brand logo, favicon and pattern assets

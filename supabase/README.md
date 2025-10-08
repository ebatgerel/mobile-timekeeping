# Supabase setup

This folder contains migration files to bootstrap the database schema, roles and policies for the Mobile Timekeeping app.

How to apply (using Supabase Studio):
- Open Supabase Studio > SQL Editor
- Apply files in order: 001_extensions => 010_schema => 020_indexes => 030_helpers => 040_rls

Or with Supabase CLI (recommended for CI):
- Not included here, but you can initialize Supabase locally via `supabase init` and move these migrations into the generated `supabase/migrations` folder with timestamped names.

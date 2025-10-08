-- Enable required extensions (Postgres on Supabase)
create extension if not exists "uuid-ossp";
-- Enable PostGIS from Studio > Database > Extensions (GUI). If CLI/local:
-- create extension if not exists postgis;
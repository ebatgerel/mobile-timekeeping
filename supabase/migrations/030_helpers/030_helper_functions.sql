-- Helper functions for Supabase JWT and roles

-- Current org id from JWT
create or replace function public.current_org_id()
returns uuid language sql stable as $$
  select nullif(auth.jwt() ->> 'org_id','')::uuid;
$$;

-- Check if current user is manager
create or replace function public.is_manager()
returns boolean language sql stable as $$
  select coalesce(auth.jwt() ->> 'role','') = 'manager';
$$;

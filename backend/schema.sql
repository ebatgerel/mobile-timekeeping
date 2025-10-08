-- Postgres schema for Mobile Timekeeping (Supabase friendly)
-- Enable PostGIS (if on Supabase: Database > Extensions > postgis)

create extension if not exists "uuid-ossp";

-- Organizations
create table if not exists public.organizations (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  created_at timestamptz not null default now()
);

-- Profiles: mirrors auth.users
create table if not exists public.profiles (
  id uuid primary key, -- equals auth.users.id
  org_id uuid not null references public.organizations(id) on delete cascade,
  role text not null check (role in ('manager','worker')),
  full_name text,
  phone text,
  created_at timestamptz not null default now()
);

-- Projects with geometry region (polygon)
create table if not exists public.projects (
  id uuid primary key default uuid_generate_v4(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  region geometry, -- polygon
  created_at timestamptz not null default now()
);

-- Time entries
create table if not exists public.time_entries (
  id uuid primary key default uuid_generate_v4(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  project_id uuid references public.projects(id) on delete set null,
  clock_in timestamptz,
  clock_out timestamptz,
  clock_in_loc geometry,  -- point
  clock_out_loc geometry, -- point
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  meta jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Leave requests
create table if not exists public.leave_requests (
  id uuid primary key default uuid_generate_v4(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null check (type in ('annual','sick','other')),
  period daterange not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  approver_id uuid references public.profiles(id) on delete set null,
  reason text,
  created_at timestamptz not null default now()
);

-- Chat
create table if not exists public.channels (
  id uuid primary key default uuid_generate_v4(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  type text not null check (type in ('direct','group','project')),
  name text,
  created_at timestamptz not null default now()
);

create table if not exists public.channel_members (
  channel_id uuid not null references public.channels(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  primary key (channel_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default uuid_generate_v4(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  channel_id uuid not null references public.channels(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  content text,
  files jsonb default '[]'::jsonb, -- array of storage paths
  created_at timestamptz not null default now()
);

-- Payroll/Reports
create table if not exists public.payroll_runs (
  id uuid primary key default uuid_generate_v4(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  period daterange not null,
  file_url text,
  summary jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Indexes
create index if not exists idx_time_entries_org_user_clock_in on public.time_entries(org_id, user_id, clock_in);
create index if not exists idx_time_entries_org_project_clock_in on public.time_entries(org_id, project_id, clock_in);
create index if not exists idx_messages_org_channel_created on public.messages(org_id, channel_id, created_at desc);

-- Basic RLS (policy templates). Enable RLS
alter table public.organizations enable row level security;
alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.time_entries enable row level security;
alter table public.leave_requests enable row level security;
alter table public.channels enable row level security;
alter table public.channel_members enable row level security;
alter table public.messages enable row level security;
alter table public.payroll_runs enable row level security;

-- Helper: current org id from JWT (Supabase)
create or replace function public.current_org_id()
returns uuid language sql stable as $$
  select nullif(auth.jwt() ->> 'org_id','')::uuid;
$$;

-- Policies (simplified):
-- Only access rows in same org
create policy org_isolation_select on public.profiles for select using (org_id = public.current_org_id());
create policy org_isolation_select_projects on public.projects for select using (org_id = public.current_org_id());
create policy org_isolation_select_time on public.time_entries for select using (org_id = public.current_org_id());
create policy org_isolation_select_leave on public.leave_requests for select using (org_id = public.current_org_id());
create policy org_isolation_select_channels on public.channels for select using (org_id = public.current_org_id());
create policy org_isolation_select_channel_members on public.channel_members for select using (exists(select 1 from public.channels c where c.id = channel_id and c.org_id = public.current_org_id()));
create policy org_isolation_select_messages on public.messages for select using (org_id = public.current_org_id());
create policy org_isolation_select_payroll on public.payroll_runs for select using (org_id = public.current_org_id());

-- Insert policies (workers insert own time/leave; managers broader)
create policy insert_profile_self on public.profiles for insert with check (org_id = public.current_org_id() and id = auth.uid());
create policy insert_time_self on public.time_entries for insert with check (org_id = public.current_org_id() and user_id = auth.uid());
create policy insert_leave_self on public.leave_requests for insert with check (org_id = public.current_org_id() and user_id = auth.uid());
create policy insert_messages_member on public.messages for insert with check (
  org_id = public.current_org_id() and author_id = auth.uid() and exists (
    select 1 from public.channel_members m
    where m.channel_id = messages.channel_id and m.user_id = auth.uid()
  )
);

-- Update policies (self or manager). For brevity, allow managers everywhere by claim
create or replace function public.is_manager()
returns boolean language sql stable as $$
  select coalesce(auth.jwt() ->> 'role','') = 'manager';
$$;

create policy update_time_self_or_mgr on public.time_entries for update using (
  org_id = public.current_org_id() and (user_id = auth.uid() or public.is_manager())
) with check (
  org_id = public.current_org_id() and (user_id = auth.uid() or public.is_manager())
);

create policy update_leave_self_or_mgr on public.leave_requests for update using (
  org_id = public.current_org_id() and (user_id = auth.uid() or public.is_manager())
) with check (
  org_id = public.current_org_id() and (user_id = auth.uid() or public.is_manager())
);

-- Core schema (organizations, profiles, projects, time_entries, leave_requests, channels, channel_members, messages, payroll_runs)

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
  region geometry, -- polygon (enable PostGIS)
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

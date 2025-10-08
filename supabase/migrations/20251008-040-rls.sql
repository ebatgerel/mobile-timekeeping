-- Enable RLS
alter table public.organizations enable row level security;
alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.time_entries enable row level security;
alter table public.leave_requests enable row level security;
alter table public.channels enable row level security;
alter table public.channel_members enable row level security;
alter table public.messages enable row level security;
alter table public.payroll_runs enable row level security;

-- Org isolation policies (select)
create policy org_isolation_select_profiles on public.profiles for select using (org_id = public.current_org_id());
create policy org_isolation_select_projects on public.projects for select using (org_id = public.current_org_id());
create policy org_isolation_select_time on public.time_entries for select using (org_id = public.current_org_id());
create policy org_isolation_select_leave on public.leave_requests for select using (org_id = public.current_org_id());
create policy org_isolation_select_channels on public.channels for select using (org_id = public.current_org_id());
create policy org_isolation_select_channel_members on public.channel_members for select using (
  exists(select 1 from public.channels c where c.id = channel_id and c.org_id = public.current_org_id())
);
create policy org_isolation_select_messages on public.messages for select using (org_id = public.current_org_id());
create policy org_isolation_select_payroll on public.payroll_runs for select using (org_id = public.current_org_id());

-- Insert policies
create policy insert_profile_self on public.profiles for insert with check (
  org_id = public.current_org_id() and id = auth.uid()
);

create policy insert_time_self on public.time_entries for insert with check (
  org_id = public.current_org_id() and user_id = auth.uid()
);

create policy insert_leave_self on public.leave_requests for insert with check (
  org_id = public.current_org_id() and user_id = auth.uid()
);

create policy insert_messages_member on public.messages for insert with check (
  org_id = public.current_org_id() and author_id = auth.uid() and exists (
    select 1 from public.channel_members m
    where m.channel_id = messages.channel_id and m.user_id = auth.uid()
  )
);

-- Update policies
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

-- Delete policies
create policy delete_time_mgr on public.time_entries for delete using (
  org_id = public.current_org_id() and public.is_manager()
);

create policy delete_leave_mgr on public.leave_requests for delete using (
  org_id = public.current_org_id() and public.is_manager()
);

create policy delete_messages_mgr on public.messages for delete using (
  org_id = public.current_org_id() and public.is_manager()
);

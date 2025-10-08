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

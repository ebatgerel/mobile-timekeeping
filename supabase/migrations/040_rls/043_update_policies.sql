-- Update policies (self or manager)
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

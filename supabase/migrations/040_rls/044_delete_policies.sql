-- Delete policies (managers only for critical tables)
create policy delete_time_mgr on public.time_entries for delete using (
  org_id = public.current_org_id() and public.is_manager()
);

create policy delete_leave_mgr on public.leave_requests for delete using (
  org_id = public.current_org_id() and public.is_manager()
);

create policy delete_messages_mgr on public.messages for delete using (
  org_id = public.current_org_id() and public.is_manager()
);

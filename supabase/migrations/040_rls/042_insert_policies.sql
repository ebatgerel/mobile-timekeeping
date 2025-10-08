-- Insert policies (self insert; managers broader via separate policies if needed)
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

-- Indexes
create index if not exists idx_time_entries_org_user_clock_in on public.time_entries(org_id, user_id, clock_in);
create index if not exists idx_time_entries_org_project_clock_in on public.time_entries(org_id, project_id, clock_in);
create index if not exists idx_messages_org_channel_created on public.messages(org_id, channel_id, created_at desc);

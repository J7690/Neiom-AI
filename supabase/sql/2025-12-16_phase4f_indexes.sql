-- Phase 4f – Performance indexes for routing (NON DESTRUCTIF)

create index if not exists webhook_events_channel_eventdate_idx on public.webhook_events (channel, event_date);
create index if not exists webhook_events_routed_at_idx on public.webhook_events (routed_at);

create table if not exists public.contacts (
  id uuid primary key default gen_random_uuid(),
  full_name text,
  first_name text,
  last_name text,
  whatsapp_phone text,
  email text,
  locale text,
  country text,
  tags text[] default '{}'::text[],
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists contacts_whatsapp_phone_unique
  on public.contacts (whatsapp_phone)
  where whatsapp_phone is not null;

create unique index if not exists contacts_email_unique
  on public.contacts (email)
  where email is not null;

create index if not exists contacts_created_at_idx
  on public.contacts (created_at);

create table if not exists public.contact_channels (
  id uuid primary key default gen_random_uuid(),
  contact_id uuid not null references public.contacts(id) on delete cascade,
  channel text not null check (channel in ('whatsapp','facebook','instagram','tiktok','youtube','webchat','other')),
  external_id text not null,
  display_name text,
  is_primary boolean not null default false,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create unique index if not exists contact_channels_channel_external_id_unique
  on public.contact_channels (channel, external_id);

create index if not exists contact_channels_contact_id_idx
  on public.contact_channels (contact_id);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  contact_id uuid references public.contacts(id) on delete set null,
  channel text not null check (channel in ('whatsapp','facebook','instagram','tiktok','youtube','webchat')),
  channel_conversation_id text,
  status text not null default 'open'
    check (status in ('open','pending','closed','archived')),
  subject text,
  last_message_at timestamptz,
  assigned_to text,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists conversations_contact_id_idx
  on public.conversations (contact_id);

create index if not exists conversations_channel_status_idx
  on public.conversations (channel, status);

create index if not exists conversations_last_message_at_idx
  on public.conversations (last_message_at);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  channel text not null,
  direction text not null
    check (direction in ('inbound','outbound','system')),
  message_type text not null default 'text'
    check (message_type in ('text','image','video','audio','file','event')),
  content_text text,
  media_url text,
  provider_message_id text,
  sent_at timestamptz not null default now(),
  metadata jsonb default '{}'::jsonb
);

create index if not exists messages_conversation_id_sent_at_idx
  on public.messages (conversation_id, sent_at);

create index if not exists messages_channel_sent_at_idx
  on public.messages (channel, sent_at);

create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(),
  contact_id uuid not null references public.contacts(id) on delete cascade,
  source_channel text not null
    check (source_channel in ('whatsapp','facebook','instagram','tiktok','youtube','offline','other')),
  source_conversation_id uuid references public.conversations(id) on delete set null,
  status text not null default 'new'
    check (status in ('new','contacted','qualified','won','lost','disqualified')),
  program_interest text,
  notes text,
  first_contact_at timestamptz,
  last_contact_at timestamptz,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists leads_contact_id_idx
  on public.leads (contact_id);

create index if not exists leads_status_idx
  on public.leads (status);

create index if not exists leads_source_channel_idx
  on public.leads (source_channel);

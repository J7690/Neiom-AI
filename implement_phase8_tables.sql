-- Phase 8 Tables Implementation
-- Advanced Activation & Channel Orchestration

-- 1. Activation Channels
CREATE TABLE IF NOT EXISTS studio_activation_channels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_name TEXT NOT NULL,
    channel_type TEXT NOT NULL CHECK (channel_type IN (
        'whatsapp', 'instagram', 'facebook_messenger', 'sms', 'email', 'webhook', 'other'
    )),
    provider TEXT NOT NULL DEFAULT 'meta',
    config JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_status TEXT DEFAULT 'ok',
    last_error TEXT,
    metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Activation Scenarios
CREATE TABLE IF NOT EXISTS studio_activation_scenarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scenario_name TEXT NOT NULL,
    description TEXT,
    trigger_type TEXT NOT NULL CHECK (trigger_type IN (
        'incoming_message', 'scheduled', 'manual', 'external_event'
    )),
    channel_type TEXT,
    matching_rules JSONB NOT NULL DEFAULT '{}'::jsonb,
    action_type TEXT NOT NULL CHECK (action_type IN (
        'auto_reply', 'escalate', 'multi_step', 'tag_only'
    )),
    action_config JSONB NOT NULL DEFAULT '{}'::jsonb,
    priority INTEGER NOT NULL DEFAULT 5,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    stats JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Activation Executions
CREATE TABLE IF NOT EXISTS studio_activation_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scenario_id UUID NOT NULL REFERENCES studio_activation_scenarios(id) ON DELETE CASCADE,
    channel_id UUID REFERENCES studio_activation_channels(id) ON DELETE SET NULL,
    trigger_source TEXT NOT NULL,
    trigger_type TEXT NOT NULL,
    message_id UUID,
    trigger_context JSONB NOT NULL DEFAULT '{}'::jsonb,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending', 'running', 'completed', 'failed', 'skipped'
    )),
    result JSONB NOT NULL DEFAULT '{}'::jsonb,
    error_details JSONB,
    started_at TIMESTAMPTZ DEFAULT now(),
    completed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Channel Messages Outbox
CREATE TABLE IF NOT EXISTS studio_channel_messages_outbox (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_id UUID NOT NULL REFERENCES studio_activation_channels(id) ON DELETE CASCADE,
    direction TEXT NOT NULL DEFAULT 'outbound' CHECK (direction IN ('outbound', 'inbound')),
    conversation_id UUID,
    external_recipient_id TEXT,
    message_body TEXT NOT NULL,
    template_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    send_status TEXT NOT NULL DEFAULT 'queued' CHECK (send_status IN (
        'queued', 'sending', 'sent', 'failed', 'cancelled'
    )),
    provider_message_id TEXT,
    error_code TEXT,
    error_details JSONB,
    scheduled_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 5. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_activation_channels_active
    ON studio_activation_channels(is_active) WHERE is_active = TRUE;

CREATE INDEX IF NOT EXISTS idx_activation_channels_type
    ON studio_activation_channels(channel_type);

CREATE INDEX IF NOT EXISTS idx_activation_scenarios_active
    ON studio_activation_scenarios(is_active) WHERE is_active = TRUE;

CREATE INDEX IF NOT EXISTS idx_activation_scenarios_trigger
    ON studio_activation_scenarios(trigger_type);

CREATE INDEX IF NOT EXISTS idx_activation_executions_scenario
    ON studio_activation_executions(scenario_id);

CREATE INDEX IF NOT EXISTS idx_activation_executions_status
    ON studio_activation_executions(status);

CREATE INDEX IF NOT EXISTS idx_activation_executions_message
    ON studio_activation_executions(message_id);

CREATE INDEX IF NOT EXISTS idx_channel_outbox_status
    ON studio_channel_messages_outbox(send_status);

CREATE INDEX IF NOT EXISTS idx_channel_outbox_channel
    ON studio_channel_messages_outbox(channel_id);

-- 6. Updated-at trigger function (shared)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Attach triggers
DROP TRIGGER IF EXISTS trg_activation_channels_updated_at ON studio_activation_channels;
CREATE TRIGGER trg_activation_channels_updated_at
    BEFORE UPDATE ON studio_activation_channels
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_activation_scenarios_updated_at ON studio_activation_scenarios;
CREATE TRIGGER trg_activation_scenarios_updated_at
    BEFORE UPDATE ON studio_activation_scenarios
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_activation_executions_updated_at ON studio_activation_executions;
CREATE TRIGGER trg_activation_executions_updated_at
    BEFORE UPDATE ON studio_activation_executions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_channel_outbox_updated_at ON studio_channel_messages_outbox;
CREATE TRIGGER trg_channel_outbox_updated_at
    BEFORE UPDATE ON studio_channel_messages_outbox
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 8. Enable RLS
ALTER TABLE studio_activation_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_activation_scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_activation_executions ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_channel_messages_outbox ENABLE ROW LEVEL SECURITY;

-- 9. RLS Policies
CREATE POLICY "Users can view activation channels" ON studio_activation_channels
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can manage activation channels" ON studio_activation_channels
    FOR ALL USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can view activation scenarios" ON studio_activation_scenarios
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can manage activation scenarios" ON studio_activation_scenarios
    FOR ALL USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can view activation executions" ON studio_activation_executions
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can manage activation executions" ON studio_activation_executions
    FOR ALL USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can view channel outbox" ON studio_channel_messages_outbox
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can manage channel outbox" ON studio_channel_messages_outbox
    FOR ALL USING (auth.uid() IS NOT NULL);

-- 10. Grants
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_activation_channels TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_activation_scenarios TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_activation_executions TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_channel_messages_outbox TO authenticated, anon;

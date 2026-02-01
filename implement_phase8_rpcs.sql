-- Phase 8 RPC Functions Implementation
-- Advanced Activation & Channel Orchestration

-- 1. Create Activation Channel
CREATE OR REPLACE FUNCTION public.create_activation_channel(
    p_channel_name TEXT,
    p_channel_type TEXT,
    p_provider TEXT,
    p_config JSONB DEFAULT '{}'::jsonb
)
RETURNS studio_activation_channels
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS
$$
DECLARE
    v_channel_id UUID;
BEGIN
    IF p_channel_name IS NULL OR p_channel_name = '' THEN
        RAISE EXCEPTION 'channel_name is required';
    END IF;

    IF p_channel_type NOT IN ('whatsapp','instagram','facebook_messenger','sms','email','webhook','other') THEN
        RAISE EXCEPTION 'Invalid channel_type: %', p_channel_type;
    END IF;

    INSERT INTO studio_activation_channels (
        channel_name,
        channel_type,
        provider,
        config
    ) VALUES (
        p_channel_name,
        p_channel_type,
        p_provider,
        COALESCE(p_config, '{}'::jsonb)
    ) RETURNING id INTO v_channel_id;

    RETURN (
        SELECT c FROM studio_activation_channels c WHERE c.id = v_channel_id
    );
END;
$$;

-- 2. Create Activation Scenario
CREATE OR REPLACE FUNCTION public.create_activation_scenario(
    p_scenario_name TEXT,
    p_description TEXT,
    p_trigger_type TEXT,
    p_channel_type TEXT,
    p_matching_rules JSONB DEFAULT '{}'::jsonb,
    p_action_type TEXT,
    p_action_config JSONB DEFAULT '{}'::jsonb,
    p_priority INTEGER DEFAULT 5
)
RETURNS studio_activation_scenarios
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS
$$
DECLARE
    v_scenario_id UUID;
BEGIN
    IF p_scenario_name IS NULL OR p_scenario_name = '' THEN
        RAISE EXCEPTION 'scenario_name is required';
    END IF;

    IF p_trigger_type NOT IN ('incoming_message','scheduled','manual','external_event') THEN
        RAISE EXCEPTION 'Invalid trigger_type: %', p_trigger_type;
    END IF;

    IF p_action_type NOT IN ('auto_reply','escalate','multi_step','tag_only') THEN
        RAISE EXCEPTION 'Invalid action_type: %', p_action_type;
    END IF;

    INSERT INTO studio_activation_scenarios (
        scenario_name,
        description,
        trigger_type,
        channel_type,
        matching_rules,
        action_type,
        action_config,
        priority
    ) VALUES (
        p_scenario_name,
        p_description,
        p_trigger_type,
        p_channel_type,
        COALESCE(p_matching_rules, '{}'::jsonb),
        p_action_type,
        COALESCE(p_action_config, '{}'::jsonb),
        COALESCE(p_priority, 5)
    ) RETURNING id INTO v_scenario_id;

    RETURN (
        SELECT s FROM studio_activation_scenarios s WHERE s.id = v_scenario_id
    );
END;
$$;

-- 3. Enqueue Channel Message (Outbox)
CREATE OR REPLACE FUNCTION public.enqueue_channel_message(
    p_channel_id UUID,
    p_external_recipient_id TEXT,
    p_message_body TEXT,
    p_template_data JSONB DEFAULT '{}'::jsonb,
    p_conversation_id UUID DEFAULT NULL
)
RETURNS studio_channel_messages_outbox
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS
$$
DECLARE
    v_message_id UUID;
BEGIN
    IF p_channel_id IS NULL THEN
        RAISE EXCEPTION 'channel_id is required';
    END IF;

    IF p_message_body IS NULL OR p_message_body = '' THEN
        RAISE EXCEPTION 'message_body is required';
    END IF;

    INSERT INTO studio_channel_messages_outbox (
        channel_id,
        direction,
        conversation_id,
        external_recipient_id,
        message_body,
        template_data,
        send_status,
        scheduled_at
    ) VALUES (
        p_channel_id,
        'outbound',
        p_conversation_id,
        p_external_recipient_id,
        p_message_body,
        COALESCE(p_template_data, '{}'::jsonb),
        'queued',
        now()
    ) RETURNING id INTO v_message_id;

    RETURN (
        SELECT m FROM studio_channel_messages_outbox m WHERE m.id = v_message_id
    );
END;
$$;

-- 4. Run Activation Scenario on Message
CREATE OR REPLACE FUNCTION public.run_activation_scenario_on_message(
    p_scenario_id UUID,
    p_message_id UUID,
    p_channel_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS
$$
DECLARE
    v_scenario studio_activation_scenarios%ROWTYPE;
    v_channel studio_activation_channels%ROWTYPE;
    v_msg RECORD;
    v_analysis RECORD;
    v_execution_id UUID;
    v_outbox_id UUID;
    v_should_execute BOOLEAN := TRUE;
    v_result JSONB;
    v_reply_text TEXT;
    v_auto_reply_message_id UUID;
    v_has_auto_reply_stub BOOLEAN := FALSE;
BEGIN
    -- Load scenario
    SELECT * INTO v_scenario
    FROM studio_activation_scenarios
    WHERE id = p_scenario_id AND is_active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Activation scenario not found or inactive: %', p_scenario_id;
    END IF;

    -- Optional channel
    IF p_channel_id IS NOT NULL THEN
        SELECT * INTO v_channel
        FROM studio_activation_channels
        WHERE id = p_channel_id;
    END IF;

    -- Load base message & analysis if available
    SELECT m.id, m.conversation_id, m.content_text
    INTO v_msg
    FROM public.messages m
    WHERE m.id = p_message_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Message not found: %', p_message_id;
    END IF;

    BEGIN
        SELECT ma.intent, ma.sentiment, ma.needs_escalation
        INTO v_analysis
        FROM public.message_analysis ma
        WHERE ma.message_id = p_message_id
        LIMIT 1;
    EXCEPTION WHEN undefined_table THEN
        v_analysis := NULL;
    END;

    -- Simple matching rules evaluation (optional)
    IF v_scenario.matching_rules ? 'require_escalation' THEN
        IF v_analysis IS NULL OR NOT COALESCE((v_analysis).needs_escalation, FALSE) THEN
            v_should_execute := FALSE;
        END IF;
    END IF;

    IF v_scenario.matching_rules ? 'allowed_intents' AND v_analysis IS NOT NULL THEN
        IF (v_analysis).intent IS NOT NULL THEN
            IF NOT ((v_scenario.matching_rules->'allowed_intents') ? (v_analysis).intent) THEN
                v_should_execute := FALSE;
            END IF;
        END IF;
    END IF;

    -- Create execution record
    INSERT INTO studio_activation_executions (
        scenario_id,
        channel_id,
        trigger_source,
        trigger_type,
        message_id,
        trigger_context,
        status,
        result,
        started_at
    ) VALUES (
        p_scenario_id,
        p_channel_id,
        COALESCE(v_scenario.channel_type, 'generic'),
        v_scenario.trigger_type,
        p_message_id,
        jsonb_build_object(
            'message_id', p_message_id,
            'conversation_id', v_msg.conversation_id,
            'analysis', to_jsonb(v_analysis),
            'matching_rules', v_scenario.matching_rules
        ),
        CASE WHEN v_should_execute THEN 'running' ELSE 'skipped' END,
        '{}'::jsonb,
        now()
    ) RETURNING id INTO v_execution_id;

    IF NOT v_should_execute THEN
        UPDATE studio_activation_executions
        SET status = 'skipped',
            result = jsonb_build_object(
                'executed', FALSE,
                'reason', 'matching_rules_not_satisfied'
            ),
            completed_at = now(),
            updated_at = now()
        WHERE id = v_execution_id;

        RETURN jsonb_build_object(
            'execution_id', v_execution_id,
            'executed', FALSE,
            'reason', 'matching_rules_not_satisfied'
        );
    END IF;

    -- Optional auto-reply using existing stub if present
    SELECT EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
          AND p.proname = 'auto_reply_stub'
    ) INTO v_has_auto_reply_stub;

    IF v_scenario.action_type = 'auto_reply' AND v_has_auto_reply_stub THEN
        BEGIN
            EXECUTE 'SELECT public.auto_reply_stub($1)' INTO v_auto_reply_message_id USING p_message_id;
            v_reply_text := public.ai_reply_template(p_message_id);
        EXCEPTION WHEN OTHERS THEN
            v_auto_reply_message_id := NULL;
            v_reply_text := NULL;
        END;
    END IF;

    -- Enqueue channel message if channel is provided
    IF p_channel_id IS NOT NULL AND v_scenario.action_type IN ('auto_reply','multi_step') THEN
        v_reply_text := COALESCE(
            v_reply_text,
            COALESCE(v_scenario.action_config->>'fallback_message', 'Merci pour votre message.')
        );

        INSERT INTO studio_channel_messages_outbox (
            channel_id,
            direction,
            conversation_id,
            external_recipient_id,
            message_body,
            template_data,
            send_status,
            scheduled_at
        ) VALUES (
            p_channel_id,
            'outbound',
            v_msg.conversation_id,
            NULL,
            v_reply_text,
            jsonb_build_object(
                'scenario_id', p_scenario_id,
                'message_id', p_message_id
            ),
            'queued',
            now()
        ) RETURNING id INTO v_outbox_id;
    END IF;

    v_result := jsonb_build_object(
        'execution_id', v_execution_id,
        'scenario_id', p_scenario_id,
        'channel_id', p_channel_id,
        'message_id', p_message_id,
        'auto_reply_message_id', v_auto_reply_message_id,
        'outbox_id', v_outbox_id,
        'executed', TRUE,
        'action_type', v_scenario.action_type
    );

    UPDATE studio_activation_executions
    SET status = 'completed',
        result = v_result,
        completed_at = now(),
        updated_at = now()
    WHERE id = v_execution_id;

    RETURN v_result;
END;
$$;

-- 5. Activation Dashboard
CREATE OR REPLACE FUNCTION public.get_activation_dashboard()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS
$$
DECLARE
    v_result JSONB;
    v_channels INTEGER;
    v_active_channels INTEGER;
    v_scenarios INTEGER;
    v_active_scenarios INTEGER;
    v_executions_total INTEGER;
    v_executions_last_24h INTEGER;
    v_outbox_queued INTEGER;
    v_outbox_failed INTEGER;
    v_messages_last_24h INTEGER;
    v_auto_reply_functions INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_channels FROM studio_activation_channels;
    SELECT COUNT(*) INTO v_active_channels FROM studio_activation_channels WHERE is_active = TRUE;

    SELECT COUNT(*) INTO v_scenarios FROM studio_activation_scenarios;
    SELECT COUNT(*) INTO v_active_scenarios FROM studio_activation_scenarios WHERE is_active = TRUE;

    SELECT COUNT(*) INTO v_executions_total FROM studio_activation_executions;
    SELECT COUNT(*) INTO v_executions_last_24h
    FROM studio_activation_executions
    WHERE started_at >= now() - INTERVAL '24 hours';

    SELECT COUNT(*) INTO v_outbox_queued
    FROM studio_channel_messages_outbox
    WHERE send_status = 'queued';

    SELECT COUNT(*) INTO v_outbox_failed
    FROM studio_channel_messages_outbox
    WHERE send_status = 'failed';

    BEGIN
        SELECT COUNT(*) INTO v_messages_last_24h
        FROM public.messages
        WHERE created_at >= now() - INTERVAL '24 hours';
    EXCEPTION WHEN undefined_column OR undefined_table THEN
        v_messages_last_24h := 0;
    END;

    SELECT COUNT(*) INTO v_auto_reply_functions
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
      AND p.proname IN ('ingest_instagram_webhook','ai_reply_template','auto_reply_stub');

    v_result := jsonb_build_object(
        'summary', jsonb_build_object(
            'channels_total', v_channels,
            'channels_active', v_active_channels,
            'scenarios_total', v_scenarios,
            'scenarios_active', v_active_scenarios,
            'executions_total', v_executions_total,
            'executions_last_24h', v_executions_last_24h,
            'outbox_queued', v_outbox_queued,
            'outbox_failed', v_outbox_failed,
            'messages_last_24h', v_messages_last_24h
        ),
        'functions', jsonb_build_object(
            'ai_reply_related_functions', v_auto_reply_functions
        )
    );

    RETURN v_result;
END;
$$;

-- Grants for RPCs
GRANT EXECUTE ON FUNCTION public.create_activation_channel(TEXT, TEXT, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_activation_scenario(TEXT, TEXT, TEXT, TEXT, JSONB, TEXT, JSONB, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.enqueue_channel_message(UUID, TEXT, TEXT, JSONB, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.run_activation_scenario_on_message(UUID, UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_activation_dashboard() TO authenticated;

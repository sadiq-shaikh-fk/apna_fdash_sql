-- =================================================================================================================
-- ******************************************** EMAIL TEMPLATES SYSTEM *********************************************
-- =================================================================================================================

---------- table email_templates ----------
CREATE TYPE template_type_enum AS ENUM ('system', 'user_custom');
CREATE TYPE template_category_enum AS ENUM (
  'onboarding', 'terms_conditions', 'script_request', 'script_approval', 'script_rejection',
  'assets_request', 'assets_approval', 'assets_rejection', 
  'deliverable_request', 'deliverable_approval', 'deliverable_rejection',
  'live_link_request', 'insights_request', 'payment_notification',
  'campaign_completion', 'reminder', 'general', 'custom'
);

CREATE TABLE email_templates (
  et_id BIGSERIAL PRIMARY KEY,
  et_name VARCHAR(255) NOT NULL,                    -- 'Onboarding Welcome Email', 'Script Approval Notice'
  et_type template_type_enum NOT NULL DEFAULT 'user_custom',
  et_category template_category_enum NOT NULL,
  et_subject VARCHAR(500) NOT NULL,                 -- Email subject line with variables
  et_body TEXT NOT NULL,                            -- Email body with variables
  et_variables JSONB,                               -- Available variables for this template
  et_is_active BOOLEAN NOT NULL DEFAULT true,
  et_is_default BOOLEAN NOT NULL DEFAULT false,    -- Default template for this category
  et_description TEXT,                              -- What this template is used for
  et_created_by_user_id INTEGER,                    -- NULL for system templates
  et_t_id INTEGER,                                  -- NULL for system templates, tenant-specific for user templates
  
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- soft delete
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by VARCHAR(100),
  
  -- Foreign key constraints
  CONSTRAINT fk_email_templates_created_by FOREIGN KEY (et_created_by_user_id) REFERENCES users(u_id) ON DELETE RESTRICT,
  CONSTRAINT fk_email_templates_tenant FOREIGN KEY (et_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,
  
  -- constraints
  CONSTRAINT uk_template_name_per_tenant UNIQUE (et_name, et_t_id),
  CONSTRAINT chk_system_templates_no_tenant CHECK (
    (et_type = 'system' AND et_t_id IS NULL AND et_created_by_user_id IS NULL) OR 
    (et_type = 'user_custom' AND et_t_id IS NOT NULL AND et_created_by_user_id IS NOT NULL)
  ),
  CONSTRAINT chk_one_default_per_category_tenant UNIQUE (et_category, et_t_id, et_is_default) DEFERRABLE INITIALLY DEFERRED
);

---------- table email_template_versions ----------
CREATE TABLE email_template_versions (
  etv_id BIGSERIAL PRIMARY KEY,
  etv_et_id INTEGER NOT NULL,                      -- foreign key to email_templates
  etv_version_number INTEGER NOT NULL DEFAULT 1,
  etv_subject VARCHAR(500) NOT NULL,
  etv_body TEXT NOT NULL,
  etv_variables JSONB,
  etv_is_current BOOLEAN NOT NULL DEFAULT false,
  etv_change_notes TEXT,                           -- What changed in this version
  etv_created_by_user_id INTEGER,
  
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- soft delete
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by VARCHAR(100),
  
  -- Foreign key constraints
  CONSTRAINT fk_email_template_versions_template FOREIGN KEY (etv_et_id) REFERENCES email_templates(et_id) ON DELETE RESTRICT,
  CONSTRAINT fk_email_template_versions_created_by FOREIGN KEY (etv_created_by_user_id) REFERENCES users(u_id) ON DELETE RESTRICT,
  
  -- constraints
  CONSTRAINT uk_template_version UNIQUE (etv_et_id, etv_version_number),
  CONSTRAINT chk_one_current_version_per_template UNIQUE (etv_et_id, etv_is_current) DEFERRABLE INITIALLY DEFERRED
);

---------- table email_logs ----------
CREATE TYPE email_status_enum AS ENUM ('queued', 'sent', 'delivered', 'opened', 'clicked', 'bounced', 'failed', 'spam');

CREATE TABLE email_logs (
  el_id BIGSERIAL PRIMARY KEY,
  el_et_id INTEGER,                                -- foreign key to email_templates (nullable for non-template emails)
  el_etv_id INTEGER,                               -- foreign key to email_template_versions used
  el_dp_id INTEGER,                                -- foreign key to deliverable_proposals (if related to workflow)
  el_recipient_email VARCHAR(255) NOT NULL,
  el_recipient_name VARCHAR(255),
  el_sender_email VARCHAR(255) NOT NULL,
  el_sender_name VARCHAR(255),
  el_subject VARCHAR(500) NOT NULL,               -- Final subject after variable substitution
  el_body TEXT NOT NULL,                          -- Final body after variable substitution
  el_variables_used JSONB,                        -- Variables and their values used
  el_status email_status_enum NOT NULL DEFAULT 'queued',
  el_gateway VARCHAR(50),                         -- 'sendgrid', 'mailgun', 'ses', etc.
  el_gateway_message_id VARCHAR(255),            -- Gateway's message ID for tracking
  el_sent_at TIMESTAMP WITH TIME ZONE,
  el_delivered_at TIMESTAMP WITH TIME ZONE,
  el_opened_at TIMESTAMP WITH TIME ZONE,
  el_clicked_at TIMESTAMP WITH TIME ZONE,
  el_error_message TEXT,                          -- Error details if failed
  el_t_id INTEGER NOT NULL,
  
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- soft delete
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by VARCHAR(100),
  
  -- Foreign key constraints
  CONSTRAINT fk_email_logs_template FOREIGN KEY (el_et_id) REFERENCES email_templates(et_id) ON DELETE RESTRICT,
  CONSTRAINT fk_email_logs_template_version FOREIGN KEY (el_etv_id) REFERENCES email_template_versions(etv_id) ON DELETE RESTRICT,
  CONSTRAINT fk_email_logs_deliverable FOREIGN KEY (el_dp_id) REFERENCES deliverable_proposals(dp_id) ON DELETE RESTRICT,
  CONSTRAINT fk_email_logs_tenant FOREIGN KEY (el_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

-- =================================================================================================================
-- ********************************************* SAMPLE SYSTEM TEMPLATES *****************************************
-- =================================================================================================================

---------- Insert system email templates ----------
-- Onboarding Templates
INSERT INTO email_templates (et_name, et_type, et_category, et_subject, et_body, et_variables, et_is_default, et_description) VALUES
('Default Onboarding Email', 'system', 'onboarding', 
'Welcome to {{campaign_name}} - Action Required', 
'Hi {{influencer_name}},

We''re excited to invite you to participate in our {{campaign_name}} campaign for {{brand_name}}!

Campaign Details:
- Campaign: {{campaign_name}}
- Brand: {{brand_name}}
- Deliverable: {{deliverable_type}} on {{platform_name}}
- Compensation: {{agreed_price}}
- Go Live Date: {{live_date}}

To get started, please:
1. Reply to confirm your participation
2. Review the attached brand guidelines
3. Complete your onboarding information

If you have any questions, feel free to reach out!

Best regards,
{{agency_name}} Team

---
This email was sent regarding your proposal for {{campaign_name}}.', 
'{"influencer_name": "Influencer Name", "campaign_name": "Campaign Name", "brand_name": "Brand Name", "deliverable_type": "Instagram Reel", "platform_name": "Instagram", "agreed_price": "₹50,000", "live_date": "2025-07-15", "agency_name": "Fame Keeda"}', 
true, 'Default template for influencer onboarding'),

('Default Terms & Conditions Email', 'system', 'terms_conditions',
'{{campaign_name}} - Terms & Conditions for Review',
'Hi {{influencer_name}},

Thank you for confirming your participation in {{campaign_name}}!

Please review the attached Terms & Conditions document for this collaboration. The key points include:

- Content guidelines and brand requirements
- Payment terms and schedule  
- Posting deadlines and approval process
- Usage rights and exclusivity clauses

Please reply to this email confirming your acceptance of these terms so we can proceed to the next step.

Campaign Timeline:
- Script Submission: {{script_deadline}}
- Content Creation: {{production_deadline}}
- Go Live: {{live_date}}

Best regards,
{{agency_name}} Team',
'{"influencer_name": "Influencer Name", "campaign_name": "Campaign Name", "script_deadline": "2025-07-01", "production_deadline": "2025-07-10", "live_date": "2025-07-15", "agency_name": "Fame Keeda"}',
true, 'Default terms and conditions email'),

('Default Script Request Email', 'system', 'script_request',
'{{campaign_name}} - Script Submission Required',
'Hi {{influencer_name}},

Great news! The terms have been finalized for {{campaign_name}}.

Next step: Please submit your content script/outline for approval.

What to include:
- Hook/Opening (first 3 seconds)
- Key talking points about {{brand_name}}
- Call-to-action
- Estimated video length: {{estimated_duration}}

Please submit your script by {{script_deadline}} so we have enough time for review and revisions if needed.

Upload your script here: {{upload_link}}

Looking forward to your creative ideas!

Best regards,
{{agency_name}} Team',
'{"influencer_name": "Influencer Name", "campaign_name": "Campaign Name", "brand_name": "Brand Name", "estimated_duration": "60 seconds", "script_deadline": "2025-07-01", "upload_link": "https://app.famekeeda.com/upload/script", "agency_name": "Fame Keeda"}',
true, 'Default script request email'),

('Default Script Approval Email', 'system', 'script_approval',
'✅ Script Approved - {{campaign_name}}',
'Hi {{influencer_name}},

Excellent work! Your script for {{campaign_name}} has been approved by {{brand_name}}.

{{approval_notes}}

Next Steps:
1. We''ll send you the brand assets and guidelines
2. Begin content creation
3. Submit final content by {{production_deadline}}

Keep up the great work!

Best regards,
{{agency_name}} Team',
'{"influencer_name": "Influencer Name", "campaign_name": "Campaign Name", "brand_name": "Brand Name", "approval_notes": "The brand loves your creative approach!", "production_deadline": "2025-07-10", "agency_name": "Fame Keeda"}',
true, 'Default script approval notification'),

('Default Reminder Email', 'system', 'reminder',
'Reminder: {{action_required}} - {{campaign_name}}',
'Hi {{influencer_name}},

This is a friendly reminder about {{campaign_name}}.

Action Required: {{action_required}}
Deadline: {{deadline}}

{{reminder_message}}

If you need any assistance or have questions, please don''t hesitate to reach out.

Best regards,
{{agency_name}} Team',
'{"influencer_name": "Influencer Name", "campaign_name": "Campaign Name", "action_required": "Script Submission", "deadline": "2025-07-01", "reminder_message": "Please submit your script so we can proceed with the approval process.", "agency_name": "Fame Keeda"}',
true, 'Default reminder email for any pending action');

-- =================================================================================================================
-- ********************************************* EMAIL TEMPLATE TRIGGERS *****************************************
-- =================================================================================================================

---------- Trigger to create initial version when template is created ----------
CREATE OR REPLACE FUNCTION trg_create_initial_template_version()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO email_template_versions (
    etv_et_id, etv_version_number, etv_subject, etv_body, 
    etv_variables, etv_is_current, etv_change_notes, etv_created_by_user_id
  ) VALUES (
    NEW.et_id, 1, NEW.et_subject, NEW.et_body, 
    NEW.et_variables, true, 'Initial version', NEW.et_created_by_user_id
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_email_template_initial_version
AFTER INSERT ON email_templates
FOR EACH ROW
EXECUTE FUNCTION trg_create_initial_template_version();

---------- Trigger to create new version when template is updated ----------
CREATE OR REPLACE FUNCTION trg_create_new_template_version()
RETURNS TRIGGER AS $$
DECLARE
  next_version INTEGER;
BEGIN
  -- Only create new version if subject or body changed
  IF OLD.et_subject != NEW.et_subject OR OLD.et_body != NEW.et_body OR OLD.et_variables::text != NEW.et_variables::text THEN
    
    -- Get next version number
    SELECT COALESCE(MAX(etv_version_number), 0) + 1 INTO next_version
    FROM email_template_versions WHERE etv_et_id = NEW.et_id;
    
    -- Mark previous version as not current
    UPDATE email_template_versions 
    SET etv_is_current = false 
    WHERE etv_et_id = NEW.et_id;
    
    -- Create new version
    INSERT INTO email_template_versions (
      etv_et_id, etv_version_number, etv_subject, etv_body, 
      etv_variables, etv_is_current, etv_change_notes, etv_created_by_user_id
    ) VALUES (
      NEW.et_id, next_version, NEW.et_subject, NEW.et_body, 
      NEW.et_variables, true, 'Template updated', NEW.et_created_by_user_id
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_email_template_version_update
AFTER UPDATE ON email_templates
FOR EACH ROW
EXECUTE FUNCTION trg_create_new_template_version();

-- =================================================================================================================
-- ********************************************* HELPER FUNCTIONS **************************************************
-- =================================================================================================================

---------- Function to get template for sending email ----------
CREATE OR REPLACE FUNCTION get_email_template(
  p_category template_category_enum,
  p_tenant_id INTEGER DEFAULT NULL
) RETURNS TABLE (
  template_id INTEGER,
  template_name VARCHAR(255),
  subject VARCHAR(500),
  body TEXT,
  variables JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    et.et_id,
    et.et_name,
    etv.etv_subject,
    etv.etv_body,
    etv.etv_variables
  FROM email_templates et
  JOIN email_template_versions etv ON et.et_id = etv.etv_et_id AND etv.etv_is_current = true
  WHERE et.et_category = p_category 
    AND et.et_is_active = true
    AND et.is_deleted = false
    AND (
      -- User's custom template for this tenant
      (et.et_type = 'user_custom' AND et.et_t_id = p_tenant_id) OR
      -- System template (fallback)
      (et.et_type = 'system' AND et.et_t_id IS NULL)
    )
  ORDER BY 
    et.et_type DESC, -- user_custom first, then system
    et.et_is_default DESC, -- default templates first
    et.created_at DESC -- newest first
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- =================================================================================================================
-- ********************************************* USAGE EXAMPLES ****************************************************
-- =================================================================================================================

/*
-- Example 1: Get onboarding template for tenant 1
SELECT * FROM get_email_template('onboarding', 1);

-- Example 2: Create custom template for a tenant
INSERT INTO email_templates (
  et_name, et_type, et_category, et_subject, et_body, 
  et_variables, et_created_by_user_id, et_t_id
) VALUES (
  'Custom Onboarding - Fame Keeda Style', 'user_custom', 'onboarding',
  '🎬 You''re IN! {{campaign_name}} Collaboration',
  'Hey {{influencer_name}}! 🎉
  
  This is going to be EPIC! Welcome to {{campaign_name}}...
  
  [Custom branded content here]',
  '{"influencer_name": "Creator Name", "campaign_name": "Campaign Name"}',
  15, 1
);

-- Example 3: Log email sending
INSERT INTO email_logs (
  el_et_id, el_etv_id, el_dp_id, el_recipient_email, el_recipient_name,
  el_sender_email, el_subject, el_body, el_variables_used, el_t_id
) VALUES (
  1, 1, 123, 'tanmay@example.com', 'Tanmay Bhat',
  'campaigns@famekeeda.com', 
  'Welcome to Nike Air Max Campaign - Action Required',
  '[Email body with variables substituted]',
  '{"influencer_name": "Tanmay Bhat", "campaign_name": "Nike Air Max Campaign", "brand_name": "Nike"}',
  1
);

-- Example 4: Update email delivery status
UPDATE email_logs 
SET el_status = 'delivered', el_delivered_at = NOW() 
WHERE el_gateway_message_id = 'msg_abc123';
*/

-- =================================================================================================================
-- ********************************************* INTEGRATION WITH WORKFLOW ***************************************
-- =================================================================================================================

---------- Add template reference to deliverable activity ----------
ALTER TABLE deliverable_proposals_activity 
ADD COLUMN dpa_email_template_id INTEGER,
ADD COLUMN dpa_email_log_id INTEGER,
ADD CONSTRAINT fk_deliverable_activity_email_template FOREIGN KEY (dpa_email_template_id) REFERENCES email_templates(et_id) ON DELETE RESTRICT,
ADD CONSTRAINT fk_deliverable_activity_email_log FOREIGN KEY (dpa_email_log_id) REFERENCES email_logs(el_id) ON DELETE RESTRICT;
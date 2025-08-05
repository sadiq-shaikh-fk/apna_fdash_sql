-- =================================================================================================================
-- *************************************************** TRIGGERS ****************************************************
-- =================================================================================================================

-- ========== Trigger to insert into tenants before adding brands ==========
---------- trigger function ----------
CREATE OR REPLACE FUNCTION trg_auto_create_tenant_for_brand()
RETURNS TRIGGER AS $$
DECLARE
    new_tenant_id INTEGER;
    agency_tenant_id INTEGER;
    default_plan_id INTEGER;
BEGIN
    -- Get the agency tenant ID (should be the first tenant of type 'agency')
    SELECT t_id INTO agency_tenant_id 
    FROM tenants 
    WHERE t_type = 'agency' 
    ORDER BY t_id 
    LIMIT 1;
    
    -- Get default plan ID (free forever plan)
    SELECT plan_id INTO default_plan_id 
    FROM plans 
    WHERE plan_name = 'free forever' 
    LIMIT 1;
    
    -- Use fallback values if not found
    IF agency_tenant_id IS NULL THEN
        agency_tenant_id := 1;
    END IF;
    
    IF default_plan_id IS NULL THEN
        default_plan_id := 1;
    END IF;

    -- Insert new tenant
    INSERT INTO tenants (
        t_name, 
        t_slug,
        t_o_id, 
        t_parent_t_id, 
        t_type, 
        t_portal_mode, 
        t_cluster_affinity, 
        t_status, 
        t_theme, 
        t_plan_id, 
        t_mrr
    ) VALUES (
        NEW.b_name,         -- brand name becomes tenant name
        NULL,               -- optional slug, can generate later
        NEW.b_o_id,         -- pass org id from brand insert
        agency_tenant_id,   -- agency tenant id (parent tenant)
        'brand',            -- tenant_type_enum
        'brand_lite',       -- portal_mode_enum
        'core',             -- cluster_affinity_enum
        'active',           -- default status
        '{}'::jsonb,        -- theme default
        default_plan_id,    -- default plan id
        0                   -- default MRR
    )
    RETURNING t_id INTO new_tenant_id;

    -- Assign generated tenant id back to brand foreign keys
    NEW.b_t_id := new_tenant_id;
    NEW.b_parent_t_id := agency_tenant_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

---------- trigger assignment ----------
CREATE TRIGGER trg_brands_before_insert
BEFORE INSERT ON brands
FOR EACH ROW
EXECUTE FUNCTION trg_auto_create_tenant_for_brand();


-- ========== CORRECTED: Auth user sync trigger ==========
CREATE OR REPLACE FUNCTION public.sync_auth_user_to_public_user()
RETURNS TRIGGER AS $$
DECLARE
  first_name TEXT;
  last_name TEXT;
BEGIN
  -- Extract first word
  first_name := split_part(NEW.display_name, ' ', 1);
  
  -- Extract remainder as last_name if exists
  IF position(' ' IN NEW.display_name) > 0 THEN
    last_name := substring(NEW.display_name FROM position(' ' IN NEW.display_name) + 1);
  ELSE
    last_name := NULL;
  END IF;

  INSERT INTO public.app_users (  -- FIXED: Corrected table name to app_users
    u_id_auth,
    u_first_name,
    u_last_name,
    u_email_verified_at,
    u_phone_verified_at,
    u_avatar_url
  )
  VALUES (
    NEW.id,
    first_name,
    last_name,
    CASE WHEN NEW.email_verified THEN NOW() ELSE NULL END,
    CASE WHEN NEW.phone_number_verified THEN NOW() ELSE NULL END,
    NEW.avatar_url
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

---------- trigger assignment ----------
CREATE TRIGGER trg_insert_auth_user_to_public_user_app
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.sync_auth_user_to_public_user();


-- ========== Trigger to log all deliverable status changes ==========
CREATE OR REPLACE FUNCTION trg_log_deliverable_status_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Only log if status or stage actually changed (handle NULLs properly)
  IF (OLD.dp_status IS DISTINCT FROM NEW.dp_status) OR (OLD.dp_stage IS DISTINCT FROM NEW.dp_stage) THEN
    INSERT INTO deliverable_proposals_activity (
      dpa_dp_id,
      dpa_action_type,
      dpa_action_description,
      dpa_actor_type,
      dpa_previous_status,
      dpa_new_status,
      dpa_previous_stage,
      dpa_new_stage,
      dpa_t_id
    ) VALUES (
      NEW.dp_id,
      'status_updated',
      CONCAT('Status changed from ', COALESCE(OLD.dp_status::text, 'NULL'), ' to ', COALESCE(NEW.dp_status::text, 'NULL')),
      'system',
      OLD.dp_status,
      NEW.dp_status,
      OLD.dp_stage,
      NEW.dp_stage,
      NEW.dp_t_id
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

---------- trigger assignment ----------
CREATE TRIGGER trg_deliverable_status_change
AFTER UPDATE ON deliverable_proposals
FOR EACH ROW
EXECUTE FUNCTION trg_log_deliverable_status_change();


-- ========== Trigger to create initial workflow state ==========
CREATE OR REPLACE FUNCTION trg_create_initial_deliverable_activity()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO deliverable_proposals_activity (
    dpa_dp_id,
    dpa_action_type,
    dpa_action_description,
    dpa_actor_type,
    dpa_new_status,
    dpa_new_stage,
    dpa_t_id
  ) VALUES (
    NEW.dp_id,
    'status_updated',
    'Deliverable created with initial status',
    'system',
    NEW.dp_status,
    NEW.dp_stage,
    NEW.dp_t_id
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

---------- trigger assignment ----------
CREATE TRIGGER trg_deliverable_created
AFTER INSERT ON deliverable_proposals
FOR EACH ROW
EXECUTE FUNCTION trg_create_initial_deliverable_activity();


-- ========== Trigger to update deliverable status when brand approves/rejects ==========
CREATE OR REPLACE FUNCTION trg_update_deliverable_on_brand_approval()
RETURNS TRIGGER AS $$
BEGIN
  -- Update deliverable proposal status based on brand approval
  IF NEW.ba_action = 'approved' THEN
    UPDATE deliverable_proposals 
    SET dp_proposal_status = 'approved',
        dp_stage = 'onboarding',                    -- Start execution workflow
        dp_status = 'onboarding_pending_email'     -- Initial execution status
    WHERE dp_id = NEW.ba_dp_id;
    
  ELSIF NEW.ba_action = 'rejected' THEN
    UPDATE deliverable_proposals 
    SET dp_proposal_status = 'rejected'
    WHERE dp_id = NEW.ba_dp_id;
    
  ELSIF NEW.ba_action = 'requested_changes' THEN
    UPDATE deliverable_proposals 
    SET dp_proposal_status = 'pending_approval'    -- Back to pending for changes
    WHERE dp_id = NEW.ba_dp_id;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

---------- trigger assignment ----------
CREATE TRIGGER trg_brand_approval_updates_deliverable
AFTER INSERT ON brand_approvals
FOR EACH ROW
EXECUTE FUNCTION trg_update_deliverable_on_brand_approval();


-- ========== Trigger to update cart status when all items are reviewed ==========
CREATE OR REPLACE FUNCTION trg_update_cart_status_on_review()
RETURNS TRIGGER AS $$
DECLARE
  cart_id INTEGER;
  total_items INTEGER;
  reviewed_items INTEGER;
BEGIN
  -- Get cart ID for this deliverable
  SELECT ci_cr_id INTO cart_id 
  FROM cart_items 
  WHERE ci_dp_id = NEW.dp_id AND is_deleted = false
  LIMIT 1;
  
  IF cart_id IS NOT NULL THEN
    -- Count total items and reviewed items in this cart
    SELECT 
      COUNT(*),
      COUNT(CASE WHEN dp.dp_proposal_status IN ('approved', 'rejected') THEN 1 END)
    INTO total_items, reviewed_items
    FROM cart_items ci
    JOIN deliverable_proposals dp ON ci.ci_dp_id = dp.dp_id
    WHERE ci.ci_cr_id = cart_id AND ci.is_deleted = false AND dp.is_deleted = false;
    
    -- If all items reviewed, mark cart as reviewed
    IF reviewed_items = total_items AND total_items > 0 THEN
      UPDATE cart_details 
      SET cr_status = 'reviewed',
          cr_reviewed_at = NOW()
      WHERE cr_id = cart_id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_cart_status_update_on_review
AFTER UPDATE ON deliverable_proposals
FOR EACH ROW
WHEN (OLD.dp_proposal_status IS DISTINCT FROM NEW.dp_proposal_status AND NEW.dp_proposal_status IN ('approved', 'rejected'))
EXECUTE FUNCTION trg_update_cart_status_on_review();


-- ========== Trigger to automatically set cart status when sent to brand ==========
CREATE OR REPLACE FUNCTION trg_update_cart_sent_status()
RETURNS TRIGGER AS $$
BEGIN
  -- When cart status changes to 'sent_to_brand', set timestamp
  IF OLD.cr_status != NEW.cr_status AND NEW.cr_status = 'sent_to_brand' THEN
    NEW.cr_sent_to_brand_at := NOW();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

---------- trigger assignment ----------
CREATE TRIGGER trg_cart_sent_timestamp
BEFORE UPDATE ON cart_details
FOR EACH ROW
EXECUTE FUNCTION trg_update_cart_sent_status();


-- ========== Trigger to update email template versions ==========
CREATE OR REPLACE FUNCTION trg_manage_email_template_versions()
RETURNS TRIGGER AS $$
BEGIN
  -- When template content changes, create new version
  IF OLD.et_subject != NEW.et_subject OR OLD.et_body != NEW.et_body OR OLD.et_variables::text != NEW.et_variables::text THEN
    
    -- Set all existing versions as not current
    UPDATE email_template_versions 
    SET etv_is_current = false 
    WHERE etv_et_id = NEW.et_id;
    
    -- Create new version
    INSERT INTO email_template_versions (
      etv_et_id,
      etv_version_number,
      etv_subject,
      etv_body,
      etv_variables,
      etv_change_notes,
      etv_is_current,
      etv_t_id
    ) VALUES (
      NEW.et_id,
      (SELECT COALESCE(MAX(etv_version_number), 0) + 1 FROM email_template_versions WHERE etv_et_id = NEW.et_id),
      NEW.et_subject,
      NEW.et_body,
      NEW.et_variables,
      'Auto-generated version from template update',
      true,
      NEW.et_t_id
    );
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_email_template_versioning
AFTER UPDATE ON email_templates
FOR EACH ROW
EXECUTE FUNCTION trg_manage_email_template_versions();


-- ========== Trigger to auto-insert brand POC when campaign is created ==========
---------- trigger function ----------
CREATE OR REPLACE FUNCTION trg_auto_create_brand_poc_from_campaign()
RETURNS TRIGGER AS $$
BEGIN
    -- Only insert if POC information is provided in the campaign
    IF NEW.c_poc_brand_email IS NOT NULL AND NEW.c_poc_brand_phone IS NOT NULL THEN
        
        -- Check if this POC already exists for this brand to avoid duplicates
        IF NOT EXISTS (
            SELECT 1 FROM brand_poc 
            WHERE bp_b_id = NEW.c_b_id 
            AND bp_contact_email = NEW.c_poc_brand_email 
            AND is_deleted = false
        ) THEN
            
            -- Insert new brand POC
            INSERT INTO brand_poc (
                bp_b_id,
                bp_name,
                bp_description,
                bp_contact_email,
                bp_contact_phone,
                bp_is_active,
                bp_t_id
            ) VALUES (
                NEW.c_b_id,                           -- brand ID from campaign
                COALESCE(NEW.c_poc_brand_name, 'Campaign POC'), -- POC name (with fallback)
                CONCAT('Auto-created from campaign: ', NEW.c_name), -- description with campaign reference
                NEW.c_poc_brand_email,                -- POC email
                NEW.c_poc_brand_phone,                -- POC phone
                true,                                 -- active by default
                NEW.c_t_id                           -- tenant ID from campaign
            );
            
        END IF;
        
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

---------- trigger assignment ----------
CREATE TRIGGER trg_campaigns_create_brand_poc
AFTER INSERT ON campaigns
FOR EACH ROW
EXECUTE FUNCTION trg_auto_create_brand_poc_from_campaign();

-- ========== Optional trigger to handle POC updates in campaigns ==========
---------- trigger function for updates ----------
CREATE OR REPLACE FUNCTION trg_auto_update_brand_poc_from_campaign()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process if POC information has actually changed
    IF (OLD.c_poc_brand_name IS DISTINCT FROM NEW.c_poc_brand_name) OR
       (OLD.c_poc_brand_email IS DISTINCT FROM NEW.c_poc_brand_email) OR
       (OLD.c_poc_brand_phone IS DISTINCT FROM NEW.c_poc_brand_phone) OR
       (OLD.c_poc_brand_designation IS DISTINCT FROM NEW.c_poc_brand_designation) THEN
        
        -- If new POC information is provided
        IF NEW.c_poc_brand_email IS NOT NULL AND NEW.c_poc_brand_phone IS NOT NULL THEN
            
            -- Check if this new POC already exists for this brand
            IF NOT EXISTS (
                SELECT 1 FROM brand_poc 
                WHERE bp_b_id = NEW.c_b_id 
                AND bp_contact_email = NEW.c_poc_brand_email 
                AND is_deleted = false
            ) THEN
                
                -- Insert new brand POC for the updated information
                INSERT INTO brand_poc (
                    bp_b_id,
                    bp_name,
                    bp_description,
                    bp_contact_email,
                    bp_contact_phone,
                    bp_is_active,
                    bp_t_id
                ) VALUES (
                    NEW.c_b_id,
                    COALESCE(NEW.c_poc_brand_name, 'Campaign POC'),
                    CONCAT('Auto-updated from campaign: ', NEW.c_name),
                    NEW.c_poc_brand_email,
                    NEW.c_poc_brand_phone,
                    true,
                    NEW.c_t_id
                );
                
            END IF;
            
        END IF;
        
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

---------- trigger assignment for updates ----------
CREATE TRIGGER trg_campaigns_update_brand_poc
AFTER UPDATE ON campaigns
FOR EACH ROW
EXECUTE FUNCTION trg_auto_update_brand_poc_from_campaign();

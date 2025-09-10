-- Function 1: Deactivate old backup codes (called by your REST API)
CREATE OR REPLACE FUNCTION deactivate_old_backup_codes(user_id_val BIGINT)
RETURNS INTEGER AS $$
DECLARE
  deactivated_count INTEGER;
BEGIN
  -- Deactivate ALL existing backup codes (mark as inactive)
  UPDATE mfa_backup_codes 
  SET mbc_is_active = false,
      modified_at = NOW(),
      modified_by = current_user
  WHERE mbc_u_id = user_id_val 
    AND mbc_is_active = true
    AND is_deleted = false;
  
  GET DIAGNOSTICS deactivated_count = ROW_COUNT;
  
  RETURN deactivated_count;
END;
$$ LANGUAGE plpgsql;

-- Function 2: Store backup codes (called by your REST API)
CREATE OR REPLACE FUNCTION store_backup_codes(
  user_id_val BIGINT, 
  code_hashes TEXT[],
  expires_in_days INTEGER DEFAULT 365
)
RETURNS INTEGER AS $$
DECLARE
  code_hash TEXT;
  codes_inserted INTEGER := 0;
BEGIN
  -- Store each hashed backup code
  FOREACH code_hash IN ARRAY code_hashes
  LOOP
    INSERT INTO mfa_backup_codes (
      mbc_u_id,
      mbc_code_hash,
      mbc_expires_at
    ) VALUES (
      user_id_val,
      code_hash,
      NOW() + (expires_in_days || ' days')::INTERVAL
    );
    
    codes_inserted := codes_inserted + 1;
  END LOOP;
  
  -- Update backup codes generation timestamp in app_users
  UPDATE app_users 
  SET u_backup_codes_generated_at = NOW(),
      modified_at = NOW(),
      modified_by = current_user
  WHERE u_id = user_id_val;
  
  RETURN codes_inserted;
END;
$$ LANGUAGE plpgsql;

-- Function 3: Validate backup code (called during MFA verification)
CREATE OR REPLACE FUNCTION validate_backup_code(user_id_val BIGINT, input_code TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  code_record RECORD;
  is_valid BOOLEAN := false;
BEGIN
  -- Find matching unused backup code
  SELECT mbc_id, mbc_code_hash
  INTO code_record
  FROM mfa_backup_codes
  WHERE mbc_u_id = user_id_val 
    AND mbc_is_active = true 
    AND mbc_used_at IS NULL
    AND mbc_expires_at > NOW()
    AND is_deleted = false
    AND crypt(input_code, mbc_code_hash) = mbc_code_hash
  LIMIT 1;
  
  IF FOUND THEN
    -- Mark code as used (CANNOT be used again)
    UPDATE mfa_backup_codes 
    SET mbc_used_at = NOW(),
        modified_at = NOW(),
        modified_by = current_user
    WHERE mbc_id = code_record.mbc_id;
    
    is_valid := true;
  END IF;
  
  RETURN is_valid;
END;
$$ LANGUAGE plpgsql;

-- Function 4: Get backup codes status for a user
CREATE OR REPLACE FUNCTION get_backup_codes_status(user_id_val BIGINT)
RETURNS TABLE (
  total_codes INTEGER,
  unused_codes INTEGER,
  used_codes INTEGER,
  last_generated TIMESTAMP WITH TIME ZONE,
  expires_soon INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INTEGER as total_codes,
    COUNT(*) FILTER (WHERE mbc_used_at IS NULL)::INTEGER as unused_codes,
    COUNT(*) FILTER (WHERE mbc_used_at IS NOT NULL)::INTEGER as used_codes,
    MAX(created_at) as last_generated,
    COUNT(*) FILTER (WHERE mbc_expires_at < NOW() + INTERVAL '30 days')::INTEGER as expires_soon
  FROM mfa_backup_codes
  WHERE mbc_u_id = user_id_val 
    AND mbc_is_active = true 
    AND is_deleted = false;
END;
$$ LANGUAGE plpgsql;

-- Function 5: Complete backup codes workflow (for your REST API)
CREATE OR REPLACE FUNCTION generate_and_store_backup_codes(
  user_id_val BIGINT,
  code_hashes TEXT[]
)
RETURNS JSON AS $$
DECLARE
  deactivated_count INTEGER;
  inserted_count INTEGER;
  result JSON;
BEGIN
  -- Step 1: Deactivate old codes
  SELECT deactivate_old_backup_codes(user_id_val) INTO deactivated_count;
  
  -- Step 2: Store new codes
  SELECT store_backup_codes(user_id_val, code_hashes) INTO inserted_count;
  
  -- Step 3: Return summary
  result := json_build_object(
    'success', true,
    'deactivated_codes', deactivated_count,
    'new_codes_stored', inserted_count,
    'generated_at', NOW()
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;



-- -----------------------------------------------------------------------------------------------------
-- ***************************** FUNCTIONS FOR user_devices TABLE **************************************
-- -----------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION handle_user_login(
  user_id_val BIGINT,
  device_name_val VARCHAR(255),
  device_type_val device_type_enum,
  browser_val VARCHAR(100),
  os_val VARCHAR(100),
  ip_address_val INET,
  location_city_val VARCHAR(100),
  location_country_val VARCHAR(100),
  nhost_refresh_token_id_val UUID DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  device_id BIGINT;
  session_key VARCHAR(255);
  session_id BIGINT;
  is_new_device BOOLEAN := false;
  result JSON;
BEGIN
  -- 1. Find or create device
  SELECT ud_id INTO device_id
  FROM user_devices
  WHERE ud_u_id = user_id_val 
    AND ud_browser = browser_val
    AND ud_os = os_val
    AND is_deleted = false
  ORDER BY ud_last_login_at DESC
  LIMIT 1;
  
  IF NOT FOUND THEN
    -- Create new device
    INSERT INTO user_devices (
      ud_u_id, ud_device_name, ud_device_type, ud_browser, ud_os,
      ud_ip_address, ud_location_city, ud_location_country,
      ud_login_count, ud_last_login_at
    ) VALUES (
      user_id_val, device_name_val, device_type_val, browser_val, os_val,
      ip_address_val, location_city_val, location_country_val,
      1, NOW()
    )
    RETURNING ud_id INTO device_id;
    
    is_new_device := true;
  ELSE
    -- Update existing device
    UPDATE user_devices 
    SET ud_last_login_at = NOW(),
        ud_login_count = ud_login_count + 1,
        ud_ip_address = ip_address_val,
        ud_location_city = location_city_val,
        ud_location_country = location_country_val,
        modified_at = NOW()
    WHERE ud_id = device_id;
  END IF;
  
  -- 2. Generate truly unique session key using random bytes
  session_key := 'session_' || user_id_val || '_' || device_id || '_' || 
                 EXTRACT(EPOCH FROM NOW())::BIGINT || '_' || 
                 encode(gen_random_bytes(8), 'hex');
  
  -- 3. Deactivate old sessions for this user+device combination
  UPDATE user_sessions 
  SET us_is_active = false,
      modified_at = NOW()
  WHERE us_u_id = user_id_val AND us_device_id = device_id AND us_is_active = true;
  
  -- 4. Create new session (7 days)
  INSERT INTO user_sessions (
    us_u_id, us_device_id, us_nhost_refresh_token_id,
    us_session_key, us_expires_at, us_last_activity_at
  ) VALUES (
    user_id_val, device_id, nhost_refresh_token_id_val,
    session_key, NOW() + INTERVAL '7 days', NOW()
  )
  RETURNING us_id INTO session_id;
  
  -- 5. Log security event
  INSERT INTO user_security_events (
    use_u_id, use_event_type, use_device_id, use_ip_address, use_success, use_metadata
  ) VALUES (
    user_id_val, 
    CASE WHEN is_new_device THEN 'device_added'::security_event_type_enum ELSE 'login_success'::security_event_type_enum END,
    device_id, ip_address_val, true,
    jsonb_build_object(
      'session_id', session_id, 
      'device_new', is_new_device,
      'session_key', session_key
    )
  );
  
  -- 6. Return result
  result := json_build_object(
    'success', true,
    'device_id', device_id,
    'session_id', session_id,
    'session_key', session_key,
    'is_new_device', is_new_device,
    'session_expires_at', NOW() + INTERVAL '7 days'
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function 2: Validate session and extend if active
CREATE OR REPLACE FUNCTION validate_and_extend_session(session_key_val VARCHAR(255))
RETURNS JSON AS $$
DECLARE
  session_record RECORD;
  result JSON;
BEGIN
  -- Get session details with user and device info
  SELECT 
    us.*, 
    ud.ud_device_name, 
    ud.ud_browser,
    ud.ud_os,
    app.u_first_name, 
    app.u_last_name
  INTO session_record
  FROM user_sessions us
  JOIN user_devices ud ON us.us_device_id = ud.ud_id
  JOIN app_users app ON us.us_u_id = app.u_id
  WHERE us.us_session_key = session_key_val
    AND us.us_is_active = true
    AND us.us_expires_at > NOW()
    AND ud.is_deleted = false
    AND app.is_deleted = false;
  
  IF NOT FOUND THEN
    -- Session expired, invalid, or user/device deleted
    result := json_build_object(
      'valid', false,
      'reason', 'Session expired or not found'
    );
  ELSE
    -- Session valid, extend expiry and update activity
    UPDATE user_sessions 
    SET us_expires_at = NOW() + INTERVAL '7 days',
        us_last_activity_at = NOW(),
        modified_at = NOW()
    WHERE us_session_key = session_key_val;
    
    result := json_build_object(
      'valid', true,
      'user_id', session_record.us_u_id,
      'device_id', session_record.us_device_id,
      'device_name', session_record.ud_device_name,
      'browser', session_record.ud_browser,
      'os', session_record.ud_os,
      'user_name', session_record.u_first_name || ' ' || COALESCE(session_record.u_last_name, ''),
      'session_expires_at', NOW() + INTERVAL '7 days',
      'last_activity', session_record.us_last_activity_at
    );
  END IF;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function 3: Logout user session
CREATE OR REPLACE FUNCTION logout_user_session(
  session_key_val VARCHAR(255),
  logout_all_devices BOOLEAN DEFAULT false
)
RETURNS JSON AS $$
DECLARE
  session_record RECORD;
  sessions_logged_out INTEGER := 0;
  result JSON;
BEGIN
  -- Get session info
  SELECT us_u_id, us_device_id INTO session_record
  FROM user_sessions
  WHERE us_session_key = session_key_val AND us_is_active = true;
  
  IF NOT FOUND THEN
    result := json_build_object(
      'success', false,
      'reason', 'Session not found'
    );
  ELSE
    IF logout_all_devices THEN
      -- Logout from all devices for this user
      UPDATE user_sessions 
      SET us_is_active = false,
          modified_at = NOW()
      WHERE us_u_id = session_record.us_u_id AND us_is_active = true;
      
      GET DIAGNOSTICS sessions_logged_out = ROW_COUNT;
      
      -- Log security event
      INSERT INTO user_security_events (
        use_u_id, use_event_type, use_success, use_metadata
      ) VALUES (
        session_record.us_u_id, 'logout', true,
        jsonb_build_object('logout_type', 'all_devices', 'sessions_count', sessions_logged_out)
      );
    ELSE
      -- Logout from current device only
      UPDATE user_sessions 
      SET us_is_active = false,
          modified_at = NOW()
      WHERE us_session_key = session_key_val;
      
      sessions_logged_out := 1;
      
      -- Log security event
      INSERT INTO user_security_events (
        use_u_id, use_event_type, use_device_id, use_success, use_metadata
      ) VALUES (
        session_record.us_u_id, 'logout', session_record.us_device_id, true,
        jsonb_build_object('logout_type', 'single_device')
      );
    END IF;
    
    result := json_build_object(
      'success', true,
      'sessions_logged_out', sessions_logged_out,
      'logout_type', CASE WHEN logout_all_devices THEN 'all_devices' ELSE 'single_device' END
    );
  END IF;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =================================================================================================================
-- ************************** DEVICE MANAGEMENT FUNCTIONS ********************************************************
-- =================================================================================================================

-- Function 4: Get user devices for security dashboard
CREATE OR REPLACE FUNCTION get_user_devices_dashboard(user_id_val BIGINT)
RETURNS TABLE (
  device_id BIGINT,
  device_name VARCHAR(255),
  ip_address TEXT,
  app_used VARCHAR(100),
  last_location TEXT,
  last_login TIMESTAMP WITH TIME ZONE,
  status TEXT,
  login_count INTEGER,
  is_trusted BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ud.ud_id as device_id,
    ud.ud_device_name as device_name,
    ud.ud_ip_address::TEXT as ip_address,
    ud.ud_browser as app_used,
    CONCAT(ud.ud_location_city, ', ', ud.ud_location_country) as last_location,
    ud.ud_last_login_at as last_login,
    CASE 
      WHEN us.us_expires_at > NOW() AND us.us_is_active THEN 'Active'
      WHEN ud.ud_status = 'blocked' THEN 'Blocked'
      WHEN ud.ud_status = 'suspicious' THEN 'Suspicious'
      ELSE 'Inactive'
    END as status,
    ud.ud_login_count as login_count,
    ud.ud_is_trusted as is_trusted
  FROM user_devices ud
  LEFT JOIN user_sessions us ON ud.ud_id = us.us_device_id AND us.us_is_active = true
  WHERE ud.ud_u_id = user_id_val AND ud.is_deleted = false
  ORDER BY ud.ud_last_login_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function 5: Block/unblock device
CREATE OR REPLACE FUNCTION update_device_status(
  device_id_val BIGINT,
  new_status_val device_status_enum,
  user_id_val BIGINT
)
RETURNS BOOLEAN AS $$
DECLARE
  success BOOLEAN := false;
  device_user_id BIGINT;
BEGIN
  -- Verify device belongs to user
  SELECT ud_u_id INTO device_user_id
  FROM user_devices
  WHERE ud_id = device_id_val AND is_deleted = false;
  
  IF device_user_id = user_id_val THEN
    UPDATE user_devices 
    SET ud_status = new_status_val,
        modified_at = NOW()
    WHERE ud_id = device_id_val;
    
    -- If blocking device, also deactivate its sessions
    IF new_status_val = 'blocked' THEN
      UPDATE user_sessions 
      SET us_is_active = false,
          modified_at = NOW()
      WHERE us_device_id = device_id_val AND us_is_active = true;
    END IF;
    
    -- Log security event
    INSERT INTO user_security_events (
      use_u_id, use_event_type, use_device_id, use_success, use_metadata
    ) VALUES (
      user_id_val, 'device_blocked', device_id_val, true,
      jsonb_build_object('new_status', new_status_val)
    );
    
    success := true;
  END IF;
  
  RETURN success;
END;
$$ LANGUAGE plpgsql;

-- Function 6: Trust/untrust device
CREATE OR REPLACE FUNCTION update_device_trust(
  device_id_val BIGINT,
  is_trusted_val BOOLEAN,
  user_id_val BIGINT
)
RETURNS BOOLEAN AS $$
DECLARE
  success BOOLEAN := false;
  device_user_id BIGINT;
BEGIN
  -- Verify device belongs to user
  SELECT ud_u_id INTO device_user_id
  FROM user_devices
  WHERE ud_id = device_id_val AND is_deleted = false;
  
  IF device_user_id = user_id_val THEN
    UPDATE user_devices 
    SET ud_is_trusted = is_trusted_val,
        modified_at = NOW()
    WHERE ud_id = device_id_val;
    
    -- Log security event
    INSERT INTO user_security_events (
      use_u_id, use_event_type, use_device_id, use_success, use_metadata
    ) VALUES (
      user_id_val, 'device_trusted', device_id_val, true,
      jsonb_build_object('is_trusted', is_trusted_val)
    );
    
    success := true;
  END IF;
  
  RETURN success;
END;
$$ LANGUAGE plpgsql;

-- =================================================================================================================
-- ************************** SECURITY AND MAINTENANCE FUNCTIONS *************************************************
-- =================================================================================================================

-- Function 7: Cleanup expired sessions (run as scheduled job)
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS JSON AS $$
DECLARE
  expired_count INTEGER;
  affected_users BIGINT[];
  result JSON;
BEGIN
  -- Get list of users with expired sessions for logging
  SELECT ARRAY_AGG(DISTINCT us_u_id) INTO affected_users
  FROM user_sessions 
  WHERE us_expires_at < NOW() AND us_is_active = true;
  
  -- Mark expired sessions as inactive
  UPDATE user_sessions 
  SET us_is_active = false,
      modified_at = NOW()
  WHERE us_expires_at < NOW() AND us_is_active = true;
  
  GET DIAGNOSTICS expired_count = ROW_COUNT;
  
  -- Log cleanup activity for each affected user
  IF expired_count > 0 THEN
    INSERT INTO user_security_events (
      use_u_id, use_event_type, use_success, use_metadata
    )
    SELECT 
      unnest(affected_users), 
      'session_expired', 
      true, 
      jsonb_build_object(
        'cleanup_timestamp', NOW(),
        'total_expired_sessions', expired_count
      );
  END IF;
  
  result := json_build_object(
    'expired_sessions', expired_count,
    'affected_users', COALESCE(array_length(affected_users, 1), 0),
    'cleanup_timestamp', NOW()
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function 8: Get security statistics for user
CREATE OR REPLACE FUNCTION get_user_security_stats(user_id_val BIGINT)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_devices', (
      SELECT COUNT(*) FROM user_devices WHERE ud_u_id = user_id_val AND is_deleted = false
    ),
    'active_sessions', (
      SELECT COUNT(*) FROM user_sessions us
      JOIN user_devices ud ON us.us_device_id = ud.ud_id
      WHERE us.us_u_id = user_id_val AND us.us_is_active = true 
        AND us.us_expires_at > NOW() AND ud.is_deleted = false
    ),
    'trusted_devices', (
      SELECT COUNT(*) FROM user_devices 
      WHERE ud_u_id = user_id_val AND ud_is_trusted = true AND is_deleted = false
    ),
    'total_logins', (
      SELECT SUM(ud_login_count) FROM user_devices 
      WHERE ud_u_id = user_id_val AND is_deleted = false
    ),
    'failed_logins_24h', (
      SELECT COUNT(*) FROM user_security_events 
      WHERE use_u_id = user_id_val 
        AND use_event_type = 'login_failed'
        AND use_timestamp > NOW() - INTERVAL '24 hours'
    ),
    'last_login', (
      SELECT MAX(ud_last_login_at) FROM user_devices 
      WHERE ud_u_id = user_id_val AND is_deleted = false
    ),
    'security_events_30d', (
      SELECT COUNT(*) FROM user_security_events 
      WHERE use_u_id = user_id_val 
        AND use_timestamp > NOW() - INTERVAL '30 days'
    )
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function 9: Get recent security events for user
CREATE OR REPLACE FUNCTION get_user_security_events(
  user_id_val BIGINT,
  limit_val INTEGER DEFAULT 20
)
RETURNS TABLE (
  event_id BIGINT,
  event_type security_event_type_enum,
  timestamp_val TIMESTAMP WITH TIME ZONE,
  success BOOLEAN,
  device_name VARCHAR(255),
  ip_address TEXT,
  description TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    use.use_id as event_id,
    use.use_event_type as event_type,
    use.use_timestamp as timestamp_val,
    use.use_success as success,
    ud.ud_device_name as device_name,
    use.use_ip_address::TEXT as ip_address,
    CASE 
      WHEN use.use_event_type = 'login_success' THEN 'Successful login'
      WHEN use.use_event_type = 'login_failed' THEN 'Failed login attempt'
      WHEN use.use_event_type = 'device_added' THEN 'New device registered'
      WHEN use.use_event_type = 'device_blocked' THEN 'Device blocked'
      WHEN use.use_event_type = 'device_trusted' THEN 'Device marked as trusted'
      WHEN use.use_event_type = 'logout' THEN 'User logged out'
      WHEN use.use_event_type = 'session_expired' THEN 'Session expired'
      ELSE REPLACE(use.use_event_type::TEXT, '_', ' ')
    END as description
  FROM user_security_events use
  LEFT JOIN user_devices ud ON use.use_device_id = ud.ud_id
  WHERE use.use_u_id = user_id_val
  ORDER BY use.use_timestamp DESC
  LIMIT limit_val;
END;
$$ LANGUAGE plpgsql;



-- =================================================================================================================
-- ******************************* RECENTLY VIEWWS INFLUENCERS *****************************************************
-- =================================================================================================================

-- Function to handle recently viewed influencers with automatic cleanup
CREATE OR REPLACE FUNCTION track_recently_viewed_influencer(
  user_id_val INTEGER,
  influencer_id_val INTEGER,
  tenant_id_val INTEGER,
  max_recent_items INTEGER DEFAULT 50
)
RETURNS VOID AS $$
BEGIN
  -- UPSERT: Insert new record or update existing one
  INSERT INTO recently_viewed_influencers (
    rvi_u_id, 
    rvi_inf_id, 
    rvi_t_id, 
    rvi_viewed_at
  ) VALUES (
    user_id_val, 
    influencer_id_val, 
    tenant_id_val, 
    NOW()
  )
  ON CONFLICT (rvi_u_id, rvi_inf_id) 
  DO UPDATE SET 
    rvi_viewed_at = NOW(),
    modified_at = NOW(),
    modified_by = current_user
  WHERE recently_viewed_influencers.is_deleted = false;
  
  -- Cleanup: Keep only the most recent N items per user
  WITH ranked_views AS (
    SELECT rvi_id,
           ROW_NUMBER() OVER (
             PARTITION BY rvi_u_id 
             ORDER BY rvi_viewed_at DESC
           ) as rn
    FROM recently_viewed_influencers 
    WHERE rvi_u_id = user_id_val 
      AND rvi_t_id = tenant_id_val
      AND is_deleted = false
  )
  UPDATE recently_viewed_influencers 
  SET is_deleted = true,
      deleted_at = NOW(),
      deleted_by = current_user
  WHERE rvi_id IN (
    SELECT rvi_id 
    FROM ranked_views 
    WHERE rn > max_recent_items
  );
  
END;
$$ LANGUAGE plpgsql;


-- Function to get recently viewed influencers for a user
CREATE OR REPLACE FUNCTION get_recently_viewed_influencers(
  user_id_val INTEGER,
  tenant_id_val INTEGER,
  limit_val INTEGER DEFAULT 20
)
RETURNS TABLE (
  influencer_id INTEGER,
  influencer_name VARCHAR(255),
  primary_platform_name VARCHAR(100),
  viewed_at TIMESTAMP WITH TIME ZONE,
  days_ago INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    i.inf_id as influencer_id,
    i.inf_name as influencer_name,
    p.p_name as primary_platform_name,
    rvi.rvi_viewed_at as viewed_at,
    EXTRACT(days FROM NOW() - rvi.rvi_viewed_at)::INTEGER as days_ago
  FROM recently_viewed_influencers rvi
  JOIN influencers i ON rvi.rvi_inf_id = i.inf_id
  LEFT JOIN platforms p ON i.inf_primary_platform_id = p.p_id
  WHERE rvi.rvi_u_id = user_id_val 
    AND rvi.rvi_t_id = tenant_id_val
    AND rvi.is_deleted = false
    AND i.is_deleted = false
  ORDER BY rvi.rvi_viewed_at DESC
  LIMIT limit_val;
END;
$$ LANGUAGE plpgsql;

-- Cleanup function to remove old viewed records (run as scheduled job)
CREATE OR REPLACE FUNCTION cleanup_old_recently_viewed(
  retention_days INTEGER DEFAULT 90
)
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  -- Soft delete records older than retention period
  UPDATE recently_viewed_influencers 
  SET is_deleted = true,
      deleted_at = NOW(),
      deleted_by = 'system_cleanup'
  WHERE rvi_viewed_at < NOW() - (retention_days || ' days')::INTERVAL
    AND is_deleted = false;
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;


-- Function to toggle saved influencer status
CREATE OR REPLACE FUNCTION toggle_saved_influencer(
  user_id_val INTEGER,
  influencer_id_val INTEGER,
  tenant_id_val INTEGER
)
RETURNS JSON AS $$
DECLARE
  existing_record RECORD;
  result JSON;
BEGIN
  -- Check if record exists
  SELECT si_id, is_deleted INTO existing_record
  FROM saved_influencers 
  WHERE si_u_id = user_id_val 
    AND si_inf_id = influencer_id_val;
  
  IF existing_record.si_id IS NULL THEN
    -- Insert new saved record
    INSERT INTO saved_influencers (si_u_id, si_inf_id, si_t_id)
    VALUES (user_id_val, influencer_id_val, tenant_id_val);
    
    result := json_build_object(
      'action', 'saved',
      'is_saved', true,
      'message', 'Influencer added to saved list'
    );
    
  ELSIF existing_record.is_deleted = true THEN
    -- Restore deleted record
    UPDATE saved_influencers 
    SET is_deleted = false,
        deleted_at = NULL,
        deleted_by = NULL,
        modified_at = NOW(),
        modified_by = current_user
    WHERE si_u_id = user_id_val 
      AND si_inf_id = influencer_id_val;
    
    result := json_build_object(
      'action', 'restored',
      'is_saved', true,
      'message', 'Influencer restored to saved list'
    );
    
  ELSE
    -- Remove from saved (soft delete)
    UPDATE saved_influencers 
    SET is_deleted = true,
        deleted_at = NOW(),
        deleted_by = current_user,
        modified_at = NOW()
    WHERE si_u_id = user_id_val 
      AND si_inf_id = influencer_id_val;
    
    result := json_build_object(
      'action', 'unsaved',
      'is_saved', false,
      'message', 'Influencer removed from saved list'
    );
  END IF;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to handle recently viewed influencers with automatic cleanup
CREATE OR REPLACE FUNCTION track_recently_viewed_influencer(
  user_id_val INTEGER,
  influencer_id_val INTEGER,
  tenant_id_val INTEGER,
  max_recent_items INTEGER DEFAULT 50
)
RETURNS VOID AS $$
BEGIN
  -- UPSERT: Insert new record or update existing one
  INSERT INTO recently_viewed_influencers (
    rvi_u_id, 
    rvi_inf_id, 
    rvi_t_id, 
    rvi_viewed_at
  ) VALUES (
    user_id_val, 
    influencer_id_val, 
    tenant_id_val, 
    NOW()
  )
  ON CONFLICT (rvi_u_id, rvi_inf_id) 
  DO UPDATE SET 
    rvi_viewed_at = NOW(),
    modified_at = NOW(),
    modified_by = current_user
  WHERE recently_viewed_influencers.is_deleted = false;
  
  -- Cleanup: Keep only the most recent N items per user
  WITH ranked_views AS (
    SELECT rvi_id,
           ROW_NUMBER() OVER (
             PARTITION BY rvi_u_id 
             ORDER BY rvi_viewed_at DESC
           ) as rn
    FROM recently_viewed_influencers 
    WHERE rvi_u_id = user_id_val 
      AND rvi_t_id = tenant_id_val
      AND is_deleted = false
  )
  UPDATE recently_viewed_influencers 
  SET is_deleted = true,
      deleted_at = NOW(),
      deleted_by = current_user
  WHERE rvi_id IN (
    SELECT rvi_id 
    FROM ranked_views 
    WHERE rn > max_recent_items
  );
  
END;
$$ LANGUAGE plpgsql;


-- Function to get recently viewed influencers for a user
CREATE OR REPLACE FUNCTION get_recently_viewed_influencers(
  user_id_val INTEGER,
  tenant_id_val INTEGER,
  limit_val INTEGER DEFAULT 20
)
RETURNS TABLE (
  influencer_id INTEGER,
  influencer_name VARCHAR(255),
  primary_platform_name VARCHAR(100),
  viewed_at TIMESTAMP WITH TIME ZONE,
  days_ago INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    i.inf_id as influencer_id,
    i.inf_name as influencer_name,
    p.p_name as primary_platform_name,
    rvi.rvi_viewed_at as viewed_at,
    EXTRACT(days FROM NOW() - rvi.rvi_viewed_at)::INTEGER as days_ago
  FROM recently_viewed_influencers rvi
  JOIN influencers i ON rvi.rvi_inf_id = i.inf_id
  LEFT JOIN platforms p ON i.inf_primary_platform_id = p.p_id
  WHERE rvi.rvi_u_id = user_id_val 
    AND rvi.rvi_t_id = tenant_id_val
    AND rvi.is_deleted = false
    AND i.is_deleted = false
  ORDER BY rvi.rvi_viewed_at DESC
  LIMIT limit_val;
END;
$$ LANGUAGE plpgsql;

-- Cleanup function to remove old viewed records (run as scheduled job)
CREATE OR REPLACE FUNCTION cleanup_old_recently_viewed(
  retention_days INTEGER DEFAULT 90
)
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  -- Soft delete records older than retention period
  UPDATE recently_viewed_influencers 
  SET is_deleted = true,
      deleted_at = NOW(),
      deleted_by = 'system_cleanup'
  WHERE rvi_viewed_at < NOW() - (retention_days || ' days')::INTERVAL
    AND is_deleted = false;
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;


-- Function to toggle saved influencer status
CREATE OR REPLACE FUNCTION toggle_saved_influencer(
  user_id_val INTEGER,
  influencer_id_val INTEGER,
  tenant_id_val INTEGER
)
RETURNS JSON AS $$
DECLARE
  existing_record RECORD;
  result JSON;
BEGIN
  -- Check if record exists
  SELECT si_id, is_deleted INTO existing_record
  FROM saved_influencers 
  WHERE si_u_id = user_id_val 
    AND si_inf_id = influencer_id_val;
  
  IF existing_record.si_id IS NULL THEN
    -- Insert new saved record
    INSERT INTO saved_influencers (si_u_id, si_inf_id, si_t_id)
    VALUES (user_id_val, influencer_id_val, tenant_id_val);
    
    result := json_build_object(
      'action', 'saved',
      'is_saved', true,
      'message', 'Influencer added to saved list'
    );
    
  ELSIF existing_record.is_deleted = true THEN
    -- Restore deleted record
    UPDATE saved_influencers 
    SET is_deleted = false,
        deleted_at = NULL,
        deleted_by = NULL,
        modified_at = NOW(),
        modified_by = current_user
    WHERE si_u_id = user_id_val 
      AND si_inf_id = influencer_id_val;
    
    result := json_build_object(
      'action', 'restored',
      'is_saved', true,
      'message', 'Influencer restored to saved list'
    );
    
  ELSE
    -- Remove from saved (soft delete)
    UPDATE saved_influencers 
    SET is_deleted = true,
        deleted_at = NOW(),
        deleted_by = current_user,
        modified_at = NOW()
    WHERE si_u_id = user_id_val 
      AND si_inf_id = influencer_id_val;
    
    result := json_build_object(
      'action', 'unsaved',
      'is_saved', false,
      'message', 'Influencer removed from saved list'
    );
  END IF;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to get saved influencers for a user (FIXED - Added missing closing)
CREATE OR REPLACE FUNCTION get_saved_influencers(
  user_id_val INTEGER,
  tenant_id_val INTEGER,
  limit_val INTEGER DEFAULT 50,
  offset_val INTEGER DEFAULT 0
)
RETURNS TABLE (
  influencer_id INTEGER,
  influencer_name VARCHAR(255),
  primary_platform_name VARCHAR(100),
  saved_at TIMESTAMP WITH TIME ZONE,
  days_saved INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    i.inf_id as influencer_id,
    i.inf_name as influencer_name,
    p.p_name as primary_platform_name,
    si.created_at as saved_at,
    EXTRACT(days FROM NOW() - si.created_at)::INTEGER as days_saved
  FROM saved_influencers si
  JOIN influencers i ON si.si_inf_id = i.inf_id
  LEFT JOIN platforms p ON i.inf_primary_platform_id = p.p_id
  WHERE si.si_u_id = user_id_val 
    AND si.si_t_id = tenant_id_val
    AND si.is_deleted = false
    AND i.is_deleted = false
  ORDER BY si.created_at DESC
  LIMIT limit_val
  OFFSET offset_val;
END;
$$ LANGUAGE plpgsql;

-- Function to get saved influencer count for a user
CREATE OR REPLACE FUNCTION get_saved_influencers_count(
  user_id_val INTEGER,
  tenant_id_val INTEGER
)
RETURNS INTEGER AS $$
DECLARE
  count_result INTEGER;
BEGIN
  SELECT COUNT(*)::INTEGER INTO count_result
  FROM saved_influencers si
  JOIN influencers i ON si.si_inf_id = i.inf_id
  WHERE si.si_u_id = user_id_val 
    AND si.si_t_id = tenant_id_val
    AND si.is_deleted = false
    AND i.is_deleted = false;
  
  RETURN count_result;
END;
$$ LANGUAGE plpgsql;

-- Function to check if an influencer is saved by a user
CREATE OR REPLACE FUNCTION is_influencer_saved(
  user_id_val INTEGER,
  influencer_id_val INTEGER,
  tenant_id_val INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
  is_saved BOOLEAN DEFAULT false;
BEGIN
  SELECT EXISTS(
    SELECT 1 
    FROM saved_influencers si
    WHERE si.si_u_id = user_id_val 
      AND si.si_inf_id = influencer_id_val
      AND si.si_t_id = tenant_id_val
      AND si.is_deleted = false
  ) INTO is_saved;
  
  RETURN is_saved;
END;
$$ LANGUAGE plpgsql;
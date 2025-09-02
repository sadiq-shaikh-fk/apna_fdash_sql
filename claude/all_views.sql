-- =================================================================================================================
-- ************************* SECURITY DASHBOARD VIEW for TABLE user_devices ****************************************
-- =================================================================================================================

-- Create view that exactly matches your UI table structure
CREATE OR REPLACE VIEW user_device_sessions AS
SELECT
  ud.ud_id,
  ud.ud_u_id,
  app.u_first_name || ' ' || COALESCE(app.u_last_name, '') as user_name,
  ud.ud_device_name,
  ud.ud_ip_address::TEXT as ip_address,
  ud.ud_browser as app_used,  -- This will show actual browser names like "Chrome", "Safari"
  CONCAT(ud.ud_location_city, ', ', ud.ud_location_region, ', ', ud.ud_location_country) as last_location,
  ud.ud_last_login_at as last_login,
  
  -- Status matching your UI (Active/Inactive instead of enum values)
  CASE 
    WHEN ud.ud_last_login_at > NOW() - INTERVAL '5 minutes' THEN 'Active'
    WHEN ud.ud_status = 'blocked' THEN 'Blocked'
    WHEN ud.ud_status = 'suspicious' THEN 'Suspicious'
    ELSE 'Inactive'
  END as status,
  
  -- Additional useful fields for management
  ud.ud_device_type,
  ud.ud_browser_version,
  ud.ud_os,
  ud.ud_os_version,
  ud.ud_is_trusted,
  ud.ud_login_count,
  ud.ud_first_seen_at,
  ud.ud_last_seen_at,
  ud.ud_status as raw_status

FROM user_devices ud
JOIN app_users app ON ud.ud_u_id = app.u_id
WHERE ud.is_deleted = false AND app.is_deleted = false;
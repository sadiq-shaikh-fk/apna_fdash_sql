-- ================================================
-- FDash Database Schema - Production Ready Version
-- ================================================

-- -------------------------
-- INITIAL SETUP - Core Tables
-- -------------------------

---------- table gods_eye ----------
CREATE TABLE gods_eye (
  ge_id SERIAL PRIMARY KEY,
  ge_name VARCHAR(255) NOT NULL,
  ge_password VARCHAR(255) NOT NULL,
  ge_is_active BOOLEAN NOT NULL DEFAULT true,
  ge_last_login TIMESTAMP WITH TIME ZONE,
  -- audit and logs 
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- constraints
  CONSTRAINT uk_gods_eye_name UNIQUE (ge_name)
);

---------- table organizations ----------
CREATE TYPE organization_status_enum AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE organization_type_enum AS ENUM ('general', 'agency', 'brand');

CREATE TABLE organizations (
  o_id SERIAL PRIMARY KEY,
  o_name VARCHAR(255) NOT NULL DEFAULT 'Freemium',
  o_type organization_type_enum NOT NULL DEFAULT 'general',
  o_status organization_status_enum NOT NULL DEFAULT 'active',
  o_logo_url VARCHAR(500),
  o_subscription_plan VARCHAR(100),
  o_subscription_expires_at TIMESTAMP WITH TIME ZONE,
  -- audit and logs 
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- constraints
  CONSTRAINT uk_organizations_name UNIQUE (o_name)
);

---------- table teams ----------
CREATE TYPE team_status_enum AS ENUM ('active', 'inactive');

CREATE TABLE teams (
  t_id SERIAL PRIMARY KEY,
  t_name VARCHAR(255) NOT NULL,
  t_description TEXT,
  t_workspace_id INTEGER NOT NULL,
  t_status team_status_enum NOT NULL DEFAULT 'active',
  t_o_id INTEGER NOT NULL,
  -- audit and logs 
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_teams_organization FOREIGN KEY (t_o_id) REFERENCES organizations(o_id) ON DELETE CASCADE,
  -- constraints
  CONSTRAINT uk_teams_name_org UNIQUE (t_name, t_o_id)
);

---------- table roles ----------
CREATE TABLE roles (
  r_id SERIAL PRIMARY KEY,
  r_name VARCHAR(100) NOT NULL,
  r_description TEXT,
  r_o_id INTEGER,
  r_is_system_role BOOLEAN NOT NULL DEFAULT false,
  -- audit and logs 
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_roles_organization FOREIGN KEY (r_o_id) REFERENCES organizations(o_id) ON DELETE CASCADE,
  -- constraints
  CONSTRAINT uk_roles_name_org UNIQUE (r_name, r_o_id)
);

---------- table users ----------
CREATE TYPE user_type_enum AS ENUM ('general', 'agency', 'brand');
CREATE TYPE user_status_enum AS ENUM ('active', 'inactive', 'suspended', 'pending_verification');

CREATE TABLE users (
  u_id SERIAL PRIMARY KEY,
  u_email VARCHAR(255) NOT NULL,
  u_phone_number VARCHAR(20) NOT NULL,
  u_first_name VARCHAR(100),
  u_last_name VARCHAR(100),
  u_password VARCHAR(255) NOT NULL,  -- hashed password
  u_oauth_token VARCHAR(500),
  u_oauth_provider VARCHAR(50),
  u_is_authorized BOOLEAN NOT NULL DEFAULT false,
  u_user_type user_type_enum NOT NULL DEFAULT 'general',
  u_status user_status_enum NOT NULL DEFAULT 'pending_verification',
  u_o_id INTEGER NOT NULL,
  u_t_id INTEGER NOT NULL,
  u_r_id INTEGER NOT NULL,
  u_is_workspace_admin BOOLEAN NOT NULL DEFAULT false,
  u_last_login TIMESTAMP WITH TIME ZONE,
  u_login_attempts INTEGER DEFAULT 0,
  u_locked_until TIMESTAMP WITH TIME ZONE,
  u_email_verified_at TIMESTAMP WITH TIME ZONE,
  u_phone_verified_at TIMESTAMP WITH TIME ZONE,
  u_avatar_url VARCHAR(500),
  u_timezone VARCHAR(50) DEFAULT 'UTC',
  -- audit and logs 
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_users_team FOREIGN KEY (u_t_id) REFERENCES teams(t_id) ON DELETE RESTRICT,
  CONSTRAINT fk_users_organization FOREIGN KEY (u_o_id) REFERENCES organizations(o_id) ON DELETE CASCADE,
  CONSTRAINT fk_users_role FOREIGN KEY (u_r_id) REFERENCES roles(r_id) ON DELETE RESTRICT,
  -- constraints
  CONSTRAINT uk_users_email UNIQUE (u_email),
  CONSTRAINT uk_users_phone UNIQUE (u_phone_number),
  CONSTRAINT chk_email_format CHECK (u_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
  CONSTRAINT chk_login_attempts CHECK (u_login_attempts >= 0)
);

---------- table user_invites ----------
CREATE TYPE ui_invite_status_enum AS ENUM ('pending', 'accepted', 'expired', 'cancelled');

CREATE TABLE user_invites (
  ui_id SERIAL PRIMARY KEY,
  ui_token VARCHAR(255) NOT NULL,
  ui_status ui_invite_status_enum NOT NULL DEFAULT 'pending',
  ui_sent_by_u_id INTEGER NOT NULL,
  ui_sent_to_email VARCHAR(255) NOT NULL,
  ui_sent_to_phone VARCHAR(20),
  ui_expiry_at TIMESTAMP WITH TIME ZONE NOT NULL,
  ui_redeemed_at TIMESTAMP WITH TIME ZONE,
  ui_r_id INTEGER NOT NULL,
  ui_o_id INTEGER NOT NULL,
  ui_t_id INTEGER NOT NULL,
  ui_message TEXT,
  -- audit and logs 
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_user_invites_sent_by FOREIGN KEY (ui_sent_by_u_id) REFERENCES users(u_id) ON DELETE CASCADE,
  CONSTRAINT fk_user_invites_role FOREIGN KEY (ui_r_id) REFERENCES roles(r_id) ON DELETE RESTRICT,
  CONSTRAINT fk_user_invites_organization FOREIGN KEY (ui_o_id) REFERENCES organizations(o_id) ON DELETE CASCADE,
  CONSTRAINT fk_user_invites_team FOREIGN KEY (ui_t_id) REFERENCES teams(t_id) ON DELETE CASCADE,
  -- constraints
  CONSTRAINT uk_user_invites_token UNIQUE (ui_token),
  CONSTRAINT chk_email_format CHECK (ui_sent_to_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
  CONSTRAINT chk_expiry_future CHECK (ui_expiry_at > created_at)
);

-- -------------------------
-- RBAC (Role-Based Access Control)
-- -------------------------

---------- table modules ----------
CREATE TABLE modules (
  m_id SERIAL PRIMARY KEY,
  m_name VARCHAR(100) NOT NULL,
  m_description TEXT,
  m_is_active BOOLEAN NOT NULL DEFAULT true,
  m_sort_order INTEGER DEFAULT 0,
  -- audit and logs 
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- constraints
  CONSTRAINT uk_modules_name UNIQUE (m_name)
);

---------- table features ----------
CREATE TABLE features (
  f_id SERIAL PRIMARY KEY,
  f_name VARCHAR(100) NOT NULL,
  f_description TEXT,
  f_m_id INTEGER NOT NULL,
  f_is_active BOOLEAN NOT NULL DEFAULT true,
  f_sort_order INTEGER DEFAULT 0,
  -- audit and logs 
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_features_module FOREIGN KEY (f_m_id) REFERENCES modules(m_id) ON DELETE CASCADE,
  -- constraints
  CONSTRAINT uk_features_name_module UNIQUE (f_name, f_m_id)
);

---------- table access ----------
CREATE TABLE access (
  a_id SERIAL PRIMARY KEY,
  a_name VARCHAR(50) NOT NULL,
  a_description TEXT,
  a_is_active BOOLEAN NOT NULL DEFAULT true,
  -- audit and logs 
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- constraints
  CONSTRAINT uk_access_name UNIQUE (a_name)
);

---------- table role_permissions ----------
CREATE TABLE role_permissions (
  rp_id SERIAL PRIMARY KEY,
  rp_r_id INTEGER NOT NULL,
  rp_m_id INTEGER NOT NULL,
  rp_f_id INTEGER NOT NULL,
  rp_a_id INTEGER NOT NULL,
  rp_is_active BOOLEAN NOT NULL DEFAULT true,
  -- audit and logs 
  created_by INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by INTEGER NOT NULL,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_role_permissions_role FOREIGN KEY (rp_r_id) REFERENCES roles(r_id) ON DELETE CASCADE,
  CONSTRAINT fk_role_permissions_module FOREIGN KEY (rp_m_id) REFERENCES modules(m_id) ON DELETE CASCADE,
  CONSTRAINT fk_role_permissions_feature FOREIGN KEY (rp_f_id) REFERENCES features(f_id) ON DELETE CASCADE,
  CONSTRAINT fk_role_permissions_access FOREIGN KEY (rp_a_id) REFERENCES access(a_id) ON DELETE CASCADE,
  CONSTRAINT fk_role_permissions_created_by FOREIGN KEY (created_by) REFERENCES users(u_id),
  CONSTRAINT fk_role_permissions_modified_by FOREIGN KEY (modified_by) REFERENCES users(u_id),
  -- constraints
  CONSTRAINT uk_role_permissions UNIQUE (rp_r_id, rp_m_id, rp_f_id, rp_a_id)
);

-- -------------------------
-- FILTERS AND SHARING
-- -------------------------

---------- table filters ----------
CREATE TYPE filter_type_enum AS ENUM ('public', 'private', 'shared');

CREATE TABLE filters (
  f_id SERIAL PRIMARY KEY,
  f_name VARCHAR(255) NOT NULL,
  f_description TEXT,
  f_type filter_type_enum NOT NULL DEFAULT 'private',
  f_created_by INTEGER NOT NULL,
  f_metadata JSONB NOT NULL,
  f_is_active BOOLEAN NOT NULL DEFAULT true,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_filters_created_by FOREIGN KEY (f_created_by) REFERENCES users(u_id) ON DELETE CASCADE,
  -- constraints
  CONSTRAINT uk_filters_name_user UNIQUE (f_name, f_created_by)
);

---------- table filter_shares ----------
CREATE TABLE filter_shares (
  fs_id SERIAL PRIMARY KEY,
  fs_f_id INTEGER NOT NULL,
  fs_shared_with INTEGER NOT NULL,
  fs_access_level INTEGER NOT NULL,
  fs_is_active BOOLEAN NOT NULL DEFAULT true,
  fs_expires_at TIMESTAMP WITH TIME ZONE,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_filter_shares_filter FOREIGN KEY (fs_f_id) REFERENCES filters(f_id) ON DELETE CASCADE,
  CONSTRAINT fk_filter_shares_user FOREIGN KEY (fs_shared_with) REFERENCES users(u_id) ON DELETE CASCADE,
  CONSTRAINT fk_filter_shares_access FOREIGN KEY (fs_access_level) REFERENCES access(a_id) ON DELETE RESTRICT,
  -- constraints
  CONSTRAINT uk_filter_shares UNIQUE (fs_f_id, fs_shared_with)
);

-- -------------------------
-- INFLUENCERS SECTION
-- -------------------------

---------- table platforms ----------
CREATE TABLE platforms (
  p_id SERIAL PRIMARY KEY,
  p_name VARCHAR(100) NOT NULL,
  p_display_name VARCHAR(100),
  p_icon_url VARCHAR(500),
  p_api_endpoint VARCHAR(255),
  p_is_active BOOLEAN NOT NULL DEFAULT true,
  p_sort_order INTEGER DEFAULT 0,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- constraints
  CONSTRAINT uk_platforms_name UNIQUE (p_name)
);

---------- table influencers ---------- 
CREATE TYPE influencer_status_enum AS ENUM ('active', 'inactive', 'blacklisted', 'pending_verification');
CREATE TYPE verification_status_enum AS ENUM ('verified', 'unverified', 'pending');

CREATE TABLE influencers (
  inf_id SERIAL PRIMARY KEY,
  inf_name VARCHAR(255) NOT NULL,
  inf_email VARCHAR(255),
  inf_phone VARCHAR(20),
  inf_status influencer_status_enum NOT NULL DEFAULT 'pending_verification',
  inf_verification_status verification_status_enum NOT NULL DEFAULT 'unverified',
  inf_primary_platform_id INTEGER,
  inf_bio TEXT,
  inf_location VARCHAR(255),
  inf_age INTEGER,
  inf_gender VARCHAR(20),
  inf_languages JSONB,
  inf_categories JSONB,
  inf_niches JSONB,
  inf_average_engagement_rate DECIMAL(5,2),
  inf_last_active_date TIMESTAMP WITH TIME ZONE,
  inf_payment_terms TEXT,
  inf_preferred_collaboration_types JSONB,
  inf_min_campaign_budget DECIMAL(15,2),
  inf_rating DECIMAL(3,2) DEFAULT 0.00,
  inf_total_campaigns INTEGER DEFAULT 0,
  inf_profile_image_url VARCHAR(500),
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_influencers_platform FOREIGN KEY (inf_primary_platform_id) REFERENCES platforms(p_id) ON DELETE SET NULL,
  -- constraints
  CONSTRAINT uk_influencers_email UNIQUE (inf_email),
  CONSTRAINT chk_age_range CHECK (inf_age >= 13 AND inf_age <= 100),
  CONSTRAINT chk_engagement_rate CHECK (inf_average_engagement_rate >= 0 AND inf_average_engagement_rate <= 100),
  CONSTRAINT chk_rating CHECK (inf_rating >= 0 AND inf_rating <= 5)
);

---------- table influencer_platform_metrics ----------
CREATE TABLE influencer_platform_metrics (
  ipm_id SERIAL PRIMARY KEY,
  ipm_inf_id INTEGER NOT NULL,
  ipm_p_id INTEGER NOT NULL,
  ipm_platform_username VARCHAR(255),
  ipm_platform_url VARCHAR(500),
  ipm_followers_count BIGINT DEFAULT 0,
  ipm_following_count BIGINT DEFAULT 0,
  ipm_posts_count BIGINT DEFAULT 0,
  ipm_engagement_rate DECIMAL(5,2) DEFAULT 0.00,
  ipm_avg_likes BIGINT DEFAULT 0,
  ipm_avg_comments BIGINT DEFAULT 0,
  ipm_avg_shares BIGINT DEFAULT 0,
  ipm_last_post_date TIMESTAMP WITH TIME ZONE,
  ipm_verification_badge BOOLEAN DEFAULT false,
  ipm_metrics_last_updated TIMESTAMP WITH TIME ZONE DEFAULT current_timestamp,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_inf_platform_metrics_influencer FOREIGN KEY (ipm_inf_id) REFERENCES influencers(inf_id) ON DELETE CASCADE,
  CONSTRAINT fk_inf_platform_metrics_platform FOREIGN KEY (ipm_p_id) REFERENCES platforms(p_id) ON DELETE CASCADE,
  -- constraints
  CONSTRAINT uk_influencer_platform UNIQUE (ipm_inf_id, ipm_p_id),
  CONSTRAINT chk_followers_positive CHECK (ipm_followers_count >= 0),
  CONSTRAINT chk_engagement_positive CHECK (ipm_engagement_rate >= 0)
);

-- -------------------------
-- BRANDS SECTION
-- -------------------------

---------- table brands ----------
CREATE TYPE brand_status_enum AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE company_size_enum AS ENUM ('startup', 'small', 'medium', 'large', 'enterprise');

CREATE TABLE brands (
  b_id SERIAL PRIMARY KEY,
  b_name VARCHAR(255) NOT NULL,
  b_legal_name VARCHAR(255),
  b_status brand_status_enum NOT NULL DEFAULT 'active',
  b_logo_url VARCHAR(500),
  b_website VARCHAR(500),
  b_linkedin_url VARCHAR(500),
  b_company_size company_size_enum,
  b_industry VARCHAR(100),
  b_market_cap_range VARCHAR(50),
  b_values TEXT,
  b_messaging TEXT,
  b_brand_identity TEXT,
  b_detailed_summary TEXT,
  b_tax_registration_number VARCHAR(100),
  b_payment_terms TEXT,
  b_primary_contact_name VARCHAR(255),
  b_primary_contact_email VARCHAR(255),
  b_primary_contact_phone VARCHAR(20),
  b_address TEXT,
  b_city VARCHAR(100),
  b_state VARCHAR(100),
  b_country VARCHAR(100),
  b_postal_code VARCHAR(20),
  b_founded_year INTEGER,
  b_employee_count INTEGER,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- constraints
  CONSTRAINT uk_brands_name UNIQUE (b_name),
  CONSTRAINT chk_founded_year CHECK (b_founded_year >= 1800 AND b_founded_year <= EXTRACT(YEAR FROM CURRENT_DATE))
);

---------- table brand_products_services ----------
CREATE TABLE brand_products_services (
  bps_id SERIAL PRIMARY KEY,
  bps_b_id INTEGER NOT NULL,
  bps_name VARCHAR(255) NOT NULL,
  bps_description TEXT,
  bps_category VARCHAR(100),
  bps_price_range VARCHAR(50),
  bps_is_active BOOLEAN NOT NULL DEFAULT true,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_brand_products_brand FOREIGN KEY (bps_b_id) REFERENCES brands(b_id) ON DELETE CASCADE,
  -- constraints
  CONSTRAINT uk_brand_products_name UNIQUE (bps_name)
);

---------- table brand_competitors ----------
CREATE TYPE competitor_type_enum AS ENUM ('direct', 'indirect');

CREATE TABLE brand_competitors (
  bc_id SERIAL PRIMARY KEY,
  bc_b_id INTEGER NOT NULL,
  bc_competitor_name VARCHAR(255) NOT NULL,
  bc_type competitor_type_enum NOT NULL,
  bc_market_share VARCHAR(50),
  bc_strengths TEXT,
  bc_weaknesses TEXT,
  bc_website VARCHAR(500),
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_brand_competitors_brand FOREIGN KEY (bc_b_id) REFERENCES brands(b_id) ON DELETE CASCADE,
  -- constraints
  CONSTRAINT uk_brand_competitors UNIQUE (bc_competitor_name)
);

---------- table brand_poc ----------
CREATE TABLE brand_poc (
  bp_id SERIAL PRIMARY KEY,
  bp_b_id INTEGER NOT NULL,
  bp_name VARCHAR(255) NOT NULL,
  bp_description TEXT,
  bp_contact_email VARCHAR(255) NOT NULL,
  bp_contact_phone BIGINT(50) NOT NULL,
  bp_is_active BOOLEAN NOT NULL DEFAULT true,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_brand_poc FOREIGN KEY (bp_b_id) REFERENCES brands(b_id) ON DELETE CASCADE,
  -- constraints
  CONSTRAINT uk_brand_poc UNIQUE (bp_name)
);

-- -------------------------
-- CAMPAIGNS SECTION
-- -------------------------

---------- table campaigns ----------
CREATE TYPE campaign_status_enum AS ENUM ('draft', 'active', 'paused', 'completed', 'cancelled');
CREATE TYPE campaign_gender_enum AS ENUM ('male', 'female', 'both', 'non_binary', 'other');
CREATE TYPE campaign_income_enum AS ENUM ('0-2LPA', '2-4LPA', '4-6LPA', '6-10LPA', '10-15LPA', '15-25LPA', '25LPA+');
CREATE TYPE campaign_priority_enum AS ENUM ('low', 'medium', 'high', 'urgent');

CREATE TABLE campaigns (
  c_id SERIAL PRIMARY KEY,
  c_b_id INTEGER NOT NULL,
  c_status campaign_status_enum NOT NULL DEFAULT 'draft',
  c_priority campaign_priority_enum NOT NULL DEFAULT 'medium',
  
  -- Basic Campaign Info
  c_name VARCHAR(255) NOT NULL,
  c_description TEXT,
  c_budget_min DECIMAL(15,2),
  c_budget_max DECIMAL(15,2),
  c_budget_currency VARCHAR(3) DEFAULT 'INR',
  c_start_date DATE NOT NULL,
  c_end_date DATE NOT NULL,
  c_bidding_start_time TIMESTAMP WITH TIME ZONE,
  c_bidding_end_time TIMESTAMP WITH TIME ZONE,
  c_products_services TEXT,
  c_business_objectives TEXT,
  c_success_metrics TEXT,
  
  -- Target Demographics
  c_target_age_min INTEGER,
  c_target_age_max INTEGER,
  c_target_gender campaign_gender_enum,
  c_target_income campaign_income_enum,
  c_target_locations JSONB,
  c_target_education_levels JSONB,
  c_target_languages JSONB,
  c_target_interests JSONB,
  c_behavioral_patterns TEXT,
  c_psychographics TEXT,
  c_technographics TEXT,
  c_purchase_intent TEXT,
  c_additional_demographics TEXT,
  
  -- Influencer Requirements
  c_inf_followers_min INTEGER,
  c_inf_followers_max INTEGER,
  c_inf_engagement_rate_min DECIMAL(5,2),
  c_inf_engagement_rate_max DECIMAL(5,2),
  c_inf_genres JSONB,
  c_inf_niches JSONB,
  c_inf_locations JSONB,
  c_inf_age_min INTEGER,
  c_inf_age_max INTEGER,
  c_inf_languages JSONB,
  c_inf_primary_platform_id INTEGER,
  c_inf_last_post_days INTEGER,
  c_inf_content_categories JSONB,
  c_inf_payment_terms TEXT,
  c_exclude_previous_brand_collaborators BOOLEAN DEFAULT false,
  c_exclude_competitor_collaborators BOOLEAN DEFAULT false,
  
  -- Point of Contact Information
  c_poc_cs_user_id INTEGER,
  c_poc_bd_user_id INTEGER,
  c_poc_ex_user_id INTEGER,
  c_poc_brand_name VARCHAR(255),
  c_poc_brand_designation VARCHAR(100),
  c_poc_brand_email VARCHAR(255),
  c_poc_brand_phone VARCHAR(20),
  
  -- Campaign Analytics
  c_total_applications INTEGER DEFAULT 0,
  c_total_shortlisted INTEGER DEFAULT 0,
  c_total_selected INTEGER DEFAULT 0,
  c_total_deliverables INTEGER DEFAULT 0,
  c_total_spend DECIMAL(15,2) DEFAULT 0,
  
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  
  -- Foreign key constraints
  CONSTRAINT fk_campaigns_brand FOREIGN KEY (c_b_id) REFERENCES brands(b_id) ON DELETE CASCADE,
  CONSTRAINT fk_campaigns_inf_platform FOREIGN KEY (c_inf_primary_platform_id) REFERENCES platforms(p_id) ON DELETE SET NULL,
  CONSTRAINT fk_campaigns_poc_cs FOREIGN KEY (c_poc_cs_user_id) REFERENCES users(u_id) ON DELETE SET NULL,
  CONSTRAINT fk_campaigns_poc_bd FOREIGN KEY (c_poc_bd_user_id) REFERENCES users(u_id) ON DELETE SET NULL,
  CONSTRAINT fk_campaigns_poc_ex FOREIGN KEY (c_poc_ex_user_id) REFERENCES users(u_id) ON DELETE SET NULL,
  
  -- constraints
  CONSTRAINT uk_campaigns_name_brand UNIQUE (c_name, c_b_id),
  CONSTRAINT chk_campaign_dates CHECK (c_end_date >= c_start_date),
  CONSTRAINT chk_budget_range CHECK (c_budget_max >= c_budget_min),
  CONSTRAINT chk_age_range CHECK (c_target_age_max >= c_target_age_min),
  CONSTRAINT chk_inf_age_range CHECK (c_inf_age_max >= c_inf_age_min),
  CONSTRAINT chk_followers_range CHECK (c_inf_followers_max >= c_inf_followers_min),
  CONSTRAINT chk_engagement_range CHECK (c_inf_engagement_rate_max >= c_inf_engagement_rate_min)
);

---------- table campaign_objectives ----------
CREATE TABLE campaign_objectives (
  co_id SERIAL PRIMARY KEY,
  co_c_id INTEGER NOT NULL,
  co_objective_name VARCHAR(255) NOT NULL,
  co_target_value VARCHAR(100),
  co_measurement_method TEXT,
  co_priority INTEGER DEFAULT 1,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_campaign_objectives_campaign FOREIGN KEY (co_c_id) REFERENCES campaigns(c_id) ON DELETE CASCADE
);

---------- table campaign_platforms ----------
CREATE TABLE campaign_platforms (
  cp_id SERIAL PRIMARY KEY,
  cp_c_id INTEGER NOT NULL,
  cp_p_id INTEGER NOT NULL,
  cp_priority INTEGER DEFAULT 1,
  cp_budget_allocation_percentage DECIMAL(5,2),
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_campaign_platforms_campaign FOREIGN KEY (cp_c_id) REFERENCES campaigns(c_id) ON DELETE CASCADE,
  CONSTRAINT fk_campaign_platforms_platform FOREIGN KEY (cp_p_id) REFERENCES platforms(p_id) ON DELETE CASCADE,
  -- constraints
  CONSTRAINT uk_campaign_platforms UNIQUE (cp_c_id, cp_p_id),
  CONSTRAINT chk_allocation_percentage CHECK (cp_budget_allocation_percentage >= 0 AND cp_budget_allocation_percentage <= 100)
);

-- -------------------------
-- DELIVERABLES SECTION
-- -------------------------

---------- table deliverable_types ----------
CREATE TABLE deliverable_types (
  dt_id SERIAL PRIMARY KEY,
  dt_name VARCHAR(100) NOT NULL,
  dt_description TEXT,
  dt_is_active BOOLEAN NOT NULL DEFAULT true,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- constraints
  CONSTRAINT uk_deliverable_types_name UNIQUE (dt_name)
);

---------- table platform_deliverables ----------
CREATE TABLE platform_deliverables (
  pd_id SERIAL PRIMARY KEY,
  pd_p_id INTEGER NOT NULL,
  pd_dt_id INTEGER NOT NULL,
  pd_name VARCHAR(255) NOT NULL,
  pd_description TEXT,
  pd_base_price DECIMAL(15,2),
  pd_is_active BOOLEAN NOT NULL DEFAULT true,
  pd_estimated_duration_hours INTEGER,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_platform_deliverables_platform FOREIGN KEY (pd_p_id) REFERENCES platforms(p_id) ON DELETE CASCADE,
  CONSTRAINT fk_platform_deliverables_type FOREIGN KEY (pd_dt_id) REFERENCES deliverable_types(dt_id) ON DELETE RESTRICT,
  -- constraints
  CONSTRAINT uk_platform_deliverables UNIQUE (pd_p_id, pd_dt_id, pd_name)
);

-- -------------------------
-- CAMPAIGN LISTS AND INFLUENCER SELECTION
-- -------------------------

---------- table campaign_lists ----------
CREATE TYPE list_status_enum AS ENUM ('draft', 'active', 'completed', 'archived');

CREATE TABLE campaign_lists (
  cl_id SERIAL PRIMARY KEY,
  cl_name VARCHAR(255) NOT NULL,
  cl_description TEXT,
  cl_c_id INTEGER NOT NULL,
  cl_created_by INTEGER NOT NULL,
  cl_status list_status_enum NOT NULL DEFAULT 'draft',
  cl_total_influencers INTEGER DEFAULT 0,
  cl_total_budget DECIMAL(15,2) DEFAULT 0,
  cl_is_active BOOLEAN NOT NULL DEFAULT true,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_campaign_lists_campaign FOREIGN KEY (cl_c_id) REFERENCES campaigns(c_id) ON DELETE CASCADE,
  CONSTRAINT fk_campaign_lists_creator FOREIGN KEY (cl_created_by) REFERENCES users(u_id) ON DELETE RESTRICT,
  -- constraints
  CONSTRAINT uk_campaign_lists_name UNIQUE (cl_c_id, cl_name)
);

---------- table influencer_proposals ----------
CREATE TYPE proposal_status_enum AS ENUM ('pending', 'shortlisted', 'selected', 'rejected', 'withdrawn');
CREATE TYPE proposal_priority_enum AS ENUM ('low', 'medium', 'high');

CREATE TABLE influencer_proposals (
  ip_id SERIAL PRIMARY KEY,
  ip_cl_id INTEGER NOT NULL,
  ip_inf_id INTEGER NOT NULL,
  ip_status proposal_status_enum NOT NULL DEFAULT 'pending',
  ip_priority proposal_priority_enum NOT NULL DEFAULT 'medium',
  ip_proposed_rate DECIMAL(15,2),
  ip_negotiated_rate DECIMAL(15,2),
  ip_final_rate DECIMAL(15,2),
  ip_proposal_notes TEXT,
  ip_rejection_reason TEXT,
  ip_influencer_response TEXT,
  ip_response_date TIMESTAMP WITH TIME ZONE,
  ip_selection_date TIMESTAMP WITH TIME ZONE,
  ip_contract_signed_date TIMESTAMP WITH TIME ZONE,
  ip_performance_score DECIMAL(3,2),
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_influencer_proposals_list FOREIGN KEY (ip_cl_id) REFERENCES campaign_lists(cl_id) ON DELETE CASCADE,
  CONSTRAINT fk_influencer_proposals_influencer FOREIGN KEY (ip_inf_id) REFERENCES influencers(inf_id) ON DELETE CASCADE,
  -- constraints
  CONSTRAINT uk_influencer_proposals UNIQUE (ip_cl_id, ip_inf_id),
  CONSTRAINT chk_rates_positive CHECK (ip_proposed_rate >= 0 AND ip_negotiated_rate >= 0 AND ip_final_rate >= 0)
);

---------- table proposal_deliverables ----------
CREATE TYPE deliverable_status_enum AS ENUM ('pending', 'in_progress', 'submitted', 'approved', 'rejected', 'revision_required');

CREATE TABLE proposal_deliverables (
  prd_id SERIAL PRIMARY KEY,
  prd_ip_id INTEGER NOT NULL,
  prd_pd_id INTEGER NOT NULL,
  prd_quantity INTEGER NOT NULL DEFAULT 1,
  prd_agreed_price DECIMAL(15,2) NOT NULL,
  prd_status deliverable_status_enum NOT NULL DEFAULT 'pending',
  prd_scheduled_date DATE,
  prd_submission_date TIMESTAMP WITH TIME ZONE,
  prd_approval_date TIMESTAMP WITH TIME ZONE,
  prd_content_brief TEXT,
  prd_submission_url VARCHAR(500),
  prd_submission_notes TEXT,
  prd_feedback TEXT,
  prd_revision_count INTEGER DEFAULT 0,
  prd_performance_metrics JSONB,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_proposal_deliverables_proposal FOREIGN KEY (prd_ip_id) REFERENCES influencer_proposals(ip_id) ON DELETE CASCADE,
  CONSTRAINT fk_proposal_deliverables_platform_deliverable FOREIGN KEY (prd_pd_id) REFERENCES platform_deliverables(pd_id) ON DELETE RESTRICT,
  -- constraints
  CONSTRAINT chk_quantity_positive CHECK (prd_quantity > 0),
  CONSTRAINT chk_price_positive CHECK (prd_agreed_price >= 0),
  CONSTRAINT chk_revision_count CHECK (prd_revision_count >= 0)
);

---------- table shopping_cart ----------
CREATE TYPE cart_item_status_enum AS ENUM ('active', 'removed', 'converted');

CREATE TABLE shopping_cart (
  sc_id SERIAL PRIMARY KEY,
  sc_cl_id INTEGER NOT NULL,
  sc_inf_id INTEGER NOT NULL,
  sc_status cart_item_status_enum NOT NULL DEFAULT 'active',
  sc_estimated_total DECIMAL(15,2) DEFAULT 0,
  sc_notes TEXT,
  sc_attachments JSONB,
  sc_added_by INTEGER NOT NULL,
  sc_converted_to_proposal_id INTEGER,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_shopping_cart_list FOREIGN KEY (sc_cl_id) REFERENCES campaign_lists(cl_id) ON DELETE CASCADE,
  CONSTRAINT fk_shopping_cart_influencer FOREIGN KEY (sc_inf_id) REFERENCES influencers(inf_id) ON DELETE CASCADE,
  CONSTRAINT fk_shopping_cart_added_by FOREIGN KEY (sc_added_by) REFERENCES users(u_id) ON DELETE RESTRICT,
  CONSTRAINT fk_shopping_cart_proposal FOREIGN KEY (sc_converted_to_proposal_id) REFERENCES influencer_proposals(ip_id) ON DELETE SET NULL,
  -- constraints
  CONSTRAINT uk_shopping_cart UNIQUE (sc_cl_id, sc_inf_id)
);

---------- table cart_deliverable_items ----------
CREATE TABLE cart_deliverable_items (
  cdi_id SERIAL PRIMARY KEY,
  cdi_sc_id INTEGER NOT NULL,
  cdi_pd_id INTEGER NOT NULL,
  cdi_quantity INTEGER NOT NULL DEFAULT 1,
  cdi_estimated_price DECIMAL(15,2) NOT NULL,
  cdi_scheduled_date DATE,
  cdi_special_requirements TEXT,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_cart_deliverable_items_cart FOREIGN KEY (cdi_sc_id) REFERENCES shopping_cart(sc_id) ON DELETE CASCADE,
  CONSTRAINT fk_cart_deliverable_items_deliverable FOREIGN KEY (cdi_pd_id) REFERENCES platform_deliverables(pd_id) ON DELETE RESTRICT,
  -- constraints
  CONSTRAINT uk_cart_deliverable_items UNIQUE (cdi_sc_id, cdi_pd_id),
  CONSTRAINT chk_cart_quantity_positive CHECK (cdi_quantity > 0),
  CONSTRAINT chk_cart_price_positive CHECK (cdi_estimated_price >= 0)
);

-- -------------------------
-- CAMPAIGN PERFORMANCE AND ANALYTICS
-- -------------------------

---------- table campaign_analytics ----------
CREATE TABLE campaign_analytics (
  ca_id SERIAL PRIMARY KEY,
  ca_c_id INTEGER NOT NULL,
  ca_date DATE NOT NULL,
  ca_total_reach BIGINT DEFAULT 0,
  ca_total_impressions BIGINT DEFAULT 0,
  ca_total_engagement BIGINT DEFAULT 0,
  ca_total_clicks BIGINT DEFAULT 0,
  ca_total_conversions BIGINT DEFAULT 0,
  ca_total_spend DECIMAL(15,2) DEFAULT 0,
  ca_cost_per_engagement DECIMAL(10,4) DEFAULT 0,
  ca_cost_per_click DECIMAL(10,4) DEFAULT 0,
  ca_cost_per_conversion DECIMAL(10,4) DEFAULT 0,
  ca_engagement_rate DECIMAL(5,2) DEFAULT 0,
  ca_click_through_rate DECIMAL(5,2) DEFAULT 0,
  ca_conversion_rate DECIMAL(5,2) DEFAULT 0,
  ca_roi DECIMAL(8,4) DEFAULT 0,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_campaign_analytics_campaign FOREIGN KEY (ca_c_id) REFERENCES campaigns(c_id) ON DELETE CASCADE,
  -- constraints
  CONSTRAINT uk_campaign_analytics_date UNIQUE (ca_c_id, ca_date)
);

---------- table deliverable_performance ----------
CREATE TABLE deliverable_performance (
  dp_id SERIAL PRIMARY KEY,
  dp_prd_id INTEGER NOT NULL,
  dp_platform_post_id VARCHAR(255),
  dp_post_url VARCHAR(500),
  dp_published_date TIMESTAMP WITH TIME ZONE,
  dp_reach BIGINT DEFAULT 0,
  dp_impressions BIGINT DEFAULT 0,
  dp_likes BIGINT DEFAULT 0,
  dp_comments BIGINT DEFAULT 0,
  dp_shares BIGINT DEFAULT 0,
  dp_saves BIGINT DEFAULT 0,
  dp_clicks BIGINT DEFAULT 0,
  dp_engagement_rate DECIMAL(5,2) DEFAULT 0,
  dp_sentiment_score DECIMAL(3,2),
  dp_brand_mention_count INTEGER DEFAULT 0,
  dp_hashtag_performance JSONB,
  dp_audience_demographics JSONB,
  dp_performance_grade VARCHAR(2),
  dp_last_updated TIMESTAMP WITH TIME ZONE DEFAULT current_timestamp,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_deliverable_performance_deliverable FOREIGN KEY (dp_prd_id) REFERENCES proposal_deliverables(prd_id) ON DELETE CASCADE,
  -- constraints
  CONSTRAINT uk_deliverable_performance_post UNIQUE (dp_prd_id, dp_platform_post_id)
);

-- -------------------------
-- FINANCIAL MANAGEMENT
-- -------------------------

---------- table invoices ----------
CREATE TYPE invoice_status_enum AS ENUM ('draft', 'sent', 'paid', 'overdue', 'cancelled');
CREATE TYPE payment_status_enum AS ENUM ('pending', 'processing', 'completed', 'failed', 'refunded');

CREATE TABLE invoices (
  inv_id SERIAL PRIMARY KEY,
  inv_number VARCHAR(50) NOT NULL,
  inv_ip_id INTEGER NOT NULL,
  inv_status invoice_status_enum NOT NULL DEFAULT 'draft',
  inv_amount DECIMAL(15,2) NOT NULL,
  inv_tax_amount DECIMAL(15,2) DEFAULT 0,
  inv_total_amount DECIMAL(15,2) NOT NULL,
  inv_currency VARCHAR(3) DEFAULT 'INR',
  inv_issue_date DATE NOT NULL,
  inv_due_date DATE NOT NULL,
  inv_payment_terms TEXT,
  inv_notes TEXT,
  inv_file_url VARCHAR(500),
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_invoices_proposal FOREIGN KEY (inv_ip_id) REFERENCES influencer_proposals(ip_id) ON DELETE RESTRICT,
  -- constraints
  CONSTRAINT uk_invoices_number UNIQUE (inv_number),
  CONSTRAINT chk_invoice_amounts CHECK (inv_amount >= 0 AND inv_tax_amount >= 0 AND inv_total_amount >= inv_amount),
  CONSTRAINT chk_invoice_dates CHECK (inv_due_date >= inv_issue_date)
);

---------- table payments ----------
CREATE TABLE payments (
  pay_id SERIAL PRIMARY KEY,
  pay_inv_id INTEGER NOT NULL,
  pay_amount DECIMAL(15,2) NOT NULL,
  pay_currency VARCHAR(3) DEFAULT 'INR',
  pay_status payment_status_enum NOT NULL DEFAULT 'pending',
  pay_method VARCHAR(50),
  pay_transaction_id VARCHAR(255),
  pay_reference_number VARCHAR(255),
  pay_processed_date TIMESTAMP WITH TIME ZONE,
  pay_gateway_response JSONB,
  pay_notes TEXT,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_payments_invoice FOREIGN KEY (pay_inv_id) REFERENCES invoices(inv_id) ON DELETE RESTRICT,
  -- constraints
  CONSTRAINT chk_payment_amount CHECK (pay_amount > 0)
);

-- -------------------------
-- COMMUNICATION AND NOTIFICATIONS
-- -------------------------

---------- table communication_threads ----------
CREATE TYPE thread_type_enum AS ENUM ('campaign_discussion', 'proposal_negotiation', 'deliverable_feedback', 'support_ticket', 'general');
CREATE TYPE thread_status_enum AS ENUM ('open', 'closed', 'archived');

CREATE TABLE communication_threads (
  ct_id SERIAL PRIMARY KEY,
  ct_subject VARCHAR(255) NOT NULL,
  ct_type thread_type_enum NOT NULL,
  ct_status thread_status_enum NOT NULL DEFAULT 'open',
  ct_c_id INTEGER,
  ct_ip_id INTEGER,
  ct_prd_id INTEGER,
  ct_created_by INTEGER NOT NULL,
  ct_last_message_at TIMESTAMP WITH TIME ZONE,
  ct_participant_count INTEGER DEFAULT 0,
  ct_unread_count INTEGER DEFAULT 0,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_communication_threads_campaign FOREIGN KEY (ct_c_id) REFERENCES campaigns(c_id) ON DELETE CASCADE,
  CONSTRAINT fk_communication_threads_proposal FOREIGN KEY (ct_ip_id) REFERENCES influencer_proposals(ip_id) ON DELETE CASCADE,
  CONSTRAINT fk_communication_threads_deliverable FOREIGN KEY (ct_prd_id) REFERENCES proposal_deliverables(prd_id) ON DELETE CASCADE,
  CONSTRAINT fk_communication_threads_creator FOREIGN KEY (ct_created_by) REFERENCES users(u_id) ON DELETE RESTRICT
);

---------- table thread_messages ----------
CREATE TYPE message_type_enum AS ENUM ('text', 'file', 'system', 'notification');

CREATE TABLE thread_messages (
  tm_id SERIAL PRIMARY KEY,
  tm_ct_id INTEGER NOT NULL,
  tm_sender_id INTEGER NOT NULL,
  tm_message TEXT NOT NULL,
  tm_type message_type_enum NOT NULL DEFAULT 'text',
  tm_attachments JSONB,
  tm_is_read BOOLEAN NOT NULL DEFAULT false,
  tm_read_at TIMESTAMP WITH TIME ZONE,
  tm_is_edited BOOLEAN NOT NULL DEFAULT false,
  tm_edited_at TIMESTAMP WITH TIME ZONE,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_thread_messages_thread FOREIGN KEY (tm_ct_id) REFERENCES communication_threads(ct_id) ON DELETE CASCADE,
  CONSTRAINT fk_thread_messages_sender FOREIGN KEY (tm_sender_id) REFERENCES users(u_id) ON DELETE RESTRICT
);

---------- table thread_participants ----------
CREATE TYPE participant_role_enum AS ENUM ('admin', 'member', 'observer');

CREATE TABLE thread_participants (
  tp_id SERIAL PRIMARY KEY,
  tp_ct_id INTEGER NOT NULL,
  tp_u_id INTEGER NOT NULL,
  tp_role participant_role_enum NOT NULL DEFAULT 'member',
  tp_joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  tp_last_read_at TIMESTAMP WITH TIME ZONE,
  tp_is_active BOOLEAN NOT NULL DEFAULT true,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_thread_participants_thread FOREIGN KEY (tp_ct_id) REFERENCES communication_threads(ct_id) ON DELETE CASCADE,
  CONSTRAINT fk_thread_participants_user FOREIGN KEY (tp_u_id) REFERENCES users(u_id) ON DELETE CASCADE,
  -- constraints
  CONSTRAINT uk_thread_participants UNIQUE (tp_ct_id, tp_u_id)
);

-- -------------------------
-- SYSTEM LOGS AND AUDIT TRAIL
-- -------------------------

---------- table activity_logs ----------
CREATE TYPE activity_type_enum AS ENUM ('create', 'update', 'delete', 'login', 'logout', 'export', 'import', 'approve', 'reject');

CREATE TABLE activity_logs (
  al_id SERIAL PRIMARY KEY,
  al_user_id INTEGER,
  al_activity_type activity_type_enum NOT NULL,
  al_table_name VARCHAR(100),
  al_record_id INTEGER,
  al_description TEXT NOT NULL,
  al_old_values JSONB,
  al_new_values JSONB,
  al_ip_address INET,
  al_user_agent TEXT,
  al_session_id VARCHAR(255),
  -- audit and logs
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_activity_logs_user FOREIGN KEY (al_user_id) REFERENCES users(u_id) ON DELETE SET NULL
);

-- -------------------------
-- INDEXES FOR PERFORMANCE
-- -------------------------

-- User-related indexes
CREATE INDEX idx_users_email ON users(u_email);
CREATE INDEX idx_users_organization ON users(u_o_id);
CREATE INDEX idx_users_team ON users(u_t_id);
CREATE INDEX idx_users_status ON users(u_status);
CREATE INDEX idx_users_last_login ON users(u_last_login);

-- Campaign-related indexes
CREATE INDEX idx_campaigns_brand ON campaigns(c_b_id);
CREATE INDEX idx_campaigns_status ON campaigns(c_status);
CREATE INDEX idx_campaigns_dates ON campaigns(c_start_date, c_end_date);
CREATE INDEX idx_campaigns_created_at ON campaigns(created_at);

-- Influencer-related indexes
CREATE INDEX idx_influencers_status ON influencers(inf_status);
CREATE INDEX idx_influencers_location ON influencers(inf_location);
CREATE INDEX idx_influencers_platform ON influencers(inf_primary_platform_id);
CREATE INDEX idx_influencer_metrics_followers ON influencer_platform_metrics(ipm_followers_count);
CREATE INDEX idx_influencer_metrics_engagement ON influencer_platform_metrics(ipm_engagement_rate);

-- Proposal-related indexes
CREATE INDEX idx_proposals_status ON influencer_proposals(ip_status);
CREATE INDEX idx_proposals_list ON influencer_proposals(ip_cl_id);
CREATE INDEX idx_proposals_influencer ON influencer_proposals(ip_inf_id);
CREATE INDEX idx_proposals_created_at ON influencer_proposals(created_at);

-- Deliverable-related indexes
CREATE INDEX idx_deliverables_status ON proposal_deliverables(prd_status);
CREATE INDEX idx_deliverables_scheduled_date ON proposal_deliverables(prd_scheduled_date);
CREATE INDEX idx_deliverables_proposal ON proposal_deliverables(prd_ip_id);

-- Performance indexes
CREATE INDEX idx_campaign_analytics_date ON campaign_analytics(ca_date);
CREATE INDEX idx_campaign_analytics_campaign ON campaign_analytics(ca_c_id);
CREATE INDEX idx_deliverable_performance_published ON deliverable_performance(dp_published_date);

-- Activity logs indexes
CREATE INDEX idx_activity_logs_user ON activity_logs(al_user_id);
CREATE INDEX idx_activity_logs_type ON activity_logs(al_activity_type);
CREATE INDEX idx_activity_logs_created_at ON activity_logs(created_at);
CREATE INDEX idx_activity_logs_table_record ON activity_logs(al_table_name, al_record_id);

-- JSON indexes for better query performance
CREATE INDEX idx_campaigns_target_locations ON campaigns USING GIN(c_target_locations);
CREATE INDEX idx_campaigns_target_interests ON campaigns USING GIN(c_target_interests);
CREATE INDEX idx_influencers_categories ON influencers USING GIN(inf_categories);
CREATE INDEX idx_influencers_niches ON influencers USING GIN(inf_niches);
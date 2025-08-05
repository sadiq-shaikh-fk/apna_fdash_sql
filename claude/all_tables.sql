-- ------------------------------------------------------------------------------------------------------------------
-- *******************************************INITIAL SETUP - Core Tables *******************************************
-- ------------------------------------------------------------------------------------------------------------------

-- ---------- table gods_eye ----------
-- CREATE TABLE gods_eye (
--   ge_id BIGSERIAL PRIMARY KEY,
--   ge_name VARCHAR(255) NOT NULL,
--   ge_password VARCHAR(255) NOT NULL,
--   ge_is_active BOOLEAN NOT NULL DEFAULT true,
--   ge_last_login TIMESTAMP WITH TIME ZONE,
--   -- audit and logs
--   created_by VARCHAR(100) NOT NULL DEFAULT current_user,
--   created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
--   modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
--   modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
--   -- soft delete
--   is_deleted BOOLEAN NOT NULL DEFAULT false,
--   deleted_at TIMESTAMP WITH TIME ZONE,
--   deleted_by VARCHAR(100),
--   -- constraints
--   CONSTRAINT uk_gods_eye_name UNIQUE (ge_name)
-- );

---------- table plans ----------
CREATE TYPE plan_name_enum AS ENUM ('free forever','starter','pro','enterprise');

CREATE TABLE plans (
  plan_id BIGSERIAL PRIMARY KEY,
  plan_name plan_name_enum NOT NULL UNIQUE,
  plan_base_price_inr numeric(12,2) NOT NULL,  
  seats INTEGER NOT NULL DEFAULT 0,       -- number of seats included in the plan
  brands INTEGER NOT NULL DEFAULT 0,      -- list of brands included in the plan
  campaigns INTEGER NOT NULL DEFAULT 0,   -- list of campaigns included in the plan
  ai_actions INTEGER NOT NULL DEFAULT 0,  -- list of AI actions included in the plan
  plan_overage jsonb NOT NULL,    -- {api_per_1k: 25, ai_sec: 3, storage_gb: 10}
-- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- soft delete
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by VARCHAR(100),
  -- constraints
  CONSTRAINT uk_plan_name UNIQUE (plan_name)
);

---------- table plan_features ----------
CREATE TABLE plan_features (
  pf_id BIGSERIAL PRIMARY KEY,
  pf_plan_id INTEGER NOT NULL,
  pf_feature_value TEXT NOT NULL,
  pf_is_enabled BOOLEAN NOT NULL DEFAULT true,
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
  CONSTRAINT fk_plan_features_plan FOREIGN KEY (pf_plan_id) REFERENCES plans(plan_id) ON DELETE CASCADE
);

---------- table organizations (for white labelled products only) ----------
CREATE TYPE o_type_enum AS ENUM ('agency', 'brand');
CREATE TYPE o_status_enum AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE o_cluster_affinity_enum AS ENUM ('core','techm_dedicated');

CREATE TABLE organizations (
  o_id                    BIGSERIAL PRIMARY KEY,
  o_name                  VARCHAR(255) NOT NULL,
  o_slug                  CITEXT NOT NULL UNIQUE,  -- URL / sub-domain key
  o_type                  o_type_enum NOT NULL,
  o_status                o_status_enum NOT NULL,
  o_cluster_affinity      o_cluster_affinity_enum DEFAULT 'core',
  o_address               TEXT,
  o_contact_email         VARCHAR(255),
  o_contact_phone         VARCHAR(20),
  o_website               VARCHAR(255),
  o_logo_url              VARCHAR(500),
  o_payment_terms         JSONB,  -- payment terms for the organization
  o_tax_info              JSONB,  -- tax information for the organization
  o_support_info          JSONB,  -- support information for the organization
  o_legal_info            JSONB,  -- legal information for the organization
  -- audit and logs
  created_by              VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by             VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at             TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- soft delete
  is_deleted              BOOLEAN NOT NULL DEFAULT false,
  deleted_at              TIMESTAMP WITH TIME ZONE,
  deleted_by              VARCHAR(100),
  -- constraints
  CONSTRAINT uk_organizations_name UNIQUE (o_name),
  CONSTRAINT chk_contact_email_format CHECK (o_contact_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

---------- table tenants ----------
CREATE TYPE tenant_type_enum AS ENUM ('agency','brand');
CREATE TYPE portal_mode_enum AS ENUM ('agency','brand','brand_lite');
CREATE TYPE cluster_affinity_enum AS ENUM ('core','techm_dedicated');

CREATE TABLE tenants (
  t_id                    BIGSERIAL PRIMARY KEY,
  t_name                  VARCHAR(255) NOT NULL,
  t_slug                  CITEXT, -- sub-path e.g. /asus
  t_o_id                  INTEGER NOT NULL,    -- foreign key to 'o_id' from organizations table
  t_parent_t_id           INTEGER,      -- self-referencing foreign key for hierarchical structure
  t_type                  tenant_type_enum NOT NULL,
  t_portal_mode           portal_mode_enum NOT NULL DEFAULT 'brand',
  t_cluster_affinity      cluster_affinity_enum DEFAULT 'core',
  t_status                TEXT NOT NULL DEFAULT 'active',
  t_theme                 JSONB,
  t_plan_id               INTEGER NOT NULL DEFAULT 1,  -- foreign key to 'plan_id' from plans table
  t_mrr                   NUMERIC(12,2) NOT NULL DEFAULT 0,
  t_trial_expires_at      TIMESTAMP WITH TIME ZONE,  -- when the tenant's trial expires
  t_payment_terms         JSONB,  -- payment terms for the tenant
  t_tax_info              JSONB,  -- tax information for the tenant
  t_support_info          JSONB,  -- support information for the tenant
  t_legal_info            JSONB,  -- legal information for the tenant
  t_settings              JSONB,  -- additional settings for the tenant
  -- audit and logs
  created_by              VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by             VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at             TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- soft delete
  is_deleted              BOOLEAN NOT NULL DEFAULT false,
  deleted_at              TIMESTAMP WITH TIME ZONE,
  deleted_by              VARCHAR(100),
  -- Foreign key constraints
  CONSTRAINT fk_tenants_t_o_id FOREIGN KEY (t_o_id) REFERENCES organizations(o_id) ON DELETE RESTRICT,
  CONSTRAINT fk_tenants_t_parent_t_id FOREIGN KEY (t_parent_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,
  CONSTRAINT fk_tenants_t_plan_id FOREIGN KEY (t_plan_id) REFERENCES plans(plan_id) ON DELETE RESTRICT,
  -- constraints
  CONSTRAINT uq_tenant_name_per_org UNIQUE (t_o_id, t_name),
  CONSTRAINT uq_tenant_slug UNIQUE (t_slug)
);

---------- table subscriptions ----------
CREATE TYPE subscription_status_enum AS ENUM ('active', 'cancelled', 'paused', 'trialing', 'expired');

CREATE TABLE subscriptions (
  sub_id                      BIGSERIAL PRIMARY KEY,
  sub_t_id                    INTEGER NOT NULL,     -- foreign key to 'o_id' from organizations table
  sub_plan_id                 INTEGER NOT NULL,  -- foreign key to 'plan_id' from plans table
  sub_status                  subscription_status_enum NOT NULL DEFAULT 'active',
  sub_start_date              TIMESTAMP WITH TIME ZONE NOT NULL,
  sub_end_date                TIMESTAMP WITH TIME ZONE,
  sub_is_trial                BOOLEAN DEFAULT false,
  sub_gateway                 VARCHAR(50), -- 'stripe' or 'razorpay'
  sub_gateway_customer_id     VARCHAR(100), -- Stripe customer ID or Razorpay contact ID
  sub_gateway_subscription_id VARCHAR(100), -- Stripe sub ID / Razorpay sub ID
  sub_notes                   TEXT,
-- audit and logs
  created_by                  VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by                 VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at                 TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- soft delete
  is_deleted                  BOOLEAN NOT NULL DEFAULT false,
  deleted_at                  TIMESTAMP WITH TIME ZONE,
  deleted_by                  VARCHAR(100),
  -- Foreign key constraints
  CONSTRAINT fk_subscriptions_sub_o_id FOREIGN KEY (sub_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,
  CONSTRAINT fk_subscriptions_sub_plan_id FOREIGN KEY (sub_plan_id) REFERENCES plans(plan_id) ON DELETE RESTRICT
);

---------- table invoices ----------
CREATE TYPE invoice_status_enum AS ENUM ('pending','sent','paid','failed');

CREATE TABLE invoices (
  i_id BIGSERIAL PRIMARY KEY,
  i_t_id INTEGER NOT NULL,
  i_month DATE NOT NULL,
  i_invoice_json JSONB NOT NULL,  -- PDF + line items blob
  i_status invoice_status_enum DEFAULT 'pending',
  i_total_inr NUMERIC(14,2) NOT NULL,
  i_issued_at TIMESTAMP WITH TIME ZONE DEFAULT current_timestamp,
-- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- soft delete
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by VARCHAR(100),
  -- Foreign key
  CONSTRAINT fk_invoices_i_t_id FOREIGN KEY (i_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

---------- table payments ----------
CREATE TYPE payment_status_enum AS ENUM ('initiated', 'success', 'failed', 'refunded');
CREATE TYPE escrow_status_enum AS ENUM ('held', 'released', 'refunded');

CREATE TABLE payments (
  pay_id BIGSERIAL PRIMARY KEY,
  pay_sub_id INTEGER REFERENCES subscriptions(sub_id) ON DELETE SET NULL,
  pay_t_id INTEGER NOT NULL,
  pay_amount_inr NUMERIC(14,2) NOT NULL,
  pay_currency VARCHAR(10) DEFAULT 'INR',
  pay_status payment_status_enum NOT  NULL DEFAULT 'initiated',
  pay_escrow_status escrow_status_enum,  -- nullable for now
  pay_gateway VARCHAR(50),               -- 'stripe' or 'razorpay'
  pay_gateway_payment_id VARCHAR(100),
  pay_gateway_order_id VARCHAR(100),
  pay_invoice_id INTEGER REFERENCES invoices(i_id),
  pay_timestamp TIMESTAMP WITH TIME ZONE DEFAULT current_timestamp,
  pay_meta JSONB, -- webhook data
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by VARCHAR(100),
  -- Foreign Key Constraints
  CONSTRAINT fk_payments_pay_sub_id FOREIGN KEY (pay_sub_id) REFERENCES subscriptions(sub_id) ON DELETE SET NULL,
  CONSTRAINT fk_payments_pay_t_id FOREIGN KEY (pay_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,
  -- Unique constraint
  CONSTRAINT uk_payments_gateway_payment_id UNIQUE (pay_gateway, pay_gateway_payment_id)
);

---------- table usage_meters ----------
CREATE TABLE usage_meters (
  um_id BIGSERIAL PRIMARY KEY,
  um_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
  um_month DATE NOT NULL,
  um_api_calls BIGINT DEFAULT 0,
  um_ai_seconds BIGINT DEFAULT 0,
  um_storage_mb BIGINT DEFAULT 0,
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
  CONSTRAINT fk_usage_meters_um_t_id FOREIGN KEY (um_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,
  -- constraints
  CONSTRAINT uk_usage_meters_month UNIQUE (um_t_id, um_month)  -- unique constraint for each tenant per month
);

---------- table teams ----------
CREATE TYPE team_status_enum AS ENUM ('active', 'inactive');

CREATE TABLE teams (
  tm_id BIGSERIAL PRIMARY KEY,
  tm_name VARCHAR(255) NOT NULL,
  tm_description TEXT,
  tm_status team_status_enum NOT NULL DEFAULT 'active',
  tm_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
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
  CONSTRAINT fk_teams_tm_t_id FOREIGN KEY (tm_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

---------- table roles ----------
CREATE TABLE roles (
  r_id BIGSERIAL PRIMARY KEY,
  r_name VARCHAR(100) NOT NULL,
  r_description TEXT,
  r_t_id INTEGER,    -- foreign key to 't_id' from tenants table
  r_is_system_role BOOLEAN NOT NULL DEFAULT false,
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
  CONSTRAINT fk_roles_r_t_id FOREIGN KEY (r_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

---------- table app_users ----------
CREATE TYPE user_type_enum AS ENUM ('general', 'agency', 'brand');
CREATE TYPE user_status_enum AS ENUM ('active', 'inactive', 'suspended', 'pending_verification');

CREATE TABLE app_users (
  u_id BIGSERIAL PRIMARY KEY,
  u_id_auth UUID,
  u_first_name VARCHAR(100),
  u_last_name VARCHAR(100),
  --u_email VARCHAR(255) NOT NULL,
  --u_phone_number VARCHAR(20) NOT NULL,
  --u_password VARCHAR(255) NOT NULL,  -- hashed password
  --u_oauth_token VARCHAR(500),    -- not null from front end
  --u_oauth_provider VARCHAR(50),  -- Google, Facebook, etc.
  u_is_authorized BOOLEAN NOT NULL DEFAULT false,    -- boolean for invited members only to workspace
  u_user_type user_type_enum NOT NULL DEFAULT 'general',
  u_status user_status_enum NOT NULL DEFAULT 'pending_verification',
  u_t_id INTEGER,    -- foreign key to 't_id' from tenants table
  u_tm_id INTEGER,    -- foreign key to 'tm_id' from teams table
  u_r_id INTEGER,    -- foreign key to 'r_id' from roles table
  u_is_workspace_admin BOOLEAN NOT NULL DEFAULT false,
  u_last_login TIMESTAMP WITH TIME ZONE,
  u_locked_until TIMESTAMP WITH TIME ZONE,
  u_email_verified_at TIMESTAMP WITH TIME ZONE,
  u_phone_verified_at TIMESTAMP WITH TIME ZONE,
  u_avatar_url VARCHAR(500),
  u_timezone VARCHAR(50) DEFAULT 'UTC',
  u_is_gods_eye BOOLEAN NOT NULL DEFAULT false,  -- for super admin
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
  CONSTRAINT fk_users_u_id_auth FOREIGN KEY (u_id_auth) REFERENCES auth.users(id) ON DELETE CASCADE,  -- when using nhost
  CONSTRAINT fk_users_u_tm_id FOREIGN KEY (u_tm_id) REFERENCES teams(tm_id) ON DELETE RESTRICT,
  CONSTRAINT fk_users_u_o_id FOREIGN KEY (u_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,
  CONSTRAINT fk_users_u_r_id FOREIGN KEY (u_r_id) REFERENCES roles(r_id) ON DELETE RESTRICT
  -- constraints
  -- CONSTRAINT uk_users_email UNIQUE (u_email),
  -- CONSTRAINT uk_users_phone UNIQUE (u_phone_number)
);

---------- table user_invites ----------
CREATE TYPE ui_invite_status_enum AS ENUM ('pending', 'accepted', 'expired', 'cancelled');

CREATE TABLE user_invites (
  ui_id BIGSERIAL PRIMARY KEY,
  ui_token VARCHAR(255) NOT NULL,
  ui_status ui_invite_status_enum NOT NULL DEFAULT 'pending', -- checking the status of the invite
  ui_sent_by_u_id INTEGER,                          -- send by a user of super_admin
  ui_sent_to_email VARCHAR(255) NOT NULL,           -- send to a user of user_agency
  ui_expiry_at TIMESTAMP WITH TIME ZONE NOT NULL,   -- current_timestamp eg:+ 12 days
  ui_redeemed_at TIMESTAMP WITH TIME ZONE,          -- when the user has accepted the invite
  ui_r_id INTEGER,          -- foreign key to 'r_id' from roles table
  ui_t_id INTEGER,          -- foreign key to 't_id' from tenants table
  ui_tm_id INTEGER,          -- foreign key to 'tm_id' from teams table
  ui_message TEXT,          -- message to the user
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
  CONSTRAINT fk_user_invites_ui_sent_by_u_id FOREIGN KEY (ui_sent_by_u_id) REFERENCES app_users(u_id) ON DELETE RESTRICT,
  CONSTRAINT fk_user_invites_ui_r_id FOREIGN KEY (ui_r_id) REFERENCES roles(r_id) ON DELETE RESTRICT,
  CONSTRAINT fk_user_invites_ui_o_id FOREIGN KEY (ui_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,
  CONSTRAINT fk_user_invites_ui_t_id FOREIGN KEY (ui_tm_id) REFERENCES teams(tm_id) ON DELETE RESTRICT,
  -- constraints
  CONSTRAINT uk_user_invites_token UNIQUE (ui_token),
  CONSTRAINT chk_email_format CHECK (ui_sent_to_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
  CONSTRAINT chk_expiry_future CHECK (ui_expiry_at > created_at)
);

-- ------------------------------------------------------------------------------------------------------------------
-- **************************************** RBAC (Role-Based Access Control) ****************************************
-- ------------------------------------------------------------------------------------------------------------------

---------- table modules ----------
CREATE TABLE modules (
  m_id BIGSERIAL PRIMARY KEY,
  m_name VARCHAR(100) NOT NULL,
  m_description TEXT,
  m_is_active BOOLEAN NOT NULL DEFAULT true,
  m_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- soft delete
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by VARCHAR(100),
  -- constraints
  CONSTRAINT uk_modules_name UNIQUE (m_name),
  -- Foreign key constraints
  CONSTRAINT fk_modules_m_t_id FOREIGN KEY (m_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

---------- table features ----------
CREATE TABLE features (
  f_id BIGSERIAL PRIMARY KEY,
  f_name VARCHAR(100) NOT NULL,
  f_description TEXT,
  f_m_id INTEGER NOT NULL,
  f_is_active BOOLEAN NOT NULL DEFAULT true,
  f_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
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
  CONSTRAINT fk_features_f_m_id FOREIGN KEY (f_m_id) REFERENCES modules(m_id) ON DELETE RESTRICT,
  CONSTRAINT fk_features_f_t_id FOREIGN KEY (f_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

---------- table access ----------
CREATE TABLE access (
  a_id BIGSERIAL PRIMARY KEY,
  a_name VARCHAR(50) NOT NULL,
  a_description TEXT,
  a_is_active BOOLEAN NOT NULL DEFAULT true,
  a_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
  -- audit and logs 
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- soft delete
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by VARCHAR(100),
  -- constraints
  CONSTRAINT uk_access_name UNIQUE (a_name),
  -- Foreign key constraints
  CONSTRAINT fk_access_a_t_id FOREIGN KEY (a_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

---------- table roles_assignment ----------
CREATE TABLE roles_assignment (
  ra_id BIGSERIAL PRIMARY KEY,
  ra_r_id INTEGER NOT NULL,     -- role id fk
  ra_m_id INTEGER NOT NULL,     -- module id fk
  ra_f_id INTEGER NOT NULL,     -- feature id fk
  ra_a_id INTEGER NOT NULL,     -- access id fk
  ra_is_active BOOLEAN NOT NULL DEFAULT true,
  ra_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
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
  CONSTRAINT fk_role_permissions_role FOREIGN KEY (ra_r_id) REFERENCES roles(r_id) ON DELETE RESTRICT,
  CONSTRAINT fk_role_permissions_module FOREIGN KEY (ra_m_id) REFERENCES modules(m_id) ON DELETE RESTRICT,
  CONSTRAINT fk_role_permissions_feature FOREIGN KEY (ra_f_id) REFERENCES features(f_id) ON DELETE RESTRICT,
  CONSTRAINT fk_role_permissions_access FOREIGN KEY (ra_a_id) REFERENCES access(a_id) ON DELETE RESTRICT,
  CONSTRAINT fk_role_permissions_tenant FOREIGN KEY (ra_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

-- ------------------------------------------------------------------------------------------------------------------
-- ***************************************** IDM PAGE - FILTERS AND SHARING *****************************************
-- ------------------------------------------------------------------------------------------------------------------

---------- table filters ----------
CREATE TYPE filter_type_enum AS ENUM ('public', 'private', 'shared');

CREATE TABLE filters (
  f_id BIGSERIAL PRIMARY KEY,
  f_name VARCHAR(255) NOT NULL,
  f_type filter_type_enum NOT NULL DEFAULT 'private',
  f_created_by INTEGER NOT NULL,  -- filter created by the user's id
  f_metadata JSONB NOT NULL,      -- stores the filter in key-value 
  f_is_active BOOLEAN NOT NULL DEFAULT true,
  f_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
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
  CONSTRAINT fk_filters_created_by FOREIGN KEY (f_created_by) REFERENCES app_users(u_id) ON DELETE RESTRICT,
  CONSTRAINT fk_filters_tenant FOREIGN KEY (f_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,
  -- constraints
  CONSTRAINT uk_filters_name_user UNIQUE (f_name)
);

---------- table filter_shares ----------
CREATE TABLE filter_shares (
  fs_id BIGSERIAL PRIMARY KEY,
  fs_f_id INTEGER NOT NULL,
  fs_shared_with INTEGER NOT NULL,
  fs_access_level INTEGER NOT NULL,
  fs_is_active BOOLEAN NOT NULL DEFAULT true,
  fs_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
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
  CONSTRAINT fk_filter_shares_filter FOREIGN KEY (fs_f_id) REFERENCES filters(f_id) ON DELETE RESTRICT,
  CONSTRAINT fk_filter_shares_user FOREIGN KEY (fs_shared_with) REFERENCES app_users(u_id) ON DELETE RESTRICT,
  CONSTRAINT fk_filter_shares_access FOREIGN KEY (fs_access_level) REFERENCES access(a_id) ON DELETE RESTRICT,
  CONSTRAINT fk_filter_shares_tenant FOREIGN KEY (fs_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

-- ------------------------------------------------------------------------------------------------------------------
-- ************************************************* BRANDS SECTION *************************************************
-- ------------------------------------------------------------------------------------------------------------------

---------- table brands ----------
CREATE TYPE brand_status_enum AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE company_size_enum AS ENUM ('startup', 'small', 'medium', 'large', 'enterprise');

CREATE TABLE brands (
  b_id                  BIGSERIAL PRIMARY KEY,
  b_name                VARCHAR(255) NOT NULL,
  b_legal_name          VARCHAR(255),
  b_status              brand_status_enum,
  b_logo_url            VARCHAR(500),
  b_website             VARCHAR(500),
  b_linkedin_url        VARCHAR(500),
  b_company_size        VARCHAR(100),   -- company_size_enum values
  b_industry            VARCHAR(100),   -- drop down enum values
  b_market_cap_range    VARCHAR(50),    -- drop down enum values
  b_values              TEXT,
  b_messaging           TEXT,
  b_brand_identity      TEXT,
  b_detailed_summary    TEXT,
  b_tax_info            VARCHAR(100),
  b_payment_terms       TEXT,
  b_o_id                INTEGER NOT NULL, -- foreign key to 'o_id' from organizations table
  b_t_id                INTEGER, -- foreign key to 't_id' from tenants table
  b_parent_t_id         INTEGER, -- self-referencing foreign key for hierarchical structure
  -- audit and logs
  created_by            VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by           VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- soft delete
  is_deleted            BOOLEAN NOT NULL DEFAULT false,
  deleted_at            TIMESTAMP WITH TIME ZONE,
  deleted_by            VARCHAR(100),
  -- constraints
  CONSTRAINT uk_brands_name UNIQUE (b_name, b_t_id),  -- unique brand name per tenant
  -- Foreign key constraints
  CONSTRAINT fk_brands_b_o_id FOREIGN KEY (b_o_id) REFERENCES organizations(o_id) ON DELETE RESTRICT,
  CONSTRAINT fk_brands_b_t_id FOREIGN KEY (b_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,
  CONSTRAINT fk_brands_b_parent_t_id FOREIGN KEY (b_parent_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

---------- table brand_products_services ----------
CREATE TABLE brand_products_services (
  bps_id BIGSERIAL PRIMARY KEY,
  bps_b_id INTEGER NOT NULL,
  bps_name VARCHAR(255) NOT NULL,
  bps_description TEXT,
  bps_category VARCHAR(100),
  bps_price_range VARCHAR(50),
  bps_is_active BOOLEAN NOT NULL DEFAULT true,
  bps_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
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
  CONSTRAINT fk_brand_products_services_bps_b_id FOREIGN KEY (bps_b_id) REFERENCES brands(b_id) ON DELETE RESTRICT,
  CONSTRAINT fk_brand_products_services_bps_t_id FOREIGN KEY (bps_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

---------- table brand_competitors ----------
CREATE TYPE competitor_type_enum AS ENUM ('direct', 'indirect');

CREATE TABLE brand_competitors (
  bc_id BIGSERIAL PRIMARY KEY,
  bc_b_id INTEGER NOT NULL,
  bc_competitor_name VARCHAR(255) NOT NULL,
  bc_type competitor_type_enum NOT NULL,
  bc_market_share VARCHAR(50),
  bc_strengths TEXT,
  bc_weaknesses TEXT,
  bc_website VARCHAR(500),
  bc_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
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
  CONSTRAINT fk_brand_competitors_bc_b_id FOREIGN KEY (bc_b_id) REFERENCES brands(b_id) ON DELETE RESTRICT,
  CONSTRAINT fk_brand_competitors_bc_t_id FOREIGN KEY (bc_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

---------- table brand_poc ----------
CREATE TABLE brand_poc (
  bp_id BIGSERIAL PRIMARY KEY,
  bp_b_id INTEGER NOT NULL,
  bp_name VARCHAR(255) NOT NULL,
  bp_description TEXT,
  bp_contact_email VARCHAR(255) NOT NULL,
  bp_contact_phone VARCHAR(20) NOT NULL,
  bp_is_active BOOLEAN NOT NULL DEFAULT true,
  bp_t_id INTEGER NOT NULL,  -- foreign key to 't_id' from tenants table
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
  CONSTRAINT fk_brand_poc FOREIGN KEY (bp_b_id) REFERENCES brands(b_id) ON DELETE RESTRICT,
  CONSTRAINT fk_brand_poc_tenant FOREIGN KEY (bp_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

-- ------------------------------------------------------------------------------------------------------------------
-- ********************************************* DELIVERABLES SECTION ***********************************************
-- ------------------------------------------------------------------------------------------------------------------

---------- table platforms ----------
CREATE TABLE platforms (
  p_id BIGSERIAL PRIMARY KEY,
  p_name VARCHAR(100) NOT NULL,
  p_icon_url VARCHAR(500),
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- soft delete
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by VARCHAR(100),
  -- constraints
  CONSTRAINT uk_platforms_name UNIQUE (p_name)
);

---------- table deliverable_types ----------
CREATE TABLE deliverable_types (
  dt_id BIGSERIAL PRIMARY KEY,
  dt_name VARCHAR(100) NOT NULL,
  dt_description TEXT,
  dt_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
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
  CONSTRAINT fk_deliverable_types_tenant FOREIGN KEY (dt_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

---------- table platform_deliverables ----------
CREATE TABLE platform_deliverables (
  pd_id BIGSERIAL PRIMARY KEY,
  pd_p_id INTEGER NOT NULL,    -- foreign key to 'p_id' from platforms table
  pd_dt_id INTEGER NOT NULL,    -- foreign key to 'dt_id' from deliverable_types table
  pd_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
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
  CONSTRAINT fk_platform_deliverables_platform_pd_p_id FOREIGN KEY (pd_p_id) REFERENCES platforms(p_id) ON DELETE RESTRICT,
  CONSTRAINT fk_platform_deliverables_type_pd_dt_id FOREIGN KEY (pd_dt_id) REFERENCES deliverable_types(dt_id) ON DELETE RESTRICT,
  CONSTRAINT fk_platform_deliverables_tenant_pd_t_id FOREIGN KEY (pd_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

-- ------------------------------------------------------------------------------------------------------------------
-- ********************************************** INFLUENCERS SECTION ***********************************************
-- ------------------------------------------------------------------------------------------------------------------

---------- table influencers ----------
CREATE TYPE influencer_status_enum AS ENUM ('active', 'inactive', 'blacklisted', 'pending_verification');
CREATE TYPE verification_status_enum AS ENUM ('verified', 'unverified', 'pending');

CREATE TABLE influencers (
  inf_id BIGSERIAL PRIMARY KEY,
  inf_name VARCHAR(255) NOT NULL,
  inf_status influencer_status_enum NOT NULL DEFAULT 'pending_verification',
  inf_verification_status verification_status_enum NOT NULL DEFAULT 'unverified',
  inf_primary_platform_id INTEGER,
  inf_pk_id integer,
  inf_email VARCHAR(255),
  inf_phone1 VARCHAR(20),
  inf_phone2 VARCHAR(20),
  inf_gender VARCHAR(20),
  inf_city VARCHAR(200),
  inf_country VARCHAR(200),
  inf_billing_address TEXT,
  inf_shipping_address TEXT,
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
  CONSTRAINT fk_influencers_inf_primary_platform_id FOREIGN KEY (inf_primary_platform_id) REFERENCES platforms(p_id) ON DELETE RESTRICT
  -- constraints
  -- CONSTRAINT uk_inf_email UNIQUE (inf_email),
  -- CONSTRAINT uk_inf_phone1 UNIQUE (inf_phone1),
  -- CONSTRAINT uk_inf_phone2 UNIQUE (inf_phone2)
);

---------- table influencers_social ----------
CREATE TABLE influencer_socials (
  is_id BIGSERIAL PRIMARY KEY,
  is_inf_id INTEGER NOT NULL,    -- foreign key to 'inf_id' from influencers table
  is_platform_id INTEGER NOT NULL, -- foreign key to 'p_id' from platforms table
  is_pk_id INTEGER NOT NULL, -- primary key id for that platform for linking
  -- ========== inf_prices in another table ==========
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
  CONSTRAINT fk_influencers_socials_is_inf_id FOREIGN KEY (is_inf_id) REFERENCES influencers(inf_id) ON DELETE RESTRICT,
  CONSTRAINT fk_influencers_socials_is_platform_id FOREIGN KEY (is_platform_id) REFERENCES platforms(p_id) ON DELETE RESTRICT
);

---------- table influencer_primary_poc ----------
CREATE TABLE influencer_primary_poc(
  ipp_id BIGSERIAL PRIMARY KEY,
  ipp_inf_id INTEGER NOT NULL,    -- foreign key to 'inf_id' from influencers table
  ipp_name VARCHAR(100) NOT NULL,
  ipp_email VARCHAR(255) NOT NULL,
  ipp_phone1 VARCHAR(20) NOT NULL,
  ipp_phone2 VARCHAR(20),
  ipp_billing_address TEXT,
  ipp_shipping_address TEXT,
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
  CONSTRAINT fk_influencer_primary_poc FOREIGN KEY (ipp_inf_id) REFERENCES influencers(inf_id) ON DELETE RESTRICT,
  -- constraints
  CONSTRAINT uk_ipp_email UNIQUE (ipp_email),
  CONSTRAINT uk_ipp_phone1 UNIQUE (ipp_phone1),
  CONSTRAINT uk_ipp_phone2 UNIQUE (ipp_phone2)
);

---------- table influencer_mgmt_details ----------
CREATE TABLE influencer_mgmt (
  imd_id BIGSERIAL PRIMARY KEY,
  imd_inf_id INTEGER NOT NULL,    -- foreign key to 'inf_id' from influencers table
  imd_name VARCHAR(100) NOT NULL,
  imd_email VARCHAR(255) NOT NULL,
  imd_phone1 VARCHAR(20) NOT NULL,
  imd_phone2 VARCHAR(20),
  imd_billing_address TEXT,
  imd_shipping_address TEXT,
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
  CONSTRAINT fk_influencers_mgmt_imd_inf_id FOREIGN KEY (imd_inf_id) REFERENCES influencers(inf_id) ON DELETE RESTRICT,
  -- constraints
  CONSTRAINT uk_imd_email UNIQUE (imd_email),
  CONSTRAINT uk_imd_phone1 UNIQUE (imd_phone1),
  CONSTRAINT uk_imd_phone2 UNIQUE (imd_phone2)
);

---------- table influencer_prices ----------
CREATE TABLE influencer_prices (
  ip_id BIGSERIAL PRIMARY KEY,
  ip_inf_id INTEGER NOT NULL,    -- foreign key to 'inf_id' from influencers table
  ip_pd_id INTEGER,              --  foreign key to 'pd_id' from products table
  ip_currency VARCHAR(10) NOT NULL DEFAULT 'USD',
  ip_price BIGINT,
  ip_price_updated_at TIMESTAMP WITH TIME ZONE DEFAULT current_timestamp,
  ip_notes TEXT,
  ip_attachements JSONB, -- stores attachments in key-value pairs
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
  CONSTRAINT fk_influencer_prices_ip_inf_id FOREIGN KEY (ip_inf_id) REFERENCES influencers(inf_id) ON DELETE RESTRICT,
  CONSTRAINT fk_influencer_prices_ip_pd_id FOREIGN KEY (ip_pd_id) REFERENCES platform_deliverables(pd_id) ON DELETE RESTRICT
);

-- ------------------------------------------------------------------------------------------------------------------
-- *********************************************** CAMPAIGNS SECTION ************************************************
-- ------------------------------------------------------------------------------------------------------------------

---------- table campaigns ----------
CREATE TYPE campaign_status_enum AS ENUM ('draft', 'active', 'paused', 'completed', 'cancelled');
CREATE TYPE campaign_income_enum AS ENUM ('0-2LPA', '2-4LPA', '4-6LPA', '6-10LPA', '10-15LPA', '15-25LPA', '25LPA+');

CREATE TABLE campaigns (
  c_id BIGSERIAL PRIMARY KEY,
  c_b_id INTEGER NOT NULL,    -- foreign key to 'b_id' from brands table
  c_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
  c_status campaign_status_enum NOT NULL DEFAULT 'draft',

  -- Basic Campaign Info
  c_name VARCHAR(255) NOT NULL,
  c_budget DECIMAL,
  c_budget_currency VARCHAR(3) DEFAULT 'INR',
  c_p_id JSONB,
  c_start_date DATE NOT NULL,
  c_end_date DATE NOT NULL,
  c_products_services TEXT,
  c_business_objectives TEXT,

  -- Target Demographics
  c_target_age_from INTEGER,
  c_target_age_to INTEGER,
  c_target_gender VARCHAR(10),
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
  c_inf_followers_range VARCHAR(50), -- e.g. 'Nano', 'Micro', 'Macro'
  c_inf_engagement_rate VARCHAR(50), -- e.g. '0-2', '2-4', '4-6', '6-10', '10+'
  c_inf_genres JSONB,
  c_inf_niches JSONB,
  c_inf_locations JSONB,
  c_inf_age_from INTEGER,
  c_inf_age_to INTEGER,
  c_inf_languages JSONB,
  c_inf_primary_platform_id JSONB,
  c_inf_last_post_days VARCHAR(50), -- e.g. '7 days', '30 days', '90 days'
  c_inf_payment_terms VARCHAR(255),
  c_worked_with_promoted_competitors BOOLEAN DEFAULT false,
  c_previously_worked_with_brand BOOLEAN DEFAULT false,
  -- Point of Contact Information
  c_poc_brand_name VARCHAR(255),
  c_poc_brand_designation VARCHAR(100),
  c_poc_brand_email VARCHAR(255),
  c_poc_brand_phone VARCHAR(20),  
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
  CONSTRAINT fk_campaigns_brand FOREIGN KEY (c_b_id) REFERENCES brands(b_id) ON DELETE RESTRICT,
  CONSTRAINT fk_campaigns_tenant FOREIGN KEY (c_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,
  -- constraints
  CONSTRAINT uk_campaigns_name_brand UNIQUE (c_name),
  CONSTRAINT chk_campaign_dates CHECK (c_end_date >= c_start_date),
  CONSTRAINT chk_target_age_range CHECK (c_target_age_from <= c_target_age_to),
  CONSTRAINT chk_inf_age_range CHECK (c_inf_age_from   <= c_inf_age_to)
);

---------- table campaign_poc ----------
CREATE TABLE campaign_poc (
  cp_id BIGSERIAL PRIMARY KEY,
  cp_c_id INTEGER NOT NULL,    -- foreign key to 'c_id' from campaigns table
  cp_u_id INTEGER NOT NULL,    -- foreign key to 'u_id' from app_users table
  cp_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
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
  CONSTRAINT fk_campaign_poc_cp_u_id FOREIGN KEY (cp_u_id) REFERENCES app_users(u_id) ON DELETE RESTRICT,
  CONSTRAINT fk_campaign_poc_cp_c_id FOREIGN KEY (cp_c_id) REFERENCES campaigns(c_id) ON DELETE RESTRICT,
  CONSTRAINT fk_campaign_poc_cp_t_id FOREIGN KEY (cp_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

---------- table campaign_objectives ----------
CREATE TABLE campaign_objectives (
  co_id BIGSERIAL PRIMARY KEY,
  co_c_id INTEGER NOT NULL,
  co_objective TEXT NOT NULL,
  co_kpi TEXT NOT NULL,
  co_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
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
  CONSTRAINT fk_campaign_objectives_campaign FOREIGN KEY (co_c_id) REFERENCES campaigns(c_id) ON DELETE RESTRICT,
  CONSTRAINT fk_campaign_objectives_tenant FOREIGN KEY (co_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

-- ------------------------------------------------------------------------------------------------------------------
-- ************************************ CAMPAIGN LISTS AND INFLUENCER SELECTION *************************************
-- ------------------------------------------------------------------------------------------------------------------

---------- table campaign_lists (FIXED SYNTAX ERROR) ----------
CREATE TABLE campaign_lists (
  cl_id BIGSERIAL PRIMARY KEY,
  cl_name VARCHAR(500) NOT NULL,
  cl_c_id INTEGER NOT NULL,     -- foreign key to 'c_id' from campaigns table
  cl_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,  -- FIXED: Removed extra 's'
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- soft delete
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by VARCHAR(100),
  -- Foreign key constraints
  CONSTRAINT fk_campaign_lists_cl_c_id FOREIGN KEY (cl_c_id) REFERENCES campaigns(c_id) ON DELETE RESTRICT,
  CONSTRAINT fk_campaign_lists_cl_t_id FOREIGN KEY (cl_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

---------- table influencer_proposals ----------
CREATE TABLE influencer_proposals (
  ip_id BIGSERIAL PRIMARY KEY,
  ip_cl_id INTEGER NOT NULL,    -- foreign key to 'cl_id' from campaign_lists table
  ip_is_id INTEGER NOT NULL,   -- foreign key to 'is_id' from influencer_socials table
  ip_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
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
  CONSTRAINT fk_influencer_proposals_ip_cl_id FOREIGN KEY (ip_cl_id) REFERENCES campaign_lists(cl_id) ON DELETE RESTRICT,
  CONSTRAINT fk_influencer_proposals_ip_is_id FOREIGN KEY (ip_is_id) REFERENCES influencer_socials(is_id) ON DELETE RESTRICT,
  CONSTRAINT fk_influencer_proposals_ip_t_id FOREIGN KEY (ip_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,
  -- constraints
  CONSTRAINT unique_inf_per_list UNIQUE (ip_cl_id, ip_is_id)
);

---------- table deliverable_proposals ----------
CREATE TYPE dp_stage_enum AS ENUM ('onboarding', 'script', 'production', 'ready', 'live', 'report');

CREATE TYPE dp_status_enum AS ENUM (
  -- Onboarding Stage
  'onboarding_pending_email',
  'waiting_influencer_onboarding_response',
  'influencer_declined_onboarding',
  'influencer_confirmed_onboarding',
  'tc_sent_waiting_response',
  'influencer_declined_tc',
  'influencer_approved_tc',
  
  -- Script Stage
  'script_request_pending',
  'waiting_script_submission',
  'script_received_pending_review',
  'script_approved_request_assets',
  'script_sent_to_client',
  'script_changes_requested',
  
  -- Production Stage
  'assets_request_pending',
  'waiting_assets_submission',
  'assets_received_pending_review',
  'assets_approved_request_deliverable',
  'assets_sent_to_client',
  'assets_changes_requested',
  'waiting_deliverable_submission',
  'deliverable_received_pending_review',
  'deliverable_approved',
  'deliverable_sent_to_client',
  'deliverable_changes_requested',
  
  -- Ready Stage
  'ready_for_publishing',
  'waiting_live_link_submission',
  
  -- Live Stage
  'live_link_received',
  'content_live',
  'waiting_insights_request',
  
  -- Report Stage
  'insights_requested',
  'waiting_insights_submission',
  'insights_received_pending_review',
  'insights_approved',
  'campaign_completed'
);

CREATE TYPE proposal_status_enum AS ENUM ('draft', 'pending_approval', 'approved', 'rejected');

CREATE TABLE deliverable_proposals (
  dp_id BIGSERIAL PRIMARY KEY,
  dp_influencer_proposal_id INTEGER NOT NULL,    -- foreign key to 'ip_id' from influencer_proposals table
  dp_platform_deliverable_id INTEGER NOT NULL,    -- foreign key to 'pd_id' from platform_deliverables table
  dp_agreed_price DECIMAL(15,2) NOT NULL,
  dp_live_date DATE,
  dp_notes TEXT,
  dp_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
  
  -- ADD THIS: PROPOSAL STATUS (Missing in your version)
  dp_proposal_status proposal_status_enum NOT NULL DEFAULT 'draft',
  
  -- EXECUTION WORKFLOW (Only set after approval)
  dp_stage dp_stage_enum,           -- NULL until approved
  dp_status dp_status_enum,         -- NULL until approved
  dp_is_active BOOLEAN NOT NULL DEFAULT true,
  
  -- Stage completion tracking for UI progress indicators
  dp_onboarding_completed BOOLEAN NOT NULL DEFAULT false,
  dp_script_completed BOOLEAN NOT NULL DEFAULT false,
  dp_script_skipped BOOLEAN NOT NULL DEFAULT false,
  dp_production_completed BOOLEAN NOT NULL DEFAULT false,
  dp_production_skipped BOOLEAN NOT NULL DEFAULT false,
  dp_ready_completed BOOLEAN NOT NULL DEFAULT false,
  dp_live_completed BOOLEAN NOT NULL DEFAULT false,
  dp_report_completed BOOLEAN NOT NULL DEFAULT false,
  
  -- Workflow tracking timestamps
  dp_onboarding_email_sent_at TIMESTAMP WITH TIME ZONE,
  dp_onboarding_completed_at TIMESTAMP WITH TIME ZONE,
  dp_tc_sent_at TIMESTAMP WITH TIME ZONE,
  dp_script_requested_at TIMESTAMP WITH TIME ZONE,
  dp_script_completed_at TIMESTAMP WITH TIME ZONE,
  dp_script_skipped_at TIMESTAMP WITH TIME ZONE,
  dp_assets_requested_at TIMESTAMP WITH TIME ZONE,
  dp_production_completed_at TIMESTAMP WITH TIME ZONE,
  dp_production_skipped_at TIMESTAMP WITH TIME ZONE,
  dp_ready_completed_at TIMESTAMP WITH TIME ZONE,
  dp_live_link_submitted_at TIMESTAMP WITH TIME ZONE,
  dp_live_completed_at TIMESTAMP WITH TIME ZONE,
  dp_insights_requested_at TIMESTAMP WITH TIME ZONE,
  dp_report_completed_at TIMESTAMP WITH TIME ZONE,
  
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
  CONSTRAINT fk_deliverable_proposals_dp_ip_id FOREIGN KEY (dp_influencer_proposal_id) REFERENCES influencer_proposals(ip_id) ON DELETE RESTRICT,
  CONSTRAINT fk_deliverable_proposals_dp_pd_id FOREIGN KEY (dp_platform_deliverable_id) REFERENCES platform_deliverables(pd_id) ON DELETE RESTRICT,
  CONSTRAINT fk_deliverable_proposals_dp_t_id FOREIGN KEY (dp_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,
  -- constraints
  CONSTRAINT chk_price_positive CHECK (dp_agreed_price >= 0),
  CONSTRAINT uk_one_proposal_per_influencer_deliverable UNIQUE (dp_influencer_proposal_id, dp_platform_deliverable_id)
);

-- ------------------------------------------------------------------------------------------------------------------
-- ************************************************ EMAIL TEMPLATES  ************************************************
-- ------------------------------------------------------------------------------------------------------------------

---------- table email_templates ----------
CREATE TYPE template_category_enum AS ENUM (
  'onboarding', 'script_request', 'script_approval', 'content_submission', 'content_approval', 
  'payment_reminder', 'campaign_completion',  'general_reminder', 'custom'
);

CREATE TYPE et_stage_enum AS ENUM ('onboarding', 'script', 'production', 'ready', 'live', 'report');

CREATE TYPE email_status_enum AS ENUM (
  'queued', 'sent', 'delivered', 'opened', 'clicked', 'failed', 'bounced'
);

CREATE TABLE email_templates (
  et_id BIGSERIAL PRIMARY KEY,
  et_name VARCHAR(255) NOT NULL,
  et_category template_category_enum NOT NULL,
  et_workflow_stage et_stage_enum,                 -- Which deliverable stage this template is for
  et_description TEXT,
  et_subject VARCHAR(500) NOT NULL,
  et_body TEXT NOT NULL,
  et_variables JSONB,                              -- Available variables like {{influencer_name}}, {{brand_name}}
  et_is_active BOOLEAN NOT NULL DEFAULT true,
  et_is_default BOOLEAN NOT NULL DEFAULT false,   -- Default template for this category/stage
  et_t_id INTEGER NOT NULL,                        -- foreign key to 't_id' from tenants table
  
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
  CONSTRAINT fk_email_templates_tenant FOREIGN KEY (et_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,
  
  -- constraints
  CONSTRAINT uk_email_templates_name_tenant UNIQUE (et_name, et_t_id),
  CONSTRAINT uk_default_template_per_category UNIQUE (et_category, et_workflow_stage, et_t_id, et_is_default) 
    DEFERRABLE INITIALLY DEFERRED
);

---------- table email_template_versions ----------
CREATE TABLE email_template_versions (
  etv_id BIGSERIAL PRIMARY KEY,
  etv_et_id INTEGER NOT NULL,                     -- foreign key to 'et_id' from email_templates table
  etv_version_number INTEGER NOT NULL,
  etv_subject VARCHAR(500) NOT NULL,
  etv_body TEXT NOT NULL,
  etv_variables JSONB,
  etv_change_notes TEXT,                          -- What changed in this version
  etv_is_current BOOLEAN NOT NULL DEFAULT false, -- Current active version
  etv_t_id INTEGER NOT NULL,
  
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
  CONSTRAINT fk_email_template_versions_template FOREIGN KEY (etv_et_id) REFERENCES email_templates(et_id) ON DELETE CASCADE,
  CONSTRAINT fk_email_template_versions_tenant FOREIGN KEY (etv_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,
  
  -- constraints
  CONSTRAINT uk_template_version_number UNIQUE (etv_et_id, etv_version_number),
  CONSTRAINT uk_current_version_per_template UNIQUE (etv_et_id, etv_is_current) 
    DEFERRABLE INITIALLY DEFERRED
);

---------- Updated email_logs table (without redundant column) ----------
CREATE TABLE email_logs (
  el_id BIGSERIAL PRIMARY KEY,
  el_et_id INTEGER,                                -- Original template ID used as starting point
  el_etv_id INTEGER,                               -- Specific template version used  
  el_dp_id INTEGER,                                -- CRITICAL: Links email to specific deliverable
  el_workflow_stage et_stage_enum,                 -- Which stage this email belongs to
  el_email_category template_category_enum,        -- onboarding, script_request, reminder, etc.
  
  -- Email content (final version sent to user)
  el_recipient_email VARCHAR(255) NOT NULL,
  el_recipient_name VARCHAR(255),
  el_sender_email VARCHAR(255) NOT NULL,
  el_sender_name VARCHAR(255),
  el_subject VARCHAR(500) NOT NULL,               -- Final subject after user modifications
  el_body TEXT NOT NULL,                          -- Final body after user modifications
  el_variables_used JSONB,                        -- Variables and their actual values
  
  -- Tracking info
  el_status email_status_enum NOT NULL DEFAULT 'queued',
  el_gateway VARCHAR(50),                         -- 'sendgrid', 'mailgun', etc.
  el_gateway_message_id VARCHAR(255),
  el_sent_at TIMESTAMP WITH TIME ZONE,
  el_delivered_at TIMESTAMP WITH TIME ZONE,
  el_opened_at TIMESTAMP WITH TIME ZONE,
  
  -- Modification tracking
  el_template_modified BOOLEAN DEFAULT false,     -- Did user modify the template?
  
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
  CONSTRAINT fk_email_logs_template FOREIGN KEY (el_et_id) REFERENCES email_templates(et_id) ON DELETE SET NULL,
  CONSTRAINT fk_email_logs_template_version FOREIGN KEY (el_etv_id) REFERENCES email_template_versions(etv_id) ON DELETE SET NULL,
  CONSTRAINT fk_email_logs_deliverable FOREIGN KEY (el_dp_id) REFERENCES deliverable_proposals(dp_id) ON DELETE RESTRICT,
  CONSTRAINT fk_email_logs_tenant FOREIGN KEY (el_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

-- =================================================================================================================
-- ******************************************* CART AND BRAND APPROVAL *********************************************
-- =================================================================================================================

---------- table cart ----------
CREATE TYPE cart_status_enum AS ENUM ('draft', 'sent_to_brand', 'reviewed');

CREATE TABLE cart_details (
  cr_id BIGSERIAL PRIMARY KEY,
  cr_name TEXT NOT NULL,                            -- "Q1 Fashion Campaign Cart"
  cr_estimated_total DECIMAL(15,2) DEFAULT 0,
  cr_status cart_status_enum NOT NULL DEFAULT 'draft',
  cr_sent_to_brand_at TIMESTAMP WITH TIME ZONE,     -- When cart was sent to brand
  cr_reviewed_at TIMESTAMP WITH TIME ZONE,          -- When brand finished reviewing
  cr_brand_notes TEXT,                              -- Brand's overall feedback
  cr_t_id INTEGER NOT NULL,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- soft delete
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by VARCHAR(100),
  -- composite unique constraint
  CONSTRAINT unique_cart_per_user UNIQUE (cr_name, created_by),
  -- Foreign key constraints
  CONSTRAINT fk_cart_details_tenant FOREIGN KEY (cr_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

---------- table cart_items ----------
CREATE TABLE cart_items (
  ci_id BIGSERIAL PRIMARY KEY,
  ci_cr_id INTEGER NOT NULL,                        -- foreign key to 'cr_id' from cart_details table
  ci_dp_id INTEGER NOT NULL,                        -- foreign key to 'dp_id' from deliverable_proposals table (FIXED)
  ci_t_id INTEGER NOT NULL,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- soft delete
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by VARCHAR(100),
  -- Foreign key constraints (FIXED)
  CONSTRAINT fk_cart_items_cart FOREIGN KEY (ci_cr_id) REFERENCES cart_details(cr_id) ON DELETE RESTRICT,
  CONSTRAINT fk_cart_items_deliverable FOREIGN KEY (ci_dp_id) REFERENCES deliverable_proposals(dp_id) ON DELETE RESTRICT,
  CONSTRAINT fk_cart_items_tenant FOREIGN KEY (ci_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,  
  -- Prevent duplicate deliverables in same cart
  CONSTRAINT unique_deliverable_per_cart UNIQUE (ci_cr_id, ci_dp_id)
);

---------- table brand_approvals ----------
CREATE TYPE approval_action_enum AS ENUM ('approved', 'rejected', 'requested_changes');

CREATE TABLE brand_approvals (
  ba_id BIGSERIAL PRIMARY KEY,
  ba_dp_id INTEGER NOT NULL,                        -- foreign key to deliverable_proposals
  ba_action approval_action_enum NOT NULL,
  ba_notes TEXT,                                    -- Brand's specific feedback for this deliverable
  ba_approved_by_user_id INTEGER NOT NULL,         -- Brand user who made the decision
  ba_approved_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  ba_t_id INTEGER NOT NULL,
  
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
  CONSTRAINT fk_brand_approvals_dp_id FOREIGN KEY (ba_dp_id) REFERENCES deliverable_proposals(dp_id) ON DELETE RESTRICT,
  CONSTRAINT fk_brand_approvals_user FOREIGN KEY (ba_approved_by_user_id) REFERENCES app_users(u_id) ON DELETE RESTRICT,
  CONSTRAINT fk_brand_approvals_t_id FOREIGN KEY (ba_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

-- =================================================================================================================
-- ********************************************* DELIVERABLE EXECUTION *********************************************
-- =================================================================================================================

---------- table deliverable_proposals_activity ----------
CREATE TYPE dpa_action_type_enum AS ENUM (
  'email_sent', 'reminder_sent', 'tc_sent', 'script_requested', 'assets_requested', 
  'deliverable_requested', 'live_link_requested', 'insights_requested',
  'onboarding_accepted', 'onboarding_declined', 'tc_accepted', 'tc_declined',
  'script_submitted', 'assets_submitted', 'deliverable_submitted', 
  'live_link_submitted', 'insights_submitted', 'script_approved', 'script_rejected', 
  'assets_approved', 'assets_rejected', 'deliverable_approved', 'deliverable_rejected', 
  'insights_approved', 'insights_rejected', 'script_sent_to_client', 'assets_sent_to_client', 
  'deliverable_sent_to_client', 'changes_suggested', 'status_updated', 'stage_updated', 
  'stage_completed', 'stage_skipped', 'influencer_removed', 'comment_added'
);

CREATE TYPE dpa_actor_type_enum AS ENUM ('agency_user', 'influencer', 'brand_user', 'system');

CREATE TABLE deliverable_proposals_activity (
  dpa_id                  BIGSERIAL PRIMARY KEY,
  dpa_dp_id               INTEGER NOT NULL,    -- foreign key to 'dp_id' from deliverable_proposals table
  dpa_action_type         dpa_action_type_enum NOT NULL,
  dpa_action_description  TEXT,
  dpa_actor_type          dpa_actor_type_enum NOT NULL,
  dpa_actor_u_id          INTEGER, -- foreign key to 'u_id' from app_users table, can be NULL for system actions
  dpa_previous_status     dp_status_enum,
  dpa_new_status          dp_status_enum,
  dpa_previous_stage      dp_stage_enum,
  dpa_new_stage           dp_stage_enum,
  dpa_metadata            JSONB,        -- additional data like file IDs, email templates used, etc.
  dpa_timestamp           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  dpa_email_log_id        INTEGER,  -- Reference to email_logs table
  dpa_t_id                INTEGER NOT NULL,  -- foreign key to 't_id' from tenants table
 -- audit and logs
  created_by              VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by             VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at             TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- soft delete
  is_deleted              BOOLEAN NOT NULL DEFAULT false,
  deleted_at              TIMESTAMP WITH TIME ZONE,
  deleted_by              VARCHAR(100),
  -- Foreign key constraints
  CONSTRAINT fk_deliverable_activity_dp_id FOREIGN KEY (dpa_dp_id) REFERENCES deliverable_proposals(dp_id) ON DELETE RESTRICT,
  CONSTRAINT fk_deliverable_activity_t_id FOREIGN KEY (dpa_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,
  CONSTRAINT fk_deliverable_activity_actor FOREIGN KEY (dpa_actor_u_id) REFERENCES app_users(u_id) ON DELETE RESTRICT,
  CONSTRAINT fk_deliverable_activity_email_log FOREIGN KEY (dpa_email_log_id) REFERENCES email_logs(el_id) ON DELETE RESTRICT
);

---------- table deliverable_attachments ----------
CREATE TYPE da_category_enum AS ENUM ('script', 'assets', 'deliverable', 'live_link', 'insights', 'tc_document', 'other');
CREATE TYPE da_status_enum AS ENUM ('uploaded', 'approved', 'rejected', 'sent_to_client', 'revision_requested');

CREATE TABLE deliverable_attachments (
  da_id                 BIGSERIAL PRIMARY KEY,
  da_dp_id              INTEGER NOT NULL,    -- foreign key to 'dp_id' from deliverable_proposals table
  da_category           da_category_enum NOT NULL,
  da_file_name          VARCHAR(255) NOT NULL,
  da_file_url           VARCHAR(500) NOT NULL,
  da_file_size_bytes    BIGINT,
  da_mime_type          VARCHAR(100),
  da_status             da_status_enum NOT NULL DEFAULT 'uploaded',
  da_uploaded_by_type   dpa_actor_type_enum NOT NULL,
  da_uploaded_by_id     INTEGER, -- foreign key to 'u_id' from app_users table, can be NULL for system uploads
  da_approved_by_id     INTEGER, -- foreign key to 'u_id' from app_users table, can be NULL if not approved yet
  da_approved_at        TIMESTAMP WITH TIME ZONE,
  da_rejection_reason   TEXT,
  da_version            INTEGER NOT NULL DEFAULT 1,
  da_is_current_version BOOLEAN NOT NULL DEFAULT true,
  da_t_id               INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
  -- audit and logs
  created_by            VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by           VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- soft delete
  is_deleted            BOOLEAN NOT NULL DEFAULT false,
  deleted_at            TIMESTAMP WITH TIME ZONE,
  deleted_by            VARCHAR(100),
  -- Foreign key constraints
  CONSTRAINT fk_deliverable_attachments_dp_id FOREIGN KEY (da_dp_id) REFERENCES deliverable_proposals(dp_id) ON DELETE RESTRICT,
  CONSTRAINT fk_deliverable_attachments_t_id FOREIGN KEY (da_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,
  CONSTRAINT fk_deliverable_attachments_uploaded_by FOREIGN KEY (da_uploaded_by_id) REFERENCES app_users(u_id) ON DELETE RESTRICT,
  CONSTRAINT fk_deliverable_attachments_approved_by FOREIGN KEY (da_approved_by_id) REFERENCES app_users(u_id) ON DELETE RESTRICT
);

---------- table deliverable_approvals ----------
CREATE TYPE approval_type_enum AS ENUM ('script', 'assets', 'deliverable', 'insights');
CREATE TYPE approval_status_enum AS ENUM ('pending', 'approved', 'rejected', 'sent_to_client');

CREATE TABLE deliverable_approvals (
  dap_id BIGSERIAL PRIMARY KEY,
  dap_dp_id INTEGER NOT NULL,    -- foreign key to 'dp_id' from deliverable_proposals table
  dap_approval_type approval_type_enum NOT NULL,
  dap_status approval_status_enum NOT NULL DEFAULT 'pending',
  dap_approved_by_id INTEGER, -- foreign key to 'u_id' from app_users table, can be NULL if not approved yet
  dap_approved_at TIMESTAMP WITH TIME ZONE,
  dap_rejection_reason TEXT,
  dap_client_feedback TEXT,
  dap_ai_suggestions TEXT, -- AI generated suggestions
  dap_attachment_ids JSONB, -- array of attachment IDs being approved
  dap_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
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
  CONSTRAINT fk_deliverable_approvals_dp_id FOREIGN KEY (dap_dp_id) REFERENCES deliverable_proposals(dp_id) ON DELETE CASCADE,
  CONSTRAINT fk_deliverable_approvals_t_id FOREIGN KEY (dap_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,
  CONSTRAINT fk_deliverable_approvals_approved_by FOREIGN KEY (dap_approved_by_id) REFERENCES app_users(u_id) ON DELETE SET NULL
);

---------- table deliverable_comments ----------
CREATE TYPE comment_actor_type_enum AS ENUM ('agency_user', 'influencer', 'brand_user');

CREATE TABLE deliverable_comments (
  dc_id BIGSERIAL PRIMARY KEY,
  dc_dp_id INTEGER NOT NULL,    -- foreign key to 'dp_id' from deliverable_proposals table
  dc_stage dp_stage_enum NOT NULL, -- which stage this comment belongs to
  dc_comment_text TEXT NOT NULL,
  dc_actor_type comment_actor_type_enum NOT NULL,
  dc_actor_id INTEGER, -- user ID who commented
  dc_actor_name VARCHAR(255), -- name of the person commenting
  dc_actor_avatar_url VARCHAR(500), -- avatar URL
  dc_parent_comment_id INTEGER, -- for reply structure
  dc_attachments JSONB, -- optional file attachments in comments
  dc_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
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
  CONSTRAINT fk_deliverable_comments_dp_id FOREIGN KEY (dc_dp_id) REFERENCES deliverable_proposals(dp_id) ON DELETE CASCADE,
  CONSTRAINT fk_deliverable_comments_parent FOREIGN KEY (dc_parent_comment_id) REFERENCES deliverable_comments(dc_id) ON DELETE CASCADE,
  CONSTRAINT fk_deliverable_comments_t_id FOREIGN KEY (dc_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,
  CONSTRAINT fk_deliverable_comments_actor FOREIGN KEY (dc_actor_id) REFERENCES app_users(u_id) ON DELETE RESTRICT
);


-- =================================================================================================================
-- ********************************************* GLOBAL NAMED TABLES ***********************************************
-- =================================================================================================================

---------- table global_genres_pillars_niche ----------
CREATE TABLE global_genres_pillars_niche
(
  id              BIGSERIAL PRIMARY KEY,
  genre_id        INTEGER NOT NULL,
  genre_name      TEXT NOT NULL,
  pillar_name     TEXT NOT NULL,
  niche_name      TEXT NOT NULL,
  pillar_id       INTEGER NOT NULL,
  niche_id        INTEGER NOT NULL,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- soft delete
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by VARCHAR(100)
);

---------- table global_locations ----------
CREATE TABLE global_locations
(
  id               BIGINT PRIMARY KEY,
  cityName         TEXT NOT NULL,
  countryName      TEXT NOT NULL,
  countryCode      VARCHAR(5) NOT NULL,
  stateProvince    TEXT,
  latitude         NUMERIC(9,6),
  longitude        NUMERIC(9,6),
  population       BIGINT,
  isPopular        BOOLEAN NOT NULL DEFAULT false,
  tier             SMALLINT,
  -- audit and logs
  created_by VARCHAR(100) NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- soft delete
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_by VARCHAR(100)
);

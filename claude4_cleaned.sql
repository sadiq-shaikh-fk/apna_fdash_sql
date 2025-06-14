-- ------------------------------------------------------------------------------------------------------------------
-- *******************************************INITIAL SETUP - Core Tables *******************************************
-- ------------------------------------------------------------------------------------------------------------------

---------- table gods_eye ----------
CREATE TABLE gods_eye (
  ge_id BIGSERIAL PRIMARY KEY,
  ge_name VARCHAR(255) NOT NULL,
  ge_password VARCHAR(255) NOT NULL,
  ge_is_active BOOLEAN NOT NULL DEFAULT true,
  ge_last_login TIMESTAMP WITH TIME ZONE,
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
  CONSTRAINT uk_gods_eye_name UNIQUE (ge_name)
);

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

---------- table users ----------
CREATE TYPE user_type_enum AS ENUM ('general', 'agency', 'brand');
CREATE TYPE user_status_enum AS ENUM ('active', 'inactive', 'suspended', 'pending_verification');

CREATE TABLE users (
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
  CONSTRAINT fk_user_invites_ui_sent_by_u_id FOREIGN KEY (ui_sent_by_u_id) REFERENCES users(u_id) ON DELETE RESTRICT,
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
  CONSTRAINT fk_filters_created_by FOREIGN KEY (f_created_by) REFERENCES users(u_id) ON DELETE RESTRICT,
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
  CONSTRAINT fk_filter_shares_user FOREIGN KEY (fs_shared_with) REFERENCES users(u_id) ON DELETE RESTRICT,
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
  CONSTRAINT fk_influencers_inf_primary_platform_id FOREIGN KEY (inf_primary_platform_id) REFERENCES platforms(p_id) ON DELETE RESTRICT,
  -- constraints
  CONSTRAINT uk_inf_email UNIQUE (inf_email),
  CONSTRAINT uk_inf_phone1 UNIQUE (inf_phone1),
  CONSTRAINT uk_inf_phone2 UNIQUE (inf_phone2)
);

---------- table influencers_social ----------
CREATE TABLE influencers_socials (
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

---------- table influencer_mgmt_details ----------
CREATE TABLE influencer_mgmt (
  imd_id BIGSERIAL PRIMARY KEY,
  imd_is_id INTEGER NOT NULL,    -- foreign key to 'is_id' from influencers_socials table
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
  CONSTRAINT fk_influencers_mgmt_imd_is_id FOREIGN KEY (imd_is_id) REFERENCES influencers_socials(is_id) ON DELETE RESTRICT,
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
  CONSTRAINT fk_influencer_prices_ip_inf_id FOREIGN KEY (ip_inf_id) REFERENCES influencers(inf_id) ON DELETE RESTRICT  
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
  c_poc_cs_user_id INTEGER,
  c_poc_irm_user_id INTEGER,
  c_poc_ex_user_id INTEGER,
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
  CONSTRAINT fk_campaigns_poc_cs FOREIGN KEY (c_poc_cs_user_id) REFERENCES users(u_id) ON DELETE RESTRICT,
  CONSTRAINT fk_campaigns_poc_bd FOREIGN KEY (c_poc_irm_user_id) REFERENCES users(u_id) ON DELETE RESTRICT,
  CONSTRAINT fk_campaigns_poc_ex FOREIGN KEY (c_poc_ex_user_id) REFERENCES users(u_id) ON DELETE RESTRICT,
  CONSTRAINT fk_campaigns_tenant FOREIGN KEY (c_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,

  -- constraints
  CONSTRAINT uk_campaigns_name_brand UNIQUE (c_name),
  CONSTRAINT chk_campaign_dates CHECK (c_end_date >= c_start_date),
  CONSTRAINT chk_target_age_range CHECK (c_target_age_from <= c_target_age_to),
  CONSTRAINT chk_inf_age_range CHECK (c_inf_age_from   <= c_inf_age_to)
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

---------- table campaign_lists ----------
CREATE TABLE campaign_lists (
  cl_id BIGSERIAL PRIMARY KEY,
  cl_name VARCHAR(500) NOT NULL,
  cl_c_id INTEGER NOT NULL,     -- foreign key to 'c_id' from campaigns table
  cl_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
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
  CONSTRAINT fk_campaign_lists_cl_c_id FOREIGN KEY (cl_c_id) REFERENCES campaigns(c_id) ON DELETE RESTRICT,
  CONSTRAINT fk_campaign_lists_cl_t_id FOREIGN KEY (cl_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

---------- table influencer_proposals ----------
CREATE TABLE influencer_proposals (
  ip_id BIGSERIAL PRIMARY KEY,
  ip_cl_id INTEGER NOT NULL,    -- foreign key to 'cl_id' from campaign_lists table
  ip_inf_id INTEGER NOT NULL,   -- foreign key to 'inf_id' from influencers table
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
  CONSTRAINT fk_influencer_proposals_ip_inf_id FOREIGN KEY (ip_inf_id) REFERENCES influencers(inf_id) ON DELETE RESTRICT,
  CONSTRAINT fk_influencer_proposals_ip_t_id FOREIGN KEY (ip_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,
  -- constraints
  CONSTRAINT unique_inf_per_list UNIQUE (ip_cl_id, ip_inf_id)
);

---------- table proposal_deliverables ----------
CREATE TABLE proposal_deliverables (
  prd_id BIGSERIAL PRIMARY KEY,
  prd_ip_id INTEGER NOT NULL,    -- foreign key to 'ip_id' from influencer_proposals table
  prd_pd_id INTEGER NOT NULL,    -- foreign key to 'pd_id' from platform_deliverables table -- addition of custom deliverables will go to platform_deliverables and its id would insert here
  prd_agreed_price DECIMAL(15,2) NOT NULL,
  prd_live_date DATE,
  prd_notes TEXT,
  prd_attachments JSONB, -- stores attachments in key-value pairs
  prd_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
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
  CONSTRAINT fk_proposal_deliverables_prd_ip_id FOREIGN KEY (prd_ip_id) REFERENCES influencer_proposals(ip_id) ON DELETE RESTRICT,
  CONSTRAINT fk_proposal_deliverables_prd_pd_id FOREIGN KEY (prd_pd_id) REFERENCES platform_deliverables(pd_id) ON DELETE RESTRICT,
  CONSTRAINT fk_proposal_deliverables_prd_t_id FOREIGN KEY (prd_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT,
  -- constraints
  CONSTRAINT chk_price_positive CHECK (prd_agreed_price >= 0)
);

---------- table cart ----------
CREATE TABLE cart_details (
  cr_id BIGSERIAL PRIMARY KEY,
  cr_name TEXT NOT NULL,
  cr_estimated_total DECIMAL(15,2) DEFAULT 0,
  cr_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
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
  ci_cr_id INTEGER NOT NULL,    -- foreign key to 'cr_id' from cart table
  ci_prd_id INTEGER NOT NULL,    -- foreign key to 'prd_id' from proposal_deliverables table
  ci_t_id INTEGER NOT NULL,    -- foreign key to 't_id' from tenants table
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
  CONSTRAINT fk_cart_items_cart FOREIGN KEY (ci_cr_id) REFERENCES cart_details(cr_id) ON DELETE RESTRICT,
  CONSTRAINT fk_cart_items_deliverable FOREIGN KEY (ci_prd_id) REFERENCES proposal_deliverables(prd_id) ON DELETE RESTRICT,
  CONSTRAINT fk_cart_items_tenant FOREIGN KEY (ci_t_id) REFERENCES tenants(t_id) ON DELETE RESTRICT
);

-- =================================================================================================================
-- *************************************************** TRIGGERS ****************************************************
-- =================================================================================================================

-- ========== Trigger to insert into tenants before adding brands ==========
---------- trigger function ----------
CREATE OR REPLACE FUNCTION trg_auto_create_tenant_for_brand()
RETURNS TRIGGER AS $$
DECLARE
    new_tenant_id INTEGER;
BEGIN
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
        1,                  -- agency tenant id (parent tenant)
        'brand',            -- tenant_type_enum
        'brand_lite',       -- portal_mode_enum
        'core',             -- cluster_affinity_enum
        'active',           -- default status
        '{}'::jsonb,        -- theme default
        1,                  -- default plan id (starter plan)
        0                   -- default MRR
    )
    RETURNING t_id INTO new_tenant_id;

    -- Assign generated tenant id back to brand foreign keys
    NEW.b_t_id := new_tenant_id;
    NEW.b_parent_t_id := 1;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

---------- trigger assignment ----------
CREATE TRIGGER trg_brands_before_insert
BEFORE INSERT ON brands
FOR EACH ROW
EXECUTE FUNCTION trg_auto_create_tenant_for_brand();


-- ========== Trigger to insert data of auth.users to public.users table ==========
---------- trigger function ----------
CREATE OR REPLACE FUNCTION public.sync_auth_user_to_public_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (
    u_id_auth,
    u_first_name,
    u_last_name,
    u_email_verified_at,
    u_phone_verified_at,
    u_avatar_url
  )
  VALUES (
    NEW.id,
    NEW.metadata->>'first_name',
    NEW.metadata->>'last_name',
    CASE WHEN NEW.email_verified THEN NOW() ELSE NULL END,
    CASE WHEN NEW.phone_number_verified THEN NOW() ELSE NULL END,
    NEW.avatar_url
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

---------- trigger assignment ----------
CREATE TRIGGER trg_insert_auth_user_to_public_user
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.sync_auth_user_to_public_user();


-- ========== 


-- =================================================================================================================
-- ************************************************ INSERT QUERIES *************************************************
-- ************************************************ INSERT QUERIES *************************************************
-- ************************************************ INSERT QUERIES *************************************************
-- ************************************************ INSERT QUERIES *************************************************
-- ************************************************ INSERT QUERIES *************************************************
-- =================================================================================================================

-- ---------- insert into gods_eye table ----------
-- INSERT INTO gods_eye (ge_name, ge_password, ge_is_active, ge_last_login)
-- VALUES
--   ('sadiq', 'sadiq@123', true, NOW() - INTERVAL '7 days'),
--   ('robin', 'robin@123', false, NOW() - INTERVAL '7 days'),
--   ('melwyn', 'melwyn@123', true, NOW() - INTERVAL '7 hours'),
--   ('kriss', 'kriss@123', true, NOW() - INTERVAL '7 hours'),
--   ('rahat', 'rahat@123', false, NOW() - INTERVAL '7 days');

-- ---------- insert into plans ----------
-- INSERT INTO plans (plan_name, plan_base_price_inr, seats, brands, campaigns, ai_actions, plan_overage)
-- VALUES
--   ('free forever', 0, 1, 1, 1, 200, '{"api_per_1k": 25, "ai_sec": 3, "storage_gb": 10}'),
--   ('starter', 8999, 3, 3, 8, 1000, '{"api_per_1k": 25, "ai_sec": 3, "storage_gb": 10}'),
--   ('pro', 24999, 12, 10, 25, 5000, '{"api_per_1k": 25, "ai_sec": 3, "storage_gb": 10}'),
--   ('enterprise', 0, 99999999, 99999999, 99999999, 25000, '{"api_per_1k": 25, "ai_sec": 3, "storage_gb": 10}');

-- ---------- insert into plan_features table ----------

-- -- Free Forever
-- INSERT INTO plan_features (pf_plan_id, pf_feature_value)
-- SELECT plan_id, 'Community & Support'
-- FROM plans WHERE plan_name = 'free forever';

-- INSERT INTO plan_features (pf_plan_id, pf_feature_value)
-- SELECT plan_id, 'Knowledge Base Support'
-- FROM plans WHERE plan_name = 'free forever';

-- -- Starter
-- INSERT INTO plan_features (pf_plan_id, pf_feature_value)
-- SELECT plan_id, 'Email Support (24hr SLA)'
-- FROM plans WHERE plan_name = 'starter';

-- INSERT INTO plan_features (pf_plan_id, pf_feature_value)
-- SELECT plan_id, 'Chat Support (24hr SLA)'
-- FROM plans WHERE plan_name = 'starter';

-- -- Pro
-- INSERT INTO plan_features (pf_plan_id, pf_feature_value)
-- SELECT plan_id, 'Priority Chat Support'
-- FROM plans WHERE plan_name = 'pro';

-- INSERT INTO plan_features (pf_plan_id, pf_feature_value)
-- SELECT plan_id, 'Dedicated Onboarding Session'
-- FROM plans WHERE plan_name = 'pro';

-- -- Enterprise
-- INSERT INTO plan_features (pf_plan_id, pf_feature_value)
-- SELECT plan_id, '24/7 Dedicated Support'
-- FROM plans WHERE plan_name = 'enterprise';

-- INSERT INTO plan_features (pf_plan_id, pf_feature_value)
-- SELECT plan_id, 'SLA-driven CSM'
-- FROM plans WHERE plan_name = 'enterprise';

-- ---------- Insert into organizations ----------
-- INSERT INTO organizations(o_name, o_slug, o_type, o_status, o_cluster_affinity, o_address, o_contact_email, o_contact_phone, o_website, o_logo_url,
-- o_payment_terms, o_tax_info, o_support_info, o_legal_info
-- )
-- VALUES (
--   'Fame Keeda', 'famekeeda', 'agency', 'active', 'core',
--   '1101, A-Wing, Rupa Renaissance, Fame Keeda, MIDC Industrial Area, Turbhe, Navi Mumbai, Maharashtra 400705',
--   'info@famekeeda.com', 08655734299, 'https://www.famekeeda.com',
--   'https://drive.google.com/file/d/16E57E7rZPJRYBwAJa2cLgBM2fUFIG7hB/view?usp=drive_link',
--   NULL, '{"gstin": "27AAECF1428N1ZG"}', NULL, NULL
-- );

-- INSERT INTO organizations(o_name, o_slug, o_type, o_status, o_cluster_affinity, o_address, o_contact_email, o_contact_phone, o_website, o_logo_url,
-- o_payment_terms, o_tax_info, o_support_info, o_legal_info
-- )
-- VALUES (
--   'Tech Mahindra','techmahindra', 'brand', 'active', 'techm_dedicated', 'Gateway Building, Apollo Bunder, Mumbai, Maharashtra, 400001',
--   'corporate.communications@techmahindra.com',  NULL, 'https://www.techmahindra.com',  NULL, NULL, NULL, NULL, NULL
-- );

-- ---------- Insert into tenants ----------
-- -- Fame Keeda Tenant (agency)
-- INSERT INTO tenants (
--   t_name, t_slug, t_o_id, t_parent_t_id, t_type, t_portal_mode, 
--   t_cluster_affinity, t_status, t_theme, t_plan_id, t_mrr, 
--   t_trial_expires_at, t_payment_terms, t_tax_info, t_support_info, t_legal_info, t_settings
-- )
-- VALUES (  'Fame Keeda',  'famekeeda',  1,  NULL,  'agency',  'agency',  'core',  'active',  '{}'::jsonb,  4,  0,  NULL,  NULL,  '{"gstin": "27AAECF1428N1ZG"}',  NULL,  NULL,  '{}'
-- );


-- -- Tech Mahindra Tenant (brand)
-- INSERT INTO tenants (
--   t_name, t_slug, t_o_id, t_parent_t_id, t_type, t_portal_mode, 
--   t_cluster_affinity, t_status, t_theme, t_plan_id, t_mrr, 
--   t_trial_expires_at, t_payment_terms, t_tax_info, t_support_info, t_legal_info, t_settings
-- )
-- VALUES (  'Tech Mahindra',  'techmahindra',  2,  NULL,  'brand',  'brand',  'techm_dedicated',  'active',  '{}'::jsonb,  3,  0,  NULL,  NULL,  NULL,  NULL,  NULL,  '{}'
-- );

-- ---------- insert into subscriptions ----------
-- -- Fame Keeda subscription (internal, 0 price, 1 year validity)
-- INSERT INTO subscriptions (
--   sub_t_id, sub_plan_id, sub_status, sub_start_date, sub_end_date, 
--   sub_is_trial, sub_gateway, sub_gateway_customer_id, sub_gateway_subscription_id, sub_notes
-- )
-- VALUES (
--   1, 4, 'active', NOW(), NOW() + INTERVAL '1 year',
--   false, NULL, NULL, NULL, 'Internal free usage for Fame Keeda team'
-- );


-- -- Tech Mahindra subscription (paid, 1 month cycle)
-- INSERT INTO subscriptions (
--   sub_t_id, sub_plan_id, sub_status, sub_start_date, sub_end_date, 
--   sub_is_trial, sub_gateway, sub_gateway_customer_id, sub_gateway_subscription_id, sub_notes
-- )
-- VALUES (
--   2, 3, 'active', NOW(), NOW() + INTERVAL '1 month',
--   false, 'razorpay', 'cust_techm_001', 'sub_techm_001', 'Tech Mahindra SaaS billing'
-- );



-- ---------- insert into invoices ----------
-- -- Fame Keeda invoice (internal 0 bill)
-- INSERT INTO invoices (
--   i_t_id, i_month, i_invoice_json, i_status, i_total_inr
-- )
-- VALUES (
--   1, date_trunc('month', now()), '{}'::jsonb, 'paid', 0
-- );

-- -- Tech Mahindra invoice (normal billing)
-- INSERT INTO invoices (
--   i_t_id, i_month, i_invoice_json, i_status, i_total_inr
-- )
-- VALUES (
--   2, date_trunc('month', now()), '{}'::jsonb, 'paid', 24999
-- );



-- ---------- insert into payments ----------
-- -- Fame Keeda payment (dummy, internal, no actual gateway)
-- INSERT INTO payments (
--   pay_sub_id, pay_t_id, pay_amount_inr, pay_currency, pay_status, 
--   pay_escrow_status, pay_gateway, pay_gateway_payment_id, pay_gateway_order_id, pay_invoice_id, pay_meta
-- )
-- VALUES (
--   (SELECT sub_id FROM subscriptions WHERE sub_t_id = 1), 1, 0, 'INR', 'success',
--   NULL, NULL, NULL, NULL, (SELECT i_id FROM invoices WHERE i_t_id = 1), '{}'::jsonb
-- );


-- -- Tech Mahindra payment (paid through Razorpay)
-- INSERT INTO payments (
--   pay_sub_id, pay_t_id, pay_amount_inr, pay_currency, pay_status, 
--   pay_escrow_status, pay_gateway, pay_gateway_payment_id, pay_gateway_order_id, pay_invoice_id, pay_meta
-- )
-- VALUES (
--   (SELECT sub_id FROM subscriptions WHERE sub_t_id = 2), 2, 24999, 'INR', 'success',
--   'released', 'razorpay', 'pay_techm_001', 'order_techm_001', (SELECT i_id FROM invoices WHERE i_t_id = 2), '{}'::jsonb
-- );


-- ---------- insert into teams ----------
-- INSERT INTO teams (tm_name, tm_description, tm_status, tm_t_id)
-- VALUES
-- ('Influencers Relations', 'Influencers Relations Team', 'active', 1),
-- ('Research & Development', 'R&D Team', 'active', 1),
-- ('Human Resources', 'HR Team', 'active', 1),
-- ('Branding', 'Branding & Design Team', 'active', 1),
-- ('Affiliate Marketing', 'Affiliate Marketing Team', 'active', 1),
-- ('Campaign Execution', 'Campaign Execution Team', 'active', 1),
-- ('Business Development', 'Business Development Team', 'active', 1),
-- ('Talent Management', 'Talent Management Team', 'active', 1),
-- ('Admin', 'Administration Team', 'active', 1),
-- ('Client Success', 'Client Success Team', 'active', 1),
-- ('Finance', 'Finance & Accounts Team', 'active', 1),
-- ('Management', 'Management Leadership Team', 'active', 1),
-- ('SEO', 'SEO & Search Optimization Team', 'active', 1),
-- ('IT', 'IT & Infra Team', 'active', 1),
-- ('Legal', 'Legal & Compliance Team', 'active', 1),
-- ('R&D', 'R&D Subteam', 'active', 1),
-- ('Performance Marketing', 'Performance Marketing Team', 'active', 1),
-- ('Product Team', 'Product Development Team', 'active', 1),
-- ('BOD', 'Board of Directors', 'active', 1),
-- ('Brand Strategy', 'Brand Strategy Team', 'active', 1);


-- ---------- insert into roles ----------
-- -- Human Resources
-- INSERT INTO roles (r_name, r_description, r_t_id, r_is_system_role)
-- VALUES 
-- ('Human Resources Admin', 'Admin for HR Team', 1, false),
-- ('Human Resources Member', 'Member for HR Team', 1, false),
-- -- Branding
-- ('Branding Admin', 'Admin for Branding Team', 1, false),
-- ('Branding Member', 'Member for Branding Team', 1, false),
-- -- Affiliate Marketing
-- ('Affiliate Marketing Admin', 'Admin for Affiliate Marketing Team', 1, false),
-- ('Affiliate Marketing Member', 'Member for Affiliate Marketing Team', 1, false),
-- -- Campaign Execution
-- ('Campaign Execution Admin', 'Admin for Campaign Execution Team', 1, false),
-- ('Campaign Execution Member', 'Member for Campaign Execution Team', 1, false),
-- -- Business Development
-- ('Business Development Admin', 'Admin for Business Development Team', 1, false),
-- ('Business Development Member', 'Member for Business Development Team', 1, false),
-- -- Talent Management
-- ('Talent Management Admin', 'Admin for Talent Management Team', 1, false),
-- ('Talent Management Member', 'Member for Talent Management Team', 1, false),
-- -- Admin
-- ('Admin Admin', 'Admin for Admin Team', 1, false),
-- ('Admin Member', 'Member for Admin Team', 1, false),
-- -- Client Success
-- ('Client Success Admin', 'Admin for Client Success Team', 1, false),
-- ('Client Success Member', 'Member for Client Success Team', 1, false),
-- -- Finance
-- ('Finance Admin', 'Admin for Finance Team', 1, false),
-- ('Finance Member', 'Member for Finance Team', 1, false),
-- -- Management
-- ('Management Admin', 'Admin for Management Team', 1, false),
-- ('Management Member', 'Member for Management Team', 1, false),
-- -- SEO
-- ('SEO Admin', 'Admin for SEO Team', 1, false),
-- ('SEO Member', 'Member for SEO Team', 1, false),
-- -- IT
-- ('IT Admin', 'Admin for IT Team', 1, false),
-- ('IT Member', 'Member for IT Team', 1, false),
-- -- Legal
-- ('Legal Admin', 'Admin for Legal Team', 1, false),
-- ('Legal Member', 'Member for Legal Team', 1, false),
-- -- R&D
-- ('R&D Admin', 'Admin for R&D Team', 1, false),
-- ('R&D Member', 'Member for R&D Team', 1, false),
-- -- Performance Marketing
-- ('Performance Marketing Admin', 'Admin for Performance Marketing Team', 1, false),
-- ('Performance Marketing Member', 'Member for Performance Marketing Team', 1, false),
-- -- Product Team
-- ('Product Team Admin', 'Admin for Product Team', 1, false),
-- ('Product Team Member', 'Member for Product Team', 1, false),
-- -- BOD
-- ('BOD Admin', 'Admin for Board of Directors', 1, false),
-- ('BOD Member', 'Member for Board of Directors', 1, false),
-- -- Brand Strategy
-- ('Brand Strategy Admin', 'Admin for Brand Strategy Team', 1, false),
-- ('Brand Strategy Member', 'Member for Brand Strategy Team', 1, false);

-- ---------- insert into system roles ----------
-- INSERT INTO roles (r_name, r_description, r_is_system_role)
-- VALUES
-- ('Super Admin', 'Full system-wide super admin access', true),
-- ('Platform Billing Admin', 'Manage subscriptions, invoices, payments globally', true),
-- ('Support Agent', 'Limited read-only access for customer support', true),
-- ('Platform Developer', 'Developer backend access for internal engineering team', true),
-- ('Compliance Auditor', 'Security & compliance audit access', true);


-- ---------- insert into filters ----------
-- -- Amazon Macro Influencers #1
-- INSERT INTO filters (f_name, f_type, f_created_by, f_metadata, f_is_active, f_t_id)
-- VALUES (
--   'Amazon Macro Influencers', 
--   'private', 
--   1, 
--   '{
--     "platform": "Youtube",
--     "genre": "Entertainment",
--     "niche": ["Gaming", "Sketch Comedy", "Standup Comedy"],
--     "followers_min": 1000,
--     "followers_max": 200000,
--     "avg_views_min": 50000,
--     "avg_views_max": 700000,
--     "engagement_rate_min": 0,
--     "engagement_rate_max": 20,
--     "growth_rate_min": 0,
--     "growth_rate_max": 10,
--     "most_recent_post": "3 days ago"
--   }'::jsonb, 
--   true, 
--   1
-- );

-- -- Policy Bazaar Legends
-- INSERT INTO filters (f_name, f_type, f_created_by, f_metadata, f_is_active, f_t_id)
-- VALUES (
--   'Policy Bazaar Legends', 
--   'private', 
--   1, 
--   '{
--     "platform": "Instagram",
--     "genre": "Finance",
--     "niche": ["Insurance", "Investments"],
--     "followers_min": 5000,
--     "followers_max": 1000000,
--     "avg_views_min": 10000,
--     "avg_views_max": 400000,
--     "engagement_rate_min": 5,
--     "engagement_rate_max": 25,
--     "growth_rate_min": 0,
--     "growth_rate_max": 15,
--     "most_recent_post": "5 days ago"
--   }'::jsonb, 
--   true, 
--   1
-- );

-- -- MStock Nano Influencers
-- INSERT INTO filters (f_name, f_type, f_created_by, f_metadata, f_is_active, f_t_id)
-- VALUES (
--   'MStock Nano Influencers', 
--   'private', 
--   1, 
--   '{
--     "platform": "Instagram",
--     "genre": "Stock Trading",
--     "niche": ["Equity", "Crypto"],
--     "followers_min": 1000,
--     "followers_max": 10000,
--     "avg_views_min": 500,
--     "avg_views_max": 20000,
--     "engagement_rate_min": 2,
--     "engagement_rate_max": 15,
--     "growth_rate_min": 1,
--     "growth_rate_max": 8,
--     "most_recent_post": "1 day ago"
--   }'::jsonb, 
--   true, 
--   1
-- );

-- -- Amazon Nano Influencers #2 (deduped version)
-- INSERT INTO filters (f_name, f_type, f_created_by, f_metadata, f_is_active, f_t_id)
-- VALUES (
--   'Amazon Nano Influencers', 
--   'private', 
--   1, 
--   '{
--     "platform": "Youtube",
--     "genre": "Tech Reviews",
--     "niche": ["Mobile Phones", "Gadgets"],
--     "followers_min": 50000,
--     "followers_max": 500000,
--     "avg_views_min": 100000,
--     "avg_views_max": 1000000,
--     "engagement_rate_min": 1,
--     "engagement_rate_max": 12,
--     "growth_rate_min": 3,
--     "growth_rate_max": 10,
--     "most_recent_post": "7 days ago"
--   }'::jsonb, 
--   true, 
--   1
-- );


-- ---------- insert into access ----------
-- INSERT INTO access (a_name, a_description, a_is_active, a_t_id)
-- VALUES 
-- ('admin', 'Full access to all filters and shares', true, 1),
-- ('editor', 'Can edit filters but limited sharing rights', true, 1),
-- ('viewer', 'Read-only access to filters', true, 1);


-- ---------- insert into filter_shares ----------
-- -- Amazon Macro Influencers
-- INSERT INTO filter_shares (fs_f_id, fs_shared_with, fs_access_level, fs_is_active, fs_t_id)
-- VALUES 
--   (1, 1, 1, true, 1),  -- User 1 Admin access
--   (1, 2, 2, true, 1);  -- User 2 Editor access

-- -- Policy Bazaar Legends
-- INSERT INTO filter_shares (fs_f_id, fs_shared_with, fs_access_level, fs_is_active, fs_t_id)
-- VALUES 
--   (2, 1, 1, true, 1),
--   (2, 2, 2, true, 1);

-- -- MStock Nano Influencers
-- INSERT INTO filter_shares (fs_f_id, fs_shared_with, fs_access_level, fs_is_active, fs_t_id)
-- VALUES 
--   (3, 1, 1, true, 1),
--   (3, 2, 2, true, 1);

-- -- Amazon Nano Influencers
-- INSERT INTO filter_shares (fs_f_id, fs_shared_with, fs_access_level, fs_is_active, fs_t_id)
-- VALUES 
--   (4, 1, 1, true, 1),
--   (4, 2, 2, true, 1);


-- ---------- insert into brands ----------
-- -- Flipkart
-- INSERT INTO brands (
--   b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
--   b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
--   b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
--   b_o_id, b_t_id
-- )
-- VALUES (
--   'Flipkart',
--   'Flipkart Internet Private Limited',
--   'active',
--   'https://1000logos.net/wp-content/uploads/2021/02/Flipkart-logo.png',
--   'https://www.flipkart.com',
--   'https://www.linkedin.com/company/flipkart/',
--   'enterprise',
--   'E-Commerce',
--   'Large Cap',
--   'Customer-centricity, Innovation, Integrity',
--   'Empowering every Indian’s shopping journey',
--   'Modern, Trustworthy, Accessible',
--   'Flipkart is one of India’s leading e-commerce platforms, offering a wide range of products including electronics, fashion, and home essentials. Founded in 2007 and headquartered in Bengaluru, it was acquired by Walmart in 2018.',
--   'GSTIN: 29AAACF1234A1Z5',
--   'Net 30',
--   1,
--   1
-- );

-- -- Amazon India
-- INSERT INTO brands (
--   b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
--   b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
--   b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
--   b_o_id, b_t_id
-- )
-- VALUES (
--   'Amazon India',
--   'Amazon India Limited',
--   'active',
--   'https://1000logos.net/wp-content/uploads/2016/10/Amazon-Logo.png',
--   'https://www.amazon.in',
--   'https://www.linkedin.com/company/amazon-india/',
--   'enterprise',
--   'E-Commerce',
--   'Large Cap',
--   'Customer Obsession, Operational Excellence, Long-term Thinking',
--   'To be Earth’s most customer-centric company',
--   'Innovative, Reliable, Customer-focused',
--   'Amazon India is a subsidiary of Amazon.com, Inc., offering a vast selection of products across various categories. Launched in India in 2013, it has become a key player in the Indian e-commerce market.',
--   'GSTIN: 07AABCA1234B1Z6',
--   'Net 30',
--   1,
--   1
-- );

-- -- Meesho
-- INSERT INTO brands (
--   b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
--   b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
--   b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
--   b_o_id, b_t_id
-- )
-- VALUES (
--   'Meesho',
--   'Meesho Limited',
--   'active',
--   'https://upload.wikimedia.org/wikipedia/commons/5/5e/Meesho_Logo_Full.png',
--   'https://www.meesho.com',
--   'https://www.linkedin.com/company/meesho/',
--   'medium',
--   'E-Commerce',
--   'Mid Cap',
--   'Affordability, Inclusivity, Empowerment',
--   'Democratizing internet commerce for everyone',
--   'Accessible, Empowering, Community-driven',
--   'Meesho is an Indian e-commerce platform that enables small businesses and individuals to start their online stores via social channels. Founded in 2015, it focuses on Tier II and III cities, offering a zero-commission model.',
--   'GSTIN: 29AAACM1234C1Z7',
--   'Net 15',
--   1,
--   1
-- );

-- -- Puma India
-- INSERT INTO brands (
--   b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
--   b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
--   b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
--   b_o_id, b_t_id
-- )
-- VALUES (
--   'Puma India',
--   'Puma Sports India Private Limited',
--   'active',
--   'https://1000logos.net/wp-content/uploads/2017/05/PUMA-Logo.png',
--   'https://in.puma.com',
--   'https://www.linkedin.com/company/puma/',
--   'large',
--   'Apparel & Footwear',
--   'Mid Cap',
--   'Performance, Innovation, Sustainability',
--   'Forever Faster',
--   'Sporty, Dynamic, Trendy',
--   'Puma India is a subsidiary of the global sports brand Puma SE. Established in India in 2005, it offers a wide range of sports and lifestyle products, including footwear, apparel, and accessories.',
--   'GSTIN: 29AAACP1234D1Z8',
--   'Net 30',
--   1,
--   1
-- );

-- -- Dream11
-- INSERT INTO brands (
--   b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
--   b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
--   b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
--   b_o_id, b_t_id
-- )
-- VALUES (
--   'Dream11',
--   'Sporta Technologies Private Limited',
--   'active',
--   'https://upload.wikimedia.org/wikipedia/en/9/9a/Dream11_Logo.png',
--   'https://www.dream11.com',
--   'https://www.linkedin.com/company/dream11/',
--   'large',
--   'Fantasy Sports',
--   'Mid Cap',
--   'Passion, Strategy, Fair Play',
--   'Making sports more exciting through fantasy gaming',
--   'Engaging, Competitive, Innovative',
--   'Dream11 is India’s leading fantasy sports platform, allowing users to create virtual teams and participate in contests across various sports. Founded in 2008, it has over 190 million users.',
--   'GSTIN: 27AAACD1234E1Z9',
--   'Net 15',
--   1,
--   1
-- );

-- -- Google
-- INSERT INTO brands (
--   b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
--   b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
--   b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
--   b_o_id
-- )
-- VALUES (
--   'Google',
--   'Google LLC',
--   'active',
--   'https://logo.clearbit.com/google.com',
--   'https://www.google.com',
--   'https://www.linkedin.com/company/google',
--   'enterprise',
--   'Technology',
--   'Large Cap',
--   'Organize the world’s information and make it universally accessible and useful.',
--   'Innovative, user-centric solutions.',
--   'Colorful, playful, and approachable.',
--   'Google is a global technology leader specializing in Internet-related services and products.',
--   'US-TAX-001',
--   'Net 30',
--   1
-- );

-- -- Myntra
-- INSERT INTO brands (
--   b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
--   b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
--   b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
--   b_o_id
-- )
-- VALUES (
--   'Myntra',
--   'Myntra Designs Private Limited',
--   'active',
--   'https://logo.clearbit.com/myntra.com',
--   'https://www.myntra.com',
--   'https://www.linkedin.com/company/myntra',
--   'large',
--   'E-commerce',
--   'Mid Cap',
--   'Fashion-forward and customer-centric.',
--   'Your fashion destination.',
--   'Trendy, youthful, and vibrant.',
--   'Myntra is a leading Indian fashion e-commerce company offering a wide range of clothing and accessories.',
--   'IN-TAX-002',
--   'Net 30',
--   1
-- );

-- -- Netflix
-- INSERT INTO brands (
--   b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
--   b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
--   b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
--   b_o_id
-- )
-- VALUES (
--   'Netflix',
--   'Netflix, Inc.',
--   'active',
--   'https://logo.clearbit.com/netflix.com',
--   'https://www.netflix.com',
--   'https://www.linkedin.com/company/netflix',
--   'enterprise',
--   'Entertainment',
--   'Large Cap',
--   'Entertainment on demand.',
--   'See what’s next.',
--   'Bold, cinematic, and engaging.',
--   'Netflix is a global streaming service offering a wide variety of award-winning TV shows, movies, and documentaries.',
--   'US-TAX-003',
--   'Net 30',
--   1
-- );

-- -- Sugar
-- INSERT INTO brands (
--   b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
--   b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
--   b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
--   b_o_id
-- )
-- VALUES (
--   'Sugar',
--   'Vellvette Lifestyle Private Limited',
--   'active',
--   'https://logo.clearbit.com/sugarcosmetics.com',
--   'https://www.sugarcosmetics.com',
--   'https://www.linkedin.com/company/sugar-cosmetics',
--   'medium',
--   'Cosmetics',
--   'Small Cap',
--   'Empowering women with bold beauty choices.',
--   'Rule the world, one look at a time.',
--   'Chic, edgy, and confident.',
--   'Sugar Cosmetics is a cruelty-free makeup brand offering a wide range of products for bold and independent women.',
--   'IN-TAX-004',
--   'Net 30',
--   1
-- );

-- -- Apple
-- INSERT INTO brands (
--   b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
--   b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
--   b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
--   b_o_id
-- )
-- VALUES (
--   'Apple',
--   'Apple Inc.',
--   'active',
--   'https://logo.clearbit.com/apple.com',
--   'https://www.apple.com',
--   'https://www.linkedin.com/company/apple',
--   'enterprise',
--   'Technology',
--   'Large Cap',
--   'Innovation and simplicity.',
--   'Think different.',
--   'Sleek, minimalist, and premium.',
--   'Apple designs and manufactures consumer electronics, software, and online services, known for its innovative products.',
--   'US-TAX-005',
--   'Net 30',
--   1
-- );

-- -- Samsung
-- INSERT INTO brands (
--   b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
--   b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
--   b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
--   b_o_id
-- )
-- VALUES (
--   'Samsung',
--   'Samsung Electronics Co., Ltd.',
--   'active',
--   'https://logo.clearbit.com/samsung.com',
--   'https://www.samsung.com',
--   'https://www.linkedin.com/company/samsung-electronics',
--   'enterprise',
--   'Electronics',
--   'Large Cap',
--   'Technology for life.',
--   'Imagine the possibilities.',
--   'Innovative, reliable, and diverse.',
--   'Samsung is a global leader in technology, opening new possibilities for people everywhere.',
--   'KR-TAX-006',
--   'Net 30',
--   1
-- );

-- -- Mamaearth
-- INSERT INTO brands (
--   b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
--   b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
--   b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
--   b_o_id
-- )
-- VALUES (
--   'Mamaearth',
--   'Honasa Consumer Limited',
--   'active',
--   'https://logo.clearbit.com/mamaearth.in',
--   'https://www.mamaearth.in',
--   'https://www.linkedin.com/company/mamaearth001',
--   'medium',
--   'Personal Care',
--   'Mid Cap',
--   'Natural and toxin-free products.',
--   'Goodness inside.',
--   'Eco-friendly, safe, and nurturing.',
--   'Mamaearth offers natural and toxin-free personal care products, focusing on sustainability and safety.',
--   'IN-TAX-007',
--   'Net 30',
--   1
-- );

-- -- Allen Solly
-- INSERT INTO brands (
--   b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
--   b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
--   b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
--   b_o_id
-- )
-- VALUES (
--   'Allen Solly',
--   'Aditya Birla Fashion and Retail Limited',
--   'active',
--   'https://logo.clearbit.com/allensolly.com',
--   'https://www.allensolly.com',
--   'https://www.linkedin.com/showcase/allensollyindia',
--   'large',
--   'Apparel',
--   'Mid Cap',
--   'Smart casuals for the modern professional.',
--   'Friday dressing.',
--   'Stylish, contemporary, and professional.',
--   'Allen Solly is a premium apparel brand offering stylish and comfortable clothing for men and women.',
--   'IN-TAX-008',
--   'Net 30',
--   1
-- );

-- -- Intel
-- INSERT INTO brands (
--   b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
--   b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
--   b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
--   b_o_id
-- )
-- VALUES (
--   'Intel',
--   'Intel Corporation',
--   'active',
--   'https://logo.clearbit.com/intel.com',
--   'https://www.intel.com',
--   'https://www.linkedin.com/company/intel-corporation',
--   'enterprise',
--   'Semiconductors',
--   'Large Cap',
--   'Driving innovation in computing.',
--   'Experience what’s inside.',
--   'Innovative, powerful, and essential.',
--   'Intel is a leading technology company, known for its semiconductor chips and computing innovations.',
--   'US-TAX-009',
--   'Net 30',
--   1
-- );

-- -- Realme
-- INSERT INTO brands (
--   b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
--   b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,  --11
--   b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,  --15
--   b_o_id
-- )
-- VALUES (
--   'Realme',
--   'Realme Chongqing Mobile Telecommunications Corp., Ltd.',
--   'active',
--   'https://logo.clearbit.com/realme.com',
--   'https://www.realme.com',
--   'https://www.linkedin.com/company/realme',
--   'large',
--   'Consumer Electronics',
--   'Mid Cap',
--   'Dare to leap.',
--   'Dare to leap.',
--   'Youthful, dynamic, and innovative.',
--   'Realme is a technology brand that specializes in providing high',
--   'IN-TAX-110',
--   'NET 50',
--   1
-- );



-- ---------- insert into campaign ----------

-- =================================================================================================================
-- ************************************************ SELECT QUERIES *************************************************
-- ************************************************ SELECT QUERIES *************************************************
-- ************************************************ SELECT QUERIES *************************************************
-- ************************************************ SELECT QUERIES *************************************************
-- ************************************************ SELECT QUERIES *************************************************
-- =================================================================================================================

-- select * from roles
-- select * from teams;
-- select * from organizations;
-- select * from gods_eye;



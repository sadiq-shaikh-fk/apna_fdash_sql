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

---------- table users_app ----------
CREATE TYPE user_type_enum AS ENUM ('general', 'agency', 'brand');
CREATE TYPE user_status_enum AS ENUM ('active', 'inactive', 'suspended', 'pending_verification');

CREATE TABLE users_app (
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
  CONSTRAINT fk_user_invites_ui_sent_by_u_id FOREIGN KEY (ui_sent_by_u_id) REFERENCES users_app(u_id) ON DELETE RESTRICT,
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
  CONSTRAINT fk_filters_created_by FOREIGN KEY (f_created_by) REFERENCES users_app(u_id) ON DELETE RESTRICT,
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
  CONSTRAINT fk_filter_shares_user FOREIGN KEY (fs_shared_with) REFERENCES users_app(u_id) ON DELETE RESTRICT,
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
  cp_u_id INTEGER NOT NULL,    -- foreign key to 'u_id' from users_app table
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
  CONSTRAINT fk_campaign_poc_cp_u_id FOREIGN KEY (cp_u_id) REFERENCES users_app(u_id) ON DELETE RESTRICT,
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
  CONSTRAINT fk_brand_approvals_user FOREIGN KEY (ba_approved_by_user_id) REFERENCES users_app(u_id) ON DELETE RESTRICT,
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
  dpa_actor_u_id          INTEGER, -- foreign key to 'u_id' from users_app table, can be NULL for system actions
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
  CONSTRAINT fk_deliverable_activity_actor FOREIGN KEY (dpa_actor_u_id) REFERENCES users_app(u_id) ON DELETE RESTRICT,
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
  da_uploaded_by_id     INTEGER, -- foreign key to 'u_id' from users_app table, can be NULL for system uploads
  da_approved_by_id     INTEGER, -- foreign key to 'u_id' from users_app table, can be NULL if not approved yet
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
  CONSTRAINT fk_deliverable_attachments_uploaded_by FOREIGN KEY (da_uploaded_by_id) REFERENCES users_app(u_id) ON DELETE RESTRICT,
  CONSTRAINT fk_deliverable_attachments_approved_by FOREIGN KEY (da_approved_by_id) REFERENCES users_app(u_id) ON DELETE RESTRICT
);

---------- table deliverable_approvals ----------
CREATE TYPE approval_type_enum AS ENUM ('script', 'assets', 'deliverable', 'insights');
CREATE TYPE approval_status_enum AS ENUM ('pending', 'approved', 'rejected', 'sent_to_client');

CREATE TABLE deliverable_approvals (
  dap_id BIGSERIAL PRIMARY KEY,
  dap_dp_id INTEGER NOT NULL,    -- foreign key to 'dp_id' from deliverable_proposals table
  dap_approval_type approval_type_enum NOT NULL,
  dap_status approval_status_enum NOT NULL DEFAULT 'pending',
  dap_approved_by_id INTEGER, -- foreign key to 'u_id' from users_app table, can be NULL if not approved yet
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
  CONSTRAINT fk_deliverable_approvals_approved_by FOREIGN KEY (dap_approved_by_id) REFERENCES users_app(u_id) ON DELETE SET NULL
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
  CONSTRAINT fk_deliverable_comments_actor FOREIGN KEY (dc_actor_id) REFERENCES users_app(u_id) ON DELETE RESTRICT
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

  INSERT INTO public.users_app (  -- FIXED: Corrected table name to users_app
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





-- -- =================================================================================================================
-- -- ************************************************ INSERT QUERIES *************************************************
-- -- ************************************************ INSERT QUERIES *************************************************
-- -- ************************************************ INSERT QUERIES *************************************************
-- -- ************************************************ INSERT QUERIES *************************************************
-- -- ************************************************ INSERT QUERIES *************************************************
-- -- =================================================================================================================

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
-- ('Account Management', 'Handles client account operations', 'active', 1);


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


---------- insert into brand_products_services ----------
-- -- Flipkart
-- INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
-- VALUES
-- (1, 'Flipkart Plus Membership', 'Loyalty program offering free delivery and early access to sales.', 'Membership', '₹0–₹999', 1),
-- (1, 'Flipkart Health+', 'Online pharmacy service providing medicines and healthcare 0products.', 'Healthcare', '₹50–₹5,000', 1);

-- -- Amazon India
-- INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
-- VALUES
-- (2, 'Amazon Prime', 'Subscription offering fast delivery, Prime Video, and more.', 'Subscription', '₹179/month', 2),
-- (2, 'Amazon Pay', 'Digital wallet for seamless transactions on and off Amazon.', 'Fintech', 'Varies', 2);

-- -- Meesho
-- INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
-- VALUES
-- (3, 'Reseller Platform', 'Enables individuals to resell products via social media.', 'E-commerce', '₹100–₹5,000', 3),
-- (3, 'Meesho Supplier Hub', 'Platform for suppliers to list products for resellers.', 'Marketplace', 'Varies', 3);

-- -- Puma India
-- INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
-- VALUES
-- (4, 'Running Shoes', 'High-performance footwear for athletes.', 'Footwear', '₹2,000–₹10,000', 4),
-- (4, 'Athleisure Apparel', 'Stylish and comfortable sportswear.', 'Apparel', '₹1,000–₹8,000', 4);

-- -- Dream11
-- INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
-- VALUES
-- (5, 'Fantasy Cricket', 'Platform to create virtual cricket teams and win prizes.', 'Gaming', '₹0–₹1,000', 5),
-- (5, 'Fantasy Football', 'Engage in virtual football leagues.', 'Gaming', '₹0–₹1,000', 5);

-- -- Google
-- INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
-- VALUES
-- (6, 'Google Search', 'Search engine providing information on the web.', 'Technology', 'Free', 6),
-- (6, 'Google Ads', 'Online advertising platform for businesses.', 'Advertising', 'Varies', 6);

-- -- Myntra
-- INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
-- VALUES
-- (7, 'Fashion E-commerce', 'Online platform for clothing and accessories.', 'Retail', '₹500–₹10,000', 7),
-- (7, 'Myntra Insider', 'Loyalty program offering exclusive benefits.', 'Membership', 'Free–₹999', 7);

-- -- Netflix
-- INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
-- VALUES
-- (8, 'Streaming Service', 'Subscription-based platform for movies and TV shows.', 'Entertainment', '₹199–₹799/month', 8),
-- (8, 'Netflix Originals', 'Exclusive content produced by Netflix.', 'Entertainment', 'Included in subscription', 8);

-- -- Sugar
-- INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
-- VALUES
-- (9, 'Matte Lipsticks', 'Long-lasting lipsticks in various shades.', 'Cosmetics', '₹499–₹799', 9),
-- (9, 'Face Makeup', 'Range of foundations and concealers.', 'Cosmetics', '₹599–₹1,199', 9);

-- -- Apple
-- INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
-- VALUES
-- (10, 'iPhone 16 Pro', 'Latest smartphone with advanced features.', 'Electronics', '₹61,855', 10),
-- (10, 'MacBook Air M3', 'Lightweight laptop with M3 chip.', 'Computers', '₹92,000–₹1,20,000', 10);

-- -- Samsung
-- INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
-- VALUES
-- (11, 'Galaxy S25', 'Flagship smartphone with cutting-edge technology.', 'Electronics', '₹70,000–₹1,10,000', 11),
-- (11, 'QLED TVs', 'High-definition televisions with QLED display.', 'Home Appliances', '₹50,000–₹2,00,000', 11);

-- -- Mamaearth
-- INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
-- VALUES
-- (12, 'Natural Skincare', 'Products made with natural ingredients.', 'Personal Care', '₹299–₹999', 12),
-- (12, 'Baby Care Range', 'Safe products for babies and toddlers.', 'Personal Care', '₹199–₹799', 12);

-- -- Allen Solly
-- INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
-- VALUES
-- (13, 'Formal Wear', 'Business attire for men and women.', 'Apparel', '₹1,000–₹5,000', 13),
-- (13, 'Casual Clothing', 'Everyday wear with a stylish touch.', 'Apparel', '₹800–₹3,000', 13);

-- -- Intel
-- INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
-- VALUES
-- (14, 'Intel Core i9', 'High-performance processors for computing.', 'Technology', '₹30,000–₹60,000', 14),
-- (14, 'Intel Arc GPUs', 'Graphics processing units for gaming and design.', 'Technology', '₹20,000–₹50,000', 14);

-- -- Realme
-- INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
-- VALUES
-- (15, 'Realme GT Series', 'Smartphones with powerful performance.', 'Electronics', '₹25,000–₹40,000', 15),
-- (15, 'Realme Buds Air', 'Wireless earbuds with noise cancellation.', 'Accessories', '₹3,000–₹5,000', 15);

-- ---------- insert into brand_competitors table ----------
-- -- Amazon India Competitors
-- INSERT INTO brand_competitors (bc_b_id, bc_competitor_name, bc_type, bc_market_share, bc_strengths, bc_weaknesses, bc_website, bc_t_id)
-- VALUES
-- (2, 'Flipkart', 'direct', '45%', 'Strong presence in Indian market.', 'Limited global reach.', 'https://www.flipkart.com', 1),
-- (2, 'Reliance Digital', 'indirect', '10%', 'Wide offline network.', 'Less online presence.', 'https://www.reliancedigital.in', 1);

-- -- Meesho Competitors
-- INSERT INTO brand_competitors (bc_b_id, bc_competitor_name, bc_type, bc_market_share, bc_strengths, bc_weaknesses, bc_website, bc_t_id)
-- VALUES
-- (3, 'GlowRoad', 'direct', '15%', 'Strong reseller network.', 'Limited product categories.', 'https://www.glowroad.com', 1),
-- (3, 'Shop101', 'indirect', '10%', 'User-friendly platform.', 'Smaller supplier base.', 'https://www.shop101.com', 1);

-- -- Puma India Competitors
-- INSERT INTO brand_competitors (bc_b_id, bc_competitor_name, bc_type, bc_market_share, bc_strengths, bc_weaknesses, bc_website, bc_t_id)
-- VALUES
-- (4, 'Nike India', 'direct', '30%', 'Innovative designs.', 'Premium pricing.', 'https://www.nike.com/in', 1),
-- (4, 'Adidas India', 'direct', '25%', 'Strong brand loyalty.', 'Limited customization.', 'https://www.adidas.co.in', 1);

-- -- Dream11 Competitors
-- INSERT INTO brand_competitors (bc_b_id, bc_competitor_name, bc_type, bc_market_share, bc_strengths, bc_weaknesses, bc_website, bc_t_id)
-- VALUES
-- (5, 'My11Circle', 'direct', '20%', 'Celebrity endorsements.', 'Smaller user base.', 'https://www.my11circle.com', 1),
-- (5, 'FanFight', 'indirect', '10%', 'Easy-to-use interface.', 'Fewer contests.', 'https://www.fanfight.com', 1);


-- ---------- insert into users_app ----------
-- ----- Insert into auth.users -----

-- -- Account Management
-- INSERT INTO auth.users (id, display_name, email, locale, avatar_url)
-- VALUES
--   (gen_random_uuid(), 'Sadiq Shaikh', 'sadiq.shaikh@famekeeda.com', 'en', 'https://drive.google.com/file/d/1Nsza3vV1wClMy2FXYu1igGrgqE3s2UPc/view?usp=drive_link'),
--   (gen_random_uuid(), 'Melwyn John', 'melwyn@famekeeda.com', 'en', 'https://drive.google.com/file/d/12pnT9jQELaRRi9WncyPuEhQmBO2srOjS/view?usp=drive_link'),
--   (gen_random_uuid(), 'Shraddha Gadkari', 'shraddha@famekeeda.com', 'en', 'https://drive.google.com/file/d/191Q4_qZlX4Yt-IfOy55KNfqzeOSx6qo9/view?usp=drive_link'),
--   (gen_random_uuid(), 'Anushka Kadam', 'anushka.kadam@famekeeda.com', 'en', 'https://drive.google.com/file/d/1Nsza3vV1wClMy2FXYu1igGrgqE3s2UPc/view?usp=drive_link'),
--   (gen_random_uuid(), 'Sonya Punjabi', 'sonya.punjabi@searchffiliate.com', 'en', 'https://drive.google.com/file/d/1KdYJ05P3TqMAyb3GaVmUidK1PmPZymAa/view?usp=drive_link'),
--   (gen_random_uuid(), 'Shaibal Sutradhar', 'shaibal.sutradhar@famekeeda.com', 'en', 'https://drive.google.com/file/d/1lSdQgw_MhuXr62ohwsVqLOvHwYNI3ymT/view?usp=drive_link'),
--   (gen_random_uuid(), 'Parmi Nanda', 'parmi.nanda@famekeeda.com', 'en', 'https://drive.google.com/file/d/1eUUCOW-utL323EDCZeOQ2EqE5Y3_M3Zv/view?usp=drive_link');

-- -- Influencers Relations (tm_id = 1)
-- INSERT INTO auth.users (id, display_name, email, locale, avatar_url)
-- VALUES 
--   (gen_random_uuid(), 'Rumana Khan', 'rumana@famekeeda.com', 'en', 'https://drive.google.com/file/d/1Cl11NINkOgMvBq0NWmc1G24r9PYvOleC/view?usp=drive_link'),
--   (gen_random_uuid(), 'Shreesha Sharma', 'shreesha@famekeeda.com', 'en', 'https://drive.google.com/file/d/12pnT9jQELaRRi9WncyPuEhQmBO2srOjS/view?usp=drive_link'),
--   (gen_random_uuid(), 'Ganesh Alakuntha', 'ganesh.a@famekeeda.com', 'en', 'https://drive.google.com/file/d/1YY5V9nvHWzk1ml5OCCxXbf7YgQRBQ_93/view?usp=drive_link'),
--   (gen_random_uuid(), 'Prajakta Kadam', 'prajakta.kadam@famekeeda.com', 'en', 'https://drive.google.com/file/d/129Inr4s15R1mtAIkrAOrBO254dIXYYx5/view?usp=drive_link'),
--   (gen_random_uuid(), 'Jaiee Mohare', 'jaiee.mohare@famekeeda.com', 'en', 'https://drive.google.com/file/d/1Y1Yxcpkj2kfWt4rsVp7Nyix162544h6k/view?usp=drive_link'),
--   (gen_random_uuid(), 'Arshiya Chakraborty', 'arshiya.chakraborty@famekeeda.com', 'en', 'https://drive.google.com/file/d/1CgXDS_-dzzVKeQl8_NIyND2QryXPdj8p/view?usp=drive_link');

-- -- Client Success (tm_id = 10)
-- INSERT INTO auth.users (id, display_name, email, locale, avatar_url)
-- VALUES 
--   (gen_random_uuid(), 'Pratik Mhatre', 'pratik.mhatre@famekeeda.com', 'en', 'https://drive.google.com/file/d/1h0MOF7qugytXFOIGNir7U5JPFoJkrnzO/view?usp=drive_link');

-- ----- update users_app -----
-- -- Assign users 1-2 to R&D Subteam (tm_id = 16)
-- UPDATE users_app SET u_tm_id = 16 WHERE u_id IN (1, 2);

-- -- Assign users 3-7 to Account Management (tm_id = 21)
-- UPDATE users_app SET u_tm_id = 21 WHERE u_id IN (3, 4, 5, 6, 7);

-- -- Assign users 8-13 to Influencers Relations (tm_id = 1)
-- UPDATE users_app SET u_tm_id = 1 WHERE u_id IN (8, 9, 10, 11, 12, 13);

-- -- Assign user 14 to Client Success (tm_id = 10)
-- UPDATE users_app SET u_tm_id = 10 WHERE u_id = 14;


-- ---------- insert into campaign ----------
-- Insert into campaigns table (updated schema)

-- INSERT INTO campaigns (
--   c_b_id, c_t_id, c_status, c_name, c_budget, c_budget_currency, c_p_id,
--   c_start_date, c_end_date, c_products_services, c_business_objectives,
--   c_target_age_from, c_target_age_to, c_target_gender, c_target_income,
--   c_target_locations, c_target_education_levels, c_target_languages,
--   c_target_interests, c_behavioral_patterns, c_psychographics,
--   c_technographics, c_purchase_intent, c_additional_demographics,
--   c_inf_followers_range, c_inf_engagement_rate, c_inf_genres, c_inf_niches,
--   c_inf_locations, c_inf_age_from, c_inf_age_to, c_inf_languages,
--   c_inf_primary_platform_id, c_inf_last_post_days, c_inf_payment_terms,
--   c_worked_with_promoted_competitors, c_previously_worked_with_brand,
--   c_poc_brand_name, c_poc_brand_designation, c_poc_brand_email, c_poc_brand_phone
-- )
-- VALUES (
--   1, -- c_b_id (Flipkart)
--   1, -- c_t_id (Fame Keeda)
--   'active',
--   'Flipkart Fashion Fiesta',
--   1000000.00,
--   'INR',
--   NULL, -- c_p_id (Assuming no specific product IDs)
--   '2025-08-01',
--   '2025-08-31',
--   'Apparel, Footwear, Accessories',
--   'Increase fashion segment sales and brand visibility among young adults.',
--   18,
--   35,
--   'all',
--   '4-6LPA',
--   '["Delhi", "Mumbai", "Bangalore", "Hyderabad"]',
--   '["Bachelor''s Degree", "Master''s Degree"]',
--   '["English", "Hindi"]',
--   '["Fashion", "Lifestyle", "Shopping"]',
--   'Frequent online shoppers with interest in latest fashion trends.',
--   'Value-conscious, trend-aware, and socially active individuals.',
--   'Active on mobile platforms, responsive to digital marketing.',
--   'High intent to purchase during festive sales.',
--   'Urban dwellers with access to online shopping platforms.',
--   'Micro',
--   '4-6%',
--   '["Fashion", "Lifestyle"]',
--   '["Streetwear", "Ethnic Wear"]',
--   '["Delhi", "Mumbai", "Bangalore", "Hyderabad"]',
--   18,
--   35,
--   '["English", "Hindi"]',
--   '["Instagram", "YouTube"]',
--   '30 days',
--   'NET 30',
--   false,
--   false,
--   'Anjali Sharma',
--   'Marketing Manager',
--   'anjali.sharma@flipkart.com',
--   '+91-9876543210'
-- );

-- Insert into campaigns table
-- INSERT INTO campaigns (
--   c_b_id, c_t_id, c_status, c_name, c_budget, c_budget_currency, c_p_id,
--   c_start_date, c_end_date, c_products_services, c_business_objectives,
--   c_target_age_from, c_target_age_to, c_target_gender, c_target_income,
--   c_target_locations, c_target_education_levels, c_target_languages,
--   c_target_interests, c_behavioral_patterns, c_psychographics,
--   c_technographics, c_purchase_intent, c_additional_demographics,
--   c_inf_followers_range, c_inf_engagement_rate, c_inf_genres, c_inf_niches,
--   c_inf_locations, c_inf_age_from, c_inf_age_to, c_inf_languages,
--   c_inf_primary_platform_id, c_inf_last_post_days, c_inf_payment_terms,
--   c_worked_with_promoted_competitors, c_previously_worked_with_brand,
--   c_poc_brand_name, c_poc_brand_designation, c_poc_brand_email, c_poc_brand_phone
-- )
-- VALUES (
--   1, -- c_b_id (Flipkart)
--   1, -- c_t_id (Fame Keeda)
--   'active',
--   'Flipkart Big Billion Days 2025',
--   5000000.00,
--   'INR',
--   NULL, -- c_p_id (Assuming no specific product IDs)
--   '2025-10-01',
--   '2025-10-10',
--   'Electronics, Fashion, Home Appliances, Books, Furniture',
--   'Boost sales across all categories during the festive season and increase market share.',
--   18,
--   45,
--   'all',
--   '6-10LPA',
--   '["Delhi", "Mumbai", "Bangalore", "Chennai", "Kolkata"]',
--   '["Bachelor''s Degree", "Master''s Degree"]',
--   '["English", "Hindi"]',
--   '["Online Shopping", "Festive Deals", "Electronics", "Fashion"]',
--   'Price-sensitive shoppers looking for festive deals.',
--   'Value-driven, tech-savvy, and deal-seeking individuals.',
--   'Active on e-commerce platforms, responsive to digital marketing.',
--   'High intent to purchase during festive sales.',
--   'Urban and semi-urban dwellers with access to online shopping platforms.',
--   'Macro',
--   '6-10%',
--   '["Technology", "Lifestyle", "Fashion"]',
--   '["Smartphones", "Home Decor", "Apparel"]',
--   '["Delhi", "Mumbai", "Bangalore", "Chennai", "Kolkata"]',
--   18,
--   45,
--   '["English", "Hindi"]',
--   '["Instagram", "YouTube", "Facebook"]',
--   '30 days',
--   'NET 30',
--   false,
--   true,
--   'Ravi Kumar',
--   'Senior Marketing Manager',
--   'ravi.kumar@flipkart.com',
--   '+91-9123456789'
-- );

-- -- Insert into campaigns table
-- INSERT INTO campaigns (
--   c_b_id, c_t_id, c_status, c_name, c_budget, c_budget_currency, c_p_id,
--   c_start_date, c_end_date, c_products_services, c_business_objectives,
--   c_target_age_from, c_target_age_to, c_target_gender, c_target_income,
--   c_target_locations, c_target_education_levels, c_target_languages,
--   c_target_interests, c_behavioral_patterns, c_psychographics,
--   c_technographics, c_purchase_intent, c_additional_demographics,
--   c_inf_followers_range, c_inf_engagement_rate, c_inf_genres, c_inf_niches,
--   c_inf_locations, c_inf_age_from, c_inf_age_to, c_inf_languages,
--   c_inf_primary_platform_id, c_inf_last_post_days, c_inf_payment_terms,
--   c_worked_with_promoted_competitors, c_previously_worked_with_brand,
--   c_poc_brand_name, c_poc_brand_designation, c_poc_brand_email, c_poc_brand_phone
-- )
-- VALUES (
--   2, -- c_b_id (Amazon India)
--   1, -- c_t_id (Fame Keeda)
--   'active',
--   'Aur Dikhao 2.0',
--   1500000.00,
--   'INR',
--   NULL, -- c_p_id (Assuming no specific product IDs)
--   '2025-09-01',
--   '2025-09-30',
--   'Electronics, Home Appliances, Fashion, Books',
--   'Enhance product visibility and customer engagement across diverse categories in Tier II and III cities.',
--   18,
--   45,
--   'all',
--   '6-10LPA',
--   '["Lucknow", "Jaipur", "Indore", "Patna"]',
--   '["Bachelor''s Degree", "Master''s Degree"]',
--   '["English", "Hindi"]',
--   '["Online Shopping", "Technology", "Fashion"]',
--   'Regular online shoppers seeking variety and value.',
--   'Value-driven, tech-savvy, and aspirational individuals.',
--   'Active on mobile platforms, responsive to personalized recommendations.',
--   'High intent to purchase during promotional campaigns.',
--   'Residents of emerging urban centers with growing e-commerce adoption.',
--   'Micro',
--   '4-6%',
--   '["Technology", "Lifestyle"]',
--   '["Gadgets", "Home Decor"]',
--   '["Lucknow", "Jaipur", "Indore", "Patna"]',
--   18,
--   45,
--   '["English", "Hindi"]',
--   '["Instagram", "YouTube"]',
--   '30 days',
--   'NET 30',
--   false,
--   false,
--   'Rahul Verma',
--   'Senior Marketing Manager',
--   'rahul.verma@amazon.in',
--   '+91-9876543211'
-- );

-- INSERT INTO campaigns (
--   c_b_id, c_t_id, c_status, c_name, c_budget, c_budget_currency, c_p_id,
--   c_start_date, c_end_date, c_products_services, c_business_objectives,
--   c_target_age_from, c_target_age_to, c_target_gender, c_target_income,
--   c_target_locations, c_target_education_levels, c_target_languages,
--   c_target_interests, c_behavioral_patterns, c_psychographics,
--   c_technographics, c_purchase_intent, c_additional_demographics,
--   c_inf_followers_range, c_inf_engagement_rate, c_inf_genres, c_inf_niches,
--   c_inf_locations, c_inf_age_from, c_inf_age_to, c_inf_languages,
--   c_inf_primary_platform_id, c_inf_last_post_days, c_inf_payment_terms,
--   c_worked_with_promoted_competitors, c_previously_worked_with_brand,
--   c_poc_brand_name, c_poc_brand_designation, c_poc_brand_email, c_poc_brand_phone
-- )
-- VALUES (
--   2, -- c_b_id (Amazon India)
--   2, -- c_t_id (Assumed tenant ID for Amazon India)
--   'active',
--   'Mission GraHAQ 3.0',
--   5000000.00,
--   'INR',
--   NULL,
--   '2024-12-01',
--   '2025-02-28',
--   'Consumer Awareness Programs',
--   'Enhance consumer awareness and safety, focusing on Tier II and III cities',
--   25,
--   45,
--   'all',
--   '2-4LPA',
--   '["Lucknow", "Jaipur", "Indore", "Patna", "Nagpur"]',
--   '["Bachelor''s Degree", "High School"]',
--   '["Hindi", "English"]',
--   '["Consumer Rights", "Online Shopping", "Digital Literacy"]',
--   'Consumers seeking information on safe online shopping practices',
--   'Value-conscious, digitally curious individuals',
--   'Active on social media platforms, responsive to educational content',
--   'High intent to engage with consumer awareness initiatives',
--   'Residents of Tier II and III cities with growing internet penetration',
--   'Micro',
--   '2-4%',
--   '["Education", "Awareness"]',
--   '["Consumer Advocacy", "Digital Literacy"]',
--   '["Lucknow", "Jaipur", "Indore", "Patna", "Nagpur"]',
--   25,
--   45,
--   '["Hindi", "English"]',
--   '["YouTube", "Facebook"]',
--   '30 days',
--   'NET 30',
--   false,
--   false,
--   'Ravi Desai',
--   'Director, Mass and Brand Marketing',
--   'ravi.desai@amazon.in',
--   '+91-9876543210'
-- );

-- ---------- insert into campaign_objectives ----------
-- Insert into campaign_objectives table
-- INSERT INTO campaign_objectives (
--   co_c_id, co_objective, co_kpi, co_t_id
-- )
-- VALUES
--   (
--     1, 'Enhance brand visibility among target demographics.', 'Achieve a 20% increase in social media engagement during the campaign period.', 1 
--   ),
--   (
--     1, 'Boost sales in the fashion segment.', 'Increase fashion category sales by 15% compared to the previous month.', 1
--   ),
--   (
--     1, 'Expand customer base in Tier II and III cities.', 'Acquire 10,000 new customers from targeted regions.', 1
--   );

-- Insert into campaign_objectives table
-- INSERT INTO campaign_objectives (co_c_id, co_objective, co_kpi, co_t_id)
-- VALUES
--   (2, 'Increase overall sales during the Big Billion Days event.', 'Achieve a 30% increase in sales compared to the previous month.', 1),
--   (2, 'Enhance brand visibility and customer engagement.', 'Increase website traffic by 50% and social media engagement by 40%.', 1),
--   (2, 'Expand customer base in Tier 2 and Tier 3 cities.', 'Achieve a 20% increase in new customer registrations from targeted regions.', 1);

-- Assuming the campaign ID for 'Aur Dikhao 2.0' is 2
-- INSERT INTO campaign_objectives (
--   co_c_id, co_objective, co_kpi, co_t_id
-- )
-- VALUES
--   (2, 'Increase product visibility across key categories in Tier II and III cities.', 'Achieve a 20% increase in product page views from targeted regions.', 1),
--   (2, 'Enhance customer engagement through personalized recommendations.', 'Improve click-through rates on recommended products by 15%.', 1),
--   (2, 'Boost sales during the campaign period.', 'Achieve a 25% increase in sales compared to the previous month.', 1);

-- Insert into campaign_objectives table
-- INSERT INTO campaign_objectives (co_c_id, co_objective, co_kpi, co_t_id)
-- VALUES
--   (3, 'Educate consumers about their rights and responsibilities in e-commerce', 'Reach 50 million consumers across Tier II and III cities', 2),
--   (3, 'Promote safe online shopping practices', 'Conduct 1000+ awareness sessions and workshops', 2),
--   (3, 'Enhance trust in digital transactions', 'Achieve 80% positive feedback from participants', 2);

-- INSERT INTO campaign_objectives (co_c_id, co_objective, co_kpi, co_t_id)
-- VALUES
--   (4, 'Establish Puma as a leading brand in Indian badminton.', 'Achieve 20% market share in badminton segment by Q4 2025.', 1),
--   (4, 'Increase engagement with Gen Z athletes.', 'Reach 1 million impressions among target demographic.', 1),
--   (4, 'Boost sales of badminton products.', 'Increase sales by 30% during campaign period.', 1);

-- ---------- insert into campaign_poc ----------
-- INSERT INTO campaign_poc (cp_c_id, cp_u_id, cp_t_id)
-- VALUES 
--   (1, 3, 1),  -- Shraddha Gadkari
--   (1, 9, 1),  -- Shreesha Sharma
--   (1, 14, 1); -- Pratik Mhatre

-- INSERT INTO campaign_poc (cp_c_id, cp_u_id, cp_t_id)
-- VALUES 
--   (1, 3, 1),  -- Shraddha Gadkari
--   (1, 9, 1),  -- Shreesha Sharma
--   (1, 14, 1); -- Pratik Mhatre

-- -- Assign POCs to the new campaign
-- INSERT INTO campaign_poc (cp_c_id, cp_u_id, cp_t_id)
-- VALUES 
--   (2, 3, 1),  -- Shraddha Gadkari
--   (2, 9, 1),  -- Shreesha Sharma
--   (2, 14, 1); -- Pratik Mhatre

-- Assigning POCs to the campaign
-- INSERT INTO campaign_poc (
--   cp_c_id, cp_u_id, cp_t_id
-- )
-- VALUES
--   (2, 3, 1),  -- Shraddha Gadkari
--   (2, 9, 1),  -- Shreesha Sharma
--   (2, 14, 1); -- Pratik Mhatre

-- -- Insert into campaign_poc table
-- INSERT INTO campaign_poc (cp_c_id, cp_u_id, cp_t_id)
-- VALUES
--   (3, 3, 2),  -- Shraddha Gadkari
--   (3, 9, 2),  -- Shreesha Sharma
--   (3, 14, 2); -- Pratik Mhatre

-- INSERT INTO campaign_poc (cp_c_id, cp_u_id, cp_t_id)
-- VALUES
--   (4, 3, 1),  -- Shraddha Gadkari
--   (4, 9, 1),  -- Shreesha Sharma
--   (4, 14, 1); -- Pratik Mhatre


-- ---------- insert into platforms ----------
-- INSERT INTO platforms (p_name)
-- VALUES 
--   ('YouTube'),
--   ('Instagram'),
--   ('X (Twitter)'),
--   ('LinkedIn'),
--   ('Facebook'),
--   ('Telegram');


-- ---------- insert into deliverable_types ---------- 
-- INSERT INTO deliverable_types (dt_name, dt_t_id)
-- VALUES 
--   ('Reels', 1),
--   ('Collab Reels', 1),
--   ('Static Posts', 1),
--   ('Video Post', 1),
--   ('Carousel Post', 1),
--   ('Carousel Video', 1),
--   ('Swipe Up Story', 1),
--   ('Link Story', 1),
--   ('Static Story', 1),
--   ('Video Story', 1),
--   ('Repost Story', 1),
--   ('Live', 1),
--   ('Conceptual Video', 1),
--   ('Integrated Video', 1),
--   ('Dedicated Video', 1),
--   ('YouTube Shorts', 1),
--   ('Community Post', 1),
--   ('Pre-roll/Post-roll Ads', 1),
--   ('Product Placement', 1),
--   ('Polls', 1),
--   ('Reshare', 1),
--   ('Retweet', 1);


-- ---------- insert into platform_deliverables ----------
-- INSERT INTO platform_deliverables (pd_p_id, pd_dt_id, pd_t_id)
-- VALUES
--   (1, 13, 1), -- Conceptual Video
--   (1, 14, 1), -- Integrated Video
--   (1, 15, 1), -- Dedicated Video
--   (1, 16, 1), -- YouTube Shorts
--   (1, 17, 1), -- Community Post
--   (1, 18, 1), -- Pre-roll/Post-roll Ads
--   (1, 19, 1), -- Product Placement
--   (1, 12, 1); -- Live

-- INSERT INTO platform_deliverables (pd_p_id, pd_dt_id, pd_t_id)
-- VALUES
--   (2, 1, 1),  -- Reels
--   (2, 2, 1),  -- Collab Reels
--   (2, 3, 1),  -- Static Posts
--   (2, 4, 1),  -- Video Post
--   (2, 5, 1),  -- Carousel Post
--   (2, 6, 1),  -- Carousel Video
--   (2, 7, 1),  -- Swipe Up Story
--   (2, 8, 1),  -- Link Story
--   (2, 9, 1),  -- Static Story
--   (2, 10, 1), -- Video Story
--   (2, 11, 1), -- Repost Story
--   (2, 12, 1); -- Live

-- INSERT INTO platform_deliverables (pd_p_id, pd_dt_id, pd_t_id)
-- VALUES
--   (3, 3, 1),  -- Static Posts
--   (3, 4, 1),  -- Video Post
--   (3, 22, 1); -- Retweet

-- INSERT INTO platform_deliverables (pd_p_id, pd_dt_id, pd_t_id)
-- VALUES
--   (4, 3, 1),  -- Static Posts
--   (4, 4, 1),  -- Video Post
--   (4, 21, 1), -- Reshare
--   (4, 12, 1), -- Live
--   (4, 20, 1); -- Polls

-- INSERT INTO platform_deliverables (pd_p_id, pd_dt_id, pd_t_id)
-- VALUES
--   (5, 3, 1),  -- Static Posts
--   (5, 4, 1),  -- Video Post
--   (5, 5, 1),  -- Carousel Post
--   (5, 6, 1),  -- Carousel Video
--   (5, 7, 1),  -- Swipe Up Story
--   (5, 8, 1),  -- Link Story
--   (5, 9, 1),  -- Static Story
--   (5, 10, 1), -- Video Story
--   (5, 11, 1), -- Repost Story
--   (5, 12, 1); -- Live

-- INSERT INTO platform_deliverables (pd_p_id, pd_dt_id, pd_t_id)
-- VALUES
--   (6, 3, 1),  -- Static Posts
--   (6, 4, 1),  -- Video Post
--   (6, 11, 1), -- Repost Story
--   (6, 20, 1); -- Polls


-- ---------- insert into campaign_lists ----------
-- INSERT INTO campaign_lists (cl_name, cl_c_id, cl_t_id)
-- VALUES 
--   ('Flipkart Fashion Fiesta - Nano Boosters', 1, 1),
--   ('Flipkart Fashion Fiesta - Brand Legends', 1, 1),
--   ('Flipkart Fashion Fiesta - Sales Warriors', 1, 1),
--   ('Flipkart Fashion Fiesta - ROAS Max Pack', 1, 1),
--   ('Flipkart Fashion Fiesta - Celeb Amplifiers', 1, 1),
--   ('Flipkart Fashion Fiesta - High Turn Up Reserve', 1, 1);

-- INSERT INTO campaign_lists (cl_name, cl_c_id, cl_t_id)
-- VALUES 
--   ('Aur Dikhao 2.0 - Viral Amplifiers', 3, 1),
--   ('Aur Dikhao 2.0 - Regional Dominators', 3, 1),
--   ('Aur Dikhao 2.0 - Conversion Kings', 3, 1),
--   ('Aur Dikhao 2.0 - Brand Storytellers', 3, 1);

-- INSERT INTO campaign_lists (cl_name, cl_c_id, cl_t_id)
-- VALUES 
--   ('Flipkart Big Billion Days 2025 - Mega Converters', 2, 1),
--   ('Flipkart Big Billion Days 2025 - Tier II Warriors', 2, 1),
--   ('Flipkart Big Billion Days 2025 - ROAS Max Squad', 2, 1);

-- INSERT INTO campaign_lists (cl_name, cl_c_id, cl_t_id)
-- VALUES 
--   ('Mission GraHAQ 3.0 - Consumer Advocates', 4, 1),
--   ('Mission GraHAQ 3.0 - Awareness Amplifiers', 4, 1),
--   ('Mission GraHAQ 3.0 - Trust Builders', 4, 1),
--   ('Mission GraHAQ 3.0 - Safety Champions', 4, 1);

-- INSERT INTO campaign_lists (cl_name, cl_c_id, cl_t_id)
-- VALUES 
--   ('PVMA – Smash the Limits - Gen Z Athletes', 5, 1),
--   ('PVMA – Smash the Limits - Power Performers', 5, 1),
--   ('PVMA – Smash the Limits - Hyper Local Creators', 5, 1),
--   ('PVMA – Smash the Limits - Endurance Stars', 5, 1),
--   ('PVMA – Smash the Limits - National Icons', 5, 1);




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


-- DROP TABLE IF EXISTS campaign_lists CASCADE;
-- DROP TABLE IF EXISTS influencer_proposals CASCADE;
-- DROP TABLE IF EXISTS deliverable_proposals CASCADE;
-- DROP TABLE IF EXISTS cart_details CASCADE;
-- DROP TABLE IF EXISTS cart_items CASCADE;
-- DROP TABLE IF EXISTS brand_approvals CASCADE;
-- DROP TABLE IF EXISTS deliverable_proposals_activity CASCADE;
-- DROP TABLE IF EXISTS deliverable_attachments CASCADE;
-- DROP TABLE IF EXISTS deliverable_approvals CASCADE;
-- DROP TABLE IF EXISTS deliverable_comments CASCADE;


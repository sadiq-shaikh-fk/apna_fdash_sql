------------------------------------------------ This file contains the SQL code to create the tables for the FDash Database. --------------------------------------------------

------------------------- INITIAL SETUP -------------------------

---------- table gods_eye ----------
CREATE TABLE gods_eye (
  ge_id serial primary key,
  ge_name varchar not null,
  ge_password varchar not null,
  -- audit and logs 
  created_by VARCHAR NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- constraints
  CONSTRAINT uk_gods_eye_name UNIQUE (ge_name)
);

---------- table users ----------
CREATE TABLE users (
  u_id serial PRIMARY KEY,
  u_email varchar NOT NULL,
  u_phone_number bigint NOT NULL,
  u_password varchar NOT NULL,  -- hashed password
  u_oauth_token varchar,  -- not null from front end
  u_is_authorized boolean NOT NULL,    -- boolean for invited members only to workspace
  u_user_type user_enum DEFAULT 'general' NOT NULL,  -- removed quotes from enum value
  u_is_active boolean NOT NULL,
  u_o_id integer NOT NULL,
  u_t_id integer NOT NULL,
  u_r_id integer NOT NULL,
  u_is_workspace_admin boolean NOT NULL,
  -- audit and logs 
  created_by VARCHAR NOT NULL DEFAULT current_user,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  modified_by VARCHAR NOT NULL DEFAULT current_user,
  modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_users_team FOREIGN KEY (u_t_id) REFERENCES teams(t_id),
  CONSTRAINT fk_users_organization FOREIGN KEY (u_o_id) REFERENCES organizations(o_id),
  CONSTRAINT fk_users_role FOREIGN KEY (u_r_id) REFERENCES roles(r_id)

);

-- Create enum type first
CREATE TYPE user_enum AS ENUM ('general', 'agency', 'brand');

---------- table organizations ----------
CREATE TABLE organizations (
  o_id serial PRIMARY KEY,
  o_name varchar DEFAULT 'Freemium' NOT NULL,
  -- audit and logs 
  createdby varchar not null default current_user,
  createdat timestamp not null default current_timestamp,
  modifiedby varchar not null default current_user,
  modifiedat timestamp not null default current_timestamp
);

---------- table teams ----------
CREATE TABLE teams (
  t_id serial PRIMARY KEY,
  t_name varchar NOT NULL,
  t_is_active boolean NOT NULL,
  t_o_id integer,
  -- audit and logs 
  createdby varchar not null default current_user,
  createdat timestamp not null default current_timestamp,
  modifiedby varchar not null default current_user,
  modifiedat timestamp not null default current_timestamp,
  -- Foreign key constraints
  CONSTRAINT fk_teams_organization FOREIGN KEY (t_o_id) REFERENCES organizations(o_id)
);
-- Create enum type first
CREATE TYPE o_type_enum AS ENUM ('general', 'agency', 'brand');

---------- table user_invites ----------
CREATE TABLE user_invites (
  ui_id serial PRIMARY KEY,
  ui_token varchar,
  ui_status ui_invite_status_enum,  -- checking the status of the invite
  ui_sent_by_u_id integer,          -- send bya user of super_admin
  ui_sent_to_email varchar,         -- send to a user of user_agency
  ui_expiry_at timestamp,           -- current_timestamp + 12 days
  ui_redeemed_at timestamp,         -- when the user has accepted the invite
  ui_r_id integer,
  -- audit and logs 
  createdby varchar not null default current_user,
  createdat timestamp not null default current_timestamp,
  modifiedby varchar not null default current_user,
  modifiedat timestamp not null default current_timestamp, 
  -- Foreign key constraints
  CONSTRAINT fk_user_invites_sent_by FOREIGN KEY (ui_sent_by_u_id) REFERENCES users(u_id),
  CONSTRAINT fk_user_invites_role FOREIGN KEY (ui_r_id) REFERENCES roles(r_id)
);
-- Create enum type for user invites
CREATE TYPE ui_invite_status_enum AS ENUM ('pending', 'accepted', 'expired');


---------- table modules ----------
CREATE TABLE modules (
  m_id serial PRIMARY KEY,
  m_name varchar,
  -- audit and logs 
  created_by varchar DEFAULT current_user NOT NULL,
  created_at timestamp DEFAULT current_timestamp NOT NULL,
  modified_by varchar DEFAULT current_user NOT NULL,
  modified_at timestamp DEFAULT current_timestamp NOT NULL
);

---------- table features ----------
CREATE TABLE features (
  f_id serial PRIMARY KEY,
  f_name varchar,
  f_m_id integer,
  -- audit and logs 
  created_by varchar DEFAULT current_user NOT NULL,
  created_at timestamp DEFAULT current_timestamp NOT NULL,
  modified_by varchar DEFAULT current_user NOT NULL,
  modified_at timestamp DEFAULT current_timestamp NOT NULL,
  
  -- Foreign key constraints
  CONSTRAINT fk_features_module FOREIGN KEY (f_m_id) REFERENCES modules(m_id)
);

---------- table access ----------
CREATE TABLE access (
  a_id serial PRIMARY KEY,
  a_name varchar,
  -- audit and logs 
  created_by varchar DEFAULT current_user NOT NULL,
  created_at timestamp DEFAULT current_timestamp NOT NULL,
  modified_by varchar DEFAULT current_user NOT NULL,
  modified_at timestamp DEFAULT current_timestamp NOT NULL
);

---------- table roles ----------
CREATE TABLE roles (
  r_id serial PRIMARY KEY,
  r_name varchar,
  r_o_id integer,
  -- audit and logs 
  created_by varchar DEFAULT current_user NOT NULL,
  created_at timestamp DEFAULT current_timestamp NOT NULL,
  modified_by varchar DEFAULT current_user NOT NULL,
  modified_at timestamp DEFAULT current_timestamp NOT NULL,
  
  -- Foreign key constraints
  CONSTRAINT fk_roles_organization FOREIGN KEY (r_o_id) REFERENCES organizations(o_id)
);

---------- table roles_assignment ----------
CREATE TABLE roles_assignment (
  ra_id serial PRIMARY KEY,
  ra_r_id integer,
  ra_m_id integer,
  ra_f_id integer,
  ra_a_id integer,
  -- audit and logs 
  created_by integer NOT NULL,
  created_at timestamp DEFAULT current_timestamp NOT NULL,
  modified_by integer NOT NULL,
  modified_at timestamp DEFAULT current_timestamp NOT NULL,  
  -- Foreign key constraints
  CONSTRAINT fk_roles_assignment_role FOREIGN KEY (ra_r_id) REFERENCES roles(r_id),
  CONSTRAINT fk_roles_assignment_module FOREIGN KEY (ra_m_id) REFERENCES modules(m_id),
  CONSTRAINT fk_roles_assignment_feature FOREIGN KEY (ra_f_id) REFERENCES features(f_id),
  CONSTRAINT fk_roles_assignment_access FOREIGN KEY (ra_a_id) REFERENCES access(a_id)
);

------------------------- IDM PAGE -------------------------

---------- table filters ----------
CREATE TABLE filters (
  f_id serial PRIMARY KEY,
  f_name varchar,
  f_created_by integer,  -- filter created by the user's uuid
  f_metadata json,       -- stores the filter in key-value 
  -- audit and logs
  created_by varchar DEFAULT current_user NOT NULL,
  created_at timestamp DEFAULT current_timestamp NOT NULL,
  modified_by varchar DEFAULT current_user NOT NULL,
  modified_at timestamp DEFAULT current_timestamp NOT NULL,
  -- Foreign key constraints
  CONSTRAINT fk_filters_created_by FOREIGN KEY (f_created_by) REFERENCES users(u_id)
);

----------table filters_access ---------- 
CREATE TABLE filters_access (
  fa_id serial PRIMARY KEY,
  f_id integer,
  f_shared_with integer,     -- shared with user's u_id from users table
  f_shared_access integer,   -- access_id from access table 
  -- audit and logs
  created_by varchar DEFAULT current_user NOT NULL,
  created_at timestamp DEFAULT current_timestamp NOT NULL,
  modified_by varchar DEFAULT current_user NOT NULL,
  modified_at timestamp DEFAULT current_timestamp NOT NULL,
  -- Foreign key constraints
  CONSTRAINT fk_filters_access_filter FOREIGN KEY (f_id) REFERENCES filters(f_id),
  CONSTRAINT fk_filters_access_shared_with FOREIGN KEY (f_shared_with) REFERENCES users(u_id),
  CONSTRAINT fk_filters_access_access FOREIGN KEY (f_shared_access) REFERENCES access(a_id)
);

------------------------- INFLUENCERS -------------------------


------------------------- Brands -------------------------
----------  table brands ----------
CREATE TABLE brands (
  b_id serial PRIMARY KEY,
  b_logo_url varchar,
  b_name varchar,
  b_legal_name varchar,
  b_website varchar,
  b_linkedin_url varchar,
  b_company_size varchar,  -- drop down enum values
  b_industry varchar,      -- drop down enum values
  b_market_cap varchar,    -- drop down enum values
  b_values varchar,
  b_messaging varchar,
  b_identity varchar,
  b_detailed_summary varchar,
  b_tax_info varchar,
  b_payment_terms varchar
);

----------  table brands_prod_service ----------
CREATE TABLE brands_prod_service (
  bps_id serial PRIMARY KEY,
  b_id integer,
  bps_name varchar,
  -- Foreign key constraints
  CONSTRAINT fk_brands_prod_service_brand FOREIGN KEY (b_id) REFERENCES brands(b_id)
);

---------- brands_competitor table ----------
CREATE TABLE brands_competitor (
  bc_id serial PRIMARY KEY,
  b_id integer,
  bc_name varchar,
  bc_type varchar,     -- drop down enum values - direct and indirect
  -- Foreign key constraints
  CONSTRAINT fk_brands_competitor_brand FOREIGN KEY (b_id) REFERENCES brands(b_id)
);

------------------------- CAMPAIGNS -------------------------

----------  table campaigns ----------
CREATE TABLE campaigns (
  c_id serial PRIMARY KEY,
  c_b_id integer,
  -- basic info - page 1 
  c_name varchar,
  c_budget varchar,  -- drop down enum values
  c_p_id integer,    -- platfrom id from platform table 
  c_start_date date,
  c_end_date date,
  c_bidding_start_time timestamp,
  c_bidding_end_time timestamp,
  c_prod_service varchar,
  c_business_objective varchar,
  -- target demographics -- page 2
  c_age_from integer,
  c_age_to integer,
  c_gender c_gender_enum,    -- male, female, both
  c_income c_income_enum,    -- all ranges of income
  c_target_location varchar, -- all city drop down
  c_education varchar, -- university degree
  c_language varchar,  -- all regional languages
  c_interest_hobbies varchar,
  c_behavioral_patterns varchar,
  c_psychographics varchar,
  c_technographics varchar,    --
  c_purchase_intent varchar,   --
  c_additional_info varchar,   --
  -- influencer section - page 3
  c_inf_followers_count varchar,   -- range of followers
  c_inf_eng_rate varchar,          -- range of eng_rate
  c_inf_genre varchar,
  c_inf_niche varchar,
  c_inf_location varchar,
  c_inf_age_from integer,
  c_inf_age_to integer,
  c_inf_language varchar,
  c_inf_primary_platform_id integer, -- foreign key from platforms table
  c_inf_last_post_timeline varchar,  --
  c_inf_category varchar,            -- <--------------------------- need clarification on this 
  c_inf_inf_payment_terms varchar,   -- <--------------------------- need clarification on this 
  c_has_previously_worked_with_the_brand boolean,
  c_has_worked_with_promoted_competitors boolean,
  -- poc section - page 4
  poc_cs_user_id integer,        -- CS Team user
  poc_bd_user_id integer,        -- BD Team user
  poc_ex_user_id integer,        -- EX Team user
  poc_b_name varchar,
  poc_b_designation varchar,
  poc_b_email varchar,
  poc_b_mob_no integer,
  -- Foreign key constraints
  CONSTRAINT fk_campaigns_brand FOREIGN KEY (c_b_id) REFERENCES brands(b_id),
  CONSTRAINT fk_campaigns_platform FOREIGN KEY (c_p_id) REFERENCES platforms(p_id),
  CONSTRAINT fk_campaigns_inf_platform FOREIGN KEY (c_inf_primary_platform_id) REFERENCES platforms(p_id),
  CONSTRAINT fk_campaigns_poc_cs FOREIGN KEY (poc_cs_user_id) REFERENCES users(u_id),
  CONSTRAINT fk_campaigns_poc_bd FOREIGN KEY (poc_bd_user_id) REFERENCES users(u_id),
  CONSTRAINT fk_campaigns_poc_ex FOREIGN KEY (poc_ex_user_id) REFERENCES users(u_id)
);

-- Create enum types first
CREATE TYPE c_gender_enum AS ENUM ('male', 'female', 'both');
CREATE TYPE c_income_enum AS ENUM ('2LPA - 4LPA');

-- Create campaign_objective_kpi table
CREATE TABLE campaign_objective_kpi (
  ckpi_id serial PRIMARY KEY,
  ckpi_name varchar,
  ckpi_c_id integer,
  -- Foreign key constraints
  CONSTRAINT fk_campaign_objective_kpi_campaign FOREIGN KEY (ckpi_c_id) REFERENCES campaigns(c_id)
);

-- Create campaign_platform table
CREATE TABLE campaign_platform (
  cp_id serial PRIMARY KEY,
  cp_c_id integer,
  cp_p_id integer,
  -- Foreign key constraints
  CONSTRAINT fk_campaign_platform_campaign FOREIGN KEY (cp_c_id) REFERENCES campaigns(c_id),
  CONSTRAINT fk_campaign_platform_platform FOREIGN KEY (cp_p_id) REFERENCES platforms(p_id)
);

------------------------- Campaign Lists Section ------------------------- 

----------  table lists ----------
CREATE TABLE list (
  l_id serial PRIMARY KEY,
  l_name varchar,
  l_created_by integer,        -- list creatted by user's id
  l_c_id integer,
  -- Foreign key constraints
  CONSTRAINT fk_list_campaign FOREIGN KEY (l_c_id) REFERENCES campaigns(c_id),
  CONSTRAINT fk_list_created_by FOREIGN KEY (l_created_by) REFERENCES users(u_id)
);

---------- table platforms ----------
CREATE TABLE platforms (
  p_id serial PRIMARY KEY,  -- fixed typo: serail -> serial
  p_name varchar
);

---------- table deliverables ----------
CREATE TABLE deliverables (
  d_id serial PRIMARY KEY,
  d_name varchar,
  d_ip_id integer
);

---------- table platform_deliverables_mapping ----------
CREATE TABLE platform_deliverables_mapping (
  pd_id serial PRIMARY KEY,
  p_id integer,
  d_id integer,
  -- Foreign key constraints
  CONSTRAINT fk_platform_deliverables_platform FOREIGN KEY (p_id) REFERENCES platforms(p_id),
  CONSTRAINT fk_platform_deliverables_deliverable FOREIGN KEY (d_id) REFERENCES deliverables(d_id)
);

---------- table deliverable_groups ----------
CREATE TABLE deliverable_groups (
  dg_id serial PRIMARY KEY,
  dg_l_id integer,
  dg_inf_id integer,
  dg_p_id integer,
  dg_amt bigint,
  lipd_attachment json,
  lipd_notes text,
  -- Foreign key constraints
  CONSTRAINT fk_deliverable_groups_list FOREIGN KEY (dg_l_id) REFERENCES list(l_id),
  CONSTRAINT fk_deliverable_groups_platform FOREIGN KEY (dg_p_id) REFERENCES platforms(p_id)
);

---------- table deliverable_group_items ----------
CREATE TABLE deliverable_group_items (
  dgi_id serial PRIMARY KEY,
  dg_id integer,
  dg_pd_id integer,
  dg_live_date date,
  -- Foreign key constraints
  CONSTRAINT fk_deliverable_group_items_group FOREIGN KEY (dg_id) REFERENCES deliverable_groups(dg_id),
  CONSTRAINT fk_deliverable_group_items_mapping FOREIGN KEY (dg_pd_id) REFERENCES platform_deliverables_mapping(pd_id)
);

---------- table cart ----------
CREATE TABLE cart (
  c_id serial PRIMARY KEY,
  c_l_id integer,
  c_inf_id integer,
  c_inf_metrics json,  -- might need to remove as this should direct be fetched from api
  c_p_id integer,
  c_pd_id integer,
  c_price bigint,
  c_cpv numeric,
  c_live_date date,
  cart_attachment json,
  cart_notes text,
  -- Foreign key constraints
  CONSTRAINT fk_cart_list FOREIGN KEY (c_l_id) REFERENCES list(l_id),
  CONSTRAINT fk_cart_platform FOREIGN KEY (c_p_id) REFERENCES platforms(p_id),
  CONSTRAINT fk_cart_platform_deliverable FOREIGN KEY (c_pd_id) REFERENCES platform_deliverables_mapping(pd_id)
);

-- ---------- table cart ----------
-- CREATE TABLE cart (
--   cr_id SERIAL PRIMARY KEY,
--   cr_cl_id INTEGER NOT NULL,    -- foreign key to 'cl_id' from campaign_lists table
--   cr_inf_id INTEGER NOT NULL,   -- foreign key to 'inf_id' from influencers table
--   cr_estimated_total DECIMAL(15,2) DEFAULT 0,
--   cr_notes TEXT,
--   cr_attachments JSONB,
--   cr_added_by INTEGER NOT NULL,
--   cr_converted_to_proposal_id INTEGER,
--   -- audit and logs
--   created_by VARCHAR(100) NOT NULL DEFAULT current_user,
--   created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
--   modified_by VARCHAR(100) NOT NULL DEFAULT current_user,
--   modified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
--   -- soft delete
--   is_deleted BOOLEAN NOT NULL DEFAULT false,
--   deleted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
--   deleted_by VARCHAR(100),
--   -- Foreign key constraints
--   CONSTRAINT fk_cart_cr_cl_id FOREIGN KEY (cr_cl_id) REFERENCES campaign_lists(cl_id) ON DELETE RESTRICT,
--   CONSTRAINT fk_cart_cr_inf_id FOREIGN KEY (cr_inf_id) REFERENCES influencers(inf_id) ON DELETE RESTRICT,
--   CONSTRAINT fk_cart_sc_added_by FOREIGN KEY (cr_added_by) REFERENCES users(u_id) ON DELETE RESTRICT,
--   CONSTRAINT fk_cart_proposal FOREIGN KEY (sc_converted_to_proposal_id) REFERENCES influencer_proposals(ip_id) ON DELETE RESTRICT
-- );
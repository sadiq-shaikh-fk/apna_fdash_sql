
-- =================================================================================================================
-- ************************************************ INSERT QUERIES *************************************************
-- ************************************************ INSERT QUERIES *************************************************
-- ************************************************ INSERT QUERIES *************************************************
-- ************************************************ INSERT QUERIES *************************************************
-- ************************************************ INSERT QUERIES *************************************************
-- =================================================================================================================

---------- insert into gods_eye table ----------
INSERT INTO gods_eye (ge_name, ge_password, ge_is_active, ge_last_login)
VALUES
  ('sadiq', 'sadiq@123', true, NOW() - INTERVAL '7 days'),
  ('robin', 'robin@123', false, NOW() - INTERVAL '7 days'),
  ('melwyn', 'melwyn@123', true, NOW() - INTERVAL '7 hours'),
  ('kriss', 'kriss@123', true, NOW() - INTERVAL '7 hours'),
  ('rahat', 'rahat@123', false, NOW() - INTERVAL '7 days');

---------- insert into plans ----------
INSERT INTO plans (plan_name, plan_base_price_inr, seats, brands, campaigns, ai_actions, plan_overage)
VALUES
  ('free forever', 0, 1, 1, 1, 200, '{"api_per_1k": 25, "ai_sec": 3, "storage_gb": 10}'),
  ('starter', 8999, 3, 3, 8, 1000, '{"api_per_1k": 25, "ai_sec": 3, "storage_gb": 10}'),
  ('pro', 24999, 12, 10, 25, 5000, '{"api_per_1k": 25, "ai_sec": 3, "storage_gb": 10}'),
  ('enterprise', 0, 99999999, 99999999, 99999999, 25000, '{"api_per_1k": 25, "ai_sec": 3, "storage_gb": 10}');

---------- insert into plan_features table ----------

INSERT INTO plan_features (pf_plan_id, pf_feature_value) VALUES

-- Free Forever (plan_id = 1)
(1, 'Community & Support'),
(1, 'Knowledge Base Support'),

-- Starter (plan_id = 2) 
(2, 'Email Support (24hr SLA)'),
(2, 'Chat Support (24hr SLA)'),

-- Pro (plan_id = 3)
(3, 'Priority Chat Support'),
(3, 'Dedicated Onboarding Session'),

-- Enterprise (plan_id = 4)
(4, '24/7 Dedicated Support'),
(4, 'SLA-driven CSM');

---------- Insert into organizations ----------
INSERT INTO organizations(o_name, o_slug, o_type, o_status, o_cluster_affinity, o_address, o_contact_email, o_contact_phone, o_website, o_logo_url,
o_payment_terms, o_tax_info, o_support_info, o_legal_info
)
VALUES (
  'Fame Keeda', 'famekeeda', 'agency', 'active', 'core',
  '1101, A-Wing, Rupa Renaissance, Fame Keeda, MIDC Industrial Area, Turbhe, Navi Mumbai, Maharashtra 400705',
  'info@famekeeda.com', 08655734299, 'https://www.famekeeda.com',
  'https://drive.google.com/file/d/16E57E7rZPJRYBwAJa2cLgBM2fUFIG7hB/view?usp=drive_link',
  NULL, '{"gstin": "27AAECF1428N1ZG"}', NULL, NULL
);

INSERT INTO organizations(o_name, o_slug, o_type, o_status, o_cluster_affinity, o_address, o_contact_email, o_contact_phone, o_website, o_logo_url,
o_payment_terms, o_tax_info, o_support_info, o_legal_info
)
VALUES (
  'Tech Mahindra','techmahindra', 'brand', 'active', 'techm_dedicated', 'Gateway Building, Apollo Bunder, Mumbai, Maharashtra, 400001',
  'corporate.communications@techmahindra.com',  NULL, 'https://www.techmahindra.com',  NULL, NULL, NULL, NULL, NULL
);

---------- Insert into tenants ----------
-- Fame Keeda Tenant (agency)
INSERT INTO tenants (
  t_name, t_slug, t_o_id, t_parent_t_id, t_type, t_portal_mode, 
  t_cluster_affinity, t_status, t_theme, t_plan_id, t_mrr, 
  t_trial_expires_at, t_payment_terms, t_tax_info, t_support_info, t_legal_info, t_settings
)
VALUES (  'Fame Keeda',  'famekeeda',  1,  NULL,  'agency',  'agency',  'core',  'active',  '{}'::jsonb,  4,  0,  NULL,  NULL,  '{"gstin": "27AAECF1428N1ZG"}',  NULL,  NULL,  '{}'
);


-- Tech Mahindra Tenant (brand)
INSERT INTO tenants (
  t_name, t_slug, t_o_id, t_parent_t_id, t_type, t_portal_mode, 
  t_cluster_affinity, t_status, t_theme, t_plan_id, t_mrr, 
  t_trial_expires_at, t_payment_terms, t_tax_info, t_support_info, t_legal_info, t_settings
)
VALUES (  'Tech Mahindra',  'techmahindra',  2,  NULL,  'brand',  'brand',  'techm_dedicated',  'active',  '{}'::jsonb,  3,  0,  NULL,  NULL,  NULL,  NULL,  NULL,  '{}'
);

---------- insert into subscriptions ----------
-- Fame Keeda subscription (internal, 0 price, 1 year validity)
INSERT INTO subscriptions (
  sub_t_id, sub_plan_id, sub_status, sub_start_date, sub_end_date, 
  sub_is_trial, sub_gateway, sub_gateway_customer_id, sub_gateway_subscription_id, sub_notes
)
VALUES (
  1, 4, 'active', NOW(), NOW() + INTERVAL '1 year',
  false, NULL, NULL, NULL, 'Internal free usage for Fame Keeda team'
);


-- Tech Mahindra subscription (paid, 1 month cycle)
INSERT INTO subscriptions (
  sub_t_id, sub_plan_id, sub_status, sub_start_date, sub_end_date, 
  sub_is_trial, sub_gateway, sub_gateway_customer_id, sub_gateway_subscription_id, sub_notes
)
VALUES (
  2, 3, 'active', NOW(), NOW() + INTERVAL '1 month',
  false, 'razorpay', 'cust_techm_001', 'sub_techm_001', 'Tech Mahindra SaaS billing'
);



---------- insert into invoices ----------
-- Fame Keeda invoice (internal 0 bill)
INSERT INTO invoices (
  i_t_id, i_month, i_invoice_json, i_status, i_total_inr
)
VALUES (
  1, date_trunc('month', now()), '{}'::jsonb, 'paid', 0
);

-- Tech Mahindra invoice (normal billing)
INSERT INTO invoices (
  i_t_id, i_month, i_invoice_json, i_status, i_total_inr
)
VALUES (
  2, date_trunc('month', now()), '{}'::jsonb, 'paid', 24999
);



---------- insert into payments ----------
-- Fame Keeda payment (dummy, internal, no actual gateway)
INSERT INTO payments (
  pay_sub_id, pay_t_id, pay_amount_inr, pay_currency, pay_status, 
  pay_escrow_status, pay_gateway, pay_gateway_payment_id, pay_gateway_order_id, pay_invoice_id, pay_meta
)
VALUES (
  (SELECT sub_id FROM subscriptions WHERE sub_t_id = 1), 1, 0, 'INR', 'success',
  NULL, NULL, NULL, NULL, (SELECT i_id FROM invoices WHERE i_t_id = 1), '{}'::jsonb
);


-- Tech Mahindra payment (paid through Razorpay)
INSERT INTO payments (
  pay_sub_id, pay_t_id, pay_amount_inr, pay_currency, pay_status, 
  pay_escrow_status, pay_gateway, pay_gateway_payment_id, pay_gateway_order_id, pay_invoice_id, pay_meta
)
VALUES (
  (SELECT sub_id FROM subscriptions WHERE sub_t_id = 2), 2, 24999, 'INR', 'success',
  'released', 'razorpay', 'pay_techm_001', 'order_techm_001', (SELECT i_id FROM invoices WHERE i_t_id = 2), '{}'::jsonb
);


---------- insert into teams ----------
INSERT INTO teams (tm_name, tm_description, tm_status, tm_t_id)
VALUES
('Influencers Relations', 'Influencers Relations Team', 'active', 1),
('Research & Development', 'R&D Team', 'active', 1),
('Human Resources', 'HR Team', 'active', 1),
('Branding', 'Branding & Design Team', 'active', 1),
('Affiliate Marketing', 'Affiliate Marketing Team', 'active', 1),
('Campaign Execution', 'Campaign Execution Team', 'active', 1),
('Business Development', 'Business Development Team', 'active', 1),
('Talent Management', 'Talent Management Team', 'active', 1),
('Admin', 'Administration Team', 'active', 1),
('Client Success', 'Client Success Team', 'active', 1),
('Finance', 'Finance & Accounts Team', 'active', 1),
('Management', 'Management Leadership Team', 'active', 1),
('SEO', 'SEO & Search Optimization Team', 'active', 1),
('IT', 'IT & Infra Team', 'active', 1),
('Legal', 'Legal & Compliance Team', 'active', 1),
('R&D', 'R&D Subteam', 'active', 1),
('Performance Marketing', 'Performance Marketing Team', 'active', 1),
('Product Team', 'Product Development Team', 'active', 1),
('BOD', 'Board of Directors', 'active', 1),
('Brand Strategy', 'Brand Strategy Team', 'active', 1),
('Account Management', 'Handles client account operations', 'active', 1);


---------- insert into roles ----------
-- Human Resources
INSERT INTO roles (r_name, r_description, r_t_id, r_is_system_role)
VALUES 
('Human Resources Admin', 'Admin for HR Team', 1, false),
('Human Resources Member', 'Member for HR Team', 1, false),
-- Branding
('Branding Admin', 'Admin for Branding Team', 1, false),
('Branding Member', 'Member for Branding Team', 1, false),
-- Affiliate Marketing
('Affiliate Marketing Admin', 'Admin for Affiliate Marketing Team', 1, false),
('Affiliate Marketing Member', 'Member for Affiliate Marketing Team', 1, false),
-- Campaign Execution
('Campaign Execution Admin', 'Admin for Campaign Execution Team', 1, false),
('Campaign Execution Member', 'Member for Campaign Execution Team', 1, false),
-- Business Development
('Business Development Admin', 'Admin for Business Development Team', 1, false),
('Business Development Member', 'Member for Business Development Team', 1, false),
-- Talent Management
('Talent Management Admin', 'Admin for Talent Management Team', 1, false),
('Talent Management Member', 'Member for Talent Management Team', 1, false),
-- Admin
('Admin Admin', 'Admin for Admin Team', 1, false),
('Admin Member', 'Member for Admin Team', 1, false),
-- Client Success
('Client Success Admin', 'Admin for Client Success Team', 1, false),
('Client Success Member', 'Member for Client Success Team', 1, false),
-- Finance
('Finance Admin', 'Admin for Finance Team', 1, false),
('Finance Member', 'Member for Finance Team', 1, false),
-- Management
('Management Admin', 'Admin for Management Team', 1, false),
('Management Member', 'Member for Management Team', 1, false),
-- SEO
('SEO Admin', 'Admin for SEO Team', 1, false),
('SEO Member', 'Member for SEO Team', 1, false),
-- IT
('IT Admin', 'Admin for IT Team', 1, false),
('IT Member', 'Member for IT Team', 1, false),
-- Legal
('Legal Admin', 'Admin for Legal Team', 1, false),
('Legal Member', 'Member for Legal Team', 1, false),
-- R&D
('R&D Admin', 'Admin for R&D Team', 1, false),
('R&D Member', 'Member for R&D Team', 1, false),
-- Performance Marketing
('Performance Marketing Admin', 'Admin for Performance Marketing Team', 1, false),
('Performance Marketing Member', 'Member for Performance Marketing Team', 1, false),
-- Product Team
('Product Team Admin', 'Admin for Product Team', 1, false),
('Product Team Member', 'Member for Product Team', 1, false),
-- BOD
('BOD Admin', 'Admin for Board of Directors', 1, false),
('BOD Member', 'Member for Board of Directors', 1, false),
-- Brand Strategy
('Brand Strategy Admin', 'Admin for Brand Strategy Team', 1, false),
('Brand Strategy Member', 'Member for Brand Strategy Team', 1, false);

---------- insert into system roles ----------
INSERT INTO roles (r_name, r_description, r_is_system_role)
VALUES
('Super Admin', 'Full system-wide super admin access', true),
('Platform Billing Admin', 'Manage subscriptions, invoices, payments globally', true),
('Support Agent', 'Limited read-only access for customer support', true),
('Platform Developer', 'Developer backend access for internal engineering team', true),
('Compliance Auditor', 'Security & compliance audit access', true);


---------- insert into users_app ----------
----- Insert into auth.users -----
INSERT INTO auth.users (id, display_name, email, locale, avatar_url)
VALUES
  (gen_random_uuid(), 'Sadiq Shaikh', 'sadiq.shaikh@famekeeda.com', 'en', 'https://drive.google.com/file/d/1Nsza3vV1wClMy2FXYu1igGrgqE3s2UPc/view?usp=drive_link'),
  (gen_random_uuid(), 'Melwyn John', 'melwyn@famekeeda.com', 'en', 'https://drive.google.com/file/d/12pnT9jQELaRRi9WncyPuEhQmBO2srOjS/view?usp=drive_link'),
  (gen_random_uuid(), 'Shraddha Gadkari', 'shraddha@famekeeda.com', 'en', 'https://drive.google.com/file/d/191Q4_qZlX4Yt-IfOy55KNfqzeOSx6qo9/view?usp=drive_link'),
  (gen_random_uuid(), 'Anushka Kadam', 'anushka.kadam@famekeeda.com', 'en', 'https://drive.google.com/file/d/1Nsza3vV1wClMy2FXYu1igGrgqE3s2UPc/view?usp=drive_link'),
  (gen_random_uuid(), 'Sonya Punjabi', 'sonya.punjabi@searchffiliate.com', 'en', 'https://drive.google.com/file/d/1KdYJ05P3TqMAyb3GaVmUidK1PmPZymAa/view?usp=drive_link'),
  (gen_random_uuid(), 'Shaibal Sutradhar', 'shaibal.sutradhar@famekeeda.com', 'en', 'https://drive.google.com/file/d/1lSdQgw_MhuXr62ohwsVqLOvHwYNI3ymT/view?usp=drive_link'),
  (gen_random_uuid(), 'Parmi Nanda', 'parmi.nanda@famekeeda.com', 'en', 'https://drive.google.com/file/d/1eUUCOW-utL323EDCZeOQ2EqE5Y3_M3Zv/view?usp=drive_link'),
  (gen_random_uuid(), 'Rumana Khan', 'rumana@famekeeda.com', 'en', 'https://drive.google.com/file/d/1Cl11NINkOgMvBq0NWmc1G24r9PYvOleC/view?usp=drive_link'),
  (gen_random_uuid(), 'Shreesha Sharma', 'shreesha@famekeeda.com', 'en', 'https://drive.google.com/file/d/12pnT9jQELaRRi9WncyPuEhQmBO2srOjS/view?usp=drive_link'),
  (gen_random_uuid(), 'Ganesh Alakuntha', 'ganesh.a@famekeeda.com', 'en', 'https://drive.google.com/file/d/1YY5V9nvHWzk1ml5OCCxXbf7YgQRBQ_93/view?usp=drive_link'),
  (gen_random_uuid(), 'Prajakta Kadam', 'prajakta.kadam@famekeeda.com', 'en', 'https://drive.google.com/file/d/129Inr4s15R1mtAIkrAOrBO254dIXYYx5/view?usp=drive_link'),
  (gen_random_uuid(), 'Jaiee Mohare', 'jaiee.mohare@famekeeda.com', 'en', 'https://drive.google.com/file/d/1Y1Yxcpkj2kfWt4rsVp7Nyix162544h6k/view?usp=drive_link'),
  (gen_random_uuid(), 'Arshiya Chakraborty', 'arshiya.chakraborty@famekeeda.com', 'en', 'https://drive.google.com/file/d/1CgXDS_-dzzVKeQl8_NIyND2QryXPdj8p/view?usp=drive_link'),
  (gen_random_uuid(), 'Pratik Mhatre', 'pratik.mhatre@famekeeda.com', 'en', 'https://drive.google.com/file/d/1h0MOF7qugytXFOIGNir7U5JPFoJkrnzO/view?usp=drive_link');

----- update app_users -----
-- Assign users 1-2 to R&D Subteam (tm_id = 16)
UPDATE app_users SET u_tm_id = 16 WHERE u_id IN (1, 2);

-- Assign users 3-7 to Account Management (tm_id = 21)
UPDATE app_users SET u_tm_id = 21 WHERE u_id IN (3, 4, 5, 6, 7);

-- Assign users 8-13 to Influencers Relations (tm_id = 1)
UPDATE app_users SET u_tm_id = 1 WHERE u_id IN (8, 9, 10, 11, 12, 13);

-- Assign user 14 to Client Success (tm_id = 10)
UPDATE app_users SET u_tm_id = 10 WHERE u_id = 14;

-- ----- inserting data on user_sessions and user_devices using SQL Functions (ONLY FOR TESTING) -----
-- SELECT handle_user_login(1, 'iPhone 15', 'mobile', 'Safari', 'iOS', '192.168.1.101'::inet, 'Mumbai', 'India'); 
-- SELECT handle_user_login(2, 'Windows PC', 'desktop', 'Edge', 'Windows', '192.168.1.102'::inet, 'Delhi', 'India');
-- SELECT handle_user_login(2, 'iPhone 15', 'mobile', 'Safari', 'iOS', '192.168.1.101'::inet, 'Mumbai', 'India'); 
-- SELECT handle_user_login(2, 'Windows PC', 'desktop', 'Edge', 'Windows', '192.168.1.102'::inet, 'Delhi', 'India');
-- SELECT handle_user_login(3, 'iPhone 15', 'mobile', 'Safari', 'iOS', '192.168.1.101'::inet, 'Mumbai', 'India'); 
-- SELECT handle_user_login(3, 'Windows PC', 'desktop', 'Edge', 'Windows', '192.168.1.102'::inet, 'Delhi', 'India');

---------- insert into filters ----------
-- Amazon Macro Influencers #1
INSERT INTO filters (f_name, f_type, f_created_by, f_metadata, f_is_active, f_t_id)
VALUES (
  'Amazon Macro Influencers', 
  'private', 
  1, 
  '{
    "platform": "Youtube",
    "genre": "Entertainment",
    "niche": ["Gaming", "Sketch Comedy", "Standup Comedy"],
    "followers_min": 1000,
    "followers_max": 200000,
    "avg_views_min": 50000,
    "avg_views_max": 700000,
    "engagement_rate_min": 0,
    "engagement_rate_max": 20,
    "growth_rate_min": 0,
    "growth_rate_max": 10,
    "most_recent_post": "3 days ago"
  }'::jsonb, 
  true, 
  1
);

-- Policy Bazaar Legends
INSERT INTO filters (f_name, f_type, f_created_by, f_metadata, f_is_active, f_t_id)
VALUES (
  'Policy Bazaar Legends', 
  'private', 
  1, 
  '{
    "platform": "Instagram",
    "genre": "Finance",
    "niche": ["Insurance", "Investments"],
    "followers_min": 5000,
    "followers_max": 1000000,
    "avg_views_min": 10000,
    "avg_views_max": 400000,
    "engagement_rate_min": 5,
    "engagement_rate_max": 25,
    "growth_rate_min": 0,
    "growth_rate_max": 15,
    "most_recent_post": "5 days ago"
  }'::jsonb, 
  true, 
  1
);

-- MStock Nano Influencers
INSERT INTO filters (f_name, f_type, f_created_by, f_metadata, f_is_active, f_t_id)
VALUES (
  'MStock Nano Influencers', 
  'private', 
  1, 
  '{
    "platform": "Instagram",
    "genre": "Stock Trading",
    "niche": ["Equity", "Crypto"],
    "followers_min": 1000,
    "followers_max": 10000,
    "avg_views_min": 500,
    "avg_views_max": 20000,
    "engagement_rate_min": 2,
    "engagement_rate_max": 15,
    "growth_rate_min": 1,
    "growth_rate_max": 8,
    "most_recent_post": "1 day ago"
  }'::jsonb, 
  true, 
  1
);

-- Amazon Nano Influencers #2 (deduped version)
INSERT INTO filters (f_name, f_type, f_created_by, f_metadata, f_is_active, f_t_id)
VALUES (
  'Amazon Nano Influencers', 
  'private', 
  1, 
  '{
    "platform": "Youtube",
    "genre": "Tech Reviews",
    "niche": ["Mobile Phones", "Gadgets"],
    "followers_min": 50000,
    "followers_max": 500000,
    "avg_views_min": 100000,
    "avg_views_max": 1000000,
    "engagement_rate_min": 1,
    "engagement_rate_max": 12,
    "growth_rate_min": 3,
    "growth_rate_max": 10,
    "most_recent_post": "7 days ago"
  }'::jsonb, 
  true, 
  1
);


---------- insert into access ----------
INSERT INTO access (a_name, a_description, a_is_active, a_t_id)
VALUES 
('admin', 'Full access to all filters and shares', true, 1),
('editor', 'Can edit filters but limited sharing rights', true, 1),
('viewer', 'Read-only access to filters', true, 1);


---------- insert into filter_shares ----------
-- Amazon Macro Influencers
INSERT INTO filter_shares (fs_f_id, fs_shared_with, fs_access_level, fs_is_active, fs_t_id)
VALUES 
  (1, 1, 1, true, 1),  -- User 1 Admin access
  (1, 2, 2, true, 1);  -- User 2 Editor access

-- Policy Bazaar Legends
INSERT INTO filter_shares (fs_f_id, fs_shared_with, fs_access_level, fs_is_active, fs_t_id)
VALUES 
  (2, 1, 1, true, 1),
  (2, 2, 2, true, 1);

-- MStock Nano Influencers
INSERT INTO filter_shares (fs_f_id, fs_shared_with, fs_access_level, fs_is_active, fs_t_id)
VALUES 
  (3, 1, 1, true, 1),
  (3, 2, 2, true, 1);

-- Amazon Nano Influencers
INSERT INTO filter_shares (fs_f_id, fs_shared_with, fs_access_level, fs_is_active, fs_t_id)
VALUES 
  (4, 1, 1, true, 1),
  (4, 2, 2, true, 1);


---------- insert into brands ----------
-- Flipkart
INSERT INTO brands (
  b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
  b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
  b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
  b_o_id, b_t_id
)
VALUES (
  'Flipkart',
  'Flipkart Internet Private Limited',
  'active',
  'https://1000logos.net/wp-content/uploads/2021/02/Flipkart-logo.png',
  'https://www.flipkart.com',
  'https://www.linkedin.com/company/flipkart/',
  'enterprise',
  'E-Commerce',
  'Large Cap',
  'Customer-centricity, Innovation, Integrity',
  'Empowering every Indian’s shopping journey',
  'Modern, Trustworthy, Accessible',
  'Flipkart is one of India’s leading e-commerce platforms, offering a wide range of products including electronics, fashion, and home essentials. Founded in 2007 and headquartered in Bengaluru, it was acquired by Walmart in 2018.',
  'GSTIN: 29AAACF1234A1Z5',
  'Net 30',
  1,
  1
);

-- Amazon India
INSERT INTO brands (
  b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
  b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
  b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
  b_o_id, b_t_id
)
VALUES (
  'Amazon India',
  'Amazon India Limited',
  'active',
  'https://1000logos.net/wp-content/uploads/2016/10/Amazon-Logo.png',
  'https://www.amazon.in',
  'https://www.linkedin.com/company/amazon-india/',
  'enterprise',
  'E-Commerce',
  'Large Cap',
  'Customer Obsession, Operational Excellence, Long-term Thinking',
  'To be Earth’s most customer-centric company',
  'Innovative, Reliable, Customer-focused',
  'Amazon India is a subsidiary of Amazon.com, Inc., offering a vast selection of products across various categories. Launched in India in 2013, it has become a key player in the Indian e-commerce market.',
  'GSTIN: 07AABCA1234B1Z6',
  'Net 30',
  1,
  1
);

-- Meesho
INSERT INTO brands (
  b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
  b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
  b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
  b_o_id, b_t_id
)
VALUES (
  'Meesho',
  'Meesho Limited',
  'active',
  'https://upload.wikimedia.org/wikipedia/commons/5/5e/Meesho_Logo_Full.png',
  'https://www.meesho.com',
  'https://www.linkedin.com/company/meesho/',
  'medium',
  'E-Commerce',
  'Mid Cap',
  'Affordability, Inclusivity, Empowerment',
  'Democratizing internet commerce for everyone',
  'Accessible, Empowering, Community-driven',
  'Meesho is an Indian e-commerce platform that enables small businesses and individuals to start their online stores via social channels. Founded in 2015, it focuses on Tier II and III cities, offering a zero-commission model.',
  'GSTIN: 29AAACM1234C1Z7',
  'Net 15',
  1,
  1
);

-- Puma India
INSERT INTO brands (
  b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
  b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
  b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
  b_o_id, b_t_id
)
VALUES (
  'Puma India',
  'Puma Sports India Private Limited',
  'active',
  'https://1000logos.net/wp-content/uploads/2017/05/PUMA-Logo.png',
  'https://in.puma.com',
  'https://www.linkedin.com/company/puma/',
  'large',
  'Apparel & Footwear',
  'Mid Cap',
  'Performance, Innovation, Sustainability',
  'Forever Faster',
  'Sporty, Dynamic, Trendy',
  'Puma India is a subsidiary of the global sports brand Puma SE. Established in India in 2005, it offers a wide range of sports and lifestyle products, including footwear, apparel, and accessories.',
  'GSTIN: 29AAACP1234D1Z8',
  'Net 30',
  1,
  1
);

-- Dream11
INSERT INTO brands (
  b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
  b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
  b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
  b_o_id, b_t_id
)
VALUES (
  'Dream11',
  'Sporta Technologies Private Limited',
  'active',
  'https://upload.wikimedia.org/wikipedia/en/9/9a/Dream11_Logo.png',
  'https://www.dream11.com',
  'https://www.linkedin.com/company/dream11/',
  'large',
  'Fantasy Sports',
  'Mid Cap',
  'Passion, Strategy, Fair Play',
  'Making sports more exciting through fantasy gaming',
  'Engaging, Competitive, Innovative',
  'Dream11 is India’s leading fantasy sports platform, allowing users to create virtual teams and participate in contests across various sports. Founded in 2008, it has over 190 million users.',
  'GSTIN: 27AAACD1234E1Z9',
  'Net 15',
  1,
  1
);

-- Google
INSERT INTO brands (
  b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
  b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
  b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
  b_o_id
)
VALUES (
  'Google',
  'Google LLC',
  'active',
  'https://logo.clearbit.com/google.com',
  'https://www.google.com',
  'https://www.linkedin.com/company/google',
  'enterprise',
  'Technology',
  'Large Cap',
  'Organize the world’s information and make it universally accessible and useful.',
  'Innovative, user-centric solutions.',
  'Colorful, playful, and approachable.',
  'Google is a global technology leader specializing in Internet-related services and products.',
  'US-TAX-001',
  'Net 30',
  1
);

-- Myntra
INSERT INTO brands (
  b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
  b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
  b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
  b_o_id
)
VALUES (
  'Myntra',
  'Myntra Designs Private Limited',
  'active',
  'https://logo.clearbit.com/myntra.com',
  'https://www.myntra.com',
  'https://www.linkedin.com/company/myntra',
  'large',
  'E-commerce',
  'Mid Cap',
  'Fashion-forward and customer-centric.',
  'Your fashion destination.',
  'Trendy, youthful, and vibrant.',
  'Myntra is a leading Indian fashion e-commerce company offering a wide range of clothing and accessories.',
  'IN-TAX-002',
  'Net 30',
  1
);

-- Netflix
INSERT INTO brands (
  b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
  b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
  b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
  b_o_id
)
VALUES (
  'Netflix',
  'Netflix, Inc.',
  'active',
  'https://logo.clearbit.com/netflix.com',
  'https://www.netflix.com',
  'https://www.linkedin.com/company/netflix',
  'enterprise',
  'Entertainment',
  'Large Cap',
  'Entertainment on demand.',
  'See what’s next.',
  'Bold, cinematic, and engaging.',
  'Netflix is a global streaming service offering a wide variety of award-winning TV shows, movies, and documentaries.',
  'US-TAX-003',
  'Net 30',
  1
);

-- Sugar
INSERT INTO brands (
  b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
  b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
  b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
  b_o_id
)
VALUES (
  'Sugar',
  'Vellvette Lifestyle Private Limited',
  'active',
  'https://logo.clearbit.com/sugarcosmetics.com',
  'https://www.sugarcosmetics.com',
  'https://www.linkedin.com/company/sugar-cosmetics',
  'medium',
  'Cosmetics',
  'Small Cap',
  'Empowering women with bold beauty choices.',
  'Rule the world, one look at a time.',
  'Chic, edgy, and confident.',
  'Sugar Cosmetics is a cruelty-free makeup brand offering a wide range of products for bold and independent women.',
  'IN-TAX-004',
  'Net 30',
  1
);

-- Apple
INSERT INTO brands (
  b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
  b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
  b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
  b_o_id
)
VALUES (
  'Apple',
  'Apple Inc.',
  'active',
  'https://logo.clearbit.com/apple.com',
  'https://www.apple.com',
  'https://www.linkedin.com/company/apple',
  'enterprise',
  'Technology',
  'Large Cap',
  'Innovation and simplicity.',
  'Think different.',
  'Sleek, minimalist, and premium.',
  'Apple designs and manufactures consumer electronics, software, and online services, known for its innovative products.',
  'US-TAX-005',
  'Net 30',
  1
);

-- Samsung
INSERT INTO brands (
  b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
  b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
  b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
  b_o_id
)
VALUES (
  'Samsung',
  'Samsung Electronics Co., Ltd.',
  'active',
  'https://logo.clearbit.com/samsung.com',
  'https://www.samsung.com',
  'https://www.linkedin.com/company/samsung-electronics',
  'enterprise',
  'Electronics',
  'Large Cap',
  'Technology for life.',
  'Imagine the possibilities.',
  'Innovative, reliable, and diverse.',
  'Samsung is a global leader in technology, opening new possibilities for people everywhere.',
  'KR-TAX-006',
  'Net 30',
  1
);

-- Mamaearth
INSERT INTO brands (
  b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
  b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
  b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
  b_o_id
)
VALUES (
  'Mamaearth',
  'Honasa Consumer Limited',
  'active',
  'https://logo.clearbit.com/mamaearth.in',
  'https://www.mamaearth.in',
  'https://www.linkedin.com/company/mamaearth001',
  'medium',
  'Personal Care',
  'Mid Cap',
  'Natural and toxin-free products.',
  'Goodness inside.',
  'Eco-friendly, safe, and nurturing.',
  'Mamaearth offers natural and toxin-free personal care products, focusing on sustainability and safety.',
  'IN-TAX-007',
  'Net 30',
  1
);

-- Allen Solly
INSERT INTO brands (
  b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
  b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
  b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
  b_o_id
)
VALUES (
  'Allen Solly',
  'Aditya Birla Fashion and Retail Limited',
  'active',
  'https://logo.clearbit.com/allensolly.com',
  'https://www.allensolly.com',
  'https://www.linkedin.com/showcase/allensollyindia',
  'large',
  'Apparel',
  'Mid Cap',
  'Smart casuals for the modern professional.',
  'Friday dressing.',
  'Stylish, contemporary, and professional.',
  'Allen Solly is a premium apparel brand offering stylish and comfortable clothing for men and women.',
  'IN-TAX-008',
  'Net 30',
  1
);

-- Intel
INSERT INTO brands (
  b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
  b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,
  b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,
  b_o_id
)
VALUES (
  'Intel',
  'Intel Corporation',
  'active',
  'https://logo.clearbit.com/intel.com',
  'https://www.intel.com',
  'https://www.linkedin.com/company/intel-corporation',
  'enterprise',
  'Semiconductors',
  'Large Cap',
  'Driving innovation in computing.',
  'Experience what’s inside.',
  'Innovative, powerful, and essential.',
  'Intel is a leading technology company, known for its semiconductor chips and computing innovations.',
  'US-TAX-009',
  'Net 30',
  1
);

-- Realme
INSERT INTO brands (
  b_name, b_legal_name, b_status, b_logo_url, b_website, b_linkedin_url,
  b_company_size, b_industry, b_market_cap_range, b_values, b_messaging,  --11
  b_brand_identity, b_detailed_summary, b_tax_info, b_payment_terms,  --15
  b_o_id
)
VALUES (
  'Realme',
  'Realme Chongqing Mobile Telecommunications Corp., Ltd.',
  'active',
  'https://logo.clearbit.com/realme.com',
  'https://www.realme.com',
  'https://www.linkedin.com/company/realme',
  'large',
  'Consumer Electronics',
  'Mid Cap',
  'Dare to leap.',
  'Dare to leap.',
  'Youthful, dynamic, and innovative.',
  'Realme is a technology brand that specializes in providing high',
  'IN-TAX-110',
  'NET 50',
  1
);


-------- insert into brand_products_services ----------
-- Flipkart
INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
VALUES
(1, 'Flipkart Plus Membership', 'Loyalty program offering free delivery and early access to sales.', 'Membership', '₹0–₹999', 1),
(1, 'Flipkart Health+', 'Online pharmacy service providing medicines and healthcare 0products.', 'Healthcare', '₹50–₹5,000', 1);

-- Amazon India
INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
VALUES
(2, 'Amazon Prime', 'Subscription offering fast delivery, Prime Video, and more.', 'Subscription', '₹179/month', 2),
(2, 'Amazon Pay', 'Digital wallet for seamless transactions on and off Amazon.', 'Fintech', 'Varies', 2);

-- Meesho
INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
VALUES
(3, 'Reseller Platform', 'Enables individuals to resell products via social media.', 'E-commerce', '₹100–₹5,000', 3),
(3, 'Meesho Supplier Hub', 'Platform for suppliers to list products for resellers.', 'Marketplace', 'Varies', 3);

-- Puma India
INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
VALUES
(4, 'Running Shoes', 'High-performance footwear for athletes.', 'Footwear', '₹2,000–₹10,000', 4),
(4, 'Athleisure Apparel', 'Stylish and comfortable sportswear.', 'Apparel', '₹1,000–₹8,000', 4);

-- Dream11
INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
VALUES
(5, 'Fantasy Cricket', 'Platform to create virtual cricket teams and win prizes.', 'Gaming', '₹0–₹1,000', 5),
(5, 'Fantasy Football', 'Engage in virtual football leagues.', 'Gaming', '₹0–₹1,000', 5);

-- Google
INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
VALUES
(6, 'Google Search', 'Search engine providing information on the web.', 'Technology', 'Free', 6),
(6, 'Google Ads', 'Online advertising platform for businesses.', 'Advertising', 'Varies', 6);

-- Myntra
INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
VALUES
(7, 'Fashion E-commerce', 'Online platform for clothing and accessories.', 'Retail', '₹500–₹10,000', 7),
(7, 'Myntra Insider', 'Loyalty program offering exclusive benefits.', 'Membership', 'Free–₹999', 7);

-- Netflix
INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
VALUES
(8, 'Streaming Service', 'Subscription-based platform for movies and TV shows.', 'Entertainment', '₹199–₹799/month', 8),
(8, 'Netflix Originals', 'Exclusive content produced by Netflix.', 'Entertainment', 'Included in subscription', 8);

-- Sugar
INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
VALUES
(9, 'Matte Lipsticks', 'Long-lasting lipsticks in various shades.', 'Cosmetics', '₹499–₹799', 9),
(9, 'Face Makeup', 'Range of foundations and concealers.', 'Cosmetics', '₹599–₹1,199', 9);

-- Apple
INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
VALUES
(10, 'iPhone 16 Pro', 'Latest smartphone with advanced features.', 'Electronics', '₹61,855', 10),
(10, 'MacBook Air M3', 'Lightweight laptop with M3 chip.', 'Computers', '₹92,000–₹1,20,000', 10);

-- Samsung
INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
VALUES
(11, 'Galaxy S25', 'Flagship smartphone with cutting-edge technology.', 'Electronics', '₹70,000–₹1,10,000', 11),
(11, 'QLED TVs', 'High-definition televisions with QLED display.', 'Home Appliances', '₹50,000–₹2,00,000', 11);

-- Mamaearth
INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
VALUES
(12, 'Natural Skincare', 'Products made with natural ingredients.', 'Personal Care', '₹299–₹999', 12),
(12, 'Baby Care Range', 'Safe products for babies and toddlers.', 'Personal Care', '₹199–₹799', 12);

-- Allen Solly
INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
VALUES
(13, 'Formal Wear', 'Business attire for men and women.', 'Apparel', '₹1,000–₹5,000', 13),
(13, 'Casual Clothing', 'Everyday wear with a stylish touch.', 'Apparel', '₹800–₹3,000', 13);

-- Intel
INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
VALUES
(14, 'Intel Core i9', 'High-performance processors for computing.', 'Technology', '₹30,000–₹60,000', 14),
(14, 'Intel Arc GPUs', 'Graphics processing units for gaming and design.', 'Technology', '₹20,000–₹50,000', 14);

-- Realme
INSERT INTO brand_products_services (bps_b_id, bps_name, bps_description, bps_category, bps_price_range, bps_t_id)
VALUES
(15, 'Realme GT Series', 'Smartphones with powerful performance.', 'Electronics', '₹25,000–₹40,000', 15),
(15, 'Realme Buds Air', 'Wireless earbuds with noise cancellation.', 'Accessories', '₹3,000–₹5,000', 15);

---------- insert into brand_competitors table ----------
-- Amazon India Competitors
INSERT INTO brand_competitors (bc_b_id, bc_competitor_name, bc_type, bc_market_share, bc_strengths, bc_weaknesses, bc_website, bc_t_id)
VALUES
(2, 'Flipkart', 'direct', '45%', 'Strong presence in Indian market.', 'Limited global reach.', 'https://www.flipkart.com', 1),
(2, 'Reliance Digital', 'indirect', '10%', 'Wide offline network.', 'Less online presence.', 'https://www.reliancedigital.in', 1);

-- Meesho Competitors
INSERT INTO brand_competitors (bc_b_id, bc_competitor_name, bc_type, bc_market_share, bc_strengths, bc_weaknesses, bc_website, bc_t_id)
VALUES
(3, 'GlowRoad', 'direct', '15%', 'Strong reseller network.', 'Limited product categories.', 'https://www.glowroad.com', 1),
(3, 'Shop101', 'indirect', '10%', 'User-friendly platform.', 'Smaller supplier base.', 'https://www.shop101.com', 1);

-- Puma India Competitors
INSERT INTO brand_competitors (bc_b_id, bc_competitor_name, bc_type, bc_market_share, bc_strengths, bc_weaknesses, bc_website, bc_t_id)
VALUES
(4, 'Nike India', 'direct', '30%', 'Innovative designs.', 'Premium pricing.', 'https://www.nike.com/in', 1),
(4, 'Adidas India', 'direct', '25%', 'Strong brand loyalty.', 'Limited customization.', 'https://www.adidas.co.in', 1);

-- Dream11 Competitors
INSERT INTO brand_competitors (bc_b_id, bc_competitor_name, bc_type, bc_market_share, bc_strengths, bc_weaknesses, bc_website, bc_t_id)
VALUES
(5, 'My11Circle', 'direct', '20%', 'Celebrity endorsements.', 'Smaller user base.', 'https://www.my11circle.com', 1),
(5, 'FanFight', 'indirect', '10%', 'Easy-to-use interface.', 'Fewer contests.', 'https://www.fanfight.com', 1);


---------- insert into campaign ----------
-- Insert into campaigns table (updated schema)

INSERT INTO campaigns (
  c_b_id, c_t_id, c_status, c_name, c_budget, c_budget_currency, c_p_id,
  c_start_date, c_end_date, c_products_services, c_business_objectives,
  c_target_age_from, c_target_age_to, c_target_gender, c_target_income,
  c_target_locations, c_target_education_levels, c_target_languages,
  c_target_interests, c_behavioral_patterns, c_psychographics,
  c_technographics, c_purchase_intent, c_additional_demographics,
  c_inf_followers_range, c_inf_engagement_rate, c_inf_genres, c_inf_niches,
  c_inf_locations, c_inf_age_from, c_inf_age_to, c_inf_languages,
  c_inf_primary_platform_id, c_inf_last_post_days, c_inf_payment_terms,
  c_worked_with_promoted_competitors, c_previously_worked_with_brand,
  c_poc_brand_name, c_poc_brand_designation, c_poc_brand_email, c_poc_brand_phone
)
VALUES (
  1, -- c_b_id (Flipkart)
  1, -- c_t_id (Fame Keeda)
  'active',
  'Flipkart Fashion Fiesta',
  1000000.00,
  'INR',
  NULL, -- c_p_id (Assuming no specific product IDs)
  '2025-08-01',
  '2025-08-31',
  'Apparel, Footwear, Accessories',
  'Increase fashion segment sales and brand visibility among young adults.',
  18,
  35,
  'all',
  '4-6LPA',
  '["Delhi", "Mumbai", "Bangalore", "Hyderabad"]',
  '["Bachelor''s Degree", "Master''s Degree"]',
  '["English", "Hindi"]',
  '["Fashion", "Lifestyle", "Shopping"]',
  'Frequent online shoppers with interest in latest fashion trends.',
  'Value-conscious, trend-aware, and socially active individuals.',
  'Active on mobile platforms, responsive to digital marketing.',
  'High intent to purchase during festive sales.',
  'Urban dwellers with access to online shopping platforms.',
  'Micro',
  '4-6%',
  '["Fashion", "Lifestyle"]',
  '["Streetwear", "Ethnic Wear"]',
  '["Delhi", "Mumbai", "Bangalore", "Hyderabad"]',
  18,
  35,
  '["English", "Hindi"]',
  '["Instagram", "YouTube"]',
  '30 days',
  'NET 30',
  false,
  false,
  'Anjali Sharma',
  'Marketing Manager',
  'anjali.sharma@flipkart.com',
  '+91-9876543210'
);

INSERT INTO campaigns (
  c_b_id, c_t_id, c_status, c_name, c_budget, c_budget_currency, c_p_id,
  c_start_date, c_end_date, c_products_services, c_business_objectives,
  c_target_age_from, c_target_age_to, c_target_gender, c_target_income,
  c_target_locations, c_target_education_levels, c_target_languages,
  c_target_interests, c_behavioral_patterns, c_psychographics,
  c_technographics, c_purchase_intent, c_additional_demographics,
  c_inf_followers_range, c_inf_engagement_rate, c_inf_genres, c_inf_niches,
  c_inf_locations, c_inf_age_from, c_inf_age_to, c_inf_languages,
  c_inf_primary_platform_id, c_inf_last_post_days, c_inf_payment_terms,
  c_worked_with_promoted_competitors, c_previously_worked_with_brand,
  c_poc_brand_name, c_poc_brand_designation, c_poc_brand_email, c_poc_brand_phone
)
VALUES (
  1, -- c_b_id (Flipkart)
  1, -- c_t_id (Fame Keeda)
  'active',
  'Flipkart Big Billion Days 2025',
  5000000.00,
  'INR',
  NULL, -- c_p_id (Assuming no specific product IDs)
  '2025-10-01',
  '2025-10-10',
  'Electronics, Fashion, Home Appliances, Books, Furniture',
  'Boost sales across all categories during the festive season and increase market share.',
  18,
  45,
  'all',
  '6-10LPA',
  '["Delhi", "Mumbai", "Bangalore", "Chennai", "Kolkata"]',
  '["Bachelor''s Degree", "Master''s Degree"]',
  '["English", "Hindi"]',
  '["Online Shopping", "Festive Deals", "Electronics", "Fashion"]',
  'Price-sensitive shoppers looking for festive deals.',
  'Value-driven, tech-savvy, and deal-seeking individuals.',
  'Active on e-commerce platforms, responsive to digital marketing.',
  'High intent to purchase during festive sales.',
  'Urban and semi-urban dwellers with access to online shopping platforms.',
  'Macro',
  '6-10%',
  '["Technology", "Lifestyle", "Fashion"]',
  '["Smartphones", "Home Decor", "Apparel"]',
  '["Delhi", "Mumbai", "Bangalore", "Chennai", "Kolkata"]',
  18,
  45,
  '["English", "Hindi"]',
  '["Instagram", "YouTube", "Facebook"]',
  '30 days',
  'NET 30',
  false,
  true,
  'Ravi Kumar',
  'Senior Marketing Manager',
  'ravi.kumar@flipkart.com',
  '+91-9123456789'
);

-- Insert into campaigns table
INSERT INTO campaigns (
  c_b_id, c_t_id, c_status, c_name, c_budget, c_budget_currency, c_p_id,
  c_start_date, c_end_date, c_products_services, c_business_objectives,
  c_target_age_from, c_target_age_to, c_target_gender, c_target_income,
  c_target_locations, c_target_education_levels, c_target_languages,
  c_target_interests, c_behavioral_patterns, c_psychographics,
  c_technographics, c_purchase_intent, c_additional_demographics,
  c_inf_followers_range, c_inf_engagement_rate, c_inf_genres, c_inf_niches,
  c_inf_locations, c_inf_age_from, c_inf_age_to, c_inf_languages,
  c_inf_primary_platform_id, c_inf_last_post_days, c_inf_payment_terms,
  c_worked_with_promoted_competitors, c_previously_worked_with_brand,
  c_poc_brand_name, c_poc_brand_designation, c_poc_brand_email, c_poc_brand_phone
)
VALUES (
  2, -- c_b_id (Amazon India)
  1, -- c_t_id (Fame Keeda)
  'active',
  'Aur Dikhao 2.0',
  1500000.00,
  'INR',
  NULL, -- c_p_id (Assuming no specific product IDs)
  '2025-09-01',
  '2025-09-30',
  'Electronics, Home Appliances, Fashion, Books',
  'Enhance product visibility and customer engagement across diverse categories in Tier II and III cities.',
  18,
  45,
  'all',
  '6-10LPA',
  '["Lucknow", "Jaipur", "Indore", "Patna"]',
  '["Bachelor''s Degree", "Master''s Degree"]',
  '["English", "Hindi"]',
  '["Online Shopping", "Technology", "Fashion"]',
  'Regular online shoppers seeking variety and value.',
  'Value-driven, tech-savvy, and aspirational individuals.',
  'Active on mobile platforms, responsive to personalized recommendations.',
  'High intent to purchase during promotional campaigns.',
  'Residents of emerging urban centers with growing e-commerce adoption.',
  'Micro',
  '4-6%',
  '["Technology", "Lifestyle"]',
  '["Gadgets", "Home Decor"]',
  '["Lucknow", "Jaipur", "Indore", "Patna"]',
  18,
  45,
  '["English", "Hindi"]',
  '["Instagram", "YouTube"]',
  '30 days',
  'NET 30',
  false,
  false,
  'Rahul Verma',
  'Senior Marketing Manager',
  'rahul.verma@amazon.in',
  '+91-9876543211'
);

INSERT INTO campaigns (
  c_b_id, c_t_id, c_status, c_name, c_budget, c_budget_currency, c_p_id,
  c_start_date, c_end_date, c_products_services, c_business_objectives,
  c_target_age_from, c_target_age_to, c_target_gender, c_target_income,
  c_target_locations, c_target_education_levels, c_target_languages,
  c_target_interests, c_behavioral_patterns, c_psychographics,
  c_technographics, c_purchase_intent, c_additional_demographics,
  c_inf_followers_range, c_inf_engagement_rate, c_inf_genres, c_inf_niches,
  c_inf_locations, c_inf_age_from, c_inf_age_to, c_inf_languages,
  c_inf_primary_platform_id, c_inf_last_post_days, c_inf_payment_terms,
  c_worked_with_promoted_competitors, c_previously_worked_with_brand,
  c_poc_brand_name, c_poc_brand_designation, c_poc_brand_email, c_poc_brand_phone
)
VALUES (
  2, -- c_b_id (Amazon India)
  2, -- c_t_id (Assumed tenant ID for Amazon India)
  'active',
  'Mission GraHAQ 3.0',
  5000000.00,
  'INR',
  NULL,
  '2024-12-01',
  '2025-02-28',
  'Consumer Awareness Programs',
  'Enhance consumer awareness and safety, focusing on Tier II and III cities',
  25,
  45,
  'all',
  '2-4LPA',
  '["Lucknow", "Jaipur", "Indore", "Patna", "Nagpur"]',
  '["Bachelor''s Degree", "High School"]',
  '["Hindi", "English"]',
  '["Consumer Rights", "Online Shopping", "Digital Literacy"]',
  'Consumers seeking information on safe online shopping practices',
  'Value-conscious, digitally curious individuals',
  'Active on social media platforms, responsive to educational content',
  'High intent to engage with consumer awareness initiatives',
  'Residents of Tier II and III cities with growing internet penetration',
  'Micro',
  '2-4%',
  '["Education", "Awareness"]',
  '["Consumer Advocacy", "Digital Literacy"]',
  '["Lucknow", "Jaipur", "Indore", "Patna", "Nagpur"]',
  25,
  45,
  '["Hindi", "English"]',
  '["YouTube", "Facebook"]',
  '30 days',
  'NET 30',
  false,
  false,
  'Ravi Desai',
  'Director, Mass and Brand Marketing',
  'ravi.desai@amazon.in',
  '+91-9876543210'
);

INSERT INTO campaigns (
  c_b_id, c_t_id, c_status, c_name, c_budget, c_budget_currency, c_p_id,
  c_start_date, c_end_date, c_products_services, c_business_objectives,
  c_target_age_from, c_target_age_to, c_target_gender, c_target_income,
  c_target_locations, c_target_education_levels, c_target_languages,
  c_target_interests, c_behavioral_patterns, c_psychographics,
  c_technographics, c_purchase_intent, c_additional_demographics,
  c_inf_followers_range, c_inf_engagement_rate, c_inf_genres, c_inf_niches,
  c_inf_locations, c_inf_age_from, c_inf_age_to, c_inf_languages,
  c_inf_primary_platform_id, c_inf_last_post_days, c_inf_payment_terms,
  c_worked_with_promoted_competitors, c_previously_worked_with_brand,
  c_poc_brand_name, c_poc_brand_designation, c_poc_brand_email, c_poc_brand_phone
)
VALUES (
  4, -- c_b_id (PUMA India)
  1, -- c_t_id (Fame Keeda)
  'active',
  'PVMA – Smash the Limits',
  5000000.00,
  'INR',
  NULL,
  '2024-12-01',
  '2025-02-28',
  'Consumer Awareness Programs',
  'Enhance consumer awareness and comfort, focusing on shoe sole',
  25,
  45,
  'all',
  '2-4LPA',
  '["Lucknow", "Jaipur", "Indore", "Patna", "Nagpur"]',
  '["Bachelor''s Degree", "High School"]',
  '["Hindi", "English"]',
  '["Consumer Rights", "Online Shopping", "Digital Literacy"]',
  'Consumers seeking information on comfortable shoes',
  'Value-conscious, digitally curious individuals',
  'Active on social media platforms, responsive to educational content',
  'High intent to engage with consumer awareness initiatives',
  'Residents of Tier II and III cities with growing sales of comfortable shoes',
  'Micro',
  '2-4%',
  '["Education", "Awareness"]',
  '["Consumer Advocacy", "Digital Literacy"]',
  '["Lucknow", "Jaipur", "Indore", "Patna", "Nagpur"]',
  25,
  45,
  '["Hindi", "English"]',
  '["YouTube", "Facebook"]',
  '30 days',
  'NET 30',
  false,
  false,
  'Ravi Desai',
  'Director, Mass and Brand Marketing',
  'ravi.desai@amazon.in',
  '+91-9876543210'
);

---------- insert into campaign_objectives ----------
--Insert into campaign_objectives table
INSERT INTO campaign_objectives (
  co_c_id, co_objective, co_kpi, co_t_id
)
VALUES
  (
    1, 'Enhance brand visibility among target demographics.', 'Achieve a 20% increase in social media engagement during the campaign period.', 1 
  ),
  (
    1, 'Boost sales in the fashion segment.', 'Increase fashion category sales by 15% compared to the previous month.', 1
  ),
  (
    1, 'Expand customer base in Tier II and III cities.', 'Acquire 10,000 new customers from targeted regions.', 1
  );

--Insert into campaign_objectives table
INSERT INTO campaign_objectives (co_c_id, co_objective, co_kpi, co_t_id)
VALUES
  (2, 'Increase overall sales during the Big Billion Days event.', 'Achieve a 30% increase in sales compared to the previous month.', 1),
  (2, 'Enhance brand visibility and customer engagement.', 'Increase website traffic by 50% and social media engagement by 40%.', 1),
  (2, 'Expand customer base in Tier 2 and Tier 3 cities.', 'Achieve a 20% increase in new customer registrations from targeted regions.', 1);

-- Assuming the campaign ID for 'Aur Dikhao 2.0' is 2

INSERT INTO campaign_objectives (
  co_c_id, co_objective, co_kpi, co_t_id
)
VALUES
  (2, 'Increase product visibility across key categories in Tier II and III cities.', 'Achieve a 20% increase in product page views from targeted regions.', 1),
  (2, 'Enhance customer engagement through personalized recommendations.', 'Improve click-through rates on recommended products by 15%.', 1),
  (2, 'Boost sales during the campaign period.', 'Achieve a 25% increase in sales compared to the previous month.', 1);

--Insert into campaign_objectives table
INSERT INTO campaign_objectives (co_c_id, co_objective, co_kpi, co_t_id)
VALUES
  (3, 'Educate consumers about their rights and responsibilities in e-commerce', 'Reach 50 million consumers across Tier II and III cities', 2),
  (3, 'Promote safe online shopping practices', 'Conduct 1000+ awareness sessions and workshops', 2),
  (3, 'Enhance trust in digital transactions', 'Achieve 80% positive feedback from participants', 2);

INSERT INTO campaign_objectives (co_c_id, co_objective, co_kpi, co_t_id)
VALUES
  (4, 'Establish Puma as a leading brand in Indian badminton.', 'Achieve 20% market share in badminton segment by Q4 2025.', 1),
  (4, 'Increase engagement with Gen Z athletes.', 'Reach 1 million impressions among target demographic.', 1),
  (4, 'Boost sales of badminton products.', 'Increase sales by 30% during campaign period.', 1);


---------- insert into campaign_poc ----------
INSERT INTO campaign_poc (cp_c_id, cp_u_id, cp_t_id)
VALUES 
  (1, 3, 1),  -- Shraddha Gadkari
  (1, 9, 1),  -- Shreesha Sharma
  (1, 14, 1); -- Pratik Mhatre

INSERT INTO campaign_poc (cp_c_id, cp_u_id, cp_t_id)
VALUES 
  (1, 3, 1),  -- Shraddha Gadkari
  (1, 9, 1),  -- Shreesha Sharma
  (1, 14, 1); -- Pratik Mhatre

-- Assign POCs to the new campaign
INSERT INTO campaign_poc (cp_c_id, cp_u_id, cp_t_id)
VALUES 
  (2, 3, 1),  -- Shraddha Gadkari
  (2, 9, 1),  -- Shreesha Sharma
  (2, 14, 1); -- Pratik Mhatre

--Assigning POCs to the campaign
INSERT INTO campaign_poc (
  cp_c_id, cp_u_id, cp_t_id
)
VALUES
  (2, 3, 1),  -- Shraddha Gadkari
  (2, 9, 1),  -- Shreesha Sharma
  (2, 14, 1); -- Pratik Mhatre

-- Insert into campaign_poc table
INSERT INTO campaign_poc (cp_c_id, cp_u_id, cp_t_id)
VALUES
  (3, 3, 2),  -- Shraddha Gadkari
  (3, 9, 2),  -- Shreesha Sharma
  (3, 14, 2); -- Pratik Mhatre

INSERT INTO campaign_poc (cp_c_id, cp_u_id, cp_t_id)
VALUES
  (4, 3, 1),  -- Shraddha Gadkari
  (4, 9, 1),  -- Shreesha Sharma
  (4, 14, 1); -- Pratik Mhatre


---------- insert into platforms ----------
INSERT INTO platforms (p_name, p_icon_url)
VALUES 
  ('YouTube', 'https://drive.google.com/file/d/1CnNgDQQtl1ObktSaocN-UToW_OEKi0Xz/view?usp=drive_link'),
  ('Instagram', 'https://drive.google.com/file/d/12H6mvyFxZBCq-TQxumdy4eRgC064FlpP/view?usp=drive_link'),
  ('X', 'https://drive.google.com/file/d/1BHgiZdSIGGjZbkb1KjRq8-9tueSRKxrI/view?usp=drive_link'),
  ('LinkedIn', 'https://drive.google.com/file/d/1bPkUSgkwaCwnCYgyNSZR5kxaN6vYAf9y/view?usp=drive_link'),
  ('Facebook', 'https://drive.google.com/file/d/1WbkPn2imBrXg0hsBZAe5SmjFtgnegYOv/view?usp=drive_link'),
  ('Telegram', 'https://drive.google.com/file/d/1uUUEbZ4jyWLleWZM1_Of8V1Azzd-gXui/view?usp=drive_link'),
  ('Tiktok', 'https://drive.google.com/file/d/1238TeGHtNM6jEoP85I0HQC2z63LpkY7J/view?usp=drive_link');


---------- Insert into deliverable_types ----------
INSERT INTO deliverable_types (dt_name, dt_description, dt_t_id)
VALUES 
  ('Reels', 'Short-form vertical video content (15-90 seconds) for Instagram Reels with trending audio and effects', 1),
  ('Collab Reels', 'Collaborative Reels featuring multiple creators or brand partnerships with shared content creation', 1),
  ('Static Posts', 'Single image posts on social media platforms with captions and hashtags for engagement', 1),
  ('Video Post', 'Standard video content posted on social media feeds with longer duration than Reels', 1),
  ('Carousel Post', 'Multi-image posts that users can swipe through, showcasing multiple products or story elements', 1),
  ('Carousel Video', 'Multiple video clips combined in a single post that users can swipe through sequentially', 1),
  ('Swipe Up Story', 'Instagram/Facebook Stories with swipe-up links directing users to external websites or landing pages', 1),
  ('Link Story', 'Stories containing clickable links or link stickers for direct user navigation to brand content', 1),
  ('Static Story', 'Single image Stories posted for 24-hour visibility with text overlays and interactive elements', 1),
  ('Video Story', 'Short video content for Stories format with temporary visibility and high engagement potential', 1),
  ('Repost Story', 'Sharing and reposting existing content in Stories format with added commentary or brand messaging', 1),
  ('Live', 'Real-time streaming content for direct audience interaction, Q&A sessions, and product demonstrations', 1),
  ('Conceptual Video', 'Creative video content focused on brand storytelling, concepts, and artistic interpretation', 1),
  ('Integrated Video', 'Video content where brand messaging is naturally woven into the creator''s regular content style', 1),
  ('Dedicated Video', 'Full-length video content entirely focused on brand promotion, product reviews, or demonstrations', 1),
  ('YouTube Shorts', 'Vertical short-form videos (under 60 seconds) specifically created for YouTube Shorts platform', 1),
  ('Community Post', 'Text, image, or poll posts shared in YouTube Community tab for subscriber engagement', 1),
  ('Pre-roll/Post-roll Ads', 'Video advertisements that play before or after main video content on platforms like YouTube', 1),
  ('Product Placement', 'Subtle integration of brand products within regular content without explicit promotional messaging', 1),
  ('Polls', 'Interactive polling content on various platforms to engage audience and gather feedback or opinions', 1),
  ('Reshare', 'Sharing existing brand or user-generated content with additional commentary or endorsement', 1),
  ('Retweet', 'Twitter-specific content sharing mechanism to amplify brand messages to follower networks', 1);


---------- insert into platform_deliverables ----------
INSERT INTO platform_deliverables (pd_p_id, pd_dt_id, pd_t_id)
VALUES
  (1, 13, 1), -- Conceptual Video
  (1, 14, 1), -- Integrated Video
  (1, 15, 1), -- Dedicated Video
  (1, 16, 1), -- YouTube Shorts
  (1, 17, 1), -- Community Post
  (1, 18, 1), -- Pre-roll/Post-roll Ads
  (1, 19, 1), -- Product Placement
  (1, 12, 1); -- Live

INSERT INTO platform_deliverables (pd_p_id, pd_dt_id, pd_t_id)
VALUES
  (2, 1, 1),  -- Reels
  (2, 2, 1),  -- Collab Reels
  (2, 3, 1),  -- Static Posts
  (2, 4, 1),  -- Video Post
  (2, 5, 1),  -- Carousel Post
  (2, 6, 1),  -- Carousel Video
  (2, 7, 1),  -- Swipe Up Story
  (2, 8, 1),  -- Link Story
  (2, 9, 1),  -- Static Story
  (2, 10, 1), -- Video Story
  (2, 11, 1), -- Repost Story
  (2, 12, 1); -- Live

INSERT INTO platform_deliverables (pd_p_id, pd_dt_id, pd_t_id)
VALUES
  (3, 3, 1),  -- Static Posts
  (3, 4, 1),  -- Video Post
  (3, 22, 1); -- Retweet

INSERT INTO platform_deliverables (pd_p_id, pd_dt_id, pd_t_id)
VALUES
  (4, 3, 1),  -- Static Posts
  (4, 4, 1),  -- Video Post
  (4, 21, 1), -- Reshare
  (4, 12, 1), -- Live
  (4, 20, 1); -- Polls

INSERT INTO platform_deliverables (pd_p_id, pd_dt_id, pd_t_id)
VALUES
  (5, 3, 1),  -- Static Posts
  (5, 4, 1),  -- Video Post
  (5, 5, 1),  -- Carousel Post
  (5, 6, 1),  -- Carousel Video
  (5, 7, 1),  -- Swipe Up Story
  (5, 8, 1),  -- Link Story
  (5, 9, 1),  -- Static Story
  (5, 10, 1), -- Video Story
  (5, 11, 1), -- Repost Story
  (5, 12, 1); -- Live

INSERT INTO platform_deliverables (pd_p_id, pd_dt_id, pd_t_id)
VALUES
  (6, 3, 1),  -- Static Posts
  (6, 4, 1),  -- Video Post
  (6, 11, 1), -- Repost Story
  (6, 20, 1); -- Polls


---------- insert into campaign_lists ----------
INSERT INTO campaign_lists (cl_name, cl_c_id, cl_t_id)
VALUES 
  ('Flipkart Fashion Fiesta - Nano Boosters', 1, 1),
  ('Flipkart Fashion Fiesta - Brand Legends', 1, 1),
  ('Flipkart Fashion Fiesta - Sales Warriors', 1, 1),
  ('Flipkart Fashion Fiesta - ROAS Max Pack', 1, 1),
  ('Flipkart Fashion Fiesta - Celeb Amplifiers', 1, 1),
  ('Flipkart Fashion Fiesta - High Turn Up Reserve', 1, 1);

INSERT INTO campaign_lists (cl_name, cl_c_id, cl_t_id)
VALUES 
  ('Aur Dikhao 2.0 - Viral Amplifiers', 3, 1),
  ('Aur Dikhao 2.0 - Regional Dominators', 3, 1),
  ('Aur Dikhao 2.0 - Conversion Kings', 3, 1),
  ('Aur Dikhao 2.0 - Brand Storytellers', 3, 1);

INSERT INTO campaign_lists (cl_name, cl_c_id, cl_t_id)
VALUES 
  ('Flipkart Big Billion Days 2025 - Mega Converters', 2, 1),
  ('Flipkart Big Billion Days 2025 - Tier II Warriors', 2, 1),
  ('Flipkart Big Billion Days 2025 - ROAS Max Squad', 2, 1);

INSERT INTO campaign_lists (cl_name, cl_c_id, cl_t_id)
VALUES 
  ('Mission GraHAQ 3.0 - Consumer Advocates', 4, 1),
  ('Mission GraHAQ 3.0 - Awareness Amplifiers', 4, 1),
  ('Mission GraHAQ 3.0 - Trust Builders', 4, 1),
  ('Mission GraHAQ 3.0 - Safety Champions', 4, 1);

INSERT INTO campaign_lists (cl_name, cl_c_id, cl_t_id)
VALUES 
  ('PVMA – Smash the Limits - Gen Z Athletes', 5, 1),
  ('PVMA – Smash the Limits - Power Performers', 5, 1),
  ('PVMA – Smash the Limits - Hyper Local Creators', 5, 1),
  ('PVMA – Smash the Limits - Endurance Stars', 5, 1),
  ('PVMA – Smash the Limits - National Icons', 5, 1);

-- =================================================================================================================
-- ********************************************* IMPORTANT INSTRUCTION *********************************************  
-- =================================================================================================================

-- RUN THOSE TWO AFTER THIS 
-- 1. influencers insert queries.sql
-- 2. influencer_socials insert queries.sql


-- ---------- insert into influencers ----------
-- INSERT INTO influencers (inf_name, inf_status, inf_verification_status, inf_primary_platform_id, inf_email)
-- VALUES 
--   ('Bhuvan Bam', 'active', 'verified', NULL, 'bhuvan@bbkivines.com'),
--   ('Kusha Kapila', 'active', 'verified', NULL, 'kusha@skapila.com'),
--   ('CarryMinati', 'active', 'verified', NULL, 'carryminati@youtube.com'),
--   ('Prajakta Koli', 'active', 'verified', NULL, 'prajakta@mostlysane.com'),
--   ('Sourav Joshi', 'active', 'verified', NULL, 'sourav@joshi.com'),
--   ('Amit Bhadana', 'active', 'verified', NULL, 'amit@bhadana.com'),
--   ('Dhruv Rathee', 'active', 'verified', NULL, 'dhruv@rathee.com'),
--   ('Riyaz Aly', 'active', 'verified', NULL, 'riyaz@aly.com'),
--   ('Avneet Kaur', 'active', 'verified', NULL, 'avneet@kaur.com'),
--   ('Masoom Minawala', 'active', 'verified', NULL, 'masoom@minawala.com'),
--   ('Rashmika Mandanna', 'active', 'verified', NULL, 'rashmika@mandanna.com'),
--   ('Virat Kohli', 'active', 'verified', NULL, 'virat@kohli.com'),
--   ('Mrunal Panchal', 'active', 'verified', NULL, 'mrunal@panchal.in'),
--   ('Diipa Khosla', 'active', 'verified', NULL, 'diipa@khosla.com'),
--   ('Elvish Yadav', 'active', 'verified', NULL, 'elvish@yadav.com'),
--   ('Fukra Insaan', 'active', 'verified', NULL, 'abhishek@malhan.com'),
--   ('Apoorva Mukhija', 'active', 'verified', NULL, 'apoorva@mukhija.com'),
--   ('Gaurav Taneja', 'active', 'verified', NULL, 'gaurav@flyingbeast.in'),
--   ('Jaya Kishori', 'active', 'verified', NULL, 'jaya@kishori.org'),
--   ('Sadhguru', 'active', 'verified', NULL, 'sadhguru@ishafoundation.org'),
--   ('Angel Rai', 'active', 'verified', NULL, 'angel@rai.com'),
--   ('Appurv Gupta', 'active', 'verified', NULL, 'appurv@gupta.com'),
--   ('Dynamo Gaming', 'active', 'verified', NULL, 'dynamo@gaming.com'),
--   ('Sejal Kumar', 'active', 'verified', NULL, 'sejal@kumar.com'),
--   ('Jumana Abdu Rahman', 'active', 'verified', NULL, 'jumana@rahman.com'),
--   ('Maleesha Kharwa', 'active', 'verified', NULL, 'maleesha@kharwa.com'),
--   ('Komal Pandey', 'active', 'verified', NULL, 'komal@pandey.com'),
--   ('Kritika Khurana', 'active', 'verified', NULL, 'kritika@khurana.com'),
--   ('Ranveer Allahbadia', 'active', 'verified', NULL, 'runveer@allahbadia.com'),
--   ('Sara Tendulkar', 'active', 'verified', NULL, 'sara@tendulkar.com'),
--   ('Dulquer Salmaan', 'active', 'verified', NULL, 'dulquer@salmaan.com'),
--   ('Awez Darbar', 'active', 'verified', NULL, 'awez@darbar.com'),
--   ('Kunal Maru', 'active', 'verified', NULL, 'kunal@maru.com'),
--   ('Rituka Saksham', 'active', 'verified', NULL, 'rituka@saksham.com'),
--   ('Diksha Arora', 'active', 'verified', NULL, 'diksha@arora.com'),
--   ('Dolly Jain', 'active', 'verified', NULL, 'dolly@jain.com'),
--   ('Neha Nagar', 'active', 'verified', NULL, 'neha@nagar.com'),
--   ('Richa Gangani', 'active', 'verified', NULL, 'richa@gangani.com'),
--   ('Ishita Saluja', 'active', 'verified', NULL, 'ishita@saluja.com'),
--   ('Rachna Ranade', 'active', 'verified', NULL, 'rachna@ranade.com'),
--   ('Himani Chowdhary', 'active', 'verified', NULL, 'himani@chowdhary.com'),
--   ('Sanjana Nuwan Bandara', 'active', 'verified', NULL, 'sanjana@bandara.com'),
--   ('Mrunal Thakur', 'active', 'verified', NULL, 'mrunal@thakur.com'),
--   ('Gaurav Chaudhary', 'active', 'verified', NULL, 'technicalguruji@tg.com'),
--   ('RJ Karishma', 'active', 'verified', NULL, 'karishma@radiofun.com'),
--   ('Alia Bhatt', 'active', 'verified', NULL, 'alia@bhatt.com'),
--   ('Patricia Dumont', 'active', 'verified', NULL, 'patricia@dumont.com'),
--   ('Shubman Gill', 'active', 'verified', NULL, 'shubman@gill.com'),
--   ('Shraddha Kapoor', 'active', 'verified', NULL, 'shraddha@kapoor.com'),
--   ('Disha Patani', 'active', 'verified', NULL, 'disha@patani.com');


---------- insert into influencer_mgmt ----------
INSERT INTO influencer_mgmt (imd_inf_id, imd_name, imd_email, imd_phone1)
VALUES 
  (1, 'Vidur Bam', 'vidur.bam@management.com', '+918123450001'),
  (2, 'Kapila Manager', 'manager@skapilamgmt.com', '+918123450002'),
  (3, 'Ajey Nagar', 'ajey.nagar@management.com', '+918123450003'),
  (4, 'Prajakta PI', 'pi@mostlysane.com', '+918123450005'),
  (5, 'Piyush Joshi', 'piyush@joshi.com', '+918123450006'),
  (6, 'Bhadana Team', 'team@bhadana.com', '+918123450007'),
  (7, 'Rathee PR', 'pr@rathee.com', '+918123450008'),
  (8, 'Aly Management', 'mgmt@riyazaly.com', '+918123450009'),
  (9, 'Kaur Management', 'mgmt@avneet.com', '+918123450010'),
  (10, 'Masoom PR', 'pr@minawala.com', '+918123450011'),
  (11, 'Rashmika Agency', 'agency@rashmika.com', '+918123450021'),
  (12, 'VK Sports Mgmt', 'contact@viratkohli.com', '+918123450022'),
  (13, 'Mrunal PR', 'pr@mrunalpanchal.com', '+918123450023'),
  (14, 'Diipa PR', 'pr@diipakhosla.com', '+918123450024'),
  (15, 'Elvish Team', 'team@elvishyadav.com', '+918123450025'),
  (16, 'Fukra PR', 'pr@fukrainsaan.com', '+918123450026'),
  (17, 'Apoorva PR', 'pr@rebelkid.com', '+918123450027'),
  (18, 'Flying Beast Team', 'team@flyingbeast.in', '+918123450028'),
  (19, 'Jaya Kishori Trust', 'trust@jayakishori.org', '+918123450029'),
  (20, 'Isha Foundation', 'contact@sadhguru.org', '+918123450030'),
  (21, 'Angel management', 'mgmt@angelrai.com', '+918123450041'),
  (22, 'Appurv PR', 'pr@appurvgupta.com', '+918123450042'),
  (23, 'Dynamo Team', 'team@dynamogaming.com', '+918123450043'),
  (24, 'Sejal PR', 'pr@sejalkumar.com', '+918123450044'),
  (25, 'Jumana PR', 'pr@jumanarahman.com', '+918123450045'),
  (26, 'Maleesha PR', 'pr@maleesha.com', '+918123450046'),
  (27, 'Komal PR', 'pr@komalpandey.com', '+918123450047'),
  (28, 'Kritika PR', 'pr@kritikakhurana.com', '+918123450048'),
  (29, 'Ranveer PR', 'pr@runveerallahbadia.com', '+918123450049'),
  (30, 'Sara management', 'mgmt@saratendulkar.com', '+918123450050'),
  (31, 'Dulquer PR', 'pr@dulquer.com', '+918123450101'),
  (32, 'Awez Team', 'team@awezdarbar.com', '+918123450102'),
  (33, 'Kunal PR', 'pr@kunalmaru.com', '+918123450103'),
  (34, 'Rituka Team', 'team@ritukasaksham.com', '+918123450104'),
  (35, 'Diksha PR', 'pr@dikshaarora.com', '+918123450105'),
  (36, 'Dolly Jain PR', 'pr@dollyjain.com', '+918123450106'),
  (37, 'Neha Nagar PR', 'pr@nehanagar.com', '+918123450107'),
  (38, 'Richa PR', 'pr@richagangani.com', '+918123450108'),
  (39, 'Ishita PR', 'pr@ishitasaluja.com', '+918123450109'),
  (40, 'Rachna PR', 'pr@rachnaranade.com', '+918123450110'),
  (41, 'Himani PR', 'pr@himanichowdhary.com', '+918123450111'),
  (42, 'Sanjana Bandara PR', 'pr@sanjanabandara.com', '+918123450112'),
  (43, 'Mrunal Thakur PR', 'pr@mrunalthakur.com', '+918123450113'),
  (44, 'Tech Guruji PR', 'pr@technicalguruji.com', '+918123450114'),
  (45, 'RJ Karishma Team', 'team@karishmafun.com', '+918123450115'),
  (46, 'Alia Bhatt PR', 'pr@aliabhatt.com', '+918123450116'),
  (47, 'Patricia Dumont Team', 'team@patriciadumont.com', '+918123450117'),
  (48, 'Shubman Gill PR', 'pr@shubmangill.com', '+918123450118'),
  (49, 'Shraddha PR', 'pr@shraddhakapoor.com', '+918123450119'),
  (50, 'Disha PR', 'pr@dishapatani.com', '+918123450120');


---------- insert into influencer_prices ----------
INSERT INTO influencer_prices (ip_inf_id, ip_pd_id, ip_currency, ip_price, ip_notes)
VALUES
(1, 1,  'USD', 5000,  'Flat fee per video'),
(2, 2,  'USD', 3000,  'Per social media campaign'),
(3, 1,  'USD', 15000,  'High-reach roast video'),
(4, 2,  'USD', 4000,  'YouTube video + Instagram reel'),
(5, 1,  'USD', 8000,  'Family vlog package'),
(6, 2,  'USD', 7000,  'Comedy sketch video'),
(7, 3,  'USD', 12000,  'Explainer video campaign'),
(8, 4,  'USD', 9000,  'Instagram reel + story pack'),
(9, 2,  'USD', 10000,  'Brand integration + story'),
(10, 5,  'USD', 6000,  'Fashion campaign integration'),
(11, 6,  'USD', 12000,  'Instagram post + reel'),
(12, 3,  'USD', 30000,  'Brand campaign feature'),
(13, 1,  'USD', 8000,  'Beauty/talk video'),
(14, 4,  'USD', 10000,  'Fashion integration'),
(15, 9,  'USD', 7000,  'Comedy vlog'),
(16, 8,  'USD', 9000,  'Reaction video'),
(17, 7,  'USD', 5000,  'Lifestyle reel'),
(18, 1,  'USD', 15000,  'Fitness & travel vlog'),
(19, 3,  'USD', 6000,  'Spiritual talk reel'),
(20, 6,  'USD', 20000,  'Global campaign endorsement'),
(21, 5,  'USD', 4000,  'Music video integration'),
(22, 12,  'USD', 6000,  'Comedy show promo'),
(23, 14,  'USD', 10000,  'Gaming livestream sponsorship'),
(24, 19,  'USD', 5000,  'Travel fashion vlog'),
(25, 24,  'USD', 7000,  'Brand ambassador post'),
(26, 19,  'USD', 3000,  'Awareness campaign'),
(27, 3,  'USD', 8000,  'Fashion campaign'),
(28, 2,  'USD', 7500,  'Lifestyle branding'),
(29, 15,  'USD', 15000,  'Motivational podcast episode'),
(30, 17,  'USD', 4500,  'Emerging talent feature'),
(31, 16,  'USD', 15000,  'Film campaign + IG story'),
(32, 12,  'USD', 9000,  'Dance collab + trending reel'),
(33, 1,  'USD', 4000,  'Fashion lookbook promo'),
(34, 2,  'USD', 3500,  'Parenting collab content'),
(35, 1,  'USD', 5000,  'Career advice integration'),
(36, 2,  'USD', 7000,  'Traditional styling reel'),
(37, 3,  'USD', 4500,  'Financial literacy video'),
(38, 4,  'USD', 3200,  'Weight loss journey reel'),
(39, 2,  'USD', 3800,  'Confidence coaching bundle'),
(40, 5,  'USD', 4800,  'YouTube finance content'),
(41, 1,  'USD', 5000,  'Tax hacks series'),
(42, 2,  'USD', 6000,  'Music reel + story combo'),
(43, 1,  'USD', 11000,  'Fashion shoot + post set'),
(44, 2,  'USD', 13000,  'Tech unboxing + review'),
(45, 3,  'USD', 9500,  'Funny reel + collab shoutout'),
(46, 4,  'USD', 25000,  'Luxury brand ambassadorship'),
(47, 2,  'USD', 9000,  'Fashion/lifestyle content'),
(48, 5,  'USD', 14000,  'Cricket collab + story'),
(49, 9,  'USD', 17000,  'Bollywood promo bundle'),
(50, 1,  'USD', 15000,  'Fitness + beauty feature');

-- More Influencers have been added via n8n

-- ---------- insert into influencer_socials ----------
-- INSERT INTO influencer_socials (is_inf_id, is_platform_id, is_pk_id)
-- VALUES (
--   1,         -- Replace with actual inf_id from Step 1
--   1,         -- Replace with actual YouTube p_id from Step 2
--   6306       -- channel_id from your dataset (acts as platform PK)
-- );
-- INSERT INTO influencer_socials (is_inf_id, is_platform_id, is_pk_id)
-- VALUES (1, 2, 6718);

-- INSERT INTO influencer_socials (is_inf_id, is_platform_id, is_pk_id)
-- VALUES
-- (2, 1, 229816),    -- youtube
-- (2, 2, 6337);      -- instagram

-- INSERT INTO influencer_socials (is_inf_id, is_platform_id, is_pk_id)
-- VALUES
-- (3, 1, 5769),    -- youtube
-- (3, 1, 6858),    -- youtube
-- (3, 2, 6713);    -- instagram

-- INSERT INTO influencer_socials (is_inf_id, is_platform_id, is_pk_id)
-- VALUES
-- (4, 1, 7404),    -- youtube
-- (4, 2, 6800);    -- instagram

-- -- More Influencers have been added via n8n

---------- insert into influencer_proposals ----------
-- cl 1
INSERT INTO influencer_proposals (
  ip_cl_id, ip_is_id, ip_t_id)
  VALUES
  (1, 4, 1),
  (1, 12, 1),
  (1, 34, 1),
  (1, 24, 1),
  (1, 55, 1),
  (1, 67, 1),
  (1, 78, 1),
  (1, 89, 1),
  (1, 92, 1),
  (1, 52, 1),
  (1, 22, 1),
  (1, 80, 1),
  (1, 49, 1),
  (1, 19, 1),
  (1, 11, 1);

-- cl 2
INSERT INTO influencer_proposals (
  ip_cl_id, ip_is_id, ip_t_id)
  VALUES
  (2, 24, 1),
  (2, 78, 1),
  (2, 32, 1),
  (2, 64, 1),
  (2, 56, 1),
  (2, 89, 1),
  (2, 88, 1),
  (2, 59, 1),
  (2, 42, 1),
  (2, 52, 1),
  (2, 91, 1),
  (2, 87, 1),
  (2, 39, 1),
  (2, 61, 1),
  (2, 15, 1);

-- cl 3
INSERT INTO influencer_proposals (
  ip_cl_id, ip_is_id, ip_t_id)
  VALUES
  (3, 24, 1),
  (3, 78, 1),
  (3, 32, 1),
  (3, 64, 1),
  (3, 56, 1),
  (3, 89, 1),
  (3, 88, 1),
  (3, 59, 1),
  (3, 42, 1),
  (3, 52, 1),
  (3, 91, 1),
  (3, 87, 1),
  (3, 39, 1),
  (3, 61, 1),
  (3, 15, 1);

-- cl 4
INSERT INTO influencer_proposals (
  ip_cl_id, ip_is_id, ip_t_id)
  VALUES
  (4, 14, 1),
  (4, 28, 1),
  (4, 32, 1),
  (4, 44, 1),
  (4, 56, 1),
  (4, 67, 1),
  (4, 78, 1),
  (4, 89, 1),
  (4, 92, 1),
  (4, 102, 1),
  (4, 111, 1),
  (4, 127, 1),
  (4, 139, 1),
  (4, 141, 1),
  (4, 155, 1);

-- cl 5
INSERT INTO influencer_proposals (
  ip_cl_id, ip_is_id, ip_t_id)
  VALUES
  (5, 264, 1),
  (5, 758, 1),
  (5, 342, 1),
  (5, 634, 1),
  (5, 526, 1),
  (5, 817, 1),
  (5, 898, 1),
  (5, 589, 1),
  (5, 472, 1),
  (5, 562, 1),
  (5, 951, 1),
  (5, 847, 1),
  (5, 339, 1),
  (5, 621, 1),
  (5, 115, 1);

-- cl 6
INSERT INTO influencer_proposals (
  ip_cl_id, ip_is_id, ip_t_id)
  VALUES
  (6, 665, 1),
  (6, 653, 1),
  (6, 542, 1),
  (6, 534, 1),
  (6, 526, 1),
  (6, 517, 1),
  (6, 628, 1),
  (6, 289, 1),
  (6, 222, 1),
  (6, 262, 1),
  (6, 251, 1),
  (6, 247, 1),
  (6, 139, 1),
  (6, 121, 1),
  (6, 115, 1);

-- cl 7

INSERT INTO influencer_proposals (
  ip_cl_id, ip_is_id, ip_t_id)
  VALUES
  (7, 284, 1),
  (7, 258, 1),
  (7, 742, 1),
  (7, 234, 1),
  (7, 326, 1),
  (7, 217, 1),
  (7, 198, 1),
  (7, 589, 1),
  (7, 472, 1),
  (7, 562, 1),
  (7, 911, 1),
  (7, 817, 1),
  (7, 372, 1),
  (7, 612, 1),
  (7, 112, 1);

-- cl 8
INSERT INTO influencer_proposals (
  ip_cl_id, ip_is_id, ip_t_id)
  VALUES
  (8, 95, 1),
  (8, 66, 1),
  (8, 32, 1),
  (8, 24, 1),
  (8, 16, 1),
  (8, 97, 1),
  (8, 38, 1),
  (8, 69, 1),
  (8, 12, 1),
  (8, 10, 1),
  (8, 171, 1),
  (8, 327, 1),
  (8, 839, 1),
  (8, 181, 1),
  (8, 156, 1);

-- cl 9
INSERT INTO influencer_proposals (
  ip_cl_id, ip_is_id, ip_t_id)
  VALUES
  (9, 114, 1),
  (9, 278, 1),
  (9, 326, 1),
  (9, 144, 1),
  (9, 516, 1),
  (9, 676, 1),
  (9, 784, 1),
  (9, 819, 1),
  (9, 922, 1),
  (9, 112, 1),
  (9, 311, 1),
  (9, 827, 1),
  (9, 539, 1),
  (9, 671, 1),
  (9, 125, 1);

-- cl 10
INSERT INTO influencer_proposals (
  ip_cl_id, ip_is_id, ip_t_id)
  VALUES
  (10, 214, 1),
  (10, 248, 1),
  (10, 32, 1),
  (10, 444, 1),
  (10, 566, 1),
  (10, 677, 1),
  (10, 758, 1),
  (10, 89, 1),
  (10, 92, 1),
  (10, 2, 1),
  (10, 11, 1),
  (10, 97, 1),
  (10, 63, 1),
  (10, 54, 1),
  (10, 155, 1);


---------- insert into deliverable_proposals ----------
INSERT INTO deliverable_proposals (dp_influencer_proposal_id, dp_platform_deliverable_id, 
dp_agreed_price, dp_live_date, dp_notes, dp_t_id)
VALUES
(1, 1, 50000, '2025-08-14', 'A nice Conceptual Video for Marketing', 1),
(2, 2, 30000, '2025-08-15', 'A nice Integrated Video for Marketing', 1),
(3, 3, 150000, '2025-08-16', 'A nice Dedicated Video for Marketing', 1),
(4, 4, 40000, '2025-08-17', 'A nice Video Post for Marketing', 1),
(5, 5, 45000, '2025-08-18', 'Instagram Community Post campaign deliverable', 1),
(6, 6, 60000, '2025-08-19', 'Pre-roll Ad for YouTube Shorts push', 1),
(7, 7, 70000, '2025-08-20', 'Instagram Product Placement with storytelling', 1),
(8, 8, 35000, '2025-08-21', 'Influencer will go Live on YouTube for Q&A', 1),
(9, 9, 25000, '2025-08-22', 'Standard Instagram Reels shoot and post', 1),
(10, 10, 30000, '2025-08-23', 'Carousel Post highlighting multiple product angles', 1),
(11, 11, 28000, '2025-08-24', 'Swipe Up Story with brand mention and discount', 1),
(12, 12, 32000, '2025-08-25', 'Link Story directing to landing page', 1),
(13, 13, 42000, '2025-08-26', 'Instagram Static Story with CTA', 1),
(14, 14, 48000, '2025-08-27', 'Video Story explaining product usage', 1);

---------- insert into deliverable_proposals ----------
INSERT INTO deliverable_proposals (
  dp_influencer_proposal_id, dp_platform_deliverable_id, 
  dp_agreed_price, dp_live_date, dp_notes, dp_t_id)
VALUES
  (15, 41, 30000, '2025-08-28', 'Auto-generated deliverable for platform_deliverable_id 41', 1),
  (16, 2, 45000, '2025-08-29', 'Auto-generated deliverable for platform_deliverable_id 2', 1),
  (17, 16, 40000, '2025-08-30', 'Auto-generated deliverable for platform_deliverable_id 16', 1),
  (18, 9, 30000, '2025-08-31', 'Auto-generated deliverable for platform_deliverable_id 9', 1),
  (19, 12, 30000, '2025-09-01', 'Auto-generated deliverable for platform_deliverable_id 12', 1),
  (20, 3, 60000, '2025-09-02', 'Auto-generated deliverable for platform_deliverable_id 3', 1),
  (21, 3, 25000, '2025-09-03', 'Auto-generated deliverable for platform_deliverable_id 3', 1),
  (22, 6, 40000, '2025-09-04', 'Auto-generated deliverable for platform_deliverable_id 6', 1),
  (23, 15, 25000, '2025-09-05', 'Auto-generated deliverable for platform_deliverable_id 15', 1),
  (24, 36, 40000, '2025-09-06', 'Auto-generated deliverable for platform_deliverable_id 36', 1),
  (25, 42, 60000, '2025-09-07', 'Auto-generated deliverable for platform_deliverable_id 42', 1),
  (26, 15, 70000, '2025-09-08', 'Auto-generated deliverable for platform_deliverable_id 15', 1),
  (27, 38, 45000, '2025-09-09', 'Auto-generated deliverable for platform_deliverable_id 38', 1),
  (28, 1, 35000, '2025-09-10', 'Auto-generated deliverable for platform_deliverable_id 1', 1),
  (29, 28, 50000, '2025-09-11', 'Auto-generated deliverable for platform_deliverable_id 28', 1),
  (30, 18, 35000, '2025-09-12', 'Auto-generated deliverable for platform_deliverable_id 18', 1),
  (31, 14, 50000, '2025-09-13', 'Auto-generated deliverable for platform_deliverable_id 14', 1),
  (32, 7, 30000, '2025-09-14', 'Auto-generated deliverable for platform_deliverable_id 7', 1),
  (33, 25, 30000, '2025-09-15', 'Auto-generated deliverable for platform_deliverable_id 25', 1);






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

-- Free Forever
INSERT INTO plan_features (pf_plan_id, pf_feature_value)
SELECT plan_id, 'Community & Support'
FROM plans WHERE plan_name = 'free forever';

INSERT INTO plan_features (pf_plan_id, pf_feature_value)
SELECT plan_id, 'Knowledge Base Support'
FROM plans WHERE plan_name = 'free forever';

-- Starter
INSERT INTO plan_features (pf_plan_id, pf_feature_value)
SELECT plan_id, 'Email Support (24hr SLA)'
FROM plans WHERE plan_name = 'starter';

INSERT INTO plan_features (pf_plan_id, pf_feature_value)
SELECT plan_id, 'Chat Support (24hr SLA)'
FROM plans WHERE plan_name = 'starter';

-- Pro
INSERT INTO plan_features (pf_plan_id, pf_feature_value)
SELECT plan_id, 'Priority Chat Support'
FROM plans WHERE plan_name = 'pro';

INSERT INTO plan_features (pf_plan_id, pf_feature_value)
SELECT plan_id, 'Dedicated Onboarding Session'
FROM plans WHERE plan_name = 'pro';

-- Enterprise
INSERT INTO plan_features (pf_plan_id, pf_feature_value)
SELECT plan_id, '24/7 Dedicated Support'
FROM plans WHERE plan_name = 'enterprise';

INSERT INTO plan_features (pf_plan_id, pf_feature_value)
SELECT plan_id, 'SLA-driven CSM'
FROM plans WHERE plan_name = 'enterprise';

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
('Brand Strategy', 'Brand Strategy Team', 'active', 1);


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

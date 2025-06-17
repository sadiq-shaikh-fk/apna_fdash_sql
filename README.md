# Fame Dash — Database Seed & Schema Setup

Welcome to the Fame Dash SaaS Database Repository.

This README documents the **core schema, data inserts, and structure** for the Fame Dash influencer marketing SaaS platform.

---

## 🔥 Platform Overview

Fame Dash is an enterprise-grade influencer marketing SaaS system with:

- Multi-tenant architecture
- Campaign management
- Influencer lists & assignment
- Deliverables mapping across platforms
- Subscription & billing system
- Full RBAC & user management
- PostgreSQL production-grade schema

---

## 🚀 Key Schema Modules

| Module | Description |
|--------|-------------|
| **Organizations** | White-labeled agency and brand ownership layer |
| **Tenants** | SaaS tenant context per client or brand |
| **Users & Roles** | Auth system with teams, roles, workspaces |
| **Campaigns** | Full influencer campaign management engine |
| **Campaign Lists** | Influencer segmentation layer per campaign |
| **Deliverables** | Platform-deliverable mappings |
| **Filters & Access** | Saved filters and access control |
| **Subscriptions** | Plan management, invoices, and payments |
| **Brands** | Brand management & product definitions |

---

## ⚙️ Schema Layers

- PostgreSQL 14+
- Full Foreign Keys & Constraints
- ENUM Types for all controlled vocabulary
- Normalized many-to-many design for:
  - Deliverables
  - Campaign POCs
  - Campaign Lists
- Soft deletes enabled across tables
- Auto audit columns (`created_by`, `created_at`, etc.)
- Data triggers for auth → business users syncing

---

## 🗃️ Core Tables Snapshot

- `organizations`
- `tenants`
- `users_app` (business layer)
- `auth.users` (Nhost identity layer)
- `teams`, `roles`, `access`
- `campaigns`, `campaign_objectives`, `campaign_lists`, `campaign_poc`
- `brands`, `brand_products_services`, `brand_competitors`
- `platforms`, `deliverable_types`, `platform_deliverables`
- `filters`, `filter_shares`

---

## 📝 Sample Seeded Campaigns

| Campaign Name | Brand | Tenant |
|----------------|-------|--------|
| Flipkart Fashion Fiesta | Flipkart (b_id: 1) | Fame Keeda |
| Flipkart Big Billion Days 2025 | Flipkart (b_id: 1) | Fame Keeda |
| Aur Dikhao 2.0 | Amazon India (b_id: 2) | Fame Keeda |
| Mission GraHAQ 3.0 | Amazon India (b_id: 2) | Fame Keeda |
| PVMA – Smash The Limits | Puma India (b_id: 4) | Fame Keeda |

---

## ✅ SaaS Ready Features

- Multi-brand campaigns
- Multi-list influencer shortlisting system
- Platform-specific deliverables
- Full campaign POC assignments
- API-ready schema for frontend consumption
- SaaS-optimized naming conventions across lists

---

## 🔐 Next Steps

- Influencer assignment engine
- Deliverable assignment model
- Brand analytics layer
- Automated workflow pipelines

---

> 🚀 Fame Dash backend — production data modeling powered by PostgreSQL best practices.

---

**Maintained by:**  
Fame Keeda
R&D Team


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
  --u_oauth_token VARCHAR(500),    -- not null from front-end
  --u_oauth_provider VARCHAR(50),  -- Google, Facebook, etc.
  u_is_authorized BOOLEAN NOT NULL DEFAULT false,    -- boolean for invited members only to workspace
  u_user_type user_type_enum NOT NULL DEFAULT 'general',
  u_status user_status_enum NOT NULL DEFAULT 'pending_verification',
  u_t_id INTEGER,     -- foreign key to 't_id' from tenants table
  u_tm_id INTEGER,    -- foreign key to 'tm_id' from teams table
  u_r_id INTEGER,     -- foreign key to 'r_id' from roles table
  u_is_workspace_admin BOOLEAN NOT NULL DEFAULT false,
  u_last_login TIMESTAMP WITH TIME ZONE,
  u_locked_until TIMESTAMP WITH TIME ZONE,
  u_email_verified_at TIMESTAMP WITH TIME ZONE,
  u_phone_verified_at TIMESTAMP WITH TIME ZONE,
  u_avatar_url VARCHAR(500),
  u_timezone VARCHAR(50) DEFAULT 'UTC',
  u_is_gods_eye BOOLEAN NOT NULL DEFAULT false,  -- for super admin
  u_industry VARCHAR(100),  -- for agency or brand users
  u_about TEXT,             -- short biography or description
  u_designation VARCHAR(100),  -- job title or position
  u_mail_details JSONB,  -- additional details for email notifications
  -- security settings
  u_mfa_enabled BOOLEAN NOT NULL DEFAULT false;
  u_mfa_methods JSONB DEFAULT '[]'::jsonb; -- ['totp', 'sms', 'email']
  u_backup_codes_generated_at TIMESTAMP WITH TIME ZONE;
  u_login_attempts_count INTEGER DEFAULT 0;
  u_last_failed_login TIMESTAMP WITH TIME ZONE;
  u_security_alerts_enabled BOOLEAN NOT NULL DEFAULT true;
  u_password_changed_at TIMESTAMP WITH TIME ZONE;
  u_security_settings JSONB DEFAULT '{}'::jsonb;
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



-- ========== 2. table mfa_backup_codes ==========
CREATE TABLE mfa_backup_codes (
  mbc_id BIGSERIAL PRIMARY KEY,
  mbc_u_id BIGINT NOT NULL,
  mbc_code_hash VARCHAR(255) NOT NULL,     -- Hashed backup code
  mbc_used_at TIMESTAMP WITH TIME ZONE,    -- NULL if unused
  mbc_expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  mbc_is_active BOOLEAN NOT NULL DEFAULT true,
  
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
  CONSTRAINT fk_backup_codes_user FOREIGN KEY (umbc_u_id_auth) REFERENCES auth.users(id) ON DELETE CASCADE,
  -- constraints
  CONSTRAINT uk_backup_code_hash UNIQUE (umbc_code_hash)
);
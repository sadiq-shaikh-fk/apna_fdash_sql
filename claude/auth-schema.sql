-- Table: auth.migrations

-- DROP TABLE IF EXISTS auth.migrations;

CREATE TABLE IF NOT EXISTS auth.migrations
(
    id integer NOT NULL,
    name character varying(100) COLLATE pg_catalog."default" NOT NULL,
    hash character varying(40) COLLATE pg_catalog."default" NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT migrations_pkey PRIMARY KEY (id),
    CONSTRAINT migrations_name_key UNIQUE (name)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS auth.migrations
    OWNER to nhost_auth_admin;

GRANT ALL ON TABLE auth.migrations TO nhost_auth_admin;

GRANT ALL ON TABLE auth.migrations TO nhost_hasura;

COMMENT ON TABLE auth.migrations
    IS 'Internal table for tracking migrations. Don''t modify its structure as Hasura Auth relies on it to function properly.';


-- Table: auth.provider_requests

-- DROP TABLE IF EXISTS auth.provider_requests;

CREATE TABLE IF NOT EXISTS auth.provider_requests
(
    id uuid NOT NULL,
    options jsonb,
    CONSTRAINT provider_requests_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS auth.provider_requests
    OWNER to nhost_auth_admin;

GRANT ALL ON TABLE auth.provider_requests TO nhost_auth_admin;

GRANT ALL ON TABLE auth.provider_requests TO nhost_hasura;

COMMENT ON TABLE auth.provider_requests
    IS 'Oauth requests, inserted before redirecting to the provider''s site. Don''t modify its structure as Hasura Auth relies on it to function properly.';


-- Table: auth.providers

-- DROP TABLE IF EXISTS auth.providers;

CREATE TABLE IF NOT EXISTS auth.providers
(
    id text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT providers_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS auth.providers
    OWNER to nhost_auth_admin;

GRANT ALL ON TABLE auth.providers TO nhost_auth_admin;

GRANT ALL ON TABLE auth.providers TO nhost_hasura;

COMMENT ON TABLE auth.providers
    IS 'List of available Oauth providers. Don''t modify its structure as Hasura Auth relies on it to function properly.';


-- Table: auth.refresh_token_types

-- DROP TABLE IF EXISTS auth.refresh_token_types;

CREATE TABLE IF NOT EXISTS auth.refresh_token_types
(
    value text COLLATE pg_catalog."default" NOT NULL,
    comment text COLLATE pg_catalog."default",
    CONSTRAINT refresh_token_types_pkey PRIMARY KEY (value)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS auth.refresh_token_types
    OWNER to nhost_auth_admin;

GRANT ALL ON TABLE auth.refresh_token_types TO nhost_auth_admin;

GRANT ALL ON TABLE auth.refresh_token_types TO nhost_hasura;


-- Table: auth.refresh_tokens

-- DROP TABLE IF EXISTS auth.refresh_tokens;

CREATE TABLE IF NOT EXISTS auth.refresh_tokens
(
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    expires_at timestamp with time zone NOT NULL,
    user_id uuid NOT NULL,
    metadata jsonb,
    type text COLLATE pg_catalog."default" NOT NULL DEFAULT 'regular'::text,
    refresh_token_hash character varying(255) COLLATE pg_catalog."default",
    CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id),
    CONSTRAINT fk_user FOREIGN KEY (user_id)
        REFERENCES auth.users (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT refresh_tokens_types_fkey FOREIGN KEY (type)
        REFERENCES auth.refresh_token_types (value) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS auth.refresh_tokens
    OWNER to nhost_auth_admin;

GRANT ALL ON TABLE auth.refresh_tokens TO nhost_auth_admin;

GRANT ALL ON TABLE auth.refresh_tokens TO nhost_hasura;

COMMENT ON TABLE auth.refresh_tokens
    IS 'User refresh tokens. Hasura auth uses them to rotate new access tokens as long as the refresh token is not expired. Don''t modify its structure as Hasura Auth relies on it to function properly.';
-- Index: refresh_tokens_refresh_token_hash_expires_at_user_id_idx

-- DROP INDEX IF EXISTS auth.refresh_tokens_refresh_token_hash_expires_at_user_id_idx;

CREATE INDEX IF NOT EXISTS refresh_tokens_refresh_token_hash_expires_at_user_id_idx
    ON auth.refresh_tokens USING btree
    (refresh_token_hash COLLATE pg_catalog."default" ASC NULLS LAST, expires_at ASC NULLS LAST, user_id ASC NULLS LAST)
    TABLESPACE pg_default;



-- Table: auth.roles

-- DROP TABLE IF EXISTS auth.roles;

CREATE TABLE IF NOT EXISTS auth.roles
(
    role text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT roles_pkey PRIMARY KEY (role)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS auth.roles
    OWNER to nhost_auth_admin;

GRANT ALL ON TABLE auth.roles TO nhost_auth_admin;

GRANT ALL ON TABLE auth.roles TO nhost_hasura;

COMMENT ON TABLE auth.roles
    IS 'Persistent Hasura roles for users. Don''t modify its structure as Hasura Auth relies on it to function properly.';

-- Table: auth.user_providers

-- DROP TABLE IF EXISTS auth.user_providers;

CREATE TABLE IF NOT EXISTS auth.user_providers
(
    id uuid NOT NULL DEFAULT public.gen_random_uuid(),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    user_id uuid NOT NULL,
    access_token text COLLATE pg_catalog."default" NOT NULL,
    refresh_token text COLLATE pg_catalog."default",
    provider_id text COLLATE pg_catalog."default" NOT NULL,
    provider_user_id text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT user_providers_pkey PRIMARY KEY (id),
    CONSTRAINT user_providers_provider_id_provider_user_id_key UNIQUE (provider_id, provider_user_id),
    CONSTRAINT fk_provider FOREIGN KEY (provider_id)
        REFERENCES auth.providers (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_user FOREIGN KEY (user_id)
        REFERENCES auth.users (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS auth.user_providers
    OWNER to nhost_auth_admin;

GRANT ALL ON TABLE auth.user_providers TO nhost_auth_admin;

GRANT ALL ON TABLE auth.user_providers TO nhost_hasura;

COMMENT ON TABLE auth.user_providers
    IS 'Active providers for a given user. Don''t modify its structure as Hasura Auth relies on it to function properly.';

-- Trigger: set_auth_user_providers_updated_at

-- DROP TRIGGER IF EXISTS set_auth_user_providers_updated_at ON auth.user_providers;

CREATE OR REPLACE TRIGGER set_auth_user_providers_updated_at
    BEFORE UPDATE 
    ON auth.user_providers
    FOR EACH ROW
    EXECUTE FUNCTION auth.set_current_timestamp_updated_at();


-- Table: auth.user_roles

-- DROP TABLE IF EXISTS auth.user_roles;

CREATE TABLE IF NOT EXISTS auth.user_roles
(
    id uuid NOT NULL DEFAULT public.gen_random_uuid(),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    user_id uuid NOT NULL,
    role text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT user_roles_pkey PRIMARY KEY (id),
    CONSTRAINT user_roles_user_id_role_key UNIQUE (user_id, role),
    CONSTRAINT fk_role FOREIGN KEY (role)
        REFERENCES auth.roles (role) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_user FOREIGN KEY (user_id)
        REFERENCES auth.users (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS auth.user_roles
    OWNER to nhost_auth_admin;

GRANT ALL ON TABLE auth.user_roles TO nhost_auth_admin;

GRANT ALL ON TABLE auth.user_roles TO nhost_hasura;

COMMENT ON TABLE auth.user_roles
    IS 'Roles of users. Don''t modify its structure as Hasura Auth relies on it to function properly.';


-- Table: auth.user_security_keys

-- DROP TABLE IF EXISTS auth.user_security_keys;

CREATE TABLE IF NOT EXISTS auth.user_security_keys
(
    id uuid NOT NULL DEFAULT public.gen_random_uuid(),
    user_id uuid NOT NULL,
    credential_id text COLLATE pg_catalog."default" NOT NULL,
    credential_public_key bytea,
    counter bigint NOT NULL DEFAULT 0,
    transports character varying(255) COLLATE pg_catalog."default" NOT NULL DEFAULT ''::character varying,
    nickname text COLLATE pg_catalog."default",
    CONSTRAINT user_security_keys_pkey PRIMARY KEY (id),
    CONSTRAINT user_security_key_credential_id_key UNIQUE (credential_id),
    CONSTRAINT fk_user FOREIGN KEY (user_id)
        REFERENCES auth.users (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS auth.user_security_keys
    OWNER to nhost_auth_admin;

GRANT ALL ON TABLE auth.user_security_keys TO nhost_auth_admin;

GRANT ALL ON TABLE auth.user_security_keys TO nhost_hasura;

COMMENT ON TABLE auth.user_security_keys
    IS 'User webauthn security keys. Don''t modify its structure as Hasura Auth relies on it to function properly.';



-- Table: auth.users

-- DROP TABLE IF EXISTS auth.users;

CREATE TABLE IF NOT EXISTS auth.users
(
    id uuid NOT NULL DEFAULT public.gen_random_uuid(),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    last_seen timestamp with time zone,
    disabled boolean NOT NULL DEFAULT false,
    display_name text COLLATE pg_catalog."default" NOT NULL DEFAULT ''::text,
    avatar_url text COLLATE pg_catalog."default" NOT NULL DEFAULT ''::text,
    locale character varying(2) COLLATE pg_catalog."default" NOT NULL,
    email auth.email COLLATE pg_catalog."default",
    phone_number text COLLATE pg_catalog."default",
    password_hash text COLLATE pg_catalog."default",
    email_verified boolean NOT NULL DEFAULT false,
    phone_number_verified boolean NOT NULL DEFAULT false,
    new_email auth.email COLLATE pg_catalog."default",
    otp_method_last_used text COLLATE pg_catalog."default",
    otp_hash text COLLATE pg_catalog."default",
    otp_hash_expires_at timestamp with time zone NOT NULL DEFAULT now(),
    default_role text COLLATE pg_catalog."default" NOT NULL DEFAULT 'user'::text,
    is_anonymous boolean NOT NULL DEFAULT false,
    totp_secret text COLLATE pg_catalog."default",
    active_mfa_type text COLLATE pg_catalog."default",
    ticket text COLLATE pg_catalog."default",
    ticket_expires_at timestamp with time zone NOT NULL DEFAULT now(),
    metadata jsonb,
    webauthn_current_challenge text COLLATE pg_catalog."default",
    CONSTRAINT users_pkey PRIMARY KEY (id),
    CONSTRAINT users_email_key UNIQUE (email),
    CONSTRAINT users_phone_number_key UNIQUE (phone_number),
    CONSTRAINT fk_default_role FOREIGN KEY (default_role)
        REFERENCES auth.roles (role) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT active_mfa_types_check CHECK (active_mfa_type = 'totp'::text OR active_mfa_type = 'sms'::text)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS auth.users
    OWNER to nhost_auth_admin;

GRANT ALL ON TABLE auth.users TO nhost_auth_admin;

GRANT ALL ON TABLE auth.users TO nhost_hasura;

COMMENT ON TABLE auth.users
    IS 'User account information. Don''t modify its structure as Hasura Auth relies on it to function properly.';

-- Trigger: set_auth_users_updated_at

-- DROP TRIGGER IF EXISTS set_auth_users_updated_at ON auth.users;

CREATE OR REPLACE TRIGGER set_auth_users_updated_at
    BEFORE UPDATE 
    ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION auth.set_current_timestamp_updated_at();

-- Trigger: trg_insert_auth_user_to_public_user_app

-- DROP TRIGGER IF EXISTS trg_insert_auth_user_to_public_user_app ON auth.users;

CREATE OR REPLACE TRIGGER trg_insert_auth_user_to_public_user_app
    AFTER INSERT
    ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_auth_user_to_public_user();



-- TABLES
SELECT 
    'TABLE' as object_type,
    t.table_schema,
    t.table_name as object_name,
    c.column_name,
    c.data_type,
    c.is_nullable,
    c.column_default,
    NULL as full_definition
FROM information_schema.tables t
JOIN information_schema.columns c 
    ON t.table_name = c.table_name 
    AND t.table_schema = c.table_schema
WHERE t.table_type = 'BASE TABLE'
    AND t.table_schema NOT IN (
        'pg_catalog', 'information_schema', 'auth', 'storage',
        'realtime', 'extensions', 'graphql', 'graphql_public',
        'supabase_functions', 'supabase_migrations', 'vault',
        'pgsodium', 'pgsodium_masks', 'cron', 'net', 'pgbouncer'
    )

UNION ALL

-- FUNCTIONS RPC
SELECT 
    'FUNCTION' as object_type,
    n.nspname as table_schema,
    p.proname as object_name,
    NULL as column_name,
    NULL as data_type,
    NULL as is_nullable,
    NULL as column_default,
    pg_get_functiondef(p.oid) as full_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname NOT IN (
        'pg_catalog', 'information_schema', 'auth', 'storage',
        'realtime', 'extensions', 'graphql', 'graphql_public',
        'supabase_functions', 'supabase_migrations', 'vault',
        'pgsodium', 'pgsodium_masks', 'cron', 'net', 'pgbouncer'
    )
    AND p.prokind = 'f'
    AND p.proname NOT LIKE '\_%'
    AND p.proname NOT ILIKE '%geo%'
    AND p.proname NOT ILIKE '%pgis%'
    AND p.proname NOT ILIKE '%postg%'
    AND p.proname NOT ILIKE 'st\_%'
    AND p.proname NOT ILIKE '%json%'

UNION ALL

-- RLS POLICIES
SELECT 
    'POLICY' as object_type,
    schemaname as table_schema,
    tablename as object_name,
    policyname as column_name,
    cmd as data_type,  -- SELECT, INSERT, UPDATE, DELETE, ALL
    permissive as is_nullable,  -- PERMISSIVE ou RESTRICTIVE
    roles::text as column_default,  -- Rôles concernés
    CONCAT(
        'CREATE POLICY "', policyname, '" ON ', schemaname, '.', tablename,
        ' AS ', permissive,
        ' FOR ', cmd,
        ' TO ', roles::text,
        CASE WHEN qual IS NOT NULL THEN ' USING (' || qual || ')' ELSE '' END,
        CASE WHEN with_check IS NOT NULL THEN ' WITH CHECK (' || with_check || ')' ELSE '' END,
        ';'
    ) as full_definition
FROM pg_policies
WHERE schemaname NOT IN (
        'pg_catalog', 'information_schema', 'auth', 'storage',
        'realtime', 'extensions', 'graphql', 'graphql_public',
        'supabase_functions', 'supabase_migrations', 'vault',
        'pgsodium', 'pgsodium_masks', 'cron', 'net', 'pgbouncer'
    )

UNION ALL

-- FOREIGN KEYS
SELECT
    'FOREIGN_KEY' as object_type,
    tc.table_schema,
    tc.table_name as object_name,
    kcu.column_name,
    ccu.table_schema || '.' || ccu.table_name || '.' || ccu.column_name as data_type,
    tc.constraint_name as is_nullable,
    NULL as column_default,
    CONCAT(
        'ALTER TABLE ', tc.table_schema, '.', tc.table_name,
        ' ADD CONSTRAINT ', tc.constraint_name,
        ' FOREIGN KEY (', kcu.column_name, ')',
        ' REFERENCES ', ccu.table_schema, '.', ccu.table_name, '(', ccu.column_name, ');'
    ) as full_definition
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema NOT IN (
        'pg_catalog', 'information_schema', 'auth', 'storage',
        'realtime', 'extensions', 'graphql', 'graphql_public',
        'supabase_functions', 'supabase_migrations', 'vault',
        'pgsodium', 'pgsodium_masks', 'cron', 'net', 'pgbouncer'
    )

ORDER BY object_type, table_schema, object_name;
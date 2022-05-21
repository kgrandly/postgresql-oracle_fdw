--
-- 1. Install extensions
--

create extension pg_cron;

create extension postgres_fdw;

create extension oracle_fdw;

--
-- 2. Connect to foreign servers
--

select create_oracle_fs('source_fs', 'localhost', '1521', 'XE');

select create_postgres_fs('destination_fs', 'localhost', '5432', 'postgres');

-- select delete_foreign_server('destination_fs');

--
-- 3. Link a foreign user to a local
--

select create_user_mapping('destination_fs', 'importer', 'importer');

--
-- 4. Import a foreign schema
--

select import_foreign_schema('destination_fs', 'IMPORTER', 'destination', array ['TBL_CONTROL_PARAM']);

--
-- 5. Create a new request: launch time = now, periodicity = every 5 minutes
--

select create_request('classification_item 1/5', 'import_classification_item', now(), 5);

-- select create_request('classification_item   0', 'import_classification_item', now());

-- select create_request('classification_item -1m', 'import_classification_item', now() - interval '1 minute');

-- select create_request('classification_item 30s', 'import_classification_item', now() + interval '30 seconds');

-- select create_request('classification_item  5m', 'import_classification_item', now() + interval '5 minutes');

-- select delete_request('429c56c3-cd3d-4213-b1b1-d2ae32bf56b9');

--
-- 6. Get a list of requests
--

select show_requests();

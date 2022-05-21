CREATE USER provider;

COMMENT ON ROLE provider IS 'Пользователь приложения';


CREATE SCHEMA demo;

ALTER SCHEMA demo OWNER TO postgres;

COMMENT ON SCHEMA demo IS 'Примеры использования';


CREATE SCHEMA syncocean;

ALTER SCHEMA syncocean OWNER TO postgres;

COMMENT ON SCHEMA syncocean IS 'Схема приложения';


CREATE FUNCTION demo.reflector(p_args jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
begin
    return p_args;
end;
$$;

ALTER FUNCTION demo.reflector(p_args jsonb) OWNER TO postgres;


CREATE FUNCTION demo.import_classification_items(p_history_id uuid, p_args jsonb) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
    _cr record; -- Current row
begin
    --
    -- Delete erased rows
    --
    delete from destination.tbl_control_param
    where uuid not in (
        select cast(oid as text)
          from source.classification_item
    );

    --
    -- Update / insert modified rows
    --
    for _cr in
        select s.obozn as scaption,
               cast(s.oid as text) as uuid,
               case when s.no_show is true then 1 else 0 end as bnot_use
          from source.classification_item as s
        except
        select d.scaption,
               d.uuid,
               d.bnot_use
          from destination.tbl_control_param as d
    loop
        update destination.tbl_control_param
        set scaption = _cr.scaption,
            bnot_use = _cr.bnot_use
        where uuid = _cr.uuid;

        if not found then
            insert into destination.tbl_control_param
            values (null, _cr.scaption, _cr.uuid, _cr.bnot_use);
        end if;
    end loop;

    perform public.write_log(p_history_id, jsonb_build_object(
        'Result', 'success'
    ));

    return 0; -- No errors
end;
$$;

ALTER FUNCTION demo.import_classification_items(p_history_id uuid, p_args jsonb) OWNER TO postgres;


CREATE FUNCTION public.create_oracle_fs(p_name text, p_host text, p_port text, p_dbname text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    _cs text; -- Connection string
BEGIN
    _cs = format('//%s:%s/%s', p_host, p_port, p_dbname);

    execute format(
        'create server %I foreign data wrapper oracle_fdw options (dbserver %L)',
        p_name,
        _cs
    );

    execute format(
        'grant usage on foreign server %I to provider',
        p_name
    );

    return true;
end;
$$;

ALTER FUNCTION public.create_oracle_fs(p_name text, p_host text, p_port text, p_dbname text) OWNER TO postgres;


CREATE FUNCTION public.create_postgres_fs(p_name text, p_host text, p_port text, p_dbname text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
begin
    execute format(
        'create server %I foreign data wrapper postgres_fdw options (host %L, port %L, dbname %L)',
        p_name,
        p_host,
        p_port,
        p_dbname
    );

    execute format(
        'grant usage on foreign server %I to provider',
        p_name
    );

    return true;
end;
$$;

ALTER FUNCTION public.create_postgres_fs(p_name text, p_host text, p_port text, p_dbname text) OWNER TO postgres;


CREATE FUNCTION public.create_request(p_title text, p_func_name text, p_launch_time timestamp with time zone, p_periodicity integer DEFAULT 0, p_params jsonb DEFAULT '{}'::jsonb) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
begin
    perform syncocean.nu_request(jsonb_build_object(
        'Title', p_title,
        'FuncName', p_func_name,
        'LaunchTime', p_launch_time,
        'Periodicity', p_periodicity,
        'Params', p_params
    ));

    return true;
end;
$$;

ALTER FUNCTION public.create_request(p_title text, p_func_name text, p_launch_time timestamp with time zone, p_periodicity integer, p_params jsonb) OWNER TO postgres;


CREATE FUNCTION public.create_request(p_title text, p_func_name text, p_launch_time timestamp with time zone, p_params jsonb, p_periodicity integer DEFAULT 0) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
begin
    perform syncocean.nu_request(jsonb_build_object(
        'Title', p_title,
        'FuncName', p_func_name,
        'LaunchTime', p_launch_time,
        'Periodicity', p_periodicity,
        'Params', p_params
    ));

    return true;
end;
$$;

ALTER FUNCTION public.create_request(p_title text, p_func_name text, p_launch_time timestamp with time zone, p_params jsonb, p_periodicity integer) OWNER TO postgres;


CREATE FUNCTION public.create_user_mapping(p_fs_name text, p_user text, p_password text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
begin
    execute format(
        'create user mapping for postgres server %I options (user %L, password %L)',
        p_fs_name,
        p_user,
        p_password
    );

    execute format(
        'create user mapping for provider server %I options (user %L, password %L)',
        p_fs_name,
        p_user,
        p_password
    );

    return true;
end;
$$;

ALTER FUNCTION public.create_user_mapping(p_fs_name text, p_user text, p_password text) OWNER TO postgres;


CREATE FUNCTION public.delete_foreign_server(p_name text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
begin
    execute format(
        'drop server if exists %I cascade',
        p_name
    );

    return true;
end;
$$;

ALTER FUNCTION public.delete_foreign_server(p_name text) OWNER TO postgres;


CREATE FUNCTION public.delete_request(p_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
begin
    perform syncocean.del_request(jsonb_build_object(
        'Id', p_id
    ));

    return true;
end;
$$;

ALTER FUNCTION public.delete_request(p_id uuid) OWNER TO postgres;


CREATE FUNCTION public.delete_user_mapping(p_fs_name text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
begin
    execute format(
        'drop user mapping if exists for postgres server %I',
        p_fs_name
    );

    execute format(
        'drop user mapping if exists for provider server %I',
        p_fs_name
    );

    return true;
end;
$$;

ALTER FUNCTION public.delete_user_mapping(p_fs_name text) OWNER TO postgres;


CREATE FUNCTION public.edit_request(p_id uuid, p_property text, p_value anyelement) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
begin
    perform syncocean.nu_request(jsonb_build_object(
        'Id', p_id,
        p_property, p_value
    ));

    return true;
end;
$$;

ALTER FUNCTION public.edit_request(p_id uuid, p_property text, p_value anyelement) OWNER TO postgres;


CREATE FUNCTION public.import_foreign_schema(p_fs_name text, p_fs_schema text, p_local_schema text, p_tables text[] DEFAULT ARRAY[]::text[]) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
begin
    execute format(
        'create schema if not exists %I',
        p_local_schema
    );

    if array_length(p_tables, 1) > 0 then
        execute format(
            'import foreign schema %I limit to (%s) from server %I into %I',
            p_fs_schema,
            array_to_string(p_tables, ', '),
            p_fs_name,
            p_local_schema
        );
    else
        execute format(
            'import foreign schema %I from server %I into %I',
            p_fs_schema,
            p_fs_name,
            p_local_schema
        );
    end if;

    return true;
end;
$$;

ALTER FUNCTION public.import_foreign_schema(p_fs_name text, p_fs_schema text, p_local_schema text, p_tables text[]) OWNER TO postgres;


CREATE FUNCTION public.show_requests(p_filter jsonb DEFAULT '{}'::jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
declare
    _rs jsonb; -- Result
begin
    -- [Available filters]:
    --   * Id               - request id
    --   * Title            - request title (contains)
    --   * FuncName         - function name (contains)
    --   * BeforeLaunchTime - first execution time less or equal then
    --   ` AfterLaunchTime  - first execution time more or equal then
    --   * LessPeriodicity  - periodicity in seconds less or equal then
    --   ` MorePeriodicity  - periodicity in seconds more or equal then
    --   * BeforeStartTime  - start time less or equal then
    --   ` AfterStartTime   - start time more or equal then
    --   * BeforeEndTime    - end time less or equal then
    --   ` AfterEndTime     - end time more or equal then
    --   * LessStatus       - status number less or equal then
    --   ` MoreStatus       - status number more or equal then
    --
    -- [Note]:
    --   Use both filters at the same time to get equal value (see example).
    --
    -- [Example]:
    --   select show_requests(jsonb_build_object(
    --     'FuncName', 'import_classification_item',
    --     'LessStatus', 0
    --     'MoreStatus', 0
    --   ));

    select * into _rs
    from syncocean.get_request_list(p_filter);

    return _rs;
end;
$$;

ALTER FUNCTION public.show_requests(p_filter jsonb) OWNER TO postgres;


CREATE FUNCTION public.write_log(p_history_id uuid, p_payload jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
    perform syncocean.nu_log(jsonb_build_object(
        'HistoryId', p_history_id,
        'LogTime', now(),
        'Payload', p_payload
    ));
end;
$$;

ALTER FUNCTION public.write_log(p_history_id uuid, p_payload jsonb) OWNER TO postgres;


CREATE FUNCTION public.write_log(p_history_id uuid, p_log_time timestamp with time zone, p_payload jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
    perform syncocean.nu_log(jsonb_build_object(
        'HistoryId', p_history_id,
        'LogTime', p_log_time,
        'Payload', p_payload
    ));
end;
$$;

ALTER FUNCTION public.write_log(p_history_id uuid, p_log_time timestamp with time zone, p_payload jsonb) OWNER TO postgres;


CREATE FUNCTION syncocean.del_history(p_args jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
    _id uuid;
begin
    if p_args ? 'Id'
    and (p_args ->> 'Id') is not null then
        _id = p_args ->> 'Id';

        update syncocean.history
        set archived = true
        where id = _id;
    end if;
end;
$$;

ALTER FUNCTION syncocean.del_history(p_args jsonb) OWNER TO postgres;


CREATE FUNCTION syncocean.del_log(p_args jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
    _id uuid;
begin
    if p_args ? 'Id'
    and (p_args ->> 'Id') is not null then
        _id = p_args ->> 'Id';

        update syncocean.log
        set archived = true
        where id = _id;
    end if;
end;
$$;

ALTER FUNCTION syncocean.del_log(p_args jsonb) OWNER TO postgres;


CREATE FUNCTION syncocean.del_request(p_args jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
    _id uuid;
    _hr record; -- History record
begin
    if p_args ? 'Id'
    and (p_args ->> 'Id') is not null then
        _id = p_args ->> 'Id';

        update syncocean.request
        set archived = true
        where id = _id;

        for _hr in
            select *
            from syncocean.history
            where request_id = _id
        loop
            update syncocean.history
            set archived = true
            where id = _hr.id;

            update syncocean.log
            set archived = true
            where history_id = _hr.id;
        end loop;
    end if;
end;
$$;

ALTER FUNCTION syncocean.del_request(p_args jsonb) OWNER TO postgres;


CREATE FUNCTION syncocean.get_log_list(p_filter jsonb DEFAULT '{}'::jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
declare
    _result jsonb;
begin
    -- [Available filters]:
    --   * Id               - log's UUID
    --   * HistoryId        - history's UUID
    --   * BeforeLogTime    - log time less or equal then
    --   ` AfterLogTime     - log time more or equal then
    --
    -- [Note]:
    --   Use both filter at the same time to get equal value (see example).
    --
    -- [Example]:
    --   select get_log_list(jsonb_build_object(
    --     'BeforeLogTime', '2022-04-05T05:30:46.591525+00:00'
    --     'AfterLogTime', '2022-04-05T05:30:46.591525+00:00'
    --   ));

    if p_filter is null then
        p_filter = cast('{}' as jsonb);
    end if;

    select coalesce(jsonb_agg(
        jsonb_build_object(
            'Id', l.id,
            'Edit', l.edit,
            'Editor', l.editor,
            'HistoryId', l.history_id,
            'LogTime', l.log_time,
            'Payload', l.payload
        )
    ), '[]') into _result
    from syncocean.log as l
    where l.archived is false
      and (not p_filter ? 'Id'            or l.id         = cast(p_filter ->> 'Id'            as uuid       ))
      and (not p_filter ? 'HistoryId'     or l.history_id = cast(p_filter ->> 'HistoryId'     as uuid       ))
      and (not p_filter ? 'BeforeLogTime' or l.log_time  <= cast(p_filter ->> 'BeforeLogTime' as timestamptz))
      and (not p_filter ? 'AfterLogTime'  or l.log_time  >= cast(p_filter ->> 'AfterLogTime'  as timestamptz));

    return _result;
end;
$$;

ALTER FUNCTION syncocean.get_log_list(p_filter jsonb) OWNER TO postgres;


CREATE FUNCTION syncocean.get_request_list(p_filter jsonb DEFAULT '{}'::jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
declare
    _result jsonb;
begin
    -- [Available filters]:
    --   * Id               - request's UUID
    --   * Title            - request title (contains)
    --   * SchemaName       - schema name (contains)
    --   * FuncName         - function name (contains)
    --   * BeforeLaunchTime - first execution time less or equal then
    --   ` AfterLaunchTime  - first execution time more or equal then
    --   * LessPeriodicity  - periodicity in seconds less or equal then
    --   ` MorePeriodicity  - periodicity in seconds more or equal then
    --   * BeforeStartTime  - start time less or equal then
    --   ` AfterStartTime   - start time more or equal then
    --   * BeforeEndTime    - end time less or equal then
    --   ` AfterEndTime     - end time more or equal then
    --   * LessStatus       - status number less or equal then
    --   ` MoreStatus       - status number more or equal then
    --
    -- [Note]:
    --   Use both filter at the same time to get equal value (see example).
    --
    -- [Example]:
    --   select get_request_list(jsonb_build_object(
    --     'FuncName', 'import_classification_item',
    --     'LessStatus', 0
    --     'MoreStatus', 0
    --   ));

    if p_filter is null then
        p_filter = cast('{}' as jsonb);
    end if;

    with _history as (
        select h.request_id, jsonb_agg(
            jsonb_build_object(
                'Id', h.id,
                'Edit', h.edit,
                'Editor', h.editor,
                'StartTime', h.start_time,
                'EndTime', h.end_time,
                'Status', h.status,
                'DebugMsg', h.debug_msg
           )
        ) as history
        from syncocean.history as h
        where h.archived is false
          and (not p_filter ? 'BeforeStartTime' or h.start_time <= cast(p_filter ->> 'BeforeStartTime' as timestamptz))
          and (not p_filter ? 'AfterStartTime'  or h.start_time >= cast(p_filter ->> 'AfterStartTime'  as timestamptz))
          and (not p_filter ? 'BeforeEndTime'   or h.end_time   <= cast(p_filter ->> 'BeforeEndTime'   as timestamptz))
          and (not p_filter ? 'AfterEndTime'    or h.end_time   >= cast(p_filter ->> 'AfterEndTime'    as timestamptz))
          and (not p_filter ? 'LessStatus'      or h.status     <= cast(p_filter ->> 'LessStatus'      as integer    ))
          and (not p_filter ? 'MoreStatus'      or h.status     >= cast(p_filter ->> 'MoreStatus'      as integer    ))
        group by h.request_id
    )
    select coalesce(jsonb_agg(
        jsonb_build_object(
            'Id', r.id,
            'Edit', r.edit,
            'Editor', r.editor,
            'Title', r.title,
            'Description', r.description,
            'SchemaName', r.schema_name,
            'FuncName', r.func_name,
            'LaunchTime', r.launch_time,
            'Periodicity', r.periodicity,
            'Params', r.params,
            'History', coalesce(h.history, '[]')
        )
    ), '[]') into _result
    from syncocean.request as r
    left join _history as h on h.request_id = r.id
    where r.archived is false
      and (not p_filter ? 'Id'               or r.id          =       cast(p_filter ->> 'Id'               as uuid       ))
      and (not p_filter ? 'Title'            or r.title       like '%' || (p_filter ->> 'Title')      || '%'              )
      and (not p_filter ? 'SchemaName'       or r.schema_name like '%' || (p_filter ->> 'SchemaName') || '%'              )
      and (not p_filter ? 'FuncName'         or r.func_name   like '%' || (p_filter ->> 'FuncName')   || '%'              )
      and (not p_filter ? 'BeforeLaunchTime' or r.launch_time <=      cast(p_filter ->> 'BeforeLaunchTime' as timestamptz))
      and (not p_filter ? 'AfterLaunchTime'  or r.launch_time >=      cast(p_filter ->> 'AfterLaunchTime'  as timestamptz))
      and (not p_filter ? 'LessPeriodicity'  or r.periodicity <=      cast(p_filter ->> 'LessPeriodicity'  as integer    ))
      and (not p_filter ? 'MorePeriodicity'  or r.periodicity >=      cast(p_filter ->> 'MorePeriodicity'  as integer    ));

    return _result;
end;
$$;

ALTER FUNCTION syncocean.get_request_list(p_filter jsonb) OWNER TO postgres;


CREATE FUNCTION syncocean.nu_history(p_args jsonb) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
declare
    _id uuid;
begin
    if p_args ? 'Id'
    and (p_args ->> 'Id') is not null then
        -- Update existing
        _id = p_args ->> 'Id';

        update syncocean.history
        set request_id = case when p_args ? 'RequestId' and (p_args ->> 'RequestId') is not null then cast (p_args ->> 'RequestId' as uuid)        else request_id end,
            start_time = case when p_args ? 'StartTime'                                          then cast (p_args ->> 'StartTime' as timestamptz) else start_time end,
            end_time   = case when p_args ? 'EndTime'                                            then cast (p_args ->> 'EndTime'   as timestamptz) else end_time   end,
            status     = case when p_args ? 'Status'                                             then cast (p_args ->> 'Status'    as integer)     else status     end,
            debug_msg  = case when p_args ? 'DebugMsg'                                           then       p_args ->> 'DebugMsg'                  else debug_msg  end
        where id = _id;
    else
        -- Insert new
        if not p_args ? 'RequestId'
        or (p_args ->> 'RequestId') is null then
            raise exception 'field RequestId could not be empty';
        end if;

        insert into syncocean.history (
            request_id, start_time, end_time, status, job_id, debug_msg
        ) values (
                                                cast (p_args ->> 'RequestId' as uuid)           ,
            case when p_args ? 'StartTime' then cast (p_args ->> 'StartTime' as timestamptz) end,
            case when p_args ? 'EndTime'   then cast (p_args ->> 'EndTime'   as timestamptz) end,
            case when p_args ? 'Status'    then cast (p_args ->> 'Status'    as integer)     end,
            case when p_args ? 'DebugMsg'  then       p_args ->> 'DebugMsg'                  end
        ) returning id into _id;
    end if;

    return _id;
end;
$$;

ALTER FUNCTION syncocean.nu_history(p_args jsonb) OWNER TO postgres;


CREATE FUNCTION syncocean.nu_log(p_args jsonb) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
declare
    _id uuid;
begin
    if p_args ? 'Id'
    and (p_args ->> 'Id') is not null then
        -- Update existing
        _id = p_args ->> 'Id';

        update syncocean.log
        set history_id = case when p_args ? 'HistoryId' and (p_args ->> 'HistoryId') is not null then cast (p_args ->> 'HistoryId' as uuid)        else history_id end,
            log_time   = case when p_args ? 'LogTime'   and (p_args ->> 'LogTime'  ) is not null then cast (p_args ->> 'LogTime'   as timestamptz) else log_time   end,
            payload    = case when p_args ? 'Payload'   and (p_args ->  'Payload'  ) is not null then       p_args ->  'Payload'                   else payload    end
        where id = _id;
    else
        -- Insert new
        if not p_args ? 'HistoryId'
        or (p_args ->> 'HistoryId') is null then
            raise exception 'field HistoryId could not be empty';
        end if;

        if not p_args ? 'Payload'
        or (p_args ->> 'Payload') is null then
            raise exception 'field Payload could not be empty';
        end if;

        insert into syncocean.log (
            history_id, log_time, payload
        ) values (
                                                                                     cast (p_args ->> 'HistoryId' as uuid)                      ,
            case when p_args ? 'LogTime' and (p_args ->> 'LogTime') is not null then cast (p_args ->> 'LogTime'   as timestamptz) else now() end,
                                                                                           p_args ->  'Payload'
        ) returning id into _id;
    end if;

    return _id;
end;
$$;

ALTER FUNCTION syncocean.nu_log(p_args jsonb) OWNER TO postgres;


CREATE FUNCTION syncocean.nu_request(p_args jsonb) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
declare
    _id uuid;
    _lt timestamptz; -- Launch time
    _th timestamptz; -- Threshold
begin
    if p_args ? 'Id'
    and (p_args ->> 'Id') is not null then
        -- Update existing
        _id = p_args ->> 'Id';

        update syncocean.request
        set title       = case when p_args ? 'Title'  and (p_args ->> 'Title' ) is not null then p_args ->> 'Title'       else title       end,
            description = case when p_args ? 'Description'                                  then p_args ->> 'Description' else description end,
            params      = case when p_args ? 'Params' and (p_args ->  'Params') is not null then p_args ->  'Params'      else params      end
        where id = _id;

        if not found then
            raise exception 'request not found';
        end if;
    else
        -- Insert new
        if not p_args ? 'Title'
        or (p_args ->> 'Title') is null then
            raise exception 'field Title could not be empty';
        end if;

        if not p_args ? 'SchemaName'
        or (p_args ->> 'SchemaName') is null then
            raise exception 'field SchemaName could not be empty';
        end if;

        if not p_args ? 'FuncName'
        or (p_args ->> 'FuncName') is null then
            raise exception 'field FuncName could not be empty';
        end if;

        if       p_args ?   'Periodicity'
        and cast(p_args ->> 'Periodicity' as integer) != 0
        and cast(p_args ->> 'Periodicity' as integer)  < 5 then
            raise exception 'field Periodicity must be >= 5';
        end if;

        insert into syncocean.request (
            title, description, schema_name, func_name, launch_time, periodicity, params
        ) values (
                                                                                                   p_args ->> 'Title'                                                   ,
            case when p_args ? 'Description'                                            then       p_args ->> 'Description'                                          end,
                                                                                                   p_args ->> 'SchemaName'                                              ,
                                                                                                   p_args ->> 'FuncName'                                                ,
            case when p_args ? 'LaunchTime'  and (p_args ->> 'LaunchTime' ) is not null then cast (p_args ->> 'LaunchTime'  as timestamptz) else now()               end,
            case when p_args ? 'Periodicity' and (p_args ->> 'Periodicity') is not null then cast (p_args ->> 'Periodicity' as integer)     else 0                   end,
            case when p_args ? 'Params'      and (p_args ->  'Params'     ) is not null      then  p_args ->  'Params'                      else cast('{}' as jsonb) end
        ) returning id, launch_time into _id, _lt;

        _th = now() + interval '1 minute';

        if _lt < _th then
            _lt = _th;
        end if;

        insert into syncocean.history (request_id, job_id)
        values (_id, cron.schedule(
            format(
                '%s %s %s %s *',
                extract(min   from _lt),
                extract(hour  from _lt),
                extract(day   from _lt),
                extract(month from _lt)
            ),
            format(
                'select syncocean.request_execution(%L)',
                _id
            )
        ));
    end if;

    return _id;
end;
$$;

ALTER FUNCTION syncocean.nu_request(p_args jsonb) OWNER TO postgres;


CREATE FUNCTION syncocean.request_execution(p_request_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
    _cr record;      -- Current request
    _ch record;      -- Current history
    _nt timestamptz; -- Next launch time
    _rs integer;     -- Result
    _tm text;        -- Text message
begin
    -- Get more information about request
    select * into _cr from syncocean.request
    where id = p_request_id;

    -- Get more information about history record
    select * into _ch from syncocean.history
    where request_id = p_request_id
      and job_id is not null;

    if not found then
        raise exception 'no history record found';
    end if;

    -- Cancel current job
    if _ch.job_id >= 0 then
        perform cron.unschedule(_ch.job_id);
    end if;

    -- Erase job id
    update syncocean.history
    set job_id = null
    where id = _ch.id;

    if _cr.archived then
        return;
    end if;

    -- If the periodicity value is greater than zero,
    -- then schedule its execution again
    if _cr.periodicity > 0 then
        _nt = now() + _cr.periodicity * interval '1 minute';

        insert into syncocean.history (request_id, job_id)
        values (p_request_id, cron.schedule(
            format(
                '%s %s %s %s *',
                extract(min   from _nt),
                extract(hour  from _nt),
                extract(day   from _nt),
                extract(month from _nt)
            ),
            format(
                'select syncocean.request_execution(%L)',
                p_request_id
            )
        ));
    end if;

    -- Begin of execution
    update syncocean.history
    set start_time = clock_timestamp()
    where id = _ch.id;

    begin
        execute format(
            'select %I.%I(%L, %L)',
            _cr.schema_name,
            _cr.func_name,
            _ch.id,
            _cr.params
        ) into _rs;
    exception when others then
        get stacked diagnostics _tm = message_text;
    end;

    if _tm is null then
        _tm = 'success';
    end if;

    -- End of execution
    update syncocean.history
    set end_time  = clock_timestamp(),
        status    = _rs,
        debug_msg = _tm
    where id = _ch.id;
end;
$$;

ALTER FUNCTION syncocean.request_execution(p_request_id uuid) OWNER TO postgres;


CREATE TABLE demo.document (
	id uuid NOT NULL DEFAULT gen_random_uuid(),
	full_name text NOT NULL,
	category text NOT NULL,
	CONSTRAINT companies_pk PRIMARY KEY (id, category)
)
PARTITION BY LIST (category);


CREATE TABLE demo.document_payment
PARTITION OF demo.document FOR VALUES IN ('Payment');


CREATE TABLE demo.document_other
PARTITION OF demo.document FOR VALUES IN ('Other');


CREATE TABLE syncocean.base (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    edit timestamp with time zone DEFAULT now() NOT NULL,
    editor name DEFAULT current_user NOT NULL COLLATE pg_catalog."default",
    archived boolean DEFAULT false NOT NULL
);

ALTER TABLE syncocean.base OWNER TO postgres;


CREATE TABLE syncocean.history (
    request_id uuid NOT NULL,
    start_time timestamp with time zone,
    end_time timestamp with time zone,
    status integer,
    job_id bigint,
    debug_msg text
)
INHERITS (syncocean.base);

ALTER TABLE syncocean.history OWNER TO postgres;

COMMENT ON COLUMN syncocean.history.start_time IS 'Запланированное время начала исполнения';

COMMENT ON COLUMN syncocean.history.end_time IS 'Фактическое время окончания исполнения';

COMMENT ON COLUMN syncocean.history.status IS 'Код результата исполнения';


CREATE TABLE syncocean.log (
    history_id uuid NOT NULL,
    log_time timestamp with time zone NOT NULL,
    payload jsonb NOT NULL
)
INHERITS (syncocean.base);

ALTER TABLE syncocean.log OWNER TO postgres;

COMMENT ON COLUMN syncocean.log.log_time IS 'Время создания записи';

COMMENT ON COLUMN syncocean.log.payload IS 'Пользовательские данные';


CREATE TABLE syncocean.request (
    title text NOT NULL,
    description text,
    schema_name text NOT NULL,
    func_name text NOT NULL,
    launch_time timestamp with time zone NOT NULL,
    periodicity integer NOT NULL,
    params jsonb NOT NULL
)
INHERITS (syncocean.base);

ALTER TABLE syncocean.request OWNER TO postgres;

COMMENT ON COLUMN syncocean.request.title IS 'Заголовок';

COMMENT ON COLUMN syncocean.request.description IS 'Описание';

COMMENT ON COLUMN syncocean.request.schema_name IS 'Имя схемы с исполняемой функцией';

COMMENT ON COLUMN syncocean.request.func_name IS 'Имя исполняемой функции';

COMMENT ON COLUMN syncocean.request.launch_time IS 'Время запуска';

COMMENT ON COLUMN syncocean.request.periodicity IS 'Периодичность исполнения в минутах';

COMMENT ON COLUMN syncocean.request.params IS 'Набор передаваемых в функцию данных';


ALTER TABLE ONLY syncocean.history ALTER COLUMN id SET DEFAULT gen_random_uuid();

ALTER TABLE ONLY syncocean.history ALTER COLUMN edit SET DEFAULT now();

ALTER TABLE ONLY syncocean.history ALTER COLUMN editor SET DEFAULT current_user;

ALTER TABLE ONLY syncocean.history ALTER COLUMN archived SET DEFAULT false;


ALTER TABLE ONLY syncocean.log ALTER COLUMN id SET DEFAULT gen_random_uuid();

ALTER TABLE ONLY syncocean.log ALTER COLUMN edit SET DEFAULT now();

ALTER TABLE ONLY syncocean.log ALTER COLUMN editor SET DEFAULT current_user;

ALTER TABLE ONLY syncocean.log ALTER COLUMN archived SET DEFAULT false;


ALTER TABLE ONLY syncocean.request ALTER COLUMN id SET DEFAULT gen_random_uuid();

ALTER TABLE ONLY syncocean.request ALTER COLUMN edit SET DEFAULT now();

ALTER TABLE ONLY syncocean.request ALTER COLUMN editor SET DEFAULT current_user;

ALTER TABLE ONLY syncocean.request ALTER COLUMN archived SET DEFAULT false;


ALTER TABLE ONLY syncocean.base ADD CONSTRAINT base_pkey PRIMARY KEY (id);

ALTER TABLE ONLY syncocean.history ADD CONSTRAINT history_pkey PRIMARY KEY (id);

ALTER TABLE ONLY syncocean.log ADD CONSTRAINT log_pkey PRIMARY KEY (id);

ALTER TABLE ONLY syncocean.request ADD CONSTRAINT request_pkey PRIMARY KEY (id);


CREATE INDEX history_start_time_index ON syncocean.history USING btree (start_time);


ALTER TABLE ONLY syncocean.history ADD CONSTRAINT history_request_id_fkey FOREIGN KEY (request_id) REFERENCES syncocean.request(id);

ALTER TABLE ONLY syncocean.log ADD CONSTRAINT log_history_id_fkey FOREIGN KEY (history_id) REFERENCES syncocean.history(id);

-- Run in the TARGET DB (e.g., ga2026)
CREATE EXTENSION IF NOT EXISTS dblink;
CREATE EXTENSION IF NOT EXISTS postgis;

DO $$
DECLARE
  -- Adjust these:
  v_host        text := 'localhost';
  v_port        text := '5432';
  v_user        text := 'postgres';
  v_pass        text := 'dontuseoldserver';     -- <<< your real password
  v_srcdb       text := 'ga2026_staging';       -- remote DB
  v_src_schema  text := 'postgres';             -- remote schema
  v_dst_schema  text := 'postgres';             -- target schema (this DB)

  v_conn          text := format('host=%s port=%s dbname=%s user=%s password=%s',
                                 v_host, v_port, v_srcdb, v_user, v_pass);

  r_tab           record;
  v_remote_sql    text;
  v_select_remote text;
  v_signature     text;  -- dblink column definition list: "col1 type, col2 type, ..."
  v_quoted_tbl    text;

  v_cols          record;
BEGIN
  -- 1) List tables from remote schema (skip spatial_ref_sys)
  FOR r_tab IN
    SELECT x.table_name
    FROM dblink(
      v_conn,
      format($SQL$
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = %L
          AND table_type   = 'BASE TABLE'
          AND table_name  <> 'spatial_ref_sys'
        ORDER BY table_name
      $SQL$, v_src_schema)
    ) AS x(table_name text)
  LOOP
    v_select_remote := '';
    v_signature     := '';

    -- 2) Columns: geometry -> geometry(MultiPolygon,4326), else TEXT
    FOR v_cols IN
      SELECT
        column_name,
        ordinal_position,
        udt_name
      FROM dblink(
        v_conn,
        format($SQL$
          SELECT column_name,
                 ordinal_position,
                 udt_name
          FROM information_schema.columns
          WHERE table_schema = %L
            AND table_name   = %L
          ORDER BY ordinal_position
        $SQL$, v_src_schema, r_tab.table_name)
      ) AS c(
        column_name text,
        ordinal_position int,
        udt_name text
      )
      ORDER BY ordinal_position
    LOOP
      IF lower(v_cols.udt_name) = 'geometry' THEN
        -- Remote: cast to geometry(MultiPolygon,4326)
        v_select_remote := v_select_remote
          || CASE WHEN v_select_remote = '' THEN '' ELSE ', ' END
          || format('%1$I::geometry(MultiPolygon,4326) AS %1$I', v_cols.column_name);

        -- Signature: same geometry typmod
        v_signature := v_signature
          || CASE WHEN v_signature = '' THEN '' ELSE ', ' END
          || format('%I geometry(MultiPolygon,4326)', v_cols.column_name);
      ELSE
        -- Remote: raw column
        v_select_remote := v_select_remote
          || CASE WHEN v_select_remote = '' THEN '' ELSE ', ' END
          || format('%I', v_cols.column_name);

        -- Signature: TEXT
        v_signature := v_signature
          || CASE WHEN v_signature = '' THEN '' ELSE ', ' END
          || format('%I text', v_cols.column_name);
      END IF;
    END LOOP;

    IF v_select_remote = '' THEN
      RAISE NOTICE 'No columns for %. Skipping.', r_tab.table_name;
      CONTINUE;
    END IF;

    -- 3) Build & run CTAS via dblink with strict geometry signature
    v_quoted_tbl := format('%I.%I', v_dst_schema, r_tab.table_name);

    EXECUTE format('DROP TABLE IF EXISTS %s CASCADE;', v_quoted_tbl);

    v_remote_sql := format(
      'SELECT %s FROM %I.%I',
      v_select_remote,
      v_src_schema,
      r_tab.table_name
    );

    EXECUTE format(
      'CREATE TABLE %s AS SELECT * FROM dblink(%L, %L) AS t(%s);',
      v_quoted_tbl,
      v_conn,
      v_remote_sql,
      v_signature
    );

    RAISE NOTICE 'Created %', v_quoted_tbl;
  END LOOP;
END$$;

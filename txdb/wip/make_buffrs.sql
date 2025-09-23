
DO $$
DECLARE 
    -- Distances in meters (0.125, 0.25, 0.5 mi)
    dist_list  float[] := ARRAY[201.17, 402.34, 804.67];
    suffix_list text[] := ARRAY['0125', '025', '05'];
    i int;
BEGIN
    FOR i IN 1..array_length(dist_list,1) LOOP
        EXECUTE format($f$
            -- Drop old tables if they exist
            DROP TABLE IF EXISTS buffers_schools_%1$s, buffers_groc_%1$s, buffers_lib_%1$s, buffers_park_%1$s;
            DROP TABLE IF EXISTS overlap_sgl_%1$s, overlap_sgp_%1$s, overlap_slp_%1$s, overlap_glp_%1$s;
            DROP TABLE IF EXISTS overlap_3buffers_sep_%1$s, overlap_3buffers_union_%1$s;

            -- Buffers
            CREATE TABLE buffers_schools_%1$s AS
            SELECT ST_Buffer(shape::geography, %2$s)::geometry AS geom
            FROM public_schools_tea_24_25;

            CREATE TABLE buffers_groc_%1$s AS
            SELECT ST_Buffer(shape::geography, %2$s)::geometry AS geom
            FROM groc_final_done_uniq;

            CREATE TABLE buffers_lib_%1$s AS
            SELECT ST_Buffer(shape::geography, %2$s)::geometry AS geom
            FROM lib_final_done_uniq;

            CREATE TABLE buffers_park_%1$s AS
            SELECT ST_Buffer(shape::geography, %2$s)::geometry AS geom
            FROM park_final_done_uniq;

            -- 3-way overlaps
            CREATE TABLE overlap_sgl_%1$s AS
            SELECT ST_Intersection(ST_Intersection(s.geom, g.geom), l.geom) AS geom
            FROM buffers_schools_%1$s s
            JOIN buffers_groc_%1$s g ON ST_Intersects(s.geom, g.geom)
            JOIN buffers_lib_%1$s l ON ST_Intersects(s.geom, l.geom)
            WHERE ST_Intersects(g.geom, l.geom);

            CREATE TABLE overlap_sgp_%1$s AS
            SELECT ST_Intersection(ST_Intersection(s.geom, g.geom), p.geom) AS geom
            FROM buffers_schools_%1$s s
            JOIN buffers_groc_%1$s g ON ST_Intersects(s.geom, g.geom)
            JOIN buffers_park_%1$s p ON ST_Intersects(s.geom, p.geom)
            WHERE ST_Intersects(g.geom, p.geom);

            CREATE TABLE overlap_slp_%1$s AS
            SELECT ST_Intersection(ST_Intersection(s.geom, l.geom), p.geom) AS geom
            FROM buffers_schools_%1$s s
            JOIN buffers_lib_%1$s l ON ST_Intersects(s.geom, l.geom)
            JOIN buffers_park_%1$s p ON ST_Intersects(s.geom, p.geom)
            WHERE ST_Intersects(l.geom, p.geom);

            CREATE TABLE overlap_glp_%1$s AS
            SELECT ST_Intersection(ST_Intersection(g.geom, l.geom), p.geom) AS geom
            FROM buffers_groc_%1$s g
            JOIN buffers_lib_%1$s l ON ST_Intersects(g.geom, l.geom)
            JOIN buffers_park_%1$s p ON ST_Intersects(g.geom, p.geom)
            WHERE ST_Intersects(l.geom, p.geom);

            -- Separate overlaps
            CREATE TABLE overlap_3buffers_sep_%1$s AS
            SELECT geom FROM overlap_sgl_%1$s
            UNION ALL
            SELECT geom FROM overlap_sgp_%1$s
            UNION ALL
            SELECT geom FROM overlap_slp_%1$s
            UNION ALL
            SELECT geom FROM overlap_glp_%1$s;

            ALTER TABLE overlap_3buffers_sep_%1$s
            ADD COLUMN objectid SERIAL;

            -- Unioned overlaps
            CREATE TABLE overlap_3buffers_union_%1$s AS
            SELECT ST_Union(geom) AS geom
            FROM overlap_3buffers_sep_%1$s;

            ALTER TABLE overlap_3buffers_union_%1$s
            ADD COLUMN objectid SERIAL;
        $f$, suffix_list[i], dist_list[i]);
    END LOOP;
END$$;

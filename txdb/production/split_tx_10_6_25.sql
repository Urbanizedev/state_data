DO $$
DECLARE
    region INTEGER;
    rtype TEXT;
    rtypes TEXT[] := ARRAY['rural', 'urban'];
    table_name TEXT;
    sql TEXT;
BEGIN
    FOR region IN 1..13 LOOP
        FOREACH rtype IN ARRAY rtypes LOOP
            table_name := format('texas_final_region_10125_%s_%s', region, rtype);
            RAISE NOTICE '⏳ Creating table: %', table_name;

            sql := format($fmt$
                DROP TABLE IF EXISTS %I;
                CREATE TABLE %I AS
                SELECT objectid::text, target_fid, geoid::int, parcelnumb, alt_parcelnumb1, improvval, landval, parval, agval, saledate, owner, mailadd, mail_city, mail_state2, mail_zip, address, scity, 
				county, state2, szip, legaldesc, ll_last_refresh,  ll_gissqft, lat, lon, reg_des, elm_fid, elm_dist,  name, 
				park_fid1, park_dist1, lib_fid1, lib_dist1, gro_fid1, gro_dist1, school_distance_feet_2 as school_distance,school_name_new_2 as school_name, max3_10_3_2025 as tiebreaker_score, 
				  park_length_2,  job_proxy_rural_score, job_proxy_urban_score, crp_26 AS crp_score, deconeldery, decongeneral, deconsupportive, oi_objectid, statefp,
				countyfp, tractce, geoid_oi, name_oi, namelsad, mtfcc, funcstat, aland, awater, intptlat, intptlon, census_tract::text, geography, county_fips::int, county_oi, 
				region::int, median_household_income, q3_income, q2_income, q1_income, median_household_income_quartile, median_poverty_rate_by_region, poverty_rate_rank, total, 
				number_in_poverty, poverty_rate, hoa_index_a_v3 as hoa_index_a, hoa_index_b, hoa_index_c, itemc_elderlyscore, itemc_generalscore, itemc_supportivescore, item_d_score, item_e_score, 
				item_f_elderlyscore, item_f_generalscore, item_f_supportivescore, item_h_score, po, state, population, state_1::int, id::int, placeid::text, census_population_2010,
				increase_or_decrease, increase, objectid_pic, txdot_city_nbr, city_fips, cnty_seat_flag, pop1990, pop2000, pop2010, pop2020, pop2022, pop_cd, map_color_cd, color_cd, 
				gid, rural_urban, pic_objectid, type as urban_rural_type, 
				job_proxy_urban_crp_or_hoa_score_v2 as job_proxy_urban_crp_or_hoa_score, 
				job_proxy_rural_crp_or_hoa_score_v2 as job_proxy_rural_crp_or_hoa_score, 
				underserviceelderly_v2 as underserviceelderly, 
				underservicgeneral_v2 as underservicgeneral, 
				underservicesupportive_v2 as underservicesupportive, 
				urban_elderly_v2 as urban_elderly,
				rural_elderly_v2 as rural_elderly,  
				urban_general_v2 as urban_general,
				rural_general_v2 as rural_general,
				urban_supportive_v2 as urban_supportive, 
				--,rural_supportive
			

   
	
    crp_pt_property,
    crv_pt_violent,
	city_nm,
	ecr_e_campus_id as elementary_campus_id,
    ecr_c_rating as elementary_campus_rating,
    ecr_grdtype as elementary_grade_type,
    ecr_grdhigh as elementary_grade_high,
    ecr_grdlow as elementary_grade_low,
    ecr_campname as elementary_school_name,
	mcr_m_campus_id as middle_school_campus_id ,
    mcr_c_rating as middle_school_campus_rating,
    mcr_grdtype as middle_school_grade_type,
    mcr_grdhigh as middle_school_grade_high,
    mcr_grdlow as middle_school_grade_low,
    mcr_campname as middle_school_name,
	scr_s_campus_id as high_school_campus_id,
    scr_c_rating as high_school_campus_rating,
    scr_grdtype as high_school_grade_type,
    scr_grdhigh as high_school_grade_high,
	
    scr_grdlow as high_school_grade_low,
    scr_campname as high_school_name,
	ST_Area(ST_Transform(shape, 3857)) / 4046.8564224 as gisacre,
	shape
                
				FROM postgres.texas_final_v5_in_use
                WHERE region = %L AND type = %L
				--and tl4_boost is not null
				--AND (acres >= 1.85)
				and  ST_Area(ST_Transform(shape, 3857)) / 4046.8564224 >.18
				and greatest(urban_elderly_v2, rural_elderly_v2, rural_general_v2, urban_general_v2, urban_supportive_v2) >= 12 
				--ll_gisacre >.18 and max2 > 15000
            $fmt$, table_name, table_name, region, rtype);

            EXECUTE sql;

            RAISE NOTICE '✅ Successfully created %', table_name;
        END LOOP;
    END LOOP;
END $$;

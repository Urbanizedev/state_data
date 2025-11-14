# PostGIS Schema Repair & Rebuild – Checklist SOP

**Important:**  
This entire procedure must be performed **for every database** in your environment to ensure all DBs share the same PostGIS schema origin.

---

## 1. Identify PostGIS schema
```sql
SELECT extname, nspname
FROM pg_extension e
JOIN pg_namespace n ON e.extnamespace = n.oid
WHERE extname LIKE 'postgis%';
```

---

## 2. Determine preferred schema origin
- Import an external GIS dataset (parcels, OSM, etc.) into different database environments.
- Identify which PostGIS schema origin supports clean external data imports.
- Set this as the **standard schema** going forward (e.g., `public`).

---

## 3. Create a full safety backup (custom format)
**Purpose:** This backup is strictly for disaster recovery if anything goes wrong.

```bash
pg_dump -Fc -d <db_name> -f <db_name>.backup
```

---

## 4. Dump to editable SQL
```bash
pg_dump -Fp -d <db_name> -f <db_name>_source.sql
```

---

## 5. Correct schema references
In the SQL file:
- Update all schema-qualified PostGIS references to the **standard schema**.
- Update any `CREATE EXTENSION postgis WITH SCHEMA ...` statements.
- Ensure no edits occur inside data literals.

---

## 6. Create clean destination database
```sql
CREATE DATABASE <new_db_name>;
```

---

## 7. Install PostGIS in the standard schema
```sql
CREATE EXTENSION postgis SCHEMA <standard_schema>;
```

---

## 8. Restore corrected SQL
```bash
psql -d <new_db_name> -f <db_name>_source.sql
```

---

## 9. Verify PostGIS
```sql
SELECT ST_AsText(ST_Point(1,1));
```

---

## 10. Verify cross-database compatibility
- Confirm FDW operations work across databases.
- Confirm restoring/transferring tables between databases works cleanly.
- Confirm geometry types resolve correctly in all environments.

---

## Repeat for Every Database
This process must be completed **for each database** to ensure all DBs use the same PostGIS schema origin and behave consistently with imports, FDW, and cross-DB operations.

---

## Done
All databases will be repaired and aligned to the unified PostGIS schema standard.

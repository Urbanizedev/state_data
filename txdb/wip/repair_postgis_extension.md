# PostGIS Schema Repair & Rebuild – Checklist SOP

**Critical Notes:**  
- This entire procedure must be performed **for every database** to ensure all DBs share the same PostGIS schema origin.  
- **All commands in this document are EXAMPLES ONLY.**  
- The actual commands you run may be **completely different** depending on:
  - your OS  
  - your PostgreSQL installation  
  - your PostGIS version  
  - your environment variables  
  - your authentication setup  
  - your database names and schemas  
- **Use professional judgment**. Adjust every command and step to fit your environment.

---

## 1. Identify PostGIS schema
*(Example query — adjust or replace entirely as needed)*

```sql
SELECT extname, nspname
FROM pg_extension e
JOIN pg_namespace n ON e.extnamespace = n.oid
WHERE extname LIKE 'postgis%';
```

---

## 2. Determine preferred schema origin
To identify the schema origin to standardize on:

- Import **external GIS datasets** into each environment (parcels, OSM, etc.).
- **Export from ArcGIS (ArcGIS Pro/ArcMap)** into each database to ensure feature class exports work correctly.
- Select the schema origin that supports **both imports and ArcGIS exports** without conflict.
- This becomes the **standard schema** (e.g., `public`).

Use judgment when evaluating results.

---

## 3. Create a full safety backup (custom format)
**Purpose:**  
A clean recovery snapshot if anything goes wrong.  
This file is not edited.

*(Example — your command may differ)*

```bash
pg_dump -Fc -d <db_name> -f <db_name>.backup
```

---

## 4. Dump to editable SQL
*(Example — adjust paths, flags, DB names as needed)*

```bash
pg_dump -Fp -d <db_name> -f <db_name>_source.sql
```

---

## 5. Correct PostGIS schema references
In the SQL file:

- Update schema-qualified PostGIS functions/types to the **standard schema**.
- Fix any `CREATE EXTENSION postgis WITH SCHEMA ...` statements.
- Ensure replacements do **not** affect data literals.

Use appropriate tools or scripts based on your environment.

---

## 6. Create clean destination database
*(Example — your DB creation method may differ)*

```sql
CREATE DATABASE <new_db_name>;
```

---

## 7. Install PostGIS in the standard schema
*(Example — adjust schema name or extension settings as needed)*

```sql
CREATE EXTENSION postgis SCHEMA <standard_schema>;
```

---

## 8. Restore corrected SQL
*(Example — your restore command may differ entirely)*

```bash
psql -d <new_db_name> -f <db_name>_source.sql
```

---

## 9. Verify PostGIS functionality
*(Example test — you may verify differently)*

```sql
SELECT ST_AsText(ST_Point(1,1));
```

---

## 10. Verify cross-database compatibility
Use judgment to ensure:

- FDW operations work between databases  
- Restoring/transferring tables works cleanly  
- Geometry types resolve correctly everywhere  
- ArcGIS can **export** and **import** into all standardized databases  

---

## Repeat for Every Database
Perform this workflow **for each database** until all DBs share a unified PostGIS schema origin and behave consistently.

---

## Done
Your environment will be standardized with:

- a consistent PostGIS schema origin  
- reliable external dataset imports  
- reliable ArcGIS exports/imports  
- consistent FDW and cross-database operations  

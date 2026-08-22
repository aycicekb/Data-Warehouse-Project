/*
===============================================================================
DDL Script: Load Silver Layer Tables
===============================================================================
Script Purpose:
    This script modify tables in the 'silver' schema by loading modified and 
    standardized data from 'bronze layer' into the already created tables.
Here:
- duplicate values were found and their ordered-by-date versions were demonstrated,
then the earliest record was included. (Removing Duplicates)
- abbreviated expressions in crm_cst_gndr and crm_cst_marital_status were set as
extended expressions. (Data Normalization/Data Standardization)
- missing values were marked as 'n/a'. (Handling Missing Values)
- in case of lowercase expressions, as abbreviations, were set as uppercase to
prevent errors in future results.
- unwanted spacing was checked out and concerned columns were trimmed.
- date errors were corrected.
===============================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$ 
BEGIN

    RAISE NOTICE '========================================================================';
    RAISE NOTICE ' LOADING SILVER LAYER ';
    RAISE NOTICE '========================================================================';

    RAISE NOTICE '------------------------------------------------------------------------';
    RAISE NOTICE ' LOADING CRM TABLES ';
    RAISE NOTICE '------------------------------------------------------------------------';

    -- silver.crm_cust_info data standardization
    RAISE NOTICE ' >> Truncating Table: silver.crm_cust_info';
    TRUNCATE TABLE silver.crm_cust_info;

    RAISE NOTICE ' >> Inserting Data into: silver.crm_cust_info';
    INSERT INTO silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    )
    SELECT 
        cst_id,
        cst_key,
        TRIM(cst_firstname) AS cst_firstname,
        TRIM(cst_lastname) AS cst_lastname,
        CASE UPPER(TRIM(cst_marital_status))
            WHEN 'M' THEN 'Married'
            WHEN 'S' THEN 'Single'
            ELSE 'n/a'
        END AS cst_marital_status,

        CASE UPPER(TRIM(cst_gndr))
            WHEN 'F' THEN 'Female'
            WHEN 'M' THEN 'Male'
            ELSE 'n/a'
        END AS cst_gndr,
        cst_create_date
    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date) AS flag_last
        FROM
            bronze.crm_cust_info
        WHERE 
            cst_id IS NOT NULL
    )t 
    WHERE 
        flag_last = 1;



    -- silver.crm_prd_info data standardization
    RAISE NOTICE ' >> Truncating Table: silver.crm_prd_info';
    TRUNCATE TABLE silver.crm_prd_info;

    RAISE NOTICE ' >> Inserting Data into: silver.crm_prd_info';
    INSERT INTO silver.crm_prd_info (
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )
    SELECT 
        prd_id,
        REPLACE(SUBSTRING(prd_key FROM 1 FOR 5), '-', '_') AS cat_id,
        SUBSTRING(prd_key FROM 7 FOR LENGTH(prd_key)) AS prd_key,
        prd_nm,
        COALESCE(prd_cost, 0) AS prd_cost,
        CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
        END AS prd_line,
        prd_start_dt,
        LEAD(prd_start_dt) OVER (
            PARTITION BY prd_key
            ORDER BY prd_start_dt
        ) - 1 AS prd_end_dt 
    FROM bronze.crm_prd_info;



    -- silver.crm_prd_sales_details standardization
    RAISE NOTICE ' >> Truncating Table: silver.crm_sales_details';
    TRUNCATE TABLE silver.crm_sales_details;

    RAISE NOTICE ' >> Inserting Data into: silver.crm_sales_details';
    INSERT INTO silver.crm_sales_details (
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,	
        sls_ship_dt,	
        sls_due_dt,	
        sls_sales,	
        sls_quantity,	
        sls_price
    )
    SELECT 
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        CASE
            WHEN
            LENGTH(sls_order_dt::TEXT) = 8 THEN TO_DATE(sls_order_dt::TEXT, 'YYYYMMDD')
            ELSE NULL
        END AS sls_order_dt,
        CASE
            WHEN
            LENGTH(sls_ship_dt::TEXT) = 8 THEN TO_DATE(sls_ship_dt::TEXT, 'YYYYMMDD')
            ELSE NULL
        END AS sls_ship_dt,
        CASE
            WHEN
            LENGTH(sls_due_dt::TEXT) = 8 THEN TO_DATE(sls_due_dt::TEXT, 'YYYYMMDD')
            ELSE NULL
        END AS sls_due_dt,
        CASE    
            WHEN sls_sales IS NULL OR sls_sales < 0 OR sls_sales != ABS(sls_price) * sls_quantity THEN ABS(sls_price) * sls_quantity
            ELSE sls_sales
        END AS sls_sales,
        sls_quantity,
        CASE 
            WHEN sls_price IS NULL OR sls_price < 0 
            THEN ABS(sls_sales) / NULLIF(sls_quantity, 0)
            ELSE sls_price
        END AS sls_price
    FROM bronze.crm_sales_details;

    RAISE NOTICE '------------------------------------------------------------------------';
    RAISE NOTICE ' LOADING ERP TABLES ';
    RAISE NOTICE '------------------------------------------------------------------------';

    -- silver.erp_cust_az12 standardization
    RAISE NOTICE ' >> Truncating Table: silver.erp_cust_az12';
    TRUNCATE TABLE silver.erp_cust_az12;

    RAISE NOTICE ' >> Inserting Data into: silver.erp_cust_az12';
    INSERT INTO silver.erp_cust_az12 (
        cid,
        bdate,
        gen
    )
    SELECT 
        CASE 
            WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid FROM 4 FOR LENGTH(cid))
            ELSE cid 
        END AS cid,
        CASE 
            WHEN bdate > CURRENT_TIMESTAMP THEN NULL
            ELSE bdate
        END AS bdate,
        CASE
            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
            WHEN UPPER(TRIM(gen)) IN('F', 'FEMALE') THEN 'Female'
            ELSE 'n/a'
        END gen
    FROM bronze.erp_cust_az12;



    -- silver.erp_loc_a101 standardization
    RAISE NOTICE ' >> Truncating Table: silver.erp_loc_a101';
    TRUNCATE TABLE silver.erp_loc_a101;

    RAISE NOTICE ' >> Inserting Data into: silver.erp_loc_a101';
    INSERT INTO silver.erp_loc_a101 (
        cid,
        cntry
    )
    SELECT
        REPLACE(cid, '-', '') AS cid,
        CASE
            WHEN TRIM(cntry) = 'US' OR TRIM(cntry) = 'USA' THEN 'United States'
            WHEN TRIM(cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(cntry) IS NULL OR TRIM(cntry) = '' THEN 'n/a'
            ELSE TRIM(cntry)
        END AS cntry
    FROM bronze.erp_loc_a101;



    -- silver.erp_px_cat_g1v2 standardization
    RAISE NOTICE ' >> Truncating Table: silver.erp_px_cat_g1v2';
    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    RAISE NOTICE ' >> Inserting Data into: silver.erp_px_cat_g1v2';
    INSERT INTO silver.erp_px_cat_g1v2 (
        id,
        cat,
        subcat,
        maintenance
    )
    SELECT
        id,
        cat,
        subcat,
        maintenance
    FROM bronze.erp_px_cat_g1v2;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error occurred during loading silver layer: %', SQLERRM;
END;
$$;



/*
===============================================================================
DDL Script: Load Bronze Layer Tables
===============================================================================
Script Purpose:
    This script modify tables in the 'bronze' schema by loading csv data into 
    the already created tables.
===============================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$ 
BEGIN

    RAISE NOTICE '========================================================================';
    RAISE NOTICE ' LOADING BRONZE LAYER ';
    RAISE NOTICE '========================================================================';

    RAISE NOTICE '------------------------------------------------------------------------';
    RAISE NOTICE ' LOADING CRM TABLES ';
    RAISE NOTICE '------------------------------------------------------------------------';

    RAISE NOTICE ' >> Truncating Table: bronze.crm_cust_info';
    TRUNCATE TABLE bronze.crm_cust_info;

    RAISE NOTICE ' >> Inserting Data into: bronze.crm_cust_info';
    copy bronze.crm_cust_info
    FROM 'C:\Users\Lenovo\Desktop\Data Warehouse Project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ',');


    RAISE NOTICE ' >> Truncating Table: bronze.crm_prd_info';
    TRUNCATE TABLE bronze.crm_prd_info;

    RAISE NOTICE ' >> Inserting Data into: bronze.crm_prd_info';
    copy bronze.crm_prd_info
    FROM 'C:\Users\Lenovo\Desktop\Data Warehouse Project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ',');


    RAISE NOTICE ' >> Truncating Table: bronze.crm_sales_details';
    TRUNCATE TABLE bronze.crm_sales_details;

    RAISE NOTICE ' >> Inserting Data into: bronze.crm_sales_details';
    copy bronze.crm_sales_details
    FROM 'C:\Users\Lenovo\Desktop\Data Warehouse Project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ',');

    RAISE NOTICE '------------------------------------------------------------------------';
    RAISE NOTICE ' LOADING ERP TABLES ';
    RAISE NOTICE '------------------------------------------------------------------------';

    RAISE NOTICE ' >> Truncating Table: bronze.erp_cust_az12';
    TRUNCATE TABLE bronze.erp_cust_az12;

    RAISE NOTICE ' >> Inserting Data into: bronze.erp_cust_az12';
    copy bronze.erp_cust_az12
    FROM 'C:\Users\Lenovo\Desktop\Data Warehouse Project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ',');

    
    RAISE NOTICE ' >> Truncating Table: bronze.erp_loc_a101';
    TRUNCATE TABLE bronze.erp_loc_a101;

    RAISE NOTICE ' >> Inserting Data into: bronze.erp_loc_a101';
    copy bronze.erp_loc_a101
    FROM 'C:\Users\Lenovo\Desktop\Data Warehouse Project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ',');


    RAISE NOTICE ' >> Truncating Table: bronze.erp_px_cat_g1v2';
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;

    RAISE NOTICE ' >> Inserting Data into: bronze.erp_px_cat_g1v2';
    copy bronze.erp_px_cat_g1v2
    FROM 'C:\Users\Lenovo\Desktop\Data Warehouse Project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
    WITH (FORMAT csv, HEADER true, DELIMITER ',');

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error occurred during loading bronze layer: %', SQLERRM;

END;
$$;



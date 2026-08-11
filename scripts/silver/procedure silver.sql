CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @start_batch_time DATETIME, @end_batch_time DATETIME;
	BEGIN TRY
		SET @start_batch_time = GETDATE();
		PRINT '=================================================================='; 
		PRINT 'loading silver Layer'; 
		PRINT '=================================================================='; 

		PRINT '-------------------------------------------------------------------';
		PRINT 'loading CRM Tables'; 
		PRINT '-------------------------------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating table: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT '>> Inserting Data Into: silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info(
		 cst_id
		,cst_key
		,cst_firstname
		,cst_lastname
		,cst_material_status
		,cst_gender
		,cst_create_date )

		SELECT 
			   cst_id
			  ,cst_key
			  ,trim(cst_firstname) as cst_firstname
			  ,trim(cst_lastname) as cst_lastname
			  ,CASE WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
					WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
					ELSE 'n/a'
			   END as cst_material_status
			  ,CASE WHEN UPPER(TRIM(cst_gender)) = 'F' THEN 'Female'
					WHEN UPPER(TRIM(cst_gender)) = 'M' THEN 'Male'
					ELSE 'n/a'
			   END as cst_gender
			  ,cst_create_date
		FROM (
			SELECT 
			*,
			ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
			FROM bronze.crm_cust_info
			where cst_id is not null) t
			where flag_last =1 
		
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
		PRINT '---------------------------------';
		
		---------------------------------------------------------
		SET @start_time = GETDATE();
		PRINT '>> Truncating table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT '>> Inserting Data Into: silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info (
			prd_id ,
			cat_id ,
			prd_key, 
			prd_nm,
			prd_cost ,
			prd_line ,
			prd_start_dt ,
			prd_end_dt )

		SELECT 
			   [prd_id]
			  ,REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id
			  ,SUBSTRING(prd_key,7,LEN(prd_key)) as prd_key
			  ,[prd_nm]
			  ,ISNULL(prd_cost,0) prd_cost
			  ,CASE UPPER(TRIM(prd_line))
					WHEN 'M' THEN 'Mountain'
					WHEN 'R' THEN 'Road'
					WHEN 'S' THEN 'Other Sales'
					WHEN 'T' THEN 'Touring'
					ELSE 'n/a'
				END prd_line
			  ,CAST(prd_start_dt AS DATE) prd_start_dt
			  ,CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER by prd_start_dt ASC)-1 AS DATE) prd_end_dt
		FROM bronze.crm_prd_info 
		
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
		PRINT '---------------------------------';
		---------------------------------------------------------
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating table: silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT '>> Inserting Data Into: silver.crm_sales_details';
		INSERT INTO silver.crm_sales_details (
			   [sls_ord_num]
			  ,[sls_prd_key]
			  ,[sls_cust_id]
			  ,[sls_order_dt]
			  ,[sls_ship_dt]
			  ,[sls_due_dt]
			  ,[sls_sales]
			  ,[sls_quantity]
			  ,[sls_price])

		SELECT 
			   [sls_ord_num]
			  ,[sls_prd_key]
			  ,[sls_cust_id]
			  ,case when sls_order_dt = 0 or len(sls_order_dt) !=8 then null
					else CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
			   end sls_order_dt
			  ,case when sls_ship_dt = 0 or len(sls_ship_dt) !=8 then null
					else CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
			   end sls_ship_dt
			  ,case when sls_due_dt = 0 or len(sls_due_dt) !=8 then null
					else CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
			   end sls_due_dt
			  ,case  when sls_sales <=0 or sls_sales is null or sls_sales != ABS(sls_price) * sls_quantity  then ABS(sls_price) * sls_quantity  else sls_sales end sls_sales
			  ,sls_quantity
			  ,case when sls_price =0 or sls_price is null then sls_sales/nullif(sls_quantity,0)  when sls_price <0 then ABS(sls_price) else sls_price end sls_price
		  FROM bronze.crm_sales_details
	
			SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
		PRINT '---------------------------------';

		PRINT '-------------------------------------------------------------------';
		PRINT 'loading ERP Tables'; 
		PRINT '-------------------------------------------------------------------';
		  
		  ---------------------------------------------------------
		SET @start_time = GETDATE();

		PRINT '>> Truncating table: silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12;
		PRINT '>> Inserting Data Into: silver.erp_cust_az12';
  
		  INSERT INTO silver.erp_cust_az12(
			   [CID]
			  ,[BDATE]
			  ,[GEN])
		  select 
		   CASE WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID,4,len(CID)) ELSE CID END CID,
		   CASE WHEN BDATE > GETDATE() THEN NULL ELSE BDATE END BDATE,
		   CASE WHEN UPPER(TRIM(GEN)) IN ('F','FEMALE') THEN 'Female'
				WHEN UPPER(TRIM(GEN)) IN ('M','MALE') THEN 'Male'
				ELSE  'n/a' 
		END GEN
		   from bronze.erp_cust_az12
		
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
		PRINT '---------------------------------';
		  ---------------------------------------------------------
		
		SET @start_time = GETDATE();		
		PRINT '>> Truncating table: silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT '>> Inserting Data Into: silver.erp_loc_a101';
  
		  INSERT INTO silver.erp_loc_a101(
		   CID,
		   CNTRY
		   )
   
		   select 
		   REPLACE(CID,'-','') CID,
		   CASE WHEN TRIM(CNTRY) = 'DE' THEN 'Germany'
				WHEN TRIM(CNTRY) IN ('USA','US') THEN 'United States'
				WHEN CNTRY is null or TRIM(CNTRY)= '' THEN 'n/a'
				ELSE TRIM(CNTRY)
			END CNTRY
		   from bronze.erp_loc_a101

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
		PRINT '---------------------------------';
		   ---------------------------------------------------------
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating table: silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';

		INSERT INTO silver.erp_px_cat_g1v2(
		ID,CAT,SUBCAT,MAINTENANCE)

		select 
		*
		from bronze.erp_px_cat_g1v2
		---------------------------------------------------------
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
		PRINT '---------------------------------';
		
		SET @end_batch_time = GETDATE();
		PRINT '>> Load Batch Duration: ' + CAST(DATEDIFF(second,@start_batch_time,@end_batch_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------------';

	END TRY
	BEGIN CATCH
		PRINT '==================================================================' 
		PRINT 'ERROR OCCURED DURING LOAD SILVER LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '==================================================================' 
	END CATCH
END

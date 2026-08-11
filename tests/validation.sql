-- Validation check

-- expectation: no result
SELECT 
cst_id,count(*)
FROM silver.crm_cust_info
group by cst_id
having count(*) >1 or cst_id is null

-- Check for unwanted spaces
SELECT 
cst_firstname, len(cst_firstname),  len(TRIM(cst_firstname)) as se
FROM silver.crm_cust_info
where len(cst_firstname) != len(TRIM(cst_firstname))
-- Check for consistency -standardization
SELECT 
distinct(cst_material_status)
FROM silver.crm_cust_info

SELECT 
distinct(cst_gender)
FROM silver.crm_cust_info
-------------------------------------------------------------------
-- Chek for nulls or duplicates in primary key
-- expectation: no result

SELECT 
prd_id,count(*)
FROM silver.crm_prd_info
group by prd_id
having count(*) >1 or prd_id is null

-- Check for unwanted spaces
SELECT 
*
FROM silver.crm_prd_info
where len(prd_nm) != len(TRIM(prd_nm))

-- Check for nulls or negative
SELECT 
*
FROM silver.crm_prd_info
where prd_cost is null or prd_cost <0

-- Check for invalid dates
SELECT 
*
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt
-------------------------------------------------------------------------------
-- Check for invalid dates

SELECT 
--nullif(sls_order_dt,0)
*
FROM silver.crm_sales_details
where len(sls_order_dt) != 10
--where sls_order_dt < 0 or sls_order_dt = 0

-- order date< shiping
select sls_order_dt,sls_ship_dt
  FROM silver.crm_sales_details 
  where sls_order_dt > sls_ship_dt or sls_order_dt > sls_due_dt
-- checking data consistency
select 
sls_sales
,sls_quantity,
sls_price
FROM silver.crm_sales_details 
where sls_quantity * sls_price != sls_sales
or sls_sales is null or sls_price is null or sls_quantity is null 
or sls_sales <=0 or sls_price <=0  or sls_quantity <=0  

-- IDENTIFY out of range dates
   select 
   MIN(BDATE),
   MAX(BDATE)
   from silver.erp_cust_az12
   

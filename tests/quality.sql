-- validation quality check
select 
cst_id, count(*)
from(
select  
       ci.cst_id
      ,ci.cst_key
      ,ci.cst_firstname
      ,ci.cst_lastname
      ,ci.cst_material_status
      ,ci.cst_gender
      ,ci.cst_create_date
      ,ca.BDATE
      ,ca.GEN
      ,co.CNTRY
from silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca ON ci.cst_key = ca.CID 
LEFT JOIN silver.erp_loc_a101 AS co ON ci.cst_key = co.CID) t 
GROUP BY cst_id
ORDER BY count(*) DESC

-------

select DISTINCT 
      ci.cst_gender
      ,ca.GEN
from silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca ON ci.cst_key = ca.CID 
LEFT JOIN silver.erp_loc_a101 AS co ON ci.cst_key = co.CID
ORDER BY 1,2
--------------
select DISTINCT 
      CASE WHEN ci.cst_gender !='n/a' THEN ci.cst_gender
           ELSE COALESCE(ca.GEN,'n/a')
        end new_gen
      ,ca.GEN
from silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca ON ci.cst_key = ca.CID 
LEFT JOIN silver.erp_loc_a101 AS co ON ci.cst_key = co.CID
ORDER BY 1,2
--------------------
select* from gold.dim_customer
-------------------
select *
from silver.crm_sales_details 
where sls_order_dt is null

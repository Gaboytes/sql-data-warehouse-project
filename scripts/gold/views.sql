-- CREATING CUSTOMER DIMENSION
CREATE VIEW gold.dim_customer AS
select  
       ROW_NUMBER() OVER(ORDER BY cst_id) AS customer_key
      ,ci.cst_id AS customer_id
      ,ci.cst_key AS customer_number
      ,ci.cst_firstname AS first_name
      ,ci.cst_lastname AS last_name
      ,co.CNTRY AS country
      ,ci.cst_material_status AS marital_status
      ,CASE WHEN ci.cst_gender !='n/a' THEN ci.cst_gender
           ELSE COALESCE(ca.GEN,'n/a')
        end gender
      ,ca.BDATE AS birthdate      
      ,ci.cst_create_date AS create_date
from silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca ON ci.cst_key = ca.CID 
LEFT JOIN silver.erp_loc_a101 AS co ON ci.cst_key = co.CID

-- CREATING PRODUCT DIMENSION
DROP VIEW IF EXISTS gold.dim_products;
CREATE VIEW gold.dim_products AS

select
       row_number() over(order by prd_start_dt,prd_key) AS product_key
      ,pc.prd_id AS product_id
      ,pc.prd_key AS product_number
      ,pc.prd_nm  AS product_name
      ,pc.cat_id AS category_id
      ,pe.CAT AS category
      ,pe.SUBCAT AS subcategory
      ,pe.MAINTENANCE AS maintenance
      ,pc.prd_cost AS cost
      ,pc.prd_line AS product_line
      ,pc.prd_start_dt AS start_date
from silver.crm_prd_info as pc
left join silver.erp_px_cat_g1v2 pe on pc.cat_id = pe.ID 
where pc.prd_end_dt is NULL

-- CREATING FACT SALES TABLES
create view gold.fact_sales AS
select 
       sls_ord_num AS order_number
      ,p.product_key 
      ,c.customer_key
      ,sls_order_dt AS order_date
      ,sls_ship_dt AS shipping_date
      ,sls_due_dt AS due_date
      ,sls_sales AS sales_amount
      ,sls_quantity AS quantity
      ,sls_price
from silver.crm_sales_details s
left join gold.dim_customer c on s.sls_cust_id = c.customer_id
left join gold.dim_products p on s.sls_prd_key = p.product_number




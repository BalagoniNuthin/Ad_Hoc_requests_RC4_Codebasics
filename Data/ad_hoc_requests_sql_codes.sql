# 1. Provide the list of markets in which customer "Atliq Exclusive" operates its
#    business in the APAC region
      
      SELECT 
		DISTINCT market 
	  FROM dim_customer 
      WHERE customer ="Atliq Exclusive" AND region ="APAC";
      
# 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
#    unique_products_2020, unique_products_2021 ,percentage_chg

	WITH CTE2 AS (
	SELECT 
			COUNT(DISTINCT product_code) AS unique_products_2020,
			(SELECT COUNT(DISTINCT product_code)  FROM fact_sales_monthly WHERE fiscal_year =2021) AS unique_products_2021
			FROM fact_sales_monthly 
			WHERE fiscal_year =2020)
	SELECT *,
	 ROUND(((unique_products_2021-unique_products_2020)*100/unique_products_2020),2) AS percentage_change
	 FROM CTE2;


# 3. Provide a report with all the unique product counts for each segment and
#    sort them in descending order of product counts. 
#    The final output contains 2 fields they are segment,product_count

	SELECT 
		 segment,
		 COUNT(segment)  AS product_count
		 FROM dim_product
		 GROUP BY segment
		 ORDER BY product_count DESC;
     
     
#   4. Follow-up: Which segment had the most increase in unique products in
#      2021 vs 2020? The final output contains these fields,
#      segment,product_count_2020,product_count_2021,difference

	WITH CTE4 AS (
		 SELECT 
		 #fsm.*,dp.segment,dp.product,dp.variant
		 dp.segment AS SEGMENT,COUNT(DISTINCT fsm.product_code) AS product_count_2020,
         fsm.fiscal_year
		 FROM fact_sales_monthly AS fsm
		 JOIN dim_product AS dp
		 ON fsm.product_code =dp.product_code
		 WHERE fiscal_year =2020
		 GROUP BY dp.segment
		 ORDER BY product_count_2020 DESC),
		 
		 CTE41 AS (
		 SELECT 
		 #fsm.*,dp.segment,dp.product,dp.variant
		 dp.segment AS SEGMENT1,COUNT(DISTINCT fsm.product_code) AS product_count_2021,fsm.fiscal_year
		 FROM fact_sales_monthly fsm
		 JOIN dim_product dp
		 ON fsm.product_code =dp.product_code
		 WHERE fiscal_year =2021
		 GROUP BY dp.segment
		 ORDER BY product_count_2021 DESC)
		 
		 SELECT 
			  SEGMENT,CTE4.product_count_2020,CTE41.product_count_2021,
			  (CTE41.product_count_2021-CTE4.product_count_2020) AS Difference
			  FROM CTE4
			  JOIN CTE41
			  ON CTE4.SEGMENT =CTE41.SEGMENT1
			  ORDER BY Difference DESC;


# 5. Get the products that have the highest and lowest manufacturing costs.
#    The final output should contain these fields:
#    product_code,product,manufacturing_cost

	SELECT 
		  dp.product_code, product, fmc.manufacturing_cost
		  FROM dim_product dp
		  JOIN fact_manufacturing_cost fmc
		  USING(product_code)
		  WHERE manufacturing_cost IN
		  ((SELECT min(manufacturing_cost) FROM fact_manufacturing_cost)
		  UNION
		  (SELECT max(manufacturing_cost) FROM fact_manufacturing_cost));


#   6. Generate a report which contains the top 5 customers who received an
#      average high pre_invoice_discount_pct for the fiscal year 2021 and in the
#      Indian market. The final output contains these fields,
#      customer_code,customer,average_discount_percentage

	SELECT 
		dc.customer_code,
		dc.customer,
		ROUND(AVG(pre_invoice_discount_pct),4) AS average_discount_percentage
	FROM dim_customer dc
	JOIN fact_pre_invoice_deductions fpid
	ON dc.customer_code=fpid.customer_code
	WHERE market='india' AND fiscal_year=2021 
	GROUP BY dc.customer_code,dc.customer
	ORDER BY average_discount_percentage DESC
	LIMIT 5;

      

#    7. Get the complete report of the Gross sales amount for the customer “Atliq
#       Exclusive” for each month. This analysis helps to get an idea of low and
#       high-performing months and take strategic decisions.The final report contains these columns:
#       Month,Year,Gross sales Amount

	SET sql_mode="";
    
	SELECT  
		date,
		MONTH(f.date) as month,
		MONTHNAME(date) as monthname,
		f.fiscal_year,
		CONCAT(ROUND(SUM(g.gross_price*f.sold_quantity)/1000000,2),'M') AS gross_sales_amount
	 FROM fact_gross_price g 
	 RIGHT JOIN fact_sales_monthly f 
	 ON f.product_code=g.product_code 
	 JOIN dim_customer c 
	 ON f.customer_code=c.customer_code 
	 WHERE c.customer='Atliq Exclusive' 
	 GROUP BY month,f.fiscal_year 
	 ORDER BY f.fiscal_year;
      
      
#  8. In which quarter of 2020, got the maximum total_sold_quantity? The final
#        output contains these fields sorted by the total_sold_quantity,
#        Quarter,total_sold_quantity
    
	WITH cte8 AS(
		SELECT 
			*,
			MONTH(date) as month FROM gdb023.fact_sales_monthly
	)
		SELECT 
		CASE 
			WHEN month IN (9,10,11) THEN 'Q1'
			WHEN month IN (12,1,2) THEN 'Q2'
			WHEN month IN (3,4,5) THEN 'Q3'
			ELSE 'Q4'
		End  AS quarter,
		SUM(sold_quantity) AS total_sold_quantity
		FROM cte8
		WHERE fiscal_year=2020
		GROUP BY quarter
	    ORDER BY total_sold_quantity DESC;
    
    
#   9. Which channel helped to bring more gross sales in the fiscal year 2021
#      and the percentage of contribution? The final output contains these fields,
#      channel,gross_sales_mln,percentage

		SET sql_mode="";

		WITH cte9 AS(
		SELECT 
			c.channel,
			SUM(f.sold_quantity*g.gross_price) AS gross_sales
		 FROM dim_customer c 
		 JOIN fact_sales_monthly f 
		 ON f.customer_code=c.customer_code 
		 JOIN fact_gross_price g 
		 ON g.product_code=f.product_code 
		 WHERE f.fiscal_year=2021 
		 GROUP BY c.channel 
		 ORDER BY gross_sales DESC
		 )

		SELECT 
			channel,
			CONCAT(ROUND(gross_sales/1000000,2),' M') AS gross_sales_mln,
			CONCAT(ROUND((gross_sales*100)/SUM(gross_sales) OVER(),2),' %') AS gross_sales_pct 
		FROM cte9;
      
#    10. Get the Top 3 products in each division that have a high 
#        total_sold_quantity in the fiscal_year 2021? The final output contains these
#        fields,division,product_code

	WITH CTE10 AS(
	   SELECT 
		  fsm.product_code,
          product,division,
          SUM(sold_quantity) AS Total_Sold_Qty
		FROM dim_product dp
		JOIN fact_sales_monthly fsm
		ON dp.product_code =fsm.product_code
		WHERE fsm.fiscal_year =2021
		GROUP BY product_code,product,division
		ORDER BY division,Total_Sold_Qty DESC
	),
	CTE10_1 AS (
		SELECT
		 CTE10.product_code,
		 CTE10.product,
		 DENSE_RANK() OVER(partition by division ORDER BY Total_Sold_Qty DESC) AS ranking
		 FROM CTE10
	)
		#SELECT *,dense_rank() over(partition by division order by Total_Sold_Qty desc) as ranking FROM CTE6 WHERE ranking<=3
		SELECT 
			CTE10.division,
            CTE10.product_code,
            CTE10.product,
            CTE10.Total_Sold_Qty,
            CTE10_1.ranking 
		FROM CTE10 
		JOIN CTE10_1 
		ON CTE10.product_Code =CTE10_1.product_code
		WHERE ranking<=3
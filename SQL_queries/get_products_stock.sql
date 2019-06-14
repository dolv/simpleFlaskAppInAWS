SELECT stores.code,
	   stock.product_id,
	   stock.store_id,
       stk.*
FROM (	   
	SELECT stores.id as store_id,
		   stores.code,
		   sub.id as product_id,
		   sub.name,
		   sub.brand,
		   sub.category,
	       stock.quantity,
		   sub.quantity as total
	FROM (	   
		SELECT
		    products.id,
		    products.name,
		    products.brand,
		    products.category,
		    SUM(CASE
		    	    WHEN stock.quantity IS NULL THEN 0
		    	    ELSE stock.quantity
		        END) as quantity
		FROM products
		LEFT JOIN stock ON stock.product_id = products.id
		GROUP BY products.id) as sub
	LEFT JOIN stock ON sub.id = stock.product_id
	LEFT JOIN stores ON stock.store_id = stores.id
	) as stk
CROSS JOIN stores, stock
WHERE stores.code = 'grover-de' ;
WITH sub as (
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
		GROUP BY products.id)
SELECT sub.name,
	   sub.brand,
	   sub.category,
	   stock.quantity,
	   CASE WHEN sub.quantity > 0 THEN 'in stock' ELSE 'out of stock' END as available
FROM sub
LEFT JOIN stock ON sub.id = stock.product_id
LEFT JOIN stores ON stock.store_id = stores.id
WHERE stores.code = 'grover-de' AND stock.quantity > 0
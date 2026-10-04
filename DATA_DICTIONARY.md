
# Data Dictionary

## customers.csv
 customer_id: Unique customer identifier
 
signup_date: Customer registration date

region: UK region

customer_segment: Consumer or Small Business


## products.csv

 product_id: Unique product identifier


  product_name: Product name
  
 
category: Product category
  
brand: Synthetic brand

unit_price: List price

cost_price: Estimated product cost


## orders.csv
 order_id: Unique order identifier
 
 customer_id: Customer who placed the order
 
order_date: Order date

 channel: Website or Mobile App
 
payment_method: Payment method

status: Completed, Cancelled or Returned

shipping_fee: Shipping charge

 order_total: Total order value
 

## order_items.csv
 order_item_id: Unique order-line identifier
 
 order_id: Related order
 
 product_id: Product purchased
 
 quantity: Units purchased
 
 unit_price: Price before discount
 
discount_pct: Discount applied

 line_total: Net line value
 

## returns.csv
 return_id: Unique return identifier
 
order_id: Returned order

 return_date: Return date
 
 reason: Return reason
 
refund_amount: Refund value


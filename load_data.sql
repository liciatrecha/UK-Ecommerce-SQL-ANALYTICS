-- Run schema.sql first.
-- Then load the CSVs using PostgreSQL's server-side COPY or psql \copy.
-- Example for psql:
-- \copy customers FROM 'data/customers.csv' CSV HEADER;
-- \copy products FROM 'data/products.csv' CSV HEADER;
-- \copy orders FROM 'data/orders.csv' CSV HEADER;
-- \copy order_items FROM 'data/order_items.csv' CSV HEADER;
-- \copy returns FROM 'data/returns.csv' CSV HEADER;

\copy customers FROM 'data/customers.csv' CSV HEADER;
\copy products FROM 'data/products.csv' CSV HEADER;
\copy orders FROM 'data/orders.csv' CSV HEADER;
\copy order_items FROM 'data/order_items.csv' CSV HEADER;
\copy returns FROM 'data/returns.csv' CSV HEADER;

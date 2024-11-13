import pandas as pd                         #for data wrangling
from sqlalchemy import create_engine, text  #for database operations

df = pd.read_excel('Orders.xlsx', sheet_name='Sheet1')

engine = create_engine("mysql+pymysql://root:1234@localhost:3307/orders")

create_table_query = """
    CREATE TABLE orders (
    order_id VARCHAR(30),
    order_info_id VARCHAR(30),
    order_id_number INT,
    return_reason VARCHAR(30),
    order_date DATETIME,
    order_weekday VARCHAR(20),
    order_month VARCHAR(20),
    ship_date DATETIME,
    ship_mode VARCHAR(30),
    product_id VARCHAR(30),
    days_to_ship INT,
    category VARCHAR(30),
    sub_category VARCHAR(30),
    product_name VARCHAR(250),
    unit_cost FLOAT(10,2),
    sales FLOAT(10,2),
    sales_volume VARCHAR(20),
    profit FLOAT(10,2),
    profit_margin FLOAT(10,2),
    quantity INT,
    discount FLOAT(10,2),
    discount_over_30 FLOAT(10,2),
    region_id INT,
    postal_code INT,
    city VARCHAR(30),
    state VARCHAR(30),
    sub_region VARCHAR(30),
    salesperson VARCHAR(30),
    customer_id VARCHAR(20),
    customer_name VARCHAR(50),
    segment VARCHAR(30)
)
"""

try:
    with engine.connect() as connection:
        print('connection successful')
        connection.execute(text(create_table_query))
        print('table created successfully')
except Exception as e:
    print(e)  
    

df.to_sql('orders', con=engine, if_exists='append', index=False)
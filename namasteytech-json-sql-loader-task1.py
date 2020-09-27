#!/usr/bin/env python
# coding: utf-8

# Import libraries
import json
import pandas as pd
import sqlalchemy
import requests
import sys
from datetime import datetime
from sqlalchemy import create_engine
from sys import exit
pd.options.mode.chained_assignment = None


# Take input from the users
print("Enter the absolute path of the `order.json file`, If left black the `order.json file` would be pick from the `NamasteTechnologies` public repo ")
json_path = input('Enter absolute path for `order.json file`: ')
db_connection_string = input('Enter the connection string for your DB: ')

# verify DB connection string
if db_connection_string == "":
    print('No DB connection string provided, exiting the script.')
    exit()
else:
    db_connection_string: db_connection_string

#load json object
if json_path != "":
    print("Using the json file from the path provided. ")
    with open(json_path) as json_file:
        d = json.load(json_file)
else:
    print("Pulling order.json from `NamasteTechnologies` public repo ")
    order_json_url = 'https://raw.githubusercontent.com/namasteTechnologies/data-analyst-challenge/master/orders.json'
    d = json.loads(requests.get(order_json_url).text)


# json data into dataframe with customer details
print('Please wait while the data is being populated...')
data = pd.json_normalize(d)
data['createddate'] = pd.to_datetime(data['created_at'])
data['datekey'] = data.createddate.apply(lambda x: x.strftime('%Y%m%d')).astype(int)
data['currencykey'] = '2'


# json data into dataframe with product details
df = pd.json_normalize(d,'line_items', ['id','total_price','created_at'],record_prefix='od_')
df['createddate'] = pd.to_datetime(df['created_at'])
df['datekey'] = df.createddate.apply(lambda x: x.strftime('%Y%m%d')).astype(int)
df['currencykey'] = '2'


# customer table - dimension
headers = ["CustomerId", "CustomerName", "CustomerEmail"]
df_customer = data [['customer.id', 'customer.name', 'customer.email']].sort_values(by=['customer.id']).drop_duplicates()
df_customer.columns = headers


# product dimension
df_product = df[['od_product_id','od_product_sku','od_product_name']].sort_values(by=['od_product_id']).drop_duplicates()
headers = ["ProductId","ProductSku","ProductName"]
df_product.columns = headers
df_product=df_product.drop_duplicates()


# Function to find exchange rate from USD to CAD to via the `exchangeratesapi.io`
def conversion(date):

    payload = {'symbols': 'CAD', 'base': 'USD'}
    url = 'https://api.exchangeratesapi.io/' + str(date).strip()
    r = requests.get(url, params=payload)
    data = r.json()
    conversion_rate = data['rates']['CAD']
    return(conversion_rate)


# dataframe to store exchange rate
df_orderdates = data[['created_at','createddate','datekey','currencykey']].sort_values(by=['created_at']).drop_duplicates()
df_orderdates['exchangedate'] = pd.to_datetime(df_orderdates['createddate']).dt.date
df_exchange = df_orderdates[['datekey','exchangedate','currencykey']]
df_exchange['exchangerate'] = df_orderdates['exchangedate'].apply(conversion)
df_exchange = df_exchange.drop_duplicates()

# dataframe to store orders
df_orders = data[['id', 'customer.id', 'total_price', 'createddate', 'datekey','currencykey']].sort_values(by=['id']).drop_duplicates()
headers = ["orderid","customerid","total_price", "orderdatetime", "datekey","currencykey"]
df_orders.columns = headers


# datatframe to store order details
df_orderdetail =  df[['od_id','id','od_product_id','od_price','datekey','currencykey' ]].sort_values(by=['id']).drop_duplicates()
headers = ["prodorderid","orderid","productid", "saleprice", "datekey","currencykey"]
df_orderdetail.columns = headers


#Create MS-SQL DB Connection. This uses the managed RDS(MSSQL) from AWS
engine = sqlalchemy.create_engine(db_connection_string)


# Insert data into customer table
df_customer.to_sql('temp_DimCustomer', con=engine, if_exists = 'replace')
connection = engine.connect()
query = "Insert into [DimCustomer] select t.CustomerID, t.CustomerName, t.CustomerEmail from temp_DimCustomer " \
        "t left join [DimCustomer] d on t.customerid = d.customerid where d.customerid is null " \
        "drop table temp_DimCustomer"
connection.execute(query)
connection.close()

# Insert data into Product table
df_product.to_sql('temp_DimProduct', con=engine, if_exists = 'replace')
connection = engine.connect()
query = "INSERT INTO [DimProduct] SELECT t.ProductID, t.ProductSku, t.ProductName FROM temp_DimProduct" \
        " t LEFT JOIN [DimProduct] p ON t.ProductID = p.ProductID  WHERE p.ProductID IS NULL  " \
        "DROP TABLE temp_DimProduct"
connection.execute(query)
connection.close()


# Insert data into Exchange Table
df_exchange.to_sql('temp_FactExchangeRate', con=engine, if_exists = 'replace', dtype = {"exchangedate": sqlalchemy.DateTime()})
connection = engine.connect()
query = "INSERT INTO [FactExchangeRate](DateKey,CurrencyKey,OrderDate,ExchangeRate) SELECT t.DateKey, \
         t.CurrencyKey, t.exchangedate,t.ExchangeRate FROM temp_FactExchangeRate t LEFT JOIN [FactExchangeRate] E \
         ON t.DateKey = E.DateKey and t.CurrencyKey = E.CurrencyKey \
         WHERE (E.CurrencyKey IS NULL OR E.DateKey IS NULL) \
         DROP TABLE temp_FactExchangeRate"
connection.execute(query)
connection.close()

# Insert data into FactOrder Table
df_orders.to_sql('temp_FactOrder', con=engine, if_exists = 'replace',dtype = {"orderdatetime": sqlalchemy.DateTime()})
connection = engine.connect()
query = "INSERT INTO [FactOrder] SELECT t.orderid, t.Customerid,t.total_price,t.orderdatetime,t.datekey,t.currencykey FROM temp_FactOrder" \
        " t LEFT JOIN [FactOrder] O ON t.orderid = O.OrderID WHERE O.OrderID IS NULL " \
        "DROP TABLE temp_FactOrder"
connection.execute(query)
connection.close()


# insert data into FactOrderDetail
df_orderdetail.to_sql('temp_FactOrderDetail', con=engine, if_exists = 'replace')
connection = engine.connect()
query = "INSERT INTO [FactOrderDetail](OrderID,ProductOrderID,ProductID,SalePrice,DateKey,CurrencyKey) " \
        "SELECT t.orderid, t.prodorderid,t.productid,t.saleprice,t.datekey,t.currencykey FROM temp_FactOrderDetail " \
        "t LEFT JOIN [FactOrderDetail] OD ON (t.orderid = OD.OrderID and t.productid = OD.productid)  WHERE OD.OrderdetailID is null DROP TABLE temp_FactOrderDetail"
connection.execute(query)
connection.close()

print('SQL population is complete. Please check the DATABASE...')

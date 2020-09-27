##JSON-SQL-LOADER

#### Python `script` to load json, extract data and populate it to the MSSQL database. This script primarily uses the following libraries:
1. [Python Pandas](https://pandas.pydata.org/): It is a very powerful data analysis library. This is used for data manipulation are creating data frames.
2. [SQLALCHEMY](https://www.sqlalchemy.org/): SQLAlchemy is the Python SQL toolkit and Object Relational Mapper that gives application developers the full power and flexibility of SQL.

#### Pre-requisites

##### MAC specific requirement(Not needed for Windows)
###### Install `unixodbc`
Learn more about [unixodbc](http://www.unixodbc.org/)
Steps:
1. `brew install unixodbc`
2. `brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release`
3. `brew update`
4. `brew install msodbcsql mssql-tools`

In case `unixodbc` is not working following these troubleshooting steps:

1. `sudo mkdir -p  /usr/local/opt/unixodbc`
2. `sudo ln -s /<path to directory>/Cellar/unixodbc/2.3.9/lib /usr/local/opt/unixodbc/lib` example `sudo ln -s /usr/local/Cellar/unixodbc/2.3.9/lib /usr/local/opt/unixodbc/lib`
3. `ls -la  /usr/local/opt/unixodbc/lib`


#### Database setup
###### 1. Using AWS MSSQL RDS
Follow these instructions to [SETUP MSSQL RDS ON AWS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ConnectToMicrosoftSQLServerInstance.html).
This would fetch you the DB connection string. This would be used by the Python script to connect to the DB.
`mssql+pyodbc://<sql-server-user-login>:<sql-server-user-password>@<DNS name for SQL server>/<Your DB Name>?driver=ODBC+Driver+17+for+SQL+Server`
Example:
`mssql+pyodbc://dummyadmin:dummypassword@namestetechdw.sample.us-east-1.rds.amazonaws.com/NamasteTechDw?driver=ODBC+Driver+17+for+SQL+Server`

###### 2. Using MSSQL on Windows
Follow these instructions to [SETUP MSSQL ON Windows](https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server?view=sql-server-ver15).
Once you have setup the SQL server. The following DB connection string can be used:
`mssql+pyodbc://<sql-server-user-login>:<sql-server-user-password>@<DNS name for SQL server>/<Your DB Name>?driver=ODBC+Driver+17+for+SQL+Server`
Example:
`mssql+pyodbc://localhost/NamasteTechDw?driver=ODBC+Driver+17+for+SQL+Server`



#### How to Execute the script
1. Clone the repo to your local system.
2. Follow the instructions on the top so that the required pre-requisites are met.
3. Install Python (this script is tested on Python version >3.7.3 ).
4. Install python dependencies `pip install -r requirements.txt`
5. Create DB schema using the `NamasteTech-DBScript-task2.sql` file.
6. Execute the python script from the CLI using the following command(`python namasteytech-json-sql-loader-task1.py`).
7. Once the script execution is complete check the DB. All the values from the `order.json` file should be populated in the DB.


#### Using Jupyter notebook
1. Ensure that you have [Jupyter](https://jupyter.org/install) installed on your machine.
2. Start the notebook from CLI by running the following command -->`jupyter notebook`
3. Enter the DB connection URL in the 4th Cell, Example for MSSQL Server Localhost, default connection:
`url_db = 'mssql+pyodbc://localhost/NamasteTechDw?driver=ODBC+Driver+17+for+SQL+Server'`




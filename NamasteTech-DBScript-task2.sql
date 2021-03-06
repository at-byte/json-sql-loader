CREATE DATABASE [NamasteTechDw]

GO

USE [NamasteTechDw]
GO
/****** Object:  Table [dbo].[DimCurrency]    Script Date: 2020-09-26 11:21:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DimCurrency](
	[CurrencyKey] [int] IDENTITY(1,1) NOT NULL,
	[CurrencyAlternateKey] [nchar](3) NOT NULL,
	[CurrencyName] [nvarchar](50) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DimCustomer]    Script Date: 2020-09-26 11:21:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DimCustomer](
	[CustomerId] [bigint] NULL,
	[CustomerName] [varchar](max) NULL,
	[CustomerEmail] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DimDate]    Script Date: 2020-09-26 11:21:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DimDate](
	[DateKey] [int] NOT NULL,
	[TheDate] [datetime] NULL,
	[TheDay] [int] NULL,
	[TheDayName] [varchar](20) NULL,
	[TheWeek] [int] NULL,
	[TheISOWeek] [int] NULL,
	[TheDayOfWeek] [int] NULL,
	[TheMonth] [int] NULL,
	[TheMonthName] [varchar](20) NULL,
	[TheQuarter] [int] NULL,
	[TheYear] [int] NULL,
	[TheFirstOfMonth] [datetime] NULL,
	[TheLastOfYear] [datetime] NULL,
	[TheDayOfYear] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[DateKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DimProduct]    Script Date: 2020-09-26 11:21:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DimProduct](
	[ProductId] [bigint] NULL,
	[ProductSku] [varchar](max) NULL,
	[ProductName] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FactExchangeRate]    Script Date: 2020-09-26 11:21:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FactExchangeRate](
	[ExchangeID] [int] IDENTITY(1,1) NOT NULL,
	[DateKey] [int] NULL,
	[CurrencyKey] [int] NULL,
	[OrderDate] [datetime] NULL,
	[ExchangeRate] [float] NULL,
PRIMARY KEY CLUSTERED 
(
	[ExchangeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FactOrder]    Script Date: 2020-09-26 11:21:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FactOrder](
	[OrderId] [bigint] NULL,
	[CustomerId] [int] NULL,
	[TotalPrice] [float] NULL,
	[OrderDateTime] [datetime] NULL,
	[DateKey] [int] NULL,
	[CurrencyKey] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FactOrderDetail]    Script Date: 2020-09-26 11:21:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FactOrderDetail](
	[OrderDetailID] [bigint] IDENTITY(1,1) NOT NULL,
	[OrderId] [bigint] NULL,
	[ProductOrderID] [int] NULL,
	[ProductID] [int] NULL,
	[SalePrice] [float] NULL,
	[DateKey] [int] NULL,
	[CurrencyKey] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[OrderDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO



Use NamasteTechDw

IF OBJECT_ID('tempdb.dbo.#temp', 'U') IS NOT NULL
  DROP TABLE #temp; 


DECLARE @StartDate  date = '20200101';

DECLARE @CutoffDate date = DATEADD(DAY, -1, DATEADD(YEAR, 1, @StartDate));

;WITH seq(n) AS 
(
  SELECT 0 UNION ALL SELECT n + 1 FROM seq
  WHERE n < DATEDIFF(DAY, @StartDate, @CutoffDate)
),
d(d) AS 
(
  SELECT DATEADD(DAY, n, @StartDate) FROM seq
),
src AS
(
  SELECT
    TheDate         = CONVERT(date, d),
    TheDay          = DATEPART(DAY,       d),
    TheDayName      = DATENAME(WEEKDAY,   d),
    TheWeek         = DATEPART(WEEK,      d),
    TheISOWeek      = DATEPART(ISO_WEEK,  d),
    TheDayOfWeek    = DATEPART(WEEKDAY,   d),
    TheMonth        = DATEPART(MONTH,     d),
    TheMonthName    = DATENAME(MONTH,     d),
    TheQuarter      = DATEPART(Quarter,   d),
    TheYear         = DATEPART(YEAR,      d),
    TheFirstOfMonth = DATEFROMPARTS(YEAR(d), MONTH(d), 1),
    TheLastOfYear   = DATEFROMPARTS(YEAR(d), 12, 31),
    TheDayOfYear    = DATEPART(DAYOFYEAR, d)
  FROM d
)
SELECT * into #temp FROM src
  ORDER BY TheDate
  OPTION (MAXRECURSION 0);

  if  exists (select 1 from sysobjects where name='dimdate' and xtype='U')
	BEGIN 
	INSERT INTO DimDate

	SELECT CONVERT(INT, CONVERT(VARCHAR(8), t.TheDate, 112)) as DateKey,t.* from #temp t left join dimdate d
	on CONVERT(INT, CONVERT(VARCHAR(8), t.TheDate, 112)) = d.DateKey
	WHERE d.DateKey is null
	END



	drop table #temp



IF EXISTS (select 1 from sysobjects where name='DimCurrency' and xtype='U')
BEGIN
IF NOT EXISTS( SELECT 1 FROM [DimCurrency] where [CurrencyAlternateKey] in ('CAD'))
	BEGIN
	INSERT INTO [DimCurrency] ([CurrencyAlternateKey],[CurrencyName])
	VALUES ('USD', 'US DOLLAR'),
		('CAD', 'CANADIAN DOLLAR')
	END
END
GO


USE CableTV_DWH;
GO

DROP TABLE IF EXISTS dbo.FactMovieSales;      
DROP TABLE IF EXISTS dbo.FactFinancials;      
DROP TABLE IF EXISTS dbo.FactMovieOperations; 
DROP TABLE IF EXISTS dbo.FactSubscriptions;   

DROP TABLE IF EXISTS dbo.DimSubscriber;
DROP TABLE IF EXISTS dbo.DimMovie;
DROP TABLE IF EXISTS dbo.DimChannelGroup;
DROP TABLE IF EXISTS dbo.DimPaymentMethod;
DROP TABLE IF EXISTS dbo.DimDate;
GO

CREATE TABLE dbo.DimDate (
    DateKey INT PRIMARY KEY,           
    FullDate DATE NOT NULL,
    Year INT NOT NULL,
    Month INT NOT NULL,
    MonthName NVARCHAR(20) NOT NULL,
    Quarter INT NOT NULL,
    DayOfWeek INT NOT NULL,
    DayName NVARCHAR(20) NOT NULL,
    IsWeekend BIT NOT NULL
);

-- 2. DimSubscriber
CREATE TABLE dbo.DimSubscriber (
    SubscriberKey INT IDENTITY(1,1) PRIMARY KEY,
    SubscriberID_Source INT NOT NULL,
    FullName NVARCHAR(150) NOT NULL,
    City NVARCHAR(60) NOT NULL,
    AgeGroup NVARCHAR(20) NULL,
    CurrentStatus NVARCHAR(30) NOT NULL
);

CREATE TABLE dbo.DimMovie (
    MovieKey INT IDENTITY(1,1) PRIMARY KEY,
    MovieID_Source INT NOT NULL,
    MovieTitle NVARCHAR(200) NOT NULL,
    ReleaseYear INT NOT NULL,
    GenreName NVARCHAR(50) NOT NULL,
    AgeRating NVARCHAR(10) NULL
);

CREATE TABLE dbo.DimChannelGroup (
    ChannelGroupKey INT IDENTITY(1,1) PRIMARY KEY,
    ChannelGroupID_Source INT NOT NULL,
    GroupName NVARCHAR(100) NOT NULL,
    MonthlyFee DECIMAL(10,2) NOT NULL
);

CREATE TABLE dbo.DimPaymentMethod (
    PaymentMethodKey INT IDENTITY(1,1) PRIMARY KEY,
    PaymentMethodID_Source TINYINT NOT NULL,
    MethodName NVARCHAR(30) NOT NULL
);

CREATE TABLE dbo.FactMovieOperations (
    FactKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    DateKey INT NOT NULL CONSTRAINT FK_FactMovie_Date REFERENCES dbo.DimDate(DateKey),
    SubscriberKey INT NOT NULL CONSTRAINT FK_FactMovie_Sub REFERENCES dbo.DimSubscriber(SubscriberKey),
    MovieKey INT NOT NULL CONSTRAINT FK_FactMovie_Movie REFERENCES dbo.DimMovie(MovieKey),
    PricePaid DECIMAL(10,2) NOT NULL,
    OrderCount INT DEFAULT 1
);

CREATE TABLE dbo.FactFinancials (
    FactKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    DateKey INT NOT NULL CONSTRAINT FK_FactFin_Date REFERENCES dbo.DimDate(DateKey),
    SubscriberKey INT NOT NULL CONSTRAINT FK_FactFin_Sub REFERENCES dbo.DimSubscriber(SubscriberKey),
    PaymentMethodKey INT NOT NULL CONSTRAINT FK_FactFin_Method REFERENCES dbo.DimPaymentMethod(PaymentMethodKey),
    Amount DECIMAL(12,2) NOT NULL,
    TransactionCount INT DEFAULT 1
);
GO
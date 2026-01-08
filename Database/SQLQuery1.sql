/* 0) DATABASE */
IF DB_ID(N'CableTV') IS NULL
BEGIN
    CREATE DATABASE CableTV;
END
GO
USE CableTV;
GO

/* 1) SCHEMAS */
IF SCHEMA_ID('ref') IS NULL EXEC('CREATE SCHEMA ref');
GO

/* 2) REFERENCE TABLES */
CREATE TABLE ref.SubscriberStatus (
    SubscriberStatusID tinyint IDENTITY(1,1) CONSTRAINT PK_SubscriberStatus PRIMARY KEY,
    StatusName nvarchar(30) NOT NULL CONSTRAINT UQ_SubscriberStatus UNIQUE
);

CREATE TABLE ref.PaymentMethod (
    PaymentMethodID tinyint IDENTITY(1,1) CONSTRAINT PK_PaymentMethod PRIMARY KEY,
    MethodName nvarchar(30) NOT NULL CONSTRAINT UQ_PaymentMethod UNIQUE
);

CREATE TABLE ref.Genre (
    GenreID smallint IDENTITY(1,1) CONSTRAINT PK_Genre PRIMARY KEY,
    GenreName nvarchar(50) NOT NULL CONSTRAINT UQ_Genre UNIQUE
);

CREATE TABLE ref.ChannelCategory (
    ChannelCategoryID smallint IDENTITY(1,1) CONSTRAINT PK_ChannelCategory PRIMARY KEY,
    CategoryName nvarchar(50) NOT NULL CONSTRAINT UQ_ChannelCategory UNIQUE
);

CREATE TABLE ref.InvoiceStatus (
    InvoiceStatusID tinyint IDENTITY(1,1) CONSTRAINT PK_InvoiceStatus PRIMARY KEY,
    StatusName nvarchar(30) NOT NULL CONSTRAINT UQ_InvoiceStatus UNIQUE
);
GO

/* 3) CORE ENTITIES */
CREATE TABLE dbo.Subscriber (
    SubscriberID int IDENTITY(1,1) CONSTRAINT PK_Subscriber PRIMARY KEY,
    ExternalContractNo nvarchar(20) NOT NULL CONSTRAINT UQ_Subscriber_Contract UNIQUE,
    FirstName nvarchar(50) NOT NULL,
    LastName nvarchar(50) NOT NULL,
    Phone nvarchar(20) NOT NULL,
    Email nvarchar(120) NULL,
    BirthDate date NULL,
    City nvarchar(60) NOT NULL,
    Street nvarchar(100) NOT NULL,
    HouseNo nvarchar(10) NOT NULL,
    ApartmentNo nvarchar(10) NULL,
    CreatedAt date NOT NULL,
    ClosedAt date NULL,
    SubscriberStatusID tinyint NOT NULL,
    CONSTRAINT FK_Subscriber_Status FOREIGN KEY (SubscriberStatusID)
        REFERENCES ref.SubscriberStatus(SubscriberStatusID),
    CONSTRAINT CK_Subscriber_Dates CHECK (CreatedAt <= '2025-12-31' AND (ClosedAt IS NULL OR ClosedAt <= '2025-12-31') AND (ClosedAt IS NULL OR ClosedAt >= CreatedAt)),
    CONSTRAINT CK_Subscriber_BirthDate CHECK (BirthDate IS NULL OR (BirthDate >= '1930-01-01' AND BirthDate <= '2007-12-31'))
);

CREATE TABLE dbo.Channel (
    ChannelID int IDENTITY(1,1) CONSTRAINT PK_Channel PRIMARY KEY,
    ChannelName nvarchar(100) NOT NULL CONSTRAINT UQ_Channel_Name UNIQUE,
    ChannelCategoryID smallint NOT NULL,
    IsHD bit NOT NULL,
    IsActive bit NOT NULL,
    CONSTRAINT FK_Channel_Category FOREIGN KEY (ChannelCategoryID)
        REFERENCES ref.ChannelCategory(ChannelCategoryID)
);

CREATE TABLE dbo.ChannelGroup (
    ChannelGroupID int IDENTITY(1,1) CONSTRAINT PK_ChannelGroup PRIMARY KEY,
    GroupName nvarchar(100) NOT NULL CONSTRAINT UQ_ChannelGroup_Name UNIQUE,
    MonthlyFee decimal(10,2) NOT NULL,
    IsActive bit NOT NULL,
    CONSTRAINT CK_ChannelGroup_Fee CHECK (MonthlyFee >= 0)
);

CREATE TABLE dbo.ChannelGroupChannel (
    ChannelGroupID int NOT NULL,
    ChannelID int NOT NULL,
    CONSTRAINT PK_ChannelGroupChannel PRIMARY KEY (ChannelGroupID, ChannelID),
    CONSTRAINT FK_CGChannel_Group FOREIGN KEY (ChannelGroupID) REFERENCES dbo.ChannelGroup(ChannelGroupID),
    CONSTRAINT FK_CGChannel_Channel FOREIGN KEY (ChannelID) REFERENCES dbo.Channel(ChannelID)
);

CREATE TABLE dbo.SubscriberChannelGroup (
    SubscriberChannelGroupID bigint IDENTITY(1,1) CONSTRAINT PK_SubscriberChannelGroup PRIMARY KEY,
    SubscriberID int NOT NULL,
    ChannelGroupID int NOT NULL,
    StartDate date NOT NULL,
    EndDate date NULL,
    CONSTRAINT FK_SubCG_Subscriber FOREIGN KEY (SubscriberID) REFERENCES dbo.Subscriber(SubscriberID),
    CONSTRAINT FK_SubCG_Group FOREIGN KEY (ChannelGroupID) REFERENCES dbo.ChannelGroup(ChannelGroupID),
    CONSTRAINT CK_SubCG_Dates CHECK (StartDate <= '2025-12-31' AND (EndDate IS NULL OR (EndDate <= '2025-12-31' AND EndDate >= StartDate)))
);
GO

/* 4) MOVIES + ORDERS */
CREATE TABLE dbo.Movie (
    MovieID int IDENTITY(1,1) CONSTRAINT PK_Movie PRIMARY KEY,
    MovieTitle nvarchar(200) NOT NULL,
    ReleaseYear smallint NOT NULL,
    DurationMin smallint NOT NULL,
    BasePrice decimal(10,2) NOT NULL,
    AgeRating nvarchar(10) NULL,
    CONSTRAINT CK_Movie_Year CHECK (ReleaseYear BETWEEN 1950 AND 2025),
    CONSTRAINT CK_Movie_Duration CHECK (DurationMin BETWEEN 30 AND 300),
    CONSTRAINT CK_Movie_Price CHECK (BasePrice >= 0)
);

CREATE TABLE dbo.MovieGenre (
    MovieID int NOT NULL,
    GenreID smallint NOT NULL,
    CONSTRAINT PK_MovieGenre PRIMARY KEY (MovieID, GenreID),
    CONSTRAINT FK_MovieGenre_Movie FOREIGN KEY (MovieID) REFERENCES dbo.Movie(MovieID),
    CONSTRAINT FK_MovieGenre_Genre FOREIGN KEY (GenreID) REFERENCES ref.Genre(GenreID)
);

CREATE TABLE dbo.MovieOrder (
    MovieOrderID bigint IDENTITY(1,1) CONSTRAINT PK_MovieOrder PRIMARY KEY,
    SubscriberID int NOT NULL,
    MovieID int NOT NULL,
    OrderDateTime datetime2(0) NOT NULL,
    PricePaid decimal(10,2) NOT NULL,
    CONSTRAINT FK_Order_Subscriber FOREIGN KEY (SubscriberID) REFERENCES dbo.Subscriber(SubscriberID),
    CONSTRAINT FK_Order_Movie FOREIGN KEY (MovieID) REFERENCES dbo.Movie(MovieID),
    CONSTRAINT CK_Order_Date CHECK (OrderDateTime >= '2021-01-01' AND OrderDateTime < '2026-01-01'),
    CONSTRAINT CK_Order_Price CHECK (PricePaid >= 0)
);
GO

/* 5) INVOICES + PAYMENTS */
CREATE TABLE dbo.Invoice (
    InvoiceID bigint IDENTITY(1,1) CONSTRAINT PK_Invoice PRIMARY KEY,
    SubscriberID int NOT NULL,
    InvoiceMonth date NOT NULL, -- store first day of month
    IssuedAt date NOT NULL,
    DueDate date NOT NULL,
    InvoiceStatusID tinyint NOT NULL,
    TotalAmount decimal(12,2) NOT NULL DEFAULT(0),
    CONSTRAINT FK_Invoice_Subscriber FOREIGN KEY (SubscriberID) REFERENCES dbo.Subscriber(SubscriberID),
    CONSTRAINT FK_Invoice_Status FOREIGN KEY (InvoiceStatusID) REFERENCES ref.InvoiceStatus(InvoiceStatusID),
    CONSTRAINT CK_Invoice_Dates CHECK (InvoiceMonth >= '2021-01-01' AND InvoiceMonth <= '2025-12-01' AND IssuedAt <= '2025-12-31' AND DueDate <= '2025-12-31' AND DueDate >= IssuedAt),
    CONSTRAINT CK_Invoice_Total CHECK (TotalAmount >= 0)
);

CREATE TABLE dbo.InvoiceLine (
    InvoiceLineID bigint IDENTITY(1,1) CONSTRAINT PK_InvoiceLine PRIMARY KEY,
    InvoiceID bigint NOT NULL,
    LineType nvarchar(30) NOT NULL,  -- 'SubscriptionFee' | 'Movie' | 'Discount' | 'Penalty' etc
    SourceID bigint NULL,            -- optional: link to SubscriberChannelGroupID / MovieOrderID etc
    Description nvarchar(200) NOT NULL,
    Amount decimal(12,2) NOT NULL,
    CONSTRAINT FK_InvoiceLine_Invoice FOREIGN KEY (InvoiceID) REFERENCES dbo.Invoice(InvoiceID),
    CONSTRAINT CK_InvoiceLine_Amount CHECK (Amount <> 0)
);

CREATE TABLE dbo.Payment (
    PaymentID bigint IDENTITY(1,1) CONSTRAINT PK_Payment PRIMARY KEY,
    InvoiceID bigint NOT NULL,
    PaymentDateTime datetime2(0) NOT NULL,
    Amount decimal(12,2) NOT NULL,
    PaymentMethodID tinyint NOT NULL,
    CONSTRAINT FK_Payment_Invoice FOREIGN KEY (InvoiceID) REFERENCES dbo.Invoice(InvoiceID),
    CONSTRAINT FK_Payment_Method FOREIGN KEY (PaymentMethodID) REFERENCES ref.PaymentMethod(PaymentMethodID),
    CONSTRAINT CK_Payment_Date CHECK (PaymentDateTime >= '2021-01-01' AND PaymentDateTime < '2026-01-01'),
    CONSTRAINT CK_Payment_Amount CHECK (Amount > 0)
);
GO

/* 6) INDEXES (минимальный набор под отчеты/ETL) */
CREATE INDEX IX_Order_Date ON dbo.MovieOrder(OrderDateTime) INCLUDE (MovieID, SubscriberID, PricePaid);
CREATE INDEX IX_Order_Movie ON dbo.MovieOrder(MovieID) INCLUDE (OrderDateTime, PricePaid, SubscriberID);

CREATE INDEX IX_SubCG_Subscriber ON dbo.SubscriberChannelGroup(SubscriberID, StartDate) INCLUDE (ChannelGroupID, EndDate);
CREATE INDEX IX_SubCG_Group ON dbo.SubscriberChannelGroup(ChannelGroupID, StartDate) INCLUDE (SubscriberID, EndDate);

CREATE INDEX IX_Invoice_Month ON dbo.Invoice(InvoiceMonth) INCLUDE (SubscriberID, TotalAmount, InvoiceStatusID);
CREATE INDEX IX_Payment_Invoice ON dbo.Payment(InvoiceID) INCLUDE (PaymentDateTime, Amount);
GO

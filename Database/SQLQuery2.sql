USE CableTV;
GO

/* =========================
   A) STRUCTURE CHECKS
   ========================= */

-- A1: tables exist
SELECT s.name AS [schema], t.name AS [table]
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE (s.name='dbo' AND t.name IN ('Subscriber','Channel','ChannelGroup','ChannelGroupChannel','SubscriberChannelGroup',
                                  'Movie','MovieGenre','MovieOrder','Invoice','InvoiceLine','Payment'))
   OR (s.name='ref' AND t.name IN ('SubscriberStatus','PaymentMethod','Genre','ChannelCategory','InvoiceStatus'))
ORDER BY s.name, t.name;

-- A2: primary keys exist
SELECT
  OBJECT_SCHEMA_NAME(i.object_id) AS [schema],
  OBJECT_NAME(i.object_id) AS [table],
  i.name AS pk_name
FROM sys.indexes i
WHERE i.is_primary_key = 1
  AND OBJECT_SCHEMA_NAME(i.object_id) IN ('dbo','ref')
ORDER BY [schema],[table];

-- A3: foreign keys exist (quick view)
SELECT
  OBJECT_SCHEMA_NAME(fk.parent_object_id) AS [schema],
  OBJECT_NAME(fk.parent_object_id) AS [table],
  fk.name AS fk_name,
  OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS ref_schema,
  OBJECT_NAME(fk.referenced_object_id) AS ref_table
FROM sys.foreign_keys fk
WHERE OBJECT_SCHEMA_NAME(fk.parent_object_id) IN ('dbo','ref')
ORDER BY [schema],[table], fk.name;

-- A4: required indexes exist (we created 5)
SELECT
  OBJECT_SCHEMA_NAME(i.object_id) AS [schema],
  OBJECT_NAME(i.object_id) AS [table],
  i.name AS index_name
FROM sys.indexes i
WHERE i.name IN ('IX_Order_Date','IX_Order_Movie','IX_SubCG_Subscriber','IX_SubCG_Group','IX_Invoice_Month','IX_Payment_Invoice')
ORDER BY [schema],[table], index_name;



/* =========================
   B) REFERENCE DATA (idempotent)
   ========================= */

-- Subscriber statuses
IF NOT EXISTS (SELECT 1 FROM ref.SubscriberStatus WHERE StatusName='Active')
    INSERT INTO ref.SubscriberStatus(StatusName) VALUES ('Active'),('Suspended'),('Closed');

-- Payment methods
IF NOT EXISTS (SELECT 1 FROM ref.PaymentMethod WHERE MethodName='Card')
    INSERT INTO ref.PaymentMethod(MethodName) VALUES ('Card'),('BankTransfer'),('Cash');

-- Invoice statuses
IF NOT EXISTS (SELECT 1 FROM ref.InvoiceStatus WHERE StatusName='Open')
    INSERT INTO ref.InvoiceStatus(StatusName) VALUES ('Open'),('Paid'),('Overdue'),('Void');

-- Channel categories
IF NOT EXISTS (SELECT 1 FROM ref.ChannelCategory WHERE CategoryName='Movies')
    INSERT INTO ref.ChannelCategory(CategoryName) VALUES ('News'),('Sport'),('Kids'),('Movies'),('Music');

-- Genres
IF NOT EXISTS (SELECT 1 FROM ref.Genre WHERE GenreName='Drama')
    INSERT INTO ref.Genre(GenreName) VALUES ('Drama'),('Comedy'),('Action');



/* =========================
   C) INSERT SMALL TEST DATA
   ========================= */

DECLARE @ActiveStatus tinyint = (SELECT TOP 1 SubscriberStatusID FROM ref.SubscriberStatus WHERE StatusName='Active');
DECLARE @CardMethod tinyint   = (SELECT TOP 1 PaymentMethodID FROM ref.PaymentMethod WHERE MethodName='Card');
DECLARE @InvOpen tinyint      = (SELECT TOP 1 InvoiceStatusID FROM ref.InvoiceStatus WHERE StatusName='Open');
DECLARE @CatMovies smallint   = (SELECT TOP 1 ChannelCategoryID FROM ref.ChannelCategory WHERE CategoryName='Movies');
DECLARE @GenreDrama smallint  = (SELECT TOP 1 GenreID FROM ref.Genre WHERE GenreName='Drama');

-- C1: Subscriber
IF NOT EXISTS (SELECT 1 FROM dbo.Subscriber WHERE ExternalContractNo='TST-000001')
BEGIN
    INSERT INTO dbo.Subscriber
    (ExternalContractNo, FirstName, LastName, Phone, Email, BirthDate, City, Street, HouseNo, ApartmentNo, CreatedAt, ClosedAt, SubscriberStatusID)
    VALUES
    ('TST-000001', N'Іван', N'Петренко', N'+380631112233', N'ivan.test@mail.com', '1999-05-20',
     N'Львів', N'Шевченка', N'10', N'15', '2023-02-10', NULL, @ActiveStatus);
END

DECLARE @SubscriberID int = (SELECT SubscriberID FROM dbo.Subscriber WHERE ExternalContractNo='TST-000001');

-- C2: ChannelGroup + Channel + link
IF NOT EXISTS (SELECT 1 FROM dbo.ChannelGroup WHERE GroupName=N'Базовий пакет (TEST)')
BEGIN
    INSERT INTO dbo.ChannelGroup(GroupName, MonthlyFee, IsActive)
    VALUES (N'Базовий пакет (TEST)', 199.00, 1);
END
DECLARE @GroupID int = (SELECT ChannelGroupID FROM dbo.ChannelGroup WHERE GroupName=N'Базовий пакет (TEST)');

IF NOT EXISTS (SELECT 1 FROM dbo.Channel WHERE ChannelName=N'КіноПлюс (TEST)')
BEGIN
    INSERT INTO dbo.Channel(ChannelName, ChannelCategoryID, IsHD, IsActive)
    VALUES (N'КіноПлюс (TEST)', @CatMovies, 1, 1);
END
DECLARE @ChannelID int = (SELECT ChannelID FROM dbo.Channel WHERE ChannelName=N'КіноПлюс (TEST)');

IF NOT EXISTS (SELECT 1 FROM dbo.ChannelGroupChannel WHERE ChannelGroupID=@GroupID AND ChannelID=@ChannelID)
BEGIN
    INSERT INTO dbo.ChannelGroupChannel(ChannelGroupID, ChannelID)
    VALUES (@GroupID, @ChannelID);
END

-- C3: Subscription history
IF NOT EXISTS (
    SELECT 1 FROM dbo.SubscriberChannelGroup
    WHERE SubscriberID=@SubscriberID AND ChannelGroupID=@GroupID AND StartDate='2024-01-01'
)
BEGIN
    INSERT INTO dbo.SubscriberChannelGroup(SubscriberID, ChannelGroupID, StartDate, EndDate)
    VALUES (@SubscriberID, @GroupID, '2024-01-01', NULL);
END

-- C4: Movie + genre
IF NOT EXISTS (SELECT 1 FROM dbo.Movie WHERE MovieTitle=N'Test Movie (2024)')
BEGIN
    INSERT INTO dbo.Movie(MovieTitle, ReleaseYear, DurationMin, BasePrice, AgeRating)
    VALUES (N'Test Movie (2024)', 2024, 110, 79.00, '16+');
END
DECLARE @MovieID int = (SELECT MovieID FROM dbo.Movie WHERE MovieTitle=N'Test Movie (2024)');

IF NOT EXISTS (SELECT 1 FROM dbo.MovieGenre WHERE MovieID=@MovieID AND GenreID=@GenreDrama)
BEGIN
    INSERT INTO dbo.MovieGenre(MovieID, GenreID) VALUES (@MovieID, @GenreDrama);
END

-- C5: Movie order
DECLARE @OrderID bigint;
IF NOT EXISTS (
    SELECT 1 FROM dbo.MovieOrder
    WHERE SubscriberID=@SubscriberID AND MovieID=@MovieID AND OrderDateTime='2024-01-10 20:15:00'
)
BEGIN
    INSERT INTO dbo.MovieOrder(SubscriberID, MovieID, OrderDateTime, PricePaid)
    VALUES (@SubscriberID, @MovieID, '2024-01-10 20:15:00', 79.00);
END
SELECT @OrderID = MovieOrderID
FROM dbo.MovieOrder
WHERE SubscriberID=@SubscriberID AND MovieID=@MovieID AND OrderDateTime='2024-01-10 20:15:00';

-- C6: Invoice (January 2024)
DECLARE @InvoiceID bigint;
IF NOT EXISTS (
    SELECT 1 FROM dbo.Invoice WHERE SubscriberID=@SubscriberID AND InvoiceMonth='2024-01-01'
)
BEGIN
    INSERT INTO dbo.Invoice(SubscriberID, InvoiceMonth, IssuedAt, DueDate, InvoiceStatusID, TotalAmount)
    VALUES (@SubscriberID, '2024-01-01', '2024-01-02', '2024-01-15', @InvOpen, 0);
END
SELECT @InvoiceID = InvoiceID
FROM dbo.Invoice
WHERE SubscriberID=@SubscriberID AND InvoiceMonth='2024-01-01';

-- C7: Invoice lines (subscription + movie)
IF NOT EXISTS (SELECT 1 FROM dbo.InvoiceLine WHERE InvoiceID=@InvoiceID AND LineType='SubscriptionFee')
BEGIN
    INSERT INTO dbo.InvoiceLine(InvoiceID, LineType, SourceID, Description, Amount)
    VALUES (@InvoiceID, 'SubscriptionFee', NULL, N'Абонплата: Базовий пакет (TEST)', 199.00);
END

IF NOT EXISTS (SELECT 1 FROM dbo.InvoiceLine WHERE InvoiceID=@InvoiceID AND LineType='Movie' AND SourceID=@OrderID)
BEGIN
    INSERT INTO dbo.InvoiceLine(InvoiceID, LineType, SourceID, Description, Amount)
    VALUES (@InvoiceID, 'Movie', @OrderID, N'VOD: Test Movie (2024)', 79.00);
END

-- Recalculate invoice total
UPDATE i
SET TotalAmount = x.SumAmount
FROM dbo.Invoice i
CROSS APPLY (
    SELECT SUM(il.Amount) AS SumAmount
    FROM dbo.InvoiceLine il
    WHERE il.InvoiceID = i.InvoiceID
) x
WHERE i.InvoiceID = @InvoiceID;

-- C8: Payment (partial)
IF NOT EXISTS (
    SELECT 1 FROM dbo.Payment WHERE InvoiceID=@InvoiceID AND PaymentDateTime='2024-01-05 12:00:00'
)
BEGIN
    INSERT INTO dbo.Payment(InvoiceID, PaymentDateTime, Amount, PaymentMethodID)
    VALUES (@InvoiceID, '2024-01-05 12:00:00', 150.00, @CardMethod);
END



/* =========================
   D) VALIDATION SELECTS
   ========================= */

-- D1: subscriber + active subscriptions
SELECT TOP 20
  s.SubscriberID, s.ExternalContractNo, s.LastName, s.FirstName,
  scg.StartDate, scg.EndDate, cg.GroupName, cg.MonthlyFee
FROM dbo.Subscriber s
JOIN dbo.SubscriberChannelGroup scg ON scg.SubscriberID = s.SubscriberID
JOIN dbo.ChannelGroup cg ON cg.ChannelGroupID = scg.ChannelGroupID
WHERE s.ExternalContractNo='TST-000001'
ORDER BY scg.StartDate DESC;

-- D2: orders + movie
SELECT TOP 20
  mo.MovieOrderID, mo.OrderDateTime, mo.PricePaid,
  m.MovieTitle, m.ReleaseYear
FROM dbo.MovieOrder mo
JOIN dbo.Movie m ON m.MovieID = mo.MovieID
WHERE mo.SubscriberID = @SubscriberID
ORDER BY mo.OrderDateTime DESC;

-- D3: invoice balance (начислено/оплачено/остаток)
SELECT
  i.InvoiceID, i.InvoiceMonth, i.TotalAmount AS Charged,
  ISNULL(p.Paid,0) AS Paid,
  i.TotalAmount - ISNULL(p.Paid,0) AS Balance
FROM dbo.Invoice i
OUTER APPLY (
    SELECT SUM(Amount) AS Paid
    FROM dbo.Payment
    WHERE InvoiceID = i.InvoiceID
) p
WHERE i.InvoiceID = @InvoiceID;

-- D4: invoice lines detail
SELECT
  il.InvoiceLineID, il.LineType, il.SourceID, il.Description, il.Amount
FROM dbo.InvoiceLine il
WHERE il.InvoiceID = @InvoiceID
ORDER BY il.InvoiceLineID;
GO

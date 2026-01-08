USE CableTV;
GO

CREATE OR ALTER TRIGGER dbo.trg_SubCG_NoOverlaps
ON dbo.SubscriberChannelGroup
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM dbo.SubscriberChannelGroup a
        JOIN dbo.SubscriberChannelGroup b
          ON a.SubscriberID = b.SubscriberID
         AND a.ChannelGroupID = b.ChannelGroupID
         AND a.SubscriberChannelGroupID <> b.SubscriberChannelGroupID
        JOIN inserted i
          ON i.SubscriberID = a.SubscriberID
         AND i.ChannelGroupID = a.ChannelGroupID
        WHERE
          a.StartDate <= ISNULL(b.EndDate, '9999-12-31')
          AND b.StartDate <= ISNULL(a.EndDate, '9999-12-31')
    )
    BEGIN
        RAISERROR(N'Error. You cannot have two subscriptions to the same package with overlapping dates for one subscriber.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

CREATE OR ALTER TRIGGER dbo.trg_Invoice_RecalcTotal
ON dbo.InvoiceLine
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Changed AS (
        SELECT InvoiceID FROM inserted
        UNION
        SELECT InvoiceID FROM deleted
    )
    UPDATE i
    SET TotalAmount = ISNULL(x.SumAmount, 0)
    FROM dbo.Invoice i
    JOIN Changed c ON c.InvoiceID = i.InvoiceID
    OUTER APPLY (
        SELECT SUM(il.Amount) AS SumAmount
        FROM dbo.InvoiceLine il
        WHERE il.InvoiceID = i.InvoiceID
    ) x;
END
GO

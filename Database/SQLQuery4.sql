DECLARE @sub int = (SELECT SubscriberID FROM dbo.Subscriber WHERE ExternalContractNo='TST-000001');
DECLARE @grp int = (SELECT ChannelGroupID FROM dbo.ChannelGroup WHERE GroupName=N'Базовий пакет (TEST)');

BEGIN TRY
    INSERT INTO dbo.SubscriberChannelGroup(SubscriberID, ChannelGroupID, StartDate, EndDate)
    VALUES (@sub, @grp, '2024-02-01', NULL);  
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS TriggerBlockedAsExpected;
END CATCH;

DECLARE @inv bigint = (SELECT InvoiceID FROM dbo.Invoice WHERE SubscriberID=@sub AND InvoiceMonth='2024-01-01');
INSERT INTO dbo.InvoiceLine(InvoiceID, LineType, SourceID, Description, Amount)
VALUES (@inv, 'Discount', NULL, N'Знижка (TEST)', -20.00);

SELECT InvoiceID, TotalAmount FROM dbo.Invoice WHERE InvoiceID=@inv; -- должно стать 258.00

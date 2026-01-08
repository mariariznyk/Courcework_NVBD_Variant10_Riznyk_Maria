USE CableTV;
GO

SELECT
  (SELECT COUNT(*) FROM dbo.Invoice)    AS InvoiceCnt,
  (SELECT COUNT(*) FROM dbo.Payment)    AS PaymentCnt,
  (SELECT COUNT(*) FROM dbo.InvoiceLine) AS InvoiceLineCnt,
  (SELECT COUNT(*) FROM dbo.MovieOrder) AS OrderCnt,
  (SELECT COUNT(*) FROM dbo.Subscriber) AS SubscriberCnt;
GO

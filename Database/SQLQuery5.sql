USE CableTV;
GO

DELETE FROM dbo.ChannelGroupChannel;
DELETE FROM dbo.SubscriberChannelGroup;
DELETE FROM dbo.MovieGenre;
DELETE FROM dbo.MovieOrder;
DELETE FROM dbo.InvoiceLine;
DELETE FROM dbo.Payment;
DELETE FROM dbo.Invoice;
DELETE FROM dbo.Channel;
DELETE FROM dbo.Movie;
DELETE FROM dbo.Subscriber;
DELETE FROM dbo.ChannelGroup;

DELETE FROM ref.ChannelCategory;
DELETE FROM ref.Genre;
DELETE FROM ref.InvoiceStatus;
DELETE FROM ref.PaymentMethod;
DELETE FROM ref.SubscriberStatus;
GO

SELECT 'Movie Orders (Fact)' AS Category, COUNT(*) AS Records FROM dbo.MovieOrder
UNION ALL
SELECT 'Invoices (Fact)', COUNT(*) FROM dbo.Invoice
UNION ALL
SELECT 'Payments (Fact)', COUNT(*) FROM dbo.Payment
UNION ALL
SELECT 'Subscribers (Dim)', COUNT(*) FROM dbo.Subscriber
UNION ALL
SELECT 'Movies (Dim)', COUNT(*) FROM dbo.Movie;
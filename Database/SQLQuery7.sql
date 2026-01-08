USE CableTV;
GO
SELECT
    con.name,
    con.definition
FROM sys.check_constraints con
WHERE con.parent_object_id = OBJECT_ID('dbo.Subscriber')
  AND con.name = 'CK_Subscriber_Dates';
GO

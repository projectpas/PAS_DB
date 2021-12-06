
CREATE VIEW [dbo].[vw_TeardownReason]
AS
SELECT TR.*,TT.Name AS TeardownType FROM TeardownReason TR
JOIN TeardownType TT ON TR.TeardownTypeId=TT.TeardownTypeId
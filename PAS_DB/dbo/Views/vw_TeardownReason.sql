

CREATE VIEW [dbo].[vw_TeardownReason]
AS
SELECT TR.*,TT.Name AS TeardownType FROM TeardownReason TR
JOIN CommonTeardownType TT ON TR.CommonTeardownTypeId=TT.CommonTeardownTypeId
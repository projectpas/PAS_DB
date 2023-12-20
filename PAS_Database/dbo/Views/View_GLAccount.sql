

CREATE VIEW [dbo].[View_GLAccount]
AS
SELECT AccountCode + ' - ' + AccountName AS AccountName, GLAccountId, MasterCompanyId, IsActive, IsDeleted
FROM     dbo.GLAccount
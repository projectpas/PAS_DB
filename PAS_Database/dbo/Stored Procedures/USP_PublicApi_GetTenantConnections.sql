
---------------------------------------------------------------------------------------------
-- 6.2 Companies with their own database (same source as PAS TenantProvider).
--     Companies without a connection string use the default database.
---------------------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetTenantConnections]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [MasterCompanyId], [ConnectionString]
    FROM [dbo].[MasterCompany] WITH (NOLOCK)
    WHERE ISNULL([ConnectionString], '') <> '';
END
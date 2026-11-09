
/*************************************************************
 ** File:   [USP_PublicApi_GetTenantConnections]
 ** Author: Moin Bloch
 ** Description: 6.2 Companies with their own database (same source as PAS TenantProvider).
 **                  Companies without a connection string use the default database.
 ** Purpose: PAS_PUBLIC_API - tenant database per company
 ** Date:   09/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_GetTenantConnections]
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetTenantConnections]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [MasterCompanyId], [ConnectionString]
    FROM [dbo].[MasterCompany] WITH (NOLOCK)
    WHERE ISNULL([ConnectionString], '') <> '';
END
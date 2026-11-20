
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
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

  EXEC [dbo].[USP_PublicApi_GetTenantConnections]
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetTenantConnections]
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT [MasterCompanyId], [ConnectionString]
        FROM [dbo].[MasterCompany] WITH (NOLOCK)
        WHERE ISNULL([ConnectionString], '') <> '';
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetTenantConnections'
              , @ProcedureParameters VARCHAR(3000) = ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH
END
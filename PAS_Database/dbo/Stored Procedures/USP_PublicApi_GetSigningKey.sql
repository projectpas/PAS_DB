
/*=========================================================================================
  6. STORED PROCEDURES - PAS_PUBLIC_API APPLICATION SETTINGS
=========================================================================================*/

/*************************************************************
 ** File:   [USP_PublicApi_GetSigningKey]
 ** Author: Moin Bloch
 ** Description: 6.1 Signing key for the configured SettingEnvironment. Only this column is returned,
 **                  never the whole AppSettings row.
 ** Purpose: PAS_PUBLIC_API - JWT signing key at startup
 ** Date:   09/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09/11/2026   Moin Bloch    Created
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

  EXEC [dbo].[USP_PublicApi_GetSigningKey] @SettingEnvironment = 'UAT'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetSigningKey]
    @SettingEnvironment VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT TOP (1) [PublicApiSigningKey]
        FROM [dbo].[AppSettings] WITH (NOLOCK)
        WHERE [SettingEnvironment] = @SettingEnvironment;
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetSigningKey'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SettingEnvironment, '') AS VARCHAR(100))
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
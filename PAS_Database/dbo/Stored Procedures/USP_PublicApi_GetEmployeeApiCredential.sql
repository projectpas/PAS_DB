
/*=========================================================================================
  5. STORED PROCEDURES - PAS EMPLOYEE SCREEN (CREDENTIAL MANAGEMENT)
=========================================================================================*/

/*************************************************************
 ** File:   [USP_PublicApi_GetEmployeeApiCredential]
 ** Author: Moin Bloch
 ** Description: 5.1 Credential details for the Employee screen popup. Never returns the secret hash.
 ** Purpose: PAS Employee screen - Public API popup
 ** Date:   09/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09/11/2026   Moin Bloch    Created
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

  EXEC [dbo].[USP_PublicApi_GetEmployeeApiCredential] @EmployeeId = 2, @MasterCompanyId = 1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetEmployeeApiCredential]
    @EmployeeId      BIGINT,
    @MasterCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT [EmployeeId], [ClientId], [IsApiAccessEnabled], [SecretRotatedDate], [UpdatedBy], [UpdatedDate]
        FROM [dbo].[EmployeeApiCredential] WITH (NOLOCK)
        WHERE [EmployeeId] = @EmployeeId
          AND [MasterCompanyId] = @MasterCompanyId;
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetEmployeeApiCredential'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
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
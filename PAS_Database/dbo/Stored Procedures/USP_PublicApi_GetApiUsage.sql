
/*************************************************************
 ** File:   [USP_PublicApi_GetApiUsage]
 ** Author: Moin Bloch
 ** Description: 3.2 Call counts per API, for one employee (@EmployeeId) or the whole company (@EmployeeId NULL).
 **                  Example: EXEC dbo.USP_PublicApi_GetApiUsage @MasterCompanyId = 1, @EmployeeId = 2;
 ** Purpose: Reporting - Public API call counts
 ** Date:   09/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09/11/2026   Moin Bloch    Created
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

  EXEC [dbo].[USP_PublicApi_GetApiUsage] @MasterCompanyId = 1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetApiUsage]
    @MasterCompanyId INT,
    @EmployeeId      BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT U.[EmployeeId],
               E.[FirstName] + ' ' + E.[LastName] AS [EmployeeName],
               U.[ApiName],
               U.[TotalCalls],
               U.[SuccessCalls],
               U.[FailedCalls],
               U.[LastStatusCode],
               U.[LastCalledDate]
        FROM [dbo].[EmployeeApiUsage] U WITH (NOLOCK)
        LEFT JOIN [dbo].[Employee] E WITH (NOLOCK) ON E.[EmployeeId] = U.[EmployeeId]
        WHERE U.[MasterCompanyId] = @MasterCompanyId
          AND (@EmployeeId IS NULL OR U.[EmployeeId] = @EmployeeId)
        ORDER BY U.[EmployeeId], U.[ApiName];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetApiUsage'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100))
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
/*********************
** File:   [USP_GetLeaseSetting]
** Author:   
** Description: This stored procedure is used to get lease setting data for a master company
** Purpose:
** Date:   06/08/2026

** Change History
**********************
** PR   Date         Author  		    Change Description
** --   --------     -------		    --------------------------------
   1    06/08/2026   Ayushi Patel       [PN-17561]Created

**********************/
--EXEC USP_GetLeaseSetting 10
CREATE   PROCEDURE [dbo].[USP_GetLeaseSetting]
 @MasterCompanyId INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
    SELECT TOP 1
        ls.LeaseSettingId,
        ls.MasterCompanyId,
        ls.FlatRateGLAccountId,
        ls.OverageCycleGLAccountId,
        ls.OverageTimeGLAccountId,
        ls.UsageBasedGLAccountId,
        ls.CreatedBy,
        ls.CreatedDate,
        ls.UpdatedBy,
        ls.UpdatedDate
    FROM dbo.LeaseSetting ls WITH (NOLOCK)
    WHERE ls.MasterCompanyId = @MasterCompanyId
      AND ls.IsDeleted = 0;
  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments VARCHAR(150) = 'USP_GetLeaseSetting',
            @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)),
            @ApplicationName VARCHAR(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
  END CATCH
END
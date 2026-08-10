/*********************
** File:   [USP_AddUpdateLeaseSetting]
** Author:   
** Description: This stored procedure is used to add or update lease setting data for a master company
** Purpose:
** Date:   06/08/2026

** Change History
**********************
** PR   Date         Author  		    Change Description
** --   --------     -------		    --------------------------------
   1    06/08/2026   Ayushi Patel       [PN-17561]Created

**********************/
--EXEC USP_AddUpdateLeaseSetting 0, 10, 1, 2, 3, 4, 'admin'
CREATE   PROCEDURE [dbo].[USP_AddUpdateLeaseSetting]
 @LeaseSettingId INT = 0,
 @MasterCompanyId INT = NULL,
 @FlatRateGLAccountId INT = NULL,
 @OverageCycleGLAccountId INT = NULL,
 @OverageTimeGLAccountId INT = NULL,
 @UsageBasedGLAccountId INT = NULL,
 @UpdatedBy NVARCHAR(100) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
    IF EXISTS (SELECT 1 FROM dbo.LeaseSetting WHERE MasterCompanyId = @MasterCompanyId AND IsDeleted = 0)
    BEGIN
      UPDATE dbo.LeaseSetting
      SET FlatRateGLAccountId      = @FlatRateGLAccountId,
          OverageCycleGLAccountId  = @OverageCycleGLAccountId,
          OverageTimeGLAccountId   = @OverageTimeGLAccountId,
          UsageBasedGLAccountId    = @UsageBasedGLAccountId,
          UpdatedBy                = @UpdatedBy,
          UpdatedDate              = GETUTCDATE()
      WHERE MasterCompanyId = @MasterCompanyId
        AND IsDeleted = 0;
    END
    ELSE
    BEGIN
      INSERT INTO dbo.LeaseSetting
          (MasterCompanyId, FlatRateGLAccountId, OverageCycleGLAccountId,
           OverageTimeGLAccountId, UsageBasedGLAccountId,
           CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, IsActive, IsDeleted)
      VALUES
          (@MasterCompanyId, @FlatRateGLAccountId, @OverageCycleGLAccountId,
           @OverageTimeGLAccountId, @UsageBasedGLAccountId,
           @UpdatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), 1, 0);
    END

    SELECT LeaseSettingId FROM dbo.LeaseSetting WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND IsDeleted = 0;
  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments VARCHAR(150) = 'USP_AddUpdateLeaseSetting',
            @ProcedureParameters VARCHAR(3000) = '@LeaseSettingId = ''' + CAST(ISNULL(@LeaseSettingId, '') AS VARCHAR(100))
            + '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
            + '@FlatRateGLAccountId = ''' + CAST(ISNULL(@FlatRateGLAccountId, '') AS VARCHAR(100))
            + '@OverageCycleGLAccountId = ''' + CAST(ISNULL(@OverageCycleGLAccountId, '') AS VARCHAR(100))
            + '@OverageTimeGLAccountId = ''' + CAST(ISNULL(@OverageTimeGLAccountId, '') AS VARCHAR(100))
            + '@UsageBasedGLAccountId = ''' + CAST(ISNULL(@UsageBasedGLAccountId, '') AS VARCHAR(100)),
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
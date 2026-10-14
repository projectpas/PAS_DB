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
   2    17/09/2026   Bhargav Saliya     [PN-17931]Added EnforcePickTicketConfirmation (Lease Pick Ticket)
   3    12/10/2026   Kishor Makwana      [PN-18284] Added IsPendingInvoiceReminderEnabled and PendingInvoiceReminderEmails (pending invoice reminder e-mail job)
   4    13/10/2026   Kishor Makwana      [PN-18284] Added PendingInvoiceReminderDaysBeforeMonthEnd (reminder starts N days before month end)

**********************/
--EXEC USP_AddUpdateLeaseSetting 0, 10, 1, 2, 3, 4, 0, 1, 'billing@company.com,ops@company.com', 2, 'admin'
CREATE PROCEDURE [dbo].[USP_AddUpdateLeaseSetting]
 @LeaseSettingId INT = 0,
 @MasterCompanyId INT = NULL,
 @FlatRateGLAccountId INT = NULL,
 @OverageCycleGLAccountId INT = NULL,
 @OverageTimeGLAccountId INT = NULL,
 @UsageBasedGLAccountId INT = NULL,
 @EnforcePickTicketConfirmation BIT = 0,
 @IsPendingInvoiceReminderEnabled BIT = 0,
 @PendingInvoiceReminderEmails NVARCHAR(2000) = NULL,
 @PendingInvoiceReminderDaysBeforeMonthEnd INT = 2,
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
          EnforcePickTicketConfirmation = ISNULL(@EnforcePickTicketConfirmation, 0),
          IsPendingInvoiceReminderEnabled = ISNULL(@IsPendingInvoiceReminderEnabled, 0),
          PendingInvoiceReminderEmails    = NULLIF(LTRIM(RTRIM(@PendingInvoiceReminderEmails)), N''),
          PendingInvoiceReminderDaysBeforeMonthEnd = CASE WHEN @PendingInvoiceReminderDaysBeforeMonthEnd BETWEEN 0 AND 28 THEN @PendingInvoiceReminderDaysBeforeMonthEnd ELSE 2 END,
          UpdatedBy                = @UpdatedBy,
          UpdatedDate              = GETUTCDATE()
      WHERE MasterCompanyId = @MasterCompanyId
        AND IsDeleted = 0;
    END
    ELSE
    BEGIN
      INSERT INTO dbo.LeaseSetting
          (MasterCompanyId, FlatRateGLAccountId, OverageCycleGLAccountId,
           OverageTimeGLAccountId, UsageBasedGLAccountId, EnforcePickTicketConfirmation,
           IsPendingInvoiceReminderEnabled, PendingInvoiceReminderEmails, PendingInvoiceReminderDaysBeforeMonthEnd,
           CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, IsActive, IsDeleted)
      VALUES
          (@MasterCompanyId, @FlatRateGLAccountId, @OverageCycleGLAccountId,
           @OverageTimeGLAccountId, @UsageBasedGLAccountId, ISNULL(@EnforcePickTicketConfirmation, 0),
           ISNULL(@IsPendingInvoiceReminderEnabled, 0), NULLIF(LTRIM(RTRIM(@PendingInvoiceReminderEmails)), N''),
           CASE WHEN @PendingInvoiceReminderDaysBeforeMonthEnd BETWEEN 0 AND 28 THEN @PendingInvoiceReminderDaysBeforeMonthEnd ELSE 2 END,
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
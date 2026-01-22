/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <01/20/2025>  
** Description: <Check to allow Re-Open Finish Good WO And Reverse MPN Stockline>  
  
Exec [ReverseWorkOrder] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author				Change Description  
** --   --------    -------				--------------------------------
** 1    01/20/2025  Hemant Saliya		 Check Re-Open Finish Good WO And Reverse MPN Stockline
** 2    06/25/2025  Moin Bloch		     Change Old To new Table

EXEC dbo.USP_Check_To_Allow_ReOpen_FinishGood_WorkOrder 8807,'Admin'
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_Check_To_Allow_ReOpen_FinishGood_WorkOrder]
@workOrderPartNoId BIGINT,
@UpdatedBy VARCHAR(256)
AS
BEGIN
	DECLARE @IsPaymentReceived BIT = NULL;
	DECLARE @WOModuleId INT		
	SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
					
	BEGIN TRY
		--OLD Table
		--SELECT CASE WHEN (ISNULL(SUM(WOBI.RemainingAmount),0) - ISNULL(SUM(WOBI.GrandTotal), 0)) = 0 THEN 0 ELSE 1 END AS IsPaymentReceived			   
		--FROM dbo.WorkOrderBillingInvoicing WOBI WITH (NOLOCK) 
		--	JOIN dbo.WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId = WOBI.BillingInvoicingId 
		--WHERE WOBII.WorkOrderPartId = @WorkOrderPartNoId AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0 AND ISNULL(WOBI.IsVersionIncrease, 0) = 0 AND WOBI.IsDeleted = 0 AND
		--	ISNULL(WOBII.IsPerformaInvoice, 0) = 0 AND ISNULL(WOBII.IsVersionIncrease, 0) = 0 AND WOBII.IsDeleted = 0

		--New Table
		SELECT CASE WHEN (ISNULL(SUM(WOBI.[RemainingAmount]),0) - ISNULL(SUM(WOBI.[GrandTotal]), 0)) = 0 THEN 0 ELSE 1 END AS [IsPaymentReceived]			   
		FROM [dbo].[BillingInvoicing] WOBI WITH (NOLOCK) 
			JOIN [dbo].[BillingInvoicingItems] WOBII WITH (NOLOCK) ON WOBII.[BillingInvoicingId] = WOBI.[BillingInvoicingId]
		WHERE WOBII.[SubReferenceId] = @WorkOrderPartNoId AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 0 AND ISNULL(WOBI.[IsVersionIncrease], 0) = 0 AND WOBI.[IsDeleted] = 0 AND
			ISNULL(WOBII.[IsPerformaInvoice], 0) = 0 AND ISNULL(WOBII.[IsVersionIncrease], 0) = 0 AND WOBII.[IsDeleted] = 0 AND WOBI.[ModuleId] = @WOModuleId

	END TRY
	BEGIN CATCH
			IF @@trancount > 0
			PRINT 'ROLLBACK'
			--ROLLBACK TRANSACTION;
				DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_Check_To_Allow_ReOpen_FinishGood_WorkOrder' 
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@workOrderPartNoId, '') AS VARCHAR(100)) 
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			=  @ApplicationName
                     , @ErrorLogID				= @ErrorLogID OUTPUT;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END
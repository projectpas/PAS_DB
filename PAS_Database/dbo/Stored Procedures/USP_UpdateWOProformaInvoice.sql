/*************************************************************           
 ** File:     [USP_UpdateWOProformaInvoice]           
 ** Author:	  Devendra Shekh
 ** Description: This SP IS Used update isInvoicePosted flag for proformaInvoice
 ** Purpose:         
 ** Date:   08/02/2024
		   [dd/mm/yyyy]
          
 ** PARAMETERS:             
         
 ** RETURN VALUE:           
  
 **************************************************************    
 ** Change History           
 **************************************************************           
 ** PR   	Date			Author					Change Description            
 ** --   	--------		-------				--------------------------------     
	1		08/02/2024		Devendra Shekh			CREATED
	2		15/02/2024		Devendra Shekh			Modified
	3		16/02/2024		Devendra Shekh			added NOLOCK for update

	EXEC [USP_UpdateWOProformaInvoice] 4270,3737

**************************************************************/ 

CREATE   Procedure [dbo].[USP_UpdateWOProformaInvoice]
	@WorkOrderId  BIGINT,
	@WorkFlowWorkOrderId BIGINT,
	@BillingInvoicingId BIGINT = NULL
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN		

				DECLARE @TotalRec BIGINT = 0,@StartCount BIGINT = 1,@WorkOrderPartNoId BIGINT = 0, @WOProfomaBillingInvoicingId BIGINT = 0;

				IF OBJECT_ID('tempdb.dbo.#tempProformaInvoice', 'U') IS NOT NULL
					DROP TABLE #tempProformaInvoice; 

				CREATE TABLE #tempProformaInvoice (
					[Id] [BIGINT] IDENTITY NOT NULL,
					[BillingInvoicingId] [BIGINT] NULL,
					[WorkOrderId] [BIGINT] NULL,
					[WorkFlowWorkOrderId] [BIGINT] NULL,
				)

				INSERT INTO #tempProformaInvoice([BillingInvoicingId], [WorkOrderId], [WorkFlowWorkOrderId])
				SELECT [BillingInvoicingId],[WorkOrderId],[WorkFlowWorkOrderId] 
				FROM [dbo].[WorkOrderBillingInvoicing] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId AND [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND ISNULL(IsPerformaInvoice, 0) = 1

				SELECT TOP 1 @WorkOrderPartNoId = WorkOrderPartId FROM [dbo].[WorkOrderBillingInvoicingItem] WITH(NOLOCK) WHERE [BillingInvoicingId] = @BillingInvoicingId;

				SELECT TOP 1 @WOProfomaBillingInvoicingId = BillingInvoicingId 
				FROM [dbo].[WorkOrderBillingInvoicingItem] WITH(NOLOCK) WHERE WorkOrderPartId = @WorkOrderPartNoId AND ISNULL(IsPerformaInvoice, 0) = 1 AND ISNULL(IsVersionIncrease, 0) = 0;

				SET @TotalRec = (SELECT MAX(Id) FROM #tempProformaInvoice);

				IF(ISNULL(@TotalRec, 0) > 0)
				BEGIN

					WHILE(@TotalRec >= @StartCount)
					BEGIN
						DECLARE @BillingInvoiceId BIGINT = 0;

						SELECT @BillingInvoiceId = [BillingInvoicingId] FROM #tempProformaInvoice WHERE Id = @StartCount;

						UPDATE WOB
						SET WOB.IsInvoicePosted = 1
						FROM [dbo].[WorkOrderBillingInvoicing] WOB WITH(NOLOCK)
						WHERE WOB.[BillingInvoicingId] = @BillingInvoiceId

						UPDATE WOBI
						SET WOBI.IsInvoicePosted = 1
						FROM [dbo].[WorkOrderBillingInvoicingItem] WOBI WITH(NOLOCK)
						WHERE WOBI.[BillingInvoicingId] = @BillingInvoiceId

						SET @StartCount = @StartCount + 1;
					END

				END

				IF(ISNULL(@WOProfomaBillingInvoicingId, 0) > 0)
				BEGIN
					PRINT @WOProfomaBillingInvoicingId
					UPDATE WOBN
					SET WOBN.IsInvoicePosted = 1
					FROM [dbo].[WorkOrderBillingInvoicing] WOBN WITH(NOLOCK)
					WHERE WOBN.[BillingInvoicingId] = @WOProfomaBillingInvoicingId

					UPDATE WOBIN
					SET WOBIN.IsInvoicePosted = 1
					FROM [dbo].[WorkOrderBillingInvoicingItem] WOBIN WITH(NOLOCK)
					WHERE WOBIN.[BillingInvoicingId] = @WOProfomaBillingInvoicingId
				END

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateWOProformaInvoice' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + '''
													   @Parameter2 = ' + ISNULL(@WorkFlowWorkOrderId ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END
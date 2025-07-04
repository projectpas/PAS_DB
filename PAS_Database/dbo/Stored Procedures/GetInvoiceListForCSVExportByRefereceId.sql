/*************************************************************           
 ** File:   [dbo].[GetInvoiceListForCSVExportByRefereceId]          
 ** Author:   RAJESH GAMI
 ** Description: Get Invoice List By ModuleId and Reference Id.
 ** Date:   2 May 2025   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    2 May 2025   RAJESH GAMI	CREATED
	2    03-07-2025   Moin Bloch    Changed Old To New Billing Table
** EXEC [dbo].[GetInvoiceListForCSVExportByRefereceId] 15,8720,NULL
**************************************************************/ 
CREATE       PROCEDURE [dbo].[GetInvoiceListForCSVExportByRefereceId]
	@ModuleId INT,
	@ReferenceId BIGINT,
	@SubReferenceid BIGINT = NULL /* If need in future */
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;
	BEGIN TRY
			DECLARE @woModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'WorkOrder')
			DECLARE @soModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'SalesOrder')
			
			IF(@ModuleId = @woModuleId) /******************* START: WORK ORDER MODULE *******************/
			BEGIN
				Select 
					   WOBI.ReferenceId WorkOrderId, 
					   WOBII.SubReferenceId  WorkOrderPartId,
					   WOBI.InvoiceNo,
					   Wo.CustomerName Customer,
					   WOBI.InvoiceDate,
					   DATEADD(DAY, WO.NetDays, WOBI.InvoiceDate) AS DueDate,
					   WO.CreditTerms as Terms,
					   '' as [Location],
					   WO.Notes as Memo,
					   WOP.RevisedPartNumber as Item,
					   WOP.RevisedPartDescription as ItemDescription,
					   ISNULL(WOP.Quantity,0) as ItemQuantity,
					   ISNULL(WOBII.GrandTotal,0) as ItemRate,
					   (ISNULL(WOP.Quantity,0) * ISNULL(WOBII.GrandTotal,0)) as ItemAmount,
					   GETDATE() as ServiceDate
					FROM dbo.BillingInvoicing WOBI WITH(NOLOCK) 
						 INNER JOIN  dbo.BillingInvoicingItems WOBII WITH(NOLOCK) ON WOBI.BillingInvoicingId = WOBII.BillingInvoicingId
						 INNER JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WOBI.ReferenceId = WO.WorkOrderId
						 INNER JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId AND WOBII.ItemMasterId = WOP.ItemMasterId
					WHERE WOBI.ReferenceId = @ReferenceId AND ISNULL(WOBI.IsVersionIncrease,0) = 0 AND wobi.[ModuleId] = @WOModuleId
				
			END /******************* END: WORK ORDER MODULE *******************/
			ELSE IF(@ModuleId = @soModuleId) /******************* START: SALES ORDER MODULE *******************/
			BEGIN
				PRINT 'SALES ORDER QUERY'
			END  /******************* END: SALES ORDER MODULE *******************/
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments     VARCHAR(150)    = 'GetInvoiceListForCSVExportByRefereceId' 
			, @ProcedureParameters VARCHAR(3000)  = '@ModuleId = '''+ ISNULL(@ModuleId, '') + ''
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
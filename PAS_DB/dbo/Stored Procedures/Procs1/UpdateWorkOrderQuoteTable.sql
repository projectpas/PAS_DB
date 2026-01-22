

/*************************************************************           
 ** File:   [UpdateWorkOrderTeardownColumnsWithId]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Update UpdateWorkOrder QuoteTable
 ** Purpose:         
 ** Date:   03/16/2021       
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    03/16/2021    Subhash Saliya Created
	2	 01/20/2024	   Moin Bloch	  Modified (Added WorkOrderTask Table For conditionally check table for Task)
	     
--EXEC [UpdateWorkOrderQuoteTable] 'WorkOrderQuoteMaterial', 284
**************************************************************/

CREATE PROCEDURE [dbo].[UpdateWorkOrderQuoteTable]
    @TableName varchar(100),
	@TableprimaryId bigint
AS
BEGIN
	 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
     SET NOCOUNT ON

	 BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				DECLARE @WorkOrderId BIGINT = 0;
				DECLARE @WorkOrderQuoteId BIGINT = 0;				
				DECLARE @WorkOrderQuoteDetailsId BIGINT = 0;				
				DECLARE @WorkOrderFormTypeId BIT = 0; 
				DECLARE @WorkOrderQuoteLaborHeaderId BIGINT = 0;						

				 IF(LOWER(@TableName) ='workorderquotematerial')
				 BEGIN
					 SELECT @WorkOrderQuoteDetailsId = [WorkOrderQuoteDetailsId] FROM [dbo].[WorkOrderQuoteMaterial] WITH(NOLOCK) WHERE [WorkOrderQuoteMaterialId] = @TableprimaryId

					 SELECT @WorkOrderQuoteId = [WorkOrderQuoteId] FROM [dbo].[WorkOrderQuoteDetails] WITH(NOLOCK) WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId;

					 SELECT @WorkOrderId = [WorkOrderId] FROM [dbo].[WorkOrderQuote] WITH(NOLOCK) WHERE [WorkOrderQuoteId] = @WorkOrderQuoteId;
					 					 
             		 SELECT @WorkOrderFormTypeId = ISNULL(WO.[WorkOrderFormTypeId],0) FROM [dbo].[WorkOrder] WO WITH(NOLOCK) WHERE WO.[WorkOrderId] = @WorkOrderId;
		
						 Update WOQM SET 
							 WOQM.Conditiontype = Co.[Description],
							 WOQM.PartNumber = Im.partnumber,
							 WOQM.PartDescription = Im.PartDescription,
							 WOQM.Stocktype = (CASE WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMA&DER' WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'  WHEN im.IsPma = 0 AND im.IsDER = 1  THEN 'DER'ELSE 'OEM'END),
							 --WOQM.TaskName = T.Description,
							 WOQM.TaskName = CASE WHEN @WorkOrderFormTypeId = 1 THEN WT.[TaskName] ELSE T.[Description] END,
							 WOQM.UomName = Uo.[Description],
							 WOQM.BillingName = (CASE WHEN WOQM.BillingMethodId = 1 THEN 'T&M'  WHEN  WOQM.BillingMethodId = 2 THEN 'Actual' ELSE '' END),
							 WOQM.MarkUp = p.PercentValue,
							 WOQM.Provision = PO.[Description]
						 FROM [dbo].[WorkOrderQuoteMaterial] WOQM WITH(NOLOCK)
							 INNER JOIN dbo.Condition Co WITH(NOLOCK) ON Co.ConditionId = WOQM.ConditionCodeId
							 INNER JOIN dbo.ItemMaster Im WITH(NOLOCK) ON Im.ItemMasterId = WOQM.ItemMasterId
							 LEFT JOIN dbo.Task T WITH(NOLOCK) ON T.TaskId = WOQM.TaskId
							 LEFT JOIN dbo.WorkOrderTask WT WITH (NOLOCK) ON WT.WorkOrderTaskId = WOQM.TaskId
							 INNER JOIN dbo.UnitOfMeasure Uo WITH(NOLOCK) ON Uo.UnitOfMeasureId = WOQM.UnitOfMeasureId
							 INNER JOIN dbo.Provision PO WITH(NOLOCK) ON PO.ProvisionId = WOQM.ProvisionId
							 LEFT JOIN dbo.[Percent] p WITH(NOLOCK) ON p.PercentId = WOQM.MarkupPercentageId 
						 WHERE WOQM.WorkOrderQuoteMaterialId = @TableprimaryId
				 END
				 ELSE IF(LOWER(@TableName) ='workorderquotelabor')
				 BEGIN

						SELECT @WorkOrderQuoteLaborHeaderId = [WorkOrderQuoteLaborHeaderId] FROM [dbo].[WorkOrderQuoteLabor] WITH(NOLOCK) WHERE [WorkOrderQuoteLaborId] = @TableprimaryId;
						
						SELECT @WorkOrderQuoteDetailsId = [WorkOrderQuoteDetailsId] FROM [dbo].[WorkOrderQuoteLaborHeader] WITH(NOLOCK) WHERE [WorkOrderQuoteLaborHeaderId] = @WorkOrderQuoteLaborHeaderId;

						SELECT @WorkOrderQuoteId = [WorkOrderQuoteId] FROM [dbo].[WorkOrderQuoteDetails] WITH(NOLOCK) WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId;

					    SELECT @WorkOrderId = [WorkOrderId] FROM [dbo].[WorkOrderQuote] WITH(NOLOCK) WHERE [WorkOrderQuoteId] = @WorkOrderQuoteId;
					 					 
             		    SELECT @WorkOrderFormTypeId = ISNULL(WO.[WorkOrderFormTypeId],0) FROM [dbo].[WorkOrder] WO WITH(NOLOCK) WHERE WO.[WorkOrderId] = @WorkOrderId;
		
						 UPDATE WOQL SET 
							 WOQL.Expertise = EE.[Description],
							 --WOQL.TaskName = T.Description,
							 WOQL.TaskName = CASE WHEN @WorkOrderFormTypeId = 1 THEN WT.[TaskName] ELSE T.[Description] END,
							 WOQL.Billabletype = (CASE WHEN WOQL.BillableId = 1 THEN 'Billable'  WHEN  WOQL.BillableId = 2 THEN 'Non-Billable' ELSE '' END),
							 WOQL.BillingName = (CASE WHEN WOQL.BillingMethodId = 1 THEN 'T&M'  WHEN  WOQL.BillingMethodId = 2 THEN 'Actual' ELSE '' END),
							 WOQL.MarkUp = p.PercentValue,
							 WOQL.BurdaenRatePercentage = p1.PercentValue
						 FROM [dbo].[WorkOrderQuoteLabor] WOQL WITH(NOLOCK)
							 INNER JOIN dbo.EmployeeExpertise EE WITH(NOLOCK) ON EE.EmployeeExpertiseId = WOQL.ExpertiseId
							 LEFT JOIN dbo.Task T WITH(NOLOCK) ON T.TaskId = WOQL.TaskId
							 LEFT JOIN dbo.WorkOrderTask WT WITH (NOLOCK) ON WT.WorkOrderTaskId = WOQL.TaskId
							 LEFT JOIN dbo.[Percent] p WITH(NOLOCK) ON p.PercentId = WOQL.MarkupPercentageId 
							 LEFT JOIN dbo.[Percent] p1 WITH(NOLOCK) ON p1.PercentId = WOQL.BurdaenRatePercentageId 
						 WHERE WOQL.WorkOrderQuoteLaborId = @TableprimaryId
				 END
				 ELSE IF(LOWER(@TableName) ='workorderquotefreight')
				 BEGIN
						SELECT @WorkOrderQuoteDetailsId = [WorkOrderQuoteDetailsId] FROM [dbo].[WorkOrderQuoteFreight] WITH(NOLOCK) WHERE [WorkOrderQuoteFreightId] = @TableprimaryId
						
						SELECT @WorkOrderQuoteId = [WorkOrderQuoteId] FROM [dbo].[WorkOrderQuoteDetails] WITH(NOLOCK) WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId;

						SELECT @WorkOrderId = [WorkOrderId] FROM [dbo].[WorkOrderQuote] WITH(NOLOCK) WHERE [WorkOrderQuoteId] = @WorkOrderQuoteId;
				 					 
		         		SELECT @WorkOrderFormTypeId = ISNULL(WO.[WorkOrderFormTypeId],0) FROM [dbo].[WorkOrder] WO WITH(NOLOCK) WHERE WO.[WorkOrderId] = @WorkOrderId;
			      				 
						 UPDATE WOQF SET 
							 WOQF.Shipvia = sp.[Name],
							 WOQF.UomName =  Uo.[Description],
							 --WOQF.TaskName = T.[Description],
							 WOQF.TaskName = CASE WHEN @WorkOrderFormTypeId = 1 THEN WT.[TaskName] ELSE T.[Description] END,
							 WOQF.DimensionUomName = dUo.[Description],
							 WOQF.BillingName = (CASE WHEN WOQF.BillingMethodId = 1 THEN 'T&M'  WHEN  WOQF.BillingMethodId = 2 THEN 'Actual' ELSE '' END),
							 WOQF.MarkUp = p.PercentValue,
							 WOQF.Currency = c.Code
						 FROM [dbo].[WorkOrderQuoteFreight] WOQF WITH(NOLOCK)
							 INNER JOIN dbo.ShippingVia sp WITH(NOLOCK) ON sp.ShippingViaId = WOQF.ShipViaId
							 LEFT JOIN dbo.Task T WITH(NOLOCK) ON T.TaskId = WOQF.TaskId
							 LEFT JOIN dbo.WorkOrderTask WT WITH (NOLOCK) ON WT.WorkOrderTaskId = WOQF.TaskId							 
							 INNER JOIN dbo.UnitOfMeasure Uo WITH(NOLOCK) ON Uo.UnitOfMeasureId = WOQF.UOMId
							 INNER JOIN dbo.UnitOfMeasure dUo WITH(NOLOCK) ON dUo.UnitOfMeasureId = WOQF.DimensionUOMId
							 INNER JOIN dbo.Currency c WITH(NOLOCK) ON c.CurrencyId = WOQF.CurrencyId
							 LEFT JOIN dbo.[Percent] p WITH(NOLOCK) ON p.PercentId = WOQF.MarkupPercentageId 
						 Where WOQF.WorkOrderQuoteFreightId = @TableprimaryId
			
				 END
				 ELSE IF(LOWER(@TableName) ='workorderquotecharges')
				 BEGIN
						SELECT @WorkOrderQuoteDetailsId = [WorkOrderQuoteDetailsId] FROM [dbo].[WorkOrderQuoteCharges] WITH(NOLOCK) WHERE [WorkOrderQuoteChargesId] = @TableprimaryId
						
						SELECT @WorkOrderQuoteId = [WorkOrderQuoteId] FROM [dbo].[WorkOrderQuoteDetails] WITH(NOLOCK) WHERE [WorkOrderQuoteDetailsId] = @WorkOrderQuoteDetailsId;

						SELECT @WorkOrderId = [WorkOrderId] FROM [dbo].[WorkOrderQuote] WITH(NOLOCK) WHERE [WorkOrderQuoteId] = @WorkOrderQuoteId;
				 					 
		         		SELECT @WorkOrderFormTypeId = ISNULL(WO.[WorkOrderFormTypeId],0) FROM [dbo].[WorkOrder] WO WITH(NOLOCK) WHERE WO.[WorkOrderId] = @WorkOrderId;
			      	
	      				UPDATE WOQC SET 
							 WOQC.VendorName = v.VendorName,
							 --WOQC.TaskName = T.[Description],
							 WOQC.TaskName = CASE WHEN @WorkOrderFormTypeId = 1 THEN WT.[TaskName] ELSE T.[Description] END,
							 WOQC.BillingName = (CASE WHEN WOQC.BillingMethodId = 1 THEN 'T&M'  WHEN  WOQC.BillingMethodId = 2 THEN 'Actual' ELSE '' END),
							 WOQC.MarkUp = p.PercentValue,
							 WOQC.ChargeType = c.ChargeType,
							 WOQC.GlAccountName=gl.AccountName
						 FROM [dbo].[WorkOrderQuoteCharges] WOQC WITH(NOLOCK)
							 LEFT JOIN dbo.Vendor v WITH(NOLOCK) ON v.VendorId = WOQC.VendorId
							 LEFT JOIN dbo.Task T WITH(NOLOCK) ON T.TaskId = WOQC.TaskId
							 LEFT JOIN dbo.WorkOrderTask WT WITH (NOLOCK) ON WT.WorkOrderTaskId = WOQC.TaskId
							 LEFT JOIN dbo.[Percent] p WITH(NOLOCK) ON p.PercentId = WOQC.MarkupPercentageId 
							 INNER JOIN dbo.[Charge] c WITH(NOLOCK) ON c.ChargeId = WOQC.ChargesTypeId 
							 LEFT JOIN dbo.[GLAccount] gl WITH(NOLOCK) ON gl.GLAccountId = c.GLAccountId 
						 WHERE WOQC.WorkOrderQuoteChargesId = @TableprimaryId			
				 END
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0			
				ROLLBACK TRAN;				
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateWorkOrderQuoteTable' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@TableName, '') + ''', 
													   @Parameter2 = ' + ISNULL(CAST(@TableprimaryId AS VARCHAR(50)) ,'') +''
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


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
				if(LOWER(@TableName) ='workorderquotematerial')
				 BEGIN
						 Update WOQM SET 
							 WOQM.Conditiontype = Co.Description,
							 WOQM.PartNumber = Im.partnumber,
							 WOQM.PartDescription = Im.PartDescription,
							 WOQM.Stocktype = (CASE WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMA&DER' WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'  WHEN im.IsPma = 0 AND im.IsDER = 1  THEN 'DER'ELSE 'OEM'END),
							 WOQM.TaskName = T.Description,
							 WOQM.UomName = Uo.Description,
							 WOQM.BillingName = (case when WOQM.BillingMethodId = 1 then 'T&M'  when  WOQM.BillingMethodId = 2 then 'Actual' else '' End),
							 WOQM.MarkUp = p.PercentValue,
							 WOQM.Provision = PO.Description
						 FROM [dbo].[WorkOrderQuoteMaterial] WOQM WITH(NOLOCK)
							 INNER JOIN dbo.Condition Co WITH(NOLOCK) ON Co.ConditionId = WOQM.ConditionCodeId
							 INNER JOIN dbo.ItemMaster Im WITH(NOLOCK) ON Im.ItemMasterId = WOQM.ItemMasterId
							 INNER JOIN dbo.Task T WITH(NOLOCK) ON T.TaskId = WOQM.TaskId
							 INNER JOIN dbo.UnitOfMeasure Uo WITH(NOLOCK) ON Uo.UnitOfMeasureId = WOQM.UnitOfMeasureId
							 INNER JOIN dbo.Provision PO WITH(NOLOCK) ON PO.ProvisionId = WOQM.ProvisionId
							 LEFT JOIN dbo.[Percent] p WITH(NOLOCK) ON p.PercentId = WOQM.MarkupPercentageId 
						 WHERE WOQM.WorkOrderQuoteMaterialId = @TableprimaryId
				 END
				 ELSE IF(LOWER(@TableName) ='workorderquotelabor')
				 BEGIN
						 Update WOQL SET 
							 WOQL.Expertise = EE.Description,
							 WOQL.TaskName = T.Description,
							 WOQL.Billabletype = (case when WOQL.BillableId = 1 then 'Billable'  when  WOQL.BillableId = 2 then 'Non-Billable' else '' End),
							 WOQL.BillingName = (case when WOQL.BillingMethodId = 1 then 'T&M'  when  WOQL.BillingMethodId = 2 then 'Actual' else '' End),
							 WOQL.MarkUp = p.PercentValue,
							 WOQL.BurdaenRatePercentage = p1.PercentValue
						 FROM [dbo].[WorkOrderQuoteLabor] WOQL WITH(NOLOCK)
							 INNER JOIN dbo.EmployeeExpertise EE WITH(NOLOCK) ON EE.EmployeeExpertiseId = WOQL.ExpertiseId
							 INNER JOIN dbo.Task T WITH(NOLOCK) ON T.TaskId = WOQL.TaskId
							 LEFT JOIN dbo.[Percent] p WITH(NOLOCK) ON p.PercentId = WOQL.MarkupPercentageId 
							 LEFT JOIN dbo.[Percent] p1 WITH(NOLOCK) ON p1.PercentId = WOQL.BurdaenRatePercentageId 
						 WHERE WOQL.WorkOrderQuoteLaborId = @TableprimaryId
				 END
				 ELSE IF(LOWER(@TableName) ='workorderquotefreight')
				 begin
	      				 Update WOQF SET 
							 WOQF.Shipvia = sp.Name,
							 WOQF.UomName =  Uo.Description,
							 WOQF.TaskName = T.Description,
							 WOQF.DimensionUomName = dUo.Description,
							 WOQF.BillingName = (case when WOQF.BillingMethodId = 1 then 'T&M'  when  WOQF.BillingMethodId = 2 then 'Actual' else '' End),
							 WOQF.MarkUp = p.PercentValue,
							 WOQF.Currency = c.Code
						 FROM [dbo].[WorkOrderQuoteFreight] WOQF WITH(NOLOCK)
							 INNER JOIN dbo.ShippingVia sp WITH(NOLOCK) ON sp.ShippingViaId = WOQF.ShipViaId
							 INNER JOIN dbo.Task T WITH(NOLOCK) ON T.TaskId = WOQF.TaskId
							 INNER JOIN dbo.UnitOfMeasure Uo WITH(NOLOCK) ON Uo.UnitOfMeasureId = WOQF.UOMId
							 INNER JOIN dbo.UnitOfMeasure dUo WITH(NOLOCK) ON dUo.UnitOfMeasureId = WOQF.DimensionUOMId
							 INNER JOIN dbo.Currency c WITH(NOLOCK) ON c.CurrencyId = WOQF.CurrencyId
							 LEFT JOIN dbo.[Percent] p WITH(NOLOCK) ON p.PercentId = WOQF.MarkupPercentageId 
						 Where WOQF.WorkOrderQuoteFreightId = @TableprimaryId
			
				 end
				 else if(LOWER(@TableName) ='workorderquotecharges')
				 begin
	      				 Update WOQC SET 
							 WOQC.VendorName = v.VendorName,
							 WOQC.TaskName = T.Description,
							 WOQC.BillingName = (case when WOQC.BillingMethodId = 1 then 'T&M'  when  WOQC.BillingMethodId = 2 then 'Actual' else '' End),
							 WOQC.MarkUp = p.PercentValue,
							 WOQC.ChargeType = c.ChargeType,
							 WOQC.GlAccountName=gl.AccountName
						 FROM [dbo].[WorkOrderQuoteCharges] WOQC WITH(NOLOCK)
							 LEFT JOIN dbo.Vendor v WITH(NOLOCK) ON v.VendorId = WOQC.VendorId
							 INNER JOIN dbo.Task T WITH(NOLOCK) ON T.TaskId = WOQC.TaskId
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
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				PRINT 'HI'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateWorkOrderQuoteTable' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@TableName, '') + ''', 
													   @Parameter2 = ' + ISNULL(CAST(@TableprimaryId AS varchar(50)) ,'') +''
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
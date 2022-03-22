
/*************************************************************           
 ** File:   [USP_GetWorkOrderQuoteChargesHistory]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Work Order Materials List    
 ** Purpose:         
 ** Date:   02/22/2021        
          
 ** PARAMETERS:           
 @WorkOrderQuoteChargesId BIGINT   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/22/2021   Hemant Saliya Created
     
 EXECUTE USP_GetWorkOrderQuoteChargesHistory NULL,77

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetWorkOrderQuoteChargesHistory]    
(    
@WorkOrderQuoteChargesId BIGINT = NULL
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    	

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN  
					SELECT  WOQC.WorkOrderQuoteChargesId,
						WOQC.WorkOrderQuoteDetailsId,
						WOQC.WorkOrderQuoteChargesAuditId,
						WOQC.ChargesTypeId, 
						WOQC.VendorId,
						WOQC.TaskId,
						WOQC.TaskName,
						WOQC.ChargeType, 
						WOQC.GlAccountName,
						WOQC.Description,
						WOQC.Quantity,
						WOQC.RefNum,
						WOQC.UnitCost,
						WOQC.ExtendedCost,
						WOQC.VendorName,
						WOQC.BillingName,
						WOQC.MarkUp,
						WOQC.BillingMethodId,
						WOQC.MarkupPercentageId,
						WOQC.BillingAmount,
						WOQC.BillingRate,
						WOQC.MasterCompanyId,
						WOQC.CreatedBy,
						WOQC.UpdatedBy,
						WOQC.UpdatedDate,
						WOQC.CreatedDate,
						WOQC.IsActive,
						WOQC.IsDeleted,
						WOQC.MarkupFixedPrice
					FROM dbo.WorkOrderQuoteChargesAudit WOQC WITH (NOLOCK)  		
					WHERE WOQC.WorkOrderQuoteChargesId = @WorkOrderQuoteChargesId
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderQuoteChargesHistory' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderQuoteChargesId, '') + ''
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
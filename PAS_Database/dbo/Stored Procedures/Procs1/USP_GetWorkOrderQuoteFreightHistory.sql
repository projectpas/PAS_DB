
/*************************************************************           
 ** File:   [USP_GetWorkOrderQuoteChargesHistory]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Work Order Quote Freight History List    
 ** Purpose:         
 ** Date:   03/16/2021        
          
 ** PARAMETERS:           
 @WorkOrderQuoteChargesId BIGINT   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    03/16/2021   Hemant Saliya Created
     
 EXECUTE USP_GetWorkOrderQuoteFreightHistory 77

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetWorkOrderQuoteFreightHistory]    
(    
@WorkOrderQuoteFreightId BIGINT = NULL
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    	

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN  
					SELECT  WOQF.WorkOrderQuoteFreightId,
						WOQF.WorkOrderQuoteFreightAuditId,
						WOQF.WorkOrderQuoteDetailsId,
						WOQF.ShipViaId, 
						WOQF.TaskId,
						WOQF.DimensionUOMId,
						WOQF.CurrencyId,
						WOQF.UOMId,
						WOQF.Shipvia,			
						WOQF.TaskName,
						WOQF.Weight, 
						WOQF.UomName AS UOMName,			
						WOQF.Height,
						WOQF.Length,
						WOQF.Width,
						WOQF.DimensionUomName,			
						WOQF.Currency,	
						WOQF.Amount,	
						WOQF.Memo,	
						WOQF.BillingName,
						WOQF.MarkUp,
						WOQF.BillingMethodId,
						WOQF.MarkupPercentageId,
						WOQF.BillingAmount,
						WOQF.BillingRate,
						WOQF.MarkupFixedPrice,
						WOQF.MasterCompanyId,
						WOQF.CreatedBy,
						WOQF.UpdatedBy,
						WOQF.UpdatedDate,
						WOQF.CreatedDate,
						WOQF.IsActive,
						WOQF.IsDeleted
				FROM dbo.WorkOrderQuoteFreightAudit WOQF WITH (NOLOCK)  		
				WHERE WOQF.WorkOrderQuoteFreightId = @WorkOrderQuoteFreightId
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderQuoteFreightHistory' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderQuoteFreightId, '') + ''
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
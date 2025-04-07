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
    1    02/14/2025   Bhargav Saliya UTC Date Changes
     
 EXECUTE USP_GetWorkOrderQuoteFreightHistory 77

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetWorkOrderQuoteFreightHistory]    
(    
@WorkOrderQuoteFreightId BIGINT = NULL,
@EmployeeId BIGINT = 0
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    	

		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
			LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId;

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
						CASE WHEN CAST(WOQF.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(WOQF.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END UpdatedDate,
						CASE WHEN CAST(WOQF.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(WOQF.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END CreatedDate,
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
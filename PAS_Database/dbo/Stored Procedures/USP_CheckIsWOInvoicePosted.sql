/*********************             
 ** File:   UPDATE CUSTOMER IN WO           
 ** Author:  HEMANT SALIYA  
 ** Description: This SP Is Used to Check Is allowed to Reopen WO
 ** Purpose:           
 ** Date:   14-APRIL-2024
    
 ************************************************************             
  ** Change History             
 ************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    05/01/2024   HEMANT SALIYA      Created  

DECLARE @IsBillingGenerated BIT;       
EXECUTE USP_CheckIsWOInvoicePosted 3913,3430, @IsBillingGenerated OUTPUT 

*************************************************************/   
  
CREATE   PROCEDURE [dbo].[USP_CheckIsWOInvoicePosted] 	
@WorkOrderId BIGINT = NULL,  
@WorkOrderPartNoId BIGINT = NULL,
@IsBillingGenerated BIT = 0 OUTPUT  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY

		DECLARE @IsInvoiceGenerated BIT = 0;
		DECLARE @InvoiceStatus VARCHAR(100) = NULL;

		SELECT @IsInvoiceGenerated = CASE WHEN COUNT(WOBI.BillingInvoicingId) > 0 THEN 1 ELSE 0 END 
		FROM dbo.WorkOrderBillingInvoicing WOBI WITH (NOLOCK) 
			JOIN dbo.WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId = WOBI.BillingInvoicingId 
		WHERE WOBI.WorkOrderId = @WorkOrderId AND WOBII.WorkOrderPartId = @WorkOrderPartNoId AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0 AND ISNULL(WOBI.IsVersionIncrease, 0) = 0 AND WOBI.IsDeleted = 0 AND
			ISNULL(WOBII.IsPerformaInvoice, 0) = 0 AND ISNULL(WOBII.IsVersionIncrease, 0) = 0 AND WOBII.IsDeleted = 0
		
		SET @IsBillingGenerated = @IsInvoiceGenerated;

		SELECT @IsBillingGenerated; 

 END TRY      
 BEGIN CATCH  
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
        , @AdhocComments     VARCHAR(150)    = 'USP_CheckIsWOInvoicePosted'   
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderPartNoId, '') AS varchar(100))   
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
 END CATCH  
END
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
    1    04/30/2024   HEMANT SALIYA      Created  
	2    05/06/2024   HEMANT SALIYA      Updated For Remove Shipping Condition  

DECLARE @IsAllowReopenWO BIT;       
EXECUTE USP_CheckAllowReopenWorkOrder 3913,3430, @IsAllowReopenWO OUTPUT 

*************************************************************/   
  
CREATE   PROCEDURE [dbo].[USP_CheckAllowReopenWorkOrder] 	
@WorkOrderId BIGINT = NULL,  
@WorkOrderPartNoId BIGINT = NULL,
@IsAllowReopenWO BIT = 0 OUTPUT  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY
		DECLARE @MasterCompanyId INT = NULL;		
		DECLARE @IsPaymentReceived BIT = NULL;
		--DECLARE @IsPartShipped BIT = NULL;
		DECLARE @IsPartClosed BIT = NULL;

		SELECT @IsPartClosed = ISNULL(IsClosed, 0) FROM dbo.WorkOrderPartNumber WITH (NOLOCK) WHERE ID = @WorkOrderPartNoId 

		--SELECT @IsPartShipped = CASE WHEN COUNT(WOS.WorkOrderShippingId) > 0 THEN 1 ELSE 0 END 
		--FROM dbo.WorkOrderShipping WOS WITH (NOLOCK) 
		--	JOIN dbo.WorkOrderShippingItem WOSI WITH (NOLOCK) ON WOSI.WorkOrderShippingId = WOS.WorkOrderShippingId 
		--WHERE WOSI.WorkOrderPartNumId = @workOrderPartNoId AND (ISNULL(AirwayBill, '') != '' ) --OR ISNULL(isIgnoreAWB, 0) = 1

		SELECT @IsPaymentReceived = CASE WHEN (ISNULL(SUM(WOBI.RemainingAmount),0) - ISNULL(SUM(WOBI.GrandTotal), 0)) = 0 THEN 0 ELSE 1 END 
		FROM dbo.WorkOrderBillingInvoicing WOBI WITH (NOLOCK) 
			JOIN dbo.WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId = WOBI.BillingInvoicingId 
		WHERE WOBI.WorkOrderId = @WorkOrderId AND WOBII.WorkOrderPartId = @WorkOrderPartNoId AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0 AND ISNULL(WOBI.IsVersionIncrease, 0) = 0 AND WOBI.IsDeleted = 0 AND
			ISNULL(WOBII.IsPerformaInvoice, 0) = 0 AND ISNULL(WOBII.IsVersionIncrease, 0) = 0 AND WOBII.IsDeleted = 0
		
		--SELECT @IsPaymentReceived, @IsPartShipped, @IsPartClosed

		IF(@IsPaymentReceived = 1)
		BEGIN
			SET @IsAllowReopenWO = 0;				
		END
		ELSE
		BEGIN
			SET @IsAllowReopenWO = 1;
		END

		--IF(@IsPartClosed = 1)
		--BEGIN
		--	IF((@IsPaymentReceived = 1 OR  @IsPartShipped = 1))
		--	BEGIN
		--		SET @IsAllowReopenWO = 0;				
		--	END
		--	ELSE
		--	BEGIN
		--		SET @IsAllowReopenWO = 1;
		--	END
		--END
		--ELSE
		--BEGIN
		--	IF((@IsPaymentReceived = 1 OR  @IsPartShipped = 1))
		--	BEGIN
		--		SET @IsAllowReopenWO = 0;				
		--	END
		--	ELSE
		--	BEGIN
		--		SET @IsAllowReopenWO = 1;
		--	END
		--END

		--SET @IsAllowReopenWO = 1;
		
		SELECT @IsAllowReopenWO; 

 END TRY      
 BEGIN CATCH  
	--SELECT
 --   ERROR_NUMBER() AS ErrorNumber,
 --   ERROR_STATE() AS ErrorState,
 --   ERROR_SEVERITY() AS ErrorSeverity,
 --   ERROR_PROCEDURE() AS ErrorProcedure,
 --   ERROR_LINE() AS ErrorLine,
 --   ERROR_MESSAGE() AS ErrorMessage;
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
        , @AdhocComments     VARCHAR(150)    = 'USP_CheckAllowReopenWorkOrder'   
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
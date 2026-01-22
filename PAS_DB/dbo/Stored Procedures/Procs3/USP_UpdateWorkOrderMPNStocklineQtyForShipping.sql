/*********************             
 ** File:   UPDATE CUSTOMER IN WO           
 ** Author:  HEMANT SALIYA  
 ** Description: This SP Is Used to Update Customer from WO
 ** Purpose:           
 ** Date:   07-MAY-2024
    
 ************************************************************             
  ** Change History             
 ************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    07/05/2024   HEMANT SALIYA      Created  
   
exec dbo.USP_UpdateWorkOrderMPNStocklineQtyForShipping @WorkOrderPartNoId=3165, @WorkOrderId=3690,
*************************************************************/   
  
CREATE   PROCEDURE [dbo].[USP_UpdateWorkOrderMPNStocklineQtyForShipping] 	
@WorkOrderPartNoId BIGINT = NULL,
@WorkOrderId BIGINT = NULL
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY

		DECLARE @StockLineId BIGINT = 0;
		DECLARE @ModuleId BIGINT = 0;
		DECLARE @SubModuleId BIGINT = 0;
		DECLARE @IsShippingDone BIT = 0;
		DECLARE @WOTypeId INT = 0;
		DECLARE @CustomerWOTypeId INT = 0;
		DECLARE @ClosedWorkOrderStatusId INT;
		DECLARE @WorkOrderStatusId INT;
		DECLARE @WorkOrderNum VARCHAR(200);
		DECLARE @UpdatedBy VARCHAR(200);
		

		SELECT @IsShippingDone = CASE WHEN COUNT(WOS.WorkOrderShippingId) > 0 THEN 1 ELSE 0 END 
		FROM dbo.WorkOrderShipping WOS WITH (NOLOCK) 
		WHERE WOS.WorkOrderId = @WorkOrderId

		SELECT @WorkOrderNum = WorkOrderNum, @WOTypeId = WorkOrderTypeId, @WorkOrderStatusId = WorkOrderStatusId, @UpdatedBy = UpdatedBy FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId
		SELECT TOP 1 @CustomerWOTypeId = Id FROM dbo.WorkOrderType WITH (NOLOCK) WHERE [Description] = 'CUSTOMER'
		SELECT @ClosedWorkOrderStatusId = id FROM dbo.WorkOrderStatus WITH(NOLOCK) WHERE StatusCode = 'CLOSED'
		SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 15; -- For WORK ORDER Module
		SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'WORKORDERMPN';

		IF(ISNULL(@IsShippingDone,0) > 0 AND @WorkOrderStatusId = @ClosedWorkOrderStatusId)
		BEGIN
			SELECT @StockLineId = StockLineId 
			FROM dbo.WorkOrderPartNumber WOP WITH (NOLOCK) 
			WHERE WOP.ID = @workOrderPartNoId

			IF(ISNULL(@IsShippingDone,0) > 0 AND ISNULL(@WOTypeId,0) = @CustomerWOTypeId)
			BEGIN
				/* Update Stock Line Qty to Zero If Shipping is Done and Customer Stock */
				UPDATE Stockline SET 
					QuantityOnHand = CASE WHEN ISNULL(QuantityOnHand, 0) > 0 THEN ISNULL(QuantityOnHand, 0) - 1 ELSE QuantityOnHand END,
					QuantityAvailable = CASE WHEN ISNULL(QuantityAvailable, 0) > 0 THEN ISNULL(QuantityAvailable, 0) - 1 ELSE QuantityAvailable END,
					QuantityReserved = CASE WHEN ISNULL(QuantityReserved, 0) > 0 THEN ISNULL(QuantityReserved, 0) - 1 ELSE QuantityReserved END,
					UpdatedDate = GETUTCDATE(),
					Memo = CASE WHEN ISNULL(Memo,'') = '' THEN '</p> Updated Quntity From Close Work Order : ' + @WorkOrderNum + ' </p>' ELSE REPLACE(Memo, '</p>','<br>') + ' Updated Quntity From Close Work Order From Work Order : ' + @WorkOrderNum + ' </p>' END
				WHERE StockLineId = @StockLineId

				DECLARE @ActionId INT;
				
				SELECT @ActionId  = ActionId FROM StklineHistory_Action WHERE UPPER([Type]) = UPPER('CLOSEWORKORDER') -- CLOSE WORKORDER
				EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @WorkOrderId, @SubModuleId = @SubModuleId, @SubRefferenceId = @workOrderPartNoId, @ActionId = @ActionId, @Qty = 1, @UpdatedBy = @UpdatedBy;

			END
		END
 END TRY      
 BEGIN CATCH  
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
        , @AdhocComments     VARCHAR(150)    = 'USP_UpdateWorkOrderCustomerDetails'   
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
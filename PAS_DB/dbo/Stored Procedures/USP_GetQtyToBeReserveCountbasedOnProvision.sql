
/*************************************************************           
 ** File:   [USP_GetQtyToBeReserveCountbasedOnProvision]           
 ** Author:   Hemant Saliya
 ** Description: This SP is Used Get Count for Reserver Qty based on Provision
 ** Purpose:         
 ** Date:   02/22/2021        
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/22/2021   Hemant Saliya Created

 DECLARE @QtyToBeReserve INT;       
 EXECUTE USP_GetQtyToBeReserveCountbasedOnProvision 53,1, @QtyToBeReserve OUTPUT 
 
**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetQtyToBeReserveCountbasedOnProvision]    
(    
@WorkOrderMaterialsId BIGINT = NULL,
@IsFromSubWO BIT = 0,
@QtyToBeReserve INT = null OUTPUT
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
			BEGIN  				
				DECLARE @ProvisionId BIGINT;

				SELECT @ProvisionId = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'REPLACE' AND IsActive = 1 AND IsDeleted = 0;

				IF(@IsFromSubWO = 1)
				BEGIN
					PRINT 1;
					SELECT 
						@QtyToBeReserve = CASE WHEN WOM.ProvisionId <> @ProvisionId
								THEN (SELECT ISNULL(SUM(WOMS.Quantity), 0) - (ISNULL(SUM(WOMS.QtyReserved), 0) + ISNULL(SUM(WOMS.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMS WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMS.SubWorkOrderMaterialsId AND WOMS.ProvisionId = @ProvisionId)
							 WHEN WOM.ProvisionId = @ProvisionId
								THEN (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMS.Quantity), 0) - (ISNULL(SUM(WOMS.QtyReserved), 0) + ISNULL(SUM(WOMS.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMS WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMS.SubWorkOrderMaterialsId AND WOMS.ProvisionId <> @ProvisionId)
						END					
					FROM dbo.SubWorkOrderMaterials WOM WITH(NOLOCK)
					WHERE WOM.SubWorkOrderMaterialsId = @WorkOrderMaterialsId 
				END
				ELSE
				BEGIN
					PRINT 2;
					SELECT 
						@QtyToBeReserve = CASE WHEN WOM.ProvisionId <> @ProvisionId
								THEN (SELECT ISNULL(SUM(WOMS.Quantity), 0) - (ISNULL(SUM(WOMS.QtyReserved), 0) + ISNULL(SUM(WOMS.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId AND WOMS.ProvisionId = @ProvisionId)
							 WHEN WOM.ProvisionId = @ProvisionId
								THEN (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMS.Quantity), 0) - (ISNULL(SUM(WOMS.QtyReserved), 0) + ISNULL(SUM(WOMS.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId AND WOMS.ProvisionId <> @ProvisionId)
						END					
					FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)
					WHERE WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId 
				END

				SELECT @QtyToBeReserve;
			END
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetQtyToBeReserveCountbasedOnProvision' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderMaterialsId, '') + ''
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
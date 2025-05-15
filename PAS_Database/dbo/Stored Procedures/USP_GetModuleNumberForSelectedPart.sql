
/*************************************************************           
 ** File:   [USP_GetModuleNumberForSelectedPart]      
 ** Author:   Bhargav Saliya
 ** Description: This stored procedure is used to get Number as per Selected RepairOrder
 ** Purpose:         
 ** Date:   15-May-2025
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    15-May-2025   Bhargav Saliya     Created

--exec [USP_ModuleNumberForSelectedPart] @ItemMasterId = 3,@StockLineId = 198284, @ConditionId = 9, @ModuleId = 15
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetModuleNumberForSelectedPart]
@ItemMasterId BIGINT,
@StockLineId BIGINT,
@ConditionId BIGINT,
@ModuleId BIGINT
AS
BEGIN              
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED              
 SET NOCOUNT ON; 
	
DECLARE @SOModuleId BIGINT = (SELECT Moduleid FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder');
DECLARE @WOModuleId BIGINT = (SELECT Moduleid FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder');
DECLARE @SWOModuleId BIGINT = (SELECT Moduleid FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SubWorkOrder');
DECLARE @PRovisionId BIGINT = (SELECT Provisionid FROM [dbo].[Provision] WITH(NOLOCK) WHERE UPPER([Description]) = 'REPAIR');

 BEGIN TRY

 IF(@SOModuleId = @ModuleId)
 BEGIN
	SELECT 
		S.SalesOrderId,
		S.SalesOrderNumber
	FROM [dbo].[SalesOrderPartV1] SP WITH(NOLOCK)
		INNER JOIN [dbo].[SalesOrder] S WITH(NOLOCK) on S.SalesOrderId = SP.SalesOrderId
		INNER JOIN DBO.SalesOrderStocklineV1 Stk WITH (NOLOCK) ON SP.SalesOrderPartId = Stk.SalesOrderPartId
	WHERE Stk.QtyReserved = 0 AND SP.ItemMasterId = @ItemMasterId and Stk.StockLineId = @StockLineId and SP.ConditionId = @ConditionId 
 END

 ELSE IF(@WOModuleId = @ModuleId)
 BEGIN
	SELECT 
		W.WorkOrderId,
		W.WorkOrderNum
	FROM [dbo].[WorkOrder] W WITH(NOLOCK)
		INNER JOIN [dbo].[WorkOrderMaterials] WM WITH(NOLOCK) on W.WorkOrderId = WM.WorkOrderId
		INNER JOIN [dbo].[WorkOrderMaterialStockLine] WMS WITH(NOLOCK) on WM.WorkOrderMaterialsId = WMS.WorkOrderMaterialsId
	WHERE WMS.QtyReserved = 0 AND WMS.ItemMasterId = @ItemMasterId and WMS.StockLineId = @StockLineId and WMS.ConditionId = @ConditionId AND @PRovisionId = WMS.ProvisionId
 END

 ELSE IF(@SWOModuleId = @ModuleId)
 BEGIN
	SELECT 
		SW.SubWorkOrderId,
		SW.SubWorkOrderNo
	FROM [dbo].[SubWorkOrder] SW WITH(NOLOCK)
		INNER JOIN [dbo].[SubWorkOrderMaterials] SWM WITH(NOLOCK) on SW.SubWorkOrderId = SWM.SubWorkOrderId
		INNER JOIN [dbo].[SubWorkOrderMaterialStockLine] SWMS WITH(NOLOCK) on SWM.SubWorkOrderMaterialsId = SWMS.SubWorkOrderMaterialsId
	WHERE SWMS.QtyReserved = 0 AND SWMS.ItemMasterId = @ItemMasterId and SWMS.StockLineId = @StockLineId and SWMS.ConditionId = @ConditionId AND @PRovisionId = SWMS.ProvisionId
 END
	
 END TRY
 BEGIN CATCH  
   
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = 'USP_GetModuleNumberForSelectedPart',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ItemMasterId, '') AS varchar(100)) +    
            '@Parameter2 = ''' + CAST(ISNULL(@StockLineId, '') AS varchar(100)) +  
            '@Parameter3 = ''' + CAST(ISNULL(@ConditionId, '') AS varchar(100)),  
            @ApplicationName varchar(100) = 'PAS'   
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR (  
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'  
    , 16, 1, @ErrorLogID)  
  
    RETURN (1);  
	END CATCH
END
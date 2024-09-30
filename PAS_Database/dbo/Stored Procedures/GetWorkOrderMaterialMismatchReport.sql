/*************************************************************           
-- =============================================
-- Author:		Shrey Chandegara
-- Create date: 26-09-2024
-- Description:	This stored procedure is used to count UPdate Stockline Inventory mismatch.

  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    26-09-2024   Shrey Chandegara		Created
	
	EXEC [GetWorkOrderMaterialMismatchReport]
**************************************************************/

CREATE   PROCEDURE [dbo].[GetWorkOrderMaterialMismatchReport]

AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN
		SELECT
			WOM.WorkOrderMaterialsId, 
			WO.WorkOrderNum,
			WOM.WorkOrderId,
			WOM.ItemMasterId,
			IM.partnumber AS 'PartNumber',
			WOM.MasterCompanyId,
			WOM.UpdatedBy,
			C.Code AS 'Condition',
			WOM.Quantity,
			WOM.QuantityReserved,
			WOM.QuantityIssued,
			WOM.TotalReserved,
			WOM.TotalIssued,
			WOM.POId,
			WOM.PONum
		FROM WorkOrderMaterials WOM
		LEFT JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId = WOM.WorkOrderId
		LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
		LEFT JOIN [dbo].[Condition] C WITH(NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
		WHERE (WOM.QuantityReserved != (select ISNULL(SUM(WMS.QtyReserved),0) from dbo.WorkOrderMaterialstockline WMS  with (Nolock) WHERE WMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId)
		OR WOM.QuantityIssued != (select ISNULL(SUM(WMS.QtyIssued),0) from dbo.WorkOrderMaterialstockline WMS  with (Nolock) WHERE WMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId))
		AND (WOM.QuantityReserved > 0)
	END
	END TRY    
	BEGIN CATCH      
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderMaterialMismatchReport' 
            , @ProcedureParameters VARCHAR(3000)  = ''
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

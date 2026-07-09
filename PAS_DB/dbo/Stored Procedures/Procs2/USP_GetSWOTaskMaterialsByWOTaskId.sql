/*************************************************************
 ** File:   [USP_GetSWOTaskMaterialsByWOTaskId]
 ** Author: Vishal Suthar
 ** Description: This stored procedure is used to get SWO Task Instruction by SWO Task Id
 ** Purpose:
 ** Date:   03/28/2025
    
 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date				Author			Change Description
 ** --   --------			-------			--------------------------------
    1    03/28/2025			Vishal Suthar		Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0

EXEC [dbo].[USP_GetSWOTaskMaterialsByWOTaskId] 831
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetSWOTaskMaterialsByWOTaskId]
	@SubWorkOrderTaskId bigint = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT 
		--STRING_AGG(Parts.PartNumber, ',') AS PartNumbers,
		--SUM(Parts.BillingAmount) AS BillingAmount
		PartNumber AS PartNumbers, BillingAmount, PartDescription, UnitOfMeasure, Condition, Quantity
		FROM
		(
			SELECT 
				IM.PartNumber,
				CASE WHEN ISNULL(MSTL.StockLIneId, 0) > 0 THEN ISNULL(MSTL.ExtendedCost, 0) ELSE ISNULL(WOM.ExtendedCost, 0) END AS BillingAmount,
				IM.PartDescription,
				CASE WHEN SUOM.UnitOfMeasureId IS NOT NULL THEN SUOM.ShortName ELSE UOM.ShortName END AS UnitOfMeasure,
				C.Description AS Condition,
				ISNULL(WOM.Quantity, 0) AS Quantity 
			FROM DBO.SubWorkOrderMaterials WOM WITH (NOLOCK) 
			LEFT JOIN DBO.SubWorkOrderMaterialStockLine MSTL WITH (NOLOCK) ON MSTL.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND MSTL.IsDeleted = 0
			INNER JOIN DBO.ItemMaster IM WITH (NOLOCK) ON WOM.ItemMasterId = IM.ItemMasterId
			LEFT JOIN DBO.SubWorkOrderTask WOT WITH (NOLOCK) ON WOT.SubWorkOrderTaskId = WOM.TaskId AND WOT.WorkOrderId = WOM.WorkOrderId
			LEFT JOIN DBO.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
			LEFT JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
			LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId AND ISNULL(SL.IsNonStock,0) = 0
			LEFT JOIN dbo.UnitOfMeasure SUOM WITH (NOLOCK) ON SUOM.UnitOfMeasureId = SL.PurchaseUnitOfMeasureId
			WHERE WOM.IsDeleted = 0 AND WOT.SubWorkOrderTaskId = @SubWorkOrderTaskId
    
			 AND ISNULL(IM.IsNonStock,0) = 0
			 UNION ALL
    
			SELECT 
				IM.PartNumber,
				CASE WHEN ISNULL(MSTL.StockLIneId, 0) > 0 THEN ISNULL(MSTL.ExtendedCost, 0) ELSE ISNULL(WOMK.ExtendedCost, 0) END AS BillingAmount,
				IM.PartDescription,
				CASE WHEN SUOM.UnitOfMeasureId IS NOT NULL THEN SUOM.ShortName ELSE UOM.ShortName END AS UnitOfMeasure,
				CASE WHEN Stk_C.ConditionId IS NOT NULL THEN Stk_C.Description ELSE C.Description END AS Condition,
				ISNULL(WOMK.Quantity, 0) AS Quantity
			FROM [DBO].[SubWorkOrderMaterialsKitMapping] WOMKIT WITH(NOLOCK)
			INNER JOIN [dbo].[SubWorkOrderMaterialsKit] WOMK WITH(NOLOCK) ON WOMK.SubWorkOrderMaterialsKitMappingId = WOMKIT.SubWorkOrderMaterialsKitMappingId
			LEFT JOIN dbo.SubWorkOrderMaterialStockLineKit MSTL WITH (NOLOCK) ON MSTL.SubWorkOrderMaterialsKitId = WOMK.SubWorkOrderMaterialsKitId AND MSTL.IsDeleted = 0
			INNER JOIN DBO.ItemMaster IM WITH (NOLOCK) ON WOMK.ItemMasterId = IM.ItemMasterId
			LEFT JOIN DBO.SubWorkOrderTask WOT WITH (NOLOCK) ON WOT.SubWorkOrderTaskId = WOMK.TaskId AND WOT.WorkOrderId = WOMK.WorkOrderId
			LEFT JOIN DBO.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
			LEFT JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOMK.ConditionCodeId
			LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId AND ISNULL(SL.IsNonStock,0) = 0
			LEFT JOIN dbo.UnitOfMeasure SUOM WITH (NOLOCK) ON SUOM.UnitOfMeasureId = SL.PurchaseUnitOfMeasureId
			LEFT JOIN dbo.Condition Stk_C WITH (NOLOCK) ON Stk_C.ConditionId = SL.ConditionId
			WHERE WOMKIT.IsDeleted = 0 AND WOT.SubWorkOrderTaskId = @SubWorkOrderTaskId
		 AND ISNULL(IM.IsNonStock,0) = 0 ) AS Parts;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetSWOTaskMaterialsByWOTaskId'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@SubWorkOrderTaskId AS varchar(10)) ,'') +''
        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException
                @DatabaseName           =  @DatabaseName
                , @AdhocComments          =  @AdhocComments
                , @ProcedureParameters    =  @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID             =  @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
  END CATCH
END
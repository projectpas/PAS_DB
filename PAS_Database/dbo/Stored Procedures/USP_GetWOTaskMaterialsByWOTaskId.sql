/*************************************************************
 ** File:   [USP_GetWOTaskMaterialsByWOTaskId]
 ** Author: Vishal Suthar
 ** Description: This stored procedure is used to get WO Task Instruction by WO Task Id
 ** Purpose:
 ** Date:   01/17/2025
    
 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    01/17/2025   Vishal Suthar		Created

EXEC [dbo].[USP_GetWOTaskMaterialsByWOTaskId] 185
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWOTaskMaterialsByWOTaskId]
	@WorkOrderTaskId bigint = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT 
		STRING_AGG(Parts.PartNumber, ',') AS PartNumbers,
		SUM(Parts.BillingAmount) AS BillingAmount
		FROM
		(
			SELECT 
				IM.PartNumber,
				CASE WHEN ISNULL(MSTL.StockLIneId, 0) > 0 THEN ISNULL(MSTL.ExtendedCost, 0) ELSE ISNULL(WOM.ExtendedCost, 0) END AS BillingAmount
			FROM DBO.WorkOrderMaterials WOM WITH (NOLOCK) 
			LEFT JOIN DBO.WorkOrderMaterialStockLine MSTL WITH (NOLOCK) ON MSTL.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND MSTL.IsDeleted = 0
			INNER JOIN DBO.ItemMaster IM WITH (NOLOCK) ON WOM.ItemMasterId = IM.ItemMasterId
			LEFT JOIN DBO.WorkOrderTask WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOM.TaskId AND WOT.WorkOrderId = WOM.WorkOrderId
			WHERE WOM.IsDeleted = 0 AND WOT.WorkOrderTaskId = @WorkOrderTaskId
    
			UNION ALL
    
			SELECT 
				IM.PartNumber,
				CASE WHEN ISNULL(MSTL.StockLIneId, 0) > 0 THEN ISNULL(MSTL.ExtendedCost, 0) ELSE ISNULL(WOMK.ExtendedCost, 0) END AS BillingAmount
			FROM [DBO].[WorkOrderMaterialsKitMapping] WOMKIT WITH(NOLOCK)
			INNER JOIN [dbo].[WorkOrderMaterialsKit] WOMK WITH(NOLOCK) ON WOMK.WorkOrderMaterialsKitMappingId = WOMKIT.WorkOrderMaterialsKitMappingId
			LEFT JOIN dbo.WorkOrderMaterialStockLineKit MSTL WITH (NOLOCK) ON MSTL.WorkOrderMaterialsKitId = WOMK.WorkOrderMaterialsKitId AND MSTL.IsDeleted = 0
			INNER JOIN DBO.ItemMaster IM WITH (NOLOCK) ON WOMK.ItemMasterId = IM.ItemMasterId
			LEFT JOIN DBO.WorkOrderTask WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOMK.TaskId AND WOT.WorkOrderId = WOMK.WorkOrderId
			WHERE WOMKIT.IsDeleted = 0 AND WOT.WorkOrderTaskId = @WorkOrderTaskId
		) AS Parts;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetWOTaskMaterialsByWOTaskId'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@WorkOrderTaskId AS varchar(10)) ,'') +''
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
/*************************************************************
 ** File:   [GetCustomerSuppliedPartsByWorkOrder]
 ** Author: Rajesh Gami
 ** Description: Receive Customer Supplied Materials: the Customer Supplied Part (CSP) material lines of one Work Order with required / received / remaining qty
 ** Date:   12-Nov-2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author        Change Description
 ** --   --------       -------       --------------------------------
    1    12-Nov-2026    RAJESH GAMI   [PN-18508] Created
 **************************************************************
-- EXEC dbo.GetCustomerSuppliedPartsByWorkOrder @WorkFlowWorkOrderId = 100, @MasterCompanyId = 1
************************************************************************/

CREATE OR ALTER PROCEDURE [dbo].[GetCustomerSuppliedPartsByWorkOrder]
	@WorkFlowWorkOrderId BIGINT,
	@MasterCompanyId INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		SELECT
			WOM.WorkOrderMaterialsId,
			WOM.WorkOrderId,
			WOM.WorkFlowWorkOrderId,
			WOM.ItemMasterId,
			IM.partnumber AS PartNumber,
			IM.PartDescription AS PartDescription,
			IM.ManufacturerId,
			IM.ManufacturerName AS Manufacturer,
			WOM.ConditionCodeId AS ConditionId,
			C.[Description] AS Condition,
			WOM.UnitOfMeasureId,
			UOM.ShortName AS UnitOfMeasure,
			ISNULL(IM.isSerialized, 0) AS IsSerialized,
			WOM.Quantity AS QtyRequired,
			ISNULL(RCV.QtyReceived, 0) AS QtyReceived,
			WOM.Quantity - ISNULL(RCV.QtyReceived, 0) AS QtyRemaining
		FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)
			INNER JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
			LEFT JOIN dbo.Condition C WITH(NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
			LEFT JOIN dbo.UnitOfMeasure UOM WITH(NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
			OUTER APPLY (SELECT SUM(STK.Quantity) AS QtyReceived FROM dbo.Stockline STK WITH(NOLOCK)
						 WHERE STK.CustomerSuppliedWorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND STK.IsDeleted = 0) RCV
		WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId
			AND WOM.MasterCompanyId = @MasterCompanyId
			AND ISNULL(WOM.IsCustomerSuppliedPart, 0) = 1
			AND WOM.IsActive = 1 AND WOM.IsDeleted = 0
			AND ISNULL(WOM.IsAltPart, 0) = 0 AND ISNULL(WOM.IsEquPart, 0) = 0
		ORDER BY IM.partnumber;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'GetCustomerSuppliedPartsByWorkOrder'
			, @ProcedureParameters VARCHAR(3000) = '@WorkFlowWorkOrderId = ' + CAST(ISNULL(@WorkFlowWorkOrderId, 0) AS VARCHAR(20)) + ' @MasterCompanyId = ' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(20))
			, @ApplicationName VARCHAR(100) = 'PAS'
------------------------------------PLEASE DO NOT EDIT BELOW--------------------------------------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters, @ApplicationName = @ApplicationName, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN(1);
	END CATCH
END

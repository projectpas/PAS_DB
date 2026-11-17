/*************************************************************
 ** File:   [GetCustomerSuppliedWorkOrders]
 ** Author: Rajesh Gami
 ** Description: Receive Customer Supplied Materials: open Work Orders (WO - MPN) of the selected customer
 ** Date:   12-Nov-2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author        Change Description
 ** --   --------       -------       --------------------------------
    1    12-Nov-2026    RAJESH GAMI   [PN-18508] Created
    2    16-Nov-2026    RAJESH GAMI   [PN-18508] List all open WOs of the customer (no Customer Supplied material line filter)
 **************************************************************
-- EXEC dbo.GetCustomerSuppliedWorkOrders @CustomerId = 3, @MasterCompanyId = 1
************************************************************************/

CREATE PROCEDURE [dbo].[GetCustomerSuppliedWorkOrders]
	@CustomerId BIGINT,
	@MasterCompanyId INT,
	@SearchText NVARCHAR(100) = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		SELECT DISTINCT
			WO.WorkOrderId,
			WO.WorkOrderNum,
			WOPN.ID AS WorkOrderPartNoId,
			WOWF.WorkFlowWorkOrderId,
			IM.partnumber AS PartNumber,
			IM.PartDescription AS PartDescription,
			WOS.[Status] AS WorkOrderStatus,
			WO.WorkOrderNum + ' - ' + ISNULL(IM.partnumber, '') AS Label
		FROM dbo.WorkOrder WO WITH(NOLOCK)
			INNER JOIN dbo.WorkOrderPartNumber WOPN WITH(NOLOCK) ON WOPN.WorkOrderId = WO.WorkOrderId AND ISNULL(WOPN.IsClosed, 0) = 0
			INNER JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOWF.WorkOrderId = WO.WorkOrderId AND WOWF.WorkOrderPartNoId = WOPN.ID
			INNER JOIN dbo.WorkOrderStatus WOS WITH(NOLOCK) ON WOS.Id = WOPN.WorkOrderStatusId
			LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WOPN.ItemMasterId
		WHERE WO.CustomerId = @CustomerId
			AND WO.MasterCompanyId = @MasterCompanyId
			AND WO.IsActive = 1 AND WO.IsDeleted = 0
			AND WOPN.WorkOrderStatusId NOT IN (SELECT WS.Id FROM dbo.WorkOrderStatus WS WITH(NOLOCK) WHERE WS.[Description] IN ('Closed', 'Canceled'))
			AND (ISNULL(@SearchText, '') = '' OR WO.WorkOrderNum LIKE '%' + @SearchText + '%' OR IM.partnumber LIKE '%' + @SearchText + '%')
		ORDER BY WO.WorkOrderNum;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'GetCustomerSuppliedWorkOrders'
			, @ProcedureParameters VARCHAR(3000) = '@CustomerId = ' + CAST(ISNULL(@CustomerId, 0) AS VARCHAR(20)) + ' @MasterCompanyId = ' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(20))
			, @ApplicationName VARCHAR(100) = 'PAS'
------------------------------------PLEASE DO NOT EDIT BELOW--------------------------------------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters, @ApplicationName = @ApplicationName, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN(1);
	END CATCH
END

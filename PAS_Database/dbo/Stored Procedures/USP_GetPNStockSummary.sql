/*************************************************************
 ** File:  [USP_GetPNStockSummary]
 ** Author:  SAHDEV SALIYA
 ** Description: Get quantities by Condition across the phases of inventory
 **              (On Hand, On Order, Open Sales, On Repair, On Lease, On WO,
 **              YTD Sales, Prior YR Sales) for a single Item Master, for the
 **              Parts Inquiry "Stock Summary" quick view.
 ** Date:   01-Sep-2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** --   --------		-------				--------------------------------
    1    01-Sep-2026	SAHDEV SALIYA		Created
    2    03-Sep-2026	SAHDEV SALIYA		Aligned OnHand/OnOrder/OpenSales/OnRepair/OnWO/
                                                YtdSales/PriorYrSales to confirmed business
                                                definitions

--  EXEC [dbo].[USP_GetPNStockSummary] @ItemMasterId = 95632, @MasterCompanyId = 1

************************************************************************/
CREATE    PROCEDURE [dbo].[USP_GetPNStockSummary]
	@ItemMasterId BIGINT,
	@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN

		DECLARE @YtdFrom DATE = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
		DECLARE @YtdTo DATE = CAST(GETDATE() AS DATE);
		DECLARE @ClosedStatusId INT;
		DECLARE @CancelledStatusId INT;
		DECLARE @ExpiredStatusId INT;
		DECLARE @RejectedStatusId INT;
		DECLARE @ShippedStatusId INT;
		DECLARE @InvoicedStatusId INT;
		SELECT @ClosedStatusId = [Id] FROM [dbo].[MasterSalesOrderStatus] WITH (NOLOCK) WHERE [Name] = 'Closed';
		SELECT @CancelledStatusId = [Id] FROM [dbo].[MasterSalesOrderStatus] WITH (NOLOCK) WHERE [Name] = 'Cancelled';
		SELECT @ExpiredStatusId = [Id] FROM [dbo].[MasterSalesOrderStatus] WITH (NOLOCK) WHERE [Name] = 'Expired';
		SELECT @RejectedStatusId = [Id] FROM [dbo].[MasterSalesOrderStatus] WITH (NOLOCK) WHERE [Name] = 'Rejected';
		SELECT @ShippedStatusId = [Id] FROM [dbo].[MasterSalesOrderStatus] WITH (NOLOCK) WHERE [Name] = 'Shipped';
		SELECT @InvoicedStatusId = [Id] FROM [dbo].[MasterSalesOrderStatus] WITH (NOLOCK) WHERE [Name] = 'Invoiced';

		SELECT
			CN.ConditionId,
			CN.Code AS ConditionCode,
			CN.Description AS ConditionDescription,

			ISNULL((
				SELECT SUM(ISNULL(stl.QuantityAvailable, 0))
				FROM dbo.Stockline stl WITH (NOLOCK)
				WHERE stl.ItemMasterId = @ItemMasterId AND stl.ConditionId = CN.ConditionId
					AND stl.MasterCompanyId = @MasterCompanyId AND stl.IsActive = 1
					AND ISNULL(stl.IsParent, 0) = 1 AND ISNULL(stl.IsDeleted,0) = 0
					AND ISNULL(stl.IsCustomerStock, 0) = 0
			), 0) AS OnHand,

			ISNULL((
				SELECT SUM(ISNULL(pop.QuantityBackOrdered, 0))
				FROM dbo.PurchaseOrderPart pop WITH (NOLOCK)
				INNER JOIN dbo.PurchaseOrder po WITH (NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId
				WHERE pop.ItemMasterId = @ItemMasterId AND pop.ConditionId = CN.ConditionId
					AND ISNULL(pop.isParent, 0) = 1 AND ISNULL(pop.IsDeleted, 0) = 0
					AND po.IsDeleted = 0 AND po.MasterCompanyId = @MasterCompanyId
					-- Open POs (nothing received yet) + remaining Receive Qty from Fulfilling
					-- (partially received) POs; Pending POs are intentionally excluded.
					AND po.[Status] IN ('Open', 'Fulfilling')
			), 0) AS OnOrder,

			ISNULL((
				SELECT SUM(ISNULL(sop.QtyReserved, 0))
				FROM dbo.SalesOrderPartV1 sop WITH (NOLOCK)
				INNER JOIN dbo.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
				WHERE sop.ItemMasterId = @ItemMasterId AND sop.ConditionId = CN.ConditionId
					AND sop.IsDeleted = 0 AND so.IsDeleted = 0 AND so.MasterCompanyId = @MasterCompanyId
					-- exclude Closed(2)/Cancelled(5)/Expired(6)/Rejected(9)/Shipped(11)/Invoiced(12)
					AND so.StatusId NOT IN (@ClosedStatusId, @CancelledStatusId, @ExpiredStatusId, @RejectedStatusId, @ShippedStatusId, @InvoicedStatusId)
			), 0) AS OpenSales,

			ISNULL((
				SELECT SUM(ISNULL(rop.QuantityOrdered, 0) - ISNULL(rosi.QtyShipped, 0))
				FROM dbo.RepairOrderPart rop WITH (NOLOCK)
				INNER JOIN dbo.RepairOrder ro WITH (NOLOCK) ON ro.RepairOrderId = rop.RepairOrderId
				LEFT JOIN (
					SELECT RepairOrderPartId, SUM(QtyShipped) AS QtyShipped
					FROM dbo.RepairOrderShippingItem WITH (NOLOCK)
					WHERE ISNULL(IsDeleted, 0) = 0
					GROUP BY RepairOrderPartId
				) rosi ON rosi.RepairOrderPartId = rop.RepairOrderPartRecordId
				WHERE rop.ItemMasterId = @ItemMasterId AND rop.ConditionId = CN.ConditionId
					AND ISNULL(rop.IsParent, 0) = 1 AND rop.IsDeleted = 0
					AND ro.MasterCompanyId = @MasterCompanyId
					-- Open ROs (nothing shipped back yet) + remaining Receive Qty from Fulfilling
					-- (partially received) ROs; Pending/Shipped ROs are intentionally excluded.
					AND ro.[Status] IN ('Open', 'Fulfilling')
			), 0) AS OnRepair,

			0 AS OnLease,

			ISNULL((
				SELECT SUM(ISNULL(QuantityReserved, 0) + ISNULL(QuantityIssued, 0))
				FROM (
					SELECT QuantityReserved, QuantityIssued FROM dbo.WorkOrderMaterials WITH (NOLOCK)
					WHERE ItemMasterId = @ItemMasterId AND ConditionCodeId = CN.ConditionId
						AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0
					UNION ALL
					SELECT QuantityReserved, QuantityIssued FROM dbo.WorkOrderMaterialsKit WITH (NOLOCK)
					WHERE ItemMasterId = @ItemMasterId AND ConditionCodeId = CN.ConditionId
						AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0
					UNION ALL
					SELECT QuantityReserved, QuantityIssued FROM dbo.SubWorkOrderMaterials WITH (NOLOCK)
					WHERE ItemMasterId = @ItemMasterId AND ConditionCodeId = CN.ConditionId
						AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0
					UNION ALL
					SELECT QuantityReserved, QuantityIssued FROM dbo.SubWorkOrderMaterialsKit WITH (NOLOCK)
					WHERE ItemMasterId = @ItemMasterId AND ConditionCodeId = CN.ConditionId
						AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0
				) wo
			), 0) AS OnWO,

			ISNULL((
				SELECT SUM(ISNULL(sop.QtyOrder, 0))
				FROM dbo.SalesOrderPartV1 sop WITH (NOLOCK)
				INNER JOIN dbo.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
				WHERE sop.ItemMasterId = @ItemMasterId AND sop.ConditionId = CN.ConditionId
					AND ISNULL(sop.IsDeleted, 0) = 0 AND ISNULL(so.IsDeleted, 0) = 0 AND so.MasterCompanyId = @MasterCompanyId
					AND so.StatusId = @ClosedStatusId
					AND CAST(so.CreatedDate AS DATE) BETWEEN CAST(@YtdFrom AS DATE) AND CAST(@YtdTo AS DATE)
			), 0) AS YtdSales,

			ISNULL((
				SELECT SUM(ISNULL(sop.QtyOrder, 0))
				FROM dbo.SalesOrderPartV1 sop WITH (NOLOCK)
				INNER JOIN dbo.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
				WHERE sop.ItemMasterId = @ItemMasterId AND sop.ConditionId = CN.ConditionId
					AND ISNULL(sop.IsDeleted, 0) = 0 AND ISNULL(so.IsDeleted, 0) = 0 AND so.MasterCompanyId = @MasterCompanyId
					AND so.StatusId = @ClosedStatusId
					AND CAST(so.CreatedDate AS DATE) < CAST(@YtdFrom AS DATE)
			), 0) AS PriorYrSales

		FROM dbo.Condition CN WITH (NOLOCK)
		WHERE CN.MasterCompanyId = @MasterCompanyId AND CN.IsActive = 1 AND ISNULL(CN.IsDeleted, 0) = 0
		ORDER BY CN.SequenceNo;

	END
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments VARCHAR(150)			= 'USP_GetPNStockSummary'
		, @ProcedureParameters VARCHAR(3000)	= '@ItemMasterId = '''+ CAST(ISNULL(@ItemMasterId, '') AS VARCHAR(100)) +
												  '@MasterCompanyId = '''+ CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) + ''
		, @ApplicationName VARCHAR(100)			= 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------
		exec spLogException
				@DatabaseName				= @DatabaseName
				, @AdhocComments			= @AdhocComments
				, @ProcedureParameters		= @ProcedureParameters
				, @ApplicationName			=  @ApplicationName
				, @ErrorLogID				= @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END
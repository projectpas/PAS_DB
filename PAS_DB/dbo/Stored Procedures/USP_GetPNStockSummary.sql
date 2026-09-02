/*************************************************************
 ** File:  [USP_GetPNStockSummary]
 ** Author:  SAHDEV SALIYA
 ** Description: Get quantities by Condition across the phases of inventory
 **              (On Hand, On Order, Open Sales, On Repair, On Lease, On WO,
 **              YTD Sales, Prior YR Sales) for a single Item Master, for the
 **              Parts Inquiry "Stock Summary" quick view.
 ** Date:   02-Sep-2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** --   --------		-------				--------------------------------
    1    02-Sep-2026	SAHDEV SALIYA		Created

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
		DECLARE @PriorYrFrom DATE = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
		DECLARE @PriorYrTo DATE = DATEFROMPARTS(YEAR(GETDATE()) - 1, 12, 31);
		DECLARE @SOModuleId INT;
		DECLARE @ClosedStatusId INT;
		DECLARE @CancelledStatusId INT;
		DECLARE @ExpiredStatusId INT;
		DECLARE @RejectedStatusId INT;
		DECLARE @ShippedStatusId INT;
		DECLARE @InvoicedStatusId INT;
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'SalesOrder';
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
				SELECT SUM(ISNULL(stl.QuantityOnHand, 0))
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
					AND po.[Status] NOT IN ('Closed', 'Canceled')
			), 0) AS OnOrder,

			ISNULL((
				SELECT SUM(ISNULL(sop.QtyOrder, 0))
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
					AND ro.[Status] NOT IN ('Closed', 'Canceled')
			), 0) AS OnRepair,

			0 AS OnLease,

			ISNULL((
				SELECT SUM(ISNULL(stl.QuantityReserved, 0) + ISNULL(stl.QuantityIssued, 0))
				FROM dbo.Stockline stl WITH (NOLOCK)
				WHERE stl.ItemMasterId = @ItemMasterId AND stl.ConditionId = CN.ConditionId
					AND stl.MasterCompanyId = @MasterCompanyId AND stl.IsActive = 1
					AND ISNULL(stl.IsParent, 0) = 1 AND stl.IsDeleted = 0
					AND ISNULL(stl.IsCustomerStock, 0) = 0
			), 0) AS OnWO,

			ISNULL((
				SELECT SUM(ISNULL(sop.QtyOrder, 0))
				FROM dbo.SalesOrderPartV1 sop WITH (NOLOCK)
				INNER JOIN dbo.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
				INNER JOIN dbo.BillingInvoicingItems bii WITH (NOLOCK) ON bii.SubReferenceId = sop.SalesOrderPartId
					AND ISNULL(bii.IsPerformaInvoice, 0) = 0 AND bii.ModuleId = @SOModuleId
				INNER JOIN dbo.BillingInvoicing bi WITH (NOLOCK) ON bi.BillingInvoicingId = bii.BillingInvoicingId
					AND bi.InvoiceStatus = 'Invoiced' AND ISNULL(bi.IsPerformaInvoice, 0) = 0
				WHERE sop.ItemMasterId = @ItemMasterId AND sop.ConditionId = CN.ConditionId
					AND sop.IsDeleted = 0 AND so.MasterCompanyId = @MasterCompanyId
					AND CAST(bi.InvoiceDate AS DATE) BETWEEN @YtdFrom AND @YtdTo
			), 0) AS YtdSales,

			ISNULL((
				SELECT SUM(ISNULL(sop.QtyOrder, 0))
				FROM dbo.SalesOrderPartV1 sop WITH (NOLOCK)
				INNER JOIN dbo.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
				INNER JOIN dbo.BillingInvoicingItems bii WITH (NOLOCK) ON bii.SubReferenceId = sop.SalesOrderPartId
					AND ISNULL(bii.IsPerformaInvoice, 0) = 0 AND bii.ModuleId = @SOModuleId
				INNER JOIN dbo.BillingInvoicing bi WITH (NOLOCK) ON bi.BillingInvoicingId = bii.BillingInvoicingId
					AND bi.InvoiceStatus = 'Invoiced' AND ISNULL(bi.IsPerformaInvoice, 0) = 0
				WHERE sop.ItemMasterId = @ItemMasterId AND sop.ConditionId = CN.ConditionId
					AND sop.IsDeleted = 0 AND so.MasterCompanyId = @MasterCompanyId
					AND CAST(bi.InvoiceDate AS DATE) BETWEEN @PriorYrFrom AND @PriorYrTo
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
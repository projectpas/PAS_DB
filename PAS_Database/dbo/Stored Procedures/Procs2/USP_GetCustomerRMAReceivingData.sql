/*************************************************************
 ** File:   [USP_GetCustomerRMAReceivingData]
 ** Author:   Rajesh Gami
 ** Description: Receiving Customer RMA screen (app-receiving-customer-rma) data
 **              Result set 1 : RMA parts (CustomerRMADeatils) with Qty / Qty Received / Qty Pending and
 **                             default stockline values taken from the original (sold) stockline
 **              Result set 2 : Stocklines already received for this RMA (Stockline.RMADeatilsId)
 ** Purpose:
 ** Date:   04-Nov-2026

 ** PARAMETERS: @RMAHeaderId BIGINT

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    04-Nov-2026  RAJESH GAMI		[PN-18254] Created
    2    05-Nov-2026  RAJESH GAMI		[PN-18254] Possible Warranty per part (same rule as GetWorkOrderPartWarranty:
                                        same part + serial shipped on a WO in the last 1 year, not proforma)
    3    05-Nov-2026  RAJESH GAMI		[PN-18254] Reason from RMAReason (RMAReasonId); Site / Warehouse / Location / Shelf / Bin default
                                        from the original stockline, else from Item Master (same parent chain); GL 0 = not set
    4    12-Nov-2026  RAJESH GAMI		[PN-18552] Parts also return Item Master IsExpirationDateAvailable / IsManufacturingDateAvailable /
                                        IsTagDateAvailable (Exp / Mfr / Tag Date required, same as Receiving PO)

 EXEC [dbo].[USP_GetCustomerRMAReceivingData] 10
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCustomerRMAReceivingData]
	@RMAHeaderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		DECLARE @WorkOrderModuleId INT;
		SELECT @WorkOrderModuleId = [ModuleId] FROM [dbo].[Module] WITH (NOLOCK) WHERE [ModuleName] = 'WorkOrder';

		/*------------------------------------------------------------------
		  1. RMA parts
		------------------------------------------------------------------*/
		SELECT
			RMADetail.[RMADeatilsId],
			RMADetail.[RMAHeaderId],
			RMADetail.[ItemMasterId],
			RMADetail.[PartNumber],
			RMADetail.[PartDescription],
			RMADetail.[AltPartNumber],
			RMADetail.[CustPartNumber],
			ISNULL(PartItemMaster.[isSerialized], 0) AS [IsSerialized],
			ISNULL(PartItemMaster.[isTimeLife], 0) AS [IsTimeLife],
			ISNULL(PartItemMaster.[IsExpirationDateAvailable], 0) AS [IsExpirationDateAvailable],
			ISNULL(PartItemMaster.[IsManufacturingDateAvailable], 0) AS [IsManufacturingDateAvailable],
			ISNULL(PartItemMaster.[IsTagDateAvailable], 0) AS [IsTagDateAvailable],
			ISNULL(OriginalStockline.[ManufacturerId], PartItemMaster.[ManufacturerId]) AS [ManufacturerId],
			ISNULL(OriginalStockline.[Manufacturer], PartItemMaster.[ManufacturerName]) AS [ManufacturerName],
			RMADetail.[StocklineId] AS [OriginalStocklineId],
			RMADetail.[StocklineNumber] AS [OriginalStocklineNumber],
			RMADetail.[ControlNumber] AS [OriginalControlNumber],
			RMADetail.[ControlId] AS [OriginalControlId],
			RMADetail.[SerialNumber] AS [OriginalSerialNumber],
			RMADetail.[ReferenceId],
			RMADetail.[ReferenceNo],
			RMADetail.[isWorkOrder] AS [IsWorkOrder],
			RMADetail.[RMAReasonId],
			ISNULL(NULLIF(RMADetail.[RMAReason], ''), RMAReasonMaster.[Reason]) AS [RMAReason],
			RMADetail.[Notes],
			ISNULL(RMADetail.[UnitPrice], 0) AS [UnitPrice],
			ISNULL(RMADetail.[Qty], 0) AS [Qty],
			ISNULL(RMADetail.[QtyReceived], 0) AS [QtyReceived],
			CASE WHEN ISNULL(RMADetail.[Qty], 0) - ISNULL(RMADetail.[QtyReceived], 0) > 0
				 THEN ISNULL(RMADetail.[Qty], 0) - ISNULL(RMADetail.[QtyReceived], 0) ELSE 0 END AS [QtyPending],
			-- defaults for the new stockline (from the original stockline)
			OriginalStockline.[ConditionId],
			OriginalStockline.[Condition],
			DefaultSite.[SiteId],
			DefaultWarehouse.[WarehouseId],
			DefaultLocation.[LocationId],
			DefaultShelf.[ShelfId],
			DefaultBin.[BinId],
			CASE WHEN ISNULL(OriginalStockline.[GLAccountId], 0) > 0 THEN OriginalStockline.[GLAccountId] ELSE PartItemMaster.[GLAccountId] END AS [GLAccountId],
			CASE WHEN ISNULL(OriginalStockline.[GLAccountId], 0) > 0 THEN OriginalStockline.[GlAccountName] ELSE PartItemMaster.[GLAccount] END AS [GLAccountName],
			ISNULL(OriginalStockline.[UnitCost], 0) AS [UnitCost],
			ISNULL(OriginalStockline.[StockUnitOfMeasureId], OriginalStockline.[PurchaseUnitOfMeasureId]) AS [UnitOfMeasureId],
			ISNULL(OriginalStockline.[StockUnitOfMeasure], OriginalStockline.[UnitOfMeasure]) AS [UnitOfMeasure],
			OriginalStockline.[ManufacturerLotNumber],
			OriginalStockline.[ManufacturingBatchNumber],
			OriginalStockline.[ManufacturingDate],
			OriginalStockline.[ExpirationDate],
			OriginalStockline.[PartCertificationNumber],
			OriginalStockline.[CertifiedDate],
			OriginalStockline.[CertTypeId],
			OriginalStockline.[CertType],
			OriginalStockline.[TagDate],
			OriginalStockline.[TagTypeId],
			OriginalStockline.[TagType],
			-- Possible Warranty (same rule as GetWorkOrderPartWarranty)
			CAST(CASE WHEN WarrantyWorkOrder.[WorkOrderNum] IS NULL THEN 0 ELSE 1 END AS BIT) AS [IsPossibleWarranty],
			WarrantyWorkOrder.[PartNumber] AS [WarrantyPartNumber],
			WarrantyWorkOrder.[StockLineNumber] AS [WarrantyStockLineNumber],
			WarrantyWorkOrder.[WorkOrderNum] AS [WarrantyWorkOrderNum],
			WarrantyWorkOrder.[WorkScope] AS [WarrantyWorkScope],
			WarrantyWorkOrder.[OpenDate] AS [WarrantyOpenDate],
			WarrantyWorkOrder.[ShipDate] AS [WarrantyShipDate]
		FROM [dbo].[CustomerRMADeatils] RMADetail WITH (NOLOCK)
			LEFT JOIN [dbo].[Stockline] OriginalStockline WITH (NOLOCK) ON OriginalStockline.[StockLineId] = RMADetail.[StocklineId]
			LEFT JOIN [dbo].[ItemMaster] PartItemMaster WITH (NOLOCK) ON PartItemMaster.[ItemMasterId] = RMADetail.[ItemMasterId]
			LEFT JOIN [dbo].[RMAReason] RMAReasonMaster WITH (NOLOCK) ON RMAReasonMaster.[RMAReasonId] = RMADetail.[RMAReasonId]
			-- default location: original stockline value, else Item Master value when its parent matches the chosen parent
			CROSS APPLY (SELECT CASE WHEN ISNULL(OriginalStockline.[SiteId], 0) > 0 THEN OriginalStockline.[SiteId]
									 WHEN ISNULL(PartItemMaster.[SiteId], 0) > 0 THEN PartItemMaster.[SiteId] END AS [SiteId]) DefaultSite
			CROSS APPLY (SELECT CASE WHEN ISNULL(OriginalStockline.[WarehouseId], 0) > 0 AND OriginalStockline.[SiteId] = DefaultSite.[SiteId] THEN OriginalStockline.[WarehouseId]
									 WHEN ISNULL(PartItemMaster.[WarehouseId], 0) > 0 AND PartItemMaster.[SiteId] = DefaultSite.[SiteId] THEN PartItemMaster.[WarehouseId] END AS [WarehouseId]) DefaultWarehouse
			CROSS APPLY (SELECT CASE WHEN ISNULL(OriginalStockline.[LocationId], 0) > 0 AND OriginalStockline.[WarehouseId] = DefaultWarehouse.[WarehouseId] THEN OriginalStockline.[LocationId]
									 WHEN ISNULL(PartItemMaster.[LocationId], 0) > 0 AND PartItemMaster.[WarehouseId] = DefaultWarehouse.[WarehouseId] THEN PartItemMaster.[LocationId] END AS [LocationId]) DefaultLocation
			CROSS APPLY (SELECT CASE WHEN ISNULL(OriginalStockline.[ShelfId], 0) > 0 AND OriginalStockline.[LocationId] = DefaultLocation.[LocationId] THEN OriginalStockline.[ShelfId]
									 WHEN ISNULL(PartItemMaster.[ShelfId], 0) > 0 AND PartItemMaster.[LocationId] = DefaultLocation.[LocationId] THEN PartItemMaster.[ShelfId] END AS [ShelfId]) DefaultShelf
			CROSS APPLY (SELECT CASE WHEN ISNULL(OriginalStockline.[BinId], 0) > 0 AND OriginalStockline.[ShelfId] = DefaultShelf.[ShelfId] THEN OriginalStockline.[BinId]
									 WHEN ISNULL(PartItemMaster.[BinId], 0) > 0 AND PartItemMaster.[ShelfId] = DefaultShelf.[ShelfId] THEN PartItemMaster.[BinId] END AS [BinId]) DefaultBin
			OUTER APPLY (SELECT TOP 1
							WorkOrderHeader.[WorkOrderNum],
							WorkOrderPart.[WorkScope],
							WorkOrderHeader.[OpenDate],
							WorkOrderShip.[ShipDate],
							WorkOrderStockline.[StockLineNumber],
							WorkOrderItemMaster.[PartNumber]
						 FROM [dbo].[WorkOrderShipping] WorkOrderShip WITH (NOLOCK)
							INNER JOIN [dbo].[WorkOrderShippingItem] WorkOrderShipItem WITH (NOLOCK) ON WorkOrderShipItem.[WorkOrderShippingId] = WorkOrderShip.[WorkOrderShippingId]
							INNER JOIN [dbo].[WorkOrderPartNumber] WorkOrderPart WITH (NOLOCK) ON WorkOrderPart.[WorkOrderId] = WorkOrderShip.[WorkOrderId] AND WorkOrderPart.[ID] = WorkOrderShipItem.[WorkOrderPartNumId]
							INNER JOIN [dbo].[WorkOrder] WorkOrderHeader WITH (NOLOCK) ON WorkOrderHeader.[WorkOrderId] = WorkOrderShip.[WorkOrderId]
							INNER JOIN [dbo].[ItemMaster] WorkOrderItemMaster WITH (NOLOCK) ON WorkOrderItemMaster.[ItemMasterId] = WorkOrderPart.[ItemMasterId]
							INNER JOIN [dbo].[Stockline] WorkOrderStockline WITH (NOLOCK) ON WorkOrderStockline.[StockLineId] = WorkOrderPart.[StockLineId] AND WorkOrderStockline.[IsParent] = 1
							LEFT JOIN [dbo].[BillingInvoicing] WorkOrderInvoice WITH (NOLOCK) ON WorkOrderInvoice.[ReferenceId] = WorkOrderShip.[WorkOrderId] AND WorkOrderInvoice.[ModuleId] = @WorkOrderModuleId
							LEFT JOIN [dbo].[BillingInvoicingItems] WorkOrderInvoiceItem WITH (NOLOCK) ON WorkOrderInvoiceItem.[BillingInvoicingId] = WorkOrderInvoice.[BillingInvoicingId] AND WorkOrderInvoiceItem.[ModuleId] = @WorkOrderModuleId
						 WHERE WorkOrderPart.[ItemMasterId] = RMADetail.[ItemMasterId]
						   AND WorkOrderStockline.[isSerialized] = 1
						   AND ISNULL(WorkOrderStockline.[SerialNumber], '') <> ''
						   AND WorkOrderStockline.[SerialNumber] = ISNULL(NULLIF(OriginalStockline.[SerialNumber], ''), RMADetail.[SerialNumber])
						   AND WorkOrderShip.[ShipDate] > DATEADD(YEAR, -1, GETUTCDATE())
						   AND ISNULL(WorkOrderInvoiceItem.[IsPerformaInvoice], 0) = 0
						 ORDER BY WorkOrderShip.[ShipDate] DESC) WarrantyWorkOrder
		WHERE RMADetail.[RMAHeaderId] = @RMAHeaderId
		  AND ISNULL(RMADetail.[IsDeleted], 0) = 0
		ORDER BY RMADetail.[RMADeatilsId];

		/*------------------------------------------------------------------
		  2. Stocklines received for this RMA
		------------------------------------------------------------------*/
		SELECT
			ReceivedStockline.[StockLineId],
			ReceivedStockline.[RMADeatilsId],
			ReceivedStockline.[StockLineNumber],
			ReceivedStockline.[ControlNumber],
			ReceivedStockline.[IdNumber],
			ReceivedStockline.[PartNumber],
			ReceivedStockline.[PNDescription] AS [PartDescription],
			ReceivedStockline.[SerialNumber],
			ReceivedStockline.[Condition],
			ISNULL(ReceivedStockline.[Quantity], 0) AS [Quantity],
			ISNULL(ReceivedStockline.[QuantityOnHand], 0) AS [QuantityOnHand],
			ISNULL(ReceivedStockline.[QuantityAvailable], 0) AS [QuantityAvailable],
			ISNULL(ReceivedStockline.[UnitCost], 0) AS [UnitCost],
			ISNULL(ReceivedStockline.[UnitCost], 0) * ISNULL(ReceivedStockline.[Quantity], 0) AS [ExtendedCost],
			ISNULL(ReceivedStockline.[StockUnitOfMeasure], ReceivedStockline.[UnitOfMeasure]) AS [UnitOfMeasure],
			ReceivedStockline.[ReceiverNumber],
			ReceivedStockline.[ReceivedDate],
			ReceivedStockline.[Site],
			ReceivedStockline.[Warehouse],
			ReceivedStockline.[Location],
			ReceivedStockline.[Shelf],
			ReceivedStockline.[Bin],
			ReceivedStockline.[GlAccountName] AS [GLAccountName],
			ISNULL(ReceivedStockline.[IsCustomerStock], 0) AS [IsCustomerStock],
			ReceivedStockline.[CreatedBy],
			ReceivedStockline.[CreatedDate]
		FROM [dbo].[Stockline] ReceivedStockline WITH (NOLOCK)
			INNER JOIN [dbo].[CustomerRMADeatils] RMADetail WITH (NOLOCK) ON RMADetail.[RMADeatilsId] = ReceivedStockline.[RMADeatilsId]
		WHERE RMADetail.[RMAHeaderId] = @RMAHeaderId
		  AND ISNULL(RMADetail.[IsDeleted], 0) = 0
		  AND ISNULL(ReceivedStockline.[IsDeleted], 0) = 0
		ORDER BY ReceivedStockline.[StockLineId];

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetCustomerRMAReceivingData'
			, @ProcedureParameters VARCHAR(3000) = '@RMAHeaderId = ''' + CAST(ISNULL(@RMAHeaderId, '') AS VARCHAR(100))
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			  @DatabaseName = @DatabaseName
			, @AdhocComments = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName = @ApplicationName
			, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN(1);
	END CATCH
END

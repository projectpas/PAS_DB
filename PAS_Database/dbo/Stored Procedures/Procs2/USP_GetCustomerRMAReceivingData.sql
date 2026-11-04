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

 EXEC [dbo].[USP_GetCustomerRMAReceivingData] 10
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCustomerRMAReceivingData]
	@RMAHeaderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

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
			RMADetail.[RMAReason],
			RMADetail.[Notes],
			ISNULL(RMADetail.[UnitPrice], 0) AS [UnitPrice],
			ISNULL(RMADetail.[Qty], 0) AS [Qty],
			ISNULL(RMADetail.[QtyReceived], 0) AS [QtyReceived],
			CASE WHEN ISNULL(RMADetail.[Qty], 0) - ISNULL(RMADetail.[QtyReceived], 0) > 0
				 THEN ISNULL(RMADetail.[Qty], 0) - ISNULL(RMADetail.[QtyReceived], 0) ELSE 0 END AS [QtyPending],
			-- defaults for the new stockline (from the original stockline)
			OriginalStockline.[ConditionId],
			OriginalStockline.[Condition],
			OriginalStockline.[SiteId],
			OriginalStockline.[WarehouseId],
			OriginalStockline.[LocationId],
			OriginalStockline.[ShelfId],
			OriginalStockline.[BinId],
			ISNULL(OriginalStockline.[GLAccountId], PartItemMaster.[GLAccountId]) AS [GLAccountId],
			ISNULL(OriginalStockline.[GlAccountName], PartItemMaster.[GLAccount]) AS [GLAccountName],
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
			OriginalStockline.[TagType]
		FROM [dbo].[CustomerRMADeatils] RMADetail WITH (NOLOCK)
			LEFT JOIN [dbo].[Stockline] OriginalStockline WITH (NOLOCK) ON OriginalStockline.[StockLineId] = RMADetail.[StocklineId]
			LEFT JOIN [dbo].[ItemMaster] PartItemMaster WITH (NOLOCK) ON PartItemMaster.[ItemMasterId] = RMADetail.[ItemMasterId]
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

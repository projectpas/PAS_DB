/*************************************************************
 ** File:   [USP_GetStocklineUnitCostHistory]
 ** Description: Returns the cost-impacting transactions that built up a stockline's current Unit Cost
 **              (origin cost from Migration / PO / WO / Lot / Manual, Repair Order cost, posted Receiving
 **              Reconciliation adjustments, posted Bulk Unit Cost adjustments and Stockline Unit Cost adjustments).
 **              Amounts are PER UNIT, so SUM(UnitCostAmount) always equals Stockline.UnitCost: any change that is
 **              not linked to a tracked source transaction is returned as one balancing 'Other Cost Adjustment' row.
 ** Date:   10/19/2026
 ** Author:  Bhargav Saliya

 ** PARAMETERS:
	@StocklineId      - stockline to explain
	@MasterCompanyId  - master company

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    10/19/2026   Bhargav Saliya	Created (Unit Cost History on View Stockline)

-- EXEC [dbo].[USP_GetStocklineUnitCostHistory] @StocklineId = 214239, @MasterCompanyId = 1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetStocklineUnitCostHistory]
	@StocklineId BIGINT,
	@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	BEGIN TRY

		DECLARE @RRPostedStatusId INT = (SELECT Id FROM dbo.[BatchStatus] WITH(NOLOCK) WHERE [Name] = 'Posted');          -- BatchStatus.Posted (set by AccountingController on RR post)
		DECLARE @UnitCostDataTypeId INT = (SELECT StocklineAdjustmentDataTypeId FROM dbo.StocklineAdjustmentDataType WITH(NOLOCK) WHERE [Description] = 'Unit Cost');       -- StocklineAdjustmentDataType 'Unit Cost'
		DECLARE @BulkUnitPriceTypeId INT = (SELECT StockLineAdjustmentTypeId FROM dbo.StockLineAdjustmentType WITH(NOLOCK) WHERE [Name] = 'Unit Price');       -- StockLineAdjustmentType 'Unit Price'
		DECLARE @BulkPostedStatusId INT;
		SELECT @BulkPostedStatusId = [Id] FROM [dbo].[StocklineAdjustmentStatus] WITH(NOLOCK) WHERE [Name] = 'Posted';

		IF OBJECT_ID(N'tempdb..#CostHistory') IS NOT NULL
			DROP TABLE #CostHistory;

		CREATE TABLE #CostHistory
		(
			[SortGroup]       INT            NOT NULL,   -- 1 = origin, 2 = RO, 3 = adjustments, 9 = balancing row
			[TransactionType] VARCHAR(100)   NOT NULL,
			[ModuleName]      VARCHAR(50)    NOT NULL,   -- drives the clickable reference in the UI
			[ReferenceId]     BIGINT         NULL,
			[ReferenceNumber] VARCHAR(100)   NULL,
			[TransactionDate] DATETIME2(7)   NULL,
			[Quantity]        DECIMAL(18,6)  NULL,
			[UnitCostAmount]  DECIMAL(18,6)  NOT NULL,
			[Notes]           NVARCHAR(MAX)  NULL,
			[CreatedBy]       VARCHAR(256)   NULL
		);

		DECLARE @UnitCost DECIMAL(18,6), @POUnitCost DECIMAL(18,6), @ROUnitCost DECIMAL(18,6),
				@PurchaseOrderId BIGINT, @RepairOrderId BIGINT, @WorkOrderId BIGINT, @LotId BIGINT,
				@IsCustomerStock BIT, @StockLineNumber VARCHAR(100), @UpdatedDate DATETIME2(7), @UpdatedBy VARCHAR(256);

		SELECT @UnitCost        = ISNULL(STL.[UnitCost], 0),
			   @POUnitCost      = ISNULL(STL.[PurchaseOrderUnitCost], 0),
			   @ROUnitCost      = ISNULL(STL.[RepairOrderUnitCost], 0),
			   @PurchaseOrderId = ISNULL(STL.[PurchaseOrderId], 0),
			   @RepairOrderId   = ISNULL(STL.[RepairOrderId], 0),
			   @WorkOrderId     = ISNULL(STL.[WorkOrderId], 0),
			   @LotId           = ISNULL(STL.[LotId], 0),
			   @IsCustomerStock = ISNULL(STL.[IsCustomerStock], 0),
			   @StockLineNumber = STL.[StockLineNumber],
			   @UpdatedDate     = STL.[UpdatedDate],
			   @UpdatedBy       = STL.[UpdatedBy]
		  FROM [dbo].[Stockline] STL WITH(NOLOCK)
		 WHERE STL.[StockLineId] = @StocklineId AND STL.[MasterCompanyId] = @MasterCompanyId;

		IF @StockLineNumber IS NULL
		BEGIN
			SELECT * FROM #CostHistory;
			RETURN;
		END

		/* ---------- 2. Repair cost (RO receipt + piece-part reconciliation, or entered on a manual stockline) ---------- */
		IF (@ROUnitCost <> 0)
		BEGIN
			INSERT INTO #CostHistory ([SortGroup],[TransactionType],[ModuleName],[ReferenceId],[ReferenceNumber],[TransactionDate],[Quantity],[UnitCostAmount],[Notes],[CreatedBy])
			SELECT 2,
				   CASE WHEN @RepairOrderId > 0 THEN 'Repair Order' ELSE 'Repair Cost' END,
				   CASE WHEN @RepairOrderId > 0 THEN 'RepairOrder' ELSE 'Stockline' END,
				   CASE WHEN @RepairOrderId > 0 THEN @RepairOrderId ELSE STL.[StockLineId] END,
				   CASE WHEN @RepairOrderId > 0 THEN ISNULL(STL.[RepairOrderNumber], RO.[RepairOrderNumber]) ELSE STL.[StockLineNumber] END,
				   ISNULL(RCV.[UpdatedDate], ISNULL(STL.[ReceivedDate], STL.[CreatedDate])),
				   STL.[Quantity], @ROUnitCost,
				   CASE WHEN @RepairOrderId > 0 THEN 'Repair cost added on RO receipt (incl. reconciled piece parts)'
						ELSE 'Repair cost entered on the stockline' END,
				   ISNULL(RCV.[UpdatedBy], STL.[CreatedBy])
			  FROM [dbo].[Stockline] STL WITH(NOLOCK)
			  LEFT JOIN [dbo].[RepairOrder] RO WITH(NOLOCK) ON RO.[RepairOrderId] = STL.[RepairOrderId]
			  OUTER APPLY (SELECT TOP 1 H.[UpdatedDate], H.[UpdatedBy]
							 FROM [dbo].[Stkline_History] H WITH(NOLOCK)
							INNER JOIN [dbo].[Module] M WITH(NOLOCK) ON M.[ModuleId] = H.[ModuleId]
							WHERE H.[StocklineId] = STL.[StockLineId] AND M.[ModuleName] = 'ReceivingRepairOrder'
							ORDER BY H.[StklineHistoryId] DESC) RCV
			 WHERE STL.[StockLineId] = @StocklineId;
		END

		/* ---------- 3a. Posted Receiving Reconciliation (invoice price variance + freight / tax / misc) ---------- */
		INSERT INTO #CostHistory ([SortGroup],[TransactionType],[ModuleName],[ReferenceId],[ReferenceNumber],[TransactionDate],[Quantity],[UnitCostAmount],[Notes],[CreatedBy])
		SELECT 3, 'Receiving Reconciliation', 'ReceivingReconciliation', RRH.[ReceivingReconciliationId], RRH.[ReceivingReconciliationNumber],
			   RRH.[UpdatedDate], RRD.[InvoicedQty],
			   ISNULL(RRD.[AdjUnitCost],0) + ISNULL(RRD.[FreightAdjustmentPerUnit],0) + ISNULL(RRD.[TaxAdjustmentPerUnit],0) + ISNULL(RRD.[MiscAdjustmentPerUnit],0),
			   'Invoice ' + ISNULL(RRH.[InvoiceNum], '')
				 + ' | Price Adj: ' + CAST(CAST(ISNULL(RRD.[AdjUnitCost],0) AS DECIMAL(18,2)) AS VARCHAR(30))
				 + ', Freight: '    + CAST(CAST(ISNULL(RRD.[FreightAdjustmentPerUnit],0) AS DECIMAL(18,2)) AS VARCHAR(30))
				 + ', Tax: '        + CAST(CAST(ISNULL(RRD.[TaxAdjustmentPerUnit],0) AS DECIMAL(18,2)) AS VARCHAR(30))
				 + ', Misc: '       + CAST(CAST(ISNULL(RRD.[MiscAdjustmentPerUnit],0) AS DECIMAL(18,2)) AS VARCHAR(30)),
			   RRH.[UpdatedBy]
		  FROM [dbo].[ReceivingReconciliationDetails] RRD WITH(NOLOCK)
		 INNER JOIN [dbo].[ReceivingReconciliationHeader] RRH WITH(NOLOCK) ON RRH.[ReceivingReconciliationId] = RRD.[ReceivingReconciliationId]
		 WHERE RRD.[StocklineId] = @StocklineId
		   AND ISNULL(RRD.[IsManual],0) = 0
		   AND UPPER(ISNULL(RRD.[StockType],'')) = 'STOCK'
		   AND RRH.[StatusId] = @RRPostedStatusId
		   AND RRH.[MasterCompanyId] = @MasterCompanyId
		   AND (ISNULL(RRD.[AdjUnitCost],0) + ISNULL(RRD.[FreightAdjustmentPerUnit],0) + ISNULL(RRD.[TaxAdjustmentPerUnit],0) + ISNULL(RRD.[MiscAdjustmentPerUnit],0)) <> 0;

		/* ---------- 3b. Posted Bulk Stockline Adjustment - Unit Price ---------- */
		INSERT INTO #CostHistory ([SortGroup],[TransactionType],[ModuleName],[ReferenceId],[ReferenceNumber],[TransactionDate],[Quantity],[UnitCostAmount],[Notes],[CreatedBy])
		SELECT 3, 'Bulk Unit Cost Adjustment', 'BulkStockLineAdjustment', BSA.[BulkStkLineAdjId], BSA.[BulkStkLineAdjNumber],
			   BSA.[UpdatedDate], BSD.[Qty],
			   ISNULL(BSD.[NewUnitCost],0) - ISNULL(BSD.[UnitCost],0),
			   'Unit Cost ' + CAST(CAST(ISNULL(BSD.[UnitCost],0) AS DECIMAL(18,2)) AS VARCHAR(30)) + ' -> ' + CAST(CAST(ISNULL(BSD.[NewUnitCost],0) AS DECIMAL(18,2)) AS VARCHAR(30))
				 + CASE WHEN ISNULL(BSD.[FreightAdjustment],0) <> 0 OR ISNULL(BSD.[TaxAdjustment],0) <> 0
						THEN ' (Freight: ' + CAST(CAST(ISNULL(BSD.[FreightAdjustment],0) AS DECIMAL(18,2)) AS VARCHAR(30))
						   + ', Tax: '     + CAST(CAST(ISNULL(BSD.[TaxAdjustment],0) AS DECIMAL(18,2)) AS VARCHAR(30)) + ')'
						ELSE '' END
				 + ISNULL(' | ' + SAR.[Description], ''),
			   BSA.[UpdatedBy]
		  FROM [dbo].[BulkStockLineAdjustmentDetails] BSD WITH(NOLOCK)
		 INNER JOIN [dbo].[BulkStockLineAdjustment] BSA WITH(NOLOCK) ON BSA.[BulkStkLineAdjId] = BSD.[BulkStkLineAdjId]
		  LEFT JOIN [dbo].[StocklineAdjustmentReason] SAR WITH(NOLOCK) ON SAR.[AdjustmentReasonId] = BSD.[AdjustmentReasonId]
		 WHERE BSD.[StockLineId] = @StocklineId
		   AND BSD.[StockLineAdjustmentTypeId] = @BulkUnitPriceTypeId
		   AND BSD.[IsActive] = 1 AND BSD.[IsDeleted] = 0
		   AND BSA.[StatusId] = @BulkPostedStatusId
		   AND BSA.[MasterCompanyId] = @MasterCompanyId
		   AND ISNULL(BSD.[NewUnitCost],0) - ISNULL(BSD.[UnitCost],0) <> 0;

		/* ---------- 3c. Stockline Adjustment - Unit Cost (single adjustment screen / unit cost bulk upload) ---------- */
		INSERT INTO #CostHistory ([SortGroup],[TransactionType],[ModuleName],[ReferenceId],[ReferenceNumber],[TransactionDate],[Quantity],[UnitCostAmount],[Notes],[CreatedBy])
		SELECT 3, 'Stockline Adjustment', 'StocklineAdjustment', SA.[StocklineAdjustmentId],
			   'ADJ-' + RIGHT('000000' + CAST(SA.[StocklineAdjustmentId] AS VARCHAR(20)), 6),
			   SA.[CreatedDate], NULL,
			   ISNULL(TRY_CAST(SA.[ChangedTo] AS DECIMAL(18,6)),0) - ISNULL(TRY_CAST(SA.[ChangedFrom] AS DECIMAL(18,6)),0),
			   'Unit Cost ' + ISNULL(SA.[ChangedFrom],'0') + ' -> ' + ISNULL(SA.[ChangedTo],'0')
				 + ISNULL(' | ' + NULLIF(CAST(SA.[AdjustmentReason] AS NVARCHAR(MAX)),''), '')
				 + ISNULL(' | ' + NULLIF(CAST(SA.[AdjustmentMemo] AS NVARCHAR(MAX)),''), ''),
			   SA.[CreatedBy]
		  FROM [dbo].[StocklineAdjustment] SA WITH(NOLOCK)
		 WHERE SA.[StocklineId] = @StocklineId
		   AND SA.[StocklineAdjustmentDataTypeId] = @UnitCostDataTypeId
		   AND SA.[IsDeleted] = 0
		   AND SA.[MasterCompanyId] = @MasterCompanyId
		   AND ISNULL(TRY_CAST(SA.[ChangedTo] AS DECIMAL(18,6)),0) - ISNULL(TRY_CAST(SA.[ChangedFrom] AS DECIMAL(18,6)),0) <> 0;

		/* ---------- 1. Origin cost ----------
		   PO receipts carry their own PO unit cost; every other origin (migration, WO, lot, manual, customer) has no
		   separate cost record, so its origin cost is what remains of UnitCost after the RO + adjustment rows. */
		DECLARE @TrackedTotal DECIMAL(18,6) = ISNULL((SELECT SUM([UnitCostAmount]) FROM #CostHistory), 0);
		DECLARE @IsMigrated BIT = CASE WHEN EXISTS (SELECT 1 FROM [dbo].[Stkline_History] H WITH(NOLOCK)
													 WHERE H.[StocklineId] = @StocklineId AND H.[Notes] LIKE '%added through Migration%')
									   THEN 1 ELSE 0 END;

		INSERT INTO #CostHistory ([SortGroup],[TransactionType],[ModuleName],[ReferenceId],[ReferenceNumber],[TransactionDate],[Quantity],[UnitCostAmount],[Notes],[CreatedBy])
		SELECT 1,
			   CASE WHEN @IsMigrated = 1     THEN 'Migrated'
					WHEN @PurchaseOrderId > 0 THEN 'Purchase Order'
					WHEN @WorkOrderId > 0     THEN 'Work Order'
					WHEN @LotId > 0           THEN 'Lot'
					WHEN @IsCustomerStock = 1 THEN 'Customer Stock Receipt'
					ELSE 'Manual Entry' END,
			   CASE WHEN @IsMigrated = 1     THEN 'Stockline'
					WHEN @PurchaseOrderId > 0 THEN 'PurchaseOrder'
					WHEN @WorkOrderId > 0     THEN 'WorkOrder'
					WHEN @LotId > 0           THEN 'Lot'
					ELSE 'Stockline' END,
			   CASE WHEN @IsMigrated = 1     THEN STL.[StockLineId]
					WHEN @PurchaseOrderId > 0 THEN @PurchaseOrderId
					WHEN @WorkOrderId > 0     THEN @WorkOrderId
					WHEN @LotId > 0           THEN @LotId
					ELSE STL.[StockLineId] END,
			   CASE WHEN @IsMigrated = 1     THEN ISNULL(NULLIF(STL.[ReceiverNumber],''), STL.[StockLineNumber])
					WHEN @PurchaseOrderId > 0 THEN STL.[PurchaseOrderNumber]
					WHEN @WorkOrderId > 0     THEN STL.[WorkOrderNumber]
					WHEN @LotId > 0           THEN STL.[LotNumber]
					WHEN @IsCustomerStock = 1 THEN ISNULL(NULLIF(STL.[ReceiverNumber],''), STL.[StockLineNumber])
					ELSE STL.[StockLineNumber] END,
			   ISNULL(STL.[ReceivedDate], STL.[CreatedDate]),
			   STL.[Quantity],
			   CASE WHEN @PurchaseOrderId > 0 AND @IsMigrated = 0 THEN @POUnitCost
					ELSE @UnitCost - @TrackedTotal END,
			   CASE WHEN @IsMigrated = 1     THEN 'Cost brought in through data migration'
					WHEN @PurchaseOrderId > 0 THEN 'PO unit cost on receipt'
										   + ISNULL(' (Receiver ' + NULLIF(STL.[ReceiverNumber],'') + ')', '')
					WHEN @WorkOrderId > 0     THEN 'Cost from work order'
					WHEN @LotId > 0           THEN 'Cost from lot'
					WHEN @IsCustomerStock = 1 THEN 'Customer stock received'
					ELSE 'Cost entered when the stockline was created' END,
			   STL.[CreatedBy]
		  FROM [dbo].[Stockline] STL WITH(NOLOCK)
		 WHERE STL.[StockLineId] = @StocklineId;

		/* ---------- 9. Balancing row: changes with no tracked source (keeps SUM = Stockline.UnitCost) ---------- */
		DECLARE @Unexplained DECIMAL(18,6) = @UnitCost - ISNULL((SELECT SUM([UnitCostAmount]) FROM #CostHistory), 0);
		IF (ABS(@Unexplained) >= 0.005)
		BEGIN
			INSERT INTO #CostHistory ([SortGroup],[TransactionType],[ModuleName],[ReferenceId],[ReferenceNumber],[TransactionDate],[Quantity],[UnitCostAmount],[Notes],[CreatedBy])
			VALUES (9, 'Other Cost Adjustment', 'Other', NULL, NULL, @UpdatedDate, NULL, @Unexplained,
					'Unit cost change not linked to a tracked source transaction (e.g. inventory adjustment or legacy data)', @UpdatedBy);
		END

		SELECT ROW_NUMBER() OVER (ORDER BY [SortGroup], [TransactionDate], [ReferenceId]) AS [SeqNo],
			   [TransactionType],
			   [ModuleName],
			   [ReferenceId],
			   [ReferenceNumber],
			   [TransactionDate],
			   [Quantity],
			   [UnitCostAmount],
			   [Notes],
			   [CreatedBy]
		  FROM #CostHistory
		 ORDER BY [SeqNo];

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetStocklineUnitCostHistory'
			, @ProcedureParameters VARCHAR(3000) = '@StocklineId = ''' + CAST(ISNULL(@StocklineId, '') AS VARCHAR(100))
												 + ''', @MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) + ''''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			  @DatabaseName        = @DatabaseName
			, @AdhocComments       = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName     = @ApplicationName
			, @ErrorLogID          = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN(1);
	END CATCH
END
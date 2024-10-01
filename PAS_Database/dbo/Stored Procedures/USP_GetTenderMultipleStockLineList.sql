/*************************************************************           
 ** File:   [USP_GetTenderMultipleStockLineList]           
 ** Author:    Devendra Shekh
 ** Description:  get Tender Multiple StockLine List
 ** Purpose:         
 ** Date:   02-SEP-2024
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------  
	1    09/02/2024   Devendra Shekh	     CREATED
	2    09/24/2024   Devendra Shekh	     Modified to same rows as qty for serialized part
	3    09/26/2024   Devendra Shekh	     Modified to differentiate Serialized part with PartRowIndex
	4    10/01/2024   Devendra Shekh	     Modified (changes for [QtyToTender] and for where case to select result)

exec USP_GetTenderMultipleStockLineList @PageSize=10,@PageNumber=1,@SortColumn=NULL,@SortOrder=1,@WorkOrderId=4390,@WorkFlowWorkOrderId=3917,@MasterCompanyId=1
exec dbo.USP_GetTenderMultipleStockLineList @PageNumber=1,@PageSize=10,@SortColumn=default,@SortOrder=1,@WorkOrderId=4404,@WorkFlowWorkOrderId=3925,@MasterCompanyId=1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetTenderMultipleStockLineList]
	@PageSize INT,
	@PageNumber INT,
	@SortColumn VARCHAR(50) = NULL,
	@SortOrder INT,
	@WorkOrderId BIGINT,
	@WorkFlowWorkOrderId BIGINT,
	@MasterCompanyId INT
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @RecordFrom INT;
		DECLARE @Count INT;

		DECLARE @RepairProvisionId INT = 0;
		SELECT @RepairProvisionId  = [ProvisionId] FROM [dbo].[Provision] WITH(NOLOCK) WHERE UPPER([StatusCode]) = 'REPAIR';
		
		SET @RecordFrom = (@PageNumber-1) * @PageSize;

		IF OBJECT_ID('tempdb..#TenderMultipleStkListData') IS NOT NULL
			DROP TABLE #TenderMultipleStkListData

		IF OBJECT_ID(N'tempdb..#tmpWOMStockline') IS NOT NULL
			DROP TABLE #tmpWOMStockline

		IF OBJECT_ID(N'tempdb..#tmpWOMStocklineKit') IS NOT NULL
			DROP TABLE #tmpWOMStocklineKit

		IF OBJECT_ID(N'tempdb..#tmpWOMQtyResult') IS NOT NULL
			DROP TABLE #tmpWOMQtyResult

		IF OBJECT_ID(N'tempdb..##FinalResult') IS NOT NULL
			DROP TABLE #FinalResult

		CREATE TABLE #TenderMultipleStkListData
		(
			[RecordID] BIGINT NOT NULL IDENTITY, 	
			[WorkOrderMaterialsId] [bigint] NULL,
			[PartNumber] [varchar](200) NULL,
			[PartDescription] [varchar](MAX) NULL,
			[UOM] [varchar](100) NULL,
			[Condition] [varchar](256) NULL,
			[Quantity] [int] NULL,
			[CustomerName] [varchar](100) NULL,
			[CustomerCode] [varchar](100) NULL,
			[IsSerialized] [bit] NULL, 
			[SerialNumberNotProvided] [bit] NULL, 
			[SerialNumber] [varchar](150) NULL, 
			[WorkOrderNum] [varchar](30) NULL,
			[Manufacturer] [varchar](100) NULL,
			[Receiver] [varchar](150) NULL,
			[ReceivedDate] [datetime2] NULL,
			[Provision] [varchar](150) NULL,
			[Site] [varchar](250) NULL,
			[WareHouse] [varchar](250) NULL,
			[Location] [varchar](250) NULL,
			[Shelf] [varchar](250) NULL,
			[Bin] [varchar](250) NULL,
			[IsKitType] [bit] NULL,
			[ItemMasterId] [bigint] NULL,
			[UnitOfMeasureId] [bigint] NULL,
			[ConditionId] [bigint] NULL,
			[CustomerId] [bigint] NULL,
			[WorkOrderId] [bigint] NULL,
			[Manufacturerid] [bigint] NULL,
			[ProvisionId] [bigint] NULL,
			[SiteId] [bigint] NULL,
			[WareHouseId] [bigint] NULL,
			[LocationId] [bigint] NULL,
			[ShelfId] [bigint] NULL,
			[BinId] [bigint] NULL,
			[MasterCompanyId] [int] NULL,
			[TenderedQuantity] [int] NULL,
			[QtyToTender] [int] NULL
		)

		CREATE TABLE #FinalResult
		(
			[RecordID] BIGINT NOT NULL IDENTITY, 	
			[WorkOrderMaterialsId] [bigint] NULL,
			[PartNumber] [varchar](200) NULL,
			[PartDescription] [varchar](MAX) NULL,
			[UOM] [varchar](100) NULL,
			[Condition] [varchar](256) NULL,
			[Quantity] [int] NULL,
			[CustomerName] [varchar](100) NULL,
			[CustomerCode] [varchar](100) NULL,
			[IsSerialized] [bit] NULL, 
			[SerialNumberNotProvided] [bit] NULL, 
			[SerialNumber] [varchar](150) NULL, 
			[WorkOrderNum] [varchar](30) NULL,
			[Manufacturer] [varchar](100) NULL,
			[Receiver] [varchar](150) NULL,
			[ReceivedDate] [datetime2] NULL,
			[Provision] [varchar](150) NULL,
			[Site] [varchar](250) NULL,
			[WareHouse] [varchar](250) NULL,
			[Location] [varchar](250) NULL,
			[Shelf] [varchar](250) NULL,
			[Bin] [varchar](250) NULL,
			[IsKitType] [bit] NULL,
			[ItemMasterId] [bigint] NULL,
			[UnitOfMeasureId] [bigint] NULL,
			[ConditionId] [bigint] NULL,
			[CustomerId] [bigint] NULL,
			[WorkOrderId] [bigint] NULL,
			[Manufacturerid] [bigint] NULL,
			[ProvisionId] [bigint] NULL,
			[SiteId] [bigint] NULL,
			[WareHouseId] [bigint] NULL,
			[LocationId] [bigint] NULL,
			[ShelfId] [bigint] NULL,
			[BinId] [bigint] NULL,
			[MasterCompanyId] [int] NULL,
			[TenderedQuantity] [int] NULL,
			[QtyToTender] [int] NULL,
			[PartRowIndex] [int] NULL
		)

		CREATE TABLE #tmpWOMStockline
		(
			ID BIGINT NOT NULL IDENTITY, 						 
			[WorkOrderMaterialsId] [bigint] NULL,
			[ConditionId] [bigint] NOT NULL,
			[TotalQuantityTurnIn] [int] NULL,
			[TotalReservedQty] [int] NULL,
			[TotalIssuedQty] [int] NULL,
		)

		CREATE TABLE #tmpWOMStocklineKit
		(
			ID BIGINT NOT NULL IDENTITY, 						 
			[WorkOrderMaterialsId] [bigint] NULL,
			[ConditionId] [bigint] NOT NULL,
			[TotalQuantityTurnIn] [int] NULL,
			[TotalReservedQty] [int] NULL,
			[TotalIssuedQty] [int] NULL,
		)

		CREATE TABLE #tmpWOMQtyResult
		(
			ResID BIGINT NOT NULL IDENTITY, 						 
			[Qty] [int] NULL,
		)		 
			
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('PartNumber')
		END 
		Else
		BEGIN 
			SET @SortColumn=UPPER(@SortColumn)
		END		

		INSERT INTO #tmpWOMStockline 
		SELECT DISTINCT	WOMS.WorkOrderMaterialsId,
						WOMS.ConditionId,
						SUM(ISNULL(WOMS.QuantityTurnIn, 0)),
						SUM(ISNULL(WOMS.QtyReserved, 0)),
						SUM(ISNULL(WOMS.QtyIssued, 0))
				FROM dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) 
				JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId 
				AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
				WHERE	WOM.MasterCompanyId = @MasterCompanyId AND WOM.WorkOrderId = @WorkOrderId AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId
						AND WOM.ProvisionId = @RepairProvisionId
				GROUP BY WOMS.WorkOrderMaterialsId, WOMS.ConditionId;

		INSERT INTO #tmpWOMStocklineKit 
		SELECT DISTINCT	WOMS.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,
						WOMS.ConditionId,
						SUM(ISNULL(WOMS.QuantityTurnIn, 0)),
						SUM(ISNULL(WOMS.QtyReserved, 0)),
						SUM(ISNULL(WOMS.QtyIssued, 0))
				FROM dbo.WorkOrderMaterialStockLineKit WOMS WITH(NOLOCK) 
				JOIN dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.WorkOrderMaterialsKitId = WOMS.WorkOrderMaterialsKitId 
				AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
				WHERE	WOM.MasterCompanyId = @MasterCompanyId AND WOM.WorkOrderId = @WorkOrderId AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId
						AND WOM.ProvisionId = @RepairProvisionId
				GROUP BY WOMS.WorkOrderMaterialsKitId, WOMS.ConditionId;

		--Adding WorkOrder Material Data 
		INSERT INTO #TenderMultipleStkListData (
			[WorkOrderMaterialsId], [PartNumber], [PartDescription], [UOM], [Condition], [Quantity], [CustomerName], [CustomerCode], [IsSerialized], [SerialNumberNotProvided], [SerialNumber], [WorkOrderNum], [Manufacturer], 
			[Receiver], [ReceivedDate], [Provision], [Site], [WareHouse], [Location], [Shelf], [Bin], [IsKitType], [ItemMasterId], [UnitOfMeasureId], [ConditionId], [CustomerId], [WorkOrderId], [Manufacturerid], 
			[ProvisionId], [SiteId], [WareHouseId], [LocationId], [ShelfId], [BinId], [MasterCompanyId], [TenderedQuantity], [QtyToTender])
		SELECT DISTINCT WOM.[WorkOrderMaterialsId], IM.PartNumber, IM.PartDescription, UOM.ShortName, C.[Description], ISNULL(WOM.Quantity, 0), CU.[Name], CU.CustomerCode,  ISNULL(IM.isSerialized, 0), 1, '', WO.WorkOrderNum,  ISNULL(MF.[Name], ''),
		'Creating', GETDATE(),  ISNULL(PS.[Description], ''),  ISNULL(IM.SiteName, ''),  ISNULL(IM.WarehouseName, ''),  ISNULL(IM.LocationName, ''),  ISNULL(IM.ShelfName, ''),  ISNULL(IM.BinName, ''), 0, IM.ItemMasterId, ISNULL(UOM.UnitOfMeasureId, 0), ISNULL(WOM.ConditionCodeId, 0), WO.CustomerId, WO.WorkOrderId, ISNULL(IM.ManufacturerId, 0),
		ISNULL(WOM.ProvisionId, 0), ISNULL(IM.SiteId, 0), ISNULL(IM.WarehouseId, 0), ISNULL(IM.LocationId, 0), ISNULL(IM.ShelfId, 0), ISNULL(IM.BinId, 0), WOM.[MasterCompanyId], ISNULL(tmpWOM.TotalQuantityTurnIn, 0), (ISNULL(WOM.Quantity, 0) - (ISNULL(tmpWOM.TotalQuantityTurnIn, 0) + ISNULL(tmpWOM.TotalReservedQty, 0) + ISNULL(tmpWOM.TotalIssuedQty, 0)))
		FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
			JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
			JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
			JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
			JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOM.WorkOrderId
			JOIN dbo.Customer CU WITH (NOLOCK) ON CU.CustomerId = WO.CustomerId
			LEFT JOIN dbo.Manufacturer MF WITH (NOLOCK) ON MF.ManufacturerId = IM.ManufacturerId
			LEFT JOIN dbo.Provision PS WITH (NOLOCK) ON PS.ProvisionId = WOM.ProvisionId
			LEFT JOIN #tmpWOMStockline tmpWOM WITH (NOLOCK) ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
			WHERE	WOM.MasterCompanyId = @MasterCompanyId AND WOM.WorkOrderId = @WorkOrderId AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId
					AND WOM.ProvisionId = @RepairProvisionId AND (ISNULL(WOM.Quantity, 0) - (ISNULL(tmpWOM.TotalQuantityTurnIn, 0) + ISNULL(tmpWOM.TotalReservedQty, 0) + ISNULL(tmpWOM.TotalIssuedQty, 0)) > 0);
		
		--Adding WorkOrder Material Kit Data 
		INSERT INTO #TenderMultipleStkListData (
			[WorkOrderMaterialsId], [PartNumber], [PartDescription], [UOM], [Condition], [Quantity], [CustomerName], [CustomerCode], [IsSerialized], [SerialNumberNotProvided], [SerialNumber], [WorkOrderNum], [Manufacturer], 
			[Receiver], [ReceivedDate], [Provision], [Site], [WareHouse], [Location], [Shelf], [Bin], [IsKitType], [ItemMasterId], [UnitOfMeasureId], [ConditionId], [CustomerId], [WorkOrderId], [Manufacturerid], 
			[ProvisionId], [SiteId], [WareHouseId], [LocationId], [ShelfId], [BinId], [MasterCompanyId], [TenderedQuantity], [QtyToTender])
		SELECT DISTINCT WOM.[WorkOrderMaterialsKitId], IM.PartNumber, IM.PartDescription, UOM.ShortName, C.[Description], ISNULL(WOM.Quantity, 0), CU.[Name], CU.CustomerCode,  ISNULL(IM.isSerialized, 0), 1, '', WO.WorkOrderNum,  ISNULL(MF.[Name], ''),
		'Creating', GETDATE(),  ISNULL(PS.[Description], ''),  ISNULL(IM.SiteName, ''),  ISNULL(IM.WarehouseName, ''),  ISNULL(IM.LocationName, ''),  ISNULL(IM.ShelfName, ''),  ISNULL(IM.BinName, ''), 1, IM.ItemMasterId, ISNULL(UOM.UnitOfMeasureId, 0), ISNULL(WOM.ConditionCodeId, 0), WO.CustomerId, WO.WorkOrderId, ISNULL(IM.ManufacturerId, 0),
		ISNULL(WOM.ProvisionId, 0), ISNULL(IM.SiteId, 0), ISNULL(IM.WarehouseId, 0), ISNULL(IM.LocationId, 0), ISNULL(IM.ShelfId, 0), ISNULL(IM.BinId, 0), WOM.[MasterCompanyId], ISNULL(tmpWOMKit.TotalQuantityTurnIn, 0),(ISNULL(WOM.Quantity, 0) - (ISNULL(tmpWOMKit.TotalQuantityTurnIn, 0) + ISNULL(tmpWOMKit.TotalReservedQty, 0) + ISNULL(tmpWOMKit.TotalIssuedQty, 0)))
		FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
			JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
			JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
			JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
			JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOM.WorkOrderId
			JOIN dbo.Customer CU WITH (NOLOCK) ON CU.CustomerId = WO.CustomerId
			LEFT JOIN dbo.Manufacturer MF WITH (NOLOCK) ON MF.ManufacturerId = IM.ManufacturerId
			LEFT JOIN dbo.Provision PS WITH (NOLOCK) ON PS.ProvisionId = WOM.ProvisionId
			LEFT JOIN #tmpWOMStocklineKit tmpWOMKit WITH (NOLOCK) ON tmpWOMKit.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId
			WHERE	WOM.MasterCompanyId = @MasterCompanyId AND WOM.WorkOrderId = @WorkOrderId AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId
					AND WOM.ProvisionId = @RepairProvisionId AND (ISNULL(WOM.Quantity, 0) - (ISNULL(tmpWOMKit.TotalQuantityTurnIn, 0) + ISNULL(tmpWOMKit.TotalReservedQty, 0) + ISNULL(tmpWOMKit.TotalIssuedQty, 0)) > 0);

		DECLARE @WOMMaxQty INT;
		SELECT @WOMMaxQty = MAX(ISNULL(Quantity,0)) FROM #TenderMultipleStkListData;

		;WITH Numbers AS (
			SELECT 1 AS Number
			UNION ALL
			SELECT Number + 1
			FROM Numbers
			WHERE Number < @WOMMaxQty
		)
		INSERT INTO #tmpWOMQtyResult ([Qty]) SELECT Number FROM Numbers;

		INSERT INTO #FinalResult([WorkOrderMaterialsId], [PartNumber], [PartDescription], [UOM], [Condition], [Quantity], [CustomerName], [CustomerCode], [IsSerialized], [SerialNumberNotProvided], [SerialNumber], [WorkOrderNum], [Manufacturer], 
				[Receiver], [ReceivedDate], [Provision], [Site], [WareHouse], [Location], [Shelf], [Bin], [IsKitType], [ItemMasterId], [UnitOfMeasureId], [ConditionId], [CustomerId], [WorkOrderId], [Manufacturerid], 
				[ProvisionId], [SiteId], [WareHouseId], [LocationId], [ShelfId], [BinId], [MasterCompanyId], [TenderedQuantity], [QtyToTender], [PartRowIndex])
		SELECT	[WorkOrderMaterialsId], [PartNumber], [PartDescription], [UOM], [Condition], [Quantity], [CustomerName], [CustomerCode], [IsSerialized], [SerialNumberNotProvided], [SerialNumber], [WorkOrderNum], [Manufacturer], 
				[Receiver], [ReceivedDate], [Provision], [Site], [WareHouse], [Location], [Shelf], [Bin], [IsKitType], [ItemMasterId], [UnitOfMeasureId], [ConditionId], [CustomerId], [WorkOrderId], [Manufacturerid], 
				[ProvisionId], [SiteId], [WareHouseId], [LocationId], [ShelfId], [BinId], [MasterCompanyId], [TenderedQuantity], [QtyToTender], n.[Qty]
		FROM #TenderMultipleStkListData T
		LEFT JOIN #tmpWOMQtyResult n ON n.[Qty] <= T.[QtyToTender] WHERE T.IsSerialized = 1

		INSERT INTO #FinalResult([WorkOrderMaterialsId], [PartNumber], [PartDescription], [UOM], [Condition], [Quantity], [CustomerName], [CustomerCode], [IsSerialized], [SerialNumberNotProvided], [SerialNumber], [WorkOrderNum], [Manufacturer], 
				[Receiver], [ReceivedDate], [Provision], [Site], [WareHouse], [Location], [Shelf], [Bin], [IsKitType], [ItemMasterId], [UnitOfMeasureId], [ConditionId], [CustomerId], [WorkOrderId], [Manufacturerid], 
				[ProvisionId], [SiteId], [WareHouseId], [LocationId], [ShelfId], [BinId], [MasterCompanyId], [TenderedQuantity], [QtyToTender], [PartRowIndex])
		SELECT	[WorkOrderMaterialsId], [PartNumber], [PartDescription], [UOM], [Condition], [Quantity], [CustomerName], [CustomerCode], [IsSerialized], [SerialNumberNotProvided], [SerialNumber], [WorkOrderNum], [Manufacturer], 
				[Receiver], [ReceivedDate], [Provision], [Site], [WareHouse], [Location], [Shelf], [Bin], [IsKitType], [ItemMasterId], [UnitOfMeasureId], [ConditionId], [CustomerId], [WorkOrderId], [Manufacturerid], 
				[ProvisionId], [SiteId], [WareHouseId], [LocationId], [ShelfId], [BinId], [MasterCompanyId], [TenderedQuantity], [QtyToTender], 1
		FROM #TenderMultipleStkListData T WHERE T.IsSerialized = 0

		SELECT @Count = COUNT(RecordID) FROM #FinalResult;

		SELECT @Count AS NumberOfItems, 
			[WorkOrderMaterialsId], [PartNumber], [PartDescription], [UOM], [Condition], [Quantity], [CustomerName], [CustomerCode], [IsSerialized], [SerialNumberNotProvided], [SerialNumber], [WorkOrderNum], [Manufacturer], 
			[Receiver], [ReceivedDate], [Provision], [Site], [WareHouse], [Location], [Shelf], [Bin], [IsKitType], [ItemMasterId], [UnitOfMeasureId], [ConditionId], [CustomerId], [WorkOrderId], [Manufacturerid], 
			[ProvisionId], [SiteId], [WareHouseId], [LocationId], [ShelfId], [BinId], [MasterCompanyId], [TenderedQuantity], [QtyToTender], [PartRowIndex]
		FROM #FinalResult
		ORDER BY [PartNumber]
		--OFFSET @RecordFrom ROWS 
		--FETCH NEXT @PageSize ROWS ONLY

	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetTenderMultipleStockLineList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS VARCHAR(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS VARCHAR(100))
			  + '@Parameter5 = ''' + CAST(ISNULL(@masterCompanyID, '') AS VARCHAR(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END
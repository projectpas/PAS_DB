/*************************************************************             
 ** File:   [USP_GetSubWorkOrderMaterialsListNew]             
 ** Author:  Devendra Shekh 
 ** Description: This stored procedure is used retrieve Work Order Sub Materials List      
 ** Purpose:           
 ** Date:  07/29/2024		[mm/dd/yyyy]       
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date			Author					Change Description              
 ** --   --------		-------				--------------------------------            
    1    07/29/2024		Devendra Shekh			Created
    2    07/30/2024		Devendra Shekh			Modified to Manage Nullable Values and added fields for order by
       
 EXECUTE USP_GetSubWorkOrderMaterialsList 316,0  
exec dbo.USP_GetSubWorkOrderMaterialsListNew @PageNumber=1,@PageSize=5,@SortColumn=default,@SortOrder=1,@subWOPartNoId=316,@ShowPendingToIssue=0
**************************************************************/   
CREATE   PROCEDURE [dbo].[USP_GetSubWorkOrderMaterialsListNew]      
(
	@PageNumber int,  
	@PageSize int,  
	@SortColumn varchar(50)=null,  
	@SortOrder int,  
	@subWOPartNoId BIGINT = NULL , 
	@ShowPendingToIssue BIT NULL = 0
)      
AS      
BEGIN      
  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
SET NOCOUNT ON      
  
  BEGIN TRY  
   BEGIN TRANSACTION  
    BEGIN    

		DECLARE @SubProvisionId INT;
		DECLARE @ForStockProvisionId INT;
		DECLARE @MasterCompanyId INT;
		DECLARE @CustomerID BIGINT;
		DECLARE @Count Int;  
		DECLARE @RecordFrom int;  

		IF @SortColumn IS NULL
		BEGIN  
			SET @SortColumn = ('taskName')
		END
		SET @RecordFrom = (@PageNumber-1)*@PageSize;  

		SELECT @SubProvisionId = ProvisionId FROM dbo.Provision WITH (NOLOCK) WHERE UPPER(StatusCode) = 'SUB WORK ORDER'
		SELECT @ForStockProvisionId = ProvisionId FROM dbo.Provision WITH (NOLOCK) WHERE UPPER(StatusCode) = 'FOR STOCK'
		SELECT DISTINCT TOP 1 @CustomerID = WO.CustomerId, @MasterCompanyId = WO.MasterCompanyId 
		FROM dbo.WorkOrder WO WITH(NOLOCK) JOIN dbo.SubWorkOrder SWO WITH(NOLOCK) on WO.WorkOrderId = SWO.WorkOrderId 
			JOIN dbo.SubWorkOrderPartNumber SWOPN WITH(NOLOCK) on SWOPN.SubWorkOrderId = SWO.SubWorkOrderId 
		WHERE SWOPN.SubWOPartNoId = @subWOPartNoId;

  
		 IF OBJECT_ID(N'tempdb..#tmpStockline') IS NOT NULL  
		 BEGIN  
		 DROP TABLE #tmpStockline  
		 END  
  
		 IF OBJECT_ID(N'tempdb..#tmpWOMStockline') IS NOT NULL  
		 BEGIN  
		 DROP TABLE #tmpWOMStockline  
		 END  
  
		 CREATE TABLE #tmpStockline  
		  (  
			ID BIGINT NOT NULL IDENTITY,          
		   [StockLineId] [bigint] NOT NULL,  
		   [ItemMasterId] [bigint] NULL,  
		   [ConditionId] [bigint] NOT NULL,  
		   [QuantityOnHand] [int] NOT NULL,  
		   [QuantityReserved] [int] NULL,  
		   [QuantityAvailable] [int] NULL,  
		   [QuantityTurnIn] [int] NULL,  
		   [QuantityOnOrder] [int] NULL,  
		   [IsParent] [bit] NULL,  
		  )  
  
		 CREATE TABLE #tmpWOMStockline  
		 (  
		   ID BIGINT NOT NULL IDENTITY,          
		  [StockLineId] [bigint] NOT NULL,  
		  [SubWorkOrderMaterialsId] [bigint] NULL,  
		  [ConditionId] [bigint] NOT NULL,  
		  [QtyIssued] [int] NOT NULL,  
		  [QtyReserved] [int] NULL,  
		  [IsActive] BIT NULL,  
		  [IsDeleted] BIT NULL,  
		 )  

		 CREATE TABLE #TMPWOMaterialParentListData
		 (
		 	[ParentID] BIGINT NOT NULL IDENTITY, 						 
		 	[SubWorkOrderMaterialsId] [bigint] NULL,
		 	[SubWorkOrderMaterialsKitMappingId] [bigint] NULL,
		 	[SubWOPartNoId] [bigint] NULL,
		 	[IsKit] [bit] NULL,
		 )

		 
		 CREATE TABLE #finalMaterialListResult
		 (
		 	[RecordID] BIGINT NOT NULL IDENTITY, 						 
		 	[PartNumber] [varchar](200) NULL,
		 	[PartDescription] [varchar](MAX) NULL,
		 	[StocklinePartNumber] [varchar](200) NULL,
		 	[StocklinePartDescription] [varchar](MAX)  NULL,
		 	[KitNumber] [varchar](256) NULL,
		 	[KitDescription] [varchar](1000) NULL,
		 	[KitCost] [decimal](18, 2) NULL,
		 	[WOQMaterialKitMappingId] [bigint] NULL, 	
		 	[KitId] [bigint] NULL,
		 	[ItemGroup] [varchar](250) NULL,
		 	[ManufacturerName] [varchar](200) NULL,
		 	[WorkOrderNumber] [varchar](500) NULL,
		 	[SubWorkOrderNo] [varchar](100) NULL,	
			[SubWorkOrderId] [bigint] NULL,
		 	[SalesOrder] [varchar](20) NULL,
		 	[Site] [varchar](250) NULL,
		 	[WareHouse] [varchar](250) NULL,
		 	[Location] [varchar](250) NULL,
		 	[Shelf] [varchar](250) NULL,
		 	[Bin] [varchar](250) NULL,
		 	[PartStatusId] [bigint] NULL,
		 	[Provision] [varchar](150) NULL,
		 	[ProvisionStatusCode] [varchar](150) NULL,
		 	[StockType] [varchar](20) NULL,
		 	[ItemType] [varchar](20) NULL,
		 	[Condition] [varchar](256) NULL,
		 	[StocklineCondition] [varchar](256) NULL,
		 	[UnitCost] [decimal](18, 2) NULL,
		 	[ExtendedCost] [decimal](18, 2) NULL,
		 	[TotalStocklineQtyReq] [int] NULL,
		 	[WOMStockLIneId] [bigint] NULL,
			[StocklineUnitCost] [decimal](18, 2) NULL,
			[StocklineExtendedCost] [decimal](18, 2) NULL,
		 	[StockLineProvisionId] [bigint] NULL,
		 	[IsWOMSAltPart] [bit] NULL,
		 	[IsWOMSEquPart] [bit] NULL,
		 	[AlterPartNumber] [varchar](200) NULL,
		 	[StocklineProvision] [varchar](150) NULL,
		 	[StocklineProvisionStatusCode] [varchar](150) NULL,
		 	[StockLineNumber] [varchar](150) NULL,
		 	[SerialNumber] [varchar](150) NULL, 
		 	[ControlId] [varchar](150) NULL,
		 	[ControlNo] [varchar](150) NULL,
		 	[Receiver] [varchar](150) NULL,
		 	[StockLineQuantityOnHand] [int] NULL,
		 	[StockLineQuantityAvailable] [int] NULL,
		 	[PartQuantityOnHand] [int] NULL,
		 	[PartQuantityAvailable] [int] NULL,
		 	[PartQuantityReserved] [int] NULL,
		 	[PartQuantityTurnIn] [int] NULL,
		 	[PartQuantityOnOrder] [int] NULL,
		 	[CostDate] [datetime2] NULL,
		 	[Currency] [varchar](150) NULL,
		 	[QuantityIssued] [int] NULL,
		 	[QuantityReserved] [int] NULL,
		 	[QunatityRemaining] [int] NULL,
		 	[StocklineQtyReserved] [int] NULL,
		 	[QtytobeReserved] [int] NULL,
		 	[StocklineQtyIssued] [int] NULL,
		 	[StocklineQuantityTurnIn] [int] NULL,
		 	[StocklineQtyRemaining] [int] NULL,
		 	[StocklineQtytobeReserved] [int] NULL,
		 	[QtyOnOrder] [int] NULL,
		 	[QtyOnBkOrder] [int] NULL,
		 	[PONum] [varchar](150) NULL,
		 	[PONextDlvrDate] [datetime2] NULL,
		 	[POId] [bigint] NULL,
		 	[Quantity] [int] NULL,
		 	[StocklineQuantity] [int] NULL,
		 	[PartQtyToTurnIn] [int] NULL,
		 	[StocklineQtyToTurnIn] [int] NULL,
		 	[ConditionCodeId] [bigint] NULL,
		 	[StocklineConditionCodeId] [bigint] NULL,
		 	[UnitOfMeasureId] [bigint] NULL,
		 	[WorkOrderId] [bigint] NULL,
		 	[ItemMasterId] [bigint] NULL,
		 	[ItemClassificationId] [bigint] NULL,
		 	[PurchaseUnitOfMeasureId] [bigint] NULL,
		 	[Memo] [nvarchar](2000) NULL,
		 	[IsDeferred] [bit] NULL,
		 	[TaskId] [bigint] NULL,
		 	[TaskName] [varchar](200) NULL,
		 	[MandatoryOrSupplemental] [varchar](150) NULL,
		 	[MaterialMandatoriesId] [int] NULL,
		 	[MasterCompanyId] [int] NULL,
		 	[IsAltPart] [bit] NULL,
		 	[IsEquPart] [bit] NULL,
		 	[ItemClassification] [varchar](250) NULL,
		 	[UOM] [varchar](100) NULL,
		 	[Defered] [varchar](50) NULL,
		 	[IsRoleUp] [bit] NULL,
		 	[ProvisionId] [int] NULL,
			[SubWorkOrderMaterialsId] [bigint] NULL,
			[SubWOPartNoId] [bigint] NULL,
		 	[IsFromWorkFlow] [bit] NULL,
		 	[Employeename] [varchar](256) NULL,
		 	[RONextDlvrDate] [datetime2] NULL,
		 	[RepairOrderNumber] [varchar](150) NULL,
		 	[Figure] [nvarchar](250) NULL,
		 	[Item] [nvarchar](250) NULL,
		 	[StockLineFigure] [nvarchar](250) NULL,
		 	[StockLineItem] [nvarchar](250) NULL,
		 	[StockLineId] [bigint] NULL,
		 	[IsKitType] [bit] NULL,
		 	[KitQty] [int] NULL,
		 )
  
		 INSERT INTO #tmpStockline SELECT         
			   SL.StockLineId,         
			   SL.ItemMasterId,  
			   SL.ConditionId,  
			   SL.QuantityOnHand,  
			   SL.QuantityReserved,  
			   SL.QuantityAvailable,  
			   SL.QuantityTurnIn,  
			   SL.QuantityOnOrder,  
			   SL.IsParent  
		 FROM dbo.Stockline SL WITH(NOLOCK)   
		 JOIN dbo.SubWorkOrderMaterials WOM WITH (NOLOCK) ON WOM.ItemMasterId = sl.ItemMasterId AND WOM.ConditionCodeId = SL.ConditionId AND SL.IsParent = 1  
  
		 INSERT INTO #tmpWOMStockline SELECT         
			   WOMS.StockLineId,         
			   WOMS.SubWorkOrderMaterialsId,  
			   WOMS.ConditionId,  
			   WOMS.QtyIssued,  
			   WOMS.QtyReserved,  
			   WOMS.IsActive,  
			   WOMS.IsDeleted  
		 FROM dbo.SubWorkOrderMaterialStockLine WOMS WITH(NOLOCK)   
			JOIN dbo.SubWorkOrderMaterials WOM WITH (NOLOCK) ON WOM.SubWorkOrderMaterialsId = WOMS.SubWorkOrderMaterialsId   
				AND WOM.SubWOPartNoId = @subWOPartNoId AND WOMS.IsActive = 1 AND WOMS.IsDeleted = 0  

		IF OBJECT_ID(N'tempdb..#tmpStocklineKit') IS NOT NULL
		BEGIN
			DROP TABLE #tmpStocklineKit
		END

		IF OBJECT_ID(N'tempdb..#tmpWOMStocklineKit') IS NOT NULL
		BEGIN
			DROP TABLE #tmpWOMStocklineKit
		END

		
		CREATE TABLE #tmpStocklineKit
		(
			ID BIGINT NOT NULL IDENTITY, 						 
			[StockLineId] [bigint] NOT NULL,
			[ItemMasterId] [bigint] NULL,
			[ConditionId] [bigint] NOT NULL,
			[QuantityOnHand] [int] NOT NULL,
			[QuantityReserved] [int] NULL,
			[QuantityAvailable] [int] NULL,
			[QuantityTurnIn] [int] NULL,
			[QuantityOnOrder] [int] NULL,
			[IsParent] [bit] NULL,
		)

		CREATE TABLE #tmpWOMStocklineKit
		(
			ID BIGINT NOT NULL IDENTITY, 						 
			[StockLineId] [bigint] NOT NULL,
			[SubWorkOrderMaterialsId] [bigint] NULL,
			[ConditionId] [bigint] NOT NULL,
			[QtyIssued] [int] NOT NULL,
			[QtyReserved] [int] NULL,
			[IsActive] BIT NULL,
			[IsDeleted] BIT NULL,
		)

		INSERT INTO #tmpStocklineKit SELECT DISTINCT						
			SL.StockLineId, 						
			SL.ItemMasterId,
			SL.ConditionId,
			SL.QuantityOnHand,
			SL.QuantityReserved,
			SL.QuantityAvailable,
			SL.QuantityTurnIn,
			SL.QuantityOnOrder,
			SL.IsParent
		FROM dbo.Stockline SL WITH(NOLOCK) 
		JOIN dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.ItemMasterId = sl.ItemMasterId AND WOM.ConditionCodeId = SL.ConditionId AND SL.IsParent = 1
		WHERE SL.MasterCompanyId = @MasterCompanyId 
		AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
		AND  SL.IsActive = 1 AND SL.IsDeleted = 0

		INSERT INTO #tmpWOMStocklineKit SELECT DISTINCT						
				WOMS.StockLineId, 						
				WOMS.SubWorkOrderMaterialsKitId AS SubWorkOrderMaterialsId,
				WOMS.ConditionId,
				WOMS.QtyIssued,
				WOMS.QtyReserved,
				WOMS.IsActive,
				WOMS.IsDeleted
		FROM dbo.SubWorkOrderMaterialStockLineKit WOMS WITH(NOLOCK) 
		JOIN dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.SubWorkOrderMaterialsKitId = WOMS.SubWorkOrderMaterialsKitId 
		AND WOM.SubWOPartNoId = @subWOPartNoId AND WOMS.IsActive = 1 AND WOMS.IsDeleted = 0

		--Inserting Data For Parent Level- For Pagination : Start
		INSERT INTO #TMPWOMaterialParentListData
		([SubWorkOrderMaterialsId], [SubWOPartNoId], [SubWorkOrderMaterialsKitMappingId], [IsKit])
		SELECT DISTINCT	[SubWorkOrderMaterialsId], [SubWOPartNoId], 0, 0 FROM [DBO].SubWorkOrderMaterials WOM WITH(NOLOCK) WHERE WOM.IsDeleted = 0 AND WOM.SubWOPartNoId = @subWOPartNoId;

		INSERT INTO #TMPWOMaterialParentListData
		([SubWorkOrderMaterialsId], [SubWOPartNoId], [SubWorkOrderMaterialsKitMappingId], [IsKit])
		SELECT DISTINCT	0, SubWOPartNoId, [SubWorkOrderMaterialsKitMappingId], 1 FROM [DBO].[SubWorkOrderMaterialsKitMapping] WOMKIT WITH(NOLOCK) WHERE WOMKIT.IsDeleted = 0 AND WOMKIT.SubWOPartNoId = @subWOPartNoId;

		SELECT * INTO #TMPWOMaterialResultListData FROM #TMPWOMaterialParentListData tmp 
		ORDER BY tmp.SubWOPartNoId ASC
		OFFSET @RecordFrom ROWS   
		FETCH NEXT @PageSize ROWS ONLY
		--Inserting Data For Parent Level- For Pagination : End
  
		IF(ISNULL(@ShowPendingToIssue, 0) = 1)
		BEGIN
				
				INSERT INTO	#finalMaterialListResult([PartNumber], [PartDescription], [StocklinePartNumber], [StocklinePartDescription], [KitNumber], [KitDescription], [KitCost], [WOQMaterialKitMappingId], [KitId],
								[ItemGroup], [ManufacturerName], [WorkOrderNumber], [SubWorkOrderNo], [SubWorkOrderId], [SalesOrder], [Site], [WareHouse], [Location], [Shelf], [Bin], [PartStatusId], [Provision], 
								[ProvisionStatusCode], [StockType], [ItemType], [Condition], [StocklineCondition], [UnitCost], [ExtendedCost], [TotalStocklineQtyReq], [WOMStockLIneId], [StocklineUnitCost], 
								[StocklineExtendedCost],[StockLineProvisionId], [StocklineProvision], [StocklineProvisionStatusCode], [StockLineNumber], [SerialNumber], [ControlId], [ControlNo], [Receiver],
								[StockLineQuantityOnHand], [StockLineQuantityAvailable], [PartQuantityOnHand], [PartQuantityAvailable], [PartQuantityReserved], [PartQuantityTurnIn], [PartQuantityOnOrder], [CostDate], 
								[Currency], [QuantityIssued], [QuantityReserved], [QunatityRemaining], [StocklineQuantity], [StocklineQtyReserved], [StocklineQtyIssued], [PartQtyToTurnIn], [QtytobeReserved], 
								[StocklineQtytobeReserved],[StocklineQuantityTurnIn], [StocklineQtyToTurnIn], [StocklineQtyRemaining], [Quantity], [ConditionCodeId], [StocklineConditionCodeId],[UnitOfMeasureId], 
								[WorkOrderId], [QtyOnOrder], [QtyOnBkOrder], [PONum], [PONextDlvrDate], [POId], [ItemMasterId], [ItemClassificationId], [PurchaseUnitOfMeasureId], [Memo], [IsDeferred], [TaskId],
								[TaskName], [MandatoryOrSupplemental], [MaterialMandatoriesId], [MasterCompanyId], [IsAltPart], [IsEquPart], [ItemClassification], [UOM], [Defered], [IsRoleUp], [ProvisionId], 
								[SubWorkOrderMaterialsId], [SubWOPartNoId], [IsFromWorkFlow], [StockLineId], [Employeename], [RONextDlvrDate], [RepairOrderNumber], [Figure], [Item], [StockLineFigure], [StockLineItem],
								[IsKitType], [KitQty], [IsWOMSAltPart], [IsWOMSEquPart], [AlterPartNumber])
				SELECT DISTINCT   
					IM.PartNumber,  
					IM.PartDescription,   
					IMS.PartNumber StocklinePartNumber,
					IMS.PartDescription StocklinePartDescription,
					'' AS KitNumber,
					'' AS KitDescription,
					0 AS KitCost,
					0 as WOQMaterialKitMappingId,
					0 AS KitId,
					IM.ItemGroup,  
					IM.ManufacturerName,  
					W.WorkOrderNum As WorkOrderNumber,  
					--WOM.WorkOrderId,  
					SWO.SubWorkOrderNo as SubWorkOrderNo,  
					SWO.SubWorkOrderId,  
					'' AS SalesOrder,  
					IM.SiteName AS Site,  
					IM.WarehouseName AS WareHouse,  
					IM.LocationName AS Location,  
					IM.ShelfName AS Shelf,  
					IM.BinName AS Bin,  
					WOM.PartStatusId,  
					P.Description AS Provision,  
					P.StatusCode AS ProvisionStatusCode,  
					CASE   
					WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'  
					WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'  
					WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'  
					ELSE 'OEM'  
					END AS StockType,  
					CASE   
					WHEN IM.ItemTypeId = 1 THEN 'Stock'  
					WHEN IM.ItemTypeId = 2 THEN 'Non Stock'  
					WHEN IM.ItemTypeId = 3 THEN 'Equipment'  
					WHEN IM.ItemTypeId = 4 THEN 'Loan'  
					ELSE ''  
					END AS ItemType,  
					C.Description AS Condition,        
					Stk_C.Description AS StocklineCondition,
					ISNULL(WOM.UnitCost, 0),  
					ISNULL(WOM.ExtendedCost, 0),  
					ISNULL(WOM.TotalStocklineQtyReq, 0),  
					ISNULL(MSTL.StockLIneId,0),         
					ISNULL(MSTL.UnitCost,0) StocklineUnitCost,  
					ISNULL(MSTL.ExtendedCost,0) StocklineExtendedCost,  
					MSTL.ProvisionId AS StockLineProvisionId,  
					SP.Description AS StocklineProvision,  
					ISNULL(SP.StatusCode,0) AS StocklineProvisionStatusCode,  
					SL.StockLineNumber,  
					SL.SerialNumber,  
					SL.IdNumber AS ControlId,  
					SL.ControlNumber AS ControlNo,  
					SL.ReceiverNumber AS Receiver,  
					ISNULL(SL.QuantityOnHand,0) AS StockLineQuantityOnHand,  
					ISNULL(SL.QuantityAvailable,0) AS StockLineQuantityAvailable,  
  
					PartQuantityOnHand = ISNULL((SELECT SUM(ISNULL(sl.QuantityOnHand,0)) FROM #tmpStockline sl  WITH (NOLOCK)  
						Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1            
						),0),  
					PartQuantityAvailable = ISNULL((SELECT SUM(ISNULL(sl.QuantityAvailable,0)) FROM #tmpStockline sl  WITH (NOLOCK)  
						Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1  
						),0),  
  
					PartQuantityReserved = ISNULL((SELECT SUM(ISNULL(sl.QuantityReserved,0)) FROM #tmpWOMStockline womsl  WITH (NOLOCK)  
						JOIN #tmpStockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId   
						Where womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId  
						AND womsl.isActive = 1 AND womsl.isDeleted = 0  
						),0),  
					PartQuantityTurnIn = ISNULL((SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.SubWorkOrderMaterialStockLine womsl WITH (NOLOCK)   
						JOIN #tmpStockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId  
						Where womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId  
						AND womsl.isActive = 1 AND womsl.isDeleted = 0  
						),0),  
					PartQuantityOnOrder = ISNULL((SELECT SUM(ISNULL(sl.QuantityOnOrder,0)) FROM #tmpWOMStockline womsl  WITH (NOLOCK)  
						JOIN #tmpStockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId  
						Where womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId  
						AND womsl.isActive = 1 AND womsl.isDeleted = 0  
						),0),  
					CostDate = (SELECT TOP 1 CONVERT(varchar, IMPS.PP_LastListPriceDate, 101) FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND  
						IMPS.ConditionId = WOM.ConditionCodeId AND IMPS.PP_LastListPriceDate IS NOT NULL),  
					Currency = (SELECT TOP 1 CUR.Code  FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) LEFT JOIN dbo.Currency CUR WITH (NOLOCK) ON IMPS.PP_CurrencyId = CUR.CurrencyId   
						WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId ),  
					QuantityIssued = ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued,0)) FROM #tmpWOMStockline womsl WITH (NOLOCK)   
						WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0),  
					QuantityReserved = ISNULL((SELECT SUM(ISNULL(womsl.QtyReserved,0)) FROM #tmpWOMStockline womsl  WITH (NOLOCK)  
						WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0),  
					QunatityRemaining = ISNULL(WOM.Quantity - ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued,0)) FROM #tmpWOMStockline womsl  WITH (NOLOCK)  
						WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0), 0),0),  
					ISNULL(MSTL.Quantity,0) AS StocklineQuantity,  
					ISNULL(MSTL.QtyReserved,0) AS StocklineQtyReserved,  
					ISNULL(MSTL.QtyIssued,0) AS StocklineQtyIssued,  
					ISNULL(WOM.QtyToTurnIn,0) AS PartQtyToTurnIn,
					ISNULL(WOM.Quantity, 0) - Isnull((SELECT SUM(ISNULL(womsl.QtyIssued,0)) FROM #tmpWOMStockline womsl WITH (NOLOCK)   
						WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0) - Isnull((SELECT SUM(ISNULL(womsl.QtyReserved,0)) FROM #tmpWOMStockline womsl  WITH (NOLOCK)  
						WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0)  AS QtytobeReserved,
					ISNULL(MSTL.Quantity, 0) - (ISNULL(MSTL.QtyIssued,0) + ISNULL(MSTL.QtyReserved,0)) AS StocklineQtytobeReserved,
					--SL.QuantityTurnIn as StocklineQuantityTurnIn,  
					ISNULL(MSTL.QuantityTurnIn, 0) as StocklineQuantityTurnIn,
					ISNULL(CASE WHEN MSTL.ProvisionId = @SubProvisionId AND ISNULL(MSTL.Quantity, 0) != 0 THEN MSTL.Quantity 
					ELSE CASE WHEN MSTL.ProvisionId = @SubProvisionId OR MSTL.ProvisionId = @ForStockProvisionId THEN SL.QuantityTurnIn ELSE 0 END END,0) AS 'StocklineQtyToTurnIn',
					ISNULL(MSTL.Quantity, 0) - ISNULL(MSTL.QtyIssued,0) AS StocklineQtyRemaining,  
					ISNULL(WOM.Quantity,0),  
					WOM.ConditionCodeId,  
					MSTL.ConditionId AS StocklineConditionCodeId,
					WOM.UnitOfMeasureId,  
					WOM.WorkOrderId,  
					ISNULL(WOM.QtyOnOrder,0),   
					ISNULL(WOM.QtyOnBkOrder,0),  
					WOM.PONum,  
					WOM.PONextDlvrDate,  
					ISNULL(WOM.POId,0),  
					IM.ItemMasterId,  
					IM.ItemClassificationId,  
					IM.PurchaseUnitOfMeasureId,  
					WOM.Memo,  
					ISNULL(WOM.IsDeferred, 0),
					WOM.TaskId,  
					T.Description AS TaskName,  
					MM.Name AS MandatoryOrSupplemental,  
					WOM.MaterialMandatoriesId,  
					WOM.MasterCompanyId,  
					WOM.IsAltPart,  
					WOM.IsEquPart,  
					WOM.ItemClassification AS ItemClassification,  
					--UOM.ShortName AS UOM,  
					CASE WHEN SUOM.UnitOfMeasureId IS NOT NULL THEN SUOM.ShortName ELSE UOM.ShortName END AS UOM,
					CASE WHEN WOM.IsDeferred = NULL OR WOM.IsDeferred = 0 THEN 'No' ELSE 'Yes' END AS Defered,  
					IsRoleUp = 0,  
					WOM.ProvisionId,  
					WOM.SubWorkOrderMaterialsId,  
					WOM.SubWOPartNoId,  
					ISNULL(WOM.IsFromWorkFlow,0) as IsFromWorkFlow,  
					ISNULL(SL.StockLineId,0) AS  StockLIneId ,  
					Employeename = (SELECT TOP 1 (EMP.FirstName +''+ EMP.LastName) FROM dbo.Employee EMP WITH (NOLOCK) WHERE W.EmployeeID = EMP.EmployeeID ),  
					ROP.EstRecordDate 'RONextDlvrDate',  
					RO.RepairOrderNumber
					,WOM.Figure Figure
					,WOM.Item Item
					,MSTL.Figure StockLineFigure
					,MSTL.Item StockLineItem
					,0 AS IsKitType
					,0 AS KitQty
					,(CASE 
							WHEN ISNULL(MSTL.IsAltPart, 0) = 0 
							THEN 0
							ELSE MSTL.IsAltPart 
							END
						) AS IsWOMSAltPart,
						(CASE 
							WHEN ISNULL(MSTL.IsEquPart, 0) = 0 
							THEN 0 
							ELSE MSTL.IsEquPart
							END
						) AS IsWOMSEquPart,
						(SELECT partnumber FROM itemmaster IM WHERE IM.ItemMasterId = 
						(CASE 
							WHEN ISNULL(MSTL.AltPartMasterPartId, 0) = 0 
							THEN 
								CASE 
								WHEN ISNULL(MSTL.EquPartMasterPartId, 0) = 0 
								THEN 0
								ELSE MSTL.EquPartMasterPartId
								END
							ELSE MSTL.AltPartMasterPartId
							END)
						) AS AlterPartNumber
				FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK)    
					JOIN dbo.WorkOrder W WITH (NOLOCK) ON W.WorkOrderId = WOM.WorkOrderId  
					JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId  
					JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId  
					JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId        
					JOIN dbo.SubWorkOrderPartNumber wo WITH (NOLOCK) ON wo.SubWOPartNoId = WOM.SubWOPartNoId  
					JOIN dbo.MaterialMandatories MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId  
					LEFT JOIN dbo.SubWorkOrderMaterialStockLine MSTL WITH (NOLOCK) ON MSTL.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND MSTL.IsDeleted = 0  
					LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId  
					LEFT JOIN dbo.Condition Stk_C WITH (NOLOCK) ON Stk_C.ConditionId = SL.ConditionId
					LEFT JOIN dbo.UnitOfMeasure SUOM WITH (NOLOCK) ON SUOM.UnitOfMeasureId = SL.PurchaseUnitOfMeasureId
					LEFT JOIN dbo.ItemClassification ITC WITH (NOLOCK) ON ITC.ItemClassificationId = IM.ItemClassificationId  
					LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId     
					LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = MSTL.ProvisionId  
					LEFT JOIN dbo.Task T WITH (NOLOCK) ON T.TaskId = WOM.TaskId  
					LEFT JOIN dbo.SubWorkOrder SWO WITH (NOLOCK) ON SWO.SubWorkOrderId = WOM.SubWorkOrderId  
					LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) ON SL.RepairOrderPartRecordId = ROP.RepairOrderPartRecordId  
					LEFT JOIN dbo.RepairOrder RO WITH (NOLOCK) ON SL.RepairOrderId = RO.RepairOrderId  
					LEFT JOIN dbo.ItemMaster IMS WITH (NOLOCK) ON IMS.ItemMasterId = MSTL.ItemMasterId
				WHERE WOM.IsDeleted = 0 AND WOM.SubWOPartNoId = @subWOPartNoId AND ISNULL(WOM.IsAltPart, 0) = 0 AND ISNULL(WOM.IsEquPart, 0) = 0 
				AND (ISNULL(WOM.Quantity,0) - ISNULL(WOM.QuantityIssued,0) > 0)
			    AND WOM.SubWorkOrderMaterialsId IN (SELECT SubWorkOrderMaterialsId FROM #TMPWOMaterialResultListData WHERE IsKit = 0)

				--UNION ALL
				INSERT INTO	#finalMaterialListResult([PartNumber], [PartDescription], [StocklinePartNumber], [StocklinePartDescription], [KitNumber], [KitDescription], [KitCost], [WOQMaterialKitMappingId], [KitId],
								[ItemGroup], [ManufacturerName], [WorkOrderNumber], [SubWorkOrderNo], [SubWorkOrderId], [SalesOrder], [Site], [WareHouse], [Location], [Shelf], [Bin], [PartStatusId], [Provision], 
								[ProvisionStatusCode], [StockType], [ItemType], [Condition], [StocklineCondition], [UnitCost], [ExtendedCost], [TotalStocklineQtyReq], [WOMStockLIneId], [StocklineUnitCost], 
								[StocklineExtendedCost],[StockLineProvisionId], [StocklineProvision], [StocklineProvisionStatusCode], [StockLineNumber], [SerialNumber], [ControlId], [ControlNo], [Receiver],
								[StockLineQuantityOnHand], [StockLineQuantityAvailable], [PartQuantityOnHand], [PartQuantityAvailable], [PartQuantityReserved], [PartQuantityTurnIn], [PartQuantityOnOrder], [CostDate], 
								[Currency], [QuantityIssued], [QuantityReserved], [QunatityRemaining], [StocklineQuantity], [StocklineQtyReserved], [StocklineQtyIssued], [PartQtyToTurnIn], [QtytobeReserved], 
								[StocklineQtytobeReserved],[StocklineQuantityTurnIn], [StocklineQtyToTurnIn], [StocklineQtyRemaining], [Quantity], [ConditionCodeId], [StocklineConditionCodeId],[UnitOfMeasureId], 
								[WorkOrderId], [QtyOnOrder], [QtyOnBkOrder], [PONum], [PONextDlvrDate], [POId], [ItemMasterId], [ItemClassificationId], [PurchaseUnitOfMeasureId], [Memo], [IsDeferred], [TaskId],
								[TaskName], [MandatoryOrSupplemental], [MaterialMandatoriesId], [MasterCompanyId], [IsAltPart], [IsEquPart], [ItemClassification], [UOM], [Defered], [IsRoleUp], [ProvisionId], 
								[SubWorkOrderMaterialsId], [SubWOPartNoId], [IsFromWorkFlow], [StockLineId], [Employeename], [RONextDlvrDate], [RepairOrderNumber], [Figure], [Item], [StockLineFigure], [StockLineItem],
								[IsKitType], [KitQty], [IsWOMSAltPart], [IsWOMSEquPart], [AlterPartNumber])
				SELECT DISTINCT   
					IM.PartNumber,  
					IM.PartDescription,   
					IMS.PartNumber StocklinePartNumber,
					IMS.PartDescription StocklinePartDescription,
					WOMKM.KitNumber AS KitNumber,
					(SELECT KM.KitDescription FROM [dbo].[KitMaster] KM WITH (NOLOCK) WHERE KM.KitId = WOMKM.KitId) AS KitDescription,
					(SELECT KM.KitCost FROM [dbo].[KitMaster] KM WITH (NOLOCK) WHERE KM.KitId = WOMKM.KitId) AS KitCost,
					0 as WOQMaterialKitMappingId,
					WOMKM.KitId AS KitId,
					IM.ItemGroup,  
					IM.ManufacturerName,  
					W.WorkOrderNum As WorkOrderNumber,  
					--WOM.WorkOrderId,  
					SWO.SubWorkOrderNo as SubWorkOrderNo,  
					SWO.SubWorkOrderId,  
					'' AS SalesOrder,  
					IM.SiteName AS Site,  
					IM.WarehouseName AS WareHouse,  
					IM.LocationName AS Location,  
					IM.ShelfName AS Shelf,  
					IM.BinName AS Bin,  
					WOM.PartStatusId,  
					P.Description AS Provision,  
					P.StatusCode AS ProvisionStatusCode,  
					CASE   
					WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'  
					WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'  
					WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'  
					ELSE 'OEM'  
					END AS StockType,  
					CASE   
					WHEN IM.ItemTypeId = 1 THEN 'Stock'  
					WHEN IM.ItemTypeId = 2 THEN 'Non Stock'  
					WHEN IM.ItemTypeId = 3 THEN 'Equipment'  
					WHEN IM.ItemTypeId = 4 THEN 'Loan'  
					ELSE ''  
					END AS ItemType,  
					C.Description AS Condition,        
					Stk_C.Description AS StocklineCondition,
					ISNULL(WOM.UnitCost,0),  
					ISNULL(WOM.ExtendedCost,0),  
					ISNULL(WOM.TotalStocklineQtyReq,0),  
					ISNULL(MSTL.StockLIneId,0),         
					ISNULL(MSTL.UnitCost,0) StocklineUnitCost,  
					ISNULL(MSTL.ExtendedCost,0) StocklineExtendedCost,  
					ISNULL(MSTL.ProvisionId,0) AS StockLineProvisionId,  
					SP.Description AS StocklineProvision,  
					SP.StatusCode AS StocklineProvisionStatusCode,  
					SL.StockLineNumber,  
					SL.SerialNumber,  
					SL.IdNumber AS ControlId,  
					SL.ControlNumber AS ControlNo,  
					SL.ReceiverNumber AS Receiver,  
					SL.QuantityOnHand AS StockLineQuantityOnHand,  
					SL.QuantityAvailable AS StockLineQuantityAvailable,  
  
					PartQuantityOnHand = ISNULL((SELECT SUM(ISNULL(sl.QuantityOnHand,0)) FROM #tmpStocklineKit sl  WITH (NOLOCK)  
						Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1            
						),0),  
					PartQuantityAvailable = ISNULL((SELECT SUM(ISNULL(sl.QuantityAvailable,0)) FROM #tmpStocklineKit sl  WITH (NOLOCK)  
						Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1  
						),0),  
  
					PartQuantityReserved = ISNULL((SELECT SUM(ISNULL(sl.QuantityReserved,0)) FROM #tmpWOMStocklineKit womsl  WITH (NOLOCK)  
						JOIN #tmpStocklineKit sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId   
						Where womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId  
						AND womsl.isActive = 1 AND womsl.isDeleted = 0  
						),0),  
					PartQuantityTurnIn = ISNULL((SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.SubWorkOrderMaterialStockLineKit womsl WITH (NOLOCK)   
						JOIN #tmpStockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId  
						Where womsl.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId  
						AND womsl.isActive = 1 AND womsl.isDeleted = 0  
						),0),  
					PartQuantityOnOrder = ISNULL((SELECT SUM(ISNULL(sl.QuantityOnOrder,0)) FROM #tmpWOMStocklineKit womsl  WITH (NOLOCK)  
						JOIN #tmpStocklineKit sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId  
						Where womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId  
						AND womsl.isActive = 1 AND womsl.isDeleted = 0  
						),0),  
					CostDate = (SELECT TOP 1 CONVERT(varchar, IMPS.PP_LastListPriceDate, 101) FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND  
						IMPS.ConditionId = WOM.ConditionCodeId AND IMPS.PP_LastListPriceDate IS NOT NULL),  
					Currency = (SELECT TOP 1 CUR.Code  FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) LEFT JOIN dbo.Currency CUR WITH (NOLOCK) ON IMPS.PP_CurrencyId = CUR.CurrencyId   
						WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId ),  
					QuantityIssued = ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued,0)) FROM #tmpWOMStocklinekit womsl WITH (NOLOCK)   
						WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0),  
					QuantityReserved = ISNULL((SELECT SUM(ISNULL(womsl.QtyReserved,0)) FROM #tmpWOMStocklinekit womsl  WITH (NOLOCK)  
						WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0),  
					QunatityRemaining = ISNULL(WOM.Quantity - ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued,0)) FROM #tmpWOMStocklinekit womsl  WITH (NOLOCK)  
						WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0), 0),0),  
					ISNULL(MSTL.Quantity,0) AS StocklineQuantity,  
					ISNULL(MSTL.QtyReserved,0) AS StocklineQtyReserved,  
					ISNULL(MSTL.QtyIssued,0) AS StocklineQtyIssued,  
					ISNULL(WOM.QtyToTurnIn,0) AS PartQtyToTurnIn,
					ISNULL(WOM.Quantity, 0) - Isnull((SELECT SUM(ISNULL(womsl.QtyIssued,0)) FROM #tmpWOMStocklinekit womsl WITH (NOLOCK)   
						WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0) - Isnull((SELECT SUM(ISNULL(womsl.QtyReserved,0)) FROM #tmpWOMStocklinekit womsl  WITH (NOLOCK)  
						WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0)  AS QtytobeReserved,
					ISNULL(MSTL.Quantity, 0) - (ISNULL(MSTL.QtyIssued,0) + ISNULL(MSTL.QtyReserved,0)) AS StocklineQtytobeReserved,
					ISNULL(MSTL.QuantityTurnIn, 0) as StocklineQuantityTurnIn,
					ISNULL(CASE WHEN MSTL.ProvisionId = @SubProvisionId AND ISNULL(MSTL.Quantity, 0) != 0 THEN MSTL.Quantity 
					ELSE CASE WHEN MSTL.ProvisionId = @SubProvisionId OR MSTL.ProvisionId = @ForStockProvisionId THEN SL.QuantityTurnIn ELSE 0 END END,0) AS 'StocklineQtyToTurnIn',
					ISNULL(MSTL.Quantity, 0) - ISNULL(MSTL.QtyIssued,0) AS StocklineQtyRemaining,  
					ISNULL(WOM.Quantity,0),  
					ISNULL(WOM.ConditionCodeId,0),  
					ISNULL(MSTL.ConditionId,0) AS StocklineConditionCodeId,
					ISNULL(WOM.UnitOfMeasureId,0),  
					WOM.WorkOrderId,  
					ISNULL(WOM.QtyOnOrder,0),   
					ISNULL(WOM.QtyOnBkOrder,0),  
					WOM.PONum,  
					WOM.PONextDlvrDate,  
					ISNULL(WOM.POId,0),  
					IM.ItemMasterId,  
					IM.ItemClassificationId,  
					IM.PurchaseUnitOfMeasureId,  
					WOM.Memo,  
					ISNULL(WOM.IsDeferred, 0),
					WOM.TaskId,  
					T.Description AS TaskName,  
					MM.Name AS MandatoryOrSupplemental,  
					WOM.MaterialMandatoriesId,  
					WOM.MasterCompanyId,  
					WOM.IsAltPart,  
					WOM.IsEquPart,  
					WOM.ItemClassification AS ItemClassification,  
					CASE WHEN SUOM.UnitOfMeasureId IS NOT NULL THEN SUOM.ShortName ELSE UOM.ShortName END AS UOM,
					CASE WHEN WOM.IsDeferred = NULL OR WOM.IsDeferred = 0 THEN 'No' ELSE 'Yes' END AS Defered,  
					IsRoleUp = 0,  
					WOM.ProvisionId,  
					WOM.SubWorkOrderMaterialsKitId AS SubWorkOrderMaterialsId,  
					WOM.SubWOPartNoId,  
					ISNULL(WOM.IsFromWorkFlow,0) as IsFromWorkFlow,  
					ISNULL(SL.StockLineId,0) AS  StockLIneId ,  
					Employeename = (SELECT TOP 1 (EMP.FirstName +''+ EMP.LastName) FROM dbo.Employee EMP WITH (NOLOCK) WHERE W.EmployeeID = EMP.EmployeeID ),  
					ROP.EstRecordDate 'RONextDlvrDate',  
					RO.RepairOrderNumber
					,WOM.Figure Figure
					,WOM.Item Item
					,MSTL.Figure StockLineFigure
					,MSTL.Item StockLineItem
					,1 AS IsKitType
					,(SELECT SUM(ISNULL(WOMK.Quantity, 0)) FROM dbo.SubWorkOrderMaterialsKit WOMK WITH (NOLOCK) WHERE WOMK.SubWorkOrderMaterialsKitMappingId = WOMKM.SubWorkOrderMaterialsKitMappingId) AS KitQty
					,(CASE 
							WHEN ISNULL(MSTL.IsAltPart, 0) = 0 
							THEN 0
							ELSE MSTL.IsAltPart 
							END
						) AS IsWOMSAltPart,
						(CASE 
							WHEN ISNULL(MSTL.IsEquPart, 0) = 0 
							THEN 0 
							ELSE MSTL.IsEquPart
							END
						) AS IsWOMSEquPart,
						(SELECT partnumber FROM itemmaster IM WHERE IM.ItemMasterId = 
						(CASE 
							WHEN ISNULL(MSTL.AltPartMasterPartId, 0) = 0 
							THEN 
								CASE 
								WHEN ISNULL(MSTL.EquPartMasterPartId, 0) = 0 
								THEN 0
								ELSE MSTL.EquPartMasterPartId
								END
							ELSE MSTL.AltPartMasterPartId
							END)
						) AS AlterPartNumber
				FROM dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK)    
					JOIN dbo.WorkOrder W WITH (NOLOCK) ON W.WorkOrderId = WOM.WorkOrderId  
					JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId  
					JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId  
					JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId        
					JOIN dbo.SubWorkOrderPartNumber wo WITH (NOLOCK) ON wo.SubWOPartNoId = WOM.SubWOPartNoId  
					JOIN dbo.MaterialMandatories MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId  
					LEFT JOIN dbo.SubWorkOrderMaterialStockLineKit MSTL WITH (NOLOCK) ON MSTL.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND MSTL.IsDeleted = 0  
					LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId  
					LEFT JOIN dbo.Condition Stk_C WITH (NOLOCK) ON Stk_C.ConditionId = SL.ConditionId
					LEFT JOIN dbo.UnitOfMeasure SUOM WITH (NOLOCK) ON SUOM.UnitOfMeasureId = SL.PurchaseUnitOfMeasureId
					LEFT JOIN dbo.ItemClassification ITC WITH (NOLOCK) ON ITC.ItemClassificationId = IM.ItemClassificationId  
					LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId     
					LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = MSTL.ProvisionId  
					LEFT JOIN dbo.Task T WITH (NOLOCK) ON T.TaskId = WOM.TaskId  
					LEFT JOIN dbo.SubWorkOrder SWO WITH (NOLOCK) ON SWO.SubWorkOrderId = WOM.SubWorkOrderId  
					LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) ON SL.RepairOrderPartRecordId = ROP.RepairOrderPartRecordId  
					LEFT JOIN dbo.RepairOrder RO WITH (NOLOCK) ON SL.RepairOrderId = RO.RepairOrderId  
					LEFT JOIN [dbo].[SubWorkOrderMaterialsKitMapping] WOMKM WITH (NOLOCK) ON WOMKM.SubWOPartNoId = wo.SubWOPartNoId AND WOMKM.SubWorkOrderMaterialsKitMappingId = WOM.SubWorkOrderMaterialsKitMappingId
					LEFT JOIN dbo.ItemMaster IMS WITH (NOLOCK) ON IMS.ItemMasterId = MSTL.ItemMasterId
				WHERE WOM.IsDeleted = 0 AND WOM.SubWOPartNoId = @subWOPartNoId AND ISNULL(WOM.IsAltPart, 0) = 0 AND ISNULL(WOM.IsEquPart, 0) = 0
				AND (ISNULL(WOM.Quantity,0) - ISNULL(WOM.QuantityIssued,0) > 0)
				AND WOM.SubWorkOrderMaterialsKitMappingId IN (SELECT SubWorkOrderMaterialsKitMappingId FROM #TMPWOMaterialResultListData WHERE IsKit = 1);
		END
		ELSE
		BEGIN
			
			INSERT INTO	#finalMaterialListResult([PartNumber], [PartDescription], [StocklinePartNumber], [StocklinePartDescription], [KitNumber], [KitDescription], [KitCost], [WOQMaterialKitMappingId], [KitId],
								[ItemGroup], [ManufacturerName], [WorkOrderNumber], [SubWorkOrderNo], [SubWorkOrderId], [SalesOrder], [Site], [WareHouse], [Location], [Shelf], [Bin], [PartStatusId], [Provision], 
								[ProvisionStatusCode], [StockType], [ItemType], [Condition], [StocklineCondition], [UnitCost], [ExtendedCost], [TotalStocklineQtyReq], [WOMStockLIneId], [StocklineUnitCost], 
								[StocklineExtendedCost],[StockLineProvisionId], [StocklineProvision], [StocklineProvisionStatusCode], [StockLineNumber], [SerialNumber], [ControlId], [ControlNo], [Receiver],
								[StockLineQuantityOnHand], [StockLineQuantityAvailable], [PartQuantityOnHand], [PartQuantityAvailable], [PartQuantityReserved], [PartQuantityTurnIn], [PartQuantityOnOrder], [CostDate], 
								[Currency], [QuantityIssued], [QuantityReserved], [QunatityRemaining], [StocklineQuantity], [StocklineQtyReserved], [StocklineQtyIssued], [PartQtyToTurnIn], [QtytobeReserved], 
								[StocklineQtytobeReserved],[StocklineQuantityTurnIn], [StocklineQtyToTurnIn], [StocklineQtyRemaining], [Quantity], [ConditionCodeId], [StocklineConditionCodeId],[UnitOfMeasureId], 
								[WorkOrderId], [QtyOnOrder], [QtyOnBkOrder], [PONum], [PONextDlvrDate], [POId], [ItemMasterId], [ItemClassificationId], [PurchaseUnitOfMeasureId], [Memo], [IsDeferred], [TaskId],
								[TaskName], [MandatoryOrSupplemental], [MaterialMandatoriesId], [MasterCompanyId], [IsAltPart], [IsEquPart], [ItemClassification], [UOM], [Defered], [IsRoleUp], [ProvisionId], 
								[SubWorkOrderMaterialsId], [SubWOPartNoId], [IsFromWorkFlow], [StockLineId], [Employeename], [RONextDlvrDate], [RepairOrderNumber], [Figure], [Item], [StockLineFigure], [StockLineItem],
								[IsKitType], [KitQty], [IsWOMSAltPart], [IsWOMSEquPart], [AlterPartNumber])
				SELECT DISTINCT   
				  IM.PartNumber,  
				  IM.PartDescription,   
				  IMS.PartNumber StocklinePartNumber,
				  IMS.PartDescription StocklinePartDescription,
				  '' AS KitNumber,
				  '' AS KitDescription,
				  0 AS KitCost,
				  0 as WOQMaterialKitMappingId,
				  0 AS KitId,
				  IM.ItemGroup,  
				  IM.ManufacturerName,  
				  W.WorkOrderNum As WorkOrderNumber,  
				  --WOM.WorkOrderId,  
				  SWO.SubWorkOrderNo as SubWorkOrderNo,  
				  SWO.SubWorkOrderId,  
				  '' AS SalesOrder,  
				  IM.SiteName AS Site,  
				  IM.WarehouseName AS WareHouse,  
				  IM.LocationName AS Location,  
				  IM.ShelfName AS Shelf,  
				  IM.BinName AS Bin,  
				  WOM.PartStatusId,  
				  P.Description AS Provision,  
				  P.StatusCode AS ProvisionStatusCode,  
				  CASE   
				  WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'  
				  WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'  
				  WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'  
				  ELSE 'OEM'  
				  END AS StockType,  
				  CASE   
				  WHEN IM.ItemTypeId = 1 THEN 'Stock'  
				  WHEN IM.ItemTypeId = 2 THEN 'Non Stock'  
				  WHEN IM.ItemTypeId = 3 THEN 'Equipment'  
				  WHEN IM.ItemTypeId = 4 THEN 'Loan'  
				  ELSE ''  
				  END AS ItemType,  
				  C.Description AS Condition,        
				  Stk_C.Description AS StocklineCondition,
				  ISNULL(WOM.UnitCost,0),  
				  ISNULL(WOM.ExtendedCost,0),  
				  ISNULL(WOM.TotalStocklineQtyReq,0),  
				  ISNULL(MSTL.StockLIneId,0),         
				  ISNULL(MSTL.UnitCost,0) StocklineUnitCost,  
				  ISNULL(MSTL.ExtendedCost,0) StocklineExtendedCost,  
				  ISNULL(MSTL.ProvisionId,0) AS StockLineProvisionId,  
				  SP.Description AS StocklineProvision,  
				  SP.StatusCode AS StocklineProvisionStatusCode,  
				  SL.StockLineNumber,  
				  SL.SerialNumber,  
				  SL.IdNumber AS ControlId,  
				  SL.ControlNumber AS ControlNo,  
				  SL.ReceiverNumber AS Receiver,  
				  ISNULL(SL.QuantityOnHand,0) AS StockLineQuantityOnHand,  
				  ISNULL(SL.QuantityAvailable,0) AS StockLineQuantityAvailable,  
  
				  PartQuantityOnHand = ISNULL((SELECT SUM(ISNULL(sl.QuantityOnHand,0)) FROM #tmpStockline sl  WITH (NOLOCK)  
					  Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1            
					  ),0),  
				  PartQuantityAvailable = ISNULL((SELECT SUM(ISNULL(sl.QuantityAvailable,0)) FROM #tmpStockline sl  WITH (NOLOCK)  
					  Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1  
					  ),0),  
  
				  PartQuantityReserved = ISNULL((SELECT SUM(ISNULL(sl.QuantityReserved,0)) FROM #tmpWOMStockline womsl  WITH (NOLOCK)  
					  JOIN #tmpStockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId   
					  Where womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId  
					  AND womsl.isActive = 1 AND womsl.isDeleted = 0  
					  ),0),  
				  PartQuantityTurnIn = ISNULL((SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.SubWorkOrderMaterialStockLine womsl WITH (NOLOCK)   
					  JOIN #tmpStockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId  
					  Where womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId  
					  AND womsl.isActive = 1 AND womsl.isDeleted = 0  
					  ),0),  
				  PartQuantityOnOrder = ISNULL((SELECT SUM(ISNULL(sl.QuantityOnOrder,0)) FROM #tmpWOMStockline womsl  WITH (NOLOCK)  
					  JOIN #tmpStockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId  
					  Where womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId  
					  AND womsl.isActive = 1 AND womsl.isDeleted = 0  
					  ),0),  
				  CostDate = (SELECT TOP 1 CONVERT(varchar, IMPS.PP_LastListPriceDate, 101) FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND  
					 IMPS.ConditionId = WOM.ConditionCodeId AND IMPS.PP_LastListPriceDate IS NOT NULL),  
				  Currency = (SELECT TOP 1 CUR.Code  FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) LEFT JOIN dbo.Currency CUR WITH (NOLOCK) ON IMPS.PP_CurrencyId = CUR.CurrencyId   
					 WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId ),  
				  QuantityIssued = ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued,0)) FROM #tmpWOMStockline womsl WITH (NOLOCK)   
					  WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0),  
				  QuantityReserved = ISNULL((SELECT SUM(ISNULL(womsl.QtyReserved,0)) FROM #tmpWOMStockline womsl  WITH (NOLOCK)  
					   WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0),  
				  QunatityRemaining = ISNULL(WOM.Quantity - ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued,0)) FROM #tmpWOMStockline womsl  WITH (NOLOCK)  
					   WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0), 0),0),  
				  ISNULL(MSTL.Quantity,0) AS StocklineQuantity,  
				  ISNULL(MSTL.QtyReserved,0) AS StocklineQtyReserved,  
				  ISNULL(MSTL.QtyIssued,0) AS StocklineQtyIssued,  
				  ISNULL(WOM.QtyToTurnIn,0) AS PartQtyToTurnIn,
				  ISNULL(WOM.Quantity, 0) - Isnull((SELECT SUM(ISNULL(womsl.QtyIssued,0)) FROM #tmpWOMStockline womsl WITH (NOLOCK)   
					  WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0) - Isnull((SELECT SUM(ISNULL(womsl.QtyReserved,0)) FROM #tmpWOMStockline womsl  WITH (NOLOCK)  
					   WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0)  AS QtytobeReserved,
				  ISNULL(MSTL.Quantity, 0) - (ISNULL(MSTL.QtyIssued,0) + ISNULL(MSTL.QtyReserved,0)) AS StocklineQtytobeReserved,
				  --SL.QuantityTurnIn as StocklineQuantityTurnIn,  
				  ISNULL(MSTL.QuantityTurnIn, 0) as StocklineQuantityTurnIn,
				  CASE WHEN MSTL.ProvisionId = @SubProvisionId AND ISNULL(MSTL.Quantity, 0) != 0 THEN MSTL.Quantity 
					ELSE CASE WHEN MSTL.ProvisionId = @SubProvisionId OR MSTL.ProvisionId = @ForStockProvisionId THEN SL.QuantityTurnIn ELSE 0 END END AS 'StocklineQtyToTurnIn',
				  ISNULL(MSTL.Quantity, 0) - ISNULL(MSTL.QtyIssued,0) AS StocklineQtyRemaining,  
				  ISNULL(WOM.Quantity,0),  
				  ISNULL(WOM.ConditionCodeId,0),  
				  ISNULL(MSTL.ConditionId,0) AS StocklineConditionCodeId,
				  ISNULL(WOM.UnitOfMeasureId,0),  
				  ISNULL(WOM.WorkOrderId,0),  
				  ISNULL(WOM.QtyOnOrder,0),   
				  ISNULL(WOM.QtyOnBkOrder,0),  
				  WOM.PONum,  
				  WOM.PONextDlvrDate,  
				  ISNULL(WOM.POId,0),  
				  IM.ItemMasterId,  
				  IM.ItemClassificationId,  
				  IM.PurchaseUnitOfMeasureId,  
				  WOM.Memo,  
				  ISNULL(WOM.IsDeferred, 0),
				  WOM.TaskId,  
				  T.Description AS TaskName,  
				  MM.Name AS MandatoryOrSupplemental,  
				  WOM.MaterialMandatoriesId,  
				  WOM.MasterCompanyId,  
				  WOM.IsAltPart,  
				  WOM.IsEquPart,  
				  WOM.ItemClassification AS ItemClassification,  
				  --UOM.ShortName AS UOM,  
				  CASE WHEN SUOM.UnitOfMeasureId IS NOT NULL THEN SUOM.ShortName ELSE UOM.ShortName END AS UOM,
				  CASE WHEN WOM.IsDeferred = NULL OR WOM.IsDeferred = 0 THEN 'No' ELSE 'Yes' END AS Defered,  
				  IsRoleUp = 0,  
				  WOM.ProvisionId,  
				  WOM.SubWorkOrderMaterialsId,  
				  WOM.SubWOPartNoId,  
				  ISNULL(WOM.IsFromWorkFlow,0) as IsFromWorkFlow,  
				  ISNULL(SL.StockLineId,0) AS  StockLIneId ,  
				  Employeename = (SELECT TOP 1 (EMP.FirstName +''+ EMP.LastName) FROM dbo.Employee EMP WITH (NOLOCK) WHERE W.EmployeeID = EMP.EmployeeID ),  
				  ROP.EstRecordDate 'RONextDlvrDate',  
				  RO.RepairOrderNumber
				  ,WOM.Figure Figure
				  ,WOM.Item Item
				  ,MSTL.Figure StockLineFigure
				  ,MSTL.Item StockLineItem
				  ,0 AS IsKitType
				  ,0 AS KitQty
				  ,(CASE 
						WHEN ISNULL(MSTL.IsAltPart, 0) = 0 
						THEN 0
						ELSE MSTL.IsAltPart 
						END
					) AS IsWOMSAltPart,
					(CASE 
						WHEN ISNULL(MSTL.IsEquPart, 0) = 0 
						THEN 0 
						ELSE MSTL.IsEquPart
						END
					) AS IsWOMSEquPart,
					(SELECT partnumber FROM itemmaster IM WHERE IM.ItemMasterId = 
					(CASE 
						WHEN ISNULL(MSTL.AltPartMasterPartId, 0) = 0 
						THEN 
							CASE 
							WHEN ISNULL(MSTL.EquPartMasterPartId, 0) = 0 
							THEN 0
							ELSE MSTL.EquPartMasterPartId
							END
						ELSE MSTL.AltPartMasterPartId
						END)
					) AS AlterPartNumber
			 FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK)    
				  JOIN dbo.WorkOrder W WITH (NOLOCK) ON W.WorkOrderId = WOM.WorkOrderId  
				  JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId  
				  JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId  
				  JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId        
				  JOIN dbo.SubWorkOrderPartNumber wo WITH (NOLOCK) ON wo.SubWOPartNoId = WOM.SubWOPartNoId  
				  JOIN dbo.MaterialMandatories MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId  
				  LEFT JOIN dbo.SubWorkOrderMaterialStockLine MSTL WITH (NOLOCK) ON MSTL.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND MSTL.IsDeleted = 0  
				  LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId  
				  LEFT JOIN dbo.Condition Stk_C WITH (NOLOCK) ON Stk_C.ConditionId = SL.ConditionId
				  LEFT JOIN dbo.UnitOfMeasure SUOM WITH (NOLOCK) ON SUOM.UnitOfMeasureId = SL.PurchaseUnitOfMeasureId
				  LEFT JOIN dbo.ItemClassification ITC WITH (NOLOCK) ON ITC.ItemClassificationId = IM.ItemClassificationId  
				  LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId     
				  LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = MSTL.ProvisionId  
				  LEFT JOIN dbo.Task T WITH (NOLOCK) ON T.TaskId = WOM.TaskId  
				  LEFT JOIN dbo.SubWorkOrder SWO WITH (NOLOCK) ON SWO.SubWorkOrderId = WOM.SubWorkOrderId  
				  LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) ON SL.RepairOrderPartRecordId = ROP.RepairOrderPartRecordId  
				  LEFT JOIN dbo.RepairOrder RO WITH (NOLOCK) ON SL.RepairOrderId = RO.RepairOrderId  
				  LEFT JOIN dbo.ItemMaster IMS WITH (NOLOCK) ON IMS.ItemMasterId = MSTL.ItemMasterId
			 WHERE WOM.IsDeleted = 0 AND WOM.SubWOPartNoId = @subWOPartNoId AND ISNULL(WOM.IsAltPart, 0) = 0 AND ISNULL(WOM.IsEquPart, 0) = 0 
			 AND WOM.SubWorkOrderMaterialsId IN (SELECT SubWorkOrderMaterialsId FROM #TMPWOMaterialResultListData WHERE IsKit = 0)

			 --UNION ALL
			INSERT INTO	#finalMaterialListResult([PartNumber], [PartDescription], [StocklinePartNumber], [StocklinePartDescription], [KitNumber], [KitDescription], [KitCost], [WOQMaterialKitMappingId], [KitId],
							[ItemGroup], [ManufacturerName], [WorkOrderNumber], [SubWorkOrderNo], [SubWorkOrderId], [SalesOrder], [Site], [WareHouse], [Location], [Shelf], [Bin], [PartStatusId], [Provision], 
							[ProvisionStatusCode], [StockType], [ItemType], [Condition], [StocklineCondition], [UnitCost], [ExtendedCost], [TotalStocklineQtyReq], [WOMStockLIneId], [StocklineUnitCost], 
							[StocklineExtendedCost],[StockLineProvisionId], [StocklineProvision], [StocklineProvisionStatusCode], [StockLineNumber], [SerialNumber], [ControlId], [ControlNo], [Receiver],
							[StockLineQuantityOnHand], [StockLineQuantityAvailable], [PartQuantityOnHand], [PartQuantityAvailable], [PartQuantityReserved], [PartQuantityTurnIn], [PartQuantityOnOrder], [CostDate], 
							[Currency], [QuantityIssued], [QuantityReserved], [QunatityRemaining], [StocklineQuantity], [StocklineQtyReserved], [StocklineQtyIssued], [PartQtyToTurnIn], [QtytobeReserved], 
							[StocklineQtytobeReserved],[StocklineQuantityTurnIn], [StocklineQtyToTurnIn], [StocklineQtyRemaining], [Quantity], [ConditionCodeId], [StocklineConditionCodeId],[UnitOfMeasureId], 
							[WorkOrderId], [QtyOnOrder], [QtyOnBkOrder], [PONum], [PONextDlvrDate], [POId], [ItemMasterId], [ItemClassificationId], [PurchaseUnitOfMeasureId], [Memo], [IsDeferred], [TaskId],
							[TaskName], [MandatoryOrSupplemental], [MaterialMandatoriesId], [MasterCompanyId], [IsAltPart], [IsEquPart], [ItemClassification], [UOM], [Defered], [IsRoleUp], [ProvisionId], 
							[SubWorkOrderMaterialsId], [SubWOPartNoId], [IsFromWorkFlow], [StockLineId], [Employeename], [RONextDlvrDate], [RepairOrderNumber], [Figure], [Item], [StockLineFigure], [StockLineItem],
							[IsKitType], [KitQty], [IsWOMSAltPart], [IsWOMSEquPart], [AlterPartNumber])
			 SELECT DISTINCT   
				  IM.PartNumber,  
				  IM.PartDescription,   
				  IMS.PartNumber StocklinePartNumber,
				  IMS.PartDescription StocklinePartDescription,
				  WOMKM.KitNumber AS KitNumber,
				  (SELECT KM.KitDescription FROM [dbo].[KitMaster] KM WITH (NOLOCK) WHERE KM.KitId = WOMKM.KitId) AS KitDescription,
				  (SELECT KM.KitCost FROM [dbo].[KitMaster] KM WITH (NOLOCK) WHERE KM.KitId = WOMKM.KitId) AS KitCost,
				  0 as WOQMaterialKitMappingId,
				  WOMKM.KitId AS KitId,
				  IM.ItemGroup,  
				  IM.ManufacturerName,  
				  W.WorkOrderNum As WorkOrderNumber,  
				  --WOM.WorkOrderId,  
				  SWO.SubWorkOrderNo as SubWorkOrderNo,  
				  SWO.SubWorkOrderId,  
				  '' AS SalesOrder,  
				  IM.SiteName AS Site,  
				  IM.WarehouseName AS WareHouse,  
				  IM.LocationName AS Location,  
				  IM.ShelfName AS Shelf,  
				  IM.BinName AS Bin,  
				  WOM.PartStatusId,  
				  P.Description AS Provision,  
				  P.StatusCode AS ProvisionStatusCode,  
				  CASE   
				  WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'  
				  WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'  
				  WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'  
				  ELSE 'OEM'  
				  END AS StockType,  
				  CASE   
				  WHEN IM.ItemTypeId = 1 THEN 'Stock'  
				  WHEN IM.ItemTypeId = 2 THEN 'Non Stock'  
				  WHEN IM.ItemTypeId = 3 THEN 'Equipment'  
				  WHEN IM.ItemTypeId = 4 THEN 'Loan'  
				  ELSE ''  
				  END AS ItemType,  
				  C.Description AS Condition,        
				  Stk_C.Description AS StocklineCondition,
				  ISNULL(WOM.UnitCost,0),  
				  ISNULL(WOM.ExtendedCost,0),  
				  ISNULL(WOM.TotalStocklineQtyReq,0),  
				  ISNULL(MSTL.StockLIneId,0),         
				  ISNULL(MSTL.UnitCost,0) StocklineUnitCost,  
				  ISNULL(MSTL.ExtendedCost,0) StocklineExtendedCost,  
				  ISNULL(MSTL.ProvisionId,0) AS StockLineProvisionId,  
				  SP.Description AS StocklineProvision,  
				  SP.StatusCode AS StocklineProvisionStatusCode,  
				  SL.StockLineNumber,  
				  SL.SerialNumber,  
				  SL.IdNumber AS ControlId,  
				  SL.ControlNumber AS ControlNo,  
				  SL.ReceiverNumber AS Receiver,  
				  ISNULL(SL.QuantityOnHand,0) AS StockLineQuantityOnHand,  
				  ISNULL(SL.QuantityAvailable,0) AS StockLineQuantityAvailable,  
  
				  PartQuantityOnHand = ISNULL((SELECT SUM(ISNULL(sl.QuantityOnHand,0)) FROM #tmpStocklineKit sl  WITH (NOLOCK)  
					  Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1            
					  ),0),  
				  PartQuantityAvailable = ISNULL((SELECT SUM(ISNULL(sl.QuantityAvailable,0)) FROM #tmpStocklineKit sl  WITH (NOLOCK)  
					  Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1  
					  ),0),  
  
				  PartQuantityReserved = ISNULL((SELECT SUM(ISNULL(sl.QuantityReserved,0)) FROM #tmpWOMStocklineKit womsl  WITH (NOLOCK)  
					  JOIN #tmpStocklineKit sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId   
					  Where womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId  
					  AND womsl.isActive = 1 AND womsl.isDeleted = 0  
					  ),0),  
				  PartQuantityTurnIn = ISNULL((SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.SubWorkOrderMaterialStockLineKit womsl WITH (NOLOCK)   
					  JOIN #tmpStockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId  
					  Where womsl.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId  
					  AND womsl.isActive = 1 AND womsl.isDeleted = 0  
					  ),0),  
				  PartQuantityOnOrder = ISNULL((SELECT SUM(ISNULL(sl.QuantityOnOrder,0)) FROM #tmpWOMStocklineKit womsl  WITH (NOLOCK)  
					  JOIN #tmpStocklineKit sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId  
					  Where womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId  
					  AND womsl.isActive = 1 AND womsl.isDeleted = 0  
					  ),0),  
				  CostDate = (SELECT TOP 1 CONVERT(varchar, IMPS.PP_LastListPriceDate, 101) FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND  
					 IMPS.ConditionId = WOM.ConditionCodeId AND IMPS.PP_LastListPriceDate IS NOT NULL),  
				  Currency = (SELECT TOP 1 CUR.Code  FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) LEFT JOIN dbo.Currency CUR WITH (NOLOCK) ON IMPS.PP_CurrencyId = CUR.CurrencyId   
					 WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId ),  
				  QuantityIssued = ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued,0)) FROM #tmpWOMStocklinekit womsl WITH (NOLOCK)   
					  WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0),  
				  QuantityReserved = ISNULL((SELECT SUM(ISNULL(womsl.QtyReserved,0)) FROM #tmpWOMStocklinekit womsl  WITH (NOLOCK)  
					   WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0),  
				  QunatityRemaining = ISNULL(WOM.Quantity - ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued,0)) FROM #tmpWOMStocklinekit womsl  WITH (NOLOCK)  
					   WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0), 0),0),  
				  ISNULL(MSTL.Quantity,0) AS StocklineQuantity,  
				  ISNULL(MSTL.QtyReserved,0) AS StocklineQtyReserved,  
				  ISNULL(MSTL.QtyIssued,0) AS StocklineQtyIssued,  
				  ISNULL(WOM.QtyToTurnIn,0) AS PartQtyToTurnIn,
				  ISNULL(WOM.Quantity, 0) - Isnull((SELECT SUM(ISNULL(womsl.QtyIssued,0)) FROM #tmpWOMStocklinekit womsl WITH (NOLOCK)   
					  WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0) - Isnull((SELECT SUM(ISNULL(womsl.QtyReserved,0)) FROM #tmpWOMStocklinekit womsl  WITH (NOLOCK)  
					   WHERE womsl.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0)  AS QtytobeReserved,
				  ISNULL(MSTL.Quantity, 0) - (ISNULL(MSTL.QtyIssued,0) + ISNULL(MSTL.QtyReserved,0)) AS StocklineQtytobeReserved,
				  ISNULL(MSTL.QuantityTurnIn, 0) as StocklineQuantityTurnIn,
				  CASE WHEN MSTL.ProvisionId = @SubProvisionId AND ISNULL(MSTL.Quantity, 0) != 0 THEN MSTL.Quantity 
					ELSE CASE WHEN MSTL.ProvisionId = @SubProvisionId OR MSTL.ProvisionId = @ForStockProvisionId THEN SL.QuantityTurnIn ELSE 0 END END AS 'StocklineQtyToTurnIn',
				  ISNULL(MSTL.Quantity, 0) - ISNULL(MSTL.QtyIssued,0) AS StocklineQtyRemaining,  
				  ISNULL(WOM.Quantity,0),  
				  ISNULL(WOM.ConditionCodeId,0),  
				  ISNULL(MSTL.ConditionId,0) AS StocklineConditionCodeId,
				  ISNULL(WOM.UnitOfMeasureId,0),  
				  ISNULL(WOM.WorkOrderId,0),  
				  ISNULL(WOM.QtyOnOrder,0),   
				  ISNULL(WOM.QtyOnBkOrder,0),  
				  WOM.PONum,  
				  WOM.PONextDlvrDate,  
				  ISNULL(WOM.POId,0),    
				  IM.ItemMasterId,  
				  IM.ItemClassificationId,  
				  IM.PurchaseUnitOfMeasureId,  
				  WOM.Memo,  
				  ISNULL(WOM.IsDeferred, 0),
				  WOM.TaskId,  
				  T.Description AS TaskName,  
				  MM.Name AS MandatoryOrSupplemental,  
				  WOM.MaterialMandatoriesId,  
				  WOM.MasterCompanyId,  
				  WOM.IsAltPart,  
				  WOM.IsEquPart,  
				  WOM.ItemClassification AS ItemClassification,  
				  CASE WHEN SUOM.UnitOfMeasureId IS NOT NULL THEN SUOM.ShortName ELSE UOM.ShortName END AS UOM,
				  CASE WHEN WOM.IsDeferred = NULL OR WOM.IsDeferred = 0 THEN 'No' ELSE 'Yes' END AS Defered,  
				  IsRoleUp = 0,  
				  WOM.ProvisionId,  
				  WOM.SubWorkOrderMaterialsKitId AS SubWorkOrderMaterialsId,  
				  WOM.SubWOPartNoId,  
				  ISNULL(WOM.IsFromWorkFlow,0) as IsFromWorkFlow,  
				  ISNULL(SL.StockLineId,0) AS  StockLIneId ,  
				  Employeename = (SELECT TOP 1 (EMP.FirstName +''+ EMP.LastName) FROM dbo.Employee EMP WITH (NOLOCK) WHERE W.EmployeeID = EMP.EmployeeID ),  
				  ROP.EstRecordDate 'RONextDlvrDate',  
				  RO.RepairOrderNumber
				  ,WOM.Figure Figure
				  ,WOM.Item Item
				  ,MSTL.Figure StockLineFigure
				  ,MSTL.Item StockLineItem
				  ,1 AS IsKitType
				  ,(SELECT SUM(ISNULL(WOMK.Quantity, 0)) FROM dbo.SubWorkOrderMaterialsKit WOMK WITH (NOLOCK) WHERE WOMK.SubWorkOrderMaterialsKitMappingId = WOMKM.SubWorkOrderMaterialsKitMappingId) AS KitQty
				  ,(CASE 
						WHEN ISNULL(MSTL.IsAltPart, 0) = 0 
						THEN 0
						ELSE MSTL.IsAltPart 
						END
					) AS IsWOMSAltPart,
					(CASE 
						WHEN ISNULL(MSTL.IsEquPart, 0) = 0 
						THEN 0 
						ELSE MSTL.IsEquPart
						END
					) AS IsWOMSEquPart,
					(SELECT partnumber FROM itemmaster IM WHERE IM.ItemMasterId = 
					(CASE 
						WHEN ISNULL(MSTL.AltPartMasterPartId, 0) = 0 
						THEN 
							CASE 
							WHEN ISNULL(MSTL.EquPartMasterPartId, 0) = 0 
							THEN 0
							ELSE MSTL.EquPartMasterPartId
							END
						ELSE MSTL.AltPartMasterPartId
						END)
					) AS AlterPartNumber
			 FROM dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK)    
				  JOIN dbo.WorkOrder W WITH (NOLOCK) ON W.WorkOrderId = WOM.WorkOrderId  
				  JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId  
				  JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId  
				  JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId        
				  JOIN dbo.SubWorkOrderPartNumber wo WITH (NOLOCK) ON wo.SubWOPartNoId = WOM.SubWOPartNoId  
				  JOIN dbo.MaterialMandatories MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId  
				  LEFT JOIN dbo.SubWorkOrderMaterialStockLineKit MSTL WITH (NOLOCK) ON MSTL.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND MSTL.IsDeleted = 0  
				  LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId  
				  LEFT JOIN dbo.Condition Stk_C WITH (NOLOCK) ON Stk_C.ConditionId = SL.ConditionId
				  LEFT JOIN dbo.UnitOfMeasure SUOM WITH (NOLOCK) ON SUOM.UnitOfMeasureId = SL.PurchaseUnitOfMeasureId
				  LEFT JOIN dbo.ItemClassification ITC WITH (NOLOCK) ON ITC.ItemClassificationId = IM.ItemClassificationId  
				  LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId     
				  LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = MSTL.ProvisionId  
				  LEFT JOIN dbo.Task T WITH (NOLOCK) ON T.TaskId = WOM.TaskId  
				  LEFT JOIN dbo.SubWorkOrder SWO WITH (NOLOCK) ON SWO.SubWorkOrderId = WOM.SubWorkOrderId  
				  LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) ON SL.RepairOrderPartRecordId = ROP.RepairOrderPartRecordId  
				  LEFT JOIN dbo.RepairOrder RO WITH (NOLOCK) ON SL.RepairOrderId = RO.RepairOrderId  
				  LEFT JOIN [dbo].[SubWorkOrderMaterialsKitMapping] WOMKM WITH (NOLOCK) ON WOMKM.SubWOPartNoId = wo.SubWOPartNoId AND WOMKM.SubWorkOrderMaterialsKitMappingId = WOM.SubWorkOrderMaterialsKitMappingId
				  LEFT JOIN dbo.ItemMaster IMS WITH (NOLOCK) ON IMS.ItemMasterId = MSTL.ItemMasterId
			 WHERE WOM.IsDeleted = 0 AND WOM.SubWOPartNoId = @subWOPartNoId AND ISNULL(WOM.IsAltPart, 0) = 0 AND ISNULL(WOM.IsEquPart, 0) = 0
			 AND WOMKM.SubWorkOrderMaterialsKitMappingId IN (SELECT SubWorkOrderMaterialsKitMappingId FROM #TMPWOMaterialResultListData WHERE IsKit = 1);  
		END

		SELECT @Count = COUNT(ParentID) from #TMPWOMaterialParentListData;

		SELECT *, @Count As NumberOfItems FROM #finalMaterialListResult
		ORDER BY    
					CASE WHEN (@SortOrder=1 and @SortColumn='taskName')  THEN taskName END ASC
					,CASE WHEN (@SortOrder=1 and @SortColumn='partNumber')  THEN partNumber END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='alterPartNumber')  THEN alterPartNumber END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='partDescription')  THEN partDescription END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='manufacturerName')  THEN manufacturerName END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='condition')  THEN condition END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='mandatoryOrSupplemental')  THEN mandatoryOrSupplemental END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='provision')  THEN provision END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='quantity')  THEN quantity END ASC,  
					--CASE WHEN (@SortOrder=1 and @SortColumn='kitStocklineQuantity')  THEN kitStocklineQuantity END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='quantityReserved')  THEN quantityReserved END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='qtytobeReserved')  THEN qtytobeReserved END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='quantityIssued')  THEN quantityIssued END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='qunatityRemaining')  THEN qunatityRemaining END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='partQtyToTurnIn')  THEN partQtyToTurnIn END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='partQuantityTurnIn')  THEN partQuantityTurnIn END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='partQuantityOnHand')  THEN partQuantityOnHand END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='partQuantityAvailable')  THEN partQuantityAvailable END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='uom')  THEN uom END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='stockType')  THEN stockType END ASC,  
					--CASE WHEN (@SortOrder=1 and @SortColumn='needDate')  THEN needDate END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='currency')  THEN currency END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='unitCost')  THEN unitCost END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='extendedCost')  THEN extendedCost END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='qtyOnOrder')  THEN qtyOnOrder END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='qtyOnBkOrder')  THEN qtyOnBkOrder END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='poNum')  THEN poNum END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='poNextDlvrDate')  THEN poNextDlvrDate END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='figure')  THEN figure END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='item')  THEN item END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='isFromWorkFlow')  THEN isFromWorkFlow END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='employeename')  THEN employeename END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='isDeferred')  THEN isDeferred END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='memo')  THEN memo END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='stocklineExtendedCost')  THEN stocklineExtendedCost END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='stockLineNumber')  THEN stockLineNumber END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='serialNumber')  THEN serialNumber END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='stocklineCondition')  THEN stocklineCondition END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='stocklineProvision')  THEN stocklineProvision END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='stocklineQuantity')  THEN stocklineQuantity END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='stocklineQtyReserved')  THEN stocklineQtyReserved END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='stocklineQtytobeReserved')  THEN stocklineQtytobeReserved END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='stocklineQtyIssued')  THEN stocklineQtyIssued END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='stocklineQtyRemaining')  THEN stocklineQtyRemaining END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='stocklineQtyToTurnIn')  THEN stocklineQtyToTurnIn END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='stocklineQuantityTurnIn')  THEN stocklineQuantityTurnIn END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='stockLineQuantityOnHand')  THEN stockLineQuantityOnHand END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='stockLineQuantityAvailable')  THEN stockLineQuantityAvailable END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='stocklineUnitCost')  THEN stocklineUnitCost END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='controlNo')  THEN controlNo END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='controlId')  THEN controlId END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='costDate')  THEN costDate END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='repairOrderNumber')  THEN repairOrderNumber END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='roNextDlvrDate')  THEN roNextDlvrDate END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='receiver')  THEN receiver END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='stockLineFigure')  THEN stockLineFigure END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='stockLineItem')  THEN stockLineItem END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='workOrderNumber')  THEN workOrderNumber END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='subWorkOrderNo')  THEN subWorkOrderNo END ASC, 
					CASE WHEN (@SortOrder=1 and @SortColumn='salesOrder')  THEN salesOrder END ASC, 

					CASE WHEN (@SortOrder=-1 and @SortColumn='taskName')  THEN taskName END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='partNumber')  THEN partNumber END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='alterPartNumber')  THEN alterPartNumber END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='partDescription')  THEN partDescription END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='manufacturerName')  THEN manufacturerName END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='condition')  THEN condition END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='mandatoryOrSupplemental')  THEN mandatoryOrSupplemental END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='provision')  THEN provision END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='quantity')  THEN quantity END DESC,  
					--CASE WHEN (@SortOrder=-1 and @SortColumn='kitStocklineQuantity')  THEN kitStocklineQuantity END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='quantityReserved')  THEN quantityReserved END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='qtytobeReserved')  THEN qtytobeReserved END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='quantityIssued')  THEN quantityIssued END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='qunatityRemaining')  THEN qunatityRemaining END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='partQtyToTurnIn')  THEN partQtyToTurnIn END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='partQuantityTurnIn')  THEN partQuantityTurnIn END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='partQuantityOnHand')  THEN partQuantityOnHand END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='partQuantityAvailable')  THEN partQuantityAvailable END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='uom')  THEN uom END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='stockType')  THEN stockType END DESC,  
					--CASE WHEN (@SortOrder=1 and @SortColumn='needDate')  THEN needDate END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='currency')  THEN currency END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='unitCost')  THEN unitCost END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='extendedCost')  THEN extendedCost END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='qtyOnOrder')  THEN qtyOnOrder END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='qtyOnBkOrder')  THEN qtyOnBkOrder END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='poNum')  THEN poNum END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='poNextDlvrDate')  THEN poNextDlvrDate END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='figure')  THEN figure END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='item')  THEN item END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='isFromWorkFlow')  THEN isFromWorkFlow END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='employeename')  THEN employeename END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='isDeferred')  THEN isDeferred END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='memo')  THEN memo END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='stocklineExtendedCost')  THEN stocklineExtendedCost END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='stockLineNumber')  THEN stockLineNumber END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='serialNumber')  THEN serialNumber END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='stocklineCondition')  THEN stocklineCondition END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='stocklineProvision')  THEN stocklineProvision END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='stocklineQuantity')  THEN stocklineQuantity END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='stocklineQtyReserved')  THEN stocklineQtyReserved END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='stocklineQtytobeReserved')  THEN stocklineQtytobeReserved END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='stocklineQtyIssued')  THEN stocklineQtyIssued END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='stocklineQtyRemaining')  THEN stocklineQtyRemaining END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='stocklineQtyToTurnIn')  THEN stocklineQtyToTurnIn END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='stocklineQuantityTurnIn')  THEN stocklineQuantityTurnIn END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='stockLineQuantityOnHand')  THEN stockLineQuantityOnHand END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='stockLineQuantityAvailable')  THEN stockLineQuantityAvailable END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='stocklineUnitCost')  THEN stocklineUnitCost END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='controlNo')  THEN controlNo END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='controlId')  THEN controlId END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='costDate')  THEN costDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='repairOrderNumber')  THEN repairOrderNumber END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='roNextDlvrDate')  THEN roNextDlvrDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='receiver')  THEN receiver END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='stockLineFigure')  THEN stockLineFigure END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='stockLineItem')  THEN stockLineItem END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='workOrderNumber')  THEN workOrderNumber END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='subWorkOrderNo')  THEN subWorkOrderNo END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='salesOrder')  THEN salesOrder END DESC;
    END  
   COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_GetSubWorkOrderMaterialsListNew'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@subWOPartNoId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
              exec spLogException   
                       @DatabaseName           = @DatabaseName  
                     , @AdhocComments          = @AdhocComments  
                     , @ProcedureParameters = @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END
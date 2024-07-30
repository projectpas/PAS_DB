/*************************************************************           
 ** File:   [USP_GetWorkOrderMaterialsListNew]           
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used retrieve Work Order Materials List With Pagination
 ** Purpose:         
 ** Date:   07/26/2024        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author					Change Description            
 ** --   --------     -------				--------------------------------          
    1	07/26/2024    Devendra Shekh			Created
	
 EXECUTE [dbo].[USP_GetWorkOrderMaterialsList] 4257,3782, 0
exec dbo.USP_GetWorkOrderMaterialsListNew @PageNumber=4,@PageSize=10,@SortColumn=default,@SortOrder=1,@WorkOrderId=4270,@WFWOId=3795,@ShowPendingToIssue=0
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWorkOrderMaterialsListNew]
(    
	@PageNumber int,  
	@PageSize int,  
	@SortColumn varchar(50)=null,  
	@SortOrder int,  
	@WorkOrderId BIGINT = NULL,   
	@WFWOId BIGINT  = NULL,
	@ShowPendingToIssue BIT  = 0
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		--BEGIN TRANSACTION
			BEGIN  

				--Local Param For Reading SP Params Values : Start
				DECLARE @Local_PageNumber int, @Local_PageSize int, @Local_SortColumn varchar(50)=null, @Local_SortOrder int, @Local_WorkOrderId BIGINT = NULL, @Local_WFWOId BIGINT  = NULL, @Local_ShowPendingToIssue BIT  = 0;
				SELECT @Local_PageNumber = @PageNumber,
					@Local_PageSize = @PageSize, @Local_SortColumn = @SortColumn, @Local_SortOrder = @SortOrder, 
					@Local_WorkOrderId = @WorkOrderId, @Local_WFWOId = @WFWOId, @Local_ShowPendingToIssue = @ShowPendingToIssue;
				--Local Param For Reading SP Params Values : End

				DECLARE @RecordFrom int;  
				DECLARE @MasterCompanyId INT;
				DECLARE @SubProvisionId INT;
				DECLARE @ForStockProvisionId INT;
				DECLARE @exchangeProvision varchar(100) = (SELECT TOP 1 Description FROM dbo.Provision WITH(NOLOCK) where UPPER(StatusCode) = 'EXCHANGE')
				DECLARE @CustomerID BIGINT, @IsTeardownWO bit = 0, @WoTypeId int = 0;
				DECLARE @Count Int;  
				DECLARE @WOPartNoId BIGINT;

				IF @Local_SortColumn IS NULL
				BEGIN  
					SET @Local_SortColumn = ('taskName')
				END

				SELECT @MasterCompanyId = MasterCompanyId,@WoTypeId = WorkOrderTypeId FROM dbo.WorkOrder WITH (NOLOCK) WHERE WorkOrderId = @Local_WorkOrderId;
				SELECT @WOPartNoId = WorkOrderPartNoId FROM dbo.WorkOrderWorkFlow WITH (NOLOCK) WHERE WorkFlowWorkOrderId = @Local_WFWOId;
				SET @IsTeardownWO = (CASE WHEN (Select TOP 1 ID from dbo.WorkOrderType WITH(NOLOCK) WHERE UPPER(Description) = UPPER('Teardown') ) = @WoTypeId THEN 1 ELSE 0 END )
				SELECT @SubProvisionId = ProvisionId FROM dbo.Provision WITH (NOLOCK) WHERE UPPER(StatusCode) = 'SUB WORK ORDER'
				SELECT @ForStockProvisionId = ProvisionId FROM dbo.Provision WITH (NOLOCK) WHERE UPPER(StatusCode) = 'FOR STOCK'
				SELECT @CustomerID = WO.CustomerId, @MasterCompanyId = WO.MasterCompanyId FROM dbo.WorkOrder WO WITH(NOLOCK) JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) on WO.WorkOrderId = WOWF.WorkOrderId WHERE WOWF.WorkFlowWorkOrderId = @Local_WFWOId;
				
				SET @RecordFrom = (@Local_PageNumber-1)*@Local_PageSize;  

				IF OBJECT_ID(N'tempdb..#tmpStockline') IS NOT NULL
				BEGIN
				DROP TABLE #tmpStockline
				END

				IF OBJECT_ID(N'tempdb..#tmpWOMStockline') IS NOT NULL
				BEGIN
				DROP TABLE #tmpWOMStockline
				END

				IF OBJECT_ID(N'tempdb..#finalMaterialListResult') IS NOT NULL
				BEGIN
				DROP TABLE #finalMaterialListResult
				END

				IF OBJECT_ID(N'tempdb..#TMPWOMaterialParentListData') IS NOT NULL
				BEGIN
				DROP TABLE #TMPWOMaterialParentListData
				END

				IF OBJECT_ID(N'tempdb..#TMPWOMaterialResultListData') IS NOT NULL
				BEGIN
				DROP TABLE #TMPWOMaterialResultListData
				END

				IF OBJECT_ID(N'tempdb..#tmpStocklineKit') IS NOT NULL
				BEGIN
				DROP TABLE #tmpStocklineKit
				END

				IF OBJECT_ID(N'tempdb..#tmpWOMStocklineKit') IS NOT NULL
				BEGIN
				DROP TABLE #tmpWOMStocklineKit
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
					[WorkOrderMaterialsId] [bigint] NULL,
					[ConditionId] [bigint] NOT NULL,
					[QtyIssued] [int] NOT NULL,
					[QtyReserved] [int] NULL,
					[IsActive] BIT NULL,
					[IsDeleted] BIT NULL,
				)

				CREATE TABLE #TMPWOMaterialParentListData
				(
					[ParentID] BIGINT NOT NULL IDENTITY, 						 
					[WorkOrderMaterialsId] [bigint] NULL,
					[WorkOrderMaterialsKitMappingId] [bigint] NULL,
					[WorkFlowWorkOrderId] [bigint] NULL,
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
					[ItemMasterUnitCost] [decimal](18, 2) NULL,
					[ExtendedCost] [decimal](18, 2) NULL,
					[TotalStocklineQtyReq] [int] NULL,
					[StocklineUnitCost] [decimal](18, 2) NULL,
					[StocklineExtendedCost] [decimal](18, 2) NULL,
					[WOMStockLIneId] [bigint] NULL,
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
					[QunatityPicked] [int] NULL,
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
					[ReceivedDate] [datetime2] NULL,
					[POId] [bigint] NULL,
					[Quantity] [int] NULL,
					[StocklineQuantity] [int] NULL,
					[PartQtyToTurnIn] [int] NULL,
					[StocklineQtyToTurnIn] [int] NULL,
					[ConditionCodeId] [bigint] NULL,
					[StocklineConditionCodeId] [bigint] NULL,
					[UnitOfMeasureId] [bigint] NULL,
					[WorkOrderMaterialsId] [bigint] NULL,
					[WorkFlowWorkOrderId] [bigint] NULL,
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
					[ParentWorkOrderMaterialsId] [bigint] NULL,
					[IsAltPart] [bit] NULL,
					[IsEquPart] [bit] NULL,
					[ItemClassification] [varchar](250) NULL,
					[UOM] [varchar](100) NULL,
					[Defered] [varchar](50) NULL,
					[IsRoleUp] [bit] NULL,
					[ProvisionId] [int] NULL,
					[IsSubWorkOrderCreated] [bit] NULL,
					[IsSubWorkOrderClosed] [bit] NULL,
					[SubWorkOrderId] [bigint] NULL,
					[SubWorkOrderStockLineId] [bigint] NULL,
					[IsFromWorkFlow] [bit] NULL,
					[Employeename] [varchar](256) NULL,
					[RONextDlvrDate] [datetime2] NULL,
					[RepairOrderNumber] [varchar](150) NULL,
					[RepairOrderId] [bigint] NULL,
					[VendorId] [bigint] NULL,
					[VendorName] [varchar](150) NULL,
					[VendorCode] [varchar](150) NULL,
					[Figure] [nvarchar](250) NULL,
					[Item] [nvarchar](250) NULL,
					[StockLineFigure] [nvarchar](250) NULL,
					[StockLineItem] [nvarchar](250) NULL,
					[StockLineId] [bigint] NULL,
					[IsKitType] [bit] NULL,
					[KitQty] [int] NULL,
					[ExpectedSerialNumber] [varchar](250) NULL,
					[IsExchangeTender] [bit] NULL,
				)

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
					[WorkOrderMaterialsId] [bigint] NULL,
					[ConditionId] [bigint] NOT NULL,
					[QtyIssued] [int] NOT NULL,
					[QtyReserved] [int] NULL,
					[IsActive] BIT NULL,
					[IsDeleted] BIT NULL,
				)

				INSERT INTO #tmpStockline SELECT DISTINCT						
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
				JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.ItemMasterId = sl.ItemMasterId AND WOM.ConditionCodeId = SL.ConditionId AND SL.IsParent = 1
				WHERE SL.MasterCompanyId = @MasterCompanyId 
				AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
				AND  SL.IsActive = 1 AND SL.IsDeleted = 0

				INSERT INTO #tmpWOMStockline SELECT DISTINCT						
						WOMS.StockLineId, 						
						WOMS.WorkOrderMaterialsId,
						WOMS.ConditionId,
						WOMS.QtyIssued,
						WOMS.QtyReserved,
						WOMS.IsActive,
						WOMS.IsDeleted
				FROM dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) 
				JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId 
				AND WOM.WorkFlowWorkOrderId = @Local_WFWOId AND WOMS.IsActive = 1 AND WOMS.IsDeleted = 0

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
				JOIN dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.ItemMasterId = sl.ItemMasterId AND WOM.ConditionCodeId = SL.ConditionId AND SL.IsParent = 1
				WHERE SL.MasterCompanyId = @MasterCompanyId 
				AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
				AND  SL.IsActive = 1 AND SL.IsDeleted = 0

				INSERT INTO #tmpWOMStocklineKit SELECT DISTINCT						
						WOMS.StockLineId, 						
						WOMS.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,
						WOMS.ConditionId,
						WOMS.QtyIssued,
						WOMS.QtyReserved,
						WOMS.IsActive,
						WOMS.IsDeleted
				FROM dbo.WorkOrderMaterialStockLineKit WOMS WITH(NOLOCK) 
				JOIN dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.WorkOrderMaterialsKitId = WOMS.WorkOrderMaterialsKitId 
				AND WOM.WorkFlowWorkOrderId = @Local_WFWOId AND WOMS.IsActive = 1 AND WOMS.IsDeleted = 0

				--Inserting Data For Parent Level- For Pagination : Start
				INSERT INTO #TMPWOMaterialParentListData
				([WorkOrderMaterialsId], [WorkFlowWorkOrderId], [WorkOrderMaterialsKitMappingId], [IsKit])
				SELECT DISTINCT	[WorkOrderMaterialsId], [WorkFlowWorkOrderId], 0, 0 FROM [DBO].[WorkOrderMaterials] WOM WITH(NOLOCK) WHERE WOM.IsDeleted = 0 AND WOM.WorkFlowWorkOrderId = @Local_WFWOId;

				INSERT INTO #TMPWOMaterialParentListData
				([WorkOrderMaterialsId], [WorkFlowWorkOrderId], [WorkOrderMaterialsKitMappingId], [IsKit])
				SELECT DISTINCT	0, @Local_WFWOId, [WorkOrderMaterialsKitMappingId], 1 FROM [DBO].[WorkOrderMaterialsKitMapping] WOMKIT WITH(NOLOCK) WHERE WOMKIT.IsDeleted = 0 AND WOMKIT.WOPartNoId = @WOPartNoId;

				SELECT * INTO #TMPWOMaterialResultListData FROM #TMPWOMaterialParentListData tmp 
				ORDER BY tmp.WorkFlowWorkOrderId ASC
				OFFSET @RecordFrom ROWS   
				FETCH NEXT @Local_PageSize ROWS ONLY
				--Inserting Data For Parent Level- For Pagination : End

				IF (ISNULL(@Local_ShowPendingToIssue, 0) = 1)
				BEGIN
					--WorkOrderMaterial Data Insert
					INSERT INTO	#finalMaterialListResult([PartNumber], [PartDescription], [StocklinePartNumber], [StocklinePartDescription], [KitNumber], [KitDescription], [KitCost], [WOQMaterialKitMappingId], [KitId],
								[ItemGroup], [ManufacturerName], [WorkOrderNumber], [SubWorkOrderNo], [SalesOrder], [Site], [WareHouse], [Location], [Shelf], [Bin],
								[PartStatusId], [Provision], [ProvisionStatusCode], [StockType], [ItemType], [Condition], [StocklineCondition], [UnitCost], [ItemMasterUnitCost], [ExtendedCost],
								[TotalStocklineQtyReq], [StocklineUnitCost], [StocklineExtendedCost], [WOMStockLIneId], [StockLineProvisionId], [IsWOMSAltPart], [IsWOMSEquPart], [AlterPartNumber],
								[StocklineProvision], [StocklineProvisionStatusCode], [StockLineNumber], [SerialNumber], [ControlId], [ControlNo], [Receiver], [StockLineQuantityOnHand], [StockLineQuantityAvailable],
								[PartQuantityOnHand], [PartQuantityAvailable], [PartQuantityReserved], [PartQuantityTurnIn], [PartQuantityOnOrder], [CostDate], [Currency], [QuantityIssued], [QuantityReserved],
								[QunatityRemaining], [QunatityPicked], [StocklineQtyReserved], [QtytobeReserved], [StocklineQtyIssued], [StocklineQuantityTurnIn], [StocklineQtyRemaining], [StocklineQtytobeReserved],
								[QtyOnOrder], [QtyOnBkOrder], [PONum], [PONextDlvrDate], [ReceivedDate], [POId], [Quantity], [StocklineQuantity], [PartQtyToTurnIn], [StocklineQtyToTurnIn], [ConditionCodeId], [StocklineConditionCodeId],
								[UnitOfMeasureId], [WorkOrderMaterialsId], [WorkFlowWorkOrderId], [WorkOrderId], [ItemMasterId], [ItemClassificationId], [PurchaseUnitOfMeasureId], [Memo], [IsDeferred], [TaskId],
								[TaskName], [MandatoryOrSupplemental], [MaterialMandatoriesId], [MasterCompanyId], [ParentWorkOrderMaterialsId], [IsAltPart], [IsEquPart], [ItemClassification], [UOM],
								[Defered], [IsRoleUp], [ProvisionId], [IsSubWorkOrderCreated], [IsSubWorkOrderClosed], [SubWorkOrderId], [SubWorkOrderStockLineId], [IsFromWorkFlow], [Employeename], [RONextDlvrDate],
								[RepairOrderNumber], [RepairOrderId], [VendorId], [VendorName], [VendorCode], [Figure], [Item], [StockLineFigure], [StockLineItem], [StockLineId], [IsKitType], [KitQty], [ExpectedSerialNumber],
								[IsExchangeTender])
					SELECT DISTINCT IM.PartNumber,
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
						SL.WorkOrderNumber,
						CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.IsDeleted = 1 THEN '' ELSE SWO.SubWorkOrderNo END AS 'SubWorkOrderNo',
						--WOM.WorkOrderId,
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
						WOM.UnitCost,
						ISNULL(IMPS.PP_UnitPurchasePrice,0) AS ItemMasterUnitCost,
						WOM.ExtendedCost,
						WOM.TotalStocklineQtyReq,
						ISNULL(MSTL.UnitCost,0) StocklineUnitCost,
						ISNULL(MSTL.ExtendedCost,0) StocklineExtendedCost,
						ISNULL(MSTL.StockLIneId, 0) as StockLIneId,
						MSTL.ProvisionId AS StockLineProvisionId,
						(CASE 
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
						) AS AlterPartNumber,
						SP.Description AS StocklineProvision,
						SP.StatusCode AS StocklineProvisionStatusCode,
						SL.StockLineNumber,
						SL.SerialNumber,
						SL.IdNumber AS ControlId,
						SL.ControlNumber AS ControlNo,
						SL.ReceiverNumber AS Receiver,
						SL.QuantityOnHand AS StockLineQuantityOnHand,
						SL.QuantityAvailable AS StockLineQuantityAvailable,
						PartQuantityOnHand = ISNULL((SELECT SUM(ISNULL(sl.QuantityOnHand,0)) FROM #tmpStockline sl WITH (NOLOCK)
										Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1										
										),0),
						PartQuantityAvailable = ISNULL((SELECT SUM(ISNULL(sl.QuantityAvailable,0)) FROM #tmpStockline sl WITH (NOLOCK)
										Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1
										),0),
						PartQuantityReserved = ISNULL((SELECT SUM(ISNULL(sl.QuantityReserved,0)) FROM #tmpWOMStockline womsl WITH (NOLOCK)
										JOIN #tmpStockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId 
										Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0
										),0),
						PartQuantityTurnIn = ISNULL((CASE WHEN @IsTeardownWO = 1 THEN 
													(SELECT SUM(ISNULL(SL.QuantityTurnIn,0)) FROM  dbo.WorkOrderPartNumber WOP  WITH(NOLOCK) 
													 JOIN dbo.Stockline SL ON WOP.WorkOrderId = SL.WorkOrderId AND WOP.ID = SL.WorkOrderPartNoId AND Sl.WorkOrderId = @Local_WorkOrderId 
													 WHERE SL.WorkOrderId = WOM.WorkOrderId AND Sl.ConditionId = WOM.ConditionCodeId AND SL.ItemMasterId = IM.ItemMasterId AND ISNULL(SL.isActive,0) = 1 AND ISNULL(SL.isDeleted,0) = 0 ) 
											       ELSE (SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.WorkOrderMaterialStockLine womsl WITH (NOLOCK)
										                 JOIN dbo.Stockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
										                 Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
										                 AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0
										                ) 
											  END),0),
						PartQuantityOnOrder = ISNULL((SELECT SUM(ISNULL(sl.QuantityOnOrder,0)) FROM #tmpWOMStockline womsl WITH (NOLOCK)
										JOIN #tmpStockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
										Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0
										),0),
						CostDate = (SELECT TOP 1 CONVERT(varchar, IMPS.PP_LastListPriceDate, 101) FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK)
									WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId AND IMPS.PP_LastListPriceDate IS NOT NULL),
						Currency = (SELECT TOP 1 CUR.Code FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) 
									LEFT JOIN dbo.Currency CUR WITH (NOLOCK)  ON IMPS.PP_CurrencyId = CUR.CurrencyId 
									WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId ),
						QuantityIssued = ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0),
						QuantityReserved = ISNULL((SELECT SUM(ISNULL(womsl.QtyReserved, 0 )) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0),
						QunatityRemaining = ISNULL((WOM.Quantity + WOM.QtyToTurnIn) - (ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0) + ISNULL(
											(SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.WorkOrderMaterialStockLine womsl WITH (NOLOCK)
											JOIN dbo.Stockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
											Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
											AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0
											), 0)),0),
						QunatityPicked = ISNULL((SELECT SUM(wopt.QtyToShip) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) 
											WHERE wopt.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND wopt.WorkorderId = WOM.WorkOrderId),0),
						
						ISNULL(MSTL.QtyReserved,0) AS StocklineQtyReserved,
						ISNULL(ISNULL(WOM.Quantity, 0) - Isnull((SELECT SUM(ISNULL(womsl.QtyReserved, 0 )) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0) - Isnull((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0),0)  AS QtytobeReserved,
						ISNULL(MSTL.QtyIssued,0) AS StocklineQtyIssued,
						ISNULL(MSTL.QuantityTurnIn, 0) as StocklineQuantityTurnIn,
						ISNULL(MSTL.Quantity, 0) - ISNULL(MSTL.QtyIssued,0) AS StocklineQtyRemaining,
						ISNULL(MSTL.Quantity, 0) - (ISNULL(MSTL.QtyIssued,0) + ISNULL(MSTL.QtyReserved,0)) AS StocklineQtytobeReserved,
						WOM.QtyOnOrder, 
						WOM.QtyOnBkOrder,
						WOM.PONum,
						WOM.PONextDlvrDate,
						NULL AS ReceivedDate,
						ISNULL(WOM.POId, 0),
						WOM.Quantity,
						ISNULL(MSTL.Quantity,0) AS StocklineQuantity,
						ISNULL((CASE WHEN  @IsTeardownWO = 1 THEN (CASE WHEN ISNULL(WOM.Quantity,0) = 0 THEN 0 ELSE ISNULL(WOM.Quantity,0) - ISNULL((SELECT SUM(ISNULL(SL.QuantityTurnIn,0)) FROM  dbo.WorkOrderPartNumber WOP  WITH(NOLOCK) 
													 JOIN dbo.Stockline SL ON WOP.WorkOrderId = SL.WorkOrderId AND WOP.ID = SL.WorkOrderPartNoId AND Sl.WorkOrderId = @Local_WorkOrderId   AND ISNULL(SL.isActive,0) = 1 AND ISNULL(SL.isDeleted,0) = 0
													 WHERE SL.WorkOrderId = WOM.WorkOrderId AND Sl.ConditionId = WOM.ConditionCodeId AND SL.ItemMasterId = IM.ItemMasterId),0) END) 
							  ELSE WOM.QtyToTurnIn END),0) AS PartQtyToTurnIn,
						ISNULL(CASE WHEN MSTL.ProvisionId = @SubProvisionId AND ISNULL(MSTL.Quantity, 0) != 0 THEN MSTL.Quantity 
							 ELSE CASE WHEN MSTL.ProvisionId = @SubProvisionId OR MSTL.ProvisionId = @ForStockProvisionId THEN SL.QuantityTurnIn ELSE 0 END END,0) AS 'StocklineQtyToTurnIn',
						WOM.ConditionCodeId,
						MSTL.ConditionId AS StocklineConditionCodeId,
						WOM.UnitOfMeasureId,
						WOM.WorkOrderMaterialsId,
						WOM.WorkFlowWorkOrderId,
						WOM.WorkOrderId,
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
						WOM.ParentWorkOrderMaterialsId,
						WOM.IsAltPart,
						WOM.IsEquPart,
						ITC.Description AS ItemClassification,
						CASE WHEN SUOM.UnitOfMeasureId IS NOT NULL THEN SUOM.ShortName ELSE UOM.ShortName END AS UOM,
						CASE WHEN WOM.IsDeferred = NULL OR WOM.IsDeferred = 0 THEN 'No' ELSE 'Yes' END AS Defered,
						IsRoleUp = 0,
						WOM.ProvisionId,
						CASE WHEN SWPN.SubWorkOrderId IS NULL THEN 0 ELSE 
							CASE WHEN SWPN.SubWorkOrderId > 0 AND SWPN.IsDeleted = 1 THEN 0 ELSE 1 END END AS IsSubWorkOrderCreated,
						CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.SubWorkOrderStatusId = 2 THEN 1 ELSE 0 END AS IsSubWorkOrderClosed,
						CASE WHEN SWO.SubWorkOrderId IS NULL THEN 0 ELSE 
							CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.IsDeleted = 1 THEN 0 ELSE SWO.SubWorkOrderId END END AS SubWorkOrderId,
						
						CASE WHEN SWPN.StockLineId IS NULL THEN 0 ELSE 
							CASE WHEN SWPN.SubWorkOrderId > 0 AND SWPN.IsDeleted = 1 THEN 0 ELSE SWPN.StockLineId END END AS SubWorkOrderStockLineId,
						ISNULL(WOM.IsFromWorkFlow,0) as IsFromWorkFlow,
						Employeename = UPPER(WOM.CreatedBy),
						CASE WHEN SL.RepairOrderPartRecordId IS NOT NULL AND MSTL.RepairOrderId > 0 THEN SL.ReceivedDate ELSE ROP.EstRecordDate END AS 'RONextDlvrDate',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.RepairOrderNumber ELSE RO.RepairOrderNumber END AS 'RepairOrderNumber',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.RepairOrderId ELSE RO.RepairOrderId END AS 'RepairOrderId',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorId ELSE RO.VendorId END AS 'VendorId',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorName ELSE RO.VendorName END AS 'VendorName',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorCode ELSE RO.VendorCode END AS 'VendorCode'
						,WOM.Figure Figure
						,WOM.Item Item
						,MSTL.Figure StockLineFigure
						,MSTL.Item StockLineItem
						,ISNULL(SL.StockLIneId, 0) as StockLIneId
						,0 AS IsKitType
						,0 AS KitQty
						,WOM.ExpectedSerialNumber AS ExpectedSerialNumber
						,(CASE WHEN P.Description = @exchangeProvision  AND (SELECT count(1) FROM dbo.Stockline stk WITH(NOLOCK) WHERE stk.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId)>0 THEN 1 ELSE 0 END)  AS IsExchangeTender
					FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
						JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
						JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
						JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId
						JOIN dbo.MaterialMandatories MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId
						LEFT JOIN dbo.WorkOrderMaterialStockLine MSTL WITH (NOLOCK) ON MSTL.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND MSTL.IsDeleted = 0
						LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.UnitOfMeasure SUOM WITH (NOLOCK) ON SUOM.UnitOfMeasureId = SL.PurchaseUnitOfMeasureId
						LEFT JOIN dbo.WorkOrderMaterialStockLine MSTL_PO WITH (NOLOCK) ON MSTL_PO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND MSTL_PO.IsDeleted = 0 AND WOM.ConditionCodeId = MSTL_PO.ConditionId AND WOM.ItemMasterId = MSTL_PO.ItemMasterId AND WOM.POId > 0
						LEFT JOIN dbo.Condition Stk_C WITH (NOLOCK) ON Stk_C.ConditionId = SL.ConditionId
						LEFT JOIN dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) ON IM.ItemMasterId = IMPS.ItemMasterId AND WOM.ConditionCodeId = IMPS.ConditionId
						LEFT JOIN dbo.ItemClassification ITC WITH (NOLOCK) ON ITC.ItemClassificationId = IM.ItemClassificationId
						LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
						LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = MSTL.ProvisionId
						LEFT JOIN dbo.Task T WITH (NOLOCK) ON T.TaskId = WOM.TaskId
						LEFT JOIN dbo.SubWorkOrder SWO WITH (NOLOCK) ON SWO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND SWO.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.SubWorkOrderPartNumber SWPN WITH (NOLOCK) ON SWPN.WorkOrderId = WOM.WorkOrderId AND SWPN.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.RepairOrder RO WITH (NOLOCK) ON SL.RepairOrderId = RO.RepairOrderId
						LEFT JOIN dbo.RepairOrder WOMS_RO WITH (NOLOCK) ON MSTL.RepairOrderId = WOMS_RO.RepairOrderId
						LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) ON ROP.RepairOrderId = WOMS_RO.RepairOrderId AND ROP.ItemMasterId = MSTL.ItemMasterId--SL.RepairOrderPartRecordId = ROP.RepairOrderPartRecordId
						LEFT JOIN dbo.RepairOrderPart WOMS_ROP WITH (NOLOCK) ON WOMS_ROP.RepairOrderId = WOMS_RO.RepairOrderId
						LEFT JOIN dbo.ItemMaster IMS WITH (NOLOCK) ON IMS.ItemMasterId = MSTL.ItemMasterId
					WHERE WOM.IsDeleted = 0 AND WOM.WorkFlowWorkOrderId = @Local_WFWOId
					AND (ISNULL(WOM.Quantity,0) - ISNULL(WOM.QuantityIssued,0) > 0)
					AND WOM.WorkOrderMaterialsId IN (SELECT WorkOrderMaterialsId FROM #TMPWOMaterialResultListData WHERE IsKit = 0)

					--WorkOrderMaterial Kit Data Insert
					INSERT INTO	#finalMaterialListResult([PartNumber], [PartDescription], [StocklinePartNumber], [StocklinePartDescription], [KitNumber], [KitDescription], [KitCost], [WOQMaterialKitMappingId], [KitId],
								[ItemGroup], [ManufacturerName], [WorkOrderNumber], [SubWorkOrderNo], [SalesOrder], [Site], [WareHouse], [Location], [Shelf], [Bin],
								[PartStatusId], [Provision], [ProvisionStatusCode], [StockType], [ItemType], [Condition], [StocklineCondition], [UnitCost], [ItemMasterUnitCost], [ExtendedCost],
								[TotalStocklineQtyReq], [StocklineUnitCost], [StocklineExtendedCost], [WOMStockLIneId], [StockLineProvisionId], [IsWOMSAltPart], [IsWOMSEquPart], [AlterPartNumber],
								[StocklineProvision], [StocklineProvisionStatusCode], [StockLineNumber], [SerialNumber], [ControlId], [ControlNo], [Receiver], [StockLineQuantityOnHand], [StockLineQuantityAvailable],
								[PartQuantityOnHand], [PartQuantityAvailable], [PartQuantityReserved], [PartQuantityTurnIn], [PartQuantityOnOrder], [CostDate], [Currency], [QuantityIssued], [QuantityReserved],
								[QunatityRemaining], [QunatityPicked], [StocklineQtyReserved], [QtytobeReserved], [StocklineQtyIssued], [StocklineQuantityTurnIn], [StocklineQtyRemaining], [StocklineQtytobeReserved],
								[QtyOnOrder], [QtyOnBkOrder], [PONum], [PONextDlvrDate], [ReceivedDate], [POId], [Quantity], [StocklineQuantity], [PartQtyToTurnIn], [StocklineQtyToTurnIn], [ConditionCodeId], [StocklineConditionCodeId],
								[UnitOfMeasureId], [WorkOrderMaterialsId], [WorkFlowWorkOrderId], [WorkOrderId], [ItemMasterId], [ItemClassificationId], [PurchaseUnitOfMeasureId], [Memo], [IsDeferred], [TaskId],
								[TaskName], [MandatoryOrSupplemental], [MaterialMandatoriesId], [MasterCompanyId], [ParentWorkOrderMaterialsId], [IsAltPart], [IsEquPart], [ItemClassification], [UOM],
								[Defered], [IsRoleUp], [ProvisionId], [IsSubWorkOrderCreated], [IsSubWorkOrderClosed], [SubWorkOrderId], [SubWorkOrderStockLineId], [IsFromWorkFlow], [Employeename], [RONextDlvrDate],
								[RepairOrderNumber], [RepairOrderId], [VendorId], [VendorName], [VendorCode], [Figure], [Item], [StockLineFigure], [StockLineItem], [StockLineId], [IsKitType], [KitQty], [ExpectedSerialNumber],
								[IsExchangeTender])
					SELECT DISTINCT IM.PartNumber,
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
						SL.WorkOrderNumber,
						CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.IsDeleted = 1 THEN '' ELSE SWO.SubWorkOrderNo END AS 'SubWorkOrderNo',
						--WOM.WorkOrderId,
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
						WOM.UnitCost,
						ISNULL(IMPS.PP_UnitPurchasePrice,0) AS ItemMasterUnitCost,
						WOM.ExtendedCost,
						WOM.TotalStocklineQtyReq,
						ISNULL(MSTL.UnitCost,0) StocklineUnitCost,
						ISNULL(MSTL.ExtendedCost,0) StocklineExtendedCost,
						ISNULL(MSTL.StockLIneId, 0) as StockLIneId,
						MSTL.ProvisionId AS StockLineProvisionId,
						(CASE 
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
						) AS AlterPartNumber,
						SP.Description AS StocklineProvision,
						SP.StatusCode AS StocklineProvisionStatusCode,
						SL.StockLineNumber,
						SL.SerialNumber,
						SL.IdNumber AS ControlId,
						SL.ControlNumber AS ControlNo,
						SL.ReceiverNumber AS Receiver,
						ISNULL(SL.QuantityOnHand,0) AS StockLineQuantityOnHand,
						ISNULL(SL.QuantityAvailable,0) AS StockLineQuantityAvailable,
						PartQuantityOnHand = ISNULL((SELECT SUM(ISNULL(sl.QuantityOnHand,0)) FROM #tmpStocklineKit sl WITH (NOLOCK)
										Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1										
										),0),
						PartQuantityAvailable = ISNULL((SELECT SUM(ISNULL(sl.QuantityAvailable,0)) FROM #tmpStocklineKit sl WITH (NOLOCK)
										Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1
										),0),
						PartQuantityReserved = ISNULL((SELECT SUM(ISNULL(sl.QuantityReserved,0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK)
										JOIN #tmpStocklineKit sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId 
										Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0
										),0),
						PartQuantityTurnIn = ISNULL((SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.WorkOrderMaterialStockLineKit womsl WITH (NOLOCK)
										JOIN dbo.Stockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
										Where womsl.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0
										),0),
						PartQuantityOnOrder = ISNULL((SELECT SUM(ISNULL(sl.QuantityOnOrder,0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK)
										JOIN #tmpStocklineKit sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
										Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0
										),0),
						CostDate = (SELECT TOP 1 CONVERT(varchar, IMPS.PP_LastListPriceDate, 101) FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK)
									WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId AND IMPS.PP_LastListPriceDate IS NOT NULL),
						Currency = (SELECT TOP 1 CUR.Code FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) 
									LEFT JOIN dbo.Currency CUR WITH (NOLOCK)  ON IMPS.PP_CurrencyId = CUR.CurrencyId 
									WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId ),
						QuantityIssued = ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0),
						QuantityReserved = ISNULL((SELECT SUM(ISNULL(womsl.QtyReserved, 0 )) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0),
						QunatityRemaining = ISNULL((WOM.Quantity + WOM.QtyToTurnIn) - (ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0) + ISNULL(
											(SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.WorkOrderMaterialStockLineKit womsl WITH (NOLOCK)
											JOIN dbo.Stockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
											Where womsl.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId
											AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0
											), 0)),0),
						QunatityPicked = ISNULL((SELECT SUM(wopt.QtyToShip) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) 
											WHERE wopt.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND wopt.WorkorderId = WOM.WorkOrderId),0),
						
						ISNULL(MSTL.QtyReserved,0) AS StocklineQtyReserved,
						ISNULL(ISNULL(WOM.Quantity, 0) - Isnull((SELECT SUM(ISNULL(womsl.QtyReserved, 0 )) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0) - Isnull((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0),0) AS QtytobeReserved,
						ISNULL(MSTL.QtyIssued,0) AS StocklineQtyIssued,
						ISNULL(MSTL.QuantityTurnIn, 0) as StocklineQuantityTurnIn,
						ISNULL(MSTL.Quantity, 0) - ISNULL(MSTL.QtyIssued,0) AS StocklineQtyRemaining,
						ISNULL(MSTL.Quantity, 0) - (ISNULL(MSTL.QtyIssued,0) + ISNULL(MSTL.QtyReserved,0)) AS StocklineQtytobeReserved,
						WOM.QtyOnOrder, 
						WOM.QtyOnBkOrder,
						WOM.PONum,
						WOM.PONextDlvrDate,
						NULL AS ReceivedDate,
						ISNULL(WOM.POId, 0),
						WOM.Quantity,
						ISNULL(MSTL.Quantity,0) AS StocklineQuantity,
						ISNULL(WOM.QtyToTurnIn,0) AS PartQtyToTurnIn,
						ISNULL(CASE WHEN MSTL.ProvisionId = @SubProvisionId AND ISNULL(MSTL.Quantity, 0) != 0 THEN MSTL.Quantity 
							 ELSE CASE WHEN MSTL.ProvisionId = @SubProvisionId OR MSTL.ProvisionId = @ForStockProvisionId THEN SL.QuantityTurnIn ELSE 0 END END,0) AS 'StocklineQtyToTurnIn',
						WOM.ConditionCodeId,
						MSTL.ConditionId AS StocklineConditionCodeId,
						WOM.UnitOfMeasureId,
						WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,
						WOM.WorkFlowWorkOrderId,
						WOM.WorkOrderId,
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
						WOM.ParentWorkOrderMaterialsId,
						WOM.IsAltPart,
						WOM.IsEquPart,
						ITC.Description AS ItemClassification,
						CASE WHEN SUOM.UnitOfMeasureId IS NOT NULL THEN SUOM.ShortName ELSE UOM.ShortName END AS UOM,
						CASE WHEN WOM.IsDeferred = NULL OR WOM.IsDeferred = 0 THEN 'No' ELSE 'Yes' END AS Defered,
						IsRoleUp = 0,
						WOM.ProvisionId,
						CASE WHEN SWO.SubWorkOrderId IS NULL THEN 0 ELSE 
							CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.IsDeleted = 1 THEN 0 ELSE 1 END END AS IsSubWorkOrderCreated,
						CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.SubWorkOrderStatusId = 2 THEN 1 ELSE 0 END AS IsSubWorkOrderClosed,
						CASE WHEN SWO.SubWorkOrderId IS NULL THEN 0 ELSE 
							CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.IsDeleted = 1 THEN 0 ELSE SWO.SubWorkOrderId END END AS SubWorkOrderId,
						CASE WHEN SWPN.StockLineId IS NULL THEN 0 ELSE 
							CASE WHEN SWPN.SubWorkOrderId > 0 AND SWPN.IsDeleted = 1 THEN 0 ELSE SWPN.StockLineId END END AS SubWorkOrderStockLineId,
						ISNULL(WOM.IsFromWorkFlow,0) as IsFromWorkFlow,
						Employeename = UPPER(WOM.CreatedBy),
						CASE WHEN SL.RepairOrderPartRecordId IS NOT NULL AND MSTL.RepairOrderId > 0 THEN SL.ReceivedDate ELSE ROP.EstRecordDate END AS 'RONextDlvrDate',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.RepairOrderNumber ELSE RO.RepairOrderNumber END AS 'RepairOrderNumber',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.RepairOrderId ELSE RO.RepairOrderId END AS 'RepairOrderId',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorId ELSE RO.VendorId END AS 'VendorId',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorName ELSE RO.VendorName END AS 'VendorName',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorCode ELSE RO.VendorCode END AS 'VendorCode'
						,WOM.Figure Figure
						,WOM.Item Item
						,CASE WHEN isnull(MSTL.StockLineId,0)=0 then WOM.Figure else MSTL.Figure end as StockLineFigure
						,CASE WHEN isnull(MSTL.StockLineId,0)=0 then WOM.Item else MSTL.Item end StockLineItem
						,ISNULL(SL.StockLIneId, 0) as StockLIneId
						,1 AS IsKitType
						,(SELECT SUM(ISNULL(WOMK.Quantity, 0)) FROM dbo.WorkOrderMaterialsKit WOMK WITH (NOLOCK) WHERE WOMK.WorkOrderMaterialsKitMappingId = WOMKM.WorkOrderMaterialsKitMappingId) AS KitQty
						,'' AS ExpectedSerialNumber
						,0  AS IsExchangeTender
					FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
						JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
						JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
						JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId
						JOIN dbo.MaterialMandatories MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId
						LEFT JOIN dbo.WorkOrderMaterialStockLineKit MSTL WITH (NOLOCK) ON MSTL.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND MSTL.IsDeleted = 0
						LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.UnitOfMeasure SUOM WITH (NOLOCK) ON SUOM.UnitOfMeasureId = SL.PurchaseUnitOfMeasureId
						LEFT JOIN dbo.Condition Stk_C WITH (NOLOCK) ON Stk_C.ConditionId = SL.ConditionId
						LEFT JOIN dbo.WorkOrderMaterialStockLineKit MSTL_PO WITH (NOLOCK) ON MSTL_PO.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND MSTL_PO.IsDeleted = 0 AND WOM.ConditionCodeId = MSTL_PO.ConditionId AND WOM.ItemMasterId = MSTL_PO.ItemMasterId AND WOM.POId > 0
						LEFT JOIN dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) ON IM.ItemMasterId = IMPS.ItemMasterId AND WOM.ConditionCodeId = IMPS.ConditionId
						LEFT JOIN dbo.ItemClassification ITC WITH (NOLOCK) ON ITC.ItemClassificationId = IM.ItemClassificationId
						LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
						LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = MSTL.ProvisionId
						LEFT JOIN dbo.Task T WITH (NOLOCK) ON T.TaskId = WOM.TaskId
						LEFT JOIN dbo.SubWorkOrder SWO WITH (NOLOCK) ON SWO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND SWO.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.SubWorkOrderPartNumber SWPN WITH (NOLOCK) ON SWPN.WorkOrderId = WOM.WorkOrderId AND SWPN.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.RepairOrder RO WITH (NOLOCK) ON SL.RepairOrderId = RO.RepairOrderId
						LEFT JOIN dbo.RepairOrder WOMS_RO WITH (NOLOCK) ON MSTL.RepairOrderId = WOMS_RO.RepairOrderId
						LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) ON ROP.RepairOrderId = WOMS_RO.RepairOrderId AND ROP.ItemMasterId = MSTL.ItemMasterId--SL.RepairOrderPartRecordId = ROP.RepairOrderPartRecordId
						LEFT JOIN dbo.RepairOrderPart WOMS_ROP WITH (NOLOCK) ON WOMS_ROP.RepairOrderId = WOMS_RO.RepairOrderId
						LEFT JOIN [dbo].[WorkOrderMaterialsKitMapping] WOMKM WITH (NOLOCK) ON WOMKM.WOPartNoId = WOWF.WorkOrderPartNoId AND WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
						LEFT JOIN dbo.ItemMaster IMS WITH (NOLOCK) ON IMS.ItemMasterId = MSTL.ItemMasterId
					WHERE WOM.IsDeleted = 0 AND WOM.WorkFlowWorkOrderId = @Local_WFWOId
						AND (ISNULL(WOM.Quantity,0) - ISNULL(WOM.QuantityIssued,0) > 0)
						AND WOMKM.WorkOrderMaterialsKitMappingId IN (SELECT WorkOrderMaterialsKitMappingId FROM #TMPWOMaterialResultListData WHERE IsKit = 1)
				END
				ELSE
				BEGIN
					--WorkOrderMaterial Data Insert
					INSERT INTO	#finalMaterialListResult([PartNumber], [PartDescription], [StocklinePartNumber], [StocklinePartDescription], [KitNumber], [KitDescription], [KitCost], [WOQMaterialKitMappingId], [KitId],
								[ItemGroup], [ManufacturerName], [WorkOrderNumber], [SubWorkOrderNo], [SalesOrder], [Site], [WareHouse], [Location], [Shelf], [Bin],
								[PartStatusId], [Provision], [ProvisionStatusCode], [StockType], [ItemType], [Condition], [StocklineCondition], [UnitCost], [ItemMasterUnitCost], [ExtendedCost],
								[TotalStocklineQtyReq], [StocklineUnitCost], [StocklineExtendedCost], [WOMStockLIneId], [StockLineProvisionId], [IsWOMSAltPart], [IsWOMSEquPart], [AlterPartNumber],
								[StocklineProvision], [StocklineProvisionStatusCode], [StockLineNumber], [SerialNumber], [ControlId], [ControlNo], [Receiver], [StockLineQuantityOnHand], [StockLineQuantityAvailable],
								[PartQuantityOnHand], [PartQuantityAvailable], [PartQuantityReserved], [PartQuantityTurnIn], [PartQuantityOnOrder], [CostDate], [Currency], [QuantityIssued], [QuantityReserved],
								[QunatityRemaining], [QunatityPicked], [StocklineQtyReserved], [QtytobeReserved], [StocklineQtyIssued], [StocklineQuantityTurnIn], [StocklineQtyRemaining], [StocklineQtytobeReserved],
								[QtyOnOrder], [QtyOnBkOrder], [PONum], [PONextDlvrDate], [ReceivedDate], [POId], [Quantity], [StocklineQuantity], [PartQtyToTurnIn], [StocklineQtyToTurnIn], [ConditionCodeId], [StocklineConditionCodeId],
								[UnitOfMeasureId], [WorkOrderMaterialsId], [WorkFlowWorkOrderId], [WorkOrderId], [ItemMasterId], [ItemClassificationId], [PurchaseUnitOfMeasureId], [Memo], [IsDeferred], [TaskId],
								[TaskName], [MandatoryOrSupplemental], [MaterialMandatoriesId], [MasterCompanyId], [ParentWorkOrderMaterialsId], [IsAltPart], [IsEquPart], [ItemClassification], [UOM],
								[Defered], [IsRoleUp], [ProvisionId], [IsSubWorkOrderCreated], [IsSubWorkOrderClosed], [SubWorkOrderId], [SubWorkOrderStockLineId], [IsFromWorkFlow], [Employeename], [RONextDlvrDate],
								[RepairOrderNumber], [RepairOrderId], [VendorId], [VendorName], [VendorCode], [Figure], [Item], [StockLineFigure], [StockLineItem], [StockLineId], [IsKitType], [KitQty], [ExpectedSerialNumber],
								[IsExchangeTender])
					SELECT DISTINCT IM.PartNumber,
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
						SL.WorkOrderNumber,
						CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.IsDeleted = 1 THEN '' ELSE SWO.SubWorkOrderNo END AS 'SubWorkOrderNo',
						--WOM.WorkOrderId,
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
						WOM.UnitCost,
						ISNULL(IMPS.PP_UnitPurchasePrice,0) AS ItemMasterUnitCost,
						WOM.ExtendedCost,
						WOM.TotalStocklineQtyReq,
						ISNULL(MSTL.UnitCost,0) StocklineUnitCost,
						ISNULL(MSTL.ExtendedCost,0) StocklineExtendedCost,
						ISNULL(MSTL.StockLIneId, 0) as StockLIneId,
						MSTL.ProvisionId AS StockLineProvisionId,
						(CASE 
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
						) AS AlterPartNumber,
						SP.Description AS StocklineProvision,
						SP.StatusCode AS StocklineProvisionStatusCode,
						SL.StockLineNumber,
						SL.SerialNumber,
						SL.IdNumber AS ControlId,
						SL.ControlNumber AS ControlNo,
						SL.ReceiverNumber AS Receiver,
						SL.QuantityOnHand AS StockLineQuantityOnHand,
						SL.QuantityAvailable AS StockLineQuantityAvailable,
						PartQuantityOnHand = ISNULL((SELECT SUM(ISNULL(sl.QuantityOnHand,0)) FROM #tmpStockline sl WITH (NOLOCK)
										Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1										
										),0),
						PartQuantityAvailable = ISNULL((SELECT SUM(ISNULL(sl.QuantityAvailable,0)) FROM #tmpStockline sl WITH (NOLOCK)
										Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1
										),0),
						PartQuantityReserved = ISNULL((SELECT SUM(ISNULL(sl.QuantityReserved,0)) FROM #tmpWOMStockline womsl WITH (NOLOCK)
										JOIN #tmpStockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId 
										Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0
										),0),
						PartQuantityTurnIn = ISNULL((CASE WHEN @IsTeardownWO = 1 THEN 
													(SELECT SUM(ISNULL(SL.QuantityTurnIn,0)) FROM  dbo.WorkOrderPartNumber WOP  WITH(NOLOCK) 
													 JOIN dbo.Stockline SL ON WOP.WorkOrderId = SL.WorkOrderId AND WOP.ID = SL.WorkOrderPartNoId AND Sl.WorkOrderId = @Local_WorkOrderId 
													 WHERE SL.WorkOrderId = WOM.WorkOrderId AND Sl.ConditionId = WOM.ConditionCodeId AND SL.ItemMasterId = IM.ItemMasterId AND ISNULL(SL.isActive,0) = 1 AND ISNULL(SL.isDeleted,0) = 0 ) 
											       ELSE (SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.WorkOrderMaterialStockLine womsl WITH (NOLOCK)
														JOIN dbo.Stockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
														Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
														AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0
										                ) 
											 END),0),
						PartQuantityOnOrder = ISNULL((SELECT SUM(ISNULL(sl.QuantityOnOrder,0)) FROM #tmpWOMStockline womsl WITH (NOLOCK)
										JOIN #tmpStockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
										Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0
										),0),
						CostDate = (SELECT TOP 1 CONVERT(varchar, IMPS.PP_LastListPriceDate, 101) FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK)
									WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId AND IMPS.PP_LastListPriceDate IS NOT NULL),
						Currency = (SELECT TOP 1 CUR.Code FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) 
									LEFT JOIN dbo.Currency CUR WITH (NOLOCK)  ON IMPS.PP_CurrencyId = CUR.CurrencyId 
									WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId ),
						QuantityIssued = ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0),
						QuantityReserved = ISNULL((SELECT SUM(ISNULL(womsl.QtyReserved, 0 )) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0),
						QunatityRemaining = ISNULL((WOM.Quantity + WOM.QtyToTurnIn) - (ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0) + ISNULL(
											(SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.WorkOrderMaterialStockLine womsl WITH (NOLOCK)
											JOIN dbo.Stockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
											Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId
											AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0
											), 0)),0),
						QunatityPicked = ISNULL((SELECT SUM(wopt.QtyToShip) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) 
											WHERE wopt.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND wopt.WorkorderId = WOM.WorkOrderId),0),
						
						ISNULL(MSTL.QtyReserved,0) AS StocklineQtyReserved,
						ISNULL(ISNULL(WOM.Quantity, 0) - Isnull((SELECT SUM(ISNULL(womsl.QtyReserved, 0 )) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0) - Isnull((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0),0) AS QtytobeReserved,
						ISNULL(MSTL.QtyIssued,0) AS StocklineQtyIssued,
						ISNULL(MSTL.QuantityTurnIn, 0) as StocklineQuantityTurnIn,
						ISNULL(MSTL.Quantity, 0) - ISNULL(MSTL.QtyIssued,0) AS StocklineQtyRemaining,
						ISNULL(MSTL.Quantity, 0) - (ISNULL(MSTL.QtyIssued,0) + ISNULL(MSTL.QtyReserved,0)) AS StocklineQtytobeReserved,
						WOM.QtyOnOrder, 
						WOM.QtyOnBkOrder,
						WOM.PONum,
						WOM.PONextDlvrDate,
						SL.ReceivedDate,
						ISNULL(WOM.POId, 0),
						WOM.Quantity,
						MSTL.Quantity AS StocklineQuantity,
						(CASE WHEN  @IsTeardownWO = 1 THEN (CASE WHEN ISNULL(WOM.Quantity,0) = 0 THEN 0 ELSE ISNULL(WOM.Quantity,0) - ISNULL((SELECT SUM(ISNULL(SL.QuantityTurnIn,0)) FROM  dbo.WorkOrderPartNumber WOP  WITH(NOLOCK) 
													 JOIN dbo.Stockline SL ON WOP.WorkOrderId = SL.WorkOrderId AND WOP.ID = SL.WorkOrderPartNoId AND Sl.WorkOrderId = @Local_WorkOrderId AND ISNULL(SL.isActive,0) = 1 AND ISNULL(SL.isDeleted,0) = 0
													 WHERE SL.WorkOrderId = WOM.WorkOrderId AND Sl.ConditionId = WOM.ConditionCodeId AND SL.ItemMasterId = IM.ItemMasterId),0) END) 
							  ELSE WOM.QtyToTurnIn END) AS PartQtyToTurnIn,
						CASE WHEN MSTL.ProvisionId = @SubProvisionId AND ISNULL(MSTL.Quantity, 0) != 0 THEN MSTL.Quantity 
							 ELSE CASE WHEN MSTL.ProvisionId = @SubProvisionId OR MSTL.ProvisionId = @ForStockProvisionId THEN SL.QuantityTurnIn ELSE 0 END END AS 'StocklineQtyToTurnIn',
						WOM.ConditionCodeId,
						MSTL.ConditionId AS StocklineConditionCodeId,
						WOM.UnitOfMeasureId,
						WOM.WorkOrderMaterialsId,
						WOM.WorkFlowWorkOrderId,
						WOM.WorkOrderId,
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
						WOM.ParentWorkOrderMaterialsId,
						WOM.IsAltPart,
						WOM.IsEquPart,
						ITC.Description AS ItemClassification,
						CASE WHEN SUOM.UnitOfMeasureId IS NOT NULL THEN SUOM.ShortName ELSE UOM.ShortName END AS UOM,
						CASE WHEN WOM.IsDeferred = NULL OR WOM.IsDeferred = 0 THEN 'No' ELSE 'Yes' END AS Defered,
						IsRoleUp = 0,
						WOM.ProvisionId,
						CASE WHEN SWPN.SubWorkOrderId IS NULL THEN 0 ELSE 
							CASE WHEN SWPN.SubWorkOrderId > 0 AND SWPN.IsDeleted = 1 THEN 0 ELSE 1 END END AS IsSubWorkOrderCreated,
						CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.SubWorkOrderStatusId = 2 THEN 1 ELSE 0 END AS IsSubWorkOrderClosed,
						CASE WHEN SWO.SubWorkOrderId IS NULL THEN 0 ELSE 
							CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.IsDeleted = 1 THEN 0 ELSE SWO.SubWorkOrderId END END AS SubWorkOrderId,
						CASE WHEN SWPN.StockLineId IS NULL THEN 0 ELSE 
							CASE WHEN SWPN.SubWorkOrderId > 0 AND SWPN.IsDeleted = 1 THEN 0 ELSE SWPN.StockLineId END END AS SubWorkOrderStockLineId,
						ISNULL(WOM.IsFromWorkFlow,0) as IsFromWorkFlow,
						Employeename = UPPER(WOM.CreatedBy),
						CASE WHEN SL.RepairOrderPartRecordId IS NOT NULL AND MSTL.RepairOrderId > 0 THEN SL.ReceivedDate ELSE ROP.EstRecordDate END AS 'RONextDlvrDate',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.RepairOrderNumber ELSE RO.RepairOrderNumber END AS 'RepairOrderNumber',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.RepairOrderId ELSE RO.RepairOrderId END AS 'RepairOrderId',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorId ELSE RO.VendorId END AS 'VendorId',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorName ELSE RO.VendorName END AS 'VendorName',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorCode ELSE RO.VendorCode END AS 'VendorCode'
						,WOM.Figure Figure
						,WOM.Item Item
						,MSTL.Figure StockLineFigure
						,MSTL.Item StockLineItem
						,ISNULL(SL.StockLIneId, 0) as StockLIneId
						,0 AS IsKitType
						,0 AS KitQty
						,WOM.ExpectedSerialNumber AS ExpectedSerialNumber
						,(CASE WHEN P.Description = @exchangeProvision  AND (SELECT count(1) FROM dbo.Stockline stk WITH(NOLOCK) WHERE stk.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId)>0 THEN 1 ELSE 0 END)  AS IsExchangeTender
					FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
						JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
						JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
						JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId
						JOIN dbo.MaterialMandatories MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId
						LEFT JOIN dbo.WorkOrderMaterialStockLine MSTL WITH (NOLOCK) ON MSTL.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND MSTL.IsDeleted = 0
						LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.UnitOfMeasure SUOM WITH (NOLOCK) ON SUOM.UnitOfMeasureId = SL.PurchaseUnitOfMeasureId
						LEFT JOIN dbo.WorkOrderMaterialStockLine MSTL_PO WITH (NOLOCK) ON MSTL_PO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND MSTL_PO.IsDeleted = 0 AND WOM.ConditionCodeId = MSTL_PO.ConditionId AND WOM.ItemMasterId = MSTL_PO.ItemMasterId AND WOM.POId > 0
						LEFT JOIN dbo.Condition Stk_C WITH (NOLOCK) ON Stk_C.ConditionId = MSTL.ConditionId -- DO Not Modify this 
						--LEFT JOIN dbo.Stockline SL_PO WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) ON IM.ItemMasterId = IMPS.ItemMasterId AND WOM.ConditionCodeId = IMPS.ConditionId
						LEFT JOIN dbo.ItemClassification ITC WITH (NOLOCK) ON ITC.ItemClassificationId = IM.ItemClassificationId
						LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
						LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = MSTL.ProvisionId
						LEFT JOIN dbo.Task T WITH (NOLOCK) ON T.TaskId = WOM.TaskId
						LEFT JOIN dbo.SubWorkOrder SWO WITH (NOLOCK) ON SWO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND SWO.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.SubWorkOrderPartNumber SWPN WITH (NOLOCK) ON SWPN.WorkOrderId = WOM.WorkOrderId AND SWPN.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.RepairOrder RO WITH (NOLOCK) ON SL.RepairOrderId = RO.RepairOrderId
						LEFT JOIN dbo.RepairOrder WOMS_RO WITH (NOLOCK) ON MSTL.RepairOrderId = WOMS_RO.RepairOrderId
						LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) ON ROP.RepairOrderId = WOMS_RO.RepairOrderId AND ROP.ItemMasterId = MSTL.ItemMasterId --SL.RepairOrderPartRecordId = ROP.RepairOrderPartRecordId
						LEFT JOIN dbo.RepairOrderPart WOMS_ROP WITH (NOLOCK) ON WOMS_ROP.RepairOrderId = WOMS_RO.RepairOrderId
						LEFT JOIN dbo.ItemMaster IMS WITH (NOLOCK) ON IMS.ItemMasterId = MSTL.ItemMasterId
					WHERE WOM.IsDeleted = 0 AND WOM.WorkFlowWorkOrderId = @Local_WFWOId
					AND WOM.WorkOrderMaterialsId IN (SELECT WorkOrderMaterialsId FROM #TMPWOMaterialResultListData WHERE IsKit = 0)

					--WorkOrderMaterial Kit Data Insert
					INSERT INTO	#finalMaterialListResult([PartNumber], [PartDescription], [StocklinePartNumber], [StocklinePartDescription], [KitNumber], [KitDescription], [KitCost], [WOQMaterialKitMappingId], [KitId],
								[ItemGroup], [ManufacturerName], [WorkOrderNumber], [SubWorkOrderNo], [SalesOrder], [Site], [WareHouse], [Location], [Shelf], [Bin],
								[PartStatusId], [Provision], [ProvisionStatusCode], [StockType], [ItemType], [Condition], [StocklineCondition], [UnitCost], [ItemMasterUnitCost], [ExtendedCost],
								[TotalStocklineQtyReq], [StocklineUnitCost], [StocklineExtendedCost], [WOMStockLIneId], [StockLineProvisionId], [IsWOMSAltPart], [IsWOMSEquPart], [AlterPartNumber],
								[StocklineProvision], [StocklineProvisionStatusCode], [StockLineNumber], [SerialNumber], [ControlId], [ControlNo], [Receiver], [StockLineQuantityOnHand], [StockLineQuantityAvailable],
								[PartQuantityOnHand], [PartQuantityAvailable], [PartQuantityReserved], [PartQuantityTurnIn], [PartQuantityOnOrder], [CostDate], [Currency], [QuantityIssued], [QuantityReserved],
								[QunatityRemaining], [QunatityPicked], [StocklineQtyReserved], [QtytobeReserved], [StocklineQtyIssued], [StocklineQuantityTurnIn], [StocklineQtyRemaining], [StocklineQtytobeReserved],
								[QtyOnOrder], [QtyOnBkOrder], [PONum], [PONextDlvrDate], [ReceivedDate], [POId], [Quantity], [StocklineQuantity], [PartQtyToTurnIn], [StocklineQtyToTurnIn], [ConditionCodeId], [StocklineConditionCodeId],
								[UnitOfMeasureId], [WorkOrderMaterialsId], [WorkFlowWorkOrderId], [WorkOrderId], [ItemMasterId], [ItemClassificationId], [PurchaseUnitOfMeasureId], [Memo], [IsDeferred], [TaskId],
								[TaskName], [MandatoryOrSupplemental], [MaterialMandatoriesId], [MasterCompanyId], [ParentWorkOrderMaterialsId], [IsAltPart], [IsEquPart], [ItemClassification], [UOM],
								[Defered], [IsRoleUp], [ProvisionId], [IsSubWorkOrderCreated], [IsSubWorkOrderClosed], [SubWorkOrderId], [SubWorkOrderStockLineId], [IsFromWorkFlow], [Employeename], [RONextDlvrDate],
								[RepairOrderNumber], [RepairOrderId], [VendorId], [VendorName], [VendorCode], [Figure], [Item], [StockLineFigure], [StockLineItem], [StockLineId], [IsKitType], [KitQty], [ExpectedSerialNumber],
								[IsExchangeTender])
					SELECT DISTINCT IM.PartNumber,
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
						SL.WorkOrderNumber,
						CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.IsDeleted = 1 THEN '' ELSE SWO.SubWorkOrderNo END AS 'SubWorkOrderNo',
						--WOM.WorkOrderId,
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
						WOM.UnitCost,
						ISNULL(IMPS.PP_UnitPurchasePrice, 0) AS ItemMasterUnitCost,
						WOM.ExtendedCost,
						WOM.TotalStocklineQtyReq,
						ISNULL(MSTL.UnitCost, 0) StocklineUnitCost,
						ISNULL(MSTL.ExtendedCost, 0) StocklineExtendedCost,
						ISNULL(MSTL.StockLIneId, 0) as StockLIneId,
						MSTL.ProvisionId AS StockLineProvisionId,
						(CASE 
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
						) AS AlterPartNumber,
						SP.Description AS StocklineProvision,
						SP.StatusCode AS StocklineProvisionStatusCode,
						SL.StockLineNumber,
						SL.SerialNumber,
						SL.IdNumber AS ControlId,
						SL.ControlNumber AS ControlNo,
						SL.ReceiverNumber AS Receiver,
						SL.QuantityOnHand AS StockLineQuantityOnHand,
						SL.QuantityAvailable AS StockLineQuantityAvailable,
						PartQuantityOnHand = ISNULL((SELECT SUM(ISNULL(sl.QuantityOnHand,0)) FROM #tmpStocklineKit sl WITH (NOLOCK)
										Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1										
										), 0),
						PartQuantityAvailable = ISNULL((SELECT SUM(ISNULL(sl.QuantityAvailable,0)) FROM #tmpStocklineKit sl WITH (NOLOCK)
										Where sl.ItemMasterId = WOM.ItemMasterId AND sl.ConditionId = WOM.ConditionCodeId AND sl.IsParent = 1
										), 0),
						PartQuantityReserved = ISNULL((SELECT SUM(ISNULL(sl.QuantityReserved,0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK)
										JOIN #tmpStocklineKit sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId 
										Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0
										), 0),
						PartQuantityTurnIn = ISNULL((SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM dbo.WorkOrderMaterialStockLineKit womsl WITH (NOLOCK)
										JOIN dbo.Stockline sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
										Where womsl.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0
										), 0),
						PartQuantityOnOrder = ISNULL((SELECT SUM(ISNULL(sl.QuantityOnOrder,0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK)
										JOIN #tmpStocklineKit sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
										Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId
										AND womsl.isActive = 1 AND womsl.isDeleted = 0
										), 0),
						CostDate = (SELECT TOP 1 CONVERT(varchar, IMPS.PP_LastListPriceDate, 101) FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK)
									WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId AND IMPS.PP_LastListPriceDate IS NOT NULL),
						Currency = (SELECT TOP 1 CUR.Code FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) 
									LEFT JOIN dbo.Currency CUR WITH (NOLOCK)  ON IMPS.PP_CurrencyId = CUR.CurrencyId 
									WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId ),
						QuantityIssued = ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0), 0),
						QuantityReserved = ISNULL((SELECT SUM(ISNULL(womsl.QtyReserved, 0 )) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0), 0),
						QunatityRemaining = ISNULL((WOM.Quantity + WOM.QtyToTurnIn) - (ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0) + ISNULL(
											(SELECT SUM(ISNULL(sl.QuantityOnOrder,0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK)
											JOIN #tmpStocklineKit sl WITH (NOLOCK) on womsl.StockLIneId = sl.StockLIneId
											Where womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.ConditionId = WOM.ConditionCodeId
											AND womsl.isActive = 1 AND womsl.isDeleted = 0
											), 0)), 0),
						QunatityPicked = ISNULL((SELECT SUM(wopt.QtyToShip) FROM dbo.WorkorderPickTicket wopt WITH (NOLOCK) 
											WHERE wopt.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND wopt.WorkorderId = WOM.WorkOrderId), 0),
						
						ISNULL(MSTL.QtyReserved, 0) AS StocklineQtyReserved,
						ISNULL(ISNULL(WOM.Quantity, 0) - Isnull((SELECT SUM(ISNULL(womsl.QtyReserved, 0 )) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0) - Isnull((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND womsl.isActive = 1 AND womsl.isDeleted = 0),0), 0) AS QtytobeReserved,
						ISNULL(MSTL.QtyIssued, 0) AS StocklineQtyIssued,
						ISNULL(MSTL.QuantityTurnIn, 0) as StocklineQuantityTurnIn,
						ISNULL(MSTL.Quantity, 0) - ISNULL(MSTL.QtyIssued,0) AS StocklineQtyRemaining,
						ISNULL(MSTL.Quantity, 0) - (ISNULL(MSTL.QtyIssued,0) + ISNULL(MSTL.QtyReserved,0)) AS StocklineQtytobeReserved,
						WOM.QtyOnOrder, 
						WOM.QtyOnBkOrder,
						WOM.PONum,
						WOM.PONextDlvrDate,
						SL.ReceivedDate,
						ISNULL(WOM.POId, 0),
						WOM.Quantity,
						ISNULL(MSTL.Quantity, 0) AS StocklineQuantity,
						WOM.QtyToTurnIn AS PartQtyToTurnIn,
						ISNULL(CASE WHEN MSTL.ProvisionId = @SubProvisionId AND ISNULL(MSTL.Quantity, 0) != 0 THEN MSTL.Quantity 
							 ELSE CASE WHEN MSTL.ProvisionId = @SubProvisionId OR MSTL.ProvisionId = @ForStockProvisionId THEN SL.QuantityTurnIn ELSE 0 END END, 0) AS 'StocklineQtyToTurnIn',
						WOM.ConditionCodeId,
						MSTL.ConditionId AS StocklineConditionCodeId,
						WOM.UnitOfMeasureId,
						WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,
						WOM.WorkFlowWorkOrderId,
						WOM.WorkOrderId,
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
						WOM.ParentWorkOrderMaterialsId,
						WOM.IsAltPart,
						WOM.IsEquPart,
						ITC.Description AS ItemClassification,
						CASE WHEN SUOM.UnitOfMeasureId IS NOT NULL THEN SUOM.ShortName ELSE UOM.ShortName END AS UOM,
						CASE WHEN WOM.IsDeferred = NULL OR WOM.IsDeferred = 0 THEN 'No' ELSE 'Yes' END AS Defered,
						IsRoleUp = 0,
						WOM.ProvisionId,
						CASE WHEN SWPN.SubWorkOrderId IS NULL THEN 0 ELSE 
							CASE WHEN SWPN.SubWorkOrderId > 0 AND SWPN.IsDeleted = 1 THEN 0 ELSE 1 END END AS IsSubWorkOrderCreated,
						CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.SubWorkOrderStatusId = 2 THEN 1 ELSE 0 END AS IsSubWorkOrderClosed,
						CASE WHEN SWO.SubWorkOrderId IS NULL THEN 0 ELSE 
							CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.IsDeleted = 1 THEN 0 ELSE SWO.SubWorkOrderId END END AS SubWorkOrderId,
						CASE WHEN SWPN.StockLineId IS NULL THEN 0 ELSE 
							CASE WHEN SWPN.SubWorkOrderId > 0 AND SWPN.IsDeleted = 1 THEN 0 ELSE SWPN.StockLineId END END AS SubWorkOrderStockLineId,
						ISNULL(WOM.IsFromWorkFlow,0) as IsFromWorkFlow,
						Employeename = UPPER(WOM.CreatedBy),
						CASE WHEN SL.RepairOrderPartRecordId IS NOT NULL AND MSTL.RepairOrderId > 0 THEN SL.ReceivedDate ELSE ROP.EstRecordDate END AS 'RONextDlvrDate',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.RepairOrderNumber ELSE RO.RepairOrderNumber END AS 'RepairOrderNumber',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.RepairOrderId ELSE RO.RepairOrderId END AS 'RepairOrderId',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorId ELSE RO.VendorId END AS 'VendorId',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorName ELSE RO.VendorName END AS 'VendorName',
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.VendorCode ELSE RO.VendorCode END AS 'VendorCode'
						,WOM.Figure Figure
						,WOM.Item Item
						,CASE WHEN isnull(MSTL.StockLineId,0)=0 then WOM.Figure else MSTL.Figure end as StockLineFigure
						,CASE WHEN isnull(MSTL.StockLineId,0)=0 then WOM.Item else MSTL.Item end StockLineItem
						,ISNULL(SL.StockLIneId, 0) as StockLIneId
						,1 AS IsKitType
						,ISNULL((SELECT SUM(ISNULL(WOMK.Quantity, 0)) FROM dbo.WorkOrderMaterialsKit WOMK WITH (NOLOCK) WHERE WOMK.WorkOrderMaterialsKitMappingId = WOMKM.WorkOrderMaterialsKitMappingId), 0) AS KitQty
						,'' AS ExpectedSerialNumber
						,0  AS IsExchangeTender
					FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
						JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
						JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
						JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId
						JOIN dbo.MaterialMandatories MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId
						LEFT JOIN dbo.WorkOrderMaterialStockLineKit MSTL WITH (NOLOCK) ON MSTL.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND MSTL.IsDeleted = 0
						LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId -- DO Not Modify this 
						LEFT JOIN dbo.UnitOfMeasure SUOM WITH (NOLOCK) ON SUOM.UnitOfMeasureId = SL.PurchaseUnitOfMeasureId
						LEFT JOIN dbo.Condition Stk_C WITH (NOLOCK) ON Stk_C.ConditionId = MSTL.ConditionId
						LEFT JOIN dbo.WorkOrderMaterialStockLineKit MSTL_PO WITH (NOLOCK) ON MSTL_PO.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND MSTL_PO.IsDeleted = 0 AND WOM.ConditionCodeId = MSTL_PO.ConditionId AND WOM.ItemMasterId = MSTL_PO.ItemMasterId AND WOM.POId > 0
						LEFT JOIN dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) ON IM.ItemMasterId = IMPS.ItemMasterId AND WOM.ConditionCodeId = IMPS.ConditionId
						LEFT JOIN dbo.ItemClassification ITC WITH (NOLOCK) ON ITC.ItemClassificationId = IM.ItemClassificationId
						LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
						LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = MSTL.ProvisionId
						LEFT JOIN dbo.Task T WITH (NOLOCK) ON T.TaskId = WOM.TaskId
						LEFT JOIN dbo.SubWorkOrder SWO WITH (NOLOCK) ON SWO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND SWO.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.SubWorkOrderPartNumber SWPN WITH (NOLOCK) ON SWPN.WorkOrderId = WOM.WorkOrderId AND SWPN.StockLineId = MSTL.StockLineId
						LEFT JOIN dbo.RepairOrder RO WITH (NOLOCK) ON SL.RepairOrderId = RO.RepairOrderId
						LEFT JOIN dbo.RepairOrder WOMS_RO WITH (NOLOCK) ON MSTL.RepairOrderId = WOMS_RO.RepairOrderId
						LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) ON ROP.RepairOrderId = WOMS_RO.RepairOrderId AND ROP.ItemMasterId = MSTL.ItemMasterId--SL.RepairOrderPartRecordId = ROP.RepairOrderPartRecordId
						LEFT JOIN dbo.RepairOrderPart WOMS_ROP WITH (NOLOCK) ON WOMS_ROP.RepairOrderId = WOMS_RO.RepairOrderId
						LEFT JOIN [dbo].[WorkOrderMaterialsKitMapping] WOMKM WITH (NOLOCK) ON WOMKM.WOPartNoId = WOWF.WorkOrderPartNoId AND WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
						LEFT JOIN dbo.ItemMaster IMS WITH (NOLOCK) ON IMS.ItemMasterId = MSTL.ItemMasterId
					WHERE WOM.IsDeleted = 0 AND WOM.WorkFlowWorkOrderId = @Local_WFWOId
					AND WOMKM.WorkOrderMaterialsKitMappingId IN (SELECT WorkOrderMaterialsKitMappingId FROM #TMPWOMaterialResultListData WHERE IsKit = 1)
				END

				SELECT @Count = COUNT(ParentID) from #TMPWOMaterialParentListData;

				SELECT *, @Count As NumberOfItems FROM #finalMaterialListResult
				ORDER BY    
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='taskName')  THEN taskName END ASC
					,CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='partNumber')  THEN partNumber END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='alterPartNumber')  THEN alterPartNumber END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='partDescription')  THEN partDescription END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='manufacturerName')  THEN manufacturerName END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='condition')  THEN condition END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='mandatoryOrSupplemental')  THEN mandatoryOrSupplemental END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='provision')  THEN provision END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='quantity')  THEN quantity END ASC,  
					--CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='kitStocklineQuantity')  THEN kitStocklineQuantity END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='quantityReserved')  THEN quantityReserved END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='qtytobeReserved')  THEN qtytobeReserved END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='quantityIssued')  THEN quantityIssued END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='qunatityRemaining')  THEN qunatityRemaining END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='partQtyToTurnIn')  THEN partQtyToTurnIn END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='partQuantityTurnIn')  THEN partQuantityTurnIn END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='partQuantityOnHand')  THEN partQuantityOnHand END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='partQuantityAvailable')  THEN partQuantityAvailable END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='uom')  THEN uom END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='stockType')  THEN stockType END ASC,  
					--CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='needDate')  THEN needDate END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='currency')  THEN currency END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='unitCost')  THEN unitCost END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='extendedCost')  THEN extendedCost END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='qtyOnOrder')  THEN qtyOnOrder END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='qtyOnBkOrder')  THEN qtyOnBkOrder END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='poNum')  THEN poNum END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='poNextDlvrDate')  THEN poNextDlvrDate END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='figure')  THEN figure END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='item')  THEN item END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='isFromWorkFlow')  THEN isFromWorkFlow END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='employeename')  THEN employeename END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='isDeferred')  THEN isDeferred END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='memo')  THEN memo END ASC, 
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='expectedSerialNumber')  THEN expectedSerialNumber END ASC, 

					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='taskName')  THEN taskName END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='partNumber')  THEN partNumber END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='alterPartNumber')  THEN alterPartNumber END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='partDescription')  THEN partDescription END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='manufacturerName')  THEN manufacturerName END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='condition')  THEN condition END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='mandatoryOrSupplemental')  THEN mandatoryOrSupplemental END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='provision')  THEN provision END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='quantity')  THEN quantity END DESC,  
					--CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='kitStocklineQuantity')  THEN kitStocklineQuantity END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='quantityReserved')  THEN quantityReserved END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='qtytobeReserved')  THEN qtytobeReserved END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='quantityIssued')  THEN quantityIssued END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='qunatityRemaining')  THEN qunatityRemaining END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='partQtyToTurnIn')  THEN partQtyToTurnIn END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='partQuantityTurnIn')  THEN partQuantityTurnIn END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='partQuantityOnHand')  THEN partQuantityOnHand END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='partQuantityAvailable')  THEN partQuantityAvailable END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='uom')  THEN uom END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='stockType')  THEN stockType END DESC,  
					--CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='needDate')  THEN needDate END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='currency')  THEN currency END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='unitCost')  THEN unitCost END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='extendedCost')  THEN extendedCost END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='qtyOnOrder')  THEN qtyOnOrder END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='qtyOnBkOrder')  THEN qtyOnBkOrder END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='poNum')  THEN poNum END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='poNextDlvrDate')  THEN poNextDlvrDate END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='figure')  THEN figure END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='item')  THEN item END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='isFromWorkFlow')  THEN isFromWorkFlow END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='employeename')  THEN employeename END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='isDeferred')  THEN isDeferred END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='memo')  THEN memo END DESC, 
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='expectedSerialNumber')  THEN expectedSerialNumber END DESC

				IF OBJECT_ID(N'tempdb..#tmpStockline') IS NOT NULL
				BEGIN
				DROP TABLE #tmpStockline
				END

				IF OBJECT_ID(N'tempdb..#tmpWOMStockline') IS NOT NULL
				BEGIN
				DROP TABLE #tmpWOMStockline
				END

				IF OBJECT_ID(N'tempdb..#tmpStocklineKit') IS NOT NULL
				BEGIN
					DROP TABLE #tmpStocklineKit
				END

				IF OBJECT_ID(N'tempdb..#tmpWOMStocklineKit') IS NOT NULL
				BEGIN
					DROP TABLE #tmpWOMStocklineKit
				END

				IF OBJECT_ID(N'tempdb..#finalMaterialListResult') IS NOT NULL
				BEGIN
					DROP TABLE #finalMaterialListResult
				END
			END
		--COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				--ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderMaterialsListNew' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''', 
													   @Parameter2 = ' + ISNULL(@WFWOId ,'') +''
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
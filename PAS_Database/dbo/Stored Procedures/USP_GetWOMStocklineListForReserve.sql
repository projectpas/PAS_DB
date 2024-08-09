/*************************************************************           
 ** File:   [USP_GetWOMStocklineListForReserve]           
 ** Author:  Devendra Shekh
 ** Description: This SP is Used to get Stockline list to reserve Stockline with Pagination
 ** Purpose:         
 ** Date:   08/07/2024		[mm/dd/yyyy]
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			  Author					Change Description            
 ** --   --------		 -------					--------------------------------          
    1    08/07/2024		 Devendra Shekh				Created
     
EXECUTE USP_GetWorkOrdMaterialsStocklineListForReserve 3847,0,0,3399,0

exec dbo.USP_GetWOMStocklineListForReserve @PageNumber=1,@PageSize=10,@SortColumn=default,@SortOrder=1,@WorkFlowWorkOrderId=3847,@ItemMasterId=0,@WorkOrderMaterialsId=16483,@KitId=0,@IncludeCustomerStock=0
exec dbo.USP_GetWOMStocklineListForReserve @PageNumber=1,@PageSize=10,@SortColumn=default,@SortOrder=1,@WorkFlowWorkOrderId=3847,@ItemMasterId=0,@WorkOrderMaterialsId=0,@KitId=3395,@IncludeCustomerStock=0
exec dbo.USP_GetWOMStocklineListForReserve @PageNumber=1,@PageSize=10,@SortColumn=default,@SortOrder=1,@WorkFlowWorkOrderId=3847,@ItemMasterId=121,@WorkOrderMaterialsId=0,@KitId=3395,@IncludeCustomerStock=0
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetWOMStocklineListForReserve]
(    
	@PageNumber int,  
	@PageSize int,  
	@SortColumn varchar(50)=null,  
	@SortOrder int,  
	@WorkFlowWorkOrderId BIGINT = NULL,
	@ItemMasterId BIGINT = NULL,
	@WorkOrderMaterialsId BIGINT = NULL,
	@KitId BIGINT = NULL,
	@IncludeCustomerStock BIT
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN

				IF OBJECT_ID(N'tempdb..#finalReserveMaterialListResult') IS NOT NULL
				BEGIN
					DROP TABLE #finalReserveMaterialListResult
				END

				IF OBJECT_ID(N'tempdb..#TMPWOReserveMaterialParentListData') IS NOT NULL
				BEGIN
					DROP TABLE #TMPWOReserveMaterialParentListData
				END

				IF OBJECT_ID(N'tempdb..#TMPWOMaterialResultListData') IS NOT NULL
				BEGIN
					DROP TABLE #TMPWOMaterialResultListData
				END
			
				CREATE TABLE #finalReserveMaterialListResult
				(
		 			[RecordID] [bigint] NOT NULL IDENTITY, 	
					[WorkOrderId] [bigint] NULL,
					[WorkFlowWorkOrderId] [bigint] NULL,
					[WorkOrderMaterialsId] [bigint] NULL,
					[WOMStockLineId] [bigint] NULL,
					[ItemMasterId] [bigint] NULL,
					[AltPartMasterPartId] [bigint] NULL,
					[EquPartMasterPartId] [bigint] NULL,
					[ConditionId] [bigint] NULL,
					[StocklineConditionId] [bigint] NULL,
					[ConditionGroup] [varchar](50) NULL,
					[MasterCompanyId] [int] NULL,
					[Quantity] [int] NULL,
					[QuantityReserved] [int] NULL,
					[QuantityIssued] [int] NULL,
					[QuantityOnOrder] [int] NULL,
					[QtyToBeReserved] [int] NULL,
					[UnitCost] [decimal](18,2) NULL,
					[ExtendedCost] [decimal](18,2) NULL,
					[TaskId] [bigint] NULL,
					[ProvisionId] [int] NULL,
					[PartNumber] [varchar](50) NULL,
		 			[PartDescription] [varchar](MAX) NULL,
					[MainPartNumber] [varchar](50) NULL,
		 			[MainPartDescription] [varchar](MAX) NULL,
					[MainManufacturer] [varchar](250) NULL,
					[MainCondition] [varchar](256) NULL,
					[StocklineId] [bigint] NULL,
					[Condition] [varchar](100) NULL,
					[StockLineNumber] [varchar](50) NULL,
					[ControlNo] [varchar](50) NULL,
					[ControlId] [varchar](100) NULL,
					[Manufacturer] [varchar](50) NULL,
					[SerialNumber] [varchar](30) NULL,
					[QuantityAvailable] [int] NULL,
					[QuantityOnHand] [int] NULL,
					[CreatedDate] [datetime2] NULL,
					[StocklineQuantityOnOrder] [int] NULL,
					[StocklineQuantityTurnIn] [int] NULL,
					[UnitOfMeasure] [varchar](100) NULL,
					[Provision] [varchar](100) NULL,
					[ProvisionStatusCode] [varchar](20) NULL,
					[StockType] [varchar](30) NULL,
					[MSQuantityRequsted] [int] NULL,
					[MSQuantityReserved] [int] NULL,
					[MSQuantityIssued] [int] NULL,
					[StocklineUnitCost] [decimal](18,2) NULL,
					[MSQunatityRemaining] [int] NULL,
					[StocklineProvision] [varchar](100) NULL,
					[StocklineProvisionCode] [varchar](50) NULL,
					[IsStocklineAdded] [bit] NULL,
					[IsAltPart] [bit] NULL,
					[IsEquPart] [bit] NULL,
					[TaskName] [varchar](200) NULL
				)

				CREATE TABLE #TMPWOReserveMaterialParentListData
				 (
		 			[ParentID] BIGINT NOT NULL IDENTITY, 						 
		 			[WorkOrderMaterialsId] [bigint] NULL,
		 			[WorkOrderMaterialsKitMappingId] [bigint] NULL,
		 			[WorkFlowWorkOrderId] [bigint] NULL,
		 			[ItemMasterId] [bigint] NULL,
		 			[IsKit] [bit] NULL,
		 			[IsAltPart] [bit] NULL,
		 			[IsEquPart] [bit] NULL,
				 )
				
				DECLARE @ProvisionId BIGINT;
				DECLARE @SubWOProvisionId BIGINT;
				DECLARE @Provision VARCHAR(50);
				DECLARE @ProvisionCode VARCHAR(50);
				DECLARE @CustomerID BIGINT;
				DECLARE @MasterCompanyId BIGINT;
				DECLARE @ARConditionId BIGINT;
				DECLARE @ConditionId BIGINT;
				DECLARE @ConditionGroup VARCHAR(50);
				DECLARE @RecordFrom int;  
				DECLARE @Count Int;  
				DECLARE @WOPartNOId BIGINT;

				IF @SortColumn IS NULL
				BEGIN  
					SET @SortColumn = ('taskName')
				END
				SET @RecordFrom = (@PageNumber-1)*@PageSize;  

				SELECT @ProvisionId = ProvisionId, @Provision = [Description], @ProvisionCode = StatusCode FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'REPLACE' AND IsActive = 1 AND IsDeleted = 0;
				SELECT @SubWOProvisionId = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'SUB WORK ORDER' AND IsActive = 1 AND IsDeleted = 0;
				SELECT @CustomerID = WO.CustomerId, @MasterCompanyId = WO.MasterCompanyId FROM dbo.WorkOrder WO WITH(NOLOCK) JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) on WO.WorkOrderId = WOWF.WorkOrderId WHERE WOWF.WorkFlowWorkOrderId = @WorkFlowWorkOrderId;
				SELECT @ARConditionId = ConditionId FROM dbo.Condition WITH(NOLOCK) WHERE Code = 'ASREMOVE' AND MasterCompanyId = @MasterCompanyId;
				SELECT @WOPartNOId = WorkOrderPartNoId FROM dbo.WorkOrderWorkFlow WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND MasterCompanyId = @MasterCompanyId;

				IF(@ItemMasterId = 0)
				BEGIN
					SET @ItemMasterId = NULL;
				END

				IF(@WorkOrderMaterialsId = 0)
				BEGIN
					SET @WorkOrderMaterialsId = NULL;
				END

				IF(@KitId = 0)
				BEGIN
					SET @KitId = NULL;
				END

				IF OBJECT_ID(N'tempdb..#AltPartList') IS NOT NULL
				BEGIN
					DROP TABLE #AltPartList 
				END

				IF OBJECT_ID(N'tempdb..#EquPartList') IS NOT NULL
				BEGIN
					DROP TABLE #EquPartList 
				END

				IF OBJECT_ID(N'tempdb..#ConditionGroup') IS NOT NULL
				BEGIN
					DROP TABLE #ConditionGroup 
				END
			
				CREATE TABLE #AltPartList 
				(
					ID BIGINT NOT NULL IDENTITY, 
					[ItemMasterId] [BIGINT] NULL,
					[AltItemMasterId] [BIGINT] NULL
				)

				CREATE TABLE #EquPartList 
				(
					ID BIGINT NOT NULL IDENTITY, 
					[ItemMasterId] [BIGINT] NULL,
					[EquItemMasterId] [BIGINT] NULL
				)

				CREATE TABLE #ConditionGroup 
				(
					ID BIGINT NOT NULL IDENTITY, 
					[ConditionId] [BIGINT] NULL,
					[WorkOrderMaterialsId] [BIGINT] NULL,
					[ConditionGroup] VARCHAR(50) NULL,
				)

				--Inserting Data For #AltPartList / #EquPartList : Start
				IF(ISNULL(@KitId, 0) = 0)
				BEGIN
						IF(ISNULL(@WorkOrderMaterialsId, 0) > 0)
						BEGIN
							SELECT @ConditionGroup = C.GroupCode FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK) JOIN dbo.Condition C ON C.ConditionId = WOM.ConditionCodeId WHERE WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId AND C.MasterCompanyId = @MasterCompanyId
					
							INSERT INTO #ConditionGroup (ConditionId, WorkOrderMaterialsId, ConditionGroup)
							SELECT DISTINCT ConditionId, WOM.WorkOrderMaterialsId, C.GroupCode 
							FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK) JOIN dbo.Condition C ON C.ConditionId = WOM.ConditionCodeId 
							WHERE WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId AND C.MasterCompanyId = @MasterCompanyId AND WOM.ConditionCodeId <> @ARConditionId

							INSERT INTO #ConditionGroup (ConditionId, WorkOrderMaterialsId, ConditionGroup)
							SELECT DISTINCT C.ConditionId, CG.WorkOrderMaterialsId, CG.ConditionGroup FROM dbo.Condition C JOIN #ConditionGroup CG ON C.GroupCode = CG.ConditionGroup 
							WHERE C.ConditionId != CG.ConditionId AND C.MasterCompanyId = @MasterCompanyId

						END
						BEGIN
							INSERT INTO #ConditionGroup (ConditionId, WorkOrderMaterialsId, ConditionGroup)
							SELECT DISTINCT ConditionId, WOM.WorkOrderMaterialsId, C.GroupCode 
							FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK) JOIN dbo.Condition C ON C.ConditionId = WOM.ConditionCodeId 
							WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND C.MasterCompanyId = @MasterCompanyId AND WOM.ConditionCodeId <> @ARConditionId

							INSERT INTO #ConditionGroup (ConditionId, WorkOrderMaterialsId, ConditionGroup)
							SELECT DISTINCT C.ConditionId, CG.WorkOrderMaterialsId, CG.ConditionGroup FROM dbo.Condition C JOIN #ConditionGroup CG ON C.GroupCode = CG.ConditionGroup 
							WHERE C.ConditionId != CG.ConditionId AND C.MasterCompanyId = @MasterCompanyId
						END

						INSERT INTO #AltPartList
						([ItemMasterId], [AltItemMasterId])
						SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
						FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
							LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 1 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
							LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.ConditionCodeId <> @ARConditionId

						INSERT INTO #EquPartList
						([ItemMasterId], [EquItemMasterId])
						SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
						FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
							LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 2 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
							LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.ConditionCodeId <> @ARConditionId

						--Inserting Data For Parent Level
						INSERT INTO #TMPWOReserveMaterialParentListData
						([WorkOrderMaterialsId], [WorkFlowWorkOrderId], [WorkOrderMaterialsKitMappingId], [ItemMasterId], [IsKit], [IsAltPart], [IsEquPart])
						SELECT DISTINCT	WOM.[WorkOrderMaterialsId], [WorkFlowWorkOrderId], 0, WOM.ItemMasterId, 0, 0, 0 FROM [DBO].WorkOrderMaterials WOM WITH(NOLOCK) 
						JOIN dbo.Stockline SL WITH (NOLOCK) ON WOM.ItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE WorkOrderMaterialsId = WOM.WorkOrderMaterialsId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
						WHERE	WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.IsDeleted = 0
								AND (@ItemMasterId IS NULL OR WOM.ItemMasterId = @ItemMasterId)
								AND (@WorkOrderMaterialsId IS NULL OR WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId)
								AND WOM.ConditionCodeId <> @ARConditionId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0

						INSERT INTO #TMPWOReserveMaterialParentListData
						([WorkOrderMaterialsId], [WorkFlowWorkOrderId], [WorkOrderMaterialsKitMappingId], [ItemMasterId], [IsKit], [IsAltPart], [IsEquPart])
						SELECT DISTINCT	WOM.[WorkOrderMaterialsId], WOM.WorkFlowWorkOrderId, 0, ALT.ItemMasterId, 0, 1, 0 
						FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)
						JOIN #AltPartList ALT WITH (NOLOCK) ON WOM.ItemMasterId = Alt.ItemMasterId
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Alt.AltItemMasterId
						JOIN dbo.Stockline SL WITH (NOLOCK) ON Alt.AltItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE WorkOrderMaterialsId = WOM.WorkOrderMaterialsId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
						WHERE	WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId
								AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR ALT.ItemMasterId = @ItemMasterId)
								AND (@WorkOrderMaterialsId IS NULL OR WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId)
								AND WOM.WorkOrderMaterialsId NOT IN (SELECT [WorkOrderMaterialsId] FROM #TMPWOReserveMaterialParentListData WHERE IsKit = 0)
								AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0;

						INSERT INTO #TMPWOReserveMaterialParentListData
						([WorkOrderMaterialsId], [WorkFlowWorkOrderId], [WorkOrderMaterialsKitMappingId], [ItemMasterId], [IsKit], [IsAltPart], [IsEquPart])
						SELECT DISTINCT	WOM.[WorkOrderMaterialsId], WOM.WorkFlowWorkOrderId, 0, EQU.ItemMasterId, 0, 1, 0 
						FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)
						JOIN #EquPartList EQU WITH (NOLOCK) ON WOM.ItemMasterId = EQU.ItemMasterId
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = EQU.EquItemMasterId
						JOIN dbo.Stockline SL WITH (NOLOCK) ON Equ.EquItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE WorkOrderMaterialsId = WOM.WorkOrderMaterialsId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
						WHERE	WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId 
								AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR EQU.ItemMasterId = @ItemMasterId)
								AND (@WorkOrderMaterialsId IS NULL OR WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId)
								AND WOM.WorkOrderMaterialsId NOT IN (SELECT [WorkOrderMaterialsId] FROM #TMPWOReserveMaterialParentListData WHERE IsKit = 0)
								AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0;
				END
				ELSE
				BEGIN
						INSERT INTO #ConditionGroup (ConditionId, WorkOrderMaterialsId, ConditionGroup)
						SELECT DISTINCT ConditionId, WOM.WorkOrderMaterialsKitId, C.GroupCode FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) 
						JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
						JOIN dbo.Condition C ON C.ConditionId = WOM.ConditionCodeId WHERE WOMKM.KitId = @KitId AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND C.MasterCompanyId = @MasterCompanyId AND WOM.ConditionCodeId <> @ARConditionId

						INSERT INTO #ConditionGroup (ConditionId, WorkOrderMaterialsId, ConditionGroup)
						SELECT DISTINCT C.ConditionId, CG.WorkOrderMaterialsId, CG.ConditionGroup FROM dbo.Condition C JOIN #ConditionGroup CG ON C.GroupCode = CG.ConditionGroup 
						WHERE C.ConditionId != CG.ConditionId AND C.MasterCompanyId = @MasterCompanyId

						INSERT INTO #AltPartList
						([ItemMasterId], [AltItemMasterId])
						SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
						FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
							LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 1 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
							LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
							JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
						WHERE (@KitId IS NULL OR WOMKM.KitId = @KitId) AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.ConditionCodeId <> @ARConditionId

						INSERT INTO #EquPartList
						([ItemMasterId], [EquItemMasterId])
						SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
						FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
							LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 2 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
							LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
							JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
						WHERE (@KitId IS NULL OR WOMKM.KitId = @KitId) AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.ConditionCodeId <> @ARConditionId

						--Inserting Data For Parent Level
						INSERT INTO #TMPWOReserveMaterialParentListData
						([WorkOrderMaterialsId], [WorkFlowWorkOrderId], [WorkOrderMaterialsKitMappingId], [ItemMasterId], [IsKit], [IsAltPart], [IsEquPart])
						SELECT DISTINCT	WOM.WorkOrderMaterialsKitId, [WorkFlowWorkOrderId], WOM.[WorkOrderMaterialsKitMappingId], WOM.ItemMasterId, 1, 0, 0 FROM [DBO].WorkOrderMaterialsKit WOM WITH(NOLOCK)
						JOIN [dbo].[WorkOrderMaterialsKitMapping] WOMKITMP WITH(NOLOCK) ON WOM.WorkOrderMaterialsKitMappingId = WOMKITMP.WorkOrderMaterialsKitMappingId
						JOIN dbo.Stockline SL WITH (NOLOCK) ON WOM.ItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
						WHERE	WOM.IsDeleted = 0 AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId
								AND (@KitId IS NULL OR WOMKITMP.KitId = @KitId)
								AND (@ItemMasterId IS NULL OR WOM.ItemMasterId = @ItemMasterId)
								AND WOM.ConditionCodeId <> @ARConditionId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0;

						INSERT INTO #TMPWOReserveMaterialParentListData
						([WorkOrderMaterialsId], [WorkFlowWorkOrderId], [WorkOrderMaterialsKitMappingId], [ItemMasterId], [IsKit], [IsAltPart], [IsEquPart])
						SELECT DISTINCT	WOM.WorkOrderMaterialsKitId, WOM.WorkFlowWorkOrderId, 0, ALT.ItemMasterId, 1, 1, 0 
						FROM dbo.WorkOrderMaterialsKitMapping WOMKM WITH(NOLOCK)
						JOIN dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
						JOIN #AltPartList ALT WITH (NOLOCK) ON WOM.ItemMasterId = Alt.ItemMasterId
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Alt.AltItemMasterId
						JOIN dbo.Stockline SL WITH (NOLOCK) ON Alt.AltItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
						WHERE	(@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR ALT.ItemMasterId = @ItemMasterId)
								AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId
								AND (@KitId IS NULL OR WOMKM.KitId = @KitId)
								AND WOM.WorkOrderMaterialsKitId NOT IN (SELECT [WorkOrderMaterialsId] FROM #TMPWOReserveMaterialParentListData WHERE IsKit = 1)
								AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0;

						INSERT INTO #TMPWOReserveMaterialParentListData
						([WorkOrderMaterialsId], [WorkFlowWorkOrderId], [WorkOrderMaterialsKitMappingId], [ItemMasterId], [IsKit], [IsAltPart], [IsEquPart])
						SELECT DISTINCT	WOM.WorkOrderMaterialsKitId, WOM.WorkFlowWorkOrderId, 0, EQU.ItemMasterId, 1, 1, 0 
						FROM dbo.WorkOrderMaterialsKitMapping WOMKM WITH(NOLOCK)
						JOIN dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
						JOIN #EquPartList EQU WITH (NOLOCK) ON WOM.ItemMasterId = EQU.ItemMasterId
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = EQU.EquItemMasterId
						JOIN dbo.Stockline SL WITH (NOLOCK) ON Equ.EquItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
						WHERE	(@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR EQU.ItemMasterId = @ItemMasterId)
								AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId
								AND (@KitId IS NULL OR WOMKM.KitId = @KitId)
								AND WOM.WorkOrderMaterialsKitId NOT IN (SELECT [WorkOrderMaterialsId] FROM #TMPWOReserveMaterialParentListData WHERE IsKit = 1)
								AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0;
				END
				--Inserting Data For #AltPartList / #EquPartList : End

				SELECT * INTO #TMPWOMaterialResultListData FROM #TMPWOReserveMaterialParentListData tmp 
				ORDER BY tmp.[WorkFlowWorkOrderId] ASC
				OFFSET @RecordFrom ROWS   
				FETCH NEXT @PageSize ROWS ONLY
				--Inserting Data For Parent Level- For Pagination : End

				--select * from #TMPWOReserveMaterialParentListData

				SELECT @Count = COUNT(ParentID) from #TMPWOReserveMaterialParentListData;

				IF(@Count > 0)
				BEGIN
					IF(ISNULL(@KitId, 0) = 0)
					BEGIN			

						INSERT INTO #finalReserveMaterialListResult([WorkOrderId], [WorkFlowWorkOrderId], [WorkOrderMaterialsId], [WOMStockLineId], [ItemMasterId],
									[AltPartMasterPartId], [EquPartMasterPartId], [ConditionId], [StocklineConditionId], [ConditionGroup], [MasterCompanyId], [Quantity], [QuantityReserved], [QuantityIssued], [QuantityOnOrder], 
									[QtyToBeReserved], [UnitCost], [ExtendedCost], [TaskId], [ProvisionId], [PartNumber], [PartDescription], [MainPartNumber],[MainPartDescription], [MainManufacturer], [MainCondition], [StocklineId],
									[Condition], [StockLineNumber], [ControlNo], [ControlId], [Manufacturer], [SerialNumber], [QuantityAvailable], [QuantityOnHand], [CreatedDate], [StocklineQuantityOnOrder], [StocklineQuantityTurnIn],
									[UnitOfMeasure], [Provision], [ProvisionStatusCode], [StockType], [MSQuantityRequsted], [MSQuantityReserved], [MSQuantityIssued], [StocklineUnitCost], [MSQunatityRemaining], [StocklineProvision], 
									[StocklineProvisionCode], [IsStocklineAdded], [IsAltPart], [IsEquPart], [TaskName])
						SELECT  WOM.WorkOrderId,
								WOM.WorkFlowWorkOrderId,
								WOM.WorkOrderMaterialsId,		
								WOMS.WOMStockLineId,
								WOM.ItemMasterId,
								0 AS AltPartMasterPartId,
								0 AS EquPartMasterPartId,
								WOM.ConditionCodeId AS ConditionId,
								SL.ConditionId AS StocklineConditionId,
								@ConditionGroup AS ConditionGroup,
								WOM.MasterCompanyId,
								ISNULL(WOM.Quantity, 0),
								ISNULL(WOM.QuantityReserved, 0),
								ISNULL(WOM.QuantityIssued, 0),
								ISNULL(WOM.QtyOnOrder, 0) AS QuantityOnOrder,
								(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
								ISNULL(WOM.UnitCost, 0),
								ISNULL(WOM.ExtendedCost, 0),
								WOM.TaskId,
								WOM.ProvisionId,
								IM.PartNumber,
								IM.PartDescription, 
								IM.PartNumber AS MainPartNumber,
								IM.PartDescription AS MainPartDescription, 
								IM.ManufacturerName AS MainManufacturer,
								C.[Description] AS MainCondition,
								SL.StocklineId,
								SL.Condition,
								ISNULL(SL.StockLineNumber, ''),
								ISNULL(SL.ControlNumber, ''),
								ISNULL(SL.IdNumber, ''),
								SL.Manufacturer,
								ISNULL(SL.SerialNumber, 0),
								ISNULL(SL.QuantityAvailable, 0) AS QuantityAvailable,
								ISNULL(SL.QuantityOnHand, 0) AS QuantityOnHand,
								SL.CreatedDate,
								ISNULL(SL.QuantityOnOrder, 0) AS StocklineQuantityOnOrder,
								ISNULL(SL.QuantityTurnIn, 0) AS StocklineQuantityTurnIn,
								SL.UnitOfMeasure,
								P.Description AS Provision,
								P.StatusCode AS ProvisionStatusCode,
								CASE 
								WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
								WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
								WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
								ELSE 'OEM'
								END AS StockType,
								ISNULL(CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) END
								, 0)AS MSQuantityRequsted,
								ISNULL(WOMS.QtyReserved, 0) AS MSQuantityReserved,
								ISNULL(WOMS.QtyIssued, 0) AS MSQuantityIssued,
								ISNULL(CASE WHEN WOMS.WOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END, 0) AS SLUnitCost,
								MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
								CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
								CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
								CASE WHEN WOMS.WOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
								0 AS IsAltPart,
								0 AS IsEquPart
								,TS.[Description] AS 'TaskName' 
							FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
								JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
								JOIN dbo.Stockline SL WITH (NOLOCK) ON WOM.ItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE WorkOrderMaterialsId = WOM.WorkOrderMaterialsId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
								LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId --(SELECT ConditionId FROM #ConditionGroup WHERE WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId)
								LEFT JOIN dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
								LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
								LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
								LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
								LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
							WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.ConditionCodeId <> @ARConditionId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  							
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
								--AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId) 
								AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								--AND (@WorkOrderMaterialsId IS NULL OR WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId)
								AND ( WOM.WorkOrderMaterialsId IN (SELECT WorkOrderMaterialsId FROM #TMPWOMaterialResultListData WHERE IsKit = 0)) --OR
									  --WOM.ItemMasterId IN (SELECT ItemMasterId FROM #TMPWOMaterialResultListData WHERE IsKit = 0 AND IsAltPart = 0 AND IsEquPart = 0))

						INSERT INTO #finalReserveMaterialListResult([WorkOrderId], [WorkFlowWorkOrderId], [WorkOrderMaterialsId], [WOMStockLineId], [ItemMasterId],
									[AltPartMasterPartId], [EquPartMasterPartId], [ConditionId], [StocklineConditionId], [ConditionGroup], [MasterCompanyId], [Quantity], [QuantityReserved], [QuantityIssued], [QuantityOnOrder], 
									[QtyToBeReserved], [UnitCost], [ExtendedCost], [TaskId], [ProvisionId], [PartNumber], [PartDescription], [MainPartNumber],[MainPartDescription], [MainManufacturer], [MainCondition], [StocklineId],
									[Condition], [StockLineNumber], [ControlNo], [ControlId], [Manufacturer], [SerialNumber], [QuantityAvailable], [QuantityOnHand], [CreatedDate], [StocklineQuantityOnOrder], [StocklineQuantityTurnIn],
									[UnitOfMeasure], [Provision], [ProvisionStatusCode], [StockType], [MSQuantityRequsted], [MSQuantityReserved], [MSQuantityIssued], [StocklineUnitCost], [MSQunatityRemaining], [StocklineProvision], 
									[StocklineProvisionCode], [IsStocklineAdded], [IsAltPart], [IsEquPart], [TaskName])
						SELECT  WOM.WorkOrderId,
								WOM.WorkFlowWorkOrderId,
								WOM.WorkOrderMaterialsId,		
								WOMS.WOMStockLineId,
								Alt.AltItemMasterId ItemMasterId,
								Alt.ItemMasterId AS AltPartMasterPartId,
								Alt.ItemMasterId AS EquPartMasterPartId,
								WOM.ConditionCodeId AS ConditionId,
								SL.ConditionId AS StocklineConditionId,
								@ConditionGroup AS ConditionGroup,
								WOM.MasterCompanyId,
								ISNULL(WOM.Quantity, 0),
								ISNULL(WOM.QuantityReserved, 0),
								ISNULL(WOM.QuantityIssued, 0),
								ISNULL(WOM.QtyOnOrder, 0) AS QuantityOnOrder,
								(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
								ISNULL(WOM.UnitCost, 0),
								ISNULL(WOM.ExtendedCost, 0),
								WOM.TaskId,
								WOM.ProvisionId,
								IM.PartNumber,
								IM.PartDescription,
								IM_AltMain.PartNumber AS MainPartNumber,
								IM_AltMain.PartDescription AS MainPartDescription,
								IM_AltMain.ManufacturerName AS MainManufacturer,
								C.[Description] AS MainCondition,
								SL.StocklineId,
								SL.Condition,
								SL.StockLineNumber,
								SL.ControlNumber,
								SL.IdNumber,
								SL.Manufacturer,
								SL.SerialNumber,
								ISNULL(SL.QuantityAvailable, 0) AS QuantityAvailable,
								ISNULL(SL.QuantityOnHand, 0) AS QuantityOnHand,
								SL.CreatedDate,
								ISNULL(SL.QuantityOnOrder, 0) AS StocklineQuantityOnOrder,
								ISNULL(SL.QuantityTurnIn, 0) AS StocklineQuantityTurnIn,
								SL.UnitOfMeasure,
								P.Description AS Provision,
								P.StatusCode AS ProvisionStatusCode,
								CASE 
								WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
								WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
								WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
								ELSE 'OEM'
								END AS StockType,
								ISNULL(CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) END
								, 0)AS MSQuantityRequsted,
								ISNULL(WOMS.QtyReserved, 0) AS MSQuantityReserved,
								ISNULL(WOMS.QtyIssued, 0) AS MSQuantityIssued,
								ISNULL(CASE WHEN WOMS.WOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END, 0) AS SLUnitCost,
								MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
								CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
								CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
								CASE WHEN WOMS.WOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
								1 AS IsAltPart,
								0 AS IsEquPart
								,TS.[Description] AS 'TaskName' 
							FROM #AltPartList Alt
								JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.ItemMasterId = Alt.ItemMasterId
								JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Alt.AltItemMasterId
								JOIN dbo.Stockline SL WITH (NOLOCK) ON Alt.AltItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE WorkOrderMaterialsId = WOM.WorkOrderMaterialsId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
								LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
								LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = Alt.ItemMasterId
								LEFT JOIN dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
								LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
								LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
								LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
								LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
							WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
								--AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId) 
								AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								--AND (@WorkOrderMaterialsId IS NULL OR WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId)
								AND (WOM.WorkOrderMaterialsId IN (SELECT WorkOrderMaterialsId FROM #TMPWOMaterialResultListData WHERE IsKit = 0) )--OR
									  --WOM.ItemMasterId IN (SELECT ItemMasterId FROM #TMPWOMaterialResultListData WHERE IsKit = 0 AND IsAltPart = 1 AND IsEquPart = 0))

						INSERT INTO #finalReserveMaterialListResult([WorkOrderId], [WorkFlowWorkOrderId], [WorkOrderMaterialsId], [WOMStockLineId], [ItemMasterId],
									[AltPartMasterPartId], [EquPartMasterPartId], [ConditionId], [StocklineConditionId], [ConditionGroup], [MasterCompanyId], [Quantity], [QuantityReserved], [QuantityIssued], [QuantityOnOrder], 
									[QtyToBeReserved], [UnitCost], [ExtendedCost], [TaskId], [ProvisionId], [PartNumber], [PartDescription], [MainPartNumber],[MainPartDescription], [MainManufacturer], [MainCondition], [StocklineId],
									[Condition], [StockLineNumber], [ControlNo], [ControlId], [Manufacturer], [SerialNumber], [QuantityAvailable], [QuantityOnHand], [CreatedDate], [StocklineQuantityOnOrder], [StocklineQuantityTurnIn],
									[UnitOfMeasure], [Provision], [ProvisionStatusCode], [StockType], [MSQuantityRequsted], [MSQuantityReserved], [MSQuantityIssued], [StocklineUnitCost], [MSQunatityRemaining], [StocklineProvision], 
									[StocklineProvisionCode], [IsStocklineAdded], [IsAltPart], [IsEquPart], [TaskName])
						SELECT  WOM.WorkOrderId,
								WOM.WorkFlowWorkOrderId,
								WOM.WorkOrderMaterialsId,		
								WOMS.WOMStockLineId,	
								Equ.EquItemMasterId ItemMasterId,
								Equ.ItemMasterId AS AltPartMasterPartId,
								Equ.ItemMasterId AS EquPartMasterPartId,
								WOM.ConditionCodeId AS ConditionId,
								SL.ConditionId AS StocklineConditionId,
								@ConditionGroup AS ConditionGroup,
								WOM.MasterCompanyId,
								ISNULL(WOM.Quantity, 0),
								ISNULL(WOM.QuantityReserved, 0),
								ISNULL(WOM.QuantityIssued, 0),
								ISNULL(WOM.QtyOnOrder, 0) AS QuantityOnOrder,
								(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
								ISNULL(WOM.UnitCost, 0),
								ISNULL(WOM.ExtendedCost, 0),
								WOM.TaskId,
								WOM.ProvisionId,
								IM.PartNumber,
								IM.PartDescription, 
								IM_EquMain.PartNumber MainPartNumber,
								IM_EquMain.PartDescription MainPartDescription,
								IM_EquMain.ManufacturerName MainManufacturer,
								C.[Description] AS MainCondition,
								SL.StocklineId,
								SL.Condition,
								SL.StockLineNumber,
								SL.ControlNumber,
								SL.IdNumber,
								SL.Manufacturer,
								SL.SerialNumber,
								ISNULL(SL.QuantityAvailable, 0) AS QuantityAvailable,
								ISNULL(SL.QuantityOnHand, 0) AS QuantityOnHand,
								SL.CreatedDate,
								ISNULL(SL.QuantityOnOrder, 0) AS StocklineQuantityOnOrder,
								ISNULL(SL.QuantityTurnIn, 0) AS StocklineQuantityTurnIn,
								SL.UnitOfMeasure,
								P.Description AS Provision,
								P.StatusCode AS ProvisionStatusCode,
								CASE 
								WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
								WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
								WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
								ELSE 'OEM'
								END AS StockType,
								ISNULL(CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) END
								, 0)AS MSQuantityRequsted,
								ISNULL(WOMS.QtyReserved, 0) AS MSQuantityReserved,
								ISNULL(WOMS.QtyIssued, 0) AS MSQuantityIssued,
								ISNULL(CASE WHEN WOMS.WOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END, 0) AS SLUnitCost,
								MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
								CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
								CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
								CASE WHEN WOMS.WOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
								0 AS IsAltPart,
								1 AS IsEquPart
								,TS.[Description] AS 'TaskName' 
							FROM #EquPartList Equ
								JOIN dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.ItemMasterId = Equ.ItemMasterId
								JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Equ.EquItemMasterId
								JOIN dbo.Stockline SL WITH (NOLOCK) ON Equ.EquItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE WorkOrderMaterialsId = WOM.WorkOrderMaterialsId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
								LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = Equ.ItemMasterId
								LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
								LEFT JOIN dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
								LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
								LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
								LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
								LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
							WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
								--AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_EquMain.ItemMasterId = @ItemMasterId) 
								AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								--AND (@WorkOrderMaterialsId IS NULL OR WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId)
								AND ( WOM.WorkOrderMaterialsId IN (SELECT WorkOrderMaterialsId FROM #TMPWOMaterialResultListData WHERE IsKit = 0))-- OR
									  --WOM.ItemMasterId IN (SELECT ItemMasterId FROM #TMPWOMaterialResultListData WHERE IsKit = 0 AND IsAltPart = 0 AND IsEquPart = 1))
					END
					ELSE
					BEGIN										

						INSERT INTO #finalReserveMaterialListResult([WorkOrderId], [WorkFlowWorkOrderId], [WorkOrderMaterialsId], [WOMStockLineId], [ItemMasterId],
									[AltPartMasterPartId], [EquPartMasterPartId], [ConditionId], [StocklineConditionId], [ConditionGroup], [MasterCompanyId], [Quantity], [QuantityReserved], [QuantityIssued], [QuantityOnOrder], 
									[QtyToBeReserved], [UnitCost], [ExtendedCost], [TaskId], [ProvisionId], [PartNumber], [PartDescription], [MainPartNumber],[MainPartDescription], [MainManufacturer], [MainCondition], [StocklineId],
									[Condition], [StockLineNumber], [ControlNo], [ControlId], [Manufacturer], [SerialNumber], [QuantityAvailable], [QuantityOnHand], [CreatedDate], [StocklineQuantityOnOrder], [StocklineQuantityTurnIn],
									[UnitOfMeasure], [Provision], [ProvisionStatusCode], [StockType], [MSQuantityRequsted], [MSQuantityReserved], [MSQuantityIssued], [StocklineUnitCost], [MSQunatityRemaining], [StocklineProvision], 
									[StocklineProvisionCode], [IsStocklineAdded], [IsAltPart], [IsEquPart], [TaskName])
						SELECT  DISTINCT WOM.WorkOrderId,
								WOM.WorkFlowWorkOrderId,
								WOM.WorkOrderMaterialsKitId,
								WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,
								WOM.ItemMasterId,
								0 AS AltPartMasterPartId,
								0 AS EquPartMasterPartId,
								WOM.ConditionCodeId AS ConditionId,
								SL.ConditionId AS StocklineConditionId,
								@ConditionGroup AS ConditionGroup,
								WOM.MasterCompanyId,
								ISNULL(WOM.Quantity, 0),
								ISNULL(WOM.QuantityReserved, 0),
								ISNULL(WOM.QuantityIssued, 0),
								ISNULL(WOM.QtyOnOrder, 0) AS QuantityOnOrder,
								(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
								ISNULL(WOM.UnitCost, 0),
								ISNULL(WOM.ExtendedCost, 0),
								WOM.TaskId,
								WOM.ProvisionId,
								IM.PartNumber,
								IM.PartDescription, 
								IM.PartNumber AS MainPartNumber,
								IM.PartDescription AS MainPartDescription, 
								IM.ManufacturerName MainManufacturer,
								--SL.Condition  AS MainCondition,
								C.[Description]  AS MainCondition,
								SL.StocklineId,
								SL.Condition,
								SL.StockLineNumber,
								SL.ControlNumber,
								SL.IdNumber,
								SL.Manufacturer,
								SL.SerialNumber,
								ISNULL(SL.QuantityAvailable, 0) AS QuantityAvailable,
								ISNULL(SL.QuantityOnHand, 0) AS QuantityOnHand,
								SL.CreatedDate,
								ISNULL(SL.QuantityOnOrder, 0) AS StocklineQuantityOnOrder,
								ISNULL(SL.QuantityTurnIn, 0) AS StocklineQuantityTurnIn,
								SL.UnitOfMeasure,
								P.Description AS Provision,
								P.StatusCode AS ProvisionStatusCode,
								CASE 
								WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
								WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
								WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
								ELSE 'OEM'
								END AS StockType,
								ISNULL(CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) END
								, 0)AS MSQuantityRequsted,
								ISNULL(WOMS.QtyReserved, 0) AS MSQuantityReserved,
								ISNULL(WOMS.QtyIssued, 0) AS MSQuantityIssued,
								ISNULL(CASE WHEN WOMS.WorkOrderMaterialStockLineKitId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END, 0) AS SLUnitCost,
								MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
								CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
								CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
								CASE WHEN WOMS.WorkOrderMaterialStockLineKitId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
								0 AS IsAltPart,
								0 AS IsEquPart
								,TS.[Description] AS 'TaskName' 
							FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK)  
								JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
								JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
								JOIN dbo.Stockline SL WITH (NOLOCK) ON WOM.ItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
								LEFT JOIN dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
								LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
								LEFT JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
								LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
								LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
								LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
							WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.ConditionCodeId <> @ARConditionId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
								--AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId) 
								AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								--AND (@KitId IS NULL OR WOMKM.KitId = @KitId)
								AND ( WOM.WorkOrderMaterialsKitId IN (SELECT WorkOrderMaterialsId FROM #TMPWOMaterialResultListData WHERE IsKit = 1)) --OR
									  --WOM.ItemMasterId IN (SELECT ItemMasterId FROM #TMPWOMaterialResultListData WHERE IsKit = 0 AND IsAltPart = 0 AND IsEquPart = 0))

						INSERT INTO #finalReserveMaterialListResult([WorkOrderId], [WorkFlowWorkOrderId], [WorkOrderMaterialsId], [WOMStockLineId], [ItemMasterId],
									[AltPartMasterPartId], [EquPartMasterPartId], [ConditionId], [StocklineConditionId], [ConditionGroup], [MasterCompanyId], [Quantity], [QuantityReserved], [QuantityIssued], [QuantityOnOrder], 
									[QtyToBeReserved], [UnitCost], [ExtendedCost], [TaskId], [ProvisionId], [PartNumber], [PartDescription], [MainPartNumber],[MainPartDescription], [MainManufacturer], [MainCondition], [StocklineId],
									[Condition], [StockLineNumber], [ControlNo], [ControlId], [Manufacturer], [SerialNumber], [QuantityAvailable], [QuantityOnHand], [CreatedDate], [StocklineQuantityOnOrder], [StocklineQuantityTurnIn],
									[UnitOfMeasure], [Provision], [ProvisionStatusCode], [StockType], [MSQuantityRequsted], [MSQuantityReserved], [MSQuantityIssued], [StocklineUnitCost], [MSQunatityRemaining], [StocklineProvision], 
									[StocklineProvisionCode], [IsStocklineAdded], [IsAltPart], [IsEquPart], [TaskName])
						SELECT  DISTINCT WOM.WorkOrderId,
								WOM.WorkFlowWorkOrderId,
								WOM.WorkOrderMaterialsKitId,
								WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,
								Alt.AltItemMasterId ItemMasterId,
								Alt.ItemMasterId AS AltPartMasterPartId,
								Alt.ItemMasterId AS EquPartMasterPartId,
								WOM.ConditionCodeId AS ConditionId,
								SL.ConditionId AS StocklineConditionId,
								@ConditionGroup AS ConditionGroup,
								WOM.MasterCompanyId,
								ISNULL(WOM.Quantity, 0),
								ISNULL(WOM.QuantityReserved, 0),
								ISNULL(WOM.QuantityIssued, 0),
								ISNULL(WOM.QtyOnOrder, 0) AS QuantityOnOrder,
								(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
								ISNULL(WOM.UnitCost, 0),
								ISNULL(WOM.ExtendedCost, 0),
								WOM.TaskId,
								WOM.ProvisionId,
								IM.PartNumber,
								IM.PartDescription, 
								IM_AltMain.PartNumber AS MainPartNumber,
								IM_AltMain.PartDescription AS MainPartDescription,
								IM_AltMain.ManufacturerName AS MainManufacturer,
								C.[Description]  AS MainCondition,
								SL.StocklineId,
								SL.Condition,
								SL.StockLineNumber,
								SL.ControlNumber,
								SL.IdNumber,
								SL.Manufacturer,
								SL.SerialNumber,
								ISNULL(SL.QuantityAvailable, 0) AS QuantityAvailable,
								ISNULL(SL.QuantityOnHand, 0) AS QuantityOnHand,
								SL.CreatedDate,
								ISNULL(SL.QuantityOnOrder, 0) AS StocklineQuantityOnOrder,
								ISNULL(SL.QuantityTurnIn, 0) AS StocklineQuantityTurnIn,
								SL.UnitOfMeasure,
								P.Description AS Provision,
								P.StatusCode AS ProvisionStatusCode,
								CASE 
								WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
								WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
								WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
								ELSE 'OEM'
								END AS StockType,
								ISNULL(CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) END
								, 0)AS MSQuantityRequsted,
								ISNULL(WOMS.QtyReserved, 0) AS MSQuantityReserved,
								ISNULL(WOMS.QtyIssued, 0) AS MSQuantityIssued,
								ISNULL(CASE WHEN WOMS.WorkOrderMaterialStockLineKitId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END, 0) AS SLUnitCost,
								MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
								CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
								CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
								CASE WHEN WOMS.WorkOrderMaterialStockLineKitId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
								1 AS IsAltPart,
								0 AS IsEquPart
								,TS.[Description] AS 'TaskName' 
							FROM #AltPartList Alt
								JOIN dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.ItemMasterId = Alt.ItemMasterId
								JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Alt.AltItemMasterId
								JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = Alt.ItemMasterId
								JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
								JOIN dbo.Stockline SL WITH (NOLOCK) ON Alt.AltItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
								LEFT JOIN dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
								LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
								LEFT JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
								LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
								LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
								LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
							WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
								--AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId)
								AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								--AND (@KitId IS NULL OR WOMKM.KitId = @KitId)
								AND ( WOM.WorkOrderMaterialsKitId IN (SELECT WorkOrderMaterialsId FROM #TMPWOMaterialResultListData WHERE IsKit = 1)) --OR
									  --WOM.ItemMasterId IN (SELECT ItemMasterId FROM #TMPWOMaterialResultListData WHERE IsKit = 0 AND IsAltPart = 1 AND IsEquPart = 0))

						INSERT INTO #finalReserveMaterialListResult([WorkOrderId], [WorkFlowWorkOrderId], [WorkOrderMaterialsId], [WOMStockLineId], [ItemMasterId],
									[AltPartMasterPartId], [EquPartMasterPartId], [ConditionId], [StocklineConditionId], [ConditionGroup], [MasterCompanyId], [Quantity], [QuantityReserved], [QuantityIssued], [QuantityOnOrder], 
									[QtyToBeReserved], [UnitCost], [ExtendedCost], [TaskId], [ProvisionId], [PartNumber], [PartDescription], [MainPartNumber],[MainPartDescription], [MainManufacturer], [MainCondition], [StocklineId],
									[Condition], [StockLineNumber], [ControlNo], [ControlId], [Manufacturer], [SerialNumber], [QuantityAvailable], [QuantityOnHand], [CreatedDate], [StocklineQuantityOnOrder], [StocklineQuantityTurnIn],
									[UnitOfMeasure], [Provision], [ProvisionStatusCode], [StockType], [MSQuantityRequsted], [MSQuantityReserved], [MSQuantityIssued], [StocklineUnitCost], [MSQunatityRemaining], [StocklineProvision], 
									[StocklineProvisionCode], [IsStocklineAdded], [IsAltPart], [IsEquPart], [TaskName])
						SELECT  DISTINCT WOM.WorkOrderId,
								WOM.WorkFlowWorkOrderId,
								WOM.WorkOrderMaterialsKitId,
								WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,
								Equ.EquItemMasterId ItemMasterId,
								Equ.ItemMasterId AS AltPartMasterPartId,
								Equ.ItemMasterId AS EquPartMasterPartId,
								WOM.ConditionCodeId AS ConditionId,
								SL.ConditionId AS StocklineConditionId,
								@ConditionGroup AS ConditionGroup,
								WOM.MasterCompanyId,
								ISNULL(WOM.Quantity, 0),
								ISNULL(WOM.QuantityReserved, 0),
								ISNULL(WOM.QuantityIssued, 0),
								ISNULL(WOM.QtyOnOrder, 0) AS QuantityOnOrder,
								(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
								ISNULL(WOM.UnitCost, 0),
								ISNULL(WOM.ExtendedCost, 0),
								WOM.TaskId,
								WOM.ProvisionId,
								IM.PartNumber,
								IM.PartDescription, 
								IM_EquMain.PartNumber AS MainPartNumber,
								IM_EquMain.PartDescription AS MainPartDescription,
								IM_EquMain.ManufacturerName AS MainManufacturer,
								SL.Condition  AS MainCondition,
								SL.StocklineId,
								SL.Condition,
								SL.StockLineNumber,
								SL.ControlNumber,
								SL.IdNumber,
								SL.Manufacturer,
								SL.SerialNumber,
								ISNULL(SL.QuantityAvailable, 0) AS QuantityAvailable,
								ISNULL(SL.QuantityOnHand, 0) AS QuantityOnHand,
								SL.CreatedDate,
								ISNULL(SL.QuantityOnOrder, 0) AS StocklineQuantityOnOrder,
								ISNULL(SL.QuantityTurnIn, 0) AS StocklineQuantityTurnIn,
								SL.UnitOfMeasure,
								P.Description AS Provision,
								P.StatusCode AS ProvisionStatusCode,
								CASE 
								WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
								WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
								WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
								ELSE 'OEM'
								END AS StockType,
								ISNULL(CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) END
								, 0)AS MSQuantityRequsted,
								ISNULL(WOMS.QtyReserved, 0) AS MSQuantityReserved,
								ISNULL(WOMS.QtyIssued, 0) AS MSQuantityIssued,
								ISNULL(CASE WHEN WOMS.WorkOrderMaterialStockLineKitId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END, 0) AS SLUnitCost,
								MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
								CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
								CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
								CASE WHEN WOMS.WorkOrderMaterialStockLineKitId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
								0 AS IsAltPart,
								1 AS IsEquPart
								,TS.[Description] AS 'TaskName' 
							FROM #EquPartList Equ
								JOIN dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.ItemMasterId = Equ.ItemMasterId
								JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Equ.EquItemMasterId
								JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = Equ.ItemMasterId
								JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
								JOIN dbo.Stockline SL WITH (NOLOCK) ON Equ.EquItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
								LEFT JOIN dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
								LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
								LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
								LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
								LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
							WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
								--AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_EquMain.ItemMasterId = @ItemMasterId) 
								AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								--AND (@KitId IS NULL OR WOMKM.KitId = @KitId)
								AND ( WOM.WorkOrderMaterialsKitId IN (SELECT WorkOrderMaterialsId FROM #TMPWOMaterialResultListData WHERE IsKit = 1)) --OR
									  --WOM.ItemMasterId IN (SELECT ItemMasterId FROM #TMPWOMaterialResultListData WHERE IsKit = 0 AND IsAltPart = 0 AND IsEquPart = 1))
					END
				END

				SELECT *, @Count AS NumberOfItems FROM #finalReserveMaterialListResult
				ORDER BY    
					CASE WHEN (@SortOrder=1 and @SortColumn='TaskName')  THEN TaskName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PartNumber')  THEN PartNumber END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='PartDescription')  THEN PartDescription END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='ConditionGroup')  THEN ConditionGroup END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='Quantity')  THEN Quantity END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='QuantityReserved')  THEN QuantityReserved END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='QuantityIssued')  THEN QuantityIssued END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='QuantityOnOrder')  THEN QuantityOnOrder END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='QtyToBeReserved')  THEN QtyToBeReserved END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='UnitCost')  THEN UnitCost END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='ExtendedCost')  THEN ExtendedCost END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='MainPartNumber')  THEN MainPartNumber END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='MainPartDescription')  THEN MainPartDescription END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='MainManufacturer')  THEN MainManufacturer END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='MainCondition')  THEN MainCondition END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='Condition')  THEN Condition END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='StockLineNumber')  THEN StockLineNumber END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='ControlNo')  THEN ControlNo END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='ControlId')  THEN ControlId END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='Manufacturer')  THEN Manufacturer END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='SerialNumber')  THEN SerialNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='QuantityAvailable')  THEN QuantityAvailable END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='QuantityOnHand')  THEN QuantityOnHand END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='CreatedDate')  THEN CreatedDate END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='StocklineQuantityOnOrder')  THEN StocklineQuantityOnOrder END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='StocklineQuantityTurnIn')  THEN StocklineQuantityTurnIn END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='Provision')  THEN Provision END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='ProvisionStatusCode')  THEN ProvisionStatusCode END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='StockType')  THEN StockType END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='MSQuantityRequsted')  THEN MSQuantityRequsted END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='MSQuantityReserved')  THEN MSQuantityReserved END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='MSQuantityIssued')  THEN MSQuantityIssued END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='StocklineUnitCost')  THEN StocklineUnitCost END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='MSQunatityRemaining')  THEN MSQunatityRemaining END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='StocklineProvision')  THEN StocklineProvision END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='StocklineProvisionCode')  THEN StocklineProvisionCode END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='IsStocklineAdded')  THEN IsStocklineAdded END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='IsAltPart')  THEN IsAltPart END ASC,  
					CASE WHEN (@SortOrder=1 and @SortColumn='IsEquPart')  THEN IsEquPart END ASC,  

					CASE WHEN (@SortOrder=-1 and @SortColumn='TaskName')  THEN TaskName END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PartNumber')  THEN PartNumber END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='PartDescription')  THEN PartDescription END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='ConditionGroup')  THEN ConditionGroup END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='Quantity')  THEN Quantity END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='QuantityReserved')  THEN QuantityReserved END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='QuantityIssued')  THEN QuantityIssued END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='QuantityOnOrder')  THEN QuantityOnOrder END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='QtyToBeReserved')  THEN QtyToBeReserved END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='UnitCost')  THEN UnitCost END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='ExtendedCost')  THEN ExtendedCost END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='MainPartNumber')  THEN MainPartNumber END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='MainPartDescription')  THEN MainPartDescription END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='MainManufacturer')  THEN MainManufacturer END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='MainCondition')  THEN MainCondition END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='Condition')  THEN Condition END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='StockLineNumber')  THEN StockLineNumber END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='ControlNo')  THEN ControlNo END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='ControlId')  THEN ControlId END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='Manufacturer')  THEN Manufacturer END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='SerialNumber')  THEN SerialNumber END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='QuantityAvailable')  THEN QuantityAvailable END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='QuantityOnHand')  THEN QuantityOnHand END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedDate')  THEN CreatedDate END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='StocklineQuantityOnOrder')  THEN StocklineQuantityOnOrder END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='StocklineQuantityTurnIn')  THEN StocklineQuantityTurnIn END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='Provision')  THEN Provision END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='ProvisionStatusCode')  THEN ProvisionStatusCode END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='StockType')  THEN StockType END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='MSQuantityRequsted')  THEN MSQuantityRequsted END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='MSQuantityReserved')  THEN MSQuantityReserved END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='MSQuantityIssued')  THEN MSQuantityIssued END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='StocklineUnitCost')  THEN StocklineUnitCost END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='MSQunatityRemaining')  THEN MSQunatityRemaining END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='StocklineProvision')  THEN StocklineProvision END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='StocklineProvisionCode')  THEN StocklineProvisionCode END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='IsStocklineAdded')  THEN IsStocklineAdded END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='IsAltPart')  THEN IsAltPart END DESC,  
					CASE WHEN (@SortOrder=-1 and @SortColumn='IsEquPart')  THEN IsEquPart END DESC;
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWOMStocklineListForReserve' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkFlowWorkOrderId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW---------------------------------------------------------------------
              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END
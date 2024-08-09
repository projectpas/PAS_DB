/*************************************************************           
 ** File:   [USP_GetSubWOMaterialStocklineListForManualReserve]           
 ** Author:  Devendra Shekh
 ** Description: This SP is Used to get Stockline list to reserve Stockline with Pagination
 ** Purpose:         
 ** Date:   08/09/2024		[mm/dd/yyyy]
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			  Author					Change Description            
 ** --   --------		 -------					--------------------------------          
    1    08/09/2024		 Devendra Shekh				Created
     

exec dbo.USP_GetSubWOMaterialStocklineListForManualReserve @PageNumber=1,@PageSize=20,@SortColumn=default,@SortOrder=1,@SubWOPartNoId=335,@ItemMasterId=0,@SubWorkOrderMaterialsId=0,@KitId=3399,@IncludeCustomerStock=0
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetSubWOMaterialStocklineListForManualReserve]
(    
	@PageNumber int,  
	@PageSize int,  
	@SortColumn varchar(50)=null,  
	@SortOrder int,  
	@SubWOPartNoId BIGINT = NULL,
	@ItemMasterId BIGINT = NULL,
	@SubWorkOrderMaterialsId BIGINT = NULL,
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

				IF OBJECT_ID(N'tempdb..#TMPSubWOReserveMaterialParentListData') IS NOT NULL
				BEGIN
					DROP TABLE #TMPSubWOReserveMaterialParentListData
				END

				IF OBJECT_ID(N'tempdb..#TMPSubWOMaterialResultListData') IS NOT NULL
				BEGIN
					DROP TABLE #TMPSubWOMaterialResultListData
				END

				CREATE TABLE #finalReserveMaterialListResult
				(
		 			[RecordID] [bigint] NOT NULL IDENTITY, 	
					[WorkOrderId] [bigint] NULL,
					[SubWorkOrderId] [bigint] NULL,
					[SubWOPartNoId] [bigint] NULL,
					[SubWorkOrderMaterialsId] [bigint] NULL,
					[SWOMStockLineId] [bigint] NULL,
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

				CREATE TABLE #TMPSubWOReserveMaterialParentListData
				 (
		 			[ParentID] BIGINT NOT NULL IDENTITY, 						 
		 			[SubWorkOrderMaterialsId] [bigint] NULL,
		 			[SubWorkOrderMaterialsKitMappingId] [bigint] NULL,
		 			[SubWOPartNoId] [bigint] NULL,
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
				
				SELECT DISTINCT TOP 1 @CustomerID = WO.CustomerId, @MasterCompanyId = SWO.MasterCompanyId 
				FROM dbo.WorkOrder WO WITH(NOLOCK) JOIN dbo.SubWorkOrder SWO WITH(NOLOCK) on WO.WorkOrderId = SWO.WorkOrderId 
					JOIN dbo.SubWorkOrderPartNumber SWOPN WITH(NOLOCK) on SWOPN.SubWorkOrderId = SWO.SubWorkOrderId WHERE SWOPN.SubWOPartNoId = @subWOPartNoId;

				SELECT @ARConditionId = ConditionId FROM dbo.Condition WITH(NOLOCK) WHERE Code = 'ASREMOVE' AND MasterCompanyId = @MasterCompanyId;

				IF(@ItemMasterId = 0)
				BEGIN
					SET @ItemMasterId = NULL;
				END

				IF(@SubWorkOrderMaterialsId = 0)
				BEGIN
					SET @SubWorkOrderMaterialsId = NULL;
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
					[SubWorkOrderMaterialsId] [BIGINT] NULL,
					[ConditionGroup] VARCHAR(50) NULL,
				)

				--Inserting Data For #AltPartList / #EquPartList : Start
				IF(ISNULL(@KitId, 0) = 0)
				BEGIN
						IF(ISNULL(@SubWorkOrderMaterialsId, 0) > 0)
						BEGIN
							SELECT @ConditionGroup = C.GroupCode FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK) JOIN dbo.Condition C ON C.ConditionId = WOM.ConditionCodeId WHERE WOM.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId AND C.MasterCompanyId = @MasterCompanyId
					
							INSERT INTO #ConditionGroup (ConditionId, SubWorkOrderMaterialsId, ConditionGroup)
							SELECT DISTINCT ConditionId, WOM.SubWorkOrderMaterialsId, C.GroupCode 
							FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK) JOIN dbo.Condition C ON C.ConditionId = WOM.ConditionCodeId 
							WHERE WOM.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId AND C.MasterCompanyId = @MasterCompanyId AND WOM.ConditionCodeId <> @ARConditionId

							INSERT INTO #ConditionGroup (ConditionId, SubWorkOrderMaterialsId, ConditionGroup)
							SELECT DISTINCT C.ConditionId, CG.SubWorkOrderMaterialsId, CG.ConditionGroup FROM dbo.Condition C JOIN #ConditionGroup CG ON C.GroupCode = CG.ConditionGroup 
							WHERE C.ConditionId != CG.ConditionId AND C.MasterCompanyId = @MasterCompanyId

						END
						BEGIN
							INSERT INTO #ConditionGroup (ConditionId, SubWorkOrderMaterialsId, ConditionGroup)
							SELECT DISTINCT ConditionId, WOM.SubWorkOrderMaterialsId, C.GroupCode 
							FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK) JOIN dbo.Condition C ON C.ConditionId = WOM.ConditionCodeId 
							WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND C.MasterCompanyId = @MasterCompanyId AND WOM.ConditionCodeId <> @ARConditionId

							INSERT INTO #ConditionGroup (ConditionId, SubWorkOrderMaterialsId, ConditionGroup)
							SELECT DISTINCT C.ConditionId, CG.SubWorkOrderMaterialsId, CG.ConditionGroup FROM dbo.Condition C JOIN #ConditionGroup CG ON C.GroupCode = CG.ConditionGroup 
							WHERE C.ConditionId != CG.ConditionId AND C.MasterCompanyId = @MasterCompanyId
						END

						INSERT INTO #AltPartList
						([ItemMasterId], [AltItemMasterId])
						SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
						FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK)  
							LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 1 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
							LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
						WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND WOM.ConditionCodeId <> @ARConditionId

						INSERT INTO #EquPartList
						([ItemMasterId], [EquItemMasterId])
						SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
						FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK)  
							LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 2 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
							LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
						WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND WOM.ConditionCodeId <> @ARConditionId

						--Inserting Data For Parent Level
						INSERT INTO #TMPSubWOReserveMaterialParentListData
						([SubWorkOrderMaterialsId], [SubWOPartNoId], [SubWorkOrderMaterialsKitMappingId], [ItemMasterId], [IsKit], [IsAltPart], [IsEquPart])
						SELECT DISTINCT	[SubWorkOrderMaterialsId], SubWOPartNoId, 0, WOM.ItemMasterId, 0, 0, 0 FROM [DBO].SubWorkOrderMaterials WOM WITH(NOLOCK) 
						WHERE	WOM.SubWOPartNoId = @SubWOPartNoId AND WOM.IsDeleted = 0
								AND (@ItemMasterId IS NULL OR WOM.ItemMasterId = @ItemMasterId)
								AND (@SubWorkOrderMaterialsId IS NULL OR WOM.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId);

						INSERT INTO #TMPSubWOReserveMaterialParentListData
						([SubWorkOrderMaterialsId], [SubWOPartNoId], [SubWorkOrderMaterialsKitMappingId], [ItemMasterId], [IsKit], [IsAltPart], [IsEquPart])
						SELECT DISTINCT	WOM.[SubWorkOrderMaterialsId], WOM.SubWOPartNoId, 0, ALT.ItemMasterId, 0, 1, 0 
						FROM dbo.SubWorkOrderMaterials WOM WITH(NOLOCK)
						JOIN #AltPartList ALT WITH (NOLOCK) ON WOM.ItemMasterId = Alt.ItemMasterId
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Alt.AltItemMasterId
						WHERE	WOM.SubWOPartNoId = @SubWOPartNoId
								AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR ALT.ItemMasterId = @ItemMasterId)
								AND (@SubWorkOrderMaterialsId IS NULL OR WOM.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId)
								AND WOM.SubWorkOrderMaterialsId NOT IN (SELECT [SubWorkOrderMaterialsId] FROM #TMPSubWOReserveMaterialParentListData WHERE IsKit = 0);

						INSERT INTO #TMPSubWOReserveMaterialParentListData
						([SubWorkOrderMaterialsId], [SubWOPartNoId], [SubWorkOrderMaterialsKitMappingId], [ItemMasterId], [IsKit], [IsAltPart], [IsEquPart])
						SELECT DISTINCT	WOM.[SubWorkOrderMaterialsId], WOM.SubWOPartNoId, 0, EQU.ItemMasterId, 0, 1, 0 
						FROM dbo.SubWorkOrderMaterials WOM WITH(NOLOCK)
						JOIN #EquPartList EQU WITH (NOLOCK) ON WOM.ItemMasterId = EQU.ItemMasterId
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = EQU.EquItemMasterId
						WHERE	WOM.SubWOPartNoId = @SubWOPartNoId
								AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR EQU.ItemMasterId = @ItemMasterId)
								AND (@SubWorkOrderMaterialsId IS NULL OR WOM.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId)
								AND WOM.SubWorkOrderMaterialsId NOT IN (SELECT [SubWorkOrderMaterialsId] FROM #TMPSubWOReserveMaterialParentListData WHERE IsKit = 0);
				END
				ELSE
				BEGIN
						INSERT INTO #ConditionGroup (ConditionId, SubWorkOrderMaterialsId, ConditionGroup)
						SELECT DISTINCT ConditionId, WOM.SubWorkOrderMaterialsKitId, C.GroupCode FROM dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK) 
						JOIN dbo.SubWorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.SubWorkOrderMaterialsKitMappingId = WOM.SubWorkOrderMaterialsKitMappingId
						JOIN dbo.Condition C ON C.ConditionId = WOM.ConditionCodeId WHERE WOMKM.KitId = @KitId AND WOM.SubWOPartNoId = @SubWOPartNoId AND C.MasterCompanyId = @MasterCompanyId AND WOM.ConditionCodeId <> @ARConditionId

						INSERT INTO #ConditionGroup (ConditionId, SubWorkOrderMaterialsId, ConditionGroup)
						SELECT DISTINCT C.ConditionId, CG.SubWorkOrderMaterialsId, CG.ConditionGroup FROM dbo.Condition C JOIN #ConditionGroup CG ON C.GroupCode = CG.ConditionGroup 
						WHERE C.ConditionId != CG.ConditionId AND C.MasterCompanyId = @MasterCompanyId

						INSERT INTO #AltPartList
						([ItemMasterId], [AltItemMasterId])
						SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
						FROM dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK)  
							LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 1 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
							LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
							JOIN dbo.SubWorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.SubWorkOrderMaterialsKitMappingId = WOM.SubWorkOrderMaterialsKitMappingId
						WHERE (@KitId IS NULL OR WOMKM.KitId = @KitId) AND WOM.SubWOPartNoId = @SubWOPartNoId AND WOM.ConditionCodeId <> @ARConditionId

						INSERT INTO #EquPartList
						([ItemMasterId], [EquItemMasterId])
						SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
						FROM dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK)  
							LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND NhaTla.MappingType = 2 AND NhaTla.IsActive = 1 AND NhaTla.IsDeleted = 0
							LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
							JOIN dbo.SubWorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.SubWorkOrderMaterialsKitMappingId = WOM.SubWorkOrderMaterialsKitMappingId
						WHERE (@KitId IS NULL OR WOMKM.KitId = @KitId) AND WOM.SubWOPartNoId = @SubWOPartNoId AND WOM.ConditionCodeId <> @ARConditionId

						--Inserting Data For Parent Level
						INSERT INTO #TMPSubWOReserveMaterialParentListData
						([SubWorkOrderMaterialsId], [SubWOPartNoId], [SubWorkOrderMaterialsKitMappingId], [ItemMasterId], [IsKit], [IsAltPart], [IsEquPart])
						SELECT DISTINCT	WOM.SubWorkOrderMaterialsKitId, WOM.[SubWOPartNoId], WOM.[SubWorkOrderMaterialsKitMappingId], WOM.ItemMasterId, 1, 0, 0 FROM [DBO].SubWorkOrderMaterialsKit WOM WITH(NOLOCK)
						JOIN [dbo].[SubWorkOrderMaterialsKitMapping] WOMKITMP WITH(NOLOCK) ON WOM.SubWorkOrderMaterialsKitMappingId = WOMKITMP.SubWorkOrderMaterialsKitMappingId
						JOIN dbo.Stockline SL WITH (NOLOCK) ON WOM.ItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.SubWorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
						WHERE	WOM.IsDeleted = 0 AND WOM.SubWOPartNoId = @SubWOPartNoId
								AND (@KitId IS NULL OR WOMKITMP.KitId = @KitId)
								AND (@ItemMasterId IS NULL OR WOM.ItemMasterId = @ItemMasterId) AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								AND WOM.ConditionCodeId <> @ARConditionId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0;

						INSERT INTO #TMPSubWOReserveMaterialParentListData
						([SubWorkOrderMaterialsId], [SubWOPartNoId], [SubWorkOrderMaterialsKitMappingId], [ItemMasterId], [IsKit], [IsAltPart], [IsEquPart])
						SELECT DISTINCT	WOM.SubWorkOrderMaterialsKitId, WOM.SubWOPartNoId, 0, ALT.ItemMasterId, 1, 1, 0 
						FROM dbo.SubWorkOrderMaterialsKitMapping WOMKM WITH(NOLOCK)
						JOIN dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOMKM.SubWorkOrderMaterialsKitMappingId = WOM.SubWorkOrderMaterialsKitMappingId
						JOIN #AltPartList ALT WITH (NOLOCK) ON WOM.ItemMasterId = Alt.ItemMasterId
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Alt.AltItemMasterId
						JOIN dbo.Stockline SL WITH (NOLOCK) ON Alt.AltItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.SubWorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
						WHERE	(@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR ALT.ItemMasterId = @ItemMasterId)  AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND WOM.SubWOPartNoId = @SubWOPartNoId AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								AND (@KitId IS NULL OR WOMKM.KitId = @KitId)
								AND WOM.SubWorkOrderMaterialsKitId NOT IN (SELECT [SubWorkOrderMaterialsId] FROM #TMPSubWOReserveMaterialParentListData WHERE IsKit = 1)
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0;

						INSERT INTO #TMPSubWOReserveMaterialParentListData
						([SubWorkOrderMaterialsId], [SubWOPartNoId], [SubWorkOrderMaterialsKitMappingId], [ItemMasterId], [IsKit], [IsAltPart], [IsEquPart])
						SELECT DISTINCT	WOM.SubWorkOrderMaterialsKitId, WOM.SubWOPartNoId, 0, EQU.ItemMasterId, 1, 1, 0 
						FROM dbo.SubWorkOrderMaterialsKitMapping WOMKM WITH(NOLOCK)
						JOIN dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOMKM.SubWorkOrderMaterialsKitMappingId = WOM.SubWorkOrderMaterialsKitMappingId
						JOIN #EquPartList EQU WITH (NOLOCK) ON WOM.ItemMasterId = EQU.ItemMasterId
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = EQU.EquItemMasterId
						JOIN dbo.Stockline SL WITH (NOLOCK) ON Equ.EquItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.SubWorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
						WHERE	(@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR EQU.ItemMasterId = @ItemMasterId)
								AND WOM.SubWOPartNoId = @SubWOPartNoId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND (@KitId IS NULL OR WOMKM.KitId = @KitId) AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								AND WOM.SubWorkOrderMaterialsKitId NOT IN (SELECT [SubWorkOrderMaterialsId] FROM #TMPSubWOReserveMaterialParentListData WHERE IsKit = 1)
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0;
				END
				--Inserting Data For #AltPartList / #EquPartList : End

				SELECT * INTO #TMPSubWOMaterialResultListData FROM #TMPSubWOReserveMaterialParentListData tmp 
				ORDER BY tmp.SubWOPartNoId ASC
				OFFSET @RecordFrom ROWS   
				FETCH NEXT @PageSize ROWS ONLY

				SELECT @Count = COUNT(ParentID) from #TMPSubWOReserveMaterialParentListData;

				IF(@Count > 0)
				BEGIN
					IF(ISNULL(@KitId, 0) = 0)
					BEGIN			

						INSERT INTO #finalReserveMaterialListResult([WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsId], [SWOMStockLineId], [ItemMasterId],
										[AltPartMasterPartId], [EquPartMasterPartId], [ConditionId], [StocklineConditionId], [ConditionGroup], [MasterCompanyId], [Quantity], [QuantityReserved], [QuantityIssued], [QuantityOnOrder], 
										[QtyToBeReserved], [UnitCost], [ExtendedCost], [TaskId], [ProvisionId], [PartNumber], [PartDescription], [MainPartNumber],[MainPartDescription], [MainManufacturer], [MainCondition], [StocklineId],
										[Condition], [StockLineNumber], [ControlNo], [ControlId], [Manufacturer], [SerialNumber], [QuantityAvailable], [QuantityOnHand], [CreatedDate], [StocklineQuantityOnOrder], [StocklineQuantityTurnIn],
										[UnitOfMeasure], [Provision], [ProvisionStatusCode], [StockType], [MSQuantityRequsted], [MSQuantityReserved], [MSQuantityIssued], [StocklineUnitCost], [MSQunatityRemaining], [StocklineProvision], 
										[StocklineProvisionCode], [IsStocklineAdded], [IsAltPart], [IsEquPart], [TaskName])
						SELECT  WOM.WorkOrderId,
								WOM.SubWorkOrderId,
								WOM.SubWOPartNoId,
								WOM.SubWorkOrderMaterialsId,		
								WOMS.SWOMStockLineId,
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
								(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
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
								ISNULL(CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) END
								, 0)AS MSQuantityRequsted,
								ISNULL(WOMS.QtyReserved, 0) AS MSQuantityReserved,
								ISNULL(WOMS.QtyIssued, 0) AS MSQuantityIssued,
								ISNULL(CASE WHEN WOMS.SWOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END, 0) AS SLUnitCost,
								MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
								CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
								CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
								CASE WHEN WOMS.SWOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
								0 AS IsAltPart,
								0 AS IsEquPart
								,TS.[Description] AS 'TaskName' 
							FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK)  
								JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
								JOIN dbo.Stockline SL WITH (NOLOCK) ON WOM.ItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
								LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId --(SELECT ConditionId FROM #ConditionGroup WHERE SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId)
								LEFT JOIN dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
								LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
								LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
								LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
								LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
							WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND WOM.ConditionCodeId <> @ARConditionId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  							
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
								--AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId)
								AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								--AND (@SubWorkOrderMaterialsId IS NULL OR WOM.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId)
								AND	(WOM.SubWorkOrderMaterialsId IN (SELECT SubWorkOrderMaterialsId FROM #TMPSubWOMaterialResultListData WHERE IsKit = 0));

						INSERT INTO #finalReserveMaterialListResult([WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsId], [SWOMStockLineId], [ItemMasterId],
										[AltPartMasterPartId], [EquPartMasterPartId], [ConditionId], [StocklineConditionId], [ConditionGroup], [MasterCompanyId], [Quantity], [QuantityReserved], [QuantityIssued], [QuantityOnOrder], 
										[QtyToBeReserved], [UnitCost], [ExtendedCost], [TaskId], [ProvisionId], [PartNumber], [PartDescription], [MainPartNumber],[MainPartDescription], [MainManufacturer], [MainCondition], [StocklineId],
										[Condition], [StockLineNumber], [ControlNo], [ControlId], [Manufacturer], [SerialNumber], [QuantityAvailable], [QuantityOnHand], [CreatedDate], [StocklineQuantityOnOrder], [StocklineQuantityTurnIn],
										[UnitOfMeasure], [Provision], [ProvisionStatusCode], [StockType], [MSQuantityRequsted], [MSQuantityReserved], [MSQuantityIssued], [StocklineUnitCost], [MSQunatityRemaining], [StocklineProvision], 
										[StocklineProvisionCode], [IsStocklineAdded], [IsAltPart], [IsEquPart], [TaskName])
						SELECT  WOM.WorkOrderId,
								WOM.SubWorkOrderId,
								WOM.SubWOPartNoId,
								WOM.SubWorkOrderMaterialsId,		
								WOMS.SWOMStockLineId,
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
								(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
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
								ISNULL(CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) END
								, 0)AS MSQuantityRequsted,
								ISNULL(WOMS.QtyReserved, 0) AS MSQuantityReserved,
								ISNULL(WOMS.QtyIssued, 0) AS MSQuantityIssued,
								ISNULL(CASE WHEN WOMS.SWOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END, 0) AS SLUnitCost,
								MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
								CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
								CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
								CASE WHEN WOMS.SWOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
								1 AS IsAltPart,
								0 AS IsEquPart
								,TS.[Description] AS 'TaskName' 
							FROM #AltPartList Alt
								JOIN dbo.SubWorkOrderMaterials WOM WITH (NOLOCK) ON WOM.ItemMasterId = Alt.ItemMasterId
								JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Alt.AltItemMasterId
								JOIN dbo.Stockline SL WITH (NOLOCK) ON Alt.AltItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
								LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
								LEFT JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = Alt.ItemMasterId
								LEFT JOIN dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
								LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
								LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
								LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
								LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
							WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								--AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
								--AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId)
								AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								--AND (@SubWorkOrderMaterialsId IS NULL OR WOM.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId)
								AND	(WOM.SubWorkOrderMaterialsId IN (SELECT SubWorkOrderMaterialsId FROM #TMPSubWOMaterialResultListData WHERE IsKit = 0));

						INSERT INTO #finalReserveMaterialListResult([WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsId], [SWOMStockLineId], [ItemMasterId],
										[AltPartMasterPartId], [EquPartMasterPartId], [ConditionId], [StocklineConditionId], [ConditionGroup], [MasterCompanyId], [Quantity], [QuantityReserved], [QuantityIssued], [QuantityOnOrder], 
										[QtyToBeReserved], [UnitCost], [ExtendedCost], [TaskId], [ProvisionId], [PartNumber], [PartDescription], [MainPartNumber],[MainPartDescription], [MainManufacturer], [MainCondition], [StocklineId],
										[Condition], [StockLineNumber], [ControlNo], [ControlId], [Manufacturer], [SerialNumber], [QuantityAvailable], [QuantityOnHand], [CreatedDate], [StocklineQuantityOnOrder], [StocklineQuantityTurnIn],
										[UnitOfMeasure], [Provision], [ProvisionStatusCode], [StockType], [MSQuantityRequsted], [MSQuantityReserved], [MSQuantityIssued], [StocklineUnitCost], [MSQunatityRemaining], [StocklineProvision], 
										[StocklineProvisionCode], [IsStocklineAdded], [IsAltPart], [IsEquPart], [TaskName])
						SELECT  WOM.WorkOrderId,
								WOM.SubWorkOrderId,
								WOM.SubWOPartNoId,
								WOM.SubWorkOrderMaterialsId,		
								WOMS.SWOMStockLineId,	
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
								(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
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
								ISNULL(CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) END
								, 0)AS MSQuantityRequsted,
								ISNULL(WOMS.QtyReserved, 0) AS MSQuantityReserved,
								ISNULL(WOMS.QtyIssued, 0) AS MSQuantityIssued,
								ISNULL(CASE WHEN WOMS.SWOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END, 0) AS SLUnitCost,
								MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
								CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
								CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
								CASE WHEN WOMS.SWOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
								0 AS IsAltPart,
								1 AS IsEquPart
								,TS.[Description] AS 'TaskName' 
							FROM #EquPartList Equ
								JOIN dbo.SubWorkOrderMaterials WOM WITH (NOLOCK) ON WOM.ItemMasterId = Equ.ItemMasterId
								JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Equ.EquItemMasterId
								JOIN dbo.Stockline SL WITH (NOLOCK) ON Equ.EquItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
								LEFT JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = Equ.ItemMasterId
								LEFT JOIN dbo.Condition C WITH (NOLOCK) ON WOM.ConditionCodeId = C.ConditionId
								LEFT JOIN dbo.SubWorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
								LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
								LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
								LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
								LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
							WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsId = WOMSL.SubWorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
								--AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_EquMain.ItemMasterId = @ItemMasterId)
								AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								--AND (@SubWorkOrderMaterialsId IS NULL OR WOM.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId)
								AND	(WOM.SubWorkOrderMaterialsId IN (SELECT SubWorkOrderMaterialsId FROM #TMPSubWOMaterialResultListData WHERE IsKit = 0));
					END
					ELSE
					BEGIN			
						INSERT INTO #finalReserveMaterialListResult([WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsId], [SWOMStockLineId], [ItemMasterId],
										[AltPartMasterPartId], [EquPartMasterPartId], [ConditionId], [StocklineConditionId], [ConditionGroup], [MasterCompanyId], [Quantity], [QuantityReserved], [QuantityIssued], [QuantityOnOrder], 
										[QtyToBeReserved], [UnitCost], [ExtendedCost], [TaskId], [ProvisionId], [PartNumber], [PartDescription], [MainPartNumber],[MainPartDescription], [MainManufacturer], [MainCondition], [StocklineId],
										[Condition], [StockLineNumber], [ControlNo], [ControlId], [Manufacturer], [SerialNumber], [QuantityAvailable], [QuantityOnHand], [CreatedDate], [StocklineQuantityOnOrder], [StocklineQuantityTurnIn],
										[UnitOfMeasure], [Provision], [ProvisionStatusCode], [StockType], [MSQuantityRequsted], [MSQuantityReserved], [MSQuantityIssued], [StocklineUnitCost], [MSQunatityRemaining], [StocklineProvision], 
										[StocklineProvisionCode], [IsStocklineAdded], [IsAltPart], [IsEquPart], [TaskName])
						SELECT  DISTINCT WOM.WorkOrderId,
								WOM.SubWorkOrderId,
								WOM.SubWOPartNoId,
								WOM.SubWorkOrderMaterialsKitId,
								WOM.SubWorkOrderMaterialsKitId AS SubWorkOrderMaterialsId,
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
								(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
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
								ISNULL(CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) END
								, 0) AS MSQuantityRequsted,
								ISNULL(WOMS.QtyReserved, 0) AS MSQuantityReserved,
								ISNULL(WOMS.QtyIssued, 0) AS MSQuantityIssued,
								ISNULL(CASE WHEN WOMS.SWOMStockLineKitId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END, 0) AS SLUnitCost,
								MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
								CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
								CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
								CASE WHEN WOMS.SWOMStockLineKitId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
								0 AS IsAltPart,
								0 AS IsEquPart
								,TS.[Description] AS 'TaskName' 
							FROM dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK)  
								JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
								JOIN dbo.SubWorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.SubWorkOrderMaterialsKitMappingId = WOM.SubWorkOrderMaterialsKitMappingId
								JOIN dbo.Stockline SL WITH (NOLOCK) ON WOM.ItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup WHERE SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.SubWorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
								LEFT JOIN dbo.SubWorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
								LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
								LEFT JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
								LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
								LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
								LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
							WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND WOM.ConditionCodeId <> @ARConditionId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
								--AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId) 
								AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								--AND (@KitId IS NULL OR WOMKM.KitId = @KitId)
								AND	(WOM.SubWorkOrderMaterialsKitId IN (SELECT SubWorkOrderMaterialsId FROM #TMPSubWOMaterialResultListData WHERE IsKit = 1));

						INSERT INTO #finalReserveMaterialListResult([WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsId], [SWOMStockLineId], [ItemMasterId],
										[AltPartMasterPartId], [EquPartMasterPartId], [ConditionId], [StocklineConditionId], [ConditionGroup], [MasterCompanyId], [Quantity], [QuantityReserved], [QuantityIssued], [QuantityOnOrder], 
										[QtyToBeReserved], [UnitCost], [ExtendedCost], [TaskId], [ProvisionId], [PartNumber], [PartDescription], [MainPartNumber],[MainPartDescription], [MainManufacturer], [MainCondition], [StocklineId],
										[Condition], [StockLineNumber], [ControlNo], [ControlId], [Manufacturer], [SerialNumber], [QuantityAvailable], [QuantityOnHand], [CreatedDate], [StocklineQuantityOnOrder], [StocklineQuantityTurnIn],
										[UnitOfMeasure], [Provision], [ProvisionStatusCode], [StockType], [MSQuantityRequsted], [MSQuantityReserved], [MSQuantityIssued], [StocklineUnitCost], [MSQunatityRemaining], [StocklineProvision], 
										[StocklineProvisionCode], [IsStocklineAdded], [IsAltPart], [IsEquPart], [TaskName])
						SELECT  DISTINCT WOM.WorkOrderId,
								WOM.SubWorkOrderId,
								WOM.SubWOPartNoId,
								WOM.SubWorkOrderMaterialsKitId,
								WOM.SubWorkOrderMaterialsKitId AS SubWorkOrderMaterialsId,
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
								(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
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
								ISNULL(CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) END
								, 0) AS MSQuantityRequsted,
								ISNULL(WOMS.QtyReserved, 0) AS MSQuantityReserved,
								ISNULL(WOMS.QtyIssued, 0) AS MSQuantityIssued,
								ISNULL(CASE WHEN WOMS.SWOMStockLineKitId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END, 0) AS SLUnitCost,
								MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
								CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
								CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
								CASE WHEN WOMS.SWOMStockLineKitId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
								1 AS IsAltPart,
								0 AS IsEquPart
								,TS.[Description] AS 'TaskName' 
							FROM #AltPartList Alt
								JOIN dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.ItemMasterId = Alt.ItemMasterId
								JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Alt.AltItemMasterId
								JOIN dbo.ItemMaster IM_AltMain WITH (NOLOCK) ON IM_AltMain.ItemMasterId = Alt.ItemMasterId
								JOIN dbo.SubWorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.SubWorkOrderMaterialsKitMappingId = WOM.SubWorkOrderMaterialsKitMappingId
								JOIN dbo.Stockline SL WITH (NOLOCK) ON Alt.AltItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.SubWorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
								LEFT JOIN dbo.SubWorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
								LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
								LEFT JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
								LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
								LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
								LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
							WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
								--AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_AltMain.ItemMasterId = @ItemMasterId) 
								AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								--AND (@KitId IS NULL OR WOMKM.KitId = @KitId)
								AND	(WOM.SubWorkOrderMaterialsKitId IN (SELECT SubWorkOrderMaterialsId FROM #TMPSubWOMaterialResultListData WHERE IsKit = 1));

						INSERT INTO #finalReserveMaterialListResult([WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsId], [SWOMStockLineId], [ItemMasterId],
										[AltPartMasterPartId], [EquPartMasterPartId], [ConditionId], [StocklineConditionId], [ConditionGroup], [MasterCompanyId], [Quantity], [QuantityReserved], [QuantityIssued], [QuantityOnOrder], 
										[QtyToBeReserved], [UnitCost], [ExtendedCost], [TaskId], [ProvisionId], [PartNumber], [PartDescription], [MainPartNumber],[MainPartDescription], [MainManufacturer], [MainCondition], [StocklineId],
										[Condition], [StockLineNumber], [ControlNo], [ControlId], [Manufacturer], [SerialNumber], [QuantityAvailable], [QuantityOnHand], [CreatedDate], [StocklineQuantityOnOrder], [StocklineQuantityTurnIn],
										[UnitOfMeasure], [Provision], [ProvisionStatusCode], [StockType], [MSQuantityRequsted], [MSQuantityReserved], [MSQuantityIssued], [StocklineUnitCost], [MSQunatityRemaining], [StocklineProvision], 
										[StocklineProvisionCode], [IsStocklineAdded], [IsAltPart], [IsEquPart], [TaskName])
						SELECT  DISTINCT WOM.WorkOrderId,
								WOM.SubWorkOrderId,
								WOM.SubWOPartNoId,
								WOM.SubWorkOrderMaterialsKitId,
								WOM.SubWorkOrderMaterialsKitId AS SubWorkOrderMaterialsId,
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
								(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
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
								ISNULL(CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId) END
								, 0) AS MSQuantityRequsted,
								ISNULL(WOMS.QtyReserved, 0) AS MSQuantityReserved,
								ISNULL(WOMS.QtyIssued, 0) AS MSQuantityIssued,
								ISNULL(CASE WHEN WOMS.SWOMStockLineKitId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END, 0) AS SLUnitCost,
								MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
								CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
								CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
								CASE WHEN WOMS.SWOMStockLineKitId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded,
								0 AS IsAltPart,
								1 AS IsEquPart
								,TS.[Description] AS 'TaskName' 
							FROM #EquPartList Equ
								JOIN dbo.SubWorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.ItemMasterId = Equ.ItemMasterId
								JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Equ.EquItemMasterId
								JOIN dbo.ItemMaster IM_EquMain WITH (NOLOCK) ON IM_EquMain.ItemMasterId = Equ.ItemMasterId
								JOIN dbo.SubWorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.SubWorkOrderMaterialsKitMappingId = WOM.SubWorkOrderMaterialsKitMappingId
								JOIN dbo.Stockline SL WITH (NOLOCK) ON Equ.EquItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.SubWorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND WOMS.ProvisionId != @ProvisionId)
								LEFT JOIN dbo.SubWorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) ON WOMS.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
								LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
								LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
								LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
								LEFT JOIN dbo.Task TS WITH (NOLOCK) ON TS.TaskId = WOM.TaskId
							WHERE WOM.SubWOPartNoId = @SubWOPartNoId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
								AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
								AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.SubWorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) WHERE WOM.SubWorkOrderMaterialsKitId = WOMSL.SubWorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
								--AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId OR IM_EquMain.ItemMasterId = @ItemMasterId) 
								AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
								--AND (@KitId IS NULL OR WOMKM.KitId = @KitId)
								AND	(WOM.SubWorkOrderMaterialsKitId IN (SELECT SubWorkOrderMaterialsId FROM #TMPSubWOMaterialResultListData WHERE IsKit = 1));
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
              , @AdhocComments     VARCHAR(150)    = 'USP_GetSubWOMaterialStocklineListForManualReserve' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWOPartNoId, '') + ''
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
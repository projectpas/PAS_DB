/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <04/04/2023>  
** Description: <Preview Work Order Materials Auto reserve Stockline Details>  
  
EXEC [USP_AutoReserveAllWorkOrderMaterials] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    04/04/2023  HEMANT SALIYA    Preview Work Order Materials Auto reserve Stockline Details
** 2    06/07/2023  VISHAL SUTHAR    Allowing to preview Repair Provision and AR condition parts
** 3    07/26/2023	HEMANT SALIYA	 Allow User to reserver & Issue other Customer Stock as well
** 4    07/26/2023	HEMANT SALIYA	 Updated For Condition Group Changes

EXEC USP_PreviewAutoReserveAllWorkOrderMaterials 3128,1,0,2,0
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_PreviewAutoReserveAllWorkOrderMaterials]
	@WorkFlowWorkOrderId BIGINT,
	@IncludeAlternate BIT,
	@IncludeEquiv BIT,
	@EmployeeId BIGINT,
	@IncludeCustomerStock BIT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					DECLARE @ProvisionId BIGINT;
					DECLARE @MasterCompanyId BIGINT;
					DECLARE @SubWOProvisionId BIGINT;
					DECLARE @Provision VARCHAR(50);
					DECLARE @ProvisionCode VARCHAR(50);
					DECLARE @ARCondition VARCHAR(50);
					DECLARE @ARConditionId VARCHAR(50);
					DECLARE @CustomerID BIGINT;

					DECLARE @ARcount INT = 1;
					DECLARE @ARTotalCounts INT = 0;
					DECLARE @tmpActQuantity INT = 0;
					DECLARE @QtytToRes INT = 0;
					DECLARE @NewWorkOrderMaterialsId BIGINT;
					DECLARE @NewStockline BIGINT;

					DECLARE @Autocount INT;
					DECLARE @Materialscount INT;
					DECLARE @Autoslcount INT;
					DECLARE @AutoTotalCounts INT;

					SELECT @ProvisionId = ProvisionId, @Provision = [Description], @ProvisionCode = StatusCode FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'REPLACE' AND IsActive = 1 AND IsDeleted = 0;
					SELECT @SubWOProvisionId = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'SUB WORK ORDER' AND IsActive = 1 AND IsDeleted = 0;
					SELECT @CustomerID = WO.CustomerId, @MasterCompanyId = WO.MasterCompanyId FROM dbo.WorkOrder WO WITH(NOLOCK) JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) on WO.WorkOrderId = WOWF.WorkOrderId WHERE WOWF.WorkFlowWorkOrderId = @WorkFlowWorkOrderId;
					SELECT @ARCondition = [Description], @ARConditionId = ConditionId FROM dbo.Condition WITH(NOLOCK) WHERE Code = 'ASREMOVE' AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;

					IF OBJECT_ID(N'tempdb..#ConditionGroup') IS NOT NULL
					BEGIN
						DROP TABLE #ConditionGroup 
					END

					CREATE TABLE #ConditionGroup 
					(
						ID BIGINT NOT NULL IDENTITY, 
						[ConditionId] [BIGINT] NULL,
						[ConditionGroup] VARCHAR(50) NULL,
					)

					INSERT INTO #ConditionGroup (ConditionId, ConditionGroup)
					SELECT ConditionId, GroupCode FROM dbo.Condition WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId

					IF OBJECT_ID(N'tempdb..#tmpWorkOrderMaterials') IS NOT NULL
					BEGIN
						DROP TABLE #tmpWorkOrderMaterials
					END
			
					CREATE TABLE #tmpWorkOrderMaterials
					(
						ID BIGINT NOT NULL IDENTITY, 
						[WorkOrderMaterialsId] [bigint] NOT NULL,
						[WorkOrderId] [bigint] NOT NULL,
						[WorkFlowWorkOrderId] [bigint] NOT NULL,
						[ItemMasterId] [bigint] NOT NULL,
						[ConditionId] [bigint] NOT NULL,
						[Quantity] [int] NOT NULL,
						[UnitCost] [decimal](20, 2) NULL,
						[ExtendedCost] [decimal](20, 2) NULL,
						[QuantityReserved] [int] NULL,
						[QuantityIssued] [int] NULL,
						[IsAltPart] [bit] NULL,
						[AltPartMasterPartId] [bigint] NULL,
						[PartStatusId] [int] NULL,
						[UnReservedQty] [int] NULL,
						[UnIssuedQty] [int] NULL,
						[IssuedById] [bigint] NULL,
						[ReservedById] [bigint] NULL,
						[IsEquPart] [bit] NULL,
						[ItemMappingId] [bigint] NULL,
						[TotalReserved] [int] NULL,
						[TotalIssued] [int] NULL,
						[TotalUnReserved] [int] NULL,
						[TotalUnIssued] [int] NULL,
						[ProvisionId] [int] NULL,
						[MaterialMandatoriesId] [int] NULL,
						[WOPartNoId] [bigint] NULL,
						[TotalStocklineQtyReq] [int] NULL,
						[QtyOnOrder] [int] NULL,
						[QtyOnBkOrder] [int] NULL,
						[QtyToTurnIn] [int] NULL,
						[Figure] [nvarchar](50) NULL,
						[Item] [nvarchar](50) NULL,
						[EquPartMasterPartId] [bigint] NULL,
						[ReservedDate] [datetime2](7) NULL,
						[UnitOfMeasureId] [bigint] NULL,
						[TaskId] [bigint] NOT NULL,
						[MasterCompanyId] [int] NOT NULL,
						[CreatedBy] [varchar](256) NOT NULL,
						[UpdatedBy] [varchar](256) NOT NULL,
						[CreatedDate] [datetime2](7) NOT NULL,
						[UpdatedDate] [datetime2](7) NOT NULL,
						[IsActive] [bit] NOT NULL,
						[IsDeleted] [bit] NOT NULL,
						[ConditionGroupCode] [varchar](50) NULL,
					)
					
					IF OBJECT_ID(N'tempdb..#tmpWorkOrderMaterialStockline') IS NOT NULL
					BEGIN
						DROP TABLE #tmpWorkOrderMaterialStockline
					END

					CREATE TABLE #tmpWorkOrderMaterialStockline
					(
						ID BIGINT NOT NULL IDENTITY, 
						[WOMStockLineId] [bigint] NULL,
						[WorkOrderMaterialsId] [bigint] NOT NULL,
						[StockLineId] [bigint] NOT NULL,
						[ItemMasterId] [bigint] NOT NULL,
						[ConditionId] [bigint] NOT NULL,								
						[Quantity] [int] NULL,
						[QtyReserved] [int] NULL,
						[QtyIssued] [int] NULL,								
						[AltPartMasterPartId] [bigint] NULL,
						[EquPartMasterPartId] [bigint] NULL,
						[IsAltPart] [bit] NULL,
						[IsEquPart] [bit] NULL,
						[UnitCost] [decimal](20, 2) NULL,
						[ExtendedCost] [decimal](20, 2) NULL,
						[UnitPrice] [decimal](20, 2) NULL,
						[ExtendedPrice] [decimal](20, 2) NULL,
						[ProvisionId] [int] NOT NULL,
						[QuantityTurnIn] [int] NULL,
						[Figure] [nvarchar](50) NULL,
						[Item] [nvarchar](50) NULL,
						[MasterCompanyId] [int] NOT NULL,
						[CreatedBy] [varchar](256) NOT NULL,
						[UpdatedBy] [varchar](256) NOT NULL,
						[CreatedDate] [datetime2](7) NOT NULL,
						[UpdatedDate] [datetime2](7) NOT NULL,
						[IsActive] [bit] NOT NULL,
						[IsDeleted] [bit] NOT NULL,
					)

					IF OBJECT_ID(N'tempdb..#tmpWorkOrderMaterialsKit') IS NOT NULL
					BEGIN
					DROP TABLE #tmpWorkOrderMaterialsKit
					END
			
					CREATE TABLE #tmpWorkOrderMaterialsKit
					(
						ID BIGINT NOT NULL IDENTITY, 
						[WorkOrderMaterialsKitId] [bigint] NOT NULL,
						[WorkOrderMaterialsKitMappingId] [bigint] NOT NULL,
						[WorkOrderId] [bigint] NOT NULL,
						[WorkFlowWorkOrderId] [bigint] NOT NULL,
						[ItemMasterId] [bigint] NOT NULL,
						[ConditionId] [bigint] NOT NULL,
						[Quantity] [int] NOT NULL,
						[UnitCost] [decimal](20, 2) NULL,
						[ExtendedCost] [decimal](20, 2) NULL,
						[QuantityReserved] [int] NULL,
						[QuantityIssued] [int] NULL,
						[IsAltPart] [bit] NULL,
						[AltPartMasterPartId] [bigint] NULL,
						[PartStatusId] [int] NULL,
						[UnReservedQty] [int] NULL,
						[UnIssuedQty] [int] NULL,
						[IssuedById] [bigint] NULL,
						[ReservedById] [bigint] NULL,
						[IsEquPart] [bit] NULL,
						[ItemMappingId] [bigint] NULL,
						[TotalReserved] [int] NULL,
						[TotalIssued] [int] NULL,
						[TotalUnReserved] [int] NULL,
						[TotalUnIssued] [int] NULL,
						[ProvisionId] [int] NULL,
						[MaterialMandatoriesId] [int] NULL,
						[WOPartNoId] [bigint] NULL,
						[TotalStocklineQtyReq] [int] NULL,
						[QtyOnOrder] [int] NULL,
						[QtyOnBkOrder] [int] NULL,
						[QtyToTurnIn] [int] NULL,
						[Figure] [nvarchar](50) NULL,
						[Item] [nvarchar](50) NULL,
						[EquPartMasterPartId] [bigint] NULL,
						[ReservedDate] [datetime2](7) NULL,
						[UnitOfMeasureId] [bigint] NULL,
						[TaskId] [bigint] NOT NULL,
						[MasterCompanyId] [int] NOT NULL,
						[CreatedBy] [varchar](256) NOT NULL,
						[UpdatedBy] [varchar](256) NOT NULL,
						[CreatedDate] [datetime2](7) NOT NULL,
						[UpdatedDate] [datetime2](7) NOT NULL,
						[IsActive] [bit] NOT NULL,
						[IsDeleted] [bit] NOT NULL,
						[ConditionGroupCode] [varchar](50) NULL,
					)
					
					IF OBJECT_ID(N'tempdb..#tmpWorkOrderMaterialStockLineKit') IS NOT NULL
					BEGIN
					DROP TABLE #tmpWorkOrderMaterialStockLineKit
					END
					CREATE TABLE #tmpWorkOrderMaterialStockLineKit
					(
						ID BIGINT NOT NULL IDENTITY, 
						[WorkOrderMaterialStockLineKitId] [bigint] NULL,
						[WorkOrderMaterialsKITId] [bigint] NOT NULL,
						[StockLineId] [bigint] NOT NULL,
						[ItemMasterId] [bigint] NOT NULL,
						[ConditionId] [bigint] NOT NULL,								
						[Quantity] [int] NULL,
						[QtyReserved] [int] NULL,
						[QtyIssued] [int] NULL,								
						[AltPartMasterPartId] [bigint] NULL,
						[EquPartMasterPartId] [bigint] NULL,
						[IsAltPart] [bit] NULL,
						[IsEquPart] [bit] NULL,
						[UnitCost] [decimal](20, 2) NULL,
						[ExtendedCost] [decimal](20, 2) NULL,
						[UnitPrice] [decimal](20, 2) NULL,
						[ExtendedPrice] [decimal](20, 2) NULL,
						[ProvisionId] [int] NOT NULL,
						[QuantityTurnIn] [int] NULL,
						[Figure] [nvarchar](50) NULL,
						[Item] [nvarchar](50) NULL,
						[MasterCompanyId] [int] NOT NULL,
						[CreatedBy] [varchar](256) NOT NULL,
						[UpdatedBy] [varchar](256) NOT NULL,
						[CreatedDate] [datetime2](7) NOT NULL,
						[UpdatedDate] [datetime2](7) NOT NULL,
						[IsActive] [bit] NOT NULL,
						[IsDeleted] [bit] NOT NULL,
					)

					INSERT INTO #tmpWorkOrderMaterials
						   ([WorkOrderMaterialsId],[WorkOrderId],[WorkFlowWorkOrderId], [ItemMasterId], [ConditionId] , [Quantity] , [UnitCost] , [ExtendedCost] , [QuantityReserved] , [QuantityIssued] , [IsAltPart] ,[AltPartMasterPartId] ,
						   [PartStatusId] , [UnReservedQty] ,  [UnIssuedQty] ,  [IssuedById] , [ReservedById] , [IsEquPart] , [ItemMappingId] ,  [TotalReserved] , [TotalIssued] ,[TotalUnReserved] ,
						   [TotalUnIssued] , [ProvisionId], [MaterialMandatoriesId], [WOPartNoId] , [TotalStocklineQtyReq],  [QtyOnOrder] , [QtyOnBkOrder] , [QtyToTurnIn] , [Figure] , [Item] , [EquPartMasterPartId], [ReservedDate], [UnitOfMeasureId], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], ConditionGroupCode) 
					SELECT [WorkOrderMaterialsId], [WorkOrderId],[WorkFlowWorkOrderId], [ItemMasterId], [ConditionCodeId] , [Quantity] , [UnitCost] , [ExtendedCost] , [QuantityReserved] , [QuantityIssued] , [IsAltPart] ,[AltPartMasterPartId] ,
						   [PartStatusId] , [UnReservedQty] ,  [UnIssuedQty] ,  [IssuedById] , [ReservedById] , [IsEquPart] , [ItemMappingId] ,  [TotalReserved] , [TotalIssued] ,[TotalUnReserved] ,
						   [TotalUnIssued] , [ProvisionId], [MaterialMandatoriesId], [WOPartNoId] , [TotalStocklineQtyReq],  [QtyOnOrder] , [QtyOnBkOrder] , [QtyToTurnIn] , [Figure] , [Item] , [EquPartMasterPartId], [ReservedDate], [UnitOfMeasureId], [TaskId], WOM.[MasterCompanyId], WOM.[CreatedBy], WOM.[UpdatedBy], WOM.[CreatedDate], WOM.[UpdatedDate], WOM.[IsActive], WOM.[IsDeleted],C.GroupCode
					FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK) 
					JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
					WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND (ISNULL(Quantity, 0) != (ISNULL([QuantityReserved], 0) + ISNULL([QuantityIssued], 0)))

					INSERT INTO #tmpWorkOrderMaterialStockline
						([WOMStockLineId] ,[WorkOrderMaterialsId] ,[StockLineId] ,[ItemMasterId] ,[ConditionId] ,[Quantity] ,[QtyReserved] ,[QtyIssued] ,		
						[AltPartMasterPartId] ,[EquPartMasterPartId] ,[IsAltPart] ,[IsEquPart] ,[UnitCost] ,[ExtendedCost] ,[UnitPrice] ,[ExtendedPrice] ,
						[ProvisionId] ,[QuantityTurnIn] ,[Figure] ,[Item], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
					SELECT [WOMStockLineId] ,WOMS.[WorkOrderMaterialsId] ,[StockLineId] ,WOMS.[ItemMasterId] ,[ConditionId] ,WOMS.[Quantity] ,[QtyReserved] ,[QtyIssued] ,		
						WOMS.[AltPartMasterPartId] ,WOMS.[EquPartMasterPartId] ,WOMS.[IsAltPart] ,WOMS.[IsEquPart] ,WOMS.[UnitCost] ,WOMS.[ExtendedCost] ,[UnitPrice] ,[ExtendedPrice] ,
						WOMS.[ProvisionId] ,[QuantityTurnIn] ,WOMS.[Figure] ,WOMS.[Item], WOMS.[MasterCompanyId], WOMS.[CreatedBy], WOMS.[UpdatedBy], WOMS.[CreatedDate], WOMS.[UpdatedDate], WOMS.[IsActive], WOMS.[IsDeleted]
					FROM dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) 
					JOIN  dbo.WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.WorkOrderMaterialsId =  WOMS.WorkOrderMaterialsId
					WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId 
					AND WOMS.ProvisionId = @ProvisionId

					INSERT INTO #tmpWorkOrderMaterialsKit
						   ([WorkOrderMaterialsKitId],[WorkOrderMaterialsKitMappingId],[WorkOrderId],[WorkFlowWorkOrderId], [ItemMasterId], [ConditionId] , [Quantity] , [UnitCost] , [ExtendedCost] , [QuantityReserved] , [QuantityIssued] , [IsAltPart] ,[AltPartMasterPartId] ,
						   [PartStatusId] , [UnReservedQty] ,  [UnIssuedQty] ,  [IssuedById] , [ReservedById] , [IsEquPart] , [ItemMappingId] ,  [TotalReserved] , [TotalIssued] ,[TotalUnReserved] ,
						   [TotalUnIssued] , [ProvisionId], [MaterialMandatoriesId], [WOPartNoId] , [TotalStocklineQtyReq],  [QtyOnOrder] , [QtyOnBkOrder] , [QtyToTurnIn] , [Figure] , [Item] , [EquPartMasterPartId], [ReservedDate], [UnitOfMeasureId], [TaskId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [ConditionGroupCode]) 
					SELECT [WorkOrderMaterialsKitId], [WorkOrderMaterialsKitMappingId],[WorkOrderId],[WorkFlowWorkOrderId], [ItemMasterId], [ConditionCodeId] , [Quantity] , [UnitCost] , [ExtendedCost] , [QuantityReserved] , [QuantityIssued] , [IsAltPart] ,[AltPartMasterPartId] ,
						   [PartStatusId] , [UnReservedQty] ,  [UnIssuedQty] ,  [IssuedById] , [ReservedById] , [IsEquPart] , [ItemMappingId] ,  [TotalReserved] , [TotalIssued] ,[TotalUnReserved] ,
						   [TotalUnIssued] , [ProvisionId], [MaterialMandatoriesId], [WOPartNoId] , [TotalStocklineQtyReq],  [QtyOnOrder] , [QtyOnBkOrder] , [QtyToTurnIn] , [Figure] , [Item] , NULL, [ReservedDate], [UnitOfMeasureId], [TaskId], WOM.[MasterCompanyId], WOM.[CreatedBy], WOM.[UpdatedBy], WOM.[CreatedDate], WOM.[UpdatedDate], WOM.[IsActive], WOM.[IsDeleted], C.GroupCode 
					FROM dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) 
					JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
					WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND (ISNULL(Quantity, 0) != (ISNULL([QuantityReserved], 0) + ISNULL([QuantityIssued], 0)))

					INSERT INTO #tmpWorkOrderMaterialStockLineKit
						([WorkOrderMaterialStockLineKitId] ,[WorkOrderMaterialsKitId] ,[StockLineId] ,[ItemMasterId] ,[ConditionId] ,[Quantity] ,[QtyReserved] ,[QtyIssued] ,		
						[AltPartMasterPartId] ,[EquPartMasterPartId] ,[IsAltPart] ,[IsEquPart] ,[UnitCost] ,[ExtendedCost] ,[UnitPrice] ,[ExtendedPrice] ,
						[ProvisionId] ,[QuantityTurnIn] ,[Figure] ,[Item], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
					SELECT [WorkOrderMaterialStockLineKitId] ,WOMS.[WorkOrderMaterialsKitId] ,[StockLineId] ,WOMS.[ItemMasterId] ,[ConditionId] ,WOMS.[Quantity] ,[QtyReserved] ,[QtyIssued] ,		
						WOMS.[AltPartMasterPartId] ,WOMS.[EquPartMasterPartId] ,WOMS.[IsAltPart] ,WOMS.[IsEquPart] ,WOMS.[UnitCost] ,WOMS.[ExtendedCost] ,[UnitPrice] ,[ExtendedPrice] ,
						WOMS.[ProvisionId] ,[QuantityTurnIn] ,WOMS.[Figure] ,WOMS.[Item], WOMS.[MasterCompanyId], WOMS.[CreatedBy], WOMS.[UpdatedBy], WOMS.[CreatedDate], WOMS.[UpdatedDate], WOMS.[IsActive], WOMS.[IsDeleted]
					FROM dbo.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) 
					JOIN  dbo.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.WorkOrderMaterialsKitId =  WOMS.WorkOrderMaterialsKitId
					WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId 
					AND WOMS.ProvisionId = @ProvisionId
					
					SELECT SL.* 					
					INTO #Stockline
					FROM dbo.Stockline SL WITH(NOLOCK) JOIN #tmpWorkOrderMaterials WOM ON SL.ItemMasterId = WOM.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup tmpC WHERE WOM.ConditionGroupCode = tmpC.ConditionGroup) 
					WHERE ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
							AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))

					INSERT INTO #Stockline
					SELECT SL.*
					FROM dbo.Stockline SL WITH(NOLOCK) JOIN #tmpWorkOrderMaterialsKit WOM ON SL.ItemMasterId = WOM.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup tmpC WHERE WOM.ConditionGroupCode = tmpC.ConditionGroup) 
					WHERE ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
							AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
							AND SL.StockLineId NOT IN (SELECT StockLineId FROM #Stockline)

					--#STEP : 1 RESERVE EXISTING STOCKLINE					
					SELECT  WOM.WorkOrderId,
							WOM.WorkFlowWorkOrderId,
							WOM.WorkOrderMaterialsId,						
							WOM.ItemMasterId,
							WOM.ConditionId AS ConditionId,
							WOM.MasterCompanyId,
							WOM.Quantity,
							WOM.QuantityReserved,
							WOM.QuantityIssued,
							WOM.QtyOnOrder AS QuantityOnOrder,
							QtyToBeReserved = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
							WOM.UnitCost,
							WOM.ExtendedCost,
							WOM.TaskId,
							WOM.ProvisionId,
							IM.PartNumber,
							IM.PartDescription, 
							SL.StocklineId,
							SL.Condition,
							SL.StockLineNumber,
							SL.ControlNumber,
							SL.IdNumber,
							SL.Manufacturer,
							SL.SerialNumber,
							SL.QuantityAvailable AS QuantityAvailable,
							SL.QuantityOnHand AS QuantityOnHand,
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
							CASE WHEN (ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0))) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM #tmpWorkOrderMaterialStockline WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) END
							AS MSQuantityRequsted,
							WOMS.QtyReserved AS MSQuantityReserved,
							WOMS.QtyIssued AS MSQuantityIssued,
							@EmployeeId AS ReservedById,
							WOMS.UpdatedBy AS ReservedBy,
							CASE WHEN WOMS.WOMStockLineId > 0 THEN WOMS.UnitCost ELSE SL.UnitCost END AS SLUnitCost,
							MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
							CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
							CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
							CASE WHEN WOMS.WOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded	
						INTO #tmpReserveIssueWOMaterialsStockline
						FROM #tmpWorkOrderMaterials WOM WITH (NOLOCK)  
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
							JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionId
							JOIN #Stockline SL WITH (NOLOCK) ON WOM.ItemMasterId = SL.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup tmpC WHERE tmpC.ConditionGroup = C.GroupCode) AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM #tmpWorkOrderMaterialStockline WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
							JOIN #tmpWorkOrderMaterialStockline WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
							LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
							AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM #tmpWorkOrderMaterialStockline WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
					
					--Select * from #tmpWorkOrderMaterials
					--#STEP : 1.1 RESERVE EXISTING STOCKLINE
					IF((SELECT COUNT(1) FROM #tmpReserveIssueWOMaterialsStockline) > 0)
					BEGIN
						--CASE 1 UPDATE WORK ORDER MATERILS
						DECLARE @count INT;
						DECLARE @count1 INT;
						DECLARE @slcount INT;
						DECLARE @TotalCounts INT;
						DECLARE @StocklineId BIGINT; 
						DECLARE @ModuleId INT;
						DECLARE @ReferenceId BIGINT;
						DECLARE @IsAddUpdate BIT; 
						DECLARE @ExecuteParentChild BIT; 
						DECLARE @UpdateQuantities BIT;
						DECLARE @IsOHUpdated BIT; 
						DECLARE @AddHistoryForNonSerialized BIT; 
						DECLARE @SubModuleId INT;
						DECLARE @SubReferenceId BIGINT;
						DECLARE @ReservePartStatus INT;
						DECLARE @WorkOrderMaterialsId BIGINT;
						DECLARE @IsSerialised BIT;
						DECLARE @stockLineQty INT;
						DECLARE @stockLineQtyAvailable INT;

						SELECT @ProvisionId = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'REPLACE' AND IsActive = 1 AND IsDeleted = 0;
						SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 15; -- For WORK ORDER Module
						SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 33; -- For WORK ORDER Materials Module
						SET @ReservePartStatus = 1; -- FOR RESERTVE
						SET @IsAddUpdate = 0;
						SET @ExecuteParentChild = 1;
						SET @UpdateQuantities = 1;
						SET @IsOHUpdated = 0;
						SET @AddHistoryForNonSerialized = 0;					
						SET @slcount = 1;
						SET @count = 1;
						SET @count1 = 1;

						IF OBJECT_ID(N'tempdb..#tmpReserveWOMaterialsStockline') IS NOT NULL
						BEGIN
						DROP TABLE #tmpReserveWOMaterialsStockline
						END
			
						CREATE TABLE #tmpReserveWOMaterialsStockline
								(
									 ID BIGINT NOT NULL IDENTITY, 
									 [WorkOrderId] BIGINT NULL,
									 [WorkFlowWorkOrderId] BIGINT NULL,
									 [WorkOrderMaterialsId] BIGINT NULL,
									 [StockLineId] BIGINT NULL,
									 [ItemMasterId] BIGINT NULL,
									 [ConditionId] BIGINT NULL,
									 [ProvisionId] BIGINT NULL,
									 [TaskId] BIGINT NULL,
									 [ReservedById] BIGINT NULL,
									 [Condition] VARCHAR(500) NULL,
									 [PartNumber] VARCHAR(500) NULL,
									 [PartDescription] VARCHAR(max) NULL,
									 [Quantity] INT NULL,
									 [QtyToBeReserved] INT NULL,
									 [QuantityActReserved] INT NULL,
									 [ControlNo] VARCHAR(500) NULL,
									 [ControlId] VARCHAR(500) NULL,
									 [StockLineNumber] VARCHAR(500) NULL,
									 [SerialNumber] VARCHAR(500) NULL,
									 [ReservedBy] VARCHAR(500) NULL,						 
									 [IsStocklineAdded] BIT NULL,
									 [MasterCompanyId] BIGINT NULL,
									 [UpdatedBy] VARCHAR(500) NULL,
									 [UnitCost] DECIMAL(18,2),
									 [IsSerialized] BIT
								)

						IF OBJECT_ID(N'tempdb..#tmpIgnoredStockline') IS NOT NULL
						BEGIN
						DROP TABLE #tmpIgnoredStockline
						END
			
						CREATE TABLE #tmpIgnoredStockline
								(
									 ID BIGINT NOT NULL IDENTITY, 
									 [Condition] VARCHAR(500) NULL,
									 [PartNumber] VARCHAR(500) NULL,
									 [ControlNo] VARCHAR(500) NULL,
									 [ControlId] VARCHAR(500) NULL,
									 [StockLineNumber] VARCHAR(500) NULL,
								)

						INSERT INTO #tmpReserveWOMaterialsStockline ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
								[TaskId], [ReservedById], [Condition], [PartNumber], [PartDescription], [Quantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
								[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UnitCost], [IsSerialized])
						SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], tblMS.[StockLineId], tblMS.[ItemMasterId], tblMS.[ConditionId], @ProvisionId, 
								[TaskId], [ReservedById], tblMS.[Condition], tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], [QtyToBeReserved], [QtyToBeReserved], tblMS.[ControlNumber], tblMS.[IdNumber],
								tblMS.[StockLineNumber], tblMS.[SerialNumber], [ReservedBy], [IsStocklineAdded], SL.MasterCompanyId, [ReservedBy], SL.UnitCost, SL.isSerialized
						FROM #tmpReserveIssueWOMaterialsStockline tblMS  JOIN #Stockline SL ON SL.StockLineId = tblMS.StockLineId 
						WHERE SL.QuantityAvailable > 0 
						AND SL.IsParent = 1 
						AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
						AND SL.QuantityAvailable >= tblMS.MSQunatityRemaining

						SELECT @TotalCounts = COUNT(ID) FROM #tmpReserveWOMaterialsStockline;

						INSERT INTO #tmpIgnoredStockline ([PartNumber], [Condition], [ControlNo], [ControlId], [StockLineNumber]) 
						SELECT tblMS.[PartNumber], tblMS.[Condition], tblMS.[ControlNumber], tblMS.[IdNumber], tblMS.[StockLineNumber] FROM #tmpReserveIssueWOMaterialsStockline tblMS  
						WHERE tblMS.StockLineId NOT IN (SELECT StockLineId FROM #tmpReserveWOMaterialsStockline)

						--UPDATE WORK ORDER MATERIALS DETAILS
						WHILE @count<= @TotalCounts
						BEGIN
							UPDATE #tmpWorkOrderMaterials 
								SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.QuantityActReserved,0),
									TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.QuantityActReserved,0),
									ReservedById = tmpWOM.ReservedById, 
									ReservedDate = GETDATE(), 
									UpdatedDate = GETDATE(),
									PartStatusId = @ReservePartStatus
							FROM #tmpWorkOrderMaterials WOM JOIN #tmpReserveWOMaterialsStockline tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.ID = @count
							SET @count = @count + 1;
						END;
					
						--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
						IF(@TotalCounts > 0 )
						BEGIN
							MERGE #tmpWorkOrderMaterialStockline AS TARGET
							USING #tmpReserveWOMaterialsStockline AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.WorkOrderMaterialsId = TARGET.WorkOrderMaterialsId) -- TARGET.ItemMasterId = SOURCE.ItemMasterId AND TARGET.ConditionId = SOURCE.ConditionId) 
							--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
							WHEN MATCHED 				
								THEN UPDATE 						
								SET TARGET.QtyReserved = ISNULL(TARGET.QtyReserved, 0) + ISNULL(SOURCE.QuantityActReserved, 0),
									TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * TARGET.UnitCost,
									TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * TARGET.UnitCost,
									TARGET.UpdatedDate = GETDATE(),
									TARGET.UpdatedBy = SOURCE.ReservedBy
							WHEN NOT MATCHED BY TARGET 
								THEN INSERT (StocklineId, WorkOrderMaterialsId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
								VALUES (SOURCE.StocklineId, SOURCE.WorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.QuantityActReserved, SOURCE.QuantityActReserved, 0, SOURCE.UnitCost, (ISNULL(SOURCE.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0);
						END

						--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
						UPDATE #tmpWorkOrderMaterialStockline 
						SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
						FROM #tmpWorkOrderMaterialStockline WOMS JOIN #tmpReserveWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId 
						WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 

						--FOR UPDATED WORKORDER MATERIALS QTY
						UPDATE #tmpWorkOrderMaterials 
						SET Quantity = GropWOM.Quantity	
						FROM(
							SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, WOM.WorkOrderMaterialsId   
							FROM #tmpWorkOrderMaterials WOM 
							JOIN #tmpWorkOrderMaterialStockline WOMS ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId 
							WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
							GROUP BY WOM.WorkOrderMaterialsId
						) GropWOM WHERE GropWOM.WorkOrderMaterialsId = #tmpWorkOrderMaterials.WorkOrderMaterialsId AND ISNULL(GropWOM.Quantity,0) > ISNULL(#tmpWorkOrderMaterials.Quantity,0)			

						IF OBJECT_ID(N'tempdb..#tmpIgnoredStockline') IS NOT NULL
						BEGIN
						DROP TABLE #tmpIgnoredStockline
						END

						IF OBJECT_ID(N'tempdb..#tmpReserveWOMaterialsStockline') IS NOT NULL
						BEGIN
						DROP TABLE #tmpReserveWOMaterialsStockline
						END
					END
					
					--#STEP : 2 RESERVE KIT ALTERNATE PARTS 
					IF(ISNULL(@IncludeAlternate, 0) = 1)
					BEGIN
						IF OBJECT_ID(N'tempdb..#AltPartList') IS NOT NULL
						BEGIN
							DROP TABLE #AltPartList 
						END
			
						CREATE TABLE #AltPartList 
						(
							ID BIGINT NOT NULL IDENTITY, 
							[ItemMasterId] [bigint] NULL,
							[AltItemMasterId] [bigint] NULL
						)
						
						INSERT INTO #AltPartList 
						(WOM.[ItemMasterId], [AltItemMasterId])
						SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
						FROM #tmpWorkOrderMaterialsKit WOM WITH (NOLOCK)  
							LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND MappingType = 1 AND NhaTla.IsDeleted = 0 AND NhaTla.IsActive = 1
							LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId

						SELECT  
							WOM.WorkOrderId,
							WOM.WorkFlowWorkOrderId,
							WOM.WorkOrderMaterialsKitId,
							WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,	
							Alt.AltItemMasterId AS ItemMasterId,
							WOM.ItemMasterId AS AltPartMasterPartId,
							WOM.ConditionId AS ConditionId,
							C.GroupCode AS ConditionGroupCode,
							WOM.MasterCompanyId,
							WOM.Quantity,
							WOM.QuantityReserved,
							WOM.QuantityIssued,
							WOM.QtyOnOrder AS QuantityOnOrder,
							(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM #tmpWorkOrderMaterialStocklineKIT WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKITId = WOMSL.WorkOrderMaterialsKITId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
							WOM.UnitCost,
							WOM.ExtendedCost,
							WOM.TaskId,
							WOM.ProvisionId,
							IM.PartNumber,
							IM.PartDescription, 							
							P.Description AS Provision,
							P.StatusCode AS ProvisionStatusCode,
							CASE 
							WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
							WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
							WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
							ELSE 'OEM'
							END AS StockType,				
							@EmployeeId AS ReservedById,
							WOM.UpdatedBy AS ReservedBy,
							0 AS IsStocklineAdded,
							1 AS IsAltPart
						INTO #tmpAutoReserveIssueWOMaterialsStocklineKITAlt
						FROM #AltPartList Alt
							JOIN #tmpWorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.ItemMasterId = Alt.ItemMasterId
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Alt.AltItemMasterId
							JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionId
							JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.IsDeleted = 0  
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM #tmpWorkOrderMaterialStocklineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)

						IF OBJECT_ID(N'tempdb..#tmpAutoReserveWOMaterialsStocklineKITAlt') IS NOT NULL
						BEGIN
						DROP TABLE #tmpAutoReserveWOMaterialsStocklineKITAlt
						END

						CREATE TABLE #tmpAutoReserveWOMaterialsStocklineKITAlt
									(
										 ID BIGINT NOT NULL IDENTITY, 
										 [WorkOrderId] BIGINT NULL,
										 [WorkFlowWorkOrderId] BIGINT NULL,
										 [WorkOrderMaterialsId] BIGINT NULL,
										 [StockLineId] BIGINT NULL,
										 [ItemMasterId] BIGINT NULL,
										 [AltPartMasterPartId] BIGINT NULL,
										 [ConditionId] BIGINT NULL,
										 [ProvisionId] BIGINT NULL,
										 [TaskId] BIGINT NULL,
										 [ReservedById] BIGINT NULL,
										 [Condition] VARCHAR(500) NULL,
										 [PartNumber] VARCHAR(500) NULL,
										 [PartDescription] VARCHAR(max) NULL,
										 [Quantity] INT NULL,
										 [QuantityAvailable] INT NULL,
										 [QuantityOnHand] INT NULL,
										 [ActQuantity] INT NULL,
										 [QtyToBeReserved] INT NULL,
										 [QuantityActReserved] INT NULL,
										 [ControlNo] VARCHAR(500) NULL,
										 [ControlId] VARCHAR(500) NULL,
										 [StockLineNumber] VARCHAR(500) NULL,
										 [SerialNumber] VARCHAR(500) NULL,
										 [ReservedBy] VARCHAR(500) NULL,						 
										 [IsStocklineAdded] BIT NULL,
										 [MasterCompanyId] BIGINT NULL,
										 [UpdatedBy] VARCHAR(500) NULL,
										 [UnitCost] DECIMAL(18,2),
										 [IsSerialized] BIT,
										 [IsAltPart] BIT,
										 [IsActive] BIT,
										 [IsDeleted] BIT,
										 [CreatedDate] DATETIME2 NULL,
									)

						INSERT INTO #tmpAutoReserveWOMaterialsStocklineKITAlt ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId], [AltPartMasterPartId],[ConditionId], [ProvisionId], 
								[TaskId], [ReservedById], [Condition], [PartNumber], [PartDescription], [Quantity],[QuantityAvailable],[QuantityOnHand], [ActQuantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
								[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UnitCost], [IsSerialized], [IsAltPart],[IsActive], [IsDeleted], [CreatedDate])
						SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], SL.StockLineId, tblMS.[ItemMasterId],tblMS.[AltPartMasterPartId], tblMS.[ConditionId], @ProvisionId, 
								[TaskId], [ReservedById], SL.Condition, tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], SL.QuantityAvailable, SL.QuantityOnHand, 0, [QtyToBeReserved], [QtyToBeReserved], SL.ControlNumber, SL.IdNumber,
								SL.StockLineNumber, SL.SerialNumber, [ReservedBy], [IsStocklineAdded], tblMS.MasterCompanyId, [ReservedBy], SL.UnitCost, NULL, tblMS.[IsAltPart], 1, 0, SL.CreatedDate
						FROM #tmpAutoReserveIssueWOMaterialsStocklineKITAlt tblMS  JOIN dbo.Stockline SL ON SL.ItemMasterId = tblMS.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup tmpC WHERE tblMS.ConditionGroupCode = tmpC.ConditionGroup)  
						WHERE SL.QuantityAvailable > 0 
						AND SL.IsParent = 1 
						AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
						ORDER BY SL.CreatedDate

						INSERT INTO #Stockline
						SELECT SL.*
						FROM dbo.Stockline SL WITH(NOLOCK) 
						JOIN #tmpAutoReserveWOMaterialsStocklineKITAlt WOM ON SL.[StockLineId] = WOM.StockLineId
						WHERE WOM.StockLineId NOT IN (SELECT StockLineId FROM #Stockline)

						SET @ARcount = 1;
						SET @ARTotalCounts = 0;
						SET @tmpActQuantity = 0;
						SET @QtytToRes = 0;
						SET @NewWorkOrderMaterialsId = 0;
						SET @NewStockline = 0;

						SELECT @ARTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMaterialsStocklineKITAlt;

						WHILE @ARcount<= @ARTotalCounts
						BEGIN						 
							SELECT @NewWorkOrderMaterialsId = WorkOrderMaterialsId, @NewStockline = StockLineId FROM #tmpAutoReserveWOMaterialsStocklineKITAlt WHERE ID = @ARcount

							SELECT @tmpActQuantity = SUM(ISNULL(ActQuantity, 0)), @QtytToRes = MAX(ISNULL(QtyToBeReserved, 0)) - SUM(ISNULL(ActQuantity, 0))
							FROM #tmpAutoReserveWOMaterialsStocklineKITAlt
							WHERE WorkOrderMaterialsId = @NewWorkOrderMaterialsId
							GROUP BY WorkOrderMaterialsId

							IF(@QtytToRes > 0)
							BEGIN
								UPDATE #tmpAutoReserveWOMaterialsStocklineKITAlt
								SET ActQuantity = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN ISNULL(QuantityAvailable, 0) ELSE @QtytToRes END,
									IsActive = 1, IsStocklineAdded = 1
								FROM #tmpAutoReserveWOMaterialsStocklineKITAlt tmpWOM
								WHERE tmpWOM.ID = @ARcount AND ISNULL(QuantityAvailable, 0) > 0 AND ISNULL(IsStocklineAdded, 0) = 0 

								UPDATE #tmpAutoReserveWOMaterialsStocklineKITAlt
								SET QuantityAvailable = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN 0 ELSE ISNULL(QuantityAvailable, 0) - @QtytToRes END								
								FROM #tmpAutoReserveWOMaterialsStocklineKITAlt tmpWOM
								WHERE tmpWOM.StockLineId = @NewStockline  AND ISNULL(QuantityAvailable, 0) > 0
							END
					
							SET @ARcount = @ARcount + 1;
						END;

						DELETE FROM #tmpAutoReserveWOMaterialsStocklineKITAlt WHERE IsStocklineAdded != 1

						SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row_Num, * INTO #tmpAutoReserveWOMKITAlt FROM #tmpAutoReserveWOMaterialsStocklineKITAlt

						IF((SELECT COUNT(1) FROM #tmpAutoReserveWOMKITAlt) > 0)
						BEGIN
							SET @Autocount = 0;
							SET @Materialscount = 0;
							SET @Autoslcount = 0;
							SET @AutoTotalCounts = 0;

							SET @Autoslcount = 1;
							SET @Autocount = 1;
							SET @Materialscount = 1;

							SELECT @AutoTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMKITAlt;
		
							--UPDATE WORK ORDER MATERIALS DETAILS
							WHILE @Autocount<= @AutoTotalCounts
							BEGIN
								UPDATE #tmpWorkOrderMaterialsKit 
									SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
										TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
										ReservedById = tmpWOM.ReservedById, 
										ReservedDate = GETDATE(), 
										UpdatedDate = GETDATE(),
										PartStatusId = @ReservePartStatus
								FROM #tmpWorkOrderMaterialsKit WOM JOIN #tmpAutoReserveWOMKITAlt tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKITId AND tmpWOM.Row_Num = @Autocount
								SET @Autocount = @Autocount + 1;
							END;

							--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
							IF(@AutoTotalCounts > 0 )
							BEGIN
								MERGE #tmpWorkOrderMaterialStockLineKit AS TARGET
								USING #tmpAutoReserveWOMKITAlt AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.WorkOrderMaterialsId = TARGET.WorkOrderMaterialsKITId) -- TARGET.ItemMasterId = SOURCE.ItemMasterId AND TARGET.ConditionId = SOURCE.ConditionId) 
								--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
								WHEN MATCHED 				
									THEN UPDATE 						
									SET TARGET.QtyReserved = ISNULL(TARGET.QtyReserved, 0) + ISNULL(SOURCE.ActQuantity, 0),
										TARGET.UnitCost = SOURCE.UnitCost,
										TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
										TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
										TARGET.UpdatedDate = GETDATE(),
										TARGET.IsAltPart = SOURCE.IsAltPart,
										TARGET.AltPartMasterPartId = SOURCE.AltPartMasterPartId,
										TARGET.UpdatedBy = SOURCE.ReservedBy
								WHEN NOT MATCHED BY TARGET 
									THEN INSERT (WorkOrderMaterialStockLineKitId, StocklineId, WorkOrderMaterialsKITId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted, IsAltPart, AltPartMasterPartId) 
									VALUES (NULL, SOURCE.StocklineId, SOURCE.WorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.ActQuantity, SOURCE.ActQuantity, 0, SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0, SOURCE.IsAltPart, SOURCE.AltPartMasterPartId);
							END

							--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
							UPDATE #tmpWorkOrderMaterialStockLineKit 
							SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
							FROM #tmpWorkOrderMaterialStockLineKit WOMS JOIN #tmpAutoReserveWOMKITAlt tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsKITId = tmpRSL.WorkOrderMaterialsId 
							WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 

							--FOR UPDATED WORKORDER MATERIALS QTY
							UPDATE #tmpWorkOrderMaterialsKit 
							SET Quantity = GropWOM.Quantity	
							FROM(
								SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, WOM.WorkOrderMaterialsKITId AS WorkOrderMaterialsId
								FROM #tmpWorkOrderMaterialsKit WOM 
								JOIN #tmpWorkOrderMaterialStockLineKit WOMS ON WOMS.WorkOrderMaterialsKITId = WOM.WorkOrderMaterialsKITId 
								WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
								GROUP BY WOM.WorkOrderMaterialsKITId
							) GropWOM WHERE GropWOM.WorkOrderMaterialsId = #tmpWorkOrderMaterialsKit.WorkOrderMaterialsKITId AND ISNULL(GropWOM.Quantity,0) > ISNULL(#tmpWorkOrderMaterialsKit.Quantity,0)			

							--FOR UPDATED STOCKLINE QTY
							UPDATE #Stockline
							SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) - ISNULL(tmpRSL.ActQuantity,0),
								QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(tmpRSL.ActQuantity,0),
								WorkOrderMaterialsKitId = tmpRSL.WorkOrderMaterialsId
							FROM #Stockline SL JOIN #tmpAutoReserveWOMKITAlt tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
							
						END
					END
					
					--#STEP : 2.1 RESERVE MATERIALS ALTERNATE PARTS 
					IF(ISNULL(@IncludeAlternate, 0) = 1)
					BEGIN
						IF OBJECT_ID(N'tempdb..#MaterialsAltPartList') IS NOT NULL
						BEGIN
							DROP TABLE #MaterialsAltPartList 
						END

						PRINT 'MATERIALS ALTERNATE PARTS'
			
						CREATE TABLE #MaterialsAltPartList 
						(
							ID BIGINT NOT NULL IDENTITY, 
							[ItemMasterId] [bigint] NULL,
							[AltItemMasterId] [bigint] NULL
						)

						--Select * from #tmpWorkOrderMaterials

						INSERT INTO #MaterialsAltPartList 
						(WOM.[ItemMasterId], [AltItemMasterId])
						SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
						FROM #tmpWorkOrderMaterials WOM WITH (NOLOCK)  
							LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND MappingType = 1 AND NhaTla.IsDeleted = 0 AND NhaTla.IsActive = 1
							LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId

						--Select * from #MaterialsAltPartList

						SELECT  WOM.WorkOrderId,
							WOM.WorkFlowWorkOrderId,
							WOM.WorkOrderMaterialsId,						
							Alt.AltItemMasterId AS ItemMasterId,
							WOM.ItemMasterId AS AltPartMasterPartId,
							WOM.ConditionId AS ConditionId,
							C.GroupCode AS ConditionGroupCode,
							WOM.MasterCompanyId,
							WOM.Quantity,
							WOM.QuantityReserved,
							WOM.QuantityIssued,
							WOM.QtyOnOrder AS QuantityOnOrder,
							(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM #tmpWorkOrderMaterialStockline WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
							WOM.UnitCost,
							WOM.ExtendedCost,
							WOM.TaskId,
							WOM.ProvisionId,
							IM.PartNumber,
							IM.PartDescription, 							
							P.Description AS Provision,
							P.StatusCode AS ProvisionStatusCode,
							CASE 
							WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
							WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
							WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
							ELSE 'OEM'
							END AS StockType,	
							@EmployeeId AS ReservedById,
							WOM.UpdatedBy AS ReservedBy,
							0 AS IsStocklineAdded,
							1 AS IsAltPart
						INTO #tmpAutoReserveIssueWOMaterialsStocklineMaterialsAlt
						FROM #MaterialsAltPartList Alt
							JOIN #tmpWorkOrderMaterials WOM WITH (NOLOCK) ON WOM.ItemMasterId = Alt.ItemMasterId
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Alt.AltItemMasterId
							JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId							
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND  WOM.IsDeleted = 0  
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM #tmpWorkOrderMaterialStockline WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)

						--Select * from #tmpAutoReserveIssueWOMaterialsStocklineMaterialsAlt

						IF OBJECT_ID(N'tempdb..#tmpAutoReserveWOMaterialsStocklineMaterialsAlt') IS NOT NULL
						BEGIN
						DROP TABLE #tmpAutoReserveWOMaterialsStocklineMaterialsAlt
						END
			
						CREATE TABLE #tmpAutoReserveWOMaterialsStocklineMaterialsAlt
								(
									 ID BIGINT NOT NULL IDENTITY, 
									 [WorkOrderId] BIGINT NULL,
									 [WorkFlowWorkOrderId] BIGINT NULL,
									 [WorkOrderMaterialsId] BIGINT NULL,
									 [StockLineId] BIGINT NULL,
									 [ItemMasterId] BIGINT NULL,
									 [AltPartMasterPartId] BIGINT NULL,
									 [ConditionId] BIGINT NULL,
									 [ProvisionId] BIGINT NULL,
									 [TaskId] BIGINT NULL,
									 [ReservedById] BIGINT NULL,
									 [Condition] VARCHAR(500) NULL,
									 [PartNumber] VARCHAR(500) NULL,
									 [PartDescription] VARCHAR(max) NULL,
									 [Quantity] INT NULL,
									 [QuantityAvailable] INT NULL,
									 [QuantityOnHand] INT NULL,
									 [ActQuantity] INT NULL,
									 [QtyToBeReserved] INT NULL,
									 [QuantityActReserved] INT NULL,
									 [ControlNo] VARCHAR(500) NULL,
									 [ControlId] VARCHAR(500) NULL,
									 [StockLineNumber] VARCHAR(500) NULL,
									 [SerialNumber] VARCHAR(500) NULL,
									 [ReservedBy] VARCHAR(500) NULL,						 
									 [IsStocklineAdded] BIT NULL,
									 [MasterCompanyId] BIGINT NULL,
									 [UpdatedBy] VARCHAR(500) NULL,
									 [UnitCost] DECIMAL(18,2),
									 [IsSerialized] BIT,
									 [IsAltPart] BIT,
									 [IsActive] BIT,
									 [IsDeleted] BIT,
									 [CreatedDate] DATETIME2 NULL,
								)

						INSERT INTO #tmpAutoReserveWOMaterialsStocklineMaterialsAlt ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId],[AltPartMasterPartId],[ConditionId], [ProvisionId], 
								[TaskId], [ReservedById], [Condition], [PartNumber], [PartDescription], [Quantity],[QuantityAvailable],[QuantityOnHand], [ActQuantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
								[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UnitCost], [IsSerialized],[IsAltPart],[IsActive], [IsDeleted], [CreatedDate])
						SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], SL.StockLineId, tblMS.[ItemMasterId],tblMS.[AltPartMasterPartId], tblMS.[ConditionId], @ProvisionId, 
								[TaskId], [ReservedById], SL.Condition, tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], SL.QuantityAvailable, SL.QuantityOnHand, 0, [QtyToBeReserved], [QtyToBeReserved], SL.ControlNumber, SL.IdNumber,
								SL.StockLineNumber, SL.SerialNumber, [ReservedBy], [IsStocklineAdded], tblMS.MasterCompanyId, [ReservedBy], SL.UnitCost, NULL, tblMS.[IsAltPart],1, 0, SL.CreatedDate
						FROM #tmpAutoReserveIssueWOMaterialsStocklineMaterialsAlt tblMS  
						JOIN dbo.Stockline SL ON SL.ItemMasterId = tblMS.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup tmpC WHERE tblMS.ConditionGroupCode = tmpC.ConditionGroup) 
						-- AND SL.ConditionId = tblMS.ConditionId 
						WHERE SL.QuantityAvailable > 0 
						AND SL.IsParent = 1 
						AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
						ORDER BY SL.CreatedDate

						--Select * from #tmpAutoReserveWOMaterialsStocklineMaterialsAlt

						INSERT INTO #Stockline
						SELECT SL.*
						FROM dbo.Stockline SL WITH(NOLOCK) 
						JOIN #tmpAutoReserveWOMaterialsStocklineMaterialsAlt WOM ON SL.[StockLineId] = WOM.StockLineId
						WHERE WOM.StockLineId NOT IN (SELECT StockLineId FROM #Stockline)

						SET @ARcount = 1;
						SET @ARTotalCounts = 0;
						SET @tmpActQuantity = 0;
						SET @QtytToRes = 0;
						SET @NewWorkOrderMaterialsId = 0;
						SET @NewStockline = 0;

						SELECT @ARTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMaterialsStocklineMaterialsAlt;

						WHILE @ARcount<= @ARTotalCounts
						BEGIN						 
							SELECT @NewWorkOrderMaterialsId = WorkOrderMaterialsId, @NewStockline = StockLineId FROM #tmpAutoReserveWOMaterialsStocklineMaterialsAlt WHERE ID = @ARcount

							SELECT @tmpActQuantity = SUM(ISNULL(ActQuantity, 0)), @QtytToRes = MAX(ISNULL(QtyToBeReserved, 0)) - SUM(ISNULL(ActQuantity, 0))
							FROM #tmpAutoReserveWOMaterialsStocklineMaterialsAlt 
							WHERE WorkOrderMaterialsId = @NewWorkOrderMaterialsId
							GROUP BY WorkOrderMaterialsId

							IF(@QtytToRes > 0)
							BEGIN
								UPDATE #tmpAutoReserveWOMaterialsStocklineMaterialsAlt 
								SET ActQuantity = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN ISNULL(QuantityAvailable, 0) ELSE @QtytToRes END,
									IsActive = 1, IsStocklineAdded = 1
								FROM #tmpAutoReserveWOMaterialsStocklineMaterialsAlt tmpWOM
								WHERE tmpWOM.ID = @ARcount AND ISNULL(QuantityAvailable, 0) > 0 AND ISNULL(IsStocklineAdded, 0) = 0 

								UPDATE #tmpAutoReserveWOMaterialsStocklineMaterialsAlt
								SET QuantityAvailable = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN 0 ELSE ISNULL(QuantityAvailable, 0) - @QtytToRes END								
								FROM #tmpAutoReserveWOMaterialsStocklineMaterialsAlt tmpWOM
								WHERE tmpWOM.StockLineId = @NewStockline  AND ISNULL(QuantityAvailable, 0) > 0
							END
					
							SET @ARcount = @ARcount + 1;
						END;

						DELETE FROM #tmpAutoReserveWOMaterialsStocklineMaterialsAlt WHERE IsStocklineAdded != 1

						SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row_Num, * INTO #tmpAutoReserveWOMMaterialsAlt FROM #tmpAutoReserveWOMaterialsStocklineMaterialsAlt

						IF((SELECT COUNT(1) FROM #tmpAutoReserveWOMMaterialsAlt) > 0)
						BEGIN
							SET @Autoslcount = 1;
							SET @Autocount = 1;
							SET @Materialscount = 1;

							SELECT @AutoTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMMaterialsAlt;
		
							--UPDATE WORK ORDER MATERIALS DETAILS
							WHILE @Autocount<= @AutoTotalCounts
							BEGIN
								UPDATE #tmpWorkOrderMaterials 
									SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
										TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
										ReservedById = tmpWOM.ReservedById, 
										ReservedDate = GETDATE(), 
										UpdatedDate = GETDATE(),
										PartStatusId = @ReservePartStatus
								FROM #tmpWorkOrderMaterials WOM JOIN #tmpAutoReserveWOMMaterialsAlt tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.Row_Num = @Autocount
								SET @Autocount = @Autocount + 1;
							END;

							--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
							IF(@AutoTotalCounts > 0 )
							BEGIN
								MERGE #tmpWorkOrderMaterialStockline AS TARGET
								USING #tmpAutoReserveWOMMaterialsAlt AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.WorkOrderMaterialsId = TARGET.WorkOrderMaterialsId) -- TARGET.ItemMasterId = SOURCE.ItemMasterId AND TARGET.ConditionId = SOURCE.ConditionId) 
								--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
								WHEN MATCHED 				
									THEN UPDATE 						
									SET TARGET.QtyReserved = ISNULL(TARGET.QtyReserved, 0) + ISNULL(SOURCE.ActQuantity, 0),
										TARGET.UnitCost = SOURCE.UnitCost,
										TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
										TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
										TARGET.UpdatedDate = GETDATE(),
										TARGET.IsAltPart = SOURCE.IsAltPart,
										TARGET.AltPartMasterPartId = SOURCE.AltPartMasterPartId,
										TARGET.UpdatedBy = SOURCE.ReservedBy
								WHEN NOT MATCHED BY TARGET 
									THEN INSERT (StocklineId, WorkOrderMaterialsId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted,IsAltPart,AltPartMasterPartId) 
									VALUES (SOURCE.StocklineId, SOURCE.WorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.ActQuantity, SOURCE.ActQuantity, 0, SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0, SOURCE.IsAltPart, SOURCE.AltPartMasterPartId);
							END

							--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
							UPDATE #tmpWorkOrderMaterialStockline
							SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
							FROM #tmpWorkOrderMaterialStockline WOMS JOIN #tmpAutoReserveWOMMaterialsAlt tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId 
							WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 

							--FOR UPDATED WORKORDER MATERIALS QTY
							UPDATE #tmpWorkOrderMaterials 
							SET Quantity = GropWOM.Quantity	
							FROM(
								SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, WOM.WorkOrderMaterialsId   
								FROM #tmpWorkOrderMaterials WOM 
								JOIN #tmpWorkOrderMaterialStockline WOMS ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId 
								WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
								GROUP BY WOM.WorkOrderMaterialsId
							) GropWOM WHERE GropWOM.WorkOrderMaterialsId = #tmpWorkOrderMaterials.WorkOrderMaterialsId AND ISNULL(GropWOM.Quantity,0) > ISNULL(#tmpWorkOrderMaterials.Quantity,0)			

							----FOR UPDATED STOCKLINE QTY
							UPDATE #Stockline
							SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) - ISNULL(tmpRSL.ActQuantity,0),
								QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(tmpRSL.ActQuantity,0),
								WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
							FROM #Stockline SL JOIN #tmpAutoReserveWOMMaterialsAlt tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
						END				
					END
					
					--#STEP : 3 RESERVE KIT EQUIVALENT PARTS 
					IF(ISNULL(@IncludeEquiv, 0) = 1)
					BEGIN
						IF OBJECT_ID(N'tempdb..#EquPartList') IS NOT NULL
						BEGIN
							DROP TABLE #EquPartList 
						END
			
						CREATE TABLE #EquPartList 
						(
							ID BIGINT NOT NULL IDENTITY, 
							[ItemMasterId] [bigint] NULL,
							[AltItemMasterId] [bigint] NULL
						)

						INSERT INTO #EquPartList 
						(WOM.[ItemMasterId], [AltItemMasterId])
						SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
						FROM #tmpWorkOrderMaterialsKit WOM WITH (NOLOCK)  
							LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND MappingType = 2 AND NhaTla.IsDeleted = 0 AND NhaTla.IsActive = 1
							LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId

						SELECT  WOM.WorkOrderId,
							WOM.WorkFlowWorkOrderId,
							WOM.WorkOrderMaterialsKitId,
							WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,	
							Equ.AltItemMasterId AS ItemMasterId,
							WOM.ItemMasterId AS EquPartMasterPartId,
							WOM.ConditionId AS ConditionId,
							C.GroupCode AS ConditionGroupCode,
							WOM.MasterCompanyId,
							WOM.Quantity,
							WOM.QuantityReserved,
							WOM.QuantityIssued,
							WOM.QtyOnOrder AS QuantityOnOrder,
							(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM #tmpWorkOrderMaterialStocklineKIT WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKITId = WOMSL.WorkOrderMaterialsKITId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
							WOM.UnitCost,
							WOM.ExtendedCost,
							WOM.TaskId,
							WOM.ProvisionId,
							IM.PartNumber,
							IM.PartDescription, 							
							P.Description AS Provision,
							P.StatusCode AS ProvisionStatusCode,
							CASE 
							WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
							WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
							WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
							ELSE 'OEM'
							END AS StockType,	
							@EmployeeId AS ReservedById,
							WOM.UpdatedBy AS ReservedBy,
							0 AS IsStocklineAdded,
							1 AS IsEquPart
						INTO #tmpAutoReserveIssueWOMaterialsStocklineKITEqu
						FROM #EquPartList Equ
							JOIN #tmpWorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.ItemMasterId = Equ.ItemMasterId
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Equ.AltItemMasterId
							JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionId
							JOIN dbo.WorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.WorkOrderMaterialsKitMappingId = WOM.WorkOrderMaterialsKitMappingId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOM.IsDeleted = 0  
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM #tmpWorkOrderMaterialStocklineKit WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = WOMSL.WorkOrderMaterialsKitId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)

						IF OBJECT_ID(N'tempdb..#tmpAutoReserveWOMaterialsStocklineKITEqu') IS NOT NULL
						BEGIN
						DROP TABLE #tmpAutoReserveWOMaterialsStocklineKITEqu
						END

						CREATE TABLE #tmpAutoReserveWOMaterialsStocklineKITEqu
									(
										 ID BIGINT NOT NULL IDENTITY, 
										 [WorkOrderId] BIGINT NULL,
										 [WorkFlowWorkOrderId] BIGINT NULL,
										 [WorkOrderMaterialsId] BIGINT NULL,
										 [StockLineId] BIGINT NULL,
										 [ItemMasterId] BIGINT NULL,
										 [EquPartMasterPartId] BIGINT NULL,										 
										 [ConditionId] BIGINT NULL,
										 [ProvisionId] BIGINT NULL,
										 [TaskId] BIGINT NULL,
										 [ReservedById] BIGINT NULL,
										 [Condition] VARCHAR(500) NULL,
										 [PartNumber] VARCHAR(500) NULL,
										 [PartDescription] VARCHAR(max) NULL,
										 [Quantity] INT NULL,
										 [QuantityAvailable] INT NULL,
										 [QuantityOnHand] INT NULL,
										 [ActQuantity] INT NULL,
										 [QtyToBeReserved] INT NULL,
										 [QuantityActReserved] INT NULL,
										 [ControlNo] VARCHAR(500) NULL,
										 [ControlId] VARCHAR(500) NULL,
										 [StockLineNumber] VARCHAR(500) NULL,
										 [SerialNumber] VARCHAR(500) NULL,
										 [ReservedBy] VARCHAR(500) NULL,						 
										 [IsStocklineAdded] BIT NULL,
										 [MasterCompanyId] BIGINT NULL,
										 [UpdatedBy] VARCHAR(500) NULL,
										 [UnitCost] DECIMAL(18,2),
										 [IsSerialized] BIT,
										 [IsEquPart] BIT,
										 [IsActive] BIT,
										 [IsDeleted] BIT,
										 [CreatedDate] DATETIME2 NULL,
									)

						INSERT INTO #tmpAutoReserveWOMaterialsStocklineKITEqu ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId],[EquPartMasterPartId],[ConditionId], [ProvisionId], 
								[TaskId], [ReservedById], [Condition], [PartNumber], [PartDescription], [Quantity],[QuantityAvailable],[QuantityOnHand], [ActQuantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
								[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UnitCost], [IsSerialized],[IsEquPart],[IsActive], [IsDeleted], [CreatedDate])
						SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], SL.StockLineId, tblMS.[ItemMasterId], tblMS.[EquPartMasterPartId], tblMS.[ConditionId], @ProvisionId, 
								[TaskId], [ReservedById], SL.Condition, tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], SL.QuantityAvailable, SL.QuantityOnHand, 0, [QtyToBeReserved], [QtyToBeReserved], SL.ControlNumber, SL.IdNumber,
								SL.StockLineNumber, SL.SerialNumber, [ReservedBy], [IsStocklineAdded], tblMS.MasterCompanyId, [ReservedBy], SL.UnitCost, NULL, tblMS.[IsEquPart], 1, 0, SL.CreatedDate
						FROM #tmpAutoReserveIssueWOMaterialsStocklineKITEqu tblMS JOIN dbo.Stockline SL ON SL.ItemMasterId = tblMS.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup tmpC WHERE tblMS.ConditionGroupCode = tmpC.ConditionGroup) 
						WHERE SL.QuantityAvailable > 0 
						AND SL.IsParent = 1 
						AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
						ORDER BY SL.CreatedDate

						INSERT INTO #Stockline
						SELECT SL.*
						FROM dbo.Stockline SL WITH(NOLOCK) 
						JOIN #tmpAutoReserveWOMaterialsStocklineKITEqu WOM ON SL.[StockLineId] = WOM.StockLineId
						WHERE WOM.StockLineId NOT IN (SELECT StockLineId FROM #Stockline)

						SET @ARcount = 1;
						SET @ARTotalCounts = 0;
						SET @tmpActQuantity = 0;
						SET @QtytToRes = 0;
						SET @NewWorkOrderMaterialsId = 0;
						SET @NewStockline = 0;

						SELECT @ARTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMaterialsStocklineKITEqu;

						WHILE @ARcount<= @ARTotalCounts
						BEGIN						 
							SELECT @NewWorkOrderMaterialsId = WorkOrderMaterialsId, @NewStockline = StockLineId FROM #tmpAutoReserveWOMaterialsStocklineKITEqu WHERE ID = @ARcount

							SELECT @tmpActQuantity = SUM(ISNULL(ActQuantity, 0)), @QtytToRes = MAX(ISNULL(QtyToBeReserved, 0)) - SUM(ISNULL(ActQuantity, 0))
							FROM #tmpAutoReserveWOMaterialsStocklineKITEqu
							WHERE WorkOrderMaterialsId = @NewWorkOrderMaterialsId
							GROUP BY WorkOrderMaterialsId

							IF(@QtytToRes > 0)
							BEGIN
								UPDATE #tmpAutoReserveWOMaterialsStocklineKITEqu
								SET ActQuantity = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN ISNULL(QuantityAvailable, 0) ELSE @QtytToRes END,
									IsActive = 1, IsStocklineAdded = 1
								FROM #tmpAutoReserveWOMaterialsStocklineKITEqu tmpWOM
								WHERE tmpWOM.ID = @ARcount AND ISNULL(QuantityAvailable, 0) > 0 AND ISNULL(IsStocklineAdded, 0) = 0 

								UPDATE #tmpAutoReserveWOMaterialsStocklineKITEqu
								SET QuantityAvailable = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN 0 ELSE ISNULL(QuantityAvailable, 0) - @QtytToRes END								
								FROM #tmpAutoReserveWOMaterialsStocklineKITEqu tmpWOM
								WHERE tmpWOM.StockLineId = @NewStockline  AND ISNULL(QuantityAvailable, 0) > 0
							END
					
							SET @ARcount = @ARcount + 1;
						END;

						DELETE FROM #tmpAutoReserveWOMaterialsStocklineKITEqu WHERE IsStocklineAdded != 1

						SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row_Num, * INTO #tmpAutoReserveWOMKITEqu FROM #tmpAutoReserveWOMaterialsStocklineKITEqu

						IF((SELECT COUNT(1) FROM #tmpAutoReserveWOMKITEqu) > 0)
						BEGIN
							SET @Autocount = 0;
							SET @Materialscount = 0;
							SET @Autoslcount = 0;
							SET @AutoTotalCounts = 0;

							SET @Autoslcount = 1;
							SET @Autocount = 1;
							SET @Materialscount = 1;

							SELECT @AutoTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMKITEqu;
		
							--UPDATE WORK ORDER MATERIALS DETAILS
							WHILE @Autocount<= @AutoTotalCounts
							BEGIN
								UPDATE #tmpWorkOrderMaterialsKit 
									SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
										TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
										ReservedById = tmpWOM.ReservedById, 
										ReservedDate = GETDATE(), 
										UpdatedDate = GETDATE(),
										PartStatusId = @ReservePartStatus
								FROM #tmpWorkOrderMaterialsKit WOM JOIN #tmpAutoReserveWOMKITEqu tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKITId AND tmpWOM.Row_Num = @Autocount
								SET @Autocount = @Autocount + 1;
							END;

							--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
							IF(@AutoTotalCounts > 0 )
							BEGIN
								MERGE #tmpWorkOrderMaterialStockLineKit AS TARGET
								USING #tmpAutoReserveWOMKITEqu AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.WorkOrderMaterialsId = TARGET.WorkOrderMaterialsKITId) -- TARGET.ItemMasterId = SOURCE.ItemMasterId AND TARGET.ConditionId = SOURCE.ConditionId) 
								--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
								WHEN MATCHED 				
									THEN UPDATE 						
									SET TARGET.QtyReserved = ISNULL(TARGET.QtyReserved, 0) + ISNULL(SOURCE.ActQuantity, 0),
										TARGET.UnitCost = SOURCE.UnitCost,
										TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
										TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
										TARGET.UpdatedDate = GETDATE(),
										TARGET.IsEquPart = SOURCE.IsEquPart,
										TARGET.EquPartMasterPartId = SOURCE.EquPartMasterPartId,
										TARGET.UpdatedBy = SOURCE.ReservedBy
								WHEN NOT MATCHED BY TARGET 
									THEN INSERT (StocklineId, WorkOrderMaterialsKITId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted, IsEquPart , EquPartMasterPartId) 
									VALUES (SOURCE.StocklineId, SOURCE.WorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.ActQuantity, SOURCE.ActQuantity, 0, SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0, SOURCE.IsEquPart , SOURCE.EquPartMasterPartId);
							END

							--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
							UPDATE #tmpWorkOrderMaterialStockLineKit 
							SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
							FROM #tmpWorkOrderMaterialStockLineKit WOMS JOIN #tmpAutoReserveWOMKITEqu tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsKITId = tmpRSL.WorkOrderMaterialsId 
							WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 

							--FOR UPDATED WORKORDER MATERIALS QTY
							UPDATE #tmpWorkOrderMaterialsKit 
							SET Quantity = GropWOM.Quantity	
							FROM(
								SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, WOM.WorkOrderMaterialsKITId AS WorkOrderMaterialsId
								FROM #tmpWorkOrderMaterialsKit WOM 
								JOIN #tmpWorkOrderMaterialStockLineKit WOMS ON WOMS.WorkOrderMaterialsKITId = WOM.WorkOrderMaterialsKITId 
								WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
								GROUP BY WOM.WorkOrderMaterialsKITId
							) GropWOM WHERE GropWOM.WorkOrderMaterialsId = #tmpWorkOrderMaterialsKit.WorkOrderMaterialsKITId AND ISNULL(GropWOM.Quantity,0) > ISNULL(#tmpWorkOrderMaterialsKit.Quantity,0)			

							----FOR UPDATED STOCKLINE QTY
							UPDATE #Stockline
							SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) - ISNULL(tmpRSL.ActQuantity,0),
								QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(tmpRSL.ActQuantity,0),
								WorkOrderMaterialsKitId = tmpRSL.WorkOrderMaterialsId
							FROM #Stockline SL JOIN #tmpAutoReserveWOMKITEqu tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
						END
					END
					
					--#STEP : 3.1 RESERVE MATERIALS EQUIVALENT PARTS 
					IF(ISNULL(@IncludeEquiv, 0) = 1)
					BEGIN
						IF OBJECT_ID(N'tempdb..#MaterialsEquPartList') IS NOT NULL
						BEGIN
							DROP TABLE #MaterialsEquPartList 
						END
			
						CREATE TABLE #MaterialsEquPartList 
						(
							ID BIGINT NOT NULL IDENTITY, 
							[ItemMasterId] [bigint] NULL,
							[AltItemMasterId] [bigint] NULL
						)

						INSERT INTO #MaterialsEquPartList 
						(WOM.[ItemMasterId], [AltItemMasterId])
						SELECT DISTINCT NhaTla.[ItemMasterId], NhaTla.MappingItemMasterId
						FROM #tmpWorkOrderMaterials WOM WITH (NOLOCK)  
							LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping AS NhaTla WITH (NOLOCK) ON NhaTla.ItemMasterId = WOM.ItemMasterId AND MappingType = 2 AND NhaTla.IsDeleted = 0 AND NhaTla.IsActive = 1
							LEFT JOIN dbo.ItemMaster IM_NhaTla WITH (NOLOCK) ON IM_NhaTla.ItemMasterId = NhaTla.MappingItemMasterId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId

						SELECT  WOM.WorkOrderId,
							WOM.WorkFlowWorkOrderId,
							WOM.WorkOrderMaterialsId,						
							Equ.AltItemMasterId AS ItemMasterId,
							WOM.ItemMasterId AS EquPartMasterPartId,
							WOM.ConditionId AS ConditionId,
							C.GroupCode AS ConditionGroupCode,
							WOM.MasterCompanyId,
							WOM.Quantity,
							WOM.QuantityReserved,
							WOM.QuantityIssued,
							WOM.QtyOnOrder AS QuantityOnOrder,
							(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM #tmpWorkOrderMaterialStockline WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
							WOM.UnitCost,
							WOM.ExtendedCost,
							WOM.TaskId,
							WOM.ProvisionId,
							IM.PartNumber,
							IM.PartDescription, 							
							P.Description AS Provision,
							P.StatusCode AS ProvisionStatusCode,
							CASE 
							WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
							WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
							WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
							ELSE 'OEM'
							END AS StockType,	
							@EmployeeId AS ReservedById,
							WOM.UpdatedBy AS ReservedBy,
							0 AS IsStocklineAdded,
							1 AS IsEquPart
						INTO #tmpAutoReserveIssueWOMaterialsStocklineMaterialsEqu
						FROM #MaterialsEquPartList Equ
							JOIN #tmpWorkOrderMaterials WOM WITH (NOLOCK) ON WOM.ItemMasterId = Equ.ItemMasterId
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = Equ.AltItemMasterId
							JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId							
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND  WOM.IsDeleted = 0  
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM #tmpWorkOrderMaterialStockline WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)

						IF OBJECT_ID(N'tempdb..#tmpAutoReserveWOMaterialsStocklineMaterialsEqu') IS NOT NULL
						BEGIN
						DROP TABLE #tmpAutoReserveWOMaterialsStocklineMaterialsEqu
						END
			
						CREATE TABLE #tmpAutoReserveWOMaterialsStocklineMaterialsEqu
								(
									 ID BIGINT NOT NULL IDENTITY, 
									 [WorkOrderId] BIGINT NULL,
									 [WorkFlowWorkOrderId] BIGINT NULL,
									 [WorkOrderMaterialsId] BIGINT NULL,
									 [StockLineId] BIGINT NULL,
									 [ItemMasterId] BIGINT NULL,
									 [EquPartMasterPartId] BIGINT NULL,
									 [ConditionId] BIGINT NULL,
									 [ProvisionId] BIGINT NULL,
									 [TaskId] BIGINT NULL,
									 [ReservedById] BIGINT NULL,
									 [Condition] VARCHAR(500) NULL,
									 [PartNumber] VARCHAR(500) NULL,
									 [PartDescription] VARCHAR(max) NULL,
									 [Quantity] INT NULL,
									 [QuantityAvailable] INT NULL,
									 [QuantityOnHand] INT NULL,
									 [ActQuantity] INT NULL,
									 [QtyToBeReserved] INT NULL,
									 [QuantityActReserved] INT NULL,
									 [ControlNo] VARCHAR(500) NULL,
									 [ControlId] VARCHAR(500) NULL,
									 [StockLineNumber] VARCHAR(500) NULL,
									 [SerialNumber] VARCHAR(500) NULL,
									 [ReservedBy] VARCHAR(500) NULL,						 
									 [IsStocklineAdded] BIT NULL,
									 [MasterCompanyId] BIGINT NULL,
									 [UpdatedBy] VARCHAR(500) NULL,
									 [UnitCost] DECIMAL(18,2),
									 [IsSerialized] BIT,
									 [IsEquPart] BIT,
									 [IsActive] BIT,
									 [IsDeleted] BIT,
									 [CreatedDate] DATETIME2 NULL,
								)

						INSERT INTO #tmpAutoReserveWOMaterialsStocklineMaterialsEqu ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId],[EquPartMasterPartId],[ConditionId], [ProvisionId], 
								[TaskId], [ReservedById], [Condition], [PartNumber], [PartDescription], [Quantity],[QuantityAvailable],[QuantityOnHand], [ActQuantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
								[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UnitCost], [IsSerialized],[IsEquPart], [IsActive], [IsDeleted], [CreatedDate])
						SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], SL.StockLineId, tblMS.[ItemMasterId],tblMS.[EquPartMasterPartId], tblMS.[ConditionId], @ProvisionId, 
								[TaskId], [ReservedById], SL.Condition, tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], SL.QuantityAvailable, SL.QuantityOnHand, 0, [QtyToBeReserved], [QtyToBeReserved], SL.ControlNumber, SL.IdNumber,
								SL.StockLineNumber, SL.SerialNumber, [ReservedBy], [IsStocklineAdded], tblMS.MasterCompanyId, [ReservedBy], SL.UnitCost, NULL, tblMS.[IsEquPart],1, 0, SL.CreatedDate
						FROM #tmpAutoReserveIssueWOMaterialsStocklineMaterialsEqu tblMS  JOIN dbo.Stockline SL ON SL.ItemMasterId = tblMS.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup tmpC WHERE tblMS.ConditionGroupCode = tmpC.ConditionGroup) 
						WHERE SL.QuantityAvailable > 0 
						AND SL.IsParent = 1 
						AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
						ORDER BY SL.CreatedDate

						INSERT INTO #Stockline
						SELECT SL.*
						FROM dbo.Stockline SL WITH(NOLOCK) 
						JOIN #tmpAutoReserveWOMaterialsStocklineMaterialsEqu WOM ON SL.[StockLineId] = WOM.StockLineId
						WHERE WOM.StockLineId NOT IN (SELECT StockLineId FROM #Stockline)

						SET @ARcount = 1;
						SET @ARTotalCounts = 0;
						SET @tmpActQuantity = 0;
						SET @QtytToRes = 0;
						SET @NewWorkOrderMaterialsId = 0;
						SET @NewStockline = 0;

						SELECT @ARTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMaterialsStocklineMaterialsEqu ;

						WHILE @ARcount<= @ARTotalCounts
						BEGIN		
							SELECT @NewWorkOrderMaterialsId = WorkOrderMaterialsId, @NewStockline = StockLineId FROM #tmpAutoReserveWOMaterialsStocklineMaterialsEqu WHERE ID = @ARcount

							SELECT @tmpActQuantity = SUM(ISNULL(ActQuantity, 0)), @QtytToRes = MAX(ISNULL(QtyToBeReserved, 0)) - SUM(ISNULL(ActQuantity, 0))
							FROM #tmpAutoReserveWOMaterialsStocklineMaterialsEqu 
							WHERE WorkOrderMaterialsId = @NewWorkOrderMaterialsId
							GROUP BY WorkOrderMaterialsId

							IF(@QtytToRes > 0)
							BEGIN
								UPDATE #tmpAutoReserveWOMaterialsStocklineMaterialsEqu 
								SET ActQuantity = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN ISNULL(QuantityAvailable, 0) ELSE @QtytToRes END,
									IsActive = 1, IsStocklineAdded = 1
								FROM #tmpAutoReserveWOMaterialsStocklineMaterialsEqu tmpWOM
								WHERE tmpWOM.ID = @ARcount AND ISNULL(QuantityAvailable, 0) > 0 AND ISNULL(IsStocklineAdded, 0) = 0 

								UPDATE #tmpAutoReserveWOMaterialsStocklineMaterialsEqu
								SET QuantityAvailable = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN 0 ELSE ISNULL(QuantityAvailable, 0) - @QtytToRes END								
								FROM #tmpAutoReserveWOMaterialsStocklineMaterialsEqu tmpWOM
								WHERE tmpWOM.StockLineId = @NewStockline  AND ISNULL(QuantityAvailable, 0) > 0
							END
					
							SET @ARcount = @ARcount + 1;
						END;

						DELETE FROM #tmpAutoReserveWOMaterialsStocklineMaterialsEqu WHERE IsStocklineAdded != 1

						SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row_Num, * INTO #tmpAutoReserveWOMMaterialsEqu FROM #tmpAutoReserveWOMaterialsStocklineMaterialsEqu

						IF((SELECT COUNT(1) FROM #tmpAutoReserveWOMMaterialsEqu) > 0)
						BEGIN
							SET @Autoslcount = 1;
							SET @Autocount = 1;
							SET @Materialscount = 1;

							SELECT @AutoTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMMaterialsEqu;
		
							--UPDATE WORK ORDER MATERIALS DETAILS
							WHILE @Autocount<= @AutoTotalCounts
							BEGIN
								UPDATE #tmpWorkOrderMaterials 
									SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
										TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
										ReservedById = tmpWOM.ReservedById, 
										ReservedDate = GETDATE(), 
										UpdatedDate = GETDATE(),
										PartStatusId = @ReservePartStatus
								FROM #tmpWorkOrderMaterials WOM JOIN #tmpAutoReserveWOMMaterialsEqu tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.Row_Num = @Autocount
								SET @Autocount = @Autocount + 1;
							END;

							--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
							IF(@AutoTotalCounts > 0 )
							BEGIN
								MERGE #tmpWorkOrderMaterialStockline AS TARGET
								USING #tmpAutoReserveWOMMaterialsEqu AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.WorkOrderMaterialsId = TARGET.WorkOrderMaterialsId) -- TARGET.ItemMasterId = SOURCE.ItemMasterId AND TARGET.ConditionId = SOURCE.ConditionId) 
								--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
								WHEN MATCHED 				
									THEN UPDATE 						
									SET TARGET.QtyReserved = ISNULL(TARGET.QtyReserved, 0) + ISNULL(SOURCE.ActQuantity, 0),
										TARGET.UnitCost = SOURCE.UnitCost,
										TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
										TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
										TARGET.UpdatedDate = GETDATE(),
										TARGET.IsEquPart = SOURCE.IsEquPart,
										TARGET.EquPartMasterPartId = SOURCE.EquPartMasterPartId,
										TARGET.UpdatedBy = SOURCE.ReservedBy
								WHEN NOT MATCHED BY TARGET 
									THEN INSERT (StocklineId, WorkOrderMaterialsId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted, IsEquPart, EquPartMasterPartId) 
									VALUES (SOURCE.StocklineId, SOURCE.WorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.ActQuantity, SOURCE.ActQuantity, 0, SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0, SOURCE.IsEquPart, SOURCE.EquPartMasterPartId);
							END

							--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
							UPDATE #tmpWorkOrderMaterialStockline
							SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
							FROM #tmpWorkOrderMaterialStockline WOMS JOIN #tmpAutoReserveWOMMaterialsEqu tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId 
							WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 

							--FOR UPDATED WORKORDER MATERIALS QTY
							UPDATE #tmpWorkOrderMaterials
							SET Quantity = GropWOM.Quantity	
							FROM(
								SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, WOM.WorkOrderMaterialsId   
								FROM #tmpWorkOrderMaterials WOM 
								JOIN #tmpWorkOrderMaterialStockline WOMS ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId 
								WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
								GROUP BY WOM.WorkOrderMaterialsId
							) GropWOM WHERE GropWOM.WorkOrderMaterialsId = #tmpWorkOrderMaterials.WorkOrderMaterialsId AND ISNULL(GropWOM.Quantity,0) > ISNULL(#tmpWorkOrderMaterials.Quantity,0)			

							--FOR UPDATED STOCKLINE QTY
							UPDATE #Stockline
							SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) - ISNULL(tmpRSL.ActQuantity,0),
								QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(tmpRSL.ActQuantity,0),
								WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
							FROM #Stockline SL JOIN #tmpAutoReserveWOMMaterialsEqu tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
							
						END				
					END
					
					--#STEP : 4 RESERVE NEW STOCKLINE
					SELECT  WOM.WorkOrderId,
							WOM.WorkFlowWorkOrderId,
							WOM.WorkOrderMaterialsId,						
							WOM.ItemMasterId,
							WOM.ConditionId AS ConditionId,
							C.GroupCode AS ConditionGroupCode,
							WOM.MasterCompanyId,
							WOM.Quantity,
							WOM.QuantityReserved,
							WOM.QuantityIssued,
							WOM.QtyOnOrder AS QuantityOnOrder,
							(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM #tmpWorkOrderMaterialStockline WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
							WOM.UnitCost,
							WOM.ExtendedCost,
							WOM.TaskId,
							WOM.ProvisionId,
							IM.PartNumber,
							IM.PartDescription, 							
							P.Description AS Provision,
							P.StatusCode AS ProvisionStatusCode,
							CASE 
							WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
							WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
							WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
							ELSE 'OEM'
							END AS StockType,	
							@EmployeeId AS ReservedById,
							WOM.UpdatedBy AS ReservedBy,
							0 AS IsStocklineAdded	
						INTO #tmpAutoReserveIssueWOMaterialsStockline
						FROM #tmpWorkOrderMaterials WOM WITH (NOLOCK)  
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
							JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId							
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND  WOM.IsDeleted = 0  
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM #tmpWorkOrderMaterialStockline WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
					
					IF OBJECT_ID(N'tempdb..#tmpAutoReserveWOMaterialsStockline') IS NOT NULL
					BEGIN
					DROP TABLE #tmpAutoReserveWOMaterialsStockline
					END

					--SELECT * FROM #tmpAutoReserveIssueWOMaterialsStockline
					--SELECT Condition, ConditionId, * FROM #Stockline
			
					CREATE TABLE #tmpAutoReserveWOMaterialsStockline
								(
									 ID BIGINT NOT NULL IDENTITY, 
									 [WorkOrderId] BIGINT NULL,
									 [WorkFlowWorkOrderId] BIGINT NULL,
									 [WorkOrderMaterialsId] BIGINT NULL,
									 [StockLineId] BIGINT NULL,
									 [ItemMasterId] BIGINT NULL,
									 [ConditionId] BIGINT NULL,
									 [ProvisionId] BIGINT NULL,
									 [TaskId] BIGINT NULL,
									 [ReservedById] BIGINT NULL,
									 [Condition] VARCHAR(500) NULL,
									 [PartNumber] VARCHAR(500) NULL,
									 [PartDescription] VARCHAR(max) NULL,
									 [Quantity] INT NULL,
									 [QuantityAvailable] INT NULL,
									 [QuantityOnHand] INT NULL,
									 [ActQuantity] INT NULL,
									 [QtyToBeReserved] INT NULL,
									 [QuantityActReserved] INT NULL,
									 [ControlNo] VARCHAR(500) NULL,
									 [ControlId] VARCHAR(500) NULL,
									 [StockLineNumber] VARCHAR(500) NULL,
									 [SerialNumber] VARCHAR(500) NULL,
									 [ReservedBy] VARCHAR(500) NULL,						 
									 [IsStocklineAdded] BIT NULL,
									 [MasterCompanyId] BIGINT NULL,
									 [UpdatedBy] VARCHAR(500) NULL,
									 [UnitCost] DECIMAL(18,2),
									 [IsSerialized] BIT,
									 [IsActive] BIT,
									 [IsDeleted] BIT,
									 [CreatedDate] DATETIME2 NULL,
									 [ConditionGroupCode] VARCHAR(50) NULL,
								)

					INSERT INTO #tmpAutoReserveWOMaterialsStockline ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
							[TaskId], [ReservedById], [Condition], [PartNumber], [PartDescription], [Quantity],[QuantityAvailable],[QuantityOnHand], [ActQuantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
							[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UnitCost], [IsSerialized],[IsActive], [IsDeleted], [CreatedDate],[ConditionGroupCode])
					SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], SL.StockLineId, tblMS.[ItemMasterId], SL.ConditionId,  @ProvisionId, --tblMS.[ConditionId],
							[TaskId], [ReservedById], SL.Condition, tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], SL.QuantityAvailable, SL.QuantityOnHand, 0, [QtyToBeReserved], [QtyToBeReserved], SL.ControlNumber, SL.IdNumber,
							SL.StockLineNumber, SL.SerialNumber, [ReservedBy], [IsStocklineAdded], tblMS.MasterCompanyId, [ReservedBy], SL.UnitCost, NULL, 1, 0, SL.CreatedDate, ConditionGroupCode
					FROM #tmpAutoReserveIssueWOMaterialsStockline tblMS  JOIN #Stockline SL ON SL.ItemMasterId = tblMS.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup tmpC WHERE tmpC.ConditionGroup = tblMS.ConditionGroupCode)
					WHERE SL.QuantityAvailable > 0 
					AND SL.IsParent = 1 
					AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
					ORDER BY SL.CreatedDate

					--SELECT * FROM #tmpAutoReserveWOMaterialsStockline
									
					SET @ARcount = 1;
					SET @ARTotalCounts = 0;
					SET @tmpActQuantity = 0;
					SET @QtytToRes = 0;
					SET @NewWorkOrderMaterialsId = 0;
					SET @NewStockline = 0;

					SELECT @ARTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMaterialsStockline ;

					WHILE @ARcount<= @ARTotalCounts
					BEGIN						 
						SELECT @NewWorkOrderMaterialsId = WorkOrderMaterialsId, @NewStockline = StockLineId FROM #tmpAutoReserveWOMaterialsStockline WHERE ID = @ARcount

						SELECT @tmpActQuantity = SUM(ISNULL(ActQuantity, 0)), @QtytToRes = MAX(ISNULL(QtyToBeReserved, 0)) - SUM(ISNULL(ActQuantity, 0))
						FROM #tmpAutoReserveWOMaterialsStockline 
						WHERE WorkOrderMaterialsId = @NewWorkOrderMaterialsId
						GROUP BY WorkOrderMaterialsId

						IF(@QtytToRes > 0)
						BEGIN
							UPDATE #tmpAutoReserveWOMaterialsStockline 
							SET ActQuantity = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN ISNULL(QuantityAvailable, 0) ELSE @QtytToRes END,
								IsActive = 1, IsStocklineAdded = 1
							FROM #tmpAutoReserveWOMaterialsStockline tmpWOM
							WHERE tmpWOM.ID = @ARcount AND ISNULL(QuantityAvailable, 0) > 0 AND ISNULL(IsStocklineAdded, 0) = 0 

							UPDATE #tmpAutoReserveWOMaterialsStockline
							SET QuantityAvailable = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN 0 ELSE ISNULL(QuantityAvailable, 0) - @QtytToRes END								
							FROM #tmpAutoReserveWOMaterialsStockline tmpWOM
							WHERE tmpWOM.StockLineId = @NewStockline  AND ISNULL(QuantityAvailable, 0) > 0
						END
					
						SET @ARcount = @ARcount + 1;
					END;

					DELETE FROM #tmpAutoReserveWOMaterialsStockline WHERE IsStocklineAdded != 1

					SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row_Num, * INTO #tmpAutoReserveWOM FROM #tmpAutoReserveWOMaterialsStockline

					--SELECT * FROM #tmpAutoReserveWOM

					IF((SELECT COUNT(1) FROM #tmpAutoReserveWOM) > 0)
					BEGIN

						SET @Autoslcount = 1;
						SET @Autocount = 1;
						SET @Materialscount = 1;

						SELECT @AutoTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOM;
		
						--UPDATE WORK ORDER MATERIALS DETAILS
						WHILE @Autocount<= @AutoTotalCounts
						BEGIN
							UPDATE #tmpWorkOrderMaterials 
								SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
									TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
									ReservedById = tmpWOM.ReservedById, 
									ReservedDate = GETDATE(), 
									UpdatedDate = GETDATE(),
									PartStatusId = @ReservePartStatus
							FROM #tmpWorkOrderMaterials WOM JOIN #tmpAutoReserveWOM tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.Row_Num = @Autocount
							SET @Autocount = @Autocount + 1;
						END;

						--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
						IF(@AutoTotalCounts > 0 )
						BEGIN
							MERGE #tmpWorkOrderMaterialStockline AS TARGET
							USING #tmpAutoReserveWOM AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.WorkOrderMaterialsId = TARGET.WorkOrderMaterialsId) -- TARGET.ItemMasterId = SOURCE.ItemMasterId AND TARGET.ConditionId = SOURCE.ConditionId) 
							--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
							WHEN MATCHED 				
								THEN UPDATE 						
								SET TARGET.QtyReserved = ISNULL(TARGET.QtyReserved, 0) + ISNULL(SOURCE.ActQuantity, 0),
									TARGET.UnitCost = SOURCE.UnitCost,
									TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
									TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
									TARGET.UpdatedDate = GETDATE(),
									TARGET.UpdatedBy = SOURCE.ReservedBy
							WHEN NOT MATCHED BY TARGET 
								THEN INSERT (StocklineId, WorkOrderMaterialsId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
								VALUES (SOURCE.StocklineId, SOURCE.WorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.ActQuantity, SOURCE.ActQuantity, 0, SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0);
						END

						--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
						UPDATE #tmpWorkOrderMaterialStockline 
						SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
						FROM #tmpWorkOrderMaterialStockline WOMS JOIN #tmpAutoReserveWOM tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId 
						WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 

						--FOR UPDATED WORKORDER MATERIALS QTY
						UPDATE #tmpWorkOrderMaterials
						SET Quantity = GropWOM.Quantity	
						FROM(
							SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, WOM.WorkOrderMaterialsId   
							FROM #tmpWorkOrderMaterials WOM 
							JOIN #tmpWorkOrderMaterialStockline WOMS ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId 
							WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
							GROUP BY WOM.WorkOrderMaterialsId
						) GropWOM WHERE GropWOM.WorkOrderMaterialsId = #tmpWorkOrderMaterials.WorkOrderMaterialsId AND ISNULL(GropWOM.Quantity,0) > ISNULL(#tmpWorkOrderMaterials.Quantity,0)			

						--FOR UPDATED STOCKLINE QTY
						UPDATE #Stockline
						SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) - ISNULL(tmpRSL.ActQuantity,0),
							QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(tmpRSL.ActQuantity,0),
							WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
						FROM #Stockline SL JOIN #tmpAutoReserveWOM tmpRSL ON SL.StockLineId = tmpRSL.StockLineId

						--Select * from #tmpWorkOrderMaterials
						--Select * from #tmpWorkOrderMaterialStockline
						--Select * from #Stockline

					END
					
					--#STEP : 5 RESERVE NEW STOCKLINE KIT MATERIALS
					SELECT  WOM.WorkOrderId,
							WOM.WorkFlowWorkOrderId,
							WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,						
							WOM.ItemMasterId,
							WOM.ConditionId AS ConditionId,
							C.GroupCode AS ConditionGroupCode,
							WOM.MasterCompanyId,
							WOM.Quantity,
							WOM.QuantityReserved,
							WOM.QuantityIssued,
							WOM.QtyOnOrder AS QuantityOnOrder,
							(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM #tmpWorkOrderMaterialStocklineKIT WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKITId = WOMSL.WorkOrderMaterialsKITId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
							WOM.UnitCost,
							WOM.ExtendedCost,
							WOM.TaskId,
							WOM.ProvisionId,
							IM.PartNumber,
							IM.PartDescription, 							
							P.Description AS Provision,
							P.StatusCode AS ProvisionStatusCode,
							CASE 
							WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
							WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
							WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
							ELSE 'OEM'
							END AS StockType,		
							@EmployeeId AS ReservedById,
							WOM.UpdatedBy AS ReservedBy,
							0 AS IsStocklineAdded	
						INTO #tmpAutoReserveIssueWOMaterialsStocklineKIT
						FROM #tmpWorkOrderMaterialsKit WOM WITH (NOLOCK)  
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
							JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId							
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND  WOM.IsDeleted = 0  
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM #tmpWorkOrderMaterialStocklineKIT WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsKITId = WOMSL.WorkOrderMaterialsKITId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
					
					IF OBJECT_ID(N'tempdb..#tmpAutoReserveWOMaterialsStocklineKIT') IS NOT NULL
					BEGIN
					DROP TABLE #tmpAutoReserveWOMaterialsStocklineKIT
					END
			
					CREATE TABLE #tmpAutoReserveWOMaterialsStocklineKIT
								(
									 ID BIGINT NOT NULL IDENTITY, 
									 [WorkOrderId] BIGINT NULL,
									 [WorkFlowWorkOrderId] BIGINT NULL,
									 [WorkOrderMaterialsId] BIGINT NULL,
									 [StockLineId] BIGINT NULL,
									 [ItemMasterId] BIGINT NULL,
									 [ConditionId] BIGINT NULL,
									 [ProvisionId] BIGINT NULL,
									 [TaskId] BIGINT NULL,
									 [ReservedById] BIGINT NULL,
									 [Condition] VARCHAR(500) NULL,
									 [PartNumber] VARCHAR(500) NULL,
									 [PartDescription] VARCHAR(max) NULL,
									 [Quantity] INT NULL,
									 [QuantityAvailable] INT NULL,
									 [QuantityOnHand] INT NULL,
									 [ActQuantity] INT NULL,
									 [QtyToBeReserved] INT NULL,
									 [QuantityActReserved] INT NULL,
									 [ControlNo] VARCHAR(500) NULL,
									 [ControlId] VARCHAR(500) NULL,
									 [StockLineNumber] VARCHAR(500) NULL,
									 [SerialNumber] VARCHAR(500) NULL,
									 [ReservedBy] VARCHAR(500) NULL,						 
									 [IsStocklineAdded] BIT NULL,
									 [MasterCompanyId] BIGINT NULL,
									 [UpdatedBy] VARCHAR(500) NULL,
									 [UnitCost] DECIMAL(18,2),
									 [IsSerialized] BIT,
									 [IsActive] BIT,
									 [IsDeleted] BIT,
									 [CreatedDate] DATETIME2 NULL,
									 [ConditionGroupCode] VARCHAR(50) NULL,
								)

					INSERT INTO #tmpAutoReserveWOMaterialsStocklineKIT ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
							[TaskId], [ReservedById], [Condition], [PartNumber], [PartDescription], [Quantity],[QuantityAvailable],[QuantityOnHand], [ActQuantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
							[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UnitCost], [IsSerialized],[IsActive], [IsDeleted], [CreatedDate], [ConditionGroupCode])
					SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], SL.StockLineId, tblMS.[ItemMasterId], tblMS.[ConditionId], @ProvisionId, 
							[TaskId], [ReservedById], SL.Condition, tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], SL.QuantityAvailable, SL.QuantityOnHand, 0, [QtyToBeReserved], [QtyToBeReserved], SL.ControlNumber, SL.IdNumber,
							SL.StockLineNumber, SL.SerialNumber, [ReservedBy], [IsStocklineAdded], tblMS.MasterCompanyId, [ReservedBy], SL.UnitCost, NULL, 1, 0, SL.CreatedDate, [ConditionGroupCode]
					FROM #tmpAutoReserveIssueWOMaterialsStocklineKIT tblMS  JOIN #Stockline SL ON SL.ItemMasterId = tblMS.ItemMasterId AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup tmpC WHERE tmpC.ConditionGroup = tblMS.ConditionGroupCode)
					WHERE SL.QuantityAvailable > 0 
					AND SL.IsParent = 1 
					AND (sl.IsCustomerStock = 0 OR @IncludeCustomerStock = 1 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
					ORDER BY SL.CreatedDate

					SET @ARcount = 1;
					SET @ARTotalCounts = 0;
					SET @tmpActQuantity = 0;
					SET @QtytToRes = 0;
					SET @NewWorkOrderMaterialsId = 0;
					SET @NewStockline = 0;

					SELECT @ARTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMaterialsStocklineKIT;

					WHILE @ARcount<= @ARTotalCounts
					BEGIN						 
						SELECT @NewWorkOrderMaterialsId = WorkOrderMaterialsId, @NewStockline = StockLineId FROM #tmpAutoReserveWOMaterialsStocklineKIT WHERE ID = @ARcount

						SELECT @tmpActQuantity = SUM(ISNULL(ActQuantity, 0)), @QtytToRes = MAX(ISNULL(QtyToBeReserved, 0)) - SUM(ISNULL(ActQuantity, 0))
						FROM #tmpAutoReserveWOMaterialsStocklineKIT
						WHERE WorkOrderMaterialsId = @NewWorkOrderMaterialsId
						GROUP BY WorkOrderMaterialsId

						IF(@QtytToRes > 0)
						BEGIN
							UPDATE #tmpAutoReserveWOMaterialsStocklineKIT
							SET ActQuantity = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN ISNULL(QuantityAvailable, 0) ELSE @QtytToRes END,
								IsActive = 1, IsStocklineAdded = 1
							FROM #tmpAutoReserveWOMaterialsStocklineKIT tmpWOM
							WHERE tmpWOM.ID = @ARcount AND ISNULL(QuantityAvailable, 0) > 0 AND ISNULL(IsStocklineAdded, 0) = 0 

							UPDATE #tmpAutoReserveWOMaterialsStocklineKIT
							SET QuantityAvailable = CASE WHEN @QtytToRes >= ISNULL(QuantityAvailable, 0) THEN 0 ELSE ISNULL(QuantityAvailable, 0) - @QtytToRes END								
							FROM #tmpAutoReserveWOMaterialsStocklineKIT tmpWOM
							WHERE tmpWOM.StockLineId = @NewStockline  AND ISNULL(QuantityAvailable, 0) > 0
						END
					
						SET @ARcount = @ARcount + 1;
					END;

					DELETE FROM #tmpAutoReserveWOMaterialsStocklineKIT WHERE IsStocklineAdded != 1

					SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Row_Num, * INTO #tmpAutoReserveWOMKIT FROM #tmpAutoReserveWOMaterialsStocklineKIT

					IF((SELECT COUNT(1) FROM #tmpAutoReserveWOMKIT) > 0)
					BEGIN
						SET @Autocount = 0;
						SET @Materialscount = 0;
						SET @Autoslcount = 0;
						SET @AutoTotalCounts = 0;

						SET @Autoslcount = 1;
						SET @Autocount = 1;
						SET @Materialscount = 1;

						SELECT @AutoTotalCounts = COUNT(ID) FROM #tmpAutoReserveWOMKIT;
		
						--UPDATE WORK ORDER MATERIALS DETAILS
						WHILE @Autocount<= @AutoTotalCounts
						BEGIN
							UPDATE #tmpWorkOrderMaterialsKit 
								SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
									TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.ActQuantity,0),
									ReservedById = tmpWOM.ReservedById, 
									ReservedDate = GETDATE(), 
									UpdatedDate = GETDATE(),
									PartStatusId = @ReservePartStatus
							FROM #tmpWorkOrderMaterialsKit WOM JOIN #tmpAutoReserveWOMKIT tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKITId AND tmpWOM.Row_Num = @Autocount
							SET @Autocount = @Autocount + 1;
						END;

						--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
						IF(@AutoTotalCounts > 0 )
						BEGIN
							MERGE #tmpWorkOrderMaterialStockLineKit AS TARGET
							USING #tmpAutoReserveWOMKIT AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.WorkOrderMaterialsId = TARGET.WorkOrderMaterialsKITId) -- TARGET.ItemMasterId = SOURCE.ItemMasterId AND TARGET.ConditionId = SOURCE.ConditionId) 
							--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
							WHEN MATCHED 				
								THEN UPDATE 						
								SET TARGET.QtyReserved = ISNULL(TARGET.QtyReserved, 0) + ISNULL(SOURCE.ActQuantity, 0),
									TARGET.UnitCost = SOURCE.UnitCost,
									TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
									TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * SOURCE.UnitCost,
									TARGET.UpdatedDate = GETDATE(),
									TARGET.UpdatedBy = SOURCE.ReservedBy
							WHEN NOT MATCHED BY TARGET 
								THEN INSERT (StocklineId, WorkOrderMaterialsKITId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
								VALUES (SOURCE.StocklineId, SOURCE.WorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.ActQuantity, SOURCE.ActQuantity, 0, SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.ActQuantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0);
						END

						--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
						UPDATE #tmpWorkOrderMaterialStockLineKit 
						SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
						FROM #tmpWorkOrderMaterialStockLineKit WOMS JOIN #tmpAutoReserveWOMKIT tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsKITId = tmpRSL.WorkOrderMaterialsId 
						WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 

						--FOR UPDATED WORKORDER MATERIALS QTY
						UPDATE #tmpWorkOrderMaterialsKit 
						SET Quantity = GropWOM.Quantity	
						FROM(
							SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, WOM.WorkOrderMaterialsKITId AS WorkOrderMaterialsId
							FROM #tmpWorkOrderMaterialsKit WOM 
							JOIN #tmpWorkOrderMaterialStockLineKit WOMS ON WOMS.WorkOrderMaterialsKITId = WOM.WorkOrderMaterialsKITId 
							WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
							GROUP BY WOM.WorkOrderMaterialsKITId
						) GropWOM WHERE GropWOM.WorkOrderMaterialsId = #tmpWorkOrderMaterialsKit.WorkOrderMaterialsKITId AND ISNULL(GropWOM.Quantity,0) > ISNULL(#tmpWorkOrderMaterialsKit.Quantity,0)			

						--FOR UPDATED STOCKLINE QTY
						UPDATE #Stockline
						SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) - ISNULL(tmpRSL.ActQuantity,0),
							QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(tmpRSL.ActQuantity,0),
							WorkOrderMaterialsKitId = tmpRSL.WorkOrderMaterialsId
						FROM #Stockline SL JOIN #tmpAutoReserveWOMKIT tmpRSL ON SL.StockLineId = tmpRSL.StockLineId

					END

					IF OBJECT_ID(N'tempdb..#WorkOrderMaterials') IS NOT NULL
					BEGIN
					DROP TABLE #WorkOrderMaterials
					END
			
					CREATE TABLE #WorkOrderMaterials
							(
								 ID BIGINT NOT NULL IDENTITY, 
								 [WorkOrderMaterialsId] [bigint] NULL,
								 [WorkOrderMaterialsKITId] [bigint] NULL,
								 [WorkOrderMaterialsKitMappingId] [bigint] NULL,
								 [WorkOrderId] [bigint] NULL,
								 [WorkFlowWorkOrderId] [bigint] NULL,
								 [ItemMasterId] [bigint] NULL,
								 [ConditionId] [bigint] NULL,
								 [Quantity] [int] NULL,
								 [UnitCost] [decimal](20, 2) NULL,
								 [ExtendedCost] [decimal](20, 2) NULL,
								 [QuantityReserved] [int] NULL,
								 [QuantityIssued] [int] NULL,
								 [QuantityShort] [int] NULL,
								 [IsAltPart] [bit] NULL,
								 [AltPartMasterPartId] [bigint] NULL,
								 [PartStatusId] [int] NULL,
								 [UnReservedQty] [int] NULL,
								 [UnIssuedQty] [int] NULL,
								 [IssuedById] [bigint] NULL,
								 [ReservedById] [bigint] NULL,
								 [IsEquPart] [bit] NULL,
								 [ItemMappingId] [bigint] NULL,
								 [TotalReserved] [int] NULL,
								 [TotalIssued] [int] NULL,
								 [TotalUnReserved] [int] NULL,
								 [TotalUnIssued] [int] NULL,
								 [ProvisionId] [int] NULL,
								 [MaterialMandatoriesId] [int] NULL,
								 [WOPartNoId] [bigint] NULL,
								 [TotalStocklineQtyReq] [int] NULL,
								 [QtyOnOrder] [int] NULL,
								 [QtyOnBkOrder] [int] NULL,
								 [QtyToTurnIn] [int] NULL,
								 [Figure] [nvarchar](50) NULL,
								 [Item] [nvarchar](50) NULL,
								 [EquPartMasterPartId] [bigint] NULL,
								 [ReservedDate] [datetime2](7) NULL,
								 [UnitOfMeasureId] [bigint] NULL,
								 [TaskId] [bigint] NULL,

								 [WOMStockLineId] [bigint] NULL,
								 [StockLineId] [bigint] NULL,
								 [StkItemMasterId] [bigint] NULL,
								 [StkConditionId] [bigint] NULL,
								 [stkCondition] [nvarchar](50) NULL,
								 [StkQuantity] [int] NULL,
								 [QtyReserved] [int] NULL,
								 [QtyIssued] [int] NULL,			
								 [StkQuantityShort] [int] NULL,
								 [StkAltPartMasterPartId] [bigint] NULL,
								 [StkEquPartMasterPartId] [bigint] NULL,
								 [StkIsAltPart] [bit] NULL,
								 [StkIsEquPart] [bit] NULL,
								 [StkUnitCost] [decimal](20, 2) NULL,
								 [StkExtendedCost] [decimal](20, 2) NULL,								 
								 [stkProvisionId] [int] NULL,
								 [QuantityTurnIn] [int] NULL,
								 [stkFigure] [nvarchar](50) NULL,
								 [stkItem] [nvarchar](50) NULL,

								 [PartNumber] [nvarchar](200) NULL,
								 [StkPartNumber] [nvarchar](200) NULL,
								 [PartDesc] [nvarchar](Max) NULL,
								 [StkPartDesc] [nvarchar](Max) NULL,
								 [Condition] [nvarchar](50) NULL,								 
								 [SerialNo] [nvarchar](50) NULL,
								 [StocklineNo] [nvarchar](50) NULL,
								 [ControlNo] [nvarchar](50) NULL,
								 [ControlId] [nvarchar](50) NULL,
								 [UOM] [nvarchar](50) NULL,
								 [Priority] [nvarchar](10) NULL,
								 [QtyAvail] [int] NULL,
								 [QtyOH] [int] NULL,	
								 [Location] [nvarchar](50) NULL,
								 [Wherehouse] [nvarchar](50) NULL,
								 [IsMaterials] [bit] NULL,
							)

					INSERT INTO #WorkOrderMaterials
						   ([WorkOrderMaterialsId],[WorkOrderMaterialsKITId],[WorkOrderMaterialsKitMappingId], [WorkOrderId],[WorkFlowWorkOrderId], [ItemMasterId], [ConditionId] , [Quantity] , [UnitCost] , [ExtendedCost] , [QuantityReserved] , [QuantityIssued] , [IsAltPart] ,[AltPartMasterPartId] ,
						   [PartStatusId] , [UnReservedQty] ,  [UnIssuedQty] ,  [IssuedById] , [ReservedById] , [IsEquPart] , [ItemMappingId] ,  [TotalReserved] , [TotalIssued] ,[TotalUnReserved] ,
						   [TotalUnIssued] , [ProvisionId], [MaterialMandatoriesId], [WOPartNoId] , [TotalStocklineQtyReq],  [QtyOnOrder] , [QtyOnBkOrder] , [QtyToTurnIn] , [Figure] , [Item] , [EquPartMasterPartId], [ReservedDate], [UnitOfMeasureId], [TaskId],
						   [PartNumber], [PartDesc], [Condition], [UOM], [Priority], [IsMaterials])--, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted]) 
					SELECT [WorkOrderMaterialsId], NULL, NULL, [WorkOrderId],[WorkFlowWorkOrderId], WOM.[ItemMasterId], WOM.[ConditionId] , [Quantity] , WOM.[UnitCost] , [ExtendedCost] , [QuantityReserved] , [QuantityIssued] , [IsAltPart] ,[AltPartMasterPartId] ,
						   [PartStatusId] , [UnReservedQty] ,  [UnIssuedQty] ,  [IssuedById] , [ReservedById] , [IsEquPart] , [ItemMappingId] ,  [TotalReserved] , [TotalIssued] ,[TotalUnReserved] ,
						   [TotalUnIssued] , WOM.[ProvisionId], [MaterialMandatoriesId], [WOPartNoId] , [TotalStocklineQtyReq],  [QtyOnOrder] , [QtyOnBkOrder] , [QtyToTurnIn] , WOM.[Figure] , WOM.[Item] , [EquPartMasterPartId], [ReservedDate], [UnitOfMeasureId], [TaskId], --, WOM.[MasterCompanyId], WOM.[CreatedBy], WOM.[UpdatedBy], WOM.[CreatedDate], WOM.[UpdatedDate], WOM.[IsActive], WOM.[IsDeleted] 
						   [PartNumber], [PartDescription], CO.[Description], IM.[PurchaseUnitOfMeasure], [Priority], 1
					FROM #tmpWorkOrderMaterials WOM WITH (NOLOCK)
						JOIN dbo.ItemMaster IM ON IM.ItemMasterId = WOM.ItemMasterId
						LEFT JOIN dbo.Condition CO ON WOM.ConditionId = CO.ConditionId
					
					INSERT INTO #WorkOrderMaterials
						   ([WorkOrderMaterialsId],[WorkOrderMaterialsKITId],[WorkOrderMaterialsKitMappingId], [WorkOrderId],[WorkFlowWorkOrderId], [ItemMasterId], [ConditionId] , [Quantity] , [UnitCost] , [ExtendedCost] , [QuantityReserved] , [QuantityIssued] , [IsAltPart] ,[AltPartMasterPartId] ,
						   [PartStatusId] , [UnReservedQty] ,  [UnIssuedQty] ,  [IssuedById] , [ReservedById] , [IsEquPart] , [ItemMappingId] ,  [TotalReserved] , [TotalIssued] ,[TotalUnReserved] ,
						   [TotalUnIssued] , [ProvisionId], [MaterialMandatoriesId], [WOPartNoId] , [TotalStocklineQtyReq],  [QtyOnOrder] , [QtyOnBkOrder] , [QtyToTurnIn] , [Figure] , [Item] , [EquPartMasterPartId], [ReservedDate], [UnitOfMeasureId], [TaskId], --, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted]
						   [PartNumber], [PartDesc], [Condition], [UOM], [Priority], [IsMaterials]) 
					SELECT NULL,[WorkOrderMaterialsKITId],[WorkOrderMaterialsKitMappingId], [WorkOrderId],[WorkFlowWorkOrderId], WOM.[ItemMasterId], WOM.[ConditionId] , [Quantity] , WOM.[UnitCost] , [ExtendedCost] , [QuantityReserved] , [QuantityIssued] , [IsAltPart] ,[AltPartMasterPartId] ,
						   [PartStatusId] , [UnReservedQty] ,  [UnIssuedQty] ,  [IssuedById] , [ReservedById] , [IsEquPart] , [ItemMappingId] ,  [TotalReserved] , [TotalIssued] ,[TotalUnReserved] ,
						   [TotalUnIssued] , WOM.[ProvisionId], [MaterialMandatoriesId], [WOPartNoId] , [TotalStocklineQtyReq],  [QtyOnOrder] , [QtyOnBkOrder] , [QtyToTurnIn] , WOM.[Figure] , WOM.[Item] , [EquPartMasterPartId], [ReservedDate], [UnitOfMeasureId], [TaskId], --, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted] 
						   [PartNumber], [PartDescription], CO.[Description], IM.[PurchaseUnitOfMeasure], [Priority], 1
					FROM #tmpWorkOrderMaterialsKit WOM WITH (NOLOCK) 
						JOIN dbo.ItemMaster IM ON IM.ItemMasterId = WOM.ItemMasterId
						LEFT JOIN dbo.Condition CO ON WOM.ConditionId = CO.ConditionId

					--SELECT * FROM #tmpWorkOrderMaterialStockline
					--SELECT * FROM #Stockline
					INSERT INTO #WorkOrderMaterials
						([WOMStockLineId] ,[WorkOrderMaterialsId] ,[StockLineId] ,[StkItemMasterId] ,[StkConditionId] ,[StkQuantity] ,[QtyReserved] ,[QtyIssued] ,		
						[StkAltPartMasterPartId] ,[StkEquPartMasterPartId] ,[StkIsAltPart] ,[StkIsEquPart] ,[StkUnitCost] ,[StkExtendedCost] ,
						[StkProvisionId] ,[QuantityTurnIn] ,[StkFigure] ,[StkItem],[PartNumber], [PartDesc], [StkPartNumber], [StkPartDesc],[stkCondition], [UOM], [Priority],
						[WorkOrderId],[WorkFlowWorkOrderId], [ItemMasterId], [ConditionId] , [Quantity], [UnitCost] , [ExtendedCost] , [QuantityReserved] , [QuantityIssued],
						[SerialNo], [StocklineNo], [ControlNo], [ControlId], [QtyAvail], [QtyOH], [Location], [Wherehouse], [IsMaterials]) 
					SELECT [WOMStockLineId], WOMS.[WorkOrderMaterialsId] ,WOMS.[StockLineId] ,WOMS.[ItemMasterId] ,WOMS.[ConditionId] ,WOMS.[Quantity] ,WOMS.[QtyReserved] ,WOMS.[QtyIssued] ,		
						WOMS.[AltPartMasterPartId] ,WOMS.[EquPartMasterPartId] ,WOMS.[IsAltPart] ,WOMS.[IsEquPart] ,WOMS.[UnitCost] ,WOMS.[ExtendedCost] ,
						WOMS.[ProvisionId] ,WOMS.[QuantityTurnIn] ,WOMS.[Figure] ,WOMS.[Item], IMM.[PartNumber], IMM.[PartDescription], IMS.[PartNumber], IMS.[PartDescription],CO.[Description], IMS.[PurchaseUnitOfMeasure], IMS.[Priority],
						WOM.[WorkOrderId],[WorkFlowWorkOrderId], WOM.[ItemMasterId], WOM.[ConditionId] , WOM.[Quantity], WOM.[UnitCost] , WOM.[ExtendedCost] , WOM.[QuantityReserved] , WOM.[QuantityIssued],
						SL.[SerialNumber], SL.[StockLineNumber] , SL.[ControlNumber], SL.[IdNumber], SL.[QuantityAvailable], SL.[QuantityOnHand], [Location], [Warehouse], 0
					FROM #tmpWorkOrderMaterialStockline WOMS WITH (NOLOCK) 
						JOIN dbo.ItemMaster IMS ON IMS.ItemMasterId = WOMS.ItemMasterId
						JOIN #Stockline SL ON SL.StockLineId = WOMS.StockLineId
						LEFT JOIN dbo.Condition CO ON WOMS.ConditionId = CO.ConditionId
						LEFT JOIN #tmpWorkOrderMaterials WOM WITH (NOLOCK) ON WOM.WorkOrderMaterialsId  = WOMS.WorkOrderMaterialsId
						LEFT JOIN dbo.ItemMaster IMM ON IMM.ItemMasterId = WOM.ItemMasterId

					--SELECT * FROM #WorkOrderMaterials

					INSERT INTO #WorkOrderMaterials
						([WOMStockLineId] ,[WorkOrderMaterialsId] ,[WorkOrderMaterialsKITId], [StockLineId] ,[StkItemMasterId] ,[StkConditionId] ,[StkQuantity] ,[QtyReserved] ,[QtyIssued] ,		
						[StkAltPartMasterPartId] ,[StkEquPartMasterPartId] ,[StkIsAltPart] ,[StkIsEquPart] ,[StkUnitCost] ,[StkExtendedCost] ,
						[StkProvisionId] ,[QuantityTurnIn] ,[StkFigure] ,[StkItem], [PartNumber], [PartDesc],[StkPartNumber], [StkPartDesc], [stkCondition], [UOM], [Priority],
						[WorkOrderId],[WorkFlowWorkOrderId], [ItemMasterId], [ConditionId] , [Quantity], [UnitCost] , [ExtendedCost] , [QuantityReserved] , [QuantityIssued],
						[SerialNo], [StocklineNo], [ControlNo], [ControlId], [QtyAvail], [QtyOH], [Location], [Wherehouse], [IsMaterials])  --, [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
					SELECT [WorkOrderMaterialStockLineKitId] ,NULL,WOMS.[WorkOrderMaterialsKITId],WOMS.[StockLineId] ,WOMS.[ItemMasterId] ,WOMS.[ConditionId] ,WOMS.[Quantity] ,WOMS.[QtyReserved] ,WOMS.[QtyIssued] ,		
						WOMS.[AltPartMasterPartId] ,WOMS.[EquPartMasterPartId] ,WOMS.[IsAltPart] ,WOMS.[IsEquPart] ,WOMS.[UnitCost] ,WOMS.[ExtendedCost] ,
						WOMS.[ProvisionId] ,WOMS.[QuantityTurnIn] ,WOMS.[Figure] ,WOMS.[Item], IMM.[PartNumber], IMM.[PartDescription], IMS.[PartNumber], IMS.[PartDescription], CO.[Description], IMS.[PurchaseUnitOfMeasure], IMS.[Priority],
						WOM.[WorkOrderId],[WorkFlowWorkOrderId], WOM.[ItemMasterId], WOM.[ConditionId] , WOM.[Quantity], WOM.[UnitCost] , WOM.[ExtendedCost] , WOM.[QuantityReserved] , WOM.[QuantityIssued],
						SL.[SerialNumber], SL.[StockLineNumber] , SL.[ControlNumber], SL.[IdNumber], SL.[QuantityAvailable], SL.[QuantityOnHand], [Location], [Warehouse], 0--, WOMS.[MasterCompanyId], WOMS.[CreatedBy], WOMS.[UpdatedBy], WOMS.[CreatedDate], WOMS.[UpdatedDate], WOMS.[IsActive], WOMS.[IsDeleted]
					FROM #tmpWorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) 
						JOIN dbo.ItemMaster IMS ON IMS.ItemMasterId = WOMS.ItemMasterId
						JOIN #Stockline SL ON SL.StockLineId = WOMS.StockLineId
						LEFT JOIN dbo.Condition CO ON WOMS.ConditionId = CO.ConditionId
						LEFT JOIN #tmpWorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.WorkOrderMaterialsKITId  = WOMS.WorkOrderMaterialsKITId
						LEFT JOIN dbo.ItemMaster IMM ON IMM.ItemMasterId = WOM.ItemMasterId

					--SELECT * FROM #WorkOrderMaterials
					UPDATE #WorkOrderMaterials SET QuantityShort = ISNULL(Quantity, 0) -  (ISNULL(QuantityReserved, 0) +  ISNULL(QuantityIssued, 0))
					
					UPDATE WOMM SET Condition = (SELECT TOP 1 Condition FROM #WorkOrderMaterials WOM WHERE WOMM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND ISNULL(WOM.Condition, '') != '') 
					FROM #WorkOrderMaterials WOMM WHERE ISNULL(WOMM.Condition, '') = ''

					SELECT DENSE_RANK() OVER (ORDER BY ISNULL(StockLineId,0) DESC) AS RowNumber , 
						[ID], [WorkOrderMaterialsId],[WorkOrderMaterialsKITId],[WorkOrderMaterialsKitMappingId],[WorkOrderId],[WorkFlowWorkOrderId],[ItemMasterId],
						[ConditionId],[Quantity],[UnitCost],[ExtendedCost],[QuantityReserved],[QuantityIssued],[QuantityShort],[IsAltPart],[AltPartMasterPartId],
						[PartStatusId],[UnReservedQty],[UnIssuedQty],[IssuedById],[ReservedById],[IsEquPart],[ItemMappingId],[TotalReserved],[TotalIssued],
						[TotalUnReserved],[TotalUnIssued],[ProvisionId],[MaterialMandatoriesId],[WOPartNoId],[TotalStocklineQtyReq],[QtyOnOrder],[QtyOnBkOrder],
						[QtyToTurnIn],UPPER([Figure]) AS [Figure],UPPER([Item]) AS [Item],[EquPartMasterPartId],[ReservedDate],[UnitOfMeasureId],[TaskId],[WOMStockLineId],[StockLineId],[StkItemMasterId],
						[StkConditionId],[StkQuantity],[QtyReserved],[QtyIssued],[StkQuantityShort],[StkAltPartMasterPartId],[StkEquPartMasterPartId],[StkIsAltPart],
						[StkIsEquPart],[StkUnitCost],[StkExtendedCost],[stkProvisionId],[QuantityTurnIn],UPPER([stkFigure]) AS [stkFigure],UPPER([stkItem]) AS [stkItem],UPPER([PartNumber]) AS [PartNumber],
						CASE WHEN ISNULL(StkIsAltPart, 0) > 0 THEN UPPER([StkPartNumber]) + ' (ALT)' 
							 WHEN ISNULL(StkIsEquPart, 0) > 0 THEN UPPER([StkPartNumber]) + ' (EQ)' 
						ELSE UPPER([StkPartNumber]) END AS [StkPartNumber],
						CASE WHEN LEN(UPPER([PartDesc])) > 52 THEN LEFT(UPPER([PartDesc]), 52) + '...' ELSE  UPPER([PartDesc]) END AS [PartDesc],
						CASE WHEN LEN(UPPER([StkPartDesc])) > 40 THEN LEFT(UPPER([StkPartDesc]), 40) + '...' ELSE  UPPER([StkPartDesc]) END AS [StkPartDesc],
						UPPER([Condition]) AS [Condition], UPPER([stkCondition]) AS [stkCondition],
						UPPER([SerialNo]) AS [SerialNo],UPPER([StocklineNo]) AS [StocklineNo],UPPER([ControlNo]) AS [ControlNo],
						UPPER([ControlId]) AS [ControlId],UPPER([UOM]) AS [UOM],UPPER([Priority]) AS [Priority],[QtyAvail],[QtyOH],	UPPER([Location]) AS [Location],UPPER([Wherehouse]) AS [Wherehouse],[IsMaterials]
					FROM #WorkOrderMaterials 
					ORDER BY ISNULL(StockLineId,0) DESC
					
				END

			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_ReserveIssueWorkOrderMaterialsStockline' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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
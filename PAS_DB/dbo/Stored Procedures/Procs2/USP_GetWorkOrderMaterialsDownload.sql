/*************************************************************           
 ** File:   [USP_GetWorkOrderMaterialsDownload]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to download Work Order Materials List
 ** Purpose:         
 ** Date:   05/03/2025       
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author					Change Description            
 ** --   --------		-------				--------------------------------          
	1	05/03/2025		Moin Bloch			    Created
	2	11/03/2025		Moin Bloch			    Fixed Issue For Duplicate Records
	3	18/04/2025		Devendra Shekh			Fixed Issue For Duplicate Records for Alt/Equ Part for parent Download
	4   26/03/2026      Moin Bloch	            Rename TearDown To Internal Teardown PN-15850
	5   22/06/2026		Abhishek Jirawla		Adding IsPiecePart condition in RepairOrderPart table 

 EXECUTE [dbo].[USP_GetWorkOrderMaterialsDownload] 4257,3782, 0
 exec dbo.USP_GetWorkOrderMaterialsDownload 8354,7964,1,1
 **************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWorkOrderMaterialsDownload]   
@WorkOrderId BIGINT = NULL,   
@WorkFlowWorkOrderId BIGINT  = NULL,
@ShowPendingToIssue BIT  = 0,	
@IsPartDownload BIT = 0    
AS    
BEGIN  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON  
	BEGIN TRY		
		BEGIN 
		    IF OBJECT_ID(N'tempdb..#tmpStockline') IS NOT NULL
			BEGIN
				DROP TABLE #tmpStockline
			END
			IF OBJECT_ID(N'tempdb..#tmpWOMStockline') IS NOT NULL
			BEGIN
				DROP TABLE #tmpWOMStockline
			END	
			IF OBJECT_ID(N'tempdb..#tmpWOMStocklineKit') IS NOT NULL
			BEGIN
				DROP TABLE #tmpWOMStocklineKit
			END
			IF OBJECT_ID(N'tempdb..#tmpStocklineKit') IS NOT NULL
			BEGIN
				DROP TABLE #tmpStocklineKit
			END
			CREATE TABLE #tmpStockline
			(
				[ID] BIGINT NOT NULL IDENTITY, 						 
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
				[ID] BIGINT NOT NULL IDENTITY, 						 
				[StockLineId] [bigint] NOT NULL,
				[WorkOrderMaterialsId] [bigint] NULL,
				[ConditionId] [bigint] NOT NULL,
				[QtyIssued] [int] NOT NULL,
				[QtyReserved] [int] NULL,
				[IsActive] BIT NULL,
				[IsDeleted] BIT NULL,
			)
			CREATE TABLE #tmpWOMStocklineKit
			(
				[ID] BIGINT NOT NULL IDENTITY, 						 
				[StockLineId] [bigint] NOT NULL,
				[WorkOrderMaterialsId] [bigint] NULL,
				[ConditionId] [bigint] NOT NULL,
				[QtyIssued] [int] NOT NULL,
				[QtyReserved] [int] NULL,
				[IsActive] BIT NULL,
				[IsDeleted] BIT NULL,
			)
			CREATE TABLE #tmpStocklineKit
			(
				[ID] BIGINT NOT NULL IDENTITY, 						 
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

		    DECLARE @WOPartNoId BIGINT;
			DECLARE @SubProvisionId INT,@ForStockProvisionId INT;
			DECLARE @MasterCompanyId INT,@CustomerID BIGINT
			DECLARE @WorkOrderFormTypeId BIT = 0; 	
			DECLARE @IsTeardownWO BIT = 0, @WoTypeId INT = 0;

			SELECT @SubProvisionId = [ProvisionId] FROM [dbo].[Provision] WITH (NOLOCK) WHERE UPPER([StatusCode]) = 'SUB WORK ORDER';
			SELECT @ForStockProvisionId = [ProvisionId] FROM [dbo].[Provision] WITH (NOLOCK) WHERE UPPER(StatusCode) = 'FOR STOCK'

			SELECT @WorkOrderFormTypeId = ISNULL([WorkOrderFormTypeId],0),@MasterCompanyId = WO.[MasterCompanyId],@CustomerID = WO.[CustomerId] 
			  FROM [dbo].[WorkOrder] WO WITH(NOLOCK) 
			INNER JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH(NOLOCK) ON WO.[WorkOrderId] = WOWF.[WorkOrderId] WHERE WOWF.[WorkFlowWorkOrderId] = @WorkFlowWorkOrderId;				
			
			SELECT @WOPartNoId = [WorkOrderPartNoId] FROM [dbo].[WorkOrderWorkFlow] WITH (NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId;
		       SET @IsTeardownWO = (CASE WHEN (SELECT TOP 1 ID FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE UPPER([Description]) = UPPER('Internal Teardown') ) = @WoTypeId THEN 1 ELSE 0 END)
			
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
				AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOMS.IsActive = 1 AND WOMS.IsDeleted = 0

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
				AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
			
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
				FROM [dbo].[Stockline] SL WITH(NOLOCK) 
				JOIN [dbo].[WorkOrderMaterialsKit] WOM WITH (NOLOCK) ON WOM.[ItemMasterId] = sl.[ItemMasterId] AND WOM.[ConditionCodeId] = SL.[ConditionId] AND SL.[IsParent] = 1
				WHERE SL.[MasterCompanyId] = @MasterCompanyId 
				AND (sl.[IsCustomerStock] = 0 OR (sl.[IsCustomerStock] = 1 AND sl.[CustomerId] = @CustomerId))
				AND  SL.[IsActive] = 1 AND SL.[IsDeleted] = 0

			IF(@IsPartDownload = 1)
			BEGIN
				IF (@ShowPendingToIssue = 1)
				BEGIN				
					--------------------------------------------------MATERIAL--------------------------------------------------
					;WITH MaterialResult AS ( 
					SELECT DISTINCT CASE WHEN @WorkOrderFormTypeId = 1 THEN WOT.[TaskName] ELSE T.[Description] END AS TaskName,
							IM.[PartNumber],
							(CASE WHEN (SELECT SUM(CASE WHEN ISNULL(MSTL.[AltPartMasterPartId], 0) <> 0 THEN 1 WHEN ISNULL(MSTL.[EquPartMasterPartId], 0) <> 0 THEN 1 ELSE 0 END) FROM [dbo].[WorkOrderMaterialStockLine] MSTL WITH (NOLOCK) WHERE MSTL.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsId] AND MSTL.[IsDeleted] = 0) > 0 THEN 'Yes' ELSE 'No' END) AS [AlterPartNumber],	
							--(SELECT [partnumber] FROM [dbo].[ItemMaster] IM WHERE IM.[ItemMasterId] = 
							--(CASE 
							--	WHEN ISNULL(MSTL.[AltPartMasterPartId], 0) = 0 
							--	THEN 
							--		CASE 
							--		WHEN ISNULL(MSTL.[EquPartMasterPartId], 0) = 0 
							--		THEN 0
							--		ELSE MSTL.[EquPartMasterPartId]
							--		END
							--	ELSE MSTL.[AltPartMasterPartId]
							--	END)
							--) AS [AlterPartNumber],							
							IM.[PartDescription],	
							IM.[ManufacturerName],
							CO.[Description] [Condition],
							MM.[Name] [MandatoryOrSupplemental],
							PV.[Description] [Provision],
							WOM.[Quantity],
							0 [kitStocklineQuantity],
							[QuantityReserved] = ISNULL((SELECT SUM(ISNULL(womsl.[QtyReserved], 0 )) FROM #tmpWOMStockline womsl WITH (NOLOCK) WHERE womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsId] AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0),0),
							[QtytobeReserved] = ISNULL(ISNULL(WOM.[Quantity], 0) - ISNULL((SELECT SUM(ISNULL(womsl.[QtyReserved], 0 )) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
												WHERE womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsId] AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0),0) - ISNULL((SELECT SUM(ISNULL(womsl.[QtyIssued], 0)) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
												WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0),0),0),
							[QuantityIssued] = ISNULL((SELECT SUM(ISNULL(womsl.[QtyIssued], 0)) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
												WHERE womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsId] AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0),0),
							[QunatityRemaining] = ISNULL((WOM.[Quantity] + WOM.[QtyToTurnIn]) - (ISNULL((SELECT SUM(ISNULL(womsl.[QtyIssued], 0)) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
												WHERE womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsId] AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0),0) + 
												ISNULL((SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) 
												FROM [dbo].[WorkOrderMaterialStockLine] womsl WITH (NOLOCK)
												JOIN [dbo].[Stockline] sl WITH (NOLOCK) on womsl.[StockLIneId] = sl.[StockLIneId]
												Where womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsId] AND womsl.[ConditionId] = WOM.[ConditionCodeId]
												AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0 AND ISNULL(sl.[QuantityTurnIn], 0) > 0 ), 0)),0),
							[PartQtyToTurnIn] = ISNULL((CASE WHEN @IsTeardownWO = 1 THEN (CASE WHEN ISNULL(WOM.[Quantity],0) = 0 THEN 0 ELSE ISNULL(WOM.[Quantity],0) - ISNULL((SELECT SUM(ISNULL(SL.[QuantityTurnIn],0)) 
												FROM  [dbo].[WorkOrderPartNumber] WOP  WITH(NOLOCK) 
												JOIN [dbo].[Stockline] SL ON WOP.[WorkOrderId] = SL.[WorkOrderId] AND WOP.ID = SL.[WorkOrderPartNoId] AND Sl.[WorkOrderId] = @WorkOrderId AND ISNULL(SL.[IsActive],0) = 1 AND ISNULL(SL.[IsDeleted],0) = 0
												WHERE SL.[WorkOrderId] = WOM.[WorkOrderId] AND Sl.[ConditionId] = WOM.[ConditionCodeId] AND SL.[ItemMasterId] = IM.[ItemMasterId]),0) END) ELSE WOM.[QtyToTurnIn] END),0),
							[PartQuantityTurnIn] = ISNULL((CASE WHEN @IsTeardownWO = 1 THEN 
														(SELECT SUM(ISNULL(SL.QuantityTurnIn,0)) FROM [dbo].[WorkOrderPartNumber] WOP  WITH(NOLOCK) 
														 JOIN [dbo].[Stockline] SL ON WOP.[WorkOrderId] = SL.[WorkOrderId] AND WOP.ID = SL.[WorkOrderPartNoId] AND Sl.[WorkOrderId] = @WorkOrderId 
														 WHERE SL.[WorkOrderId] = WOM.[WorkOrderId] AND Sl.[ConditionId] = WOM.[ConditionCodeId] AND SL.[ItemMasterId] = IM.[ItemMasterId] AND SL.[IsActive] = 1 AND SL.[IsDeleted] = 0) 
													   ELSE (SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM [dbo].[WorkOrderMaterialStockLine] womsl WITH (NOLOCK)
															 JOIN [dbo].[Stockline] sl WITH (NOLOCK) on womsl.[StockLIneId] = sl.[StockLIneId]
															 WHERE womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsId] AND womsl.[ConditionId] = WOM.[ConditionCodeId]
															 AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0 AND ISNULL(sl.[QuantityTurnIn], 0) > 0) END),0),
							[PartQuantityOnHand] = ISNULL((SELECT SUM(ISNULL(sl.[QuantityOnHand],0)) FROM #tmpStockline sl WITH (NOLOCK)
												   WHERE sl.[ItemMasterId] = WOM.[ItemMasterId] AND sl.[ConditionId] = WOM.[ConditionCodeId] AND sl.[IsParent] = 1),0),
							[PartQuantityAvailable] = ISNULL((SELECT SUM(ISNULL(sl.[QuantityAvailable],0)) FROM #tmpStockline sl WITH (NOLOCK)
											WHERE sl.[ItemMasterId] = WOM.[ItemMasterId] AND sl.[ConditionId] = WOM.[ConditionCodeId] AND sl.[IsParent] = 1),0),
							--CASE WHEN SUOM.UnitOfMeasureId IS NOT NULL THEN SUOM.ShortName ELSE UOM.ShortName END UOM,
							UOM.ShortName UOM,
							CASE WHEN IM.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'
								 WHEN IM.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'
								 WHEN IM.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'
							ELSE 'OEM'
							END [StockType],
							NULL [needDate],
							[Currency] = (SELECT TOP 1 CUR.[Code] FROM [dbo].[ItemMasterPurchaseSale] IMPS WITH (NOLOCK) 
										LEFT JOIN [dbo].[Currency] CUR WITH (NOLOCK)  ON IMPS.[PP_CurrencyId] = CUR.[CurrencyId] 
										WHERE IMPS.[ItemMasterId] = WOM.[ItemMasterId] AND IMPS.[ConditionId] = WOM.[ConditionCodeId]),
							WOM.[UnitCost],
							WOM.[ExtendedCost],
							WOM.[QtyOnOrder], 
							WOM.[QtyOnBkOrder],
							WOM.[PONum],
							WOM.[PONextDlvrDate],
							WOM.[Figure],
							WOM.[Item],
							ISNULL(WOM.IsFromWorkFlow,0) [IsFromWorkFlow],
							UPPER(WOM.[CreatedBy]) [Employeename],
							ISNULL(WOM.[IsDeferred], 0) [IsDeferred],
							WOM.[Memo],
							WOM.[ExpectedSerialNumber],
							'No' [IsKitItem]
						FROM [dbo].[WorkOrderMaterials] WOM WITH (NOLOCK)  
							INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = WOM.[ItemMasterId]
							INNER JOIN [dbo].[UnitOfMeasure] UOM WITH (NOLOCK) ON UOM.[UnitOfMeasureId] = IM.[PurchaseUnitOfMeasureId]
							INNER JOIN [dbo].[Condition] CO WITH (NOLOCK) ON CO.[ConditionId] = WOM.[ConditionCodeId]
							INNER JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH (NOLOCK) ON WOWF.[WorkFlowWorkOrderId] = WOM.[WorkFlowWorkOrderId]
							INNER JOIN [dbo].[MaterialMandatories] MM WITH (NOLOCK) ON MM.[Id] = WOM.[MaterialMandatoriesId]
							 --LEFT JOIN [dbo].[WorkOrderMaterialStockLine] MSTL WITH (NOLOCK) ON MSTL.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsId] AND MSTL.[IsDeleted] = 0							
							  LEFT JOIN [dbo].[ItemMasterPurchaseSale] IMPS WITH (NOLOCK) ON IM.[ItemMasterId] = IMPS.[ItemMasterId] AND WOM.[ConditionCodeId] = IMPS.[ConditionId]
							  LEFT JOIN [dbo].[ItemClassification] ITC WITH (NOLOCK) ON ITC.[ItemClassificationId] = IM.[ItemClassificationId]
							  LEFT JOIN [dbo].[Provision] PV WITH (NOLOCK) ON PV.[ProvisionId] = WOM.[ProvisionId]
							  LEFT JOIN [dbo].[Task] T WITH (NOLOCK) ON T.[TaskId] = WOM.[TaskId]
							  LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.[WorkOrderTaskId] = WOM.[TaskId]							
						WHERE WOM.[IsDeleted] = 0 AND WOM.[WorkFlowWorkOrderId] = @WorkFlowWorkOrderId
						AND (ISNULL(WOM.[Quantity],0) - ISNULL(WOM.[QuantityIssued],0) > 0)
						
						UNION ALL
						
--------------------------------------------------MATERIAL KIT--------------------------------------------------

						SELECT DISTINCT CASE WHEN @WorkOrderFormTypeId = 1 THEN WOT.[TaskName] ELSE T.[Description] END AS TaskName,
						IM.[PartNumber],
						(CASE WHEN (SELECT SUM(CASE WHEN ISNULL(MSTL.[AltPartMasterPartId], 0) <> 0 THEN 1 WHEN ISNULL(MSTL.[EquPartMasterPartId], 0) <> 0 THEN 1 ELSE 0 END) FROM [dbo].[WorkOrderMaterialStockLineKit] MSTL WHERE MSTL.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND MSTL.IsDeleted = 0) > 0 THEN 'Yes' ELSE 'No' END) AS [AlterPartNumber],	
							--(SELECT [partnumber] FROM [dbo].[ItemMaster] IM WHERE IM.[ItemMasterId] = 
							--(CASE 
							--	WHEN ISNULL(MSTL.[AltPartMasterPartId], 0) = 0 
							--	THEN 
							--		CASE 
							--		WHEN ISNULL(MSTL.[EquPartMasterPartId], 0) = 0 
							--		THEN 0
							--		ELSE MSTL.[EquPartMasterPartId]
							--		END
							--	ELSE MSTL.[AltPartMasterPartId]
							--	END)
							--) AS [AlterPartNumber],
						IM.[PartDescription],
						IM.[ManufacturerName],
						CO.[Description] [Condition],
						MM.[Name] [MandatoryOrSupplemental],
						PV.[Description] [Provision],
						WOM.[Quantity],
						0 [kitStocklineQuantity],
						[QuantityReserved] = ISNULL((SELECT SUM(ISNULL(womsl.[QtyReserved], 0 )) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsKitId] AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0),0),
						
						[QtytobeReserved] = ISNULL(ISNULL(WOM.[Quantity], 0) - ISNULL((SELECT SUM(ISNULL(womsl.[QtyReserved], 0 )) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsKitId] AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0),0) - ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsKitId] AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0),0),0),
						
						[QuantityIssued] = ISNULL((SELECT SUM(ISNULL(womsl.[QtyIssued], 0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsKitId] AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0),0),
						
						[QunatityRemaining] = ISNULL((WOM.[Quantity] + WOM.[QtyToTurnIn]) - (ISNULL((SELECT SUM(ISNULL(womsl.[QtyIssued], 0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsKitId] AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0),0) + ISNULL(
											(SELECT SUM(ISNULL(sl.[QuantityTurnIn],0)) FROM [dbo].[WorkOrderMaterialStockLineKit] womsl WITH (NOLOCK)
											JOIN dbo.[Stockline] sl WITH (NOLOCK) ON womsl.[StockLIneId] = sl.[StockLIneId]
											WHERE womsl.[WorkOrderMaterialsKitId] = WOM.[WorkOrderMaterialsKitId] AND womsl.[ConditionId] = WOM.[ConditionCodeId]
											AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0 AND ISNULL(sl.[QuantityTurnIn], 0) > 0 ), 0)),0),
						
						[PartQtyToTurnIn] = ISNULL(WOM.[QtyToTurnIn],0),

						[PartQuantityTurnIn] = ISNULL((SELECT SUM(ISNULL(sl.[QuantityTurnIn],0)) FROM [dbo].[WorkOrderMaterialStockLineKit] womsl WITH (NOLOCK)
										JOIN [dbo].[Stockline] sl WITH (NOLOCK) ON womsl.[StockLIneId] = sl.[StockLIneId]
										WHERE [womsl].[WorkOrderMaterialsKitId] = WOM.[WorkOrderMaterialsKitId] AND womsl.[ConditionId] = WOM.[ConditionCodeId]
										AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0 AND ISNULL(sl.[QuantityTurnIn], 0) > 0),0),

						[PartQuantityOnHand] = ISNULL((SELECT SUM(ISNULL(sl.[QuantityOnHand],0)) FROM #tmpStocklineKit sl WITH (NOLOCK)
										WHERE sl.[ItemMasterId] = WOM.[ItemMasterId] AND sl.[ConditionId] = WOM.[ConditionCodeId] AND sl.[IsParent] = 1	),0),

						[PartQuantityAvailable] = ISNULL((SELECT SUM(ISNULL(sl.[QuantityAvailable],0)) FROM #tmpStocklineKit sl WITH (NOLOCK)
										WHERE sl.[ItemMasterId] = WOM.[ItemMasterId] AND sl.[ConditionId] = WOM.[ConditionCodeId] AND sl.[IsParent] = 1),0),
						
						--CASE WHEN SUOM.[UnitOfMeasureId] IS NOT NULL THEN SUOM.[ShortName] ELSE UOM.[ShortName] END [UOM],
						UOM.[ShortName] [UOM],
						
						CASE WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
							 WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
							 WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
						ELSE 'OEM' END [StockType],
						
						NULL [needDate],
						
						[Currency] = (SELECT TOP 1 CUR.Code FROM [dbo].[ItemMasterPurchaseSale] IMPS WITH (NOLOCK) 
									LEFT JOIN [dbo].[Currency] CUR WITH (NOLOCK)  ON IMPS.[PP_CurrencyId] = CUR.[CurrencyId] 
									WHERE IMPS.[ItemMasterId] = WOM.[ItemMasterId] AND IMPS.[ConditionId] = WOM.[ConditionCodeId]),
						WOM.[UnitCost],
						WOM.[ExtendedCost],
						WOM.[QtyOnOrder], 
						WOM.[QtyOnBkOrder],
						WOM.[PONum],
						WOM.[PONextDlvrDate],
						WOM.[Figure],
						WOM.[Item],
						ISNULL(WOM.[IsFromWorkFlow],0) [IsFromWorkFlow],
						UPPER(WOM.[CreatedBy]) [Employeename],
						ISNULL(WOM.[IsDeferred], 0),
						WOM.[Memo],
						''  [ExpectedSerialNumber],
						'Yes' [IsKitItem]
					FROM [dbo].[WorkOrderMaterialsKit] WOM WITH (NOLOCK)  
						INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
						INNER JOIN [dbo].[UnitOfMeasure] UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
						INNER JOIN [dbo].[Condition] CO WITH (NOLOCK) ON CO.ConditionId = WOM.ConditionCodeId
						INNER JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId
						INNER JOIN [dbo].[MaterialMandatories] MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId
						 --LEFT JOIN [dbo].[WorkOrderMaterialStockLineKit] MSTL WITH (NOLOCK) ON MSTL.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND MSTL.IsDeleted = 0
						 LEFT JOIN [dbo].[ItemMasterPurchaseSale] IMPS WITH (NOLOCK) ON IM.ItemMasterId = IMPS.ItemMasterId AND WOM.ConditionCodeId = IMPS.ConditionId
						 LEFT JOIN [dbo].[ItemClassification] ITC WITH (NOLOCK) ON ITC.ItemClassificationId = IM.ItemClassificationId
						 LEFT JOIN [dbo].[Provision] PV WITH (NOLOCK) ON PV.ProvisionId = WOM.ProvisionId						 
						 LEFT JOIN [dbo].[Task] T WITH (NOLOCK) ON T.TaskId = WOM.TaskId
						 LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOM.TaskId						 
					WHERE WOM.[IsDeleted] = 0 AND WOM.[WorkFlowWorkOrderId] = @WorkFlowWorkOrderId-- AND MSTL.[StockLineId] IS NULL
						AND (ISNULL(WOM.Quantity,0) - ISNULL(WOM.QuantityIssued,0) > 0)		
				)
				SELECT * FROM MaterialResult 
				END
				ELSE
				BEGIN
					--------------------------------------------------MATERIAL--------------------------------------------------
					;WITH MaterialResult AS ( 
					  SELECT DISTINCT CASE WHEN @WorkOrderFormTypeId = 1 THEN WOT.[TaskName] ELSE T.[Description] END AS TaskName,
							IM.[PartNumber],
							(CASE WHEN (SELECT SUM(CASE WHEN ISNULL(MSTL.[AltPartMasterPartId], 0) <> 0 THEN 1 WHEN ISNULL(MSTL.[EquPartMasterPartId], 0) <> 0 THEN 1 ELSE 0 END) FROM [dbo].[WorkOrderMaterialStockLine] MSTL WITH (NOLOCK) WHERE MSTL.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsId] AND MSTL.[IsDeleted] = 0) > 0 THEN 'Yes' ELSE 'No' END) AS [AlterPartNumber],	
							--(SELECT [partnumber] FROM [dbo].[ItemMaster] IM WHERE IM.[ItemMasterId] = 
							--(CASE 
							--	WHEN ISNULL(MSTL.[AltPartMasterPartId], 0) = 0 
							--	THEN 
							--		CASE 
							--		WHEN ISNULL(MSTL.[EquPartMasterPartId], 0) = 0 
							--		THEN 0
							--		ELSE MSTL.[EquPartMasterPartId]
							--		END
							--	ELSE MSTL.[AltPartMasterPartId]
							--	END)
							--) AS [AlterPartNumber],				
							IM.[PartDescription],	
							IM.[ManufacturerName],
							CO.[Description] [Condition],
							MM.[Name] [MandatoryOrSupplemental],
							PV.[Description] [Provision],
							WOM.[Quantity],
							0 [kitStocklineQuantity],
							[QuantityReserved] = ISNULL((SELECT SUM(ISNULL(womsl.[QtyReserved], 0 )) FROM #tmpWOMStockline womsl WITH (NOLOCK) WHERE womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsId] AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0),0),
							[QtytobeReserved] = ISNULL(ISNULL(WOM.[Quantity], 0) - ISNULL((SELECT SUM(ISNULL(womsl.[QtyReserved], 0 )) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
												WHERE womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsId] AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0),0) - ISNULL((SELECT SUM(ISNULL(womsl.[QtyIssued], 0)) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
												WHERE womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0),0),0),
							[QuantityIssued] = ISNULL((SELECT SUM(ISNULL(womsl.[QtyIssued], 0)) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
												WHERE womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsId] AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0),0),
							[QunatityRemaining] = ISNULL((WOM.[Quantity] + WOM.[QtyToTurnIn]) - (ISNULL((SELECT SUM(ISNULL(womsl.[QtyIssued], 0)) FROM #tmpWOMStockline womsl WITH (NOLOCK) 
												WHERE womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsId] AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0),0) + 
												ISNULL((SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) 
												FROM [dbo].[WorkOrderMaterialStockLine] womsl WITH (NOLOCK)
												JOIN [dbo].[Stockline] sl WITH (NOLOCK) on womsl.[StockLIneId] = sl.[StockLIneId]
												Where womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsId] AND womsl.[ConditionId] = WOM.[ConditionCodeId]
												AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0 AND ISNULL(sl.[QuantityTurnIn], 0) > 0 ), 0)),0),
							[PartQtyToTurnIn] = ISNULL((CASE WHEN @IsTeardownWO = 1 THEN (CASE WHEN ISNULL(WOM.[Quantity],0) = 0 THEN 0 ELSE ISNULL(WOM.[Quantity],0) - ISNULL((SELECT SUM(ISNULL(SL.[QuantityTurnIn],0)) 
												FROM  [dbo].[WorkOrderPartNumber] WOP  WITH(NOLOCK) 
												JOIN [dbo].[Stockline] SL ON WOP.[WorkOrderId] = SL.[WorkOrderId] AND WOP.ID = SL.[WorkOrderPartNoId] AND Sl.[WorkOrderId] = @WorkOrderId AND ISNULL(SL.[IsActive],0) = 1 AND ISNULL(SL.[IsDeleted],0) = 0
												WHERE SL.[WorkOrderId] = WOM.[WorkOrderId] AND Sl.[ConditionId] = WOM.[ConditionCodeId] AND SL.[ItemMasterId] = IM.[ItemMasterId]),0) END) ELSE WOM.[QtyToTurnIn] END),0),
							[PartQuantityTurnIn] = ISNULL((CASE WHEN @IsTeardownWO = 1 THEN 
														(SELECT SUM(ISNULL(SL.QuantityTurnIn,0)) FROM [dbo].[WorkOrderPartNumber] WOP  WITH(NOLOCK) 
														 JOIN [dbo].[Stockline] SL ON WOP.[WorkOrderId] = SL.[WorkOrderId] AND WOP.ID = SL.[WorkOrderPartNoId] AND Sl.[WorkOrderId] = @WorkOrderId 
														 WHERE SL.[WorkOrderId] = WOM.[WorkOrderId] AND Sl.[ConditionId] = WOM.[ConditionCodeId] AND SL.[ItemMasterId] = IM.[ItemMasterId] AND SL.[IsActive] = 1 AND SL.[IsDeleted] = 0) 
													   ELSE (SELECT SUM(ISNULL(sl.QuantityTurnIn,0)) FROM [dbo].[WorkOrderMaterialStockLine] womsl WITH (NOLOCK)
															 JOIN [dbo].[Stockline] sl WITH (NOLOCK) on womsl.[StockLIneId] = sl.[StockLIneId]
															 WHERE womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsId] AND womsl.[ConditionId] = WOM.[ConditionCodeId]
															 AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0 AND ISNULL(sl.[QuantityTurnIn], 0) > 0) END),0),
							[PartQuantityOnHand] = ISNULL((SELECT SUM(ISNULL(sl.[QuantityOnHand],0)) FROM #tmpStockline sl WITH (NOLOCK)
												   WHERE sl.[ItemMasterId] = WOM.[ItemMasterId] AND sl.[ConditionId] = WOM.[ConditionCodeId] AND sl.[IsParent] = 1),0),
							[PartQuantityAvailable] = ISNULL((SELECT SUM(ISNULL(sl.[QuantityAvailable],0)) FROM #tmpStockline sl WITH (NOLOCK)
											WHERE sl.[ItemMasterId] = WOM.[ItemMasterId] AND sl.[ConditionId] = WOM.[ConditionCodeId] AND sl.[IsParent] = 1),0),
							--CASE WHEN SUOM.UnitOfMeasureId IS NOT NULL THEN SUOM.ShortName ELSE UOM.ShortName END UOM,
							UOM.ShortName UOM,
							CASE WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
								 WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
								 WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
							ELSE 'OEM'
							END [StockType],
							NULL [needDate],
							[Currency] = (SELECT TOP 1 CUR.[Code] FROM [dbo].[ItemMasterPurchaseSale] IMPS WITH (NOLOCK) 
										LEFT JOIN [dbo].[Currency] CUR WITH (NOLOCK)  ON IMPS.[PP_CurrencyId] = CUR.[CurrencyId] 
										WHERE IMPS.[ItemMasterId] = WOM.[ItemMasterId] AND IMPS.[ConditionId] = WOM.[ConditionCodeId]),
							WOM.[UnitCost],
							WOM.[ExtendedCost],
							WOM.[QtyOnOrder], 
							WOM.[QtyOnBkOrder],
							WOM.[PONum],
							WOM.[PONextDlvrDate],
							WOM.[Figure],
							WOM.[Item],
							ISNULL(WOM.IsFromWorkFlow,0) [IsFromWorkFlow],
							UPPER(WOM.[CreatedBy]) [Employeename],
							ISNULL(WOM.[IsDeferred], 0) [IsDeferred],
							WOM.[Memo],
							WOM.[ExpectedSerialNumber],
							'No' [IsKitItem]
						FROM [dbo].[WorkOrderMaterials] WOM WITH (NOLOCK)  
							INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = WOM.[ItemMasterId]
							INNER JOIN [dbo].[UnitOfMeasure] UOM WITH (NOLOCK) ON UOM.[UnitOfMeasureId] = IM.[PurchaseUnitOfMeasureId]
							INNER JOIN [dbo].[Condition] CO WITH (NOLOCK) ON CO.[ConditionId] = WOM.[ConditionCodeId]
							INNER JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH (NOLOCK) ON WOWF.[WorkFlowWorkOrderId] = WOM.[WorkFlowWorkOrderId]
							INNER JOIN [dbo].[MaterialMandatories] MM WITH (NOLOCK) ON MM.[Id] = WOM.[MaterialMandatoriesId]
							 --LEFT JOIN [dbo].[WorkOrderMaterialStockLine] MSTL WITH (NOLOCK) ON MSTL.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsId] AND MSTL.[IsDeleted] = 0
							  LEFT JOIN [dbo].[ItemMasterPurchaseSale] IMPS WITH (NOLOCK) ON IM.[ItemMasterId] = IMPS.[ItemMasterId] AND WOM.[ConditionCodeId] = IMPS.[ConditionId]
							  LEFT JOIN [dbo].[ItemClassification] ITC WITH (NOLOCK) ON ITC.[ItemClassificationId] = IM.[ItemClassificationId]
							  LEFT JOIN [dbo].[Provision] PV WITH (NOLOCK) ON PV.[ProvisionId] = WOM.[ProvisionId]
							  LEFT JOIN [dbo].[Task] T WITH (NOLOCK) ON T.[TaskId] = WOM.[TaskId]
							  LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.[WorkOrderTaskId] = WOM.[TaskId]							
						WHERE WOM.[IsDeleted] = 0 AND WOM.[WorkFlowWorkOrderId] = @WorkFlowWorkOrderId 
						
						UNION ALL

--------------------------------------------------MATERIAL KIT--------------------------------------------------

						SELECT DISTINCT CASE WHEN @WorkOrderFormTypeId = 1 THEN WOT.[TaskName] ELSE T.[Description] END AS TaskName,
						IM.[PartNumber],
						(CASE WHEN (SELECT SUM(CASE WHEN ISNULL(MSTL.[AltPartMasterPartId], 0) <> 0 THEN 1 WHEN ISNULL(MSTL.[EquPartMasterPartId], 0) <> 0 THEN 1 ELSE 0 END) FROM [dbo].[WorkOrderMaterialStockLineKit] MSTL WITH (NOLOCK) WHERE MSTL.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND MSTL.IsDeleted = 0) > 0 THEN 'Yes' ELSE 'No' END) AS [AlterPartNumber],	
							--(SELECT [partnumber] FROM [dbo].[ItemMaster] IM WHERE IM.[ItemMasterId] = 
							--(CASE 
							--	WHEN ISNULL(MSTL.[AltPartMasterPartId], 0) = 0 
							--	THEN 
							--		CASE 
							--		WHEN ISNULL(MSTL.[EquPartMasterPartId], 0) = 0 
							--		THEN 0
							--		ELSE MSTL.[EquPartMasterPartId]
							--		END
							--	ELSE MSTL.[AltPartMasterPartId]
							--	END)
							--) AS [AlterPartNumber],
						IM.[PartDescription],
						IM.[ManufacturerName],
						CO.[Description] [Condition],
						MM.[Name] [MandatoryOrSupplemental],
						PV.[Description] [Provision],
						WOM.[Quantity],
						0 [kitStocklineQuantity],
						[QuantityReserved] = ISNULL((SELECT SUM(ISNULL(womsl.[QtyReserved], 0 )) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsKitId] AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0),0),
						
						[QtytobeReserved] = ISNULL(ISNULL(WOM.[Quantity], 0) - ISNULL((SELECT SUM(ISNULL(womsl.[QtyReserved], 0 )) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsKitId] AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0),0) - ISNULL((SELECT SUM(ISNULL(womsl.QtyIssued, 0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsKitId] AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0),0),0),
						
						[QuantityIssued] = ISNULL((SELECT SUM(ISNULL(womsl.[QtyIssued], 0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsKitId] AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0),0),
						
						[QunatityRemaining] = ISNULL((WOM.[Quantity] + WOM.[QtyToTurnIn]) - (ISNULL((SELECT SUM(ISNULL(womsl.[QtyIssued], 0)) FROM #tmpWOMStocklineKit womsl WITH (NOLOCK) 
											WHERE womsl.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsKitId] AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0),0) + ISNULL(
											(SELECT SUM(ISNULL(sl.[QuantityTurnIn],0)) FROM [dbo].[WorkOrderMaterialStockLineKit] womsl WITH (NOLOCK)
											JOIN dbo.[Stockline] sl WITH (NOLOCK) ON womsl.[StockLIneId] = sl.[StockLIneId]
											WHERE womsl.[WorkOrderMaterialsKitId] = WOM.[WorkOrderMaterialsKitId] AND womsl.[ConditionId] = WOM.[ConditionCodeId]
											AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0 AND ISNULL(sl.[QuantityTurnIn], 0) > 0 ), 0)),0),
						
						[PartQtyToTurnIn] = ISNULL(WOM.[QtyToTurnIn],0),

						[PartQuantityTurnIn] = ISNULL((SELECT SUM(ISNULL(sl.[QuantityTurnIn],0)) FROM [dbo].[WorkOrderMaterialStockLineKit] womsl WITH (NOLOCK)
										JOIN [dbo].[Stockline] sl WITH (NOLOCK) ON womsl.[StockLIneId] = sl.[StockLIneId]
										WHERE [womsl].[WorkOrderMaterialsKitId] = WOM.[WorkOrderMaterialsKitId] AND womsl.[ConditionId] = WOM.[ConditionCodeId]
										AND womsl.[IsActive] = 1 AND womsl.[IsDeleted] = 0 AND ISNULL(sl.[QuantityTurnIn], 0) > 0),0),

						[PartQuantityOnHand] = ISNULL((SELECT SUM(ISNULL(sl.[QuantityOnHand],0)) FROM #tmpStocklineKit sl WITH (NOLOCK)
										WHERE sl.[ItemMasterId] = WOM.[ItemMasterId] AND sl.[ConditionId] = WOM.[ConditionCodeId] AND sl.[IsParent] = 1	),0),

						[PartQuantityAvailable] = ISNULL((SELECT SUM(ISNULL(sl.[QuantityAvailable],0)) FROM #tmpStocklineKit sl WITH (NOLOCK)
										WHERE sl.[ItemMasterId] = WOM.[ItemMasterId] AND sl.[ConditionId] = WOM.[ConditionCodeId] AND sl.[IsParent] = 1),0),
						
						--CASE WHEN SUOM.[UnitOfMeasureId] IS NOT NULL THEN SUOM.[ShortName] ELSE UOM.[ShortName] END [UOM],
						UOM.[ShortName] [UOM],
						
						CASE WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
							 WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
							 WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
						ELSE 'OEM' END [StockType],
						
						NULL [needDate],
						
						[Currency] = (SELECT TOP 1 CUR.Code FROM [dbo].[ItemMasterPurchaseSale] IMPS WITH (NOLOCK) 
									LEFT JOIN [dbo].[Currency] CUR WITH (NOLOCK)  ON IMPS.[PP_CurrencyId] = CUR.[CurrencyId] 
									WHERE IMPS.[ItemMasterId] = WOM.[ItemMasterId] AND IMPS.[ConditionId] = WOM.[ConditionCodeId]),
						WOM.[UnitCost],
						WOM.[ExtendedCost],
						WOM.[QtyOnOrder], 
						WOM.[QtyOnBkOrder],
						WOM.[PONum],
						WOM.[PONextDlvrDate],
						WOM.[Figure],
						WOM.[Item],
						ISNULL(WOM.[IsFromWorkFlow],0) [IsFromWorkFlow],
						UPPER(WOM.[CreatedBy]) [Employeename],
						ISNULL(WOM.[IsDeferred], 0),
						WOM.[Memo],
						''  [ExpectedSerialNumber],
						'Yes' [IsKitItem]
					FROM [dbo].[WorkOrderMaterialsKit] WOM WITH (NOLOCK)  
						INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
						INNER JOIN [dbo].[UnitOfMeasure] UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
						INNER JOIN [dbo].[Condition] CO WITH (NOLOCK) ON CO.ConditionId = WOM.ConditionCodeId
						INNER JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH (NOLOCK) ON WOWF.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId
						INNER JOIN [dbo].[MaterialMandatories] MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId
						 --LEFT JOIN [dbo].[WorkOrderMaterialStockLineKit] MSTL WITH (NOLOCK) ON MSTL.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND MSTL.IsDeleted = 0						
						 LEFT JOIN [dbo].[ItemMasterPurchaseSale] IMPS WITH (NOLOCK) ON IM.ItemMasterId = IMPS.ItemMasterId AND WOM.ConditionCodeId = IMPS.ConditionId
						 LEFT JOIN [dbo].[ItemClassification] ITC WITH (NOLOCK) ON ITC.ItemClassificationId = IM.ItemClassificationId
						 LEFT JOIN [dbo].[Provision] PV WITH (NOLOCK) ON PV.ProvisionId = WOM.ProvisionId
						 LEFT JOIN [dbo].[Task] T WITH (NOLOCK) ON T.TaskId = WOM.TaskId
						 LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOM.TaskId						
					WHERE WOM.[IsDeleted] = 0 AND WOM.[WorkFlowWorkOrderId] = @WorkFlowWorkOrderId		
				)
				SELECT* FROM MaterialResult 
				END
			END
			ELSE 
			BEGIN
				IF(@ShowPendingToIssue = 1)
				BEGIN
				   --------------------------------------------------MATERIAL STOCKLINE--------------------------------------------------
				  ;WITH MaterialResult AS (
					SELECT DISTINCT SL.[StockLineNumber],
					       SL.[SerialNumber],						   
						  IMS.[PartNumber],						
						  IMS.[PartDescription],
						   IM.[ManufacturerName],
						  Stk_C.[Description] [StocklineCondition],
						  MM.[Name] [MandatoryOrSupplemental],
						  SP.[Description] [StocklineProvision],
						  ISNULL(MSTL.[Quantity],0) [StocklineQuantity],
						  ISNULL(MSTL.[Quantity],0) [kitStocklineQty],
						  ISNULL(MSTL.[QtyReserved],0) [StocklineQtyReserved],
						  ISNULL(MSTL.[Quantity], 0) - (ISNULL(MSTL.[QtyIssued],0) + ISNULL(MSTL.[QtyReserved],0)) [StocklineQtytobeReserved],
						  ISNULL(MSTL.[QtyIssued],0) [StocklineQtyIssued],
						  ISNULL(MSTL.[Quantity], 0) - ISNULL(MSTL.[QtyIssued],0) [StocklineQtyRemaining],
						  ISNULL(CASE WHEN MSTL.[ProvisionId] = @SubProvisionId AND ISNULL(MSTL.[Quantity], 0) != 0 THEN MSTL.[Quantity]
							ELSE CASE WHEN MSTL.[ProvisionId] = @SubProvisionId OR MSTL.[ProvisionId] = @ForStockProvisionId THEN SL.[QuantityTurnIn] ELSE 0 END END,0) [StocklineQtyToTurnIn],
						  ISNULL(MSTL.[QuantityTurnIn], 0) [StocklineQuantityTurnIn],
						  ISNULL(SL.[QuantityOnHand],0) [StockLineQuantityOnHand],  
						  ISNULL(SL.[QuantityAvailable],0) [StockLineQuantityAvailable],  
						  CASE WHEN SUOM.[UnitOfMeasureId] IS NOT NULL THEN SUOM.[ShortName] ELSE UOM.[ShortName] END AS UOM,
						  CASE WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
							   WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
						       WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
						       ELSE 'OEM'
						  END [StockType],
						  NULL [NeedDate],
						  [Currency] = (SELECT TOP 1 CUR.Code FROM [dbo].[ItemMasterPurchaseSale] IMPS WITH (NOLOCK) 
									    LEFT JOIN [dbo].[Currency] CUR WITH (NOLOCK)  ON IMPS.PP_CurrencyId = CUR.CurrencyId 
									    WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId),
						  ISNULL(MSTL.[UnitCost],0) [StocklineUnitCost],
						  ISNULL(MSTL.[ExtendedCost],0) [StocklineExtendedCost],
						  UPPER(WOM.CreatedBy) [Employeename],
						  SL.[ControlNumber] [ControlNo],
						  SL.[IdNumber] [ControlId],
						  [CostDate] = (SELECT TOP 1 CONVERT(varchar, IMPS.PP_LastListPriceDate, 101) FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK)
									  WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId AND IMPS.PP_LastListPriceDate IS NOT NULL),
						  CASE WHEN WOMS_RO.[RepairOrderId] IS NOT NULL THEN WOMS_RO.[RepairOrderNumber] ELSE RO.[RepairOrderNumber] END AS 'RepairOrderNumber',
						  			CASE WHEN SL.RepairOrderPartRecordId IS NOT NULL AND MSTL.RepairOrderId > 0 THEN SL.ReceivedDate ELSE ROP.EstRecordDate END AS 'RONextDlvrDate',
                         SL.ReceiverNumber [Receiver],
						 MSTL.Figure [StockLineFigure],
						 MSTL.Item [StockLineItem],
						 SL.[WorkOrderNumber],
						 CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.IsDeleted = 1 THEN '' ELSE SWO.SubWorkOrderNo END [SubWorkOrderNo],
						 '' [SalesOrder],
						 WOM.[Memo],
						 'No' [IsKitItem]
					FROM [dbo].[WorkOrderMaterials] WOM WITH (NOLOCK)  
						INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
						INNER JOIN [dbo].[UnitOfMeasure] UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
						INNER JOIN [dbo].[MaterialMandatories] MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId
					    INNER JOIN [dbo].[WorkOrderMaterialStockLine] MSTL WITH (NOLOCK) ON MSTL.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND MSTL.IsDeleted = 0
						 LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId
						 LEFT JOIN [dbo].[UnitOfMeasure] SUOM WITH (NOLOCK) ON SUOM.UnitOfMeasureId = SL.PurchaseUnitOfMeasureId
						 LEFT JOIN [dbo].[WorkOrderMaterialStockLine] MSTL_PO WITH (NOLOCK) ON MSTL_PO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND MSTL_PO.IsDeleted = 0 AND WOM.ConditionCodeId = MSTL_PO.ConditionId AND WOM.ItemMasterId = MSTL_PO.ItemMasterId AND WOM.POId > 0
						 LEFT JOIN [dbo].[Condition] Stk_C WITH (NOLOCK) ON Stk_C.ConditionId = SL.ConditionId
						 LEFT JOIN [dbo].[ItemMasterPurchaseSale] IMPS WITH (NOLOCK) ON IM.ItemMasterId = IMPS.ItemMasterId AND WOM.ConditionCodeId = IMPS.ConditionId
						 LEFT JOIN [dbo].[ItemClassification] ITC WITH (NOLOCK) ON ITC.ItemClassificationId = IM.ItemClassificationId
						 LEFT JOIN [dbo].[Provision] SP WITH (NOLOCK) ON SP.ProvisionId = MSTL.ProvisionId
						 LEFT JOIN [dbo].[Task] T WITH (NOLOCK) ON T.TaskId = WOM.TaskId
						 LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOM.TaskId
						 LEFT JOIN [dbo].[SubWorkOrder] SWO WITH (NOLOCK) ON SWO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND SWO.StockLineId = MSTL.StockLineId
						 LEFT JOIN [dbo].[RepairOrder] RO WITH (NOLOCK) ON SL.RepairOrderId = RO.RepairOrderId
						 LEFT JOIN [dbo].[RepairOrder] WOMS_RO WITH (NOLOCK) ON MSTL.RepairOrderId = WOMS_RO.RepairOrderId
						 LEFT JOIN [dbo].[RepairOrderPart] ROP WITH (NOLOCK) ON ROP.RepairOrderId = WOMS_RO.RepairOrderId AND ROP.ItemMasterId = MSTL.ItemMasterId AND ISNULL(ROP.[IsPiecePart], 0) = 0--SL.RepairOrderPartRecordId = ROP.RepairOrderPartRecordId
						 LEFT JOIN [dbo].[ItemMaster] IMS WITH (NOLOCK) ON IMS.ItemMasterId = MSTL.ItemMasterId
					WHERE WOM.[IsDeleted] = 0 AND WOM.[WorkFlowWorkOrderId] = @WorkFlowWorkOrderId
					AND (ISNULL(WOM.[Quantity],0) - ISNULL(WOM.[QuantityIssued],0) > 0)

					UNION ALL 

--------------------------------------------------MATERIAL KIT--------------------------------------------------

				 SELECT DISTINCT
				        SL.[StockLineNumber],
				        SL.[SerialNumber],
						IMS.[PartNumber],
						IMS.[PartDescription],
						IM.[ManufacturerName],
						Stk_C.[Description]  StocklineCondition,
						MM.[Name] [MandatoryOrSupplemental],
						SP.[Description] [StocklineProvision],
						ISNULL(MSTL.[Quantity],0) [StocklineQuantity],
						ISNULL(MSTL.[Quantity],0) [kitStocklineQty],
						ISNULL(MSTL.[QtyReserved],0) [StocklineQtyReserved],
						ISNULL(MSTL.[Quantity], 0) - (ISNULL(MSTL.QtyIssued,0) + ISNULL(MSTL.QtyReserved,0)) [StocklineQtytobeReserved],
						ISNULL(MSTL.[QtyIssued],0) [StocklineQtyIssued],
						ISNULL(MSTL.[Quantity], 0) - ISNULL(MSTL.[QtyIssued],0) [StocklineQtyRemaining],
						ISNULL(CASE WHEN MSTL.[ProvisionId] = @SubProvisionId AND ISNULL(MSTL.Quantity, 0) != 0 THEN MSTL.[Quantity] 
						  ELSE CASE WHEN MSTL.[ProvisionId] = @SubProvisionId OR MSTL.[ProvisionId] = @ForStockProvisionId THEN SL.[QuantityTurnIn] ELSE 0 END END,0) StocklineQtyToTurnIn,
                        ISNULL(MSTL.[QuantityTurnIn], 0) [StocklineQuantityTurnIn],
						ISNULL(SL.[QuantityOnHand],0) [StockLineQuantityOnHand],
						ISNULL(SL.[QuantityAvailable],0) [StockLineQuantityAvailable],
						CASE WHEN SUOM.[UnitOfMeasureId] IS NOT NULL THEN SUOM.[ShortName] ELSE UOM.[ShortName] END UOM,
						CASE WHEN IM.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'
							 WHEN IM.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'
						     WHEN IM.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'
						     ELSE 'OEM'
						END [StockType],
						NULL [NeedDate],
						[Currency] = (SELECT TOP 1 CUR.Code FROM [dbo].[ItemMasterPurchaseSale] IMPS WITH (NOLOCK) LEFT JOIN [dbo].[Currency] CUR WITH (NOLOCK) ON IMPS.PP_CurrencyId = CUR.CurrencyId 
									  WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId),
                        ISNULL(MSTL.UnitCost,0) [StocklineUnitCost],
						ISNULL(MSTL.ExtendedCost,0) [StocklineExtendedCost],
						UPPER(WOM.CreatedBy) [Employeename],
						SL.[IdNumber] [ControlId],
						SL.[ControlNumber] [ControlNo],
						[CostDate] = (SELECT TOP 1 CONVERT(VARCHAR, IMPS.PP_LastListPriceDate, 101) FROM [dbo].[ItemMasterPurchaseSale] IMPS WITH (NOLOCK)
									WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId AND IMPS.PP_LastListPriceDate IS NOT NULL),
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.RepairOrderNumber ELSE RO.RepairOrderNumber END RepairOrderNumber,
						CASE WHEN SL.RepairOrderPartRecordId IS NOT NULL AND MSTL.RepairOrderId > 0 THEN SL.ReceivedDate ELSE ROP.EstRecordDate END RONextDlvrDate,
						SL.ReceiverNumber [Receiver],
						CASE WHEN ISNULL(MSTL.StockLineId,0)=0 THEN WOM.Figure ELSE MSTL.Figure END StockLineFigure,
						CASE WHEN ISNULL(MSTL.StockLineId,0)=0 THEN WOM.Item ELSE MSTL.Item END StockLineItem,
						SL.[WorkOrderNumber],
						CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.IsDeleted = 1 THEN '' ELSE SWO.SubWorkOrderNo END [SubWorkOrderNo],
						'' [SalesOrder],
						WOM.[Memo],
						'Yes' [IsKitItem]
					FROM [dbo].[WorkOrderMaterialsKit] WOM WITH (NOLOCK)  
						INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
						INNER JOIN [dbo].[UnitOfMeasure] UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
						INNER JOIN [dbo].[MaterialMandatories] MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId
						INNER JOIN [dbo].[WorkOrderMaterialStockLineKit] MSTL WITH (NOLOCK) ON MSTL.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND MSTL.IsDeleted = 0
						 LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId
						 LEFT JOIN [dbo].[UnitOfMeasure] SUOM WITH (NOLOCK) ON SUOM.UnitOfMeasureId = SL.PurchaseUnitOfMeasureId
						 LEFT JOIN [dbo].[Condition] Stk_C WITH (NOLOCK) ON Stk_C.ConditionId = SL.ConditionId
						 LEFT JOIN [dbo].[Provision] SP WITH (NOLOCK) ON SP.ProvisionId = MSTL.ProvisionId
						 LEFT JOIN [dbo].[Task] T WITH (NOLOCK) ON T.TaskId = WOM.TaskId
						 LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOM.TaskId
						 LEFT JOIN [dbo].[SubWorkOrder] SWO WITH (NOLOCK) ON SWO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND SWO.StockLineId = MSTL.StockLineId
						 LEFT JOIN [dbo].[RepairOrder] RO WITH (NOLOCK) ON SL.RepairOrderId = RO.RepairOrderId
						 LEFT JOIN [dbo].[RepairOrder] WOMS_RO WITH (NOLOCK) ON MSTL.RepairOrderId = WOMS_RO.RepairOrderId
						 LEFT JOIN [dbo].[RepairOrderPart] ROP WITH (NOLOCK) ON ROP.RepairOrderId = WOMS_RO.RepairOrderId AND ROP.ItemMasterId = MSTL.ItemMasterId AND ISNULL(ROP.[IsPiecePart], 0) = 0--SL.RepairOrderPartRecordId = ROP.RepairOrderPartRecordId
						 LEFT JOIN [dbo].[ItemMaster] IMS WITH (NOLOCK) ON IMS.ItemMasterId = MSTL.ItemMasterId
					WHERE WOM.[IsDeleted] = 0 AND WOM.[WorkFlowWorkOrderId] = @WorkFlowWorkOrderId
						AND (ISNULL(WOM.[Quantity],0) - ISNULL(WOM.[QuantityIssued],0) > 0)
				)
				SELECT * FROM MaterialResult
				END
				ELSE
				BEGIN
					--------------------------------------------------MATERIAL STOCKLINE--------------------------------------------------
				   ;WITH MaterialResult AS ( 
					SELECT DISTINCT SL.[StockLineNumber],
					       SL.[SerialNumber],						   
						  IMS.[PartNumber],						
						  IMS.[PartDescription],
						   IM.[ManufacturerName],
						  Stk_C.[Description] [StocklineCondition],
						  MM.[Name] [MandatoryOrSupplemental],
						  SP.[Description] [StocklineProvision],
						  ISNULL(MSTL.[Quantity],0) [StocklineQuantity],
						  ISNULL(MSTL.[Quantity],0) [kitStocklineQty],
						  ISNULL(MSTL.[QtyReserved],0) [StocklineQtyReserved],
						  ISNULL(MSTL.[Quantity], 0) - (ISNULL(MSTL.[QtyIssued],0) + ISNULL(MSTL.[QtyReserved],0)) [StocklineQtytobeReserved],
						  ISNULL(MSTL.[QtyIssued],0) [StocklineQtyIssued],
						  ISNULL(MSTL.[Quantity], 0) - ISNULL(MSTL.[QtyIssued],0) [StocklineQtyRemaining],
						  ISNULL(CASE WHEN MSTL.[ProvisionId] = @SubProvisionId AND ISNULL(MSTL.[Quantity], 0) != 0 THEN MSTL.[Quantity]
							ELSE CASE WHEN MSTL.[ProvisionId] = @SubProvisionId OR MSTL.[ProvisionId] = @ForStockProvisionId THEN SL.[QuantityTurnIn] ELSE 0 END END,0) [StocklineQtyToTurnIn],
						  ISNULL(MSTL.[QuantityTurnIn], 0) [StocklineQuantityTurnIn],
						  ISNULL(SL.[QuantityOnHand],0) [StockLineQuantityOnHand],  
						  ISNULL(SL.[QuantityAvailable],0) [StockLineQuantityAvailable],  
						  CASE WHEN SUOM.[UnitOfMeasureId] IS NOT NULL THEN SUOM.[ShortName] ELSE UOM.[ShortName] END AS UOM,
						  CASE WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
							   WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
						       WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
						       ELSE 'OEM'
						  END [StockType],
						  NULL [NeedDate],
						  [Currency] = (SELECT TOP 1 CUR.Code FROM [dbo].[ItemMasterPurchaseSale] IMPS WITH (NOLOCK) 
									    LEFT JOIN [dbo].[Currency] CUR WITH (NOLOCK)  ON IMPS.PP_CurrencyId = CUR.CurrencyId 
									    WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId),
						  ISNULL(MSTL.[UnitCost],0) [StocklineUnitCost],
						  ISNULL(MSTL.[ExtendedCost],0) [StocklineExtendedCost],
						  UPPER(WOM.CreatedBy) [Employeename],
						  SL.[ControlNumber] [ControlNo],
						  SL.[IdNumber] [ControlId],
						  [CostDate] = (SELECT TOP 1 CONVERT(varchar, IMPS.PP_LastListPriceDate, 101) FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK)
									  WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId AND IMPS.PP_LastListPriceDate IS NOT NULL),
						  CASE WHEN WOMS_RO.[RepairOrderId] IS NOT NULL THEN WOMS_RO.[RepairOrderNumber] ELSE RO.[RepairOrderNumber] END AS 'RepairOrderNumber',
						  			CASE WHEN SL.RepairOrderPartRecordId IS NOT NULL AND MSTL.RepairOrderId > 0 THEN SL.ReceivedDate ELSE ROP.EstRecordDate END AS 'RONextDlvrDate',
                         SL.ReceiverNumber [Receiver],
						 MSTL.Figure [StockLineFigure],
						 MSTL.Item [StockLineItem],
						 SL.[WorkOrderNumber],
						 CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.IsDeleted = 1 THEN '' ELSE SWO.SubWorkOrderNo END [SubWorkOrderNo],
						 '' [SalesOrder],
						 WOM.[Memo],
						 'No' [IsKitItem]
					FROM [dbo].[WorkOrderMaterials] WOM WITH (NOLOCK)  
						INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
						INNER JOIN [dbo].[UnitOfMeasure] UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
						INNER JOIN [dbo].[MaterialMandatories] MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId
					    INNER JOIN [dbo].[WorkOrderMaterialStockLine] MSTL WITH (NOLOCK) ON MSTL.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND MSTL.IsDeleted = 0
						 LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId
						 LEFT JOIN [dbo].[UnitOfMeasure] SUOM WITH (NOLOCK) ON SUOM.UnitOfMeasureId = SL.PurchaseUnitOfMeasureId
						 LEFT JOIN [dbo].[WorkOrderMaterialStockLine] MSTL_PO WITH (NOLOCK) ON MSTL_PO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND MSTL_PO.IsDeleted = 0 AND WOM.ConditionCodeId = MSTL_PO.ConditionId AND WOM.ItemMasterId = MSTL_PO.ItemMasterId AND WOM.POId > 0
						 LEFT JOIN [dbo].[Condition] Stk_C WITH (NOLOCK) ON Stk_C.ConditionId = SL.ConditionId
						 LEFT JOIN [dbo].[ItemMasterPurchaseSale] IMPS WITH (NOLOCK) ON IM.ItemMasterId = IMPS.ItemMasterId AND WOM.ConditionCodeId = IMPS.ConditionId
						 LEFT JOIN [dbo].[ItemClassification] ITC WITH (NOLOCK) ON ITC.ItemClassificationId = IM.ItemClassificationId
						 LEFT JOIN [dbo].[Provision] SP WITH (NOLOCK) ON SP.ProvisionId = MSTL.ProvisionId
						 LEFT JOIN [dbo].[Task] T WITH (NOLOCK) ON T.TaskId = WOM.TaskId
						 LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOM.TaskId
						 LEFT JOIN [dbo].[SubWorkOrder] SWO WITH (NOLOCK) ON SWO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND SWO.StockLineId = MSTL.StockLineId
						 LEFT JOIN [dbo].[RepairOrder] RO WITH (NOLOCK) ON SL.RepairOrderId = RO.RepairOrderId
						 LEFT JOIN [dbo].[RepairOrder] WOMS_RO WITH (NOLOCK) ON MSTL.RepairOrderId = WOMS_RO.RepairOrderId
						 LEFT JOIN [dbo].[RepairOrderPart] ROP WITH (NOLOCK) ON ROP.RepairOrderId = WOMS_RO.RepairOrderId AND ROP.ItemMasterId = MSTL.ItemMasterId AND ISNULL(ROP.[IsPiecePart], 0) = 0--SL.RepairOrderPartRecordId = ROP.RepairOrderPartRecordId
						 LEFT JOIN [dbo].[ItemMaster] IMS WITH (NOLOCK) ON IMS.ItemMasterId = MSTL.ItemMasterId
					WHERE WOM.[IsDeleted] = 0 AND WOM.[WorkFlowWorkOrderId] = @WorkFlowWorkOrderId
					
					UNION ALL 

--------------------------------------------------MATERIAL KIT--------------------------------------------------

				 SELECT DISTINCT SL.[StockLineNumber],
				        SL.[SerialNumber],
						IMS.[PartNumber],
						IMS.[PartDescription],
						IM.[ManufacturerName],
						Stk_C.[Description]  StocklineCondition,
						MM.[Name] [MandatoryOrSupplemental],
						SP.[Description] [StocklineProvision],
						ISNULL(MSTL.[Quantity],0) [StocklineQuantity],
						ISNULL(MSTL.[Quantity],0) [kitStocklineQty],
						ISNULL(MSTL.[QtyReserved],0) [StocklineQtyReserved],
						ISNULL(MSTL.[Quantity], 0) - (ISNULL(MSTL.QtyIssued,0) + ISNULL(MSTL.QtyReserved,0)) [StocklineQtytobeReserved],
						ISNULL(MSTL.[QtyIssued],0) [StocklineQtyIssued],
						ISNULL(MSTL.[Quantity], 0) - ISNULL(MSTL.[QtyIssued],0) [StocklineQtyRemaining],
						ISNULL(CASE WHEN MSTL.[ProvisionId] = @SubProvisionId AND ISNULL(MSTL.Quantity, 0) != 0 THEN MSTL.[Quantity] 
						  ELSE CASE WHEN MSTL.[ProvisionId] = @SubProvisionId OR MSTL.[ProvisionId] = @ForStockProvisionId THEN SL.[QuantityTurnIn] ELSE 0 END END,0) StocklineQtyToTurnIn,
                        ISNULL(MSTL.[QuantityTurnIn], 0) [StocklineQuantityTurnIn],
						ISNULL(SL.[QuantityOnHand],0) [StockLineQuantityOnHand],
						ISNULL(SL.[QuantityAvailable],0) [StockLineQuantityAvailable],
						CASE WHEN SUOM.[UnitOfMeasureId] IS NOT NULL THEN SUOM.[ShortName] ELSE UOM.[ShortName] END UOM,
						CASE WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
							 WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
						     WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
						     ELSE 'OEM'
						END [StockType],
						NULL [NeedDate],
						[Currency] = (SELECT TOP 1 CUR.Code FROM [dbo].[ItemMasterPurchaseSale] IMPS WITH (NOLOCK) LEFT JOIN [dbo].[Currency] CUR WITH (NOLOCK) ON IMPS.PP_CurrencyId = CUR.CurrencyId 
									  WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId),
                        ISNULL(MSTL.UnitCost,0) [StocklineUnitCost],
						ISNULL(MSTL.ExtendedCost,0) [StocklineExtendedCost],
						UPPER(WOM.CreatedBy) [Employeename],
						SL.[IdNumber] [ControlId],
						SL.[ControlNumber] [ControlNo],
						[CostDate] = (SELECT TOP 1 CONVERT(VARCHAR, IMPS.PP_LastListPriceDate, 101) FROM [dbo].[ItemMasterPurchaseSale] IMPS WITH (NOLOCK)
									WHERE IMPS.ItemMasterId = WOM.ItemMasterId AND IMPS.ConditionId = WOM.ConditionCodeId AND IMPS.PP_LastListPriceDate IS NOT NULL),
						CASE WHEN WOMS_RO.RepairOrderId IS NOT NULL THEN WOMS_RO.RepairOrderNumber ELSE RO.RepairOrderNumber END RepairOrderNumber,
						CASE WHEN SL.RepairOrderPartRecordId IS NOT NULL AND MSTL.RepairOrderId > 0 THEN SL.ReceivedDate ELSE ROP.EstRecordDate END RONextDlvrDate,
						SL.ReceiverNumber [Receiver],
						CASE WHEN ISNULL(MSTL.StockLineId,0)=0 THEN WOM.Figure ELSE MSTL.Figure END StockLineFigure,
						CASE WHEN ISNULL(MSTL.StockLineId,0)=0 THEN WOM.Item ELSE MSTL.Item END StockLineItem,
						SL.[WorkOrderNumber],
						CASE WHEN SWO.SubWorkOrderId > 0 AND SWO.IsDeleted = 1 THEN '' ELSE SWO.SubWorkOrderNo END [SubWorkOrderNo],
						'' [SalesOrder],
						WOM.[Memo],
						'Yes' [IsKitItem]
					FROM [dbo].[WorkOrderMaterialsKit] WOM WITH (NOLOCK)  
						INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
						INNER JOIN [dbo].[UnitOfMeasure] UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId						
						INNER JOIN [dbo].[MaterialMandatories] MM WITH (NOLOCK) ON MM.Id = WOM.MaterialMandatoriesId
						INNER JOIN [dbo].[WorkOrderMaterialStockLineKit] MSTL WITH (NOLOCK) ON MSTL.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND MSTL.IsDeleted = 0
						 LEFT JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON SL.StockLineId = MSTL.StockLineId
						 LEFT JOIN [dbo].[UnitOfMeasure] SUOM WITH (NOLOCK) ON SUOM.UnitOfMeasureId = SL.PurchaseUnitOfMeasureId
						 LEFT JOIN [dbo].[Condition] Stk_C WITH (NOLOCK) ON Stk_C.ConditionId = SL.ConditionId						
						 LEFT JOIN [dbo].[Provision] SP WITH (NOLOCK) ON SP.ProvisionId = MSTL.ProvisionId
						 LEFT JOIN [dbo].[Task] T WITH (NOLOCK) ON T.TaskId = WOM.TaskId
						 LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOM.TaskId
						 LEFT JOIN [dbo].[SubWorkOrder] SWO WITH (NOLOCK) ON SWO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND SWO.StockLineId = MSTL.StockLineId
						 LEFT JOIN [dbo].[RepairOrder] RO WITH (NOLOCK) ON SL.RepairOrderId = RO.RepairOrderId
						 LEFT JOIN [dbo].[RepairOrder] WOMS_RO WITH (NOLOCK) ON MSTL.RepairOrderId = WOMS_RO.RepairOrderId
						 LEFT JOIN [dbo].[RepairOrderPart] ROP WITH (NOLOCK) ON ROP.RepairOrderId = WOMS_RO.RepairOrderId AND ROP.ItemMasterId = MSTL.ItemMasterId AND ISNULL(ROP.[IsPiecePart], 0) = 0--SL.RepairOrderPartRecordId = ROP.RepairOrderPartRecordId						
						 LEFT JOIN [dbo].[ItemMaster] IMS WITH (NOLOCK) ON IMS.ItemMasterId = MSTL.ItemMasterId
					WHERE WOM.[IsDeleted] = 0 AND WOM.[WorkFlowWorkOrderId] = @WorkFlowWorkOrderId			
				)
			    SELECT* FROM MaterialResult 
				END			
			END
		END
	END TRY
	BEGIN CATCH   
		SELECT ERROR_NUMBER() AS ErrorNumber,ERROR_STATE() AS ErrorState, ERROR_SEVERITY() AS ErrorSeverity,ERROR_PROCEDURE() AS ErrorProcedure, ERROR_LINE() AS ErrorLine,ERROR_MESSAGE() AS ErrorMessage;		
			IF @@trancount > 0								
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderMaterialsDownload'              
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100)) + '@Parameter2 = ''' + CAST(ISNULL(@WorkFlowWorkOrderId, '') AS VARCHAR(100)) 
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
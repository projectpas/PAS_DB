﻿/*************************************************************             
 ** File:   [USP_ReserveStocklineForReceivingPO]            
 ** Author:   Vishal Suthar  
 ** Description: This stored procedure is used to reserve stocklines for receiving PO
 ** Purpose:           
 ** Date:   09/11/2023          
            
 ** PARAMETERS:  
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    09/11/2023   Vishal Suthar		Created
    2    10/30/2023   Vishal Suthar		Added a fix for reserving the stockline into multiple MPN in WO Module
    3    12/08/2023   Devendra Shekh	workorderid issue for stockline table resolved
	4    12/19/2023   Rajesh Gami		Change the SOPart status(Fulfilled) when PO reserve where SO mapped with same PO
	5    12/21/2023   Devendra Shekh	changes for sub for kit and multiple material
	6    04/08/2024   Vishal Suthar		Modified the condition to fix the issue with partial qty reservation
	7    07/30/2024   Vishal Suthar		Modified the SP to allow reserving the alternate or main part of the alternate if either or is available in WO
	8    08/13/2024   Vishal Suthar		Modified the SP to allow reserving the equavalent or main part of the equavalent if either or is available in WO
	9    08/27/2024   Vishal Suthar		Fixed issue with reserving higer qty than assigned and also Removed few unwanted code
    10   10/08/2024   RAJESH GAMI 	    Implement the ReferenceNumber column data into "WO | SubWOMaterial | Kit Stockline" table.
	11   10/14/2024   Vishal Suthar		Fixed issue with reserving and adding the wrong stockline under different WO material

exec dbo.USP_ReserveStocklineForReceivingPO @PurchaseOrderId=2718,@SelectedPartsToReserve=N'862',@UpdatedBy=N'ADMIN User',@AllowAutoIssue=default
**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_ReserveStocklineForReceivingPO]
(
	@PurchaseOrderId BIGINT = NULL,
	@SelectedPartsToReserve VARCHAR(256) = NULL,
	@UpdatedBy VARCHAR(100) = NULL,
	@AllowAutoIssue BIT = 0
)
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON
  
    BEGIN TRY
    BEGIN TRANSACTION
    BEGIN
		DECLARE @StkLoopID AS INT;
		DECLARE @LoopID AS INT;
		DECLARE @ReplaceProvisionId AS BIGINT = 0, @MaterialRefNo VARCHAR(100) = 'Receiving PO - ';
		DECLARE @soPartFulfilledStatusId INT = (SELECT SOPartStatusId FROM DBO.SOPartStatus WITH(NOLOCK) WHERE Description = 'Fulfilled');
		SELECT @ReplaceProvisionId = PRO.ProvisionId FROM DBO.Provision PRO WITH (NOLOCK) WHERE PRO.StatusCode = 'REPLACE' AND IsActive = 1 AND IsDeleted = 0;

		IF OBJECT_ID(N'tempdb..#tmpPurchaseOrderPartReference') IS NOT NULL
		BEGIN
			DROP TABLE #tmpPurchaseOrderPartReference
		END
		
		CREATE TABLE #tmpPurchaseOrderPartReference 
		(
			ID BIGINT NOT NULL IDENTITY,
			[PurchaseOrderPartReferenceId] [bigint] NULL,
			[PurchaseOrderId] [bigint] NULL,
			[PurchaseOrderPartId] [bigint] NULL,
			[ModuleId] [int] NULL,
			[ReferenceId] [bigint] NULL,
			[Qty] [int] NULL,
			[RequestedQty] [int] NULL,
			[ReservedQty] [int] NULL,
			[MasterCompanyId] [int] NULL,
			[CreatedBy] [varchar](256) NULL,
			[UpdatedBy] [varchar](256) NULL,
			[CreatedDate] [datetime2](7) NULL,
			[UpdatedDate] [datetime2](7) NULL,
			[IsActive] [bit] NULL,
			[IsDeleted] [bit] NULL
		)

		INSERT INTO #tmpPurchaseOrderPartReference ([PurchaseOrderPartReferenceId],[PurchaseOrderId],[PurchaseOrderPartId],[ModuleId],[ReferenceId],[Qty],
		[RequestedQty], [ReservedQty], [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
		SELECT [PurchaseOrderPartReferenceId],[PurchaseOrderId],[PurchaseOrderPartId],[ModuleId],[ReferenceId],[Qty],
		[RequestedQty], [ReservedQty], [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted]
		FROM DBO.PurchaseOrderPartReference POPR WITH (NOLOCK) 
		WHERE POPR.PurchaseOrderPartReferenceId IN (SELECT Item FROM DBO.SPLITSTRING(@SelectedPartsToReserve, ','))

		SELECT @LoopID = MAX(ID) FROM #tmpPurchaseOrderPartReference;
		WHILE (@LoopID > 0)
		BEGIN
			DECLARE @SelectedPurchaseOrderPartReferenceId BIGINT = 0;
			DECLARE @SelectedPurchaseOrderPartId BIGINT = 0;
			DECLARE @ModulId INT = 0;
			DECLARE @ReferenceId BIGINT;
			DECLARE @PurchaseOrderPartId BIGINT;
			DECLARE @POReferenceQty INT;
			DECLARE @InsertedWorkOrderMaterialsId BIGINT = 0;
			DECLARE @Quantity INT;
			DECLARE @QuantityReserved INT;
			DECLARE @QuantityIssued INT;
			DECLARE @ItemMasterId BIGINT;
			DECLARE @ConditionId BIGINT;
			DECLARE @Requisitioner BIGINT;
			DECLARE @PONumber VARCHAR(100) = '';

			DECLARE @QuantityReservedForPoPart INT = 0;
			DECLARE @QuantityIssuedForPoPart INT = 0;

			SELECT @SelectedPurchaseOrderPartReferenceId = PurchaseOrderPartReferenceId, @SelectedPurchaseOrderPartId = [PurchaseOrderPartId] FROM #tmpPurchaseOrderPartReference WHERE ID = @LoopID;

			SELECT @ModulId = POPR.ModuleId, @ReferenceId = POPR.ReferenceId, @PurchaseOrderPartId = PurchaseOrderPartId, @POReferenceQty = (ISNULL(POPR.Qty, 0) - ISNULL(POPR.ReservedQty, 0)) FROM DBO.PurchaseOrderPartReference POPR WITH (NOLOCK) 
			WHERE PurchaseOrderPartReferenceId = @SelectedPurchaseOrderPartReferenceId;

			IF OBJECT_ID(N'tempdb..#tmpStockline') IS NOT NULL
			BEGIN
				DROP TABLE #tmpStockline
			END 
			
			CREATE TABLE #tmpStockline 
			(
				ID BIGINT NOT NULL IDENTITY,
				[StocklineId] [bigint] NULL,
				[PurchaseOrderPartId] [bigint] NULL
			)

			INSERT INTO #tmpStockline (StocklineId, PurchaseOrderPartId)
			--SELECT StocklineId, Stk.PurchaseOrderPartRecordId FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.PurchaseOrderId = @PurchaseOrderId AND Stk.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartId
			SELECT StocklineId, Stk.PurchaseOrderPartRecordId FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.PurchaseOrderId = @PurchaseOrderId AND ((Stk.PurchaseOrderPartRecordId = @SelectedPurchaseOrderPartId) OR
			Stk.PurchaseOrderPartRecordId IN (SELECT PurchaseOrderPartRecordId FROM DBO.PurchaseOrderPart POP WITH (NOLOCK) WHERE POP.ParentId = @SelectedPurchaseOrderPartId))
			AND Stk.IsParent = 1 AND Stk.QuantityAvailable > 0 ORDER BY StocklineId DESC; 
		
			SELECT @StkLoopID = MAX(ID) FROM #tmpStockline;

			WHILE (@StkLoopID > 0 AND @POReferenceQty > 0)
			BEGIN
				DECLARE @StkStocklineId BIGINT = 0;
				DECLARE @StkPurchaseOrderPartRecordId BIGINT;
				DECLARE @stkQty INT = 0;
				DECLARE @stkMasterCompanyId INT = 0;
				DECLARE @stkQuantityAvailable INT = 0;
				DECLARE @stkQuantityOnHand INT = 0;
				DECLARE @stkQuantityReserved INT = 0;
				DECLARE @stkQuantityIssued INT = 0;
				DECLARE @stkQuantityOnOrder INT = 0;
				DECLARE @stkItemMasterId BIGINT = 0;
				DECLARE @stkConditionId BIGINT = 0;
				DECLARE @stkWorkOrderMaterialsId BIGINT = 0;
				DECLARE @stkWorkOrderMaterialsKitId BIGINT = 0;
				DECLARE @stkSalesOrderPartId BIGINT = 0;
				DECLARE @stkPurchaseOrderUnitCost DECIMAL(18, 2) = 0;
				DECLARE @Qty INT = 0;
				DECLARE @qtyFulfilled AS BIT = 0;
				DECLARE @flag AS BIT = 0;
				DECLARE @WOMSQtyReserved BIGINT = 0;
				DECLARE @WOMSQtyIssued BIGINT = 0, @WOMSQuantity BIGINT = 0;
				DECLARE @ExchangePOProvisionId BIGINT = 0;

				SELECT @ExchangePOProvisionId = PRO.ProvisionId FROM DBO.Provision PRO WITH (NOLOCK) WHERE PRO.StatusCode = 'EXCHANGE' AND IsActive = 1 AND IsDeleted = 0;

				SELECT @StkStocklineId = [StocklineId], @StkPurchaseOrderPartRecordId = [PurchaseOrderPartId] FROM #tmpStockline WHERE ID = @StkLoopID;
				
				IF (@ModulId = 1) -- Work Order
				BEGIN
					SET @ItemMasterId = 0;
					SET @ConditionId = 0;
					SET @Requisitioner = 0;
					SET @PONumber = '';
					DECLARE @WorkOrderMaterialsIdExchPO BIGINT = 0;
					DECLARE @IsExchangePO BIT = 0;
					DECLARE @IsAutoIssue BIT = 0;
					DECLARE @MasterCompanyId BIGINT = 0;
					DECLARE @WorkOrderTypeId BIGINT = 0;

					SELECT @ItemMasterId = POP.ItemMasterId, @ConditionId = POP.ConditionId, @WorkOrderMaterialsIdExchPO = ISNULL(POP.WorkOrderMaterialsId, 0), @MasterCompanyId = POP.MasterCompanyId FROM DBO.PurchaseOrderPart POP WITH (NOLOCK) WHERE PurchaseOrderPartRecordId = @PurchaseOrderPartId;
					SELECT @Requisitioner = PO.RequestedBy, @PONumber = PO.PurchaseOrderNumber FROM DBO.PurchaseOrder PO WITH (NOLOCK) WHERE PO.PurchaseOrderId = @PurchaseOrderId;
					
					SELECT @WorkOrderTypeId = WO.WorkOrderTypeId FROM DBO.WorkOrder WO WITH (NOLOCK) WHERE WO.WorkOrderId = @ReferenceId;
					
					SELECT @IsAutoIssue = 0;
					IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkOrderMaterials WOM WITH (NOLOCK) WHERE WOM.WorkOrderId = @ReferenceId AND WOM.ItemMasterId = @ItemMasterId AND WOM.WorkOrderMaterialsId = @WorkOrderMaterialsIdExchPO AND WOM.ProvisionId = @ExchangePOProvisionId)
					BEGIN
						SET @IsExchangePO = 1;
					END
					
					DECLARE @ReservedIntoMaterial BIT = 0;

					IF OBJECT_ID(N'tempdb..#WorkOrderMaterialWithWorkOrderWorkFlow') IS NOT NULL
					BEGIN
						DROP TABLE #WorkOrderMaterialWithWorkOrderWorkFlow
					END 
			
					CREATE TABLE #WorkOrderMaterialWithWorkOrderWorkFlow 
					(
						ID BIGINT NOT NULL IDENTITY,
						[WorkOrderId] [bigint] NULL,
						[WorkFlowWorkOrderId] [bigint] NULL
					)

					IF (@IsExchangePO = 0)
					BEGIN
						INSERT INTO #WorkOrderMaterialWithWorkOrderWorkFlow (WorkOrderId, WorkFlowWorkOrderId)
						SELECT DISTINCT WorkOrderId, WorkFlowWorkOrderId FROM DBO.WorkOrderMaterials WOM WITH (NOLOCK) 
						LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha ON Nha.ItemMasterId = WOM.ItemMasterId
						WHERE WOM.WorkOrderId = @ReferenceId AND (WOM.ItemMasterId = @ItemMasterId OR Nha.ItemMasterId = WOM.ItemMasterId) AND WOM.ConditionCodeId = @ConditionId; 

						INSERT INTO #WorkOrderMaterialWithWorkOrderWorkFlow (WorkOrderId, WorkFlowWorkOrderId)
						SELECT DISTINCT WorkOrderId, WorkFlowWorkOrderId FROM DBO.WorkOrderMaterialsKit WOMK WITH (NOLOCK) 
						LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha ON Nha.ItemMasterId = WOMK.ItemMasterId
						WHERE WOMK.WorkOrderId = @ReferenceId AND (WOMK.ItemMasterId = @ItemMasterId OR Nha.ItemMasterId = WOMK.ItemMasterId) AND WOMK.ConditionCodeId = @ConditionId; 
					END
					ELSE
					BEGIN
						INSERT INTO #WorkOrderMaterialWithWorkOrderWorkFlow (WorkOrderId, WorkFlowWorkOrderId)
						SELECT DISTINCT WorkOrderId, WorkFlowWorkOrderId FROM DBO.WorkOrderMaterials WOM WITH (NOLOCK) WHERE WOM.WorkOrderMaterialsId = @WorkOrderMaterialsIdExchPO;
						
						INSERT INTO #WorkOrderMaterialWithWorkOrderWorkFlow (WorkOrderId, WorkFlowWorkOrderId)
						SELECT DISTINCT WorkOrderId, WorkFlowWorkOrderId FROM DBO.WorkOrderMaterialsKit WOMK WITH (NOLOCK) WHERE WOMK.WorkOrderMaterialsKitId = @WorkOrderMaterialsIdExchPO;
					END
					DECLARE @LoopIDWFWO INT = 0;

					SELECT @LoopIDWFWO = MAX(ID) FROM #WorkOrderMaterialWithWorkOrderWorkFlow;

					WHILE (@LoopIDWFWO > 0)
					BEGIN
						DECLARE @WorkFlowWorkOrderId BIGINT = 0;

						SELECT @WorkFlowWorkOrderId = [WorkFlowWorkOrderId] FROM #WorkOrderMaterialWithWorkOrderWorkFlow WHERE ID = @LoopIDWFWO;

						IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkOrderMaterials WOM WITH (NOLOCK) LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha ON Nha.ItemMasterId = WOM.ItemMasterId WHERE WOM.WorkOrderId = @ReferenceId AND (WOM.ItemMasterId = @ItemMasterId OR Nha.ItemMasterId = WOM.ItemMasterId) AND WOM.ConditionCodeId = @ConditionId AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId) OR @IsExchangePO = 1
						BEGIN
							DECLARE @SelectedWorkOrderMaterialsId INT = 0;
							DECLARE @AltPartId BIGINT = 0;
							DECLARE @EquPartId BIGINT = 0;
						
							IF (@IsExchangePO = 0)
							BEGIN
								SELECT @SelectedWorkOrderMaterialsId = WOM.WorkOrderMaterialsId, @AltPartId = Nha_Alt.MappingItemMasterId,
								@EquPartId = Nha_Equ.MappingItemMasterId 
								FROM DBO.WorkOrderMaterials WOM WITH (NOLOCK) 
								LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha_Alt ON Nha_Alt.ItemMasterId = WOM.ItemMasterId AND Nha_Alt.MappingType = 1
								LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha_Equ ON Nha_Equ.ItemMasterId = WOM.ItemMasterId AND Nha_Equ.MappingType = 2
								WHERE WOM.WorkOrderId = @ReferenceId AND (WOM.ItemMasterId = @ItemMasterId OR Nha_Alt.ItemMasterId = WOM.ItemMasterId OR Nha_Equ.ItemMasterId = WOM.ItemMasterId) AND WOM.ConditionCodeId = @ConditionId;-- AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId;
								--WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId;
							END
							ELSE
							BEGIN
								SELECT @SelectedWorkOrderMaterialsId = WOM.WorkOrderMaterialsId FROM DBO.WorkOrderMaterials WOM WITH (NOLOCK) 
								WHERE WOM.WorkOrderMaterialsId = @WorkOrderMaterialsIdExchPO;
							END
					
							SET @Quantity = 0;
							SET @QuantityReserved = 0;
							SET @QuantityIssued = 0;

							IF(@IsExchangePO = 1)
							BEGIN
								SELECT @Quantity = WOM.Quantity, @QuantityReserved = ISNULL(WOM.QuantityReserved, 0), @QuantityIssued = ISNULL(WOM.QuantityIssued, 0), @WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId FROM DBO.WorkOrderMaterials WOM WITH (NOLOCK)
								LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha_Alt ON Nha_Alt.ItemMasterId = WOM.ItemMasterId AND Nha_Alt.MappingType = 1
								LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha_Euq ON Nha_Euq.ItemMasterId = WOM.ItemMasterId AND Nha_Euq.MappingType = 2
								WHERE WOM.WorkOrderId = @ReferenceId AND (WOM.ItemMasterId = @ItemMasterId OR Nha_Alt.ItemMasterId = WOM.ItemMasterId OR Nha_Euq.ItemMasterId = WOM.ItemMasterId) AND WOM.WorkOrderMaterialsId = @WorkOrderMaterialsIdExchPO AND WOM.ProvisionId = @ExchangePOProvisionId;
							END
							ELSE
							BEGIN
								SELECT @Quantity = WOM.Quantity, @QuantityReserved = ISNULL(WOM.QuantityReserved, 0), @QuantityIssued = ISNULL(WOM.QuantityIssued, 0) FROM DBO.WorkOrderMaterials WOM WITH (NOLOCK)
								LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha_Alt ON Nha_Alt.ItemMasterId = WOM.ItemMasterId
								LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha_Equ ON Nha_Equ.ItemMasterId = WOM.ItemMasterId
								WHERE WOM.WorkOrderId = @ReferenceId AND (WOM.ItemMasterId = @ItemMasterId OR Nha_Alt.ItemMasterId = WOM.ItemMasterId OR Nha_Equ.ItemMasterId = WOM.ItemMasterId) AND WOM.ConditionCodeId = @ConditionId;-- AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId;
							END
					
							DECLARE @OriginalQuantity INT = 0;

							SET @OriginalQuantity = @Quantity;

							DECLARE @MainPOReferenceQty INT = 0;
							SELECT @MainPOReferenceQty = (ISNULL(POPR.Qty, 0) - ISNULL(POPR.ReservedQty, 0)) FROM DBO.PurchaseOrderPartReference POPR WITH (NOLOCK) WHERE PurchaseOrderPartReferenceId = @SelectedPurchaseOrderPartReferenceId;

							IF (@MainPOReferenceQty < @Quantity)
							BEGIN
								SET @Quantity = @MainPOReferenceQty;
							END
							IF (@MainPOReferenceQty < @OriginalQuantity)
							BEGIN
								SET @OriginalQuantity = @MainPOReferenceQty;
							END

							IF ((@OriginalQuantity - (@QuantityReserved + @QuantityIssued)) > 0)
							BEGIN
								IF (@SelectedWorkOrderMaterialsId > 0)
								BEGIN
									SET @Qty = 0;
									SET @stkQty = 0;
									SET @stkMasterCompanyId = 0;
									SET @stkQuantityAvailable = 0;
									SET @stkQuantityOnHand = 0;
									SET @stkQuantityReserved = 0;
									SET @stkQuantityIssued = 0;
									SET @stkQuantityOnOrder = 0;
									SET @stkItemMasterId = 0;
									SET @stkConditionId = 0;
									SET @stkWorkOrderMaterialsId = 0;
									SET @stkPurchaseOrderUnitCost = 0;

									SELECT @stkMasterCompanyId = Stk.MasterCompanyId, @stkQty = Stk.Quantity, @stkQuantityAvailable = Stk.QuantityAvailable, @stkQuantityOnHand = Stk.QuantityOnHand, @stkQuantityReserved = QuantityReserved,
									@stkQuantityOnOrder = QuantityOnOrder, @stkItemMasterId = Stk.ItemMasterId, @stkConditionId = Stk.ConditionId,
									@stkPurchaseOrderUnitCost = Stk.PurchaseOrderUnitCost
									FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.StockLineId = @StkStocklineId;

									IF (@OriginalQuantity > 0 AND @stkQty > 0)
									BEGIN
										IF (@stkQuantityAvailable > = @OriginalQuantity)
											SET @Qty = @OriginalQuantity - (@QuantityReserved + @QuantityIssued);
										ELSE
											SET @Qty = @stkQuantityAvailable;
									END

									IF (@Qty > 0)
									BEGIN
										UPDATE WOM
										SET WOM.QuantityReserved = ISNULL(WOM.QuantityReserved, 0),
										WOM.TotalReserved = ISNULL(WOM.TotalReserved, 0),
										WOM.QuantityIssued = ISNULL(WOM.QuantityIssued, 0),
										WOM.TotalIssued = ISNULL(WOM.TotalIssued, 0)
										,WOM.ConditionCodeId = CASE WHEN @IsExchangePO = 1 THEN @ConditionId ELSE WOM.ConditionCodeId END -- Added by Rajesh: Need to change parent condition while we change the condition from the RPO process.
										FROM DBO.WorkOrderMaterials WOM
										WHERE WOM.WorkOrderMaterialsId = @SelectedWorkOrderMaterialsId;

										IF (@IsAutoIssue = 0)
										BEGIN
											UPDATE WOM
											SET WOM.QuantityReserved = @QuantityReserved + @Qty,
											WOM.TotalReserved = TotalReserved + @Qty,
											WOM.ReservedById = @Requisitioner,
											WOM.ReservedDate = GETUTCDATE(),
											WOM.IssuedById = @Requisitioner,
											WOM.IssuedDate = GETUTCDATE(),
											WOM.PONum = @PONumber,
											WOM.PartStatusId = 1, -- Reserve
											WOM.ExtendedCost = WOM.ExtendedCost + (WOM.UnitCost * @Qty)
											FROM DBO.WorkOrderMaterials WOM
											WHERE WOM.WorkOrderMaterialsId = @SelectedWorkOrderMaterialsId;
										END
										ELSE IF (@IsAutoIssue = 1)
										BEGIN
											UPDATE WOM
											SET WOM.QuantityIssued = @QuantityIssued + @Qty,
											WOM.TotalIssued = TotalIssued + @Qty,
											WOM.IssuedById = @Requisitioner,
											WOM.IssuedDate = GETUTCDATE(),
											WOM.PONum = @PONumber,
											WOM.PartStatusId = 2, -- Issued
											WOM.ExtendedCost = WOM.ExtendedCost + (WOM.UnitCost * @Qty)
											FROM DBO.WorkOrderMaterials WOM
											WHERE WOM.WorkOrderMaterialsId = @SelectedWorkOrderMaterialsId;
										END
									END

									SET @qtyFulfilled = 0;
									SET @flag = 0;

									IF (@StkStocklineId > 0)
									BEGIN
										SET @flag = 0;

										IF (@qtyFulfilled = 0)
										BEGIN
											SET @WOMSQtyReserved = 0;
											SET @WOMSQtyIssued = 0;
											SET @WOMSQuantity = 0;

											IF (@stkQuantityAvailable > 0)
											BEGIN
												IF (@stkQuantityAvailable >= @Qty)
												BEGIN
													IF (@IsAutoIssue = 0)
													BEGIN
														SET @qtyFulfilled = 1;
														SET @stkQuantityAvailable = @stkQuantityAvailable - @Qty;
														SET @stkQuantityReserved = @stkQuantityReserved + @Qty;
														SET @WOMSQtyReserved = @Qty;
													END
													ELSE IF (@IsAutoIssue = 1)
													BEGIN
														SET @qtyFulfilled = 1;
														SET @stkQuantityAvailable = @stkQuantityAvailable - @Qty;
														SET @stkQuantityOnHand = @stkQuantityOnHand - @Qty;
														SET @stkQuantityIssued = @stkQuantityIssued + @Qty;
														SET @WOMSQtyIssued = @Qty;
													END
												END
												ELSE
												BEGIN
													IF (@IsAutoIssue = 0)
													BEGIN
														SET @stkQuantityReserved = @stkQuantityReserved + @stkQuantityAvailable;
														SET @WOMSQtyReserved = @stkQuantityAvailable;
														SET @stkQuantityAvailable = 0;
													END
													ELSE IF (@IsAutoIssue = 1)
													BEGIN
														SET @stkQuantityIssued = @stkQuantityIssued + @stkQuantityAvailable;
														SET @WOMSQtyIssued = @stkQuantityAvailable;
														SET @stkQuantityIssued = 0;
													END
												END

												SET @flag = 1;
											END

											IF (@flag = 1)
											BEGIN
												SET @InsertedWorkOrderMaterialsId = 0;
												IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsId = @SelectedWorkOrderMaterialsId AND WOMS.StockLineId = @StkStocklineId)
												BEGIN
													UPDATE WOMS
													SET WOMS.Quantity = ISNULL(WOMS.Quantity, 0) + @Qty,
													WOMS.QtyReserved = ISNULL(WOMS.QtyReserved, 0) + @Qty,
													WOMS.StockLineId = @StkStocklineId,
													WOMS.UpdatedDate = GETUTCDATE(),
													WOMS.UpdatedBy = @UpdatedBy,
													WOMS.WorkOrderMaterialsId = @SelectedWorkOrderMaterialsId,
													WOMS.ItemMasterId = @stkItemMasterId,
													WOMS.ConditionId = @stkConditionId,
													WOMS.IsAltPart = CASE WHEN @AltPartId = @stkItemMasterId THEN 1 ELSE 0 END,
													WOMS.IsEquPart = CASE WHEN @EquPartId = @stkItemMasterId THEN 1 ELSE 0 END,
													WOMS.UnitCost = @stkPurchaseOrderUnitCost,
													WOMS.ExtendedCost = (@stkPurchaseOrderUnitCost * (ISNULL(WOMS.Quantity, 0) + @Qty)),
													WOMS.UnitPrice = @stkPurchaseOrderUnitCost,
													WOMS.ExtendedPrice = (@stkPurchaseOrderUnitCost * (ISNULL(WOMS.Quantity, 0) + @Qty)),
													WOMS.ReferenceNumber = @MaterialRefNo + @PONumber
													FROM DBO.WorkOrderMaterialStockLine WOMS
													WHERE WOMS.WorkOrderMaterialsId = @SelectedWorkOrderMaterialsId AND WOMS.StockLineId = @StkStocklineId;

													SET @POReferenceQty = @POReferenceQty - @Qty;
												END
												ELSE
												BEGIN
													DECLARE @ItmMsrId BIGINT = 0;
													DECLARE @CondId BIGINT = 0;

													SELECT @ItmMsrId = WOM.ItemMasterId, @CondId = WOM.ConditionCodeId FROM DBO.WorkOrderMaterials WOM WITH (NOLOCK) WHERE WOM.WorkOrderMaterialsId = @SelectedWorkOrderMaterialsId;

													IF ((@ItmMsrId = @stkItemMasterId OR @stkItemMasterId = @AltPartId OR @stkItemMasterId = @EquPartId) AND @CondId = (CASE WHEN @IsExchangePO= 1 THEN @ConditionId ELSE @stkConditionId END))
													BEGIN
														INSERT INTO DBO.WorkOrderMaterialStockLine ([WorkOrderMaterialsId],[StockLineId],[ItemMasterId],[ConditionId],[Quantity],[QtyReserved],
														[QtyIssued],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[AltPartMasterPartId],[EquPartMasterPartId],
														[IsAltPart],[IsEquPart],[UnitCost],[ExtendedCost],[UnitPrice],[ExtendedPrice],[ProvisionId],[RepairOrderId],[QuantityTurnIn],[Figure],[Item],[RepairOrderPartRecordId],ReferenceNumber)
														SELECT @SelectedWorkOrderMaterialsId, @StkStocklineId, @stkItemMasterId,CASE WHEN @IsExchangePO= 1 THEN @ConditionId ELSE @stkConditionId END, @Qty, @WOMSQtyReserved, 
														ISNULL(@WOMSQtyIssued, 0), @stkMasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, NULL, NULL, 
														CASE WHEN @AltPartId = @stkItemMasterId THEN 1 ELSE 0 END, CASE WHEN @EquPartId = @stkItemMasterId THEN 1 ELSE 0 END, @stkPurchaseOrderUnitCost, (@stkPurchaseOrderUnitCost * @Qty), @stkPurchaseOrderUnitCost, (@stkPurchaseOrderUnitCost * @Qty),
														@ReplaceProvisionId, NULL, NULL, NULL, NULL, NULL,@MaterialRefNo + @PONumber

														SET @InsertedWorkOrderMaterialsId = SCOPE_IDENTITY();

														SET @POReferenceQty = @POReferenceQty - @Qty;
													END
													ELSE
													BEGIN
														GOTO NextStockline;
													END
												END

												SET @stkWorkOrderMaterialsId = @SelectedWorkOrderMaterialsId;

												UPDATE TOP (@Qty) StkDraft
												SET 
												StkDraft.WOQty = @Qty,
												StkDraft.WorkOrderId = @ReferenceId,
												StkDraft.ForStockQty = CASE WHEN StkDraft.Quantity < @Qty THEN 0 ELSE StkDraft.Quantity - @Qty END
												FROM DBO.StocklineDraft StkDraft
												WHERE StkDraft.StockLineId = @StkStocklineId AND StkDraft.SOQty IS NULL AND StkDraft.WOQty IS NULL;

												UPDATE StkDraft
												SET 
												StkDraft.ForStockQty = StkDraft.ForStockQty - @Qty
												FROM DBO.StocklineDraft StkDraft
												WHERE StkDraft.StockLineId = @StkStocklineId AND StkDraft.ForStockQty > 0;

												EXEC USP_UpdateWOMaterialsCost @SelectedWorkOrderMaterialsId;
												EXEC USP_UpdateWOTotalCostDetails @ReferenceId, @WorkFlowWorkOrderId, @UpdatedBy, @stkMasterCompanyId;
												EXEC USP_UpdateWOCostDetails @ReferenceId, @WorkFlowWorkOrderId, @UpdatedBy, @stkMasterCompanyId;
											END
											ELSE
											BEGIN
												--GOTO NextStockline;
												GOTO NextStockline_WOMK;
											END
										END
									END
								END
							END
							ELSE
							BEGIN
								SET @ReservedIntoMaterial = 0;
								GOTO NextStockline_WOMK;
							END
						END

						IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkOrderMaterials WOM WITH (NOLOCK) LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha ON Nha.ItemMasterId = WOM.ItemMasterId WHERE WOM.WorkOrderId = @ReferenceId AND (WOM.ItemMasterId = @ItemMasterId OR Nha.ItemMasterId = WOM.ItemMasterId) AND WOM.ConditionCodeId = @ConditionId AND WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId) OR @IsExchangePO = 1
						BEGIN
							UPDATE Stk
							SET Stk.QuantityAvailable = @stkQuantityAvailable,
							--Stk.QuantityOnHand = @stkQuantityOnHand,
							Stk.QuantityReserved = @stkQuantityReserved,
							--Stk.QuantityIssued = @stkQuantityIssued,
							Stk.QuantityOnOrder = @stkQuantityOnOrder
							FROM DBO.Stockline Stk 
							WHERE Stk.StockLineId = @StkStocklineId;

							SET @ReservedIntoMaterial = 1;

							IF (@LoopIDWFWO >= 1)
								SET @QuantityReservedForPoPart = @QuantityReservedForPoPart + @Qty;
							ELSE
								SET @QuantityReservedForPoPart = @Qty;

							EXEC USP_AddUpdateStocklineHistory @StkStocklineId, 28, @PurchaseOrderId, 15, @ReferenceId, 2, @Qty, @UpdatedBy;

							IF (@stkWorkOrderMaterialsId > 0)
							BEGIN
								UPDATE Stk
								SET Stk.WorkOrderMaterialsId = @stkWorkOrderMaterialsId,
								Stk.WorkOrderId = @ReferenceId
								FROM DBO.Stockline Stk 
								WHERE Stk.StockLineId = @StkStocklineId;
							END
						END
						ELSE
						BEGIN
							SET @ReservedIntoMaterial = 0;
						END

						NextStockline_WOMK:

						IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkOrderMaterialsKit WOMK WITH (NOLOCK) LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha ON Nha.ItemMasterId = WOMK.ItemMasterId WHERE WOMK.WorkOrderId = @ReferenceId AND (WOMK.ItemMasterId = @ItemMasterId OR Nha.ItemMasterId = WOMK.ItemMasterId) AND WOMK.ConditionCodeId = @ConditionId AND WOMK.WorkFlowWorkOrderId = @WorkFlowWorkOrderId) -- AND @ReservedIntoMaterial = 0)-- OR @IsExchangePO = 1
						BEGIN
							DECLARE @SelectedWorkOrderMaterialsKitId INT = 0;
							DECLARE @WorkFlowWorkOrderKitId BIGINT = 0;
							DECLARE @RemainingStkQty INT = 0;
							DECLARE @AltPartId_WOMKIT BIGINT = 0;
							DECLARE @EquPartId_WOMKIT BIGINT = 0;

							SELECT @stkMasterCompanyId = Stk.MasterCompanyId, @stkQty = Stk.Quantity, @stkQuantityAvailable = Stk.QuantityAvailable, @stkQuantityReserved = QuantityReserved,
							@stkQuantityOnOrder = QuantityOnOrder, @stkItemMasterId = Stk.ItemMasterId, @stkConditionId = Stk.ConditionId,
							@stkPurchaseOrderUnitCost = Stk.PurchaseOrderUnitCost
							FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.StockLineId = @StkStocklineId;

							SELECT @SelectedWorkOrderMaterialsKitId = WOMK.WorkOrderMaterialsKitId, @AltPartId = Nha_Alt.MappingItemMasterId,
							@EquPartId = Nha_Euq.MappingItemMasterId FROM DBO.WorkOrderMaterialsKit WOMK WITH (NOLOCK) 
							LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha_Alt ON Nha_Alt.ItemMasterId = WOMK.ItemMasterId AND Nha_Alt.MappingType = 1
							LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha_Euq ON Nha_Euq.ItemMasterId = WOMK.ItemMasterId AND Nha_Euq.MappingType = 2
							WHERE WOMK.WorkOrderId = @ReferenceId AND (WOMK.ItemMasterId = @ItemMasterId OR Nha_Alt.ItemMasterId = WOMK.ItemMasterId OR Nha_Euq.ItemMasterId = WOMK.ItemMasterId) AND WOMK.ConditionCodeId = @ConditionId AND WOMK.WorkFlowWorkOrderId = @WorkFlowWorkOrderId;

							SET @Quantity = 0;
							SET @QuantityReserved = 0;
							SET @QuantityIssued = 0;

							SELECT @Quantity = WOMK.Quantity, @QuantityReserved = ISNULL(WOMK.QuantityReserved, 0), @QuantityIssued = ISNULL(WOMK.QuantityIssued, 0), @WorkFlowWorkOrderKitId = WOMK.WorkFlowWorkOrderId 
							FROM DBO.WorkOrderMaterialsKit WOMK WITH (NOLOCK)
							LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha_Alt ON Nha_Alt.ItemMasterId = WOMK.ItemMasterId
							LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha_Equ ON Nha_Equ.ItemMasterId = WOMK.ItemMasterId
							WHERE WOMK.WorkOrderId = @ReferenceId AND (WOMK.ItemMasterId = @ItemMasterId OR Nha_Alt.ItemMasterId = WOMK.ItemMasterId OR Nha_Equ.ItemMasterId = WOMK.ItemMasterId) AND WOMK.ConditionCodeId = @ConditionId AND WOMK.WorkFlowWorkOrderId = @WorkFlowWorkOrderId;

							SET @OriginalQuantity = @Quantity;

							DECLARE @MainPOReferenceQty_Kit INT = 0;
							SELECT @MainPOReferenceQty_Kit = (ISNULL(POPR.Qty, 0) - ISNULL(POPR.ReservedQty, 0)) FROM DBO.PurchaseOrderPartReference POPR WITH (NOLOCK) WHERE PurchaseOrderPartReferenceId = @SelectedPurchaseOrderPartReferenceId;

							IF (@MainPOReferenceQty_Kit < @Quantity)
							BEGIN
								SET @Quantity = @MainPOReferenceQty_Kit;
							END
							IF (@MainPOReferenceQty_Kit < @OriginalQuantity)
							BEGIN
								SET @OriginalQuantity = @MainPOReferenceQty_Kit;
							END

							IF ((@OriginalQuantity - (@QuantityReserved + @QuantityIssued)) > 0)
							BEGIN
								IF (@SelectedWorkOrderMaterialsKitId > 0)
								BEGIN
									SET @Qty = 0;
									SET @stkQty = 0;
									SET @stkMasterCompanyId = 0;
									SET @stkQuantityAvailable = 0;
									SET @stkQuantityReserved = 0;
									SET @stkQuantityOnOrder = 0;
									SET @stkItemMasterId = 0;
									SET @stkConditionId = 0;
									SET @stkWorkOrderMaterialsKitId = 0;
									SET @stkPurchaseOrderUnitCost = 0;

									SELECT @stkMasterCompanyId = Stk.MasterCompanyId, @stkQty = Stk.Quantity, @stkQuantityAvailable = Stk.QuantityAvailable, @stkQuantityOnHand = Stk.QuantityOnHand, @stkQuantityReserved = QuantityReserved,
									@stkQuantityOnOrder = QuantityOnOrder, @stkItemMasterId = Stk.ItemMasterId, @stkConditionId = Stk.ConditionId,
									@stkPurchaseOrderUnitCost = Stk.PurchaseOrderUnitCost
									FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.StockLineId = @StkStocklineId;

									IF (@Quantity > 0 AND @stkQty > 0)
									BEGIN
										IF (@stkQuantityAvailable > = @Quantity)
											SET @Qty = @OriginalQuantity - (@QuantityReserved + @QuantityIssued);	-- - (@QuantityReserved + @QuantityIssued);
										ELSE
											SET @Qty = @stkQuantityAvailable;
									END

									IF (@Qty > 0)
									BEGIN
										UPDATE WOMK
										SET WOMK.QuantityReserved = ISNULL(WOMK.QuantityReserved, 0),
										WOMK.TotalReserved = ISNULL(WOMK.TotalReserved, 0),
										WOMK.QuantityIssued = ISNULL(WOMK.QuantityIssued, 0),
										WOMK.TotalIssued = ISNULL(WOMK.TotalIssued, 0)
										FROM DBO.WorkOrderMaterialsKit WOMK
										WHERE WOMK.WorkOrderMaterialsKitId = @SelectedWorkOrderMaterialsKitId;

										UPDATE WOMK
										SET WOMK.QuantityReserved = @QuantityReserved + @Qty,
										WOMK.TotalReserved = TotalReserved + @Qty,
										WOMK.ReservedById = @Requisitioner,
										WOMK.ReservedDate = GETUTCDATE(),
										WOMK.IssuedById = @Requisitioner,
										WOMK.IssuedDate = GETUTCDATE(),
										WOMK.PONum = @PONumber,
										WOMK.PartStatusId = 1, -- Reserve
										WOMK.ExtendedCost = WOMK.ExtendedCost + (WOMK.UnitCost * @Qty)
										FROM DBO.WorkOrderMaterialsKit WOMK
										WHERE WOMK.WorkOrderMaterialsKitId = @SelectedWorkOrderMaterialsKitId;
									END

									SET @qtyFulfilled = 0;
									SET @flag = 0;

									IF (@StkStocklineId > 0)
									BEGIN
										SET @flag = 0;

										IF (@qtyFulfilled = 0)
										BEGIN
											SET @WOMSQtyReserved = 0;
											SET @WOMSQuantity = 0;

											IF (@stkQuantityAvailable > 0)
											BEGIN
												IF (@stkQuantityAvailable >= @Qty)
												BEGIN
													SET @qtyFulfilled = 1;
													SET @stkQuantityAvailable = @stkQuantityAvailable - @Qty;
													SET @stkQuantityReserved = @stkQuantityReserved + @Qty;
													SET @WOMSQtyReserved = @Qty;
												END
												ELSE
												BEGIN
													SET @stkQuantityReserved = @stkQuantityReserved + @stkQuantityAvailable;
													SET @WOMSQtyReserved = @stkQuantityAvailable;
													SET @stkQuantityAvailable = 0;
												END

												SET @flag = 1;
											END

											IF (@flag = 1)
											BEGIN
												SET @InsertedWorkOrderMaterialsId = 0;

												IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkOrderMaterialStockLineKit WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsKitId = @SelectedWorkOrderMaterialsKitId AND WOMS.StockLineId = @StkStocklineId)
												BEGIN
													UPDATE WOMS
													SET WOMS.Quantity = ISNULL(WOMS.Quantity, 0) + @Qty,
													WOMS.QtyReserved = ISNULL(WOMS.QtyReserved, 0) + @Qty,
													WOMS.StockLineId = @StkStocklineId,
													WOMS.UpdatedDate = GETUTCDATE(),
													WOMS.UpdatedBy = @UpdatedBy,
													WOMS.WorkOrderMaterialsKitId = @SelectedWorkOrderMaterialsKitId,
													WOMS.ItemMasterId = @stkItemMasterId,
													WOMS.ConditionId = @stkConditionId,
													WOMS.IsAltPart = CASE WHEN @AltPartId_WOMKIT = @stkItemMasterId THEN 1 ELSE 0 END,
													WOMS.IsEquPart = CASE WHEN @EquPartId_WOMKIT = @stkItemMasterId THEN 1 ELSE 0 END,
													WOMS.UnitCost = @stkPurchaseOrderUnitCost,
													WOMS.ExtendedCost = (@stkPurchaseOrderUnitCost * (ISNULL(WOMS.Quantity, 0) + @Qty)),
													WOMS.UnitPrice = @stkPurchaseOrderUnitCost,
													WOMS.ExtendedPrice = (@stkPurchaseOrderUnitCost * (ISNULL(WOMS.Quantity, 0) + @Qty)),
													WOMS.ReferenceNumber = @MaterialRefNo + @PONumber
													FROM DBO.WorkOrderMaterialStockLineKit WOMS
													WHERE WOMS.WorkOrderMaterialsKitId = @SelectedWorkOrderMaterialsKitId AND WOMS.StockLineId = @StkStocklineId;

													SET @POReferenceQty = @POReferenceQty - @Qty;
												END
												ELSE
												BEGIN
													DECLARE @ItmMsrId_KIT BIGINT = 0;
													DECLARE @CondId_KIT BIGINT = 0;

													SELECT @ItmMsrId_KIT = WOM.ItemMasterId, @CondId_KIT = WOM.ConditionCodeId FROM DBO.WorkOrderMaterialsKit WOM WITH (NOLOCK) WHERE WOM.WorkOrderMaterialsKitId = @SelectedWorkOrderMaterialsKitId;

													IF ((@ItmMsrId_KIT = @stkItemMasterId OR @stkItemMasterId = @AltPartId OR @stkItemMasterId = @EquPartId) AND @CondId_KIT = (CASE WHEN @IsExchangePO= 1 THEN @ConditionId ELSE @stkConditionId END))
													BEGIN
														INSERT INTO DBO.WorkOrderMaterialStockLineKit ([WorkOrderMaterialsKitId],[StockLineId],[ItemMasterId],[ConditionId],[Quantity],[QtyReserved],
														[QtyIssued],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[AltPartMasterPartId],[EquPartMasterPartId],
														[IsAltPart],[IsEquPart],[UnitCost],[ExtendedCost],[UnitPrice],[ExtendedPrice],[ProvisionId],[RepairOrderId],[QuantityTurnIn],[Figure],[Item],[RepairOrderPartRecordId],ReferenceNumber)
														SELECT @SelectedWorkOrderMaterialsKitId, @StkStocklineId, @stkItemMasterId, @stkConditionId, @Qty, @WOMSQtyReserved, 
														0, @stkMasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, NULL, NULL, 
														CASE WHEN @AltPartId_WOMKIT = @stkItemMasterId THEN 1 ELSE 0 END, CASE WHEN @EquPartId_WOMKIT = @stkItemMasterId THEN 1 ELSE 0 END, @stkPurchaseOrderUnitCost, (@stkPurchaseOrderUnitCost * @Qty), @stkPurchaseOrderUnitCost, (@stkPurchaseOrderUnitCost * @Qty),
														@ReplaceProvisionId, NULL, NULL, NULL, NULL, NULL,@MaterialRefNo + @PONumber

														SET @InsertedWorkOrderMaterialsId = SCOPE_IDENTITY();

														SET @POReferenceQty = @POReferenceQty - @Qty;
													END
													ELSE
													BEGIN
														GOTO NextStockline;
													END
												END

												SET @stkWorkOrderMaterialsKitId = @SelectedWorkOrderMaterialsKitId;

												UPDATE TOP (@Qty) StkDraft
												SET 
												StkDraft.WOQty = @Qty,
												StkDraft.WorkOrderId = @ReferenceId,
												StkDraft.ForStockQty = CASE WHEN StkDraft.Quantity < @Qty THEN 0 ELSE StkDraft.Quantity - @Qty END
												FROM DBO.StocklineDraft StkDraft
												WHERE StkDraft.StockLineId = @StkStocklineId AND StkDraft.SOQty IS NULL AND StkDraft.WOQty IS NULL;

												UPDATE StkDraft
												SET 
												StkDraft.ForStockQty = StkDraft.ForStockQty - @Qty
												FROM DBO.StocklineDraft StkDraft
												WHERE StkDraft.StockLineId = @StkStocklineId AND StkDraft.ForStockQty > 0;

												EXEC USP_UpdateWOMaterialsCost @SelectedWorkOrderMaterialsKitId;
												EXEC USP_UpdateWOTotalCostDetails @ReferenceId, @WorkFlowWorkOrderKitId, @UpdatedBy, @stkMasterCompanyId;
												EXEC USP_UpdateWOCostDetails @ReferenceId, @WorkFlowWorkOrderKitId, @UpdatedBy, @stkMasterCompanyId;
											END
											ELSE
											BEGIN
												GOTO NextStockline;
											END
										END
									END
								END
							END
							ELSE
							BEGIN
								GOTO NextStockline;
							END
						END
						ELSE
						BEGIN
							GOTO NextWFWO;
						END

						IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkOrderMaterialsKit WOMK WITH (NOLOCK) LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha ON Nha.ItemMasterId = WOMK.ItemMasterId WHERE WOMK.WorkOrderId = @ReferenceId AND (WOMK.ItemMasterId = @ItemMasterId OR Nha.ItemMasterId = WOMK.ItemMasterId) AND WOMK.ConditionCodeId = @ConditionId AND WOMK.WorkFlowWorkOrderId = @WorkFlowWorkOrderId)-- OR @IsExchangePO = 1
						BEGIN
							UPDATE Stk
							SET Stk.QuantityAvailable = @stkQuantityAvailable,
							Stk.QuantityReserved = @stkQuantityReserved,
							Stk.QuantityOnOrder = @stkQuantityOnOrder
							FROM DBO.Stockline Stk 
							WHERE Stk.StockLineId = @StkStocklineId;

							IF (@ReservedIntoMaterial = 1)
							BEGIN
								SET @QuantityReservedForPoPart = @QuantityReservedForPoPart + @Qty;
							END
							ELSE
							BEGIN
								IF (@LoopIDWFWO >= 1)
									SET @QuantityReservedForPoPart = @QuantityReservedForPoPart + @Qty;
								ELSE
									SET @QuantityReservedForPoPart = @Qty;
							END

							EXEC USP_AddUpdateStocklineHistory @StkStocklineId, 28, @PurchaseOrderId, 15, @ReferenceId, 2, @Qty, @UpdatedBy;

							IF (@stkWorkOrderMaterialsKitId > 0)
							BEGIN
								UPDATE Stk
								SET Stk.WorkOrderMaterialsKitId = @stkWorkOrderMaterialsKitId,
								Stk.WorkOrderId = @ReferenceId
								FROM DBO.Stockline Stk 
								WHERE Stk.StockLineId = @StkStocklineId;
							END
						END

						NextWFWO: 

						SET @LoopIDWFWO = @LoopIDWFWO - 1;
					END
				END

				IF (@ModulId = 5) -- Sub Work Order
				BEGIN
					PRINT 'SUB WORK ORDER'
					SET @ItemMasterId = 0;
					SET @ConditionId = 0;
					SET @Requisitioner = 0;
					SET @PONumber = '';

					SELECT @ItemMasterId = POP.ItemMasterId, @ConditionId = POP.ConditionId FROM DBO.PurchaseOrderPart POP WITH (NOLOCK) WHERE PurchaseOrderPartRecordId = @PurchaseOrderPartId;
					SELECT @Requisitioner = PO.RequestedBy, @PONumber = PO.PurchaseOrderNumber FROM DBO.PurchaseOrder PO WITH (NOLOCK) WHERE PO.PurchaseOrderId = @PurchaseOrderId;

					DECLARE @ReservedIntoSubWOMaterial BIT = 0;

					IF OBJECT_ID(N'tempdb..#SubWorkOrderMaterialTemp') IS NOT NULL
					BEGIN
						DROP TABLE #SubWorkOrderMaterialTemp
					END 
			
					CREATE TABLE #SubWorkOrderMaterialTemp
					(
						ID BIGINT NOT NULL IDENTITY,
						[WorkOrderId] [bigint] NULL,
						[SubWorkOrderId] [bigint] NULL,
						[SubWOPartNoId] [bigint] NULL,
						[SubWorkOrderMaterialsId] [bigint] NULL,
						[IsKitType] [bit] NULL,
					)

					INSERT INTO #SubWorkOrderMaterialTemp ([WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsId], [IsKitType])
					SELECT DISTINCT [WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsId], 0 FROM DBO.SubWorkOrderMaterials WOM WITH (NOLOCK) 
					LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha ON Nha.ItemMasterId = WOM.ItemMasterId
					WHERE WOM.SubWorkOrderId = @ReferenceId AND (WOM.ItemMasterId = @ItemMasterId OR Nha.ItemMasterId = WOM.ItemMasterId) AND WOM.ConditionCodeId = @ConditionId;

					INSERT INTO #SubWorkOrderMaterialTemp ([WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsId], [IsKitType])
					SELECT DISTINCT [WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsKitId], 1 FROM DBO.SubWorkOrderMaterialsKit WOMK WITH (NOLOCK) 
					LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha ON Nha.ItemMasterId = WOMK.ItemMasterId
					WHERE WOMK.SubWorkOrderId = @ReferenceId AND (WOMK.ItemMasterId = @ItemMasterId OR Nha.ItemMasterId = WOMK.ItemMasterId) AND WOMK.ConditionCodeId = @ConditionId; 

					DECLARE @LoopIDSUBWO INT = 0;
					SELECT @LoopIDSUBWO = MAX(ID) FROM #SubWorkOrderMaterialTemp;

					WHILE (@LoopIDSUBWO > 0)
					BEGIN
						DECLARE @SubWOMaterialId BIGINT = 0;
						DECLARE @IsKit BIT = 0;
						
						SELECT @SubWOMaterialId = [SubWorkOrderMaterialsId] , @IsKit = [IsKitType] FROM #SubWorkOrderMaterialTemp WHERE ID = @LoopIDSUBWO;
						
						IF EXISTS (SELECT TOP 1 1 FROM DBO.SubWorkOrderMaterials SWOM WITH (NOLOCK) LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha ON Nha.ItemMasterId = SWOM.ItemMasterId WHERE SWOM.SubWorkOrderId = @ReferenceId AND (SWOM.ItemMasterId = @ItemMasterId OR Nha.ItemMasterId = SWOM.ItemMasterId) AND SWOM.ConditionCodeId = @ConditionId AND SWOM.SubWorkOrderMaterialsId = @SubWOMaterialId AND @IsKit = 0)
						BEGIN
							DECLARE @SelectedWorkOrderMaterialsIdSWO INT = 0;
							DECLARE @SelectedWorkOrderId_ForSWO INT = 0;
							DECLARE @AltPartId_SWO BIGINT = 0;
							DECLARE @EquPartId_SWO BIGINT = 0;

							SELECT @SelectedWorkOrderMaterialsIdSWO = SWOM.SubWorkOrderMaterialsId, @AltPartId_SWO = Nha_Alt.MappingItemMasterId,
							@EquPartId_SWO = Nha_Euq.MappingItemMasterId, @SelectedWorkOrderId_ForSWO = SWOM.WorkOrderId 
							FROM DBO.SubWorkOrderMaterials SWOM WITH (NOLOCK) 
							LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha_Alt ON Nha_Alt.ItemMasterId = SWOM.ItemMasterId AND Nha_Alt.MappingType = 1
							LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha_Euq ON Nha_Euq.ItemMasterId = SWOM.ItemMasterId AND Nha_Euq.MappingType = 2
							WHERE SWOM.SubWorkOrderId = @ReferenceId AND (SWOM.ItemMasterId = @ItemMasterId OR Nha_Alt.ItemMasterId = SWOM.ItemMasterId OR Nha_Euq.ItemMasterId = SWOM.ItemMasterId) AND SWOM.ConditionCodeId = @ConditionId AND SWOM.SubWorkOrderMaterialsId = @SubWOMaterialId;
					
							SET @Quantity = 0;
							SET @QuantityReserved = 0;
							SET @QuantityIssued = 0;

							SELECT @Quantity = SWOM.Quantity, @QuantityReserved = ISNULL(SWOM.QuantityReserved, 0), @QuantityIssued = ISNULL(SWOM.QuantityIssued, 0) 
							FROM DBO.SubWorkOrderMaterials SWOM WITH (NOLOCK)
							LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha_Alt ON Nha_Alt.ItemMasterId = SWOM.ItemMasterId AND Nha_Alt.MappingType = 1
							LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha_Euq ON Nha_Euq.ItemMasterId = SWOM.ItemMasterId AND Nha_Euq.MappingType = 2
							WHERE SWOM.SubWorkOrderId = @ReferenceId AND (SWOM.ItemMasterId = @ItemMasterId OR Nha_Alt.ItemMasterId = SWOM.ItemMasterId OR Nha_Euq.ItemMasterId = SWOM.ItemMasterId) AND SWOM.ConditionCodeId = @ConditionId AND SWOM.SubWorkOrderMaterialsId = @SubWOMaterialId;

							DECLARE @MainPOReferenceQty_SWO INT = 0;
							SELECT @MainPOReferenceQty_SWO = (ISNULL(POPR.Qty, 0) - ISNULL(POPR.ReservedQty, 0)) FROM DBO.PurchaseOrderPartReference POPR WITH (NOLOCK) WHERE PurchaseOrderPartReferenceId = @SelectedPurchaseOrderPartReferenceId;

							IF (@MainPOReferenceQty_SWO < @Quantity)
							BEGIN
								SET @Quantity = @MainPOReferenceQty_SWO;
							END

							IF (@Quantity > 0)
							BEGIN
								IF (@SelectedWorkOrderMaterialsIdSWO > 0)
								BEGIN
									SET @Qty = 0;
									SET @stkQty = 0;
									SET @stkMasterCompanyId = 0;
									SET @stkQuantityAvailable = 0;
									SET @stkQuantityReserved = 0;
									SET @stkQuantityOnOrder = 0;
									SET @stkItemMasterId = 0;
									SET @stkConditionId = 0;
									SET @stkWorkOrderMaterialsId = 0;
									SET @stkPurchaseOrderUnitCost = 0;

									SELECT @stkMasterCompanyId = Stk.MasterCompanyId, @stkQty = Stk.Quantity, @stkQuantityAvailable = Stk.QuantityAvailable, @stkQuantityReserved = QuantityReserved,
									@stkQuantityOnOrder = QuantityOnOrder, @stkItemMasterId = Stk.ItemMasterId, @stkConditionId = Stk.ConditionId,
									@stkPurchaseOrderUnitCost = Stk.PurchaseOrderUnitCost
									FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.StockLineId = @StkStocklineId;

									IF (@Quantity > 0 AND @stkQty > 0)
									BEGIN
										IF (@stkQuantityAvailable > = @Quantity)
												SET @Qty = @Quantity;
										ELSE
											SET @Qty = @stkQuantityAvailable;
									END

									IF (@Qty > 0)
									BEGIN
										UPDATE SWOM
										SET SWOM.QuantityReserved = ISNULL(SWOM.QuantityReserved, 0),
										SWOM.TotalReserved = ISNULL(SWOM.TotalReserved, 0),
										SWOM.QuantityIssued = ISNULL(SWOM.QuantityIssued, 0),
										SWOM.TotalIssued = ISNULL(SWOM.TotalIssued, 0)
										FROM DBO.SubWorkOrderMaterials SWOM
										WHERE SWOM.SubWorkOrderMaterialsId = @SelectedWorkOrderMaterialsIdSWO;

										UPDATE SWOM
										SET SWOM.QuantityReserved = @QuantityReserved + @Qty,
										SWOM.TotalReserved = TotalReserved + @Qty,
										SWOM.ReservedById = @Requisitioner,
										SWOM.ReservedDate = GETUTCDATE(),
										SWOM.IssuedById = @Requisitioner,
										SWOM.IssuedDate = GETUTCDATE(),
										SWOM.PONum = @PONumber,
										SWOM.PartStatusId = 1, -- Reserve
										SWOM.ExtendedCost = SWOM.ExtendedCost + (SWOM.UnitCost * @Qty)
										FROM DBO.SubWorkOrderMaterials SWOM
										WHERE SWOM.SubWorkOrderMaterialsId = @SelectedWorkOrderMaterialsIdSWO;
									END

									SET @qtyFulfilled = 0;
									SET @flag = 0;

									IF (@StkStocklineId > 0)
									BEGIN
										SET @flag = 0;

										IF (@qtyFulfilled = 0)
										BEGIN
											SET @WOMSQtyReserved = 0;
											SET @WOMSQuantity = 0;

											IF (@stkQuantityAvailable > 0)
											BEGIN
												IF (@stkQuantityAvailable >= @Qty)
												BEGIN
													SET @qtyFulfilled = 1;
													SET @stkQuantityAvailable = @stkQuantityAvailable - @Qty;
													SET @stkQuantityReserved = @stkQuantityReserved + @Qty;
													SET @WOMSQtyReserved = @Qty;
												END
												ELSE
												BEGIN
													SET @stkQuantityReserved = @stkQuantityReserved + @stkQuantityAvailable;
													SET @WOMSQtyReserved = @stkQuantityAvailable;
													SET @stkQuantityAvailable = 0;
												END

												SET @flag = 1;
											END

											IF (@flag = 1)
											BEGIN
												SET @InsertedWorkOrderMaterialsId = 0;

												IF EXISTS (SELECT TOP 1 1 FROM DBO.SubWorkOrderMaterialStockLine SWOMS WITH (NOLOCK) WHERE SWOMS.SubWorkOrderMaterialsId = @SelectedWorkOrderMaterialsIdSWO AND SWOMS.StockLineId = @StkStocklineId)
												BEGIN
													UPDATE SWOMS
													SET SWOMS.Quantity = ISNULL(SWOMS.Quantity, 0) + @Qty,
													SWOMS.QtyReserved = ISNULL(SWOMS.QtyReserved, 0) + @Qty,
													SWOMS.StockLineId = @StkStocklineId,
													SWOMS.UpdatedDate = GETUTCDATE(),
													SWOMS.UpdatedBy = @UpdatedBy,
													SWOMS.SubWorkOrderMaterialsId = @SelectedWorkOrderMaterialsIdSWO,
													SWOMS.ItemMasterId = @stkItemMasterId,
													SWOMS.ConditionId = @stkConditionId,
													SWOMS.IsAltPart = CASE WHEN @AltPartId_SWO = @stkItemMasterId THEN 1 ELSE 0 END,
													SWOMS.IsEquPart = CASE WHEN @EquPartId_SWO = @stkItemMasterId THEN 1 ELSE 0 END,
													SWOMS.UnitCost = @stkPurchaseOrderUnitCost,
													SWOMS.ExtendedCost = (@stkPurchaseOrderUnitCost * @Qty),
													SWOMS.UnitPrice = @stkPurchaseOrderUnitCost,
													SWOMS.ExtendedPrice = (@stkPurchaseOrderUnitCost * @Qty),
													SWOMS.ReferenceNumber = @MaterialRefNo + @PONumber
													FROM DBO.SubWorkOrderMaterialStockLine SWOMS
													WHERE SWOMS.SubWorkOrderMaterialsId = @SelectedWorkOrderMaterialsIdSWO AND SWOMS.StockLineId = @StkStocklineId;

													SET @POReferenceQty = @POReferenceQty - @Qty;
												END
												ELSE
												BEGIN
													INSERT INTO DBO.SubWorkOrderMaterialStockLine ([SubWorkOrderMaterialsId],[StockLineId],[ItemMasterId],[ConditionId],[Quantity],[QtyReserved],
													[QtyIssued],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[AltPartMasterPartId],[EquPartMasterPartId],
													[IsAltPart],[IsEquPart],[UnitCost],[ExtendedCost],[UnitPrice],[ExtendedPrice],[ProvisionId],[RepairOrderId],[QuantityTurnIn],[Figure],[Item],ReferenceNumber)
													SELECT @SelectedWorkOrderMaterialsIdSWO, @StkStocklineId, @stkItemMasterId, @stkConditionId, @Qty, @WOMSQtyReserved, 
													0, @stkMasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, NULL, NULL, 
													CASE WHEN @AltPartId_SWO = @stkItemMasterId THEN 1 ELSE 0 END, CASE WHEN @EquPartId_SWO = @stkItemMasterId THEN 1 ELSE 0 END, @stkPurchaseOrderUnitCost, (@stkPurchaseOrderUnitCost * @Qty), @stkPurchaseOrderUnitCost, (@stkPurchaseOrderUnitCost * @Qty),
													@ReplaceProvisionId, NULL, NULL, NULL, NULL,@MaterialRefNo + @PONumber

													SET @InsertedWorkOrderMaterialsId = SCOPE_IDENTITY();

													SET @POReferenceQty = @POReferenceQty - @Qty;
												END

												SET @stkWorkOrderMaterialsId = @SelectedWorkOrderMaterialsIdSWO;

												UPDATE TOP (@Qty) StkDraft
												SET 
												--StkDraft.SOQty = CASE WHEN StkDraft.SOQty IS NULL THEN 0 ELSE StkDraft.SOQty END,
												StkDraft.WOQty = @Qty,
												StkDraft.WorkOrderId = @SelectedWorkOrderId_ForSWO,	--@ReferenceId,
												StkDraft.ForStockQty = CASE WHEN StkDraft.Quantity < @Qty THEN 0 ELSE StkDraft.Quantity - @Qty END
												FROM DBO.StocklineDraft StkDraft
												WHERE StkDraft.StockLineId = @StkStocklineId AND StkDraft.SOQty IS NULL AND StkDraft.WOQty IS NULL;

												UPDATE StkDraft
												SET 
												StkDraft.ForStockQty = StkDraft.ForStockQty - @Qty
												FROM DBO.StocklineDraft StkDraft
												WHERE StkDraft.StockLineId = @StkStocklineId AND StkDraft.ForStockQty > 0;

												--UpdateSubWOTotalCostDetails
												EXEC dbo.USP_UpdateSubWOMaterialsCost @SelectedWorkOrderMaterialsIdSWO;
											END
											ELSE
											BEGIN
												--GOTO NextStockline;
												GOTO NextStockline_SUBWOMK
											END
										END
									END
								END
							END
							ELSE
							BEGIN
								--GOTO NextStockline;
								GOTO NextStockline_SUBWOMK
							END
						END
						ELSE
						BEGIN
							--GOTO NextStockline;
							SET @ReservedIntoSubWOMaterial = 0;
							GOTO NextStockline_SUBWOMK
						END

						IF EXISTS (SELECT TOP 1 1 FROM DBO.SubWorkOrderMaterials SWOM WITH (NOLOCK) LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha ON Nha.ItemMasterId = SWOM.ItemMasterId WHERE SWOM.SubWorkOrderId = @ReferenceId AND (SWOM.ItemMasterId = @ItemMasterId OR Nha.ItemMasterId = SWOM.ItemMasterId) AND SWOM.ConditionCodeId = @ConditionId AND SWOM.SubWorkOrderMaterialsId = @SubWOMaterialId AND @IsKit = 0)
						BEGIN
							UPDATE Stk
							SET Stk.Quantity = @stkQty,
							Stk.QuantityAvailable = @stkQuantityAvailable,
							Stk.QuantityReserved = @stkQuantityReserved,
							Stk.QuantityOnOrder = @stkQuantityOnOrder
							FROM DBO.Stockline Stk 
							WHERE Stk.StockLineId = @StkStocklineId;

							SET @ReservedIntoSubWOMaterial = 1;

							IF (@LoopIDSUBWO >= 1)
								SET @QuantityReservedForPoPart = @QuantityReservedForPoPart + @Qty;
							ELSE
								SET @QuantityReservedForPoPart = @Qty;

							EXEC USP_AddUpdateStocklineHistory @StkStocklineId, 28, @PurchaseOrderId, 16, @ReferenceId, 2, @Qty, @UpdatedBy;
						END
						BEGIN
							SET @ReservedIntoSubWOMaterial = 0;
						END

						NextStockline_SUBWOMK:

						IF EXISTS (SELECT TOP 1 1 FROM DBO.SubWorkOrderMaterialsKit SWOM WITH (NOLOCK) LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha ON Nha.ItemMasterId = SWOM.ItemMasterId WHERE SWOM.SubWorkOrderId = @ReferenceId AND (SWOM.ItemMasterId = @ItemMasterId OR Nha.ItemMasterId = SWOM.ItemMasterId) AND SWOM.ConditionCodeId = @ConditionId AND SWOM.SubWorkOrderMaterialsKitId = @SubWOMaterialId AND @IsKit = 1)
						BEGIN
							DECLARE @SelectedWorkOrderMaterialsKitIdSWO INT = 0;
							DECLARE @SelectedWorkOrderId_ForSWOKit INT = 0;
							DECLARE @AltPartId_SWOKIT BIGINT = 0;
							DECLARE @EquPartId_SWOKIT BIGINT = 0;

							SELECT @SelectedWorkOrderMaterialsKitIdSWO = SWOM.SubWorkOrderMaterialsKitId, @SelectedWorkOrderId_ForSWOKit = SWOM.WorkOrderId,
							@AltPartId_SWOKIT = Nha_Alt.MappingItemMasterId, @EquPartId_SWOKIT = Nha_Euq.MappingItemMasterId
							FROM DBO.SubWorkOrderMaterialsKit SWOM WITH (NOLOCK) 
							LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha_Alt ON Nha_Alt.ItemMasterId = SWOM.ItemMasterId AND Nha_Alt.MappingType = 1
							LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha_Euq ON Nha_Euq.ItemMasterId = SWOM.ItemMasterId AND Nha_Euq.MappingType = 2
							WHERE SWOM.SubWorkOrderId = @ReferenceId AND (SWOM.ItemMasterId = @ItemMasterId OR Nha_Alt.ItemMasterId = SWOM.ItemMasterId OR Nha_Euq.ItemMasterId = SWOM.ItemMasterId) AND SWOM.ConditionCodeId = @ConditionId AND SWOM.SubWorkOrderMaterialsKitId = @SubWOMaterialId;
					
							SET @Quantity = 0;
							SET @QuantityReserved = 0;
							SET @QuantityIssued = 0;

							SELECT @Quantity = SWOM.Quantity, @QuantityReserved = ISNULL(SWOM.QuantityReserved, 0), @QuantityIssued = ISNULL(SWOM.QuantityIssued, 0) 
							FROM DBO.SubWorkOrderMaterialsKit SWOM WITH (NOLOCK)
							LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha_Alt ON Nha_Alt.ItemMasterId = SWOM.ItemMasterId
							LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha_Equ ON Nha_Equ.ItemMasterId = SWOM.ItemMasterId
							WHERE SWOM.SubWorkOrderId = @ReferenceId AND (SWOM.ItemMasterId = @ItemMasterId OR Nha_Alt.ItemMasterId = SWOM.ItemMasterId OR Nha_Equ.ItemMasterId = SWOM.ItemMasterId) AND SWOM.ConditionCodeId = @ConditionId AND SWOM.SubWorkOrderMaterialsKitId = @SubWOMaterialId;

							DECLARE @MainPOReferenceQty_SWOKit INT = 0;
							SELECT @MainPOReferenceQty_SWOKit = (ISNULL(POPR.Qty, 0) - ISNULL(POPR.ReservedQty, 0)) FROM DBO.PurchaseOrderPartReference POPR WITH (NOLOCK) WHERE PurchaseOrderPartReferenceId = @SelectedPurchaseOrderPartReferenceId;

							IF (@MainPOReferenceQty_SWOKit < @Quantity)
							BEGIN
								SET @Quantity = @MainPOReferenceQty_SWOKit;
							END

							IF (@Quantity > 0)
							BEGIN
								IF (@SelectedWorkOrderMaterialsKitIdSWO > 0)
								BEGIN
									SET @Qty = 0;
									SET @stkQty = 0;
									SET @stkMasterCompanyId = 0;
									SET @stkQuantityAvailable = 0;
									SET @stkQuantityReserved = 0;
									SET @stkQuantityOnOrder = 0;
									SET @stkItemMasterId = 0;
									SET @stkConditionId = 0;
									SET @stkWorkOrderMaterialsKitId = 0;
									SET @stkPurchaseOrderUnitCost = 0;

									SELECT @stkMasterCompanyId = Stk.MasterCompanyId, @stkQty = Stk.Quantity, @stkQuantityAvailable = Stk.QuantityAvailable, @stkQuantityReserved = QuantityReserved,
									@stkQuantityOnOrder = QuantityOnOrder, @stkItemMasterId = Stk.ItemMasterId, @stkConditionId = Stk.ConditionId,
									@stkPurchaseOrderUnitCost = Stk.PurchaseOrderUnitCost
									FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.StockLineId = @StkStocklineId;

									IF (@Quantity > 0 AND @stkQty > 0)
									BEGIN
										--IF (@stkQuantityAvailable > = @Quantity AND (@QuantityReserved + @QuantityIssued) > @Quantity)
										--	SET @Qty = @Quantity - (@QuantityReserved + @QuantityIssued);
										IF (@stkQuantityAvailable > = @Quantity)
												SET @Qty = @Quantity;
										ELSE
											SET @Qty = @stkQuantityAvailable;
									END

									IF (@Qty > 0)
									BEGIN
										UPDATE SWOM
										SET SWOM.QuantityReserved = ISNULL(SWOM.QuantityReserved, 0),
										SWOM.TotalReserved = ISNULL(SWOM.TotalReserved, 0),
										SWOM.QuantityIssued = ISNULL(SWOM.QuantityIssued, 0),
										SWOM.TotalIssued = ISNULL(SWOM.TotalIssued, 0)
										FROM DBO.SubWorkOrderMaterialsKit SWOM
										WHERE SWOM.SubWorkOrderMaterialsKitId = @SelectedWorkOrderMaterialsKitIdSWO;

										UPDATE SWOM
										SET SWOM.QuantityReserved = @QuantityReserved + @Qty,
										SWOM.TotalReserved = TotalReserved + @Qty,
										SWOM.ReservedById = @Requisitioner,
										SWOM.ReservedDate = GETUTCDATE(),
										SWOM.IssuedById = @Requisitioner,
										SWOM.IssuedDate = GETUTCDATE(),
										SWOM.PONum = @PONumber,
										SWOM.PartStatusId = 1, -- Reserve
										SWOM.ExtendedCost = SWOM.ExtendedCost + (SWOM.UnitCost * @Qty)
										FROM DBO.SubWorkOrderMaterialsKit SWOM
										WHERE SWOM.SubWorkOrderMaterialsKitId = @SelectedWorkOrderMaterialsKitIdSWO;
									END

									SET @qtyFulfilled = 0;
									SET @flag = 0;

									IF (@StkStocklineId > 0)
									BEGIN
										SET @flag = 0;

										IF (@qtyFulfilled = 0)
										BEGIN
											SET @WOMSQtyReserved = 0;
											SET @WOMSQuantity = 0;

											IF (@stkQuantityAvailable > 0)
											BEGIN
												IF (@stkQuantityAvailable >= @Qty)
												BEGIN
													SET @qtyFulfilled = 1;
													SET @stkQuantityAvailable = @stkQuantityAvailable - @Qty;
													SET @stkQuantityReserved = @stkQuantityReserved + @Qty;
													SET @WOMSQtyReserved = @Qty;
												END
												ELSE
												BEGIN
													SET @stkQuantityReserved = @stkQuantityReserved + @stkQuantityAvailable;
													SET @WOMSQtyReserved = @stkQuantityAvailable;
													SET @stkQuantityAvailable = 0;
												END

												SET @flag = 1;
											END

											IF (@flag = 1)
											BEGIN
												SET @InsertedWorkOrderMaterialsId = 0;

												IF EXISTS (SELECT TOP 1 1 FROM DBO.SubWorkOrderMaterialStockLineKit SWOMS WITH (NOLOCK) WHERE SWOMS.SubWorkOrderMaterialsKitId = @SelectedWorkOrderMaterialsKitIdSWO AND SWOMS.StockLineId = @StkStocklineId)
												BEGIN
													UPDATE SWOMS
													SET SWOMS.Quantity = ISNULL(SWOMS.Quantity, 0) + @Qty,
													SWOMS.QtyReserved = ISNULL(SWOMS.QtyReserved, 0) + @Qty,
													SWOMS.StockLineId = @StkStocklineId,
													SWOMS.UpdatedDate = GETUTCDATE(),
													SWOMS.UpdatedBy = @UpdatedBy,
													SWOMS.SubWorkOrderMaterialsKitId = @SelectedWorkOrderMaterialsKitIdSWO,
													SWOMS.ItemMasterId = @stkItemMasterId,
													SWOMS.ConditionId = @stkConditionId,
													SWOMS.IsAltPart = CASE WHEN @AltPartId_SWOKIT = @stkItemMasterId THEN 1 ELSE 0 END,
													SWOMS.IsEquPart = CASE WHEN @EquPartId_SWOKIT = @stkItemMasterId THEN 1 ELSE 0 END,
													SWOMS.UnitCost = @stkPurchaseOrderUnitCost,
													SWOMS.ExtendedCost = (@stkPurchaseOrderUnitCost * @Qty),
													SWOMS.UnitPrice = @stkPurchaseOrderUnitCost,
													SWOMS.ExtendedPrice = (@stkPurchaseOrderUnitCost * @Qty),
													SWOMS.ReferenceNumber = @MaterialRefNo + @PONumber
													FROM DBO.SubWorkOrderMaterialStockLineKit SWOMS
													WHERE SWOMS.SubWorkOrderMaterialsKitId = @SelectedWorkOrderMaterialsKitIdSWO AND SWOMS.StockLineId = @StkStocklineId;

													SET @POReferenceQty = @POReferenceQty - @Qty;
												END
												ELSE
												BEGIN
													INSERT INTO DBO.SubWorkOrderMaterialStockLinekit ([SubWorkOrderMaterialsKitId],[StockLineId],[ItemMasterId],[ConditionId],[Quantity],[QtyReserved],
													[QtyIssued],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[AltPartMasterPartId],[EquPartMasterPartId],
													[IsAltPart],[IsEquPart],[UnitCost],[ExtendedCost],[UnitPrice],[ExtendedPrice],[ProvisionId],[RepairOrderId],[QuantityTurnIn],[Figure],[Item],ReferenceNumber)
													SELECT @SelectedWorkOrderMaterialsKitIdSWO, @StkStocklineId, @stkItemMasterId, @stkConditionId, @Qty, @WOMSQtyReserved, 
													0, @stkMasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, NULL, NULL, 
													CASE WHEN @AltPartId_SWOKIT = @stkItemMasterId THEN 1 ELSE 0 END, CASE WHEN @EquPartId_SWOKIT = @stkItemMasterId THEN 1 ELSE 0 END, @stkPurchaseOrderUnitCost, (@stkPurchaseOrderUnitCost * @Qty), @stkPurchaseOrderUnitCost, (@stkPurchaseOrderUnitCost * @Qty),
													@ReplaceProvisionId, NULL, NULL, NULL, NULL,@MaterialRefNo + @PONumber

													SET @InsertedWorkOrderMaterialsId = SCOPE_IDENTITY();

													SET @POReferenceQty = @POReferenceQty - @Qty;
												END

												SET @stkWorkOrderMaterialsKitId = @SelectedWorkOrderMaterialsKitIdSWO;

												UPDATE TOP (@Qty) StkDraft
												SET 
												--StkDraft.SOQty = CASE WHEN StkDraft.SOQty IS NULL THEN 0 ELSE StkDraft.SOQty END,
												StkDraft.WOQty = @Qty,
												StkDraft.WorkOrderId = @SelectedWorkOrderId_ForSWOKit,	--@ReferenceId,
												StkDraft.ForStockQty = CASE WHEN StkDraft.Quantity < @Qty THEN 0 ELSE StkDraft.Quantity - @Qty END
												FROM DBO.StocklineDraft StkDraft
												WHERE StkDraft.StockLineId = @StkStocklineId AND StkDraft.SOQty IS NULL AND StkDraft.WOQty IS NULL;

												UPDATE StkDraft
												SET 
												StkDraft.ForStockQty = StkDraft.ForStockQty - @Qty
												FROM DBO.StocklineDraft StkDraft
												WHERE StkDraft.StockLineId = @StkStocklineId AND StkDraft.ForStockQty > 0;

												--UpdateSubWOTotalCostDetails
												EXEC dbo.USP_UpdateSubWOMaterialsCost @SelectedWorkOrderMaterialsKitIdSWO;
											END
											ELSE
											BEGIN
												GOTO NextStockline;
												--GOTO NextStockline_SUBWOMK
											END
										END
									END
								END
							END
							ELSE
							BEGIN
								GOTO NextStockline;
								--GOTO NextStockline_SUBWOMK
							END
						END
						ELSE
						BEGIN
							GOTO NextSUBWOM;
							--GOTO NextStockline_SUBWOMK
						END

						IF EXISTS (SELECT TOP 1 1 FROM DBO.SubWorkOrderMaterialsKit SWOM WITH (NOLOCK) LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha ON Nha.ItemMasterId = SWOM.ItemMasterId WHERE SWOM.SubWorkOrderId = @ReferenceId AND (SWOM.ItemMasterId = @ItemMasterId  OR Nha.ItemMasterId = SWOM.ItemMasterId) AND SWOM.ConditionCodeId = @ConditionId  AND SWOM.SubWorkOrderMaterialsKitId = @SubWOMaterialId AND @IsKit = 1)
						BEGIN
							UPDATE Stk
							SET Stk.Quantity = @stkQty,
							Stk.QuantityAvailable = @stkQuantityAvailable,
							Stk.QuantityReserved = @stkQuantityReserved,
							Stk.QuantityOnOrder = @stkQuantityOnOrder
							FROM DBO.Stockline Stk 
							WHERE Stk.StockLineId = @StkStocklineId;

							--IF (@AllowAutoIssue = 0)
							--BEGIN
							IF (@ReservedIntoSubWOMaterial = 1)
							BEGIN
								SET @QuantityReservedForPoPart = @QuantityReservedForPoPart + @Qty;
							END
							ELSE
							BEGIN
								IF (@LoopIDSUBWO >= 1)
									SET @QuantityReservedForPoPart = @QuantityReservedForPoPart + @Qty;
								ELSE
									SET @QuantityReservedForPoPart = @Qty;
							END

							EXEC USP_AddUpdateStocklineHistory @StkStocklineId, 28, @PurchaseOrderId, 16, @ReferenceId, 2, @Qty, @UpdatedBy;

							IF (@stkWorkOrderMaterialsKitId > 0)
							BEGIN
								UPDATE Stk
								SET Stk.WorkOrderMaterialsKitId = @stkWorkOrderMaterialsKitId,
								Stk.WorkOrderId = @SelectedWorkOrderId_ForSWOKit --@ReferenceId
								FROM DBO.Stockline Stk 
								WHERE Stk.StockLineId = @StkStocklineId;
							END
						END

						NextSUBWOM:

						SET @LoopIDSUBWO = @LoopIDSUBWO - 1

					END					
				END
				
				IF(@ModulId = 6) /** LOT MODULE **/
				BEGIN
					PRINT 'LOT'
					SET @ItemMasterId = 0;
					SET @ConditionId = 0;
					SET @Requisitioner = 0;
					SET @PONumber = '';

					SELECT @ItemMasterId = POP.ItemMasterId, @ConditionId = POP.ConditionId FROM DBO.PurchaseOrderPart POP WITH (NOLOCK) WHERE PurchaseOrderPartRecordId = @PurchaseOrderPartId;
					SELECT @Requisitioner = PO.RequestedBy, @PONumber = PO.PurchaseOrderNumber FROM DBO.PurchaseOrder PO WITH (NOLOCK) WHERE PO.PurchaseOrderId = @PurchaseOrderId;

					SET @Qty = 0;
						SET @stkQty = 0;
						SET @stkMasterCompanyId = 0;
						SET @stkQuantityAvailable = 0;
						SET @stkQuantityReserved = 0;
						SET @stkQuantityOnOrder = 0;
						SET @stkItemMasterId = 0;
						SET @stkConditionId = 0;
						SET @stkConditionId = 0;
						SET @stkPurchaseOrderUnitCost = 0;

						/******* DO NOT DELETE BELOW CODE *********/

						--SELECT @stkMasterCompanyId = Stk.MasterCompanyId, @stkQty = Stk.Quantity, @stkQuantityAvailable = Stk.QuantityAvailable, @stkQuantityReserved = QuantityReserved,
						--@stkQuantityOnOrder = QuantityOnOrder, @stkItemMasterId = Stk.ItemMasterId, @stkConditionId = Stk.ConditionId,
						--@stkPurchaseOrderUnitCost = Stk.UnitCost
						--FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.StockLineId = @StkStocklineId;

						--	UPDATE Stk
						--			SET Stk.Quantity = @stkQty,
						--			Stk.QuantityAvailable = CASE WHEN @stkQuantityAvailable - @POReferenceQty >= 0 THEN @stkQuantityAvailable - @POReferenceQty ELSE 0 END,
						--			Stk.QuantityReserved = @stkQuantityReserved + @POReferenceQty,
						--			Stk.QuantityOnOrder = @stkQuantityOnOrder
						--			FROM DBO.Stockline Stk 
						--			WHERE Stk.StockLineId = @StkStocklineId;

						--  EXEC USP_AddUpdateStocklineHistory @StkStocklineId, 28, @PurchaseOrderId, 10, @ReferenceId, 2, @Qty, @UpdatedBy;

				END /*** LOT MODULE END ***/
				
				IF (@ModulId = 3) -- Sales Order
				BEGIN
					SET @ItemMasterId = 0;
					SET @ConditionId = 0;
					SET @Requisitioner = 0;
					SET @PONumber = '';

					SELECT @ItemMasterId = POP.ItemMasterId, @ConditionId = POP.ConditionId FROM DBO.PurchaseOrderPart POP WITH (NOLOCK) WHERE PurchaseOrderPartRecordId = @PurchaseOrderPartId;
					SELECT @Requisitioner = PO.RequestedBy, @PONumber = PO.PurchaseOrderNumber FROM DBO.PurchaseOrder PO WITH (NOLOCK) WHERE PO.PurchaseOrderId = @PurchaseOrderId;

					IF EXISTS (SELECT TOP 1 1 FROM DBO.SalesOrderPart SOP WITH (NOLOCK) LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha ON Nha.ItemMasterId = SOP.ItemMasterId WHERE SOP.SalesOrderId = @ReferenceId AND (SOP.ItemMasterId = @ItemMasterId OR Nha.ItemMasterId = SOP.ItemMasterId) AND SOP.ConditionId = @ConditionId)
					BEGIN
						SET @Qty = 0;
						SET @stkQty = 0;
						SET @stkMasterCompanyId = 0;
						SET @stkQuantityAvailable = 0;
						SET @stkQuantityReserved = 0;
						SET @stkQuantityOnOrder = 0;
						SET @stkItemMasterId = 0;
						SET @stkConditionId = 0;
						SET @stkConditionId = 0;
						SET @stkPurchaseOrderUnitCost = 0;
						DECLARE @StkUnitSalePrice AS DECIMAL(18, 2) = 0;

						SELECT @stkMasterCompanyId = Stk.MasterCompanyId, @stkQty = Stk.Quantity, @stkQuantityAvailable = Stk.QuantityAvailable, @stkQuantityReserved = QuantityReserved,
						@stkQuantityOnOrder = QuantityOnOrder, @stkItemMasterId = Stk.ItemMasterId, @stkConditionId = Stk.ConditionId,
						@stkPurchaseOrderUnitCost = Stk.UnitCost, @StkUnitSalePrice = Stk.UnitSalesPrice
						FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.StockLineId = @StkStocklineId;

						IF OBJECT_ID(N'tempdb..#tmpSalesOrderPart') IS NOT NULL
						BEGIN
							DROP TABLE #tmpSalesOrderPart
						END
			
						CREATE TABLE #tmpSalesOrderPart 
						(
							ID BIGINT NOT NULL IDENTITY,
							[SalesOrderPartId] [bigint] NULL
						)

						INSERT INTO #tmpSalesOrderPart ([SalesOrderPartId])
						SELECT [SalesOrderPartId] FROM DBO.SalesOrderPart SOP WITH (NOLOCK) 
						LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha ON Nha.ItemMasterId = SOP.ItemMasterId
						WHERE SOP.SalesOrderId = @ReferenceId AND (SOP.ItemMasterId = @ItemMasterId OR Nha.ItemMasterId = SOP.ItemMasterId) AND SOP.ConditionId = @ConditionId;

						DECLARE @SOPLoopID BIGINT;

						SELECT @SOPLoopID = MAX(ID) FROM #tmpSalesOrderPart;

						WHILE (@SOPLoopID > 0)
						BEGIN
							DECLARE @SelectedSalesOrderPartId BIGINT = 0;
							DECLARE @QtyRequested INT = 0;
							DECLARE @SOPQty INT = 0;

							SELECT @SelectedSalesOrderPartId = [SalesOrderPartId] FROM #tmpSalesOrderPart WHERE ID = @SOPLoopID;
							
							SELECT @QtyRequested = SOP.QtyRequested FROM DBO.SalesOrderPart SOP WITH (NOLOCK) WHERE SOP.SalesOrderPartId = @SelectedSalesOrderPartId;

							IF (@POReferenceQty < @QtyRequested)
							BEGIN
								SET @QtyRequested = @POReferenceQty;
							END

							IF EXISTS (SELECT TOP 1 1 FROM DBO.SalesOrderPart SOP WITH (NOLOCK) LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha ON Nha.ItemMasterId = SOP.ItemMasterId WHERE SOP.SalesOrderId = @ReferenceId AND (SOP.ItemMasterId = @ItemMasterId OR Nha.ItemMasterId = SOP.ItemMasterId) AND SOP.ConditionId = @ConditionId AND SOP.StockLineId IS NULL)
							BEGIN
								DECLARE @SalesOrderPartIdToUpdate BIGINT = 0;
								SELECT @SalesOrderPartIdToUpdate = SOP.[SalesOrderPartId] FROM DBO.SalesOrderPart SOP WITH (NOLOCK) LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha ON Nha.ItemMasterId = SOP.ItemMasterId WHERE SOP.SalesOrderId = @ReferenceId AND (SOP.ItemMasterId = @ItemMasterId OR Nha.ItemMasterId = SOP.ItemMasterId) AND SOP.ConditionId = @ConditionId AND SOP.StockLineId IS NULL;

								SET @Qty = 0;
								SET @SOPQty = 0;

								IF (@stkQuantityAvailable > 0)
								BEGIN
									IF (@stkQuantityAvailable >= @QtyRequested)
										SET @Qty = @QtyRequested;
									ELSE IF (@QtyRequested >= @stkQuantityAvailable)
										SET @Qty = @stkQuantityAvailable;
								END

								IF (@Qty > 0)
								BEGIN
									UPDATE SOP
									SET SOP.StockLineId = @StkStocklineId,
									SOP.Qty = @Qty,
									SOP.UnitCost = @stkPurchaseOrderUnitCost,
									SOP.UnitCostExtended = (@stkPurchaseOrderUnitCost * @Qty),
									SOP.MarginAmount = @StkUnitSalePrice - @stkPurchaseOrderUnitCost,
									SOP.MarginAmountExtended = (@StkUnitSalePrice - @stkPurchaseOrderUnitCost) * @Qty,
									SOP.MarginPercentage = CASE WHEN SOP.UnitSalePrice > 0 THEN (((@StkUnitSalePrice - @stkPurchaseOrderUnitCost) / SOP.UnitSalePrice) * 100) ELSE 0 END,
									SOP.UnitSalesPricePerUnit = SOP.GrossSalePricePerUnit - SOP.DiscountAmount,
									SOP.NetSales = ISNULL(SOP.UnitSalesPricePerUnit, 0) * SOP.Qty
									,SOP.StatusId = @soPartFulfilledStatusId
									FROM DBO.SalesOrderPart SOP
									WHERE SOP.SalesOrderPartId = @SalesOrderPartIdToUpdate;

									SET @POReferenceQty = @POReferenceQty - @Qty;

									INSERT INTO DBO.SalesOrderReserveParts ([SalesOrderId],[StockLineId],[ItemMasterId],[PartStatusId],[IsEquPart],[EquPartMasterPartId],[IsAltPart],[AltPartMasterPartId],
									[QtyToReserve],[QtyToIssued],[ReservedById],[ReservedDate],[IssuedById],[IssuedDate],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],
									[SalesOrderPartId],[TotalReserved],[TotalIssued],[MasterCompanyId])
									SELECT @ReferenceId, @StkStocklineId, @ItemMasterId, 1, 0, 0, 0, 0,
									@Qty, 0, @Requisitioner, GETUTCDATE(), @Requisitioner, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), 1, 0,
									@SalesOrderPartIdToUpdate, @Qty, NULL, @stkMasterCompanyId;

									INSERT INTO DBO.SalesOrderStockLine ([SalesOrderId],[SalesOrderPartId],[StockLIneId],[ItemMasterId],[ConditionId],[Quantity],[QtyReserved],[QtyIssued],
									[AltPartMasterPartId],[EquPartMasterPartId],[IsAltPart],[IsEquPart],[UnitCost],[ExtendedCost],[UnitPrice],[ExtendedPrice],[MasterCompanyId],[CreatedBy],
									[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
									SELECT @ReferenceId, @SalesOrderPartIdToUpdate, @StkStocklineId, @ItemMasterId, @ConditionId, @Qty, @Qty, 0,
									NULL, NULL, NULL, NULL, 0, 0, 0, 0, @stkMasterCompanyId, @UpdatedBy,
									@UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0;

									SET @stkQuantityReserved = @stkQuantityReserved + @Qty;
									SET @stkQuantityAvailable = @stkQuantityAvailable - @Qty;

									SET @stkSalesOrderPartId = @SalesOrderPartIdToUpdate;

									UPDATE TOP (@Qty) StkDraft
									SET StkDraft.SOQty = @Qty,
									StkDraft.SalesOrderId = @ReferenceId,
									--StkDraft.WOQty = CASE WHEN StkDraft.WOQty IS NULL THEN 0 ELSE StkDraft.WOQty END,
									StkDraft.ForStockQty = CASE WHEN StkDraft.Quantity < @Qty THEN 0 ELSE StkDraft.Quantity - @Qty END
									FROM DBO.StocklineDraft StkDraft
									WHERE StkDraft.StockLineId = @StkStocklineId AND StkDraft.SOQty IS NULL AND StkDraft.WOQty IS NULL;

									UPDATE StkDraft
									SET 
									StkDraft.ForStockQty = StkDraft.ForStockQty - @Qty
									FROM DBO.StocklineDraft StkDraft
									WHERE StkDraft.StockLineId = @StkStocklineId AND StkDraft.ForStockQty > 0;

									UPDATE Stk
									SET Stk.Quantity = @stkQty,
									Stk.QuantityAvailable = @stkQuantityAvailable,
									Stk.QuantityReserved = @stkQuantityReserved,
									Stk.QuantityOnOrder = @stkQuantityOnOrder
									FROM DBO.Stockline Stk 
									WHERE Stk.StockLineId = @StkStocklineId;

									SET @QuantityReservedForPoPart = @Qty; 

									EXEC USP_AddUpdateStocklineHistory @StkStocklineId, 28, @PurchaseOrderId, 10, @ReferenceId, 2, @Qty, @UpdatedBy;

									IF (@stkSalesOrderPartId > 0)
									BEGIN
										UPDATE Stk
										SET Stk.SalesOrderPartId = @stkSalesOrderPartId
										FROM DBO.Stockline Stk 
										WHERE Stk.StockLineId = @StkStocklineId;
									END
								END
								ELSE
								BEGIN
									GOTO NextStockline;
								END
							END
							ELSE
							BEGIN
								IF NOT EXISTS (SELECT TOP 1 1 FROM DBO.SalesOrderPart SOP WITH (NOLOCK) LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha ON Nha.ItemMasterId = SOP.ItemMasterId WHERE SOP.SalesOrderId = @ReferenceId AND (SOP.ItemMasterId = @ItemMasterId OR Nha.ItemMasterId = SOP.ItemMasterId) AND SOP.ConditionId = @ConditionId AND SOP.StockLineId = @StkStocklineId)
								BEGIN
									IF EXISTS (SELECT TOP 1 1 FROM DBO.SalesOrderPart SOP WITH (NOLOCK) LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha ON Nha.ItemMasterId = SOP.ItemMasterId WHERE SOP.SalesOrderId = @ReferenceId AND (SOP.ItemMasterId = @ItemMasterId OR Nha.ItemMasterId = SOP.ItemMasterId) AND SOP.ConditionId = @ConditionId)
									BEGIN
										SET @Qty = 0;
										SET @SOPQty = 0;

										DECLARE @qtySumAlreadyAdded AS INT = 0;
										DECLARE @SOPQtyRequested AS INT = 0;
										
										SELECT @SOPQtyRequested = SOP.QtyRequested FROM DBO.SalesOrderPart SOP WITH (NOLOCK) 
										LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha ON Nha.ItemMasterId = SOP.ItemMasterId
										WHERE SOP.SalesOrderId = @ReferenceId AND (SOP.ItemMasterId = @ItemMasterId OR Nha.ItemMasterId = SOP.ItemMasterId) AND SOP.ConditionId = @ConditionId

										SELECT @qtySumAlreadyAdded = SUM(SOP.Qty) FROM DBO.SalesOrderPart SOP WITH (NOLOCK) 
										LEFT JOIN DBO.Nha_Tla_Alt_Equ_ItemMapping Nha ON Nha.ItemMasterId = SOP.ItemMasterId
										Where SOP.SalesOrderId = @ReferenceId AND (SOP.ItemMasterId = @ItemMasterId OR Nha.ItemMasterId = SOP.ItemMasterId) AND SOP.ConditionId = @ConditionId;

										SET @QtyRequested = @SOPQtyRequested - @qtySumAlreadyAdded;

										IF (@stkQuantityAvailable > 0)
										BEGIN
											IF (@stkQuantityAvailable >= @QtyRequested)
												SET @Qty = @QtyRequested;
											ELSE IF (@QtyRequested >= @stkQuantityAvailable)
												SET @Qty = @stkQuantityAvailable;
										END

										IF (@Qty > 0)
										BEGIN
											DECLARE @InsertedSalesOrderPartId BIGINT = 0;

											INSERT INTO DBO.SalesOrderPart ([SalesOrderId],[ItemMasterId],[StockLineId],[FxRate],[Qty],[UnitSalePrice],[MarkUpPercentage],[SalesBeforeDiscount],
											[Discount],[DiscountAmount],[NetSales],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsDeleted],[UnitCost],[MethodType],[SalesPriceExtended],
											[MarkupExtended],[SalesDiscountExtended],[NetSalePriceExtended],[UnitCostExtended],[MarginAmount],[MarginAmountExtended],[MarginPercentage],[ConditionId],[SalesOrderQuoteId],
											[SalesOrderQuotePartId],[IsActive],[CustomerRequestDate],[PromisedDate],[EstimatedShipDate],[PriorityId],[StatusId],[CustomerReference],[QtyRequested],[Notes],[CurrencyId],
											[MarkupPerUnit],[GrossSalePricePerUnit],[GrossSalePrice],[TaxType],[TaxPercentage],[TaxAmount],[AltOrEqType],[ControlNumber],[IdNumber],[ItemNo],[POId],[PONumber],
											[PONextDlvrDate],[UnitSalesPricePerUnit],[LotId],[IsLotAssigned])
											SELECT TOP 1 [SalesOrderId],[ItemMasterId],@StkStocklineId,[FxRate],@Qty,[UnitSalePrice],[MarkUpPercentage],[SalesBeforeDiscount],
											[Discount],[DiscountAmount],(ISNULL((SOP.UnitSalePrice + SOP.MarkupPerUnit - SOP.DiscountAmount), 0) * @Qty),[MasterCompanyId],@UpdatedBy,GETUTCDATE(),[UpdatedBy],GETUTCDATE(),[IsDeleted],@stkPurchaseOrderUnitCost,[MethodType],[SalesPriceExtended],
											[MarkupExtended],[SalesDiscountExtended],[NetSalePriceExtended],(@stkPurchaseOrderUnitCost * @Qty),(SOP.UnitSalePrice - @stkPurchaseOrderUnitCost),((SOP.UnitSalePrice - @stkPurchaseOrderUnitCost) * @Qty),CASE WHEN SOP.UnitSalePrice > 0 THEN (((SOP.UnitSalePrice - @stkPurchaseOrderUnitCost) / SOP.UnitSalePrice) * 100) ELSE 0 END,[ConditionId],[SalesOrderQuoteId],
											[SalesOrderQuotePartId],[IsActive],[CustomerRequestDate],[PromisedDate],[EstimatedShipDate],[PriorityId],@soPartFulfilledStatusId,[CustomerReference],[QtyRequested],[Notes],[CurrencyId],
											[MarkupPerUnit],[GrossSalePricePerUnit],[GrossSalePrice],[TaxType],[TaxPercentage],[TaxAmount],[AltOrEqType],[ControlNumber],[IdNumber],[ItemNo],[POId],[PONumber],
											[PONextDlvrDate], (SOP.UnitSalePrice + SOP.MarkupPerUnit - SOP.DiscountAmount),[LotId],[IsLotAssigned]
											FROM DBO.SalesOrderPart SOP WITH (NOLOCK) WHERE SOP.SalesOrderId = @ReferenceId AND SOP.ItemMasterId = @ItemMasterId AND SOP.ConditionId = @ConditionId;

											SELECT @InsertedSalesOrderPartId = SCOPE_IDENTITY();

											SET @POReferenceQty = @POReferenceQty - @Qty;

											SET @stkSalesOrderPartId = @InsertedSalesOrderPartId;

											INSERT INTO DBO.SalesOrderReserveParts ([SalesOrderId],[StockLineId],[ItemMasterId],[PartStatusId],[IsEquPart],[EquPartMasterPartId],[IsAltPart],[AltPartMasterPartId],
											[QtyToReserve],[QtyToIssued],[ReservedById],[ReservedDate],[IssuedById],[IssuedDate],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],
											[SalesOrderPartId],[TotalReserved],[TotalIssued],[MasterCompanyId])
											SELECT @ReferenceId, @StkStocklineId, @ItemMasterId, 1, 0, 0, 0, 0,
											@Qty, 0, @Requisitioner, GETUTCDATE(), @Requisitioner, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), 1, 0,
											@InsertedSalesOrderPartId, @Qty, NULL, @stkMasterCompanyId;

											INSERT INTO DBO.SalesOrderStockLine ([SalesOrderId],[SalesOrderPartId],[StockLIneId],[ItemMasterId],[ConditionId],[Quantity],[QtyReserved],[QtyIssued],
											[AltPartMasterPartId],[EquPartMasterPartId],[IsAltPart],[IsEquPart],[UnitCost],[ExtendedCost],[UnitPrice],[ExtendedPrice],[MasterCompanyId],[CreatedBy],
											[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
											SELECT @ReferenceId, @InsertedSalesOrderPartId, @StkStocklineId, @ItemMasterId, @ConditionId, @Qty, @Qty, 0,
											NULL, NULL, NULL, NULL, 0, 0, 0, 0, @stkMasterCompanyId, @UpdatedBy,
											@UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0;

											SET @stkQuantityReserved = @stkQuantityReserved + @Qty;
											SET @stkQuantityAvailable = @stkQuantityAvailable - @Qty;

											UPDATE TOP (@Qty) StkDraft
											SET StkDraft.SOQty = @Qty,
											StkDraft.SalesOrderId = @ReferenceId,
											--StkDraft.WOQty = CASE WHEN StkDraft.WOQty IS NULL THEN 0 ELSE StkDraft.WOQty END,
											StkDraft.ForStockQty = CASE WHEN StkDraft.Quantity < @Qty THEN 0 ELSE StkDraft.Quantity - @Qty END
											FROM DBO.StocklineDraft StkDraft
											WHERE StkDraft.StockLineId = @StkStocklineId AND StkDraft.SOQty IS NULL AND StkDraft.WOQty IS NULL;

											UPDATE Stk
											SET Stk.Quantity = @stkQty,
											Stk.QuantityAvailable = @stkQuantityAvailable,
											Stk.QuantityReserved = @stkQuantityReserved,
											Stk.QuantityOnOrder = @stkQuantityOnOrder
											FROM DBO.Stockline Stk 
											WHERE Stk.StockLineId = @StkStocklineId;

											SET @QuantityReservedForPoPart = @Qty; 

											EXEC USP_AddUpdateStocklineHistory @StkStocklineId, 28, @PurchaseOrderId, 10, @ReferenceId, 2, @Qty, @UpdatedBy;

											IF (@stkSalesOrderPartId > 0)
											BEGIN
												UPDATE Stk
												SET Stk.SalesOrderPartId = @stkSalesOrderPartId
												FROM DBO.Stockline Stk 
												WHERE Stk.StockLineId = @StkStocklineId;
											END
										END
									END
									ELSE
									BEGIN
										GOTO NextStockline;
									END
								END
								ELSE
								BEGIN
									GOTO NextStockline;
								END
							END

							SET @SOPLoopID = @SOPLoopID - 1;
						END
					END
				END

				IF (@ModulId = 4) -- Exchange Sales Order
				BEGIN
					SET @ItemMasterId = 0;
					SET @ConditionId = 0;
					SET @Requisitioner = 0;
					SET @PONumber = '';

					SELECT @ItemMasterId = POP.ItemMasterId, @ConditionId = POP.ConditionId FROM DBO.PurchaseOrderPart POP WITH (NOLOCK) WHERE PurchaseOrderPartRecordId = @PurchaseOrderPartId;
					SELECT @Requisitioner = PO.RequestedBy, @PONumber = PO.PurchaseOrderNumber FROM DBO.PurchaseOrder PO WITH (NOLOCK) WHERE PO.PurchaseOrderId = @PurchaseOrderId;

					IF EXISTS (SELECT TOP 1 1 FROM DBO.ExchangeSalesOrderPart ESOP WITH (NOLOCK) WHERE ESOP.ExchangeSalesOrderId = @ReferenceId AND ESOP.ItemMasterId = @ItemMasterId AND ESOP.ConditionId = @ConditionId)
					BEGIN
						SET @Qty = 0;
						SET @stkQty = 0;
						SET @stkMasterCompanyId = 0;
						SET @stkQuantityAvailable = 0;
						SET @stkQuantityReserved = 0;
						SET @stkQuantityOnOrder = 0;
						SET @stkItemMasterId = 0;
						SET @stkConditionId = 0;
						SET @stkConditionId = 0;
						SET @stkPurchaseOrderUnitCost = 0;
						SET @StkUnitSalePrice = 0;

						SELECT @stkMasterCompanyId = Stk.MasterCompanyId, @stkQty = Stk.Quantity, @stkQuantityAvailable = Stk.QuantityAvailable, @stkQuantityReserved = QuantityReserved,
						@stkQuantityOnOrder = QuantityOnOrder, @stkItemMasterId = Stk.ItemMasterId, @stkConditionId = Stk.ConditionId,
						@stkPurchaseOrderUnitCost = Stk.UnitCost, @StkUnitSalePrice = Stk.UnitSalesPrice
						FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.StockLineId = @StkStocklineId;

						IF OBJECT_ID(N'tempdb..#tmpExchangeSalesOrderPart') IS NOT NULL
						BEGIN
							DROP TABLE #tmpExchangeSalesOrderPart
						END
			
						CREATE TABLE #tmpExchangeSalesOrderPart 
						(
							ID BIGINT NOT NULL IDENTITY,
							[ExchangeSalesOrderPartId] [bigint] NULL
						)

						INSERT INTO #tmpExchangeSalesOrderPart ([ExchangeSalesOrderPartId])
						SELECT [ExchangeSalesOrderPartId] FROM DBO.ExchangeSalesOrderPart ESOP WITH (NOLOCK) WHERE ESOP.ExchangeSalesOrderId = @ReferenceId AND ESOP.ItemMasterId = @ItemMasterId AND ESOP.ConditionId = @ConditionId;

						DECLARE @ESOPLoopID BIGINT;

						SELECT @ESOPLoopID = MAX(ID) FROM #tmpExchangeSalesOrderPart;

						WHILE (@ESOPLoopID > 0)
						BEGIN
							DECLARE @SelectedExchangeSalesOrderPartId BIGINT = 0;
							SET @QtyRequested = 0;
							DECLARE @ESOPQty INT = 0;

							SELECT @SelectedExchangeSalesOrderPartId = [ExchangeSalesOrderPartId] FROM #tmpExchangeSalesOrderPart WHERE ID = @ESOPLoopID;
							
							SELECT @QtyRequested = ESOP.QtyRequested FROM DBO.ExchangeSalesOrderPart ESOP WITH (NOLOCK) WHERE ESOP.ExchangeSalesOrderPartId = @SelectedExchangeSalesOrderPartId;

							IF (@POReferenceQty < @QtyRequested)
							BEGIN
								SET @QtyRequested = @POReferenceQty;
							END

							IF EXISTS (SELECT TOP 1 1 FROM DBO.ExchangeSalesOrderPart ESOP WITH (NOLOCK) WHERE ESOP.ExchangeSalesOrderId = @ReferenceId AND ESOP.ItemMasterId = @ItemMasterId AND ESOP.ConditionId = @ConditionId AND ESOP.StockLineId IS NULL)
							BEGIN
								DECLARE @ExchangeSalesOrderPartIdToUpdate BIGINT = 0;
								SELECT @ExchangeSalesOrderPartIdToUpdate = ESOP.[ExchangeSalesOrderPartId] FROM DBO.ExchangeSalesOrderPart ESOP WITH (NOLOCK) WHERE ESOP.ExchangeSalesOrderId = @ReferenceId AND ESOP.ItemMasterId = @ItemMasterId AND ESOP.ConditionId = @ConditionId AND ESOP.StockLineId IS NULL;

								SET @Qty = 0;
								SET @ESOPQty = 0;

								IF (@stkQuantityAvailable > 0)
								BEGIN
									IF (@stkQuantityAvailable >= @QtyRequested)
										SET @Qty = @QtyRequested;
									ELSE IF (@QtyRequested >= @stkQuantityAvailable)
										SET @Qty = @stkQuantityAvailable;
								END

								IF (@Qty > 0)
								BEGIN
									UPDATE ESOP
									SET ESOP.StockLineId = @StkStocklineId,
									ESOP.Qty = @Qty,
									ESOP.UnitCost = @stkPurchaseOrderUnitCost
									FROM DBO.ExchangeSalesOrderPart ESOP
									WHERE ESOP.ExchangeSalesOrderPartId = @ExchangeSalesOrderPartIdToUpdate;

									SET @POReferenceQty = @POReferenceQty - @Qty;

									INSERT INTO DBO.ExchangeSalesOrderReserveParts ([ExchangeSalesOrderId],[StockLineId],[ItemMasterId],[PartStatusId],[IsEquPart],[EquPartMasterPartId],[IsAltPart],[AltPartMasterPartId],
									[QtyToReserve],[QtyToIssued],[ReservedById],[ReservedDate],[IssuedById],[IssuedDate],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],
									[ExchangeSalesOrderPartId],[TotalReserved],[TotalIssued],[MasterCompanyId])
									SELECT @ReferenceId, @StkStocklineId, @ItemMasterId, 1, 0, 0, 0, 0,
									@Qty, 0, @Requisitioner, GETUTCDATE(), @Requisitioner, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), 1, 0,
									@ExchangeSalesOrderPartIdToUpdate, @Qty, NULL, @stkMasterCompanyId;

									INSERT INTO DBO.ExchangeSalesOrderStockLine ([ExchangeSalesOrderId],[ExchangeSalesOrderPartId],[StockLIneId],[ItemMasterId],[ConditionId],[Quantity],[QtyReserved],[QtyIssued],
									[AltPartMasterPartId],[EquPartMasterPartId],[IsAltPart],[IsEquPart],[UnitCost],[ExtendedCost],[UnitPrice],[ExtendedPrice],[MasterCompanyId],[CreatedBy],
									[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
									SELECT @ReferenceId, @ExchangeSalesOrderPartIdToUpdate, @StkStocklineId, @ItemMasterId, @ConditionId, @Qty, @Qty, 0,
									NULL, NULL, NULL, NULL, 0, 0, 0, 0, @stkMasterCompanyId, @UpdatedBy,
									@UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0;

									SET @stkQuantityReserved = @stkQuantityReserved + @Qty;
									SET @stkQuantityAvailable = @stkQuantityAvailable - @Qty;

									SET @stkSalesOrderPartId = @ExchangeSalesOrderPartIdToUpdate;

									UPDATE TOP (@Qty) StkDraft
									SET StkDraft.ForStockQty = CASE WHEN StkDraft.Quantity < @Qty THEN 0 ELSE StkDraft.Quantity - @Qty END
									FROM DBO.StocklineDraft StkDraft
									WHERE StkDraft.StockLineId = @StkStocklineId;

									UPDATE StkDraft
									SET 
									StkDraft.ForStockQty = StkDraft.ForStockQty - @Qty
									FROM DBO.StocklineDraft StkDraft
									WHERE StkDraft.StockLineId = @StkStocklineId AND StkDraft.ForStockQty > 0;

									UPDATE Stk
									SET Stk.Quantity = @stkQty,
									Stk.QuantityAvailable = @stkQuantityAvailable,
									Stk.QuantityReserved = @stkQuantityReserved,
									Stk.QuantityOnOrder = @stkQuantityOnOrder
									FROM DBO.Stockline Stk 
									WHERE Stk.StockLineId = @StkStocklineId;

									SET @QuantityReservedForPoPart = @Qty; 

									EXEC USP_AddUpdateStocklineHistory @StkStocklineId, 28, @PurchaseOrderId, 18, @ReferenceId, 2, @Qty, @UpdatedBy;
								END
								ELSE
								BEGIN
									GOTO NextStockline;
								END
							END
							ELSE
							BEGIN
								IF NOT EXISTS (SELECT TOP 1 1 FROM DBO.ExchangeSalesOrderPart ESOP WITH (NOLOCK) WHERE ESOP.ExchangeSalesOrderId = @ReferenceId AND ESOP.ItemMasterId = @ItemMasterId AND ESOP.ConditionId = @ConditionId AND ESOP.StockLineId = @StkStocklineId)
								BEGIN
									IF EXISTS (SELECT TOP 1 1 FROM DBO.ExchangeSalesOrderPart ESOP WITH (NOLOCK) WHERE ESOP.ExchangeSalesOrderId = @ReferenceId AND ESOP.ItemMasterId = @ItemMasterId AND ESOP.ConditionId = @ConditionId)
									BEGIN
										SET @Qty = 0;
										SET @ESOPQty = 0;

										DECLARE @qtySumAlreadyAdded_EXCH AS INT = 0;
										DECLARE @SOPQtyRequested_EXCH AS INT = 0;
										
										SELECT @SOPQtyRequested_EXCH = ESOP.QtyRequested FROM DBO.ExchangeSalesOrderPart ESOP WITH (NOLOCK) WHERE ESOP.ExchangeSalesOrderId = @ReferenceId AND ESOP.ItemMasterId = @ItemMasterId AND ESOP.ConditionId = @ConditionId

										SELECT @qtySumAlreadyAdded_EXCH = SUM(ESOP.Qty) FROM DBO.ExchangeSalesOrderPart ESOP WITH (NOLOCK) Where ESOP.ExchangeSalesOrderId = @ReferenceId AND ESOP.ItemMasterId = @ItemMasterId AND ESOP.ConditionId = @ConditionId;

										SET @QtyRequested = @SOPQtyRequested_EXCH - @qtySumAlreadyAdded_EXCH;

										IF (@stkQuantityAvailable > 0)
										BEGIN
											IF (@stkQuantityAvailable >= @QtyRequested)
												SET @Qty = @QtyRequested;
											ELSE IF (@QtyRequested >= @stkQuantityAvailable)
												SET @Qty = @stkQuantityAvailable;
										END

										IF (@Qty > 0)
										BEGIN
											DECLARE @InsertedExchangeSalesOrderPartId BIGINT = 0;

											INSERT INTO DBO.ExchangeSalesOrderPart ([ExchangeSalesOrderId],[ExchangeQuotePartId],[ExchangeQuoteId],[ItemMasterId],[StockLineId],[ExchangeCurrencyId],[LoanCurrencyId],[ExchangeListPrice],
											[EntryDate],[ExchangeOverhaulPrice],[ExchangeCorePrice],[EstOfFeeBilling],[BillingStartDate],[ExchangeOutrightPrice],[DaysForCoreReturn],[BillingIntervalDays],[CurrencyId],[Currency],[DepositeAmount],
											[CoreDueDate],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsDeleted],[IsActive],[ConditionId],[StockLineName],[PartNumber],[PartDescription],[ConditionName],[IsRemark],[RemarkText],
											[ExchangeOverhaulCost],[QtyQuoted],[MethodType],[IsConvertedToSalesOrder],[CustomerRequestDate],[PromisedDate],[EstimatedShipDate],[ExpectedCoreSN],[StatusId],[StatusName],[FxRate],[UnitCost],[PriorityId],
											[Qty],[QtyRequested],[ControlNumber],[IdNumber],[Notes],[ExpecedCoreCond],[ExpectedCoreRetDate],[CoreRetDate],[CoreRetNum],[CoreStatusId],[LetterSentDate],[LetterTypeId],[Memo],[ExpdCoreSN],[POId],[PONumber],
											[PONextDlvrDate],[IsExpCoreSN],[CoreAccepted],[ReceivedDate])
											SELECT TOP 1 [ExchangeSalesOrderId],[ExchangeQuotePartId],[ExchangeQuoteId],[ItemMasterId],@StkStocklineId,[ExchangeCurrencyId],[LoanCurrencyId],[ExchangeListPrice],
											[EntryDate],[ExchangeOverhaulPrice],[ExchangeCorePrice],[EstOfFeeBilling],[BillingStartDate],[ExchangeOutrightPrice],[DaysForCoreReturn],[BillingIntervalDays],[CurrencyId],[Currency],[DepositeAmount],
											[CoreDueDate],[MasterCompanyId],@UpdatedBy,GETUTCDATE(),[UpdatedBy],[UpdatedDate],[IsDeleted],[IsActive],[ConditionId],[StockLineName],[PartNumber],[PartDescription],[ConditionName],[IsRemark],[RemarkText],
											[ExchangeOverhaulCost],[QtyQuoted],[MethodType],[IsConvertedToSalesOrder],[CustomerRequestDate],[PromisedDate],[EstimatedShipDate],[ExpectedCoreSN],[StatusId],[StatusName],[FxRate],@stkPurchaseOrderUnitCost,[PriorityId],
											@Qty,[QtyRequested],[ControlNumber],[IdNumber],[Notes],[ExpecedCoreCond],[ExpectedCoreRetDate],[CoreRetDate],[CoreRetNum],[CoreStatusId],[LetterSentDate],[LetterTypeId],[Memo],[ExpdCoreSN],[POId],[PONumber],
											[PONextDlvrDate],[IsExpCoreSN],[CoreAccepted],[ReceivedDate]
											FROM DBO.ExchangeSalesOrderPart ESOP WITH (NOLOCK) WHERE ESOP.ExchangeSalesOrderId = @ReferenceId AND ESOP.ItemMasterId = @ItemMasterId AND ESOP.ConditionId = @ConditionId;

											SELECT @InsertedExchangeSalesOrderPartId = SCOPE_IDENTITY();

											SET @POReferenceQty = @POReferenceQty - @Qty;

											SET @stkSalesOrderPartId = @InsertedExchangeSalesOrderPartId;

											INSERT INTO DBO.ExchangeSalesOrderReserveParts ([ExchangeSalesOrderId],[StockLineId],[ItemMasterId],[PartStatusId],[IsEquPart],[EquPartMasterPartId],[IsAltPart],[AltPartMasterPartId],
											[QtyToReserve],[QtyToIssued],[ReservedById],[ReservedDate],[IssuedById],[IssuedDate],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],
											[ExchangeSalesOrderPartId],[TotalReserved],[TotalIssued],[MasterCompanyId])
											SELECT @ReferenceId, @StkStocklineId, @ItemMasterId, 1, 0, 0, 0, 0,
											@Qty, 0, @Requisitioner, GETUTCDATE(), @Requisitioner, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), 1, 0,
											@InsertedExchangeSalesOrderPartId, @Qty, NULL, @stkMasterCompanyId;

											INSERT INTO DBO.ExchangeSalesOrderStockLine ([ExchangeSalesOrderId],[ExchangeSalesOrderPartId],[StockLIneId],[ItemMasterId],[ConditionId],[Quantity],[QtyReserved],[QtyIssued],
											[AltPartMasterPartId],[EquPartMasterPartId],[IsAltPart],[IsEquPart],[UnitCost],[ExtendedCost],[UnitPrice],[ExtendedPrice],[MasterCompanyId],[CreatedBy],
											[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
											SELECT @ReferenceId, @InsertedExchangeSalesOrderPartId, @StkStocklineId, @ItemMasterId, @ConditionId, @Qty, @Qty, 0,
											NULL, NULL, NULL, NULL, 0, 0, 0, 0, @stkMasterCompanyId, @UpdatedBy,
											@UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0;

											SET @stkQuantityReserved = @stkQuantityReserved + @Qty;
											SET @stkQuantityAvailable = @stkQuantityAvailable - @Qty;

											UPDATE TOP (@Qty) StkDraft
											SET StkDraft.ForStockQty = CASE WHEN StkDraft.Quantity < @Qty THEN 0 ELSE StkDraft.Quantity - @Qty END
											FROM DBO.StocklineDraft StkDraft
											WHERE StkDraft.StockLineId = @StkStocklineId;

											UPDATE Stk
											SET Stk.Quantity = @stkQty,
											Stk.QuantityAvailable = @stkQuantityAvailable,
											Stk.QuantityReserved = @stkQuantityReserved,
											Stk.QuantityOnOrder = @stkQuantityOnOrder
											FROM DBO.Stockline Stk 
											WHERE Stk.StockLineId = @StkStocklineId;

											SET @QuantityReservedForPoPart = @Qty; 

											EXEC USP_AddUpdateStocklineHistory @StkStocklineId, 28, @PurchaseOrderId, 18, @ReferenceId, 2, @Qty, @UpdatedBy;
										END
									END
									ELSE
									BEGIN
										GOTO NextStockline;
									END
								END
								ELSE
								BEGIN
									GOTO NextStockline;
								END
							END

							SET @ESOPLoopID = @ESOPLoopID - 1;
						END
					END
				END

				NextStockline:

				EXEC UpdateStocklineColumnsWithId @StkStocklineId;

				SET @StkLoopID = @StkLoopID - 1;

				UPDATE DBO.PurchaseOrderPartReference 
				SET ReservedQty = ISNULL(ReservedQty, 0) + ISNULL(@QuantityReservedForPoPart, 0)
				WHERE PurchaseOrderPartReferenceId = @SelectedPurchaseOrderPartReferenceId;

				SET @QuantityReservedForPoPart = 0;
			END

			SET @LoopID = @LoopID - 1;
		END
	END
    
	COMMIT TRANSACTION

  END TRY
  BEGIN CATCH
    IF @@trancount > 0
	  ROLLBACK TRAN;
	  DECLARE @ErrorLogID INT
	  ,@DatabaseName VARCHAR(100) = DB_NAME()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------  
	  ,@AdhocComments VARCHAR(150) = 'USP_ReserveStocklineForReceivingPO'  
	  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ' + ISNULL(@PurchaseOrderId, '') + ''  
	  ,@ApplicationName VARCHAR(100) = 'PAS'  
	  -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
	  EXEC spLogException @DatabaseName = @DatabaseName,  
		@AdhocComments = @AdhocComments,  
		@ProcedureParameters = @ProcedureParameters,  
		@ApplicationName = @ApplicationName,  
		@ErrorLogID = @ErrorLogID OUTPUT;  
	  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
	  RETURN (1);  
	 END CATCH  
END
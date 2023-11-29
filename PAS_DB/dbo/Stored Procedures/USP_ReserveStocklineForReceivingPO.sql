/*************************************************************             
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

exec dbo.USP_ReserveStocklineForReceivingPO @PurchaseOrderId=1929,@SelectedPartsToReserve=N'695,696',@UpdatedBy=N'ADMIN User'
**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_ReserveStocklineForReceivingPO]
(  
	@PurchaseOrderId BIGINT = NULL,
	@SelectedPartsToReserve VARCHAR(256) = NULL,
	@UpdatedBy VARCHAR(100) = NULL
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
		DECLARE @ReplaceProvisionId AS BIGINT = 0;

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
		--WHERE POPR.PurchaseOrderId = @PurchaseOrderId;
		--WHERE POPR.[PurchaseOrderPartId] = @StkPurchaseOrderPartRecordId;

		SELECT * FROM #tmpPurchaseOrderPartReference;

		SELECT @LoopID = MAX(ID) FROM #tmpPurchaseOrderPartReference;
		PRINT 'WHILE' 
		WHILE (@LoopID > 0)
		BEGIN
			DECLARE @SelectedPurchaseOrderPartReferenceId BIGINT = 0;
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

			DECLARE @QuantityReservedIntoModule INT = 0;
			DECLARE @QuantityReservedForPoPart INT = 0;

			SELECT @SelectedPurchaseOrderPartReferenceId = PurchaseOrderPartReferenceId FROM #tmpPurchaseOrderPartReference WHERE ID = @LoopID;

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
			SELECT StocklineId, Stk.PurchaseOrderPartRecordId FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.PurchaseOrderId = @PurchaseOrderId AND Stk.IsParent = 1 AND Stk.QuantityAvailable > 0 ORDER BY StocklineId DESC; 
		
			SELECT @StkLoopID = MAX(ID) FROM #tmpStockline;
			PRINT '1'
			WHILE (@StkLoopID > 0 AND @POReferenceQty > 0)
			BEGIN
				PRINT '@POReferenceQty'
				PRINT @POReferenceQty;

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
					PRINT 'WO'
					SET @ItemMasterId = 0;
					SET @ConditionId = 0;
					SET @Requisitioner = 0;
					SET @PONumber = '';
					DECLARE @WorkOrderMaterialsIdExchPO BIGINT = 0;
					DECLARE @IsExchangePO BIT = 0;

					SELECT @ItemMasterId = POP.ItemMasterId, @ConditionId = POP.ConditionId, @WorkOrderMaterialsIdExchPO = ISNULL(POP.WorkOrderMaterialsId, 0) FROM DBO.PurchaseOrderPart POP WITH (NOLOCK) WHERE PurchaseOrderPartRecordId = @PurchaseOrderPartId;
					SELECT @Requisitioner = PO.RequestedBy, @PONumber = PO.PurchaseOrderNumber FROM DBO.PurchaseOrder PO WITH (NOLOCK) WHERE PO.PurchaseOrderId = @PurchaseOrderId;
					
					IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkOrderMaterials WOM WITH (NOLOCK) WHERE WOM.WorkOrderId = @ReferenceId AND WOM.ItemMasterId = @ItemMasterId AND WOM.WorkOrderMaterialsId = @WorkOrderMaterialsIdExchPO)
					BEGIN
						SET @IsExchangePO = 1;
					END

					IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkOrderMaterials WOM WITH (NOLOCK) WHERE WOM.WorkOrderId = @ReferenceId AND WOM.ItemMasterId = @ItemMasterId AND WOM.ConditionCodeId = @ConditionId) OR @IsExchangePO = 1
					BEGIN
						DECLARE @SelectedWorkOrderMaterialsId INT = 0;
						DECLARE @WorkFlowWorkOrderId BIGINT = 0;
						
						IF (@IsExchangePO = 0)
						BEGIN
							SELECT @SelectedWorkOrderMaterialsId = WOM.WorkOrderMaterialsId FROM DBO.WorkOrderMaterials WOM WITH (NOLOCK) 
							WHERE WOM.WorkOrderId = @ReferenceId AND WOM.ItemMasterId = @ItemMasterId AND WOM.ConditionCodeId = @ConditionId;
						END
						ELSE
						BEGIN
							SELECT @SelectedWorkOrderMaterialsId = WOM.WorkOrderMaterialsId FROM DBO.WorkOrderMaterials WOM WITH (NOLOCK) 
							WHERE WOM.WorkOrderId = @ReferenceId AND WOM.ItemMasterId = @ItemMasterId AND WOM.WorkOrderMaterialsId = @WorkOrderMaterialsIdExchPO;
						END
					
						SET @Quantity = 0;
						SET @QuantityReserved = 0;
						SET @QuantityIssued = 0;

						SELECT @Quantity = WOM.Quantity, @QuantityReserved = ISNULL(WOM.QuantityReserved, 0), @QuantityIssued = ISNULL(WOM.QuantityIssued, 0), @WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId FROM DBO.WorkOrderMaterials WOM WITH (NOLOCK)
						WHERE WOM.WorkOrderId = @ReferenceId AND WOM.ItemMasterId = @ItemMasterId AND WOM.ConditionCodeId = @ConditionId;

						IF (@Quantity > (@QuantityReserved + @QuantityIssued))
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

								IF (@Quantity > 0 AND @stkQty > 0)
								BEGIN
									IF (@stkQuantityAvailable > = @Quantity)
										SET @Qty = @Quantity - (@QuantityReserved + @QuantityIssued);
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
									FROM DBO.WorkOrderMaterials WOM
									WHERE WOM.WorkOrderMaterialsId = @SelectedWorkOrderMaterialsId;

									IF (@IsExchangePO = 0)
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
									ELSE
									BEGIN
										UPDATE WOM
										SET WOM.QuantityIssued = @QuantityIssued + @Qty,
										WOM.TotalIssued = TotalIssued + @Qty,
										WOM.IssuedById = @Requisitioner,
										WOM.IssuedDate = GETUTCDATE(),
										WOM.PONum = @PONumber,
										WOM.PartStatusId = 1, -- Reserve
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
												IF (@IsExchangePO = 0)
												BEGIN
													SET @qtyFulfilled = 1;
													SET @stkQuantityAvailable = @stkQuantityAvailable - @Qty;
													SET @stkQuantityReserved = @stkQuantityReserved + @Qty;
													SET @WOMSQtyReserved = @Qty;
												END
												ELSE
												BEGIN
													SET @qtyFulfilled = 1;
													SET @stkQuantityOnHand = @stkQuantityOnHand - @Qty;
													SET @stkQuantityIssued = @stkQuantityIssued + @Qty;
													SET @WOMSQtyIssued = @Qty;
												END
											END
											ELSE
											BEGIN
												IF (@IsExchangePO = 0)
												BEGIN
													SET @stkQuantityReserved = @stkQuantityReserved + @stkQuantityAvailable;
													SET @WOMSQtyReserved = @stkQuantityAvailable;
													SET @stkQuantityAvailable = 0;
												END
												ELSE
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
												SET WOMS.Quantity = @Qty,
												WOMS.StockLineId = @StkStocklineId,
												WOMS.UpdatedDate = GETUTCDATE(),
												WOMS.UpdatedBy = @UpdatedBy,
												WOMS.WorkOrderMaterialsId = @SelectedWorkOrderMaterialsId,
												WOMS.ItemMasterId = @stkItemMasterId,
												WOMS.ConditionId = @stkConditionId,
												WOMS.IsAltPart = 0,
												WOMS.IsEquPart = 0,
												WOMS.UnitCost = @stkPurchaseOrderUnitCost,
												WOMS.ExtendedCost = (@stkPurchaseOrderUnitCost * @Qty),
												WOMS.UnitPrice = @stkPurchaseOrderUnitCost,
												WOMS.ExtendedPrice = (@stkPurchaseOrderUnitCost * @Qty)
												FROM DBO.WorkOrderMaterialStockLine WOMS
												WHERE WOMS.WorkOrderMaterialsId = @SelectedWorkOrderMaterialsId AND WOMS.StockLineId = @StkStocklineId;

												SET @POReferenceQty = @POReferenceQty - @Qty;
												SET @QuantityReservedIntoModule = @QuantityReservedIntoModule + @Qty;
											END
											ELSE
											BEGIN
												INSERT INTO DBO.WorkOrderMaterialStockLine ([WorkOrderMaterialsId],[StockLineId],[ItemMasterId],[ConditionId],[Quantity],[QtyReserved],
												[QtyIssued],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[AltPartMasterPartId],[EquPartMasterPartId],
												[IsAltPart],[IsEquPart],[UnitCost],[ExtendedCost],[UnitPrice],[ExtendedPrice],[ProvisionId],[RepairOrderId],[QuantityTurnIn],[Figure],[Item],[RepairOrderPartRecordId])
												SELECT @SelectedWorkOrderMaterialsId, @StkStocklineId, @stkItemMasterId, @stkConditionId, @Qty, @WOMSQtyReserved, 
												ISNULL(@WOMSQtyIssued, 0), @stkMasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, NULL, NULL, 
												0, 0, @stkPurchaseOrderUnitCost, (@stkPurchaseOrderUnitCost * @Qty), @stkPurchaseOrderUnitCost, (@stkPurchaseOrderUnitCost * @Qty),
												@ReplaceProvisionId, NULL, NULL, NULL, NULL, NULL

												SET @InsertedWorkOrderMaterialsId = SCOPE_IDENTITY();

												SET @POReferenceQty = @POReferenceQty - @Qty;
												SET @QuantityReservedIntoModule = @QuantityReservedIntoModule + @Qty;
											END

											SET @stkWorkOrderMaterialsId = @SelectedWorkOrderMaterialsId;

											UPDATE TOP (@Qty) StkDraft
											SET StkDraft.SOQty = 0,
											StkDraft.WOQty = @Qty,
											StkDraft.ForStockQty = CASE WHEN StkDraft.Quantity < @Qty THEN 0 ELSE StkDraft.Quantity - @Qty END
											FROM DBO.StocklineDraft StkDraft
											WHERE StkDraft.StockLineId = @StkStocklineId AND StkDraft.WOQty IS NULL;

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
					ELSE IF EXISTS (SELECT TOP 1 1 FROM DBO.WorkOrderMaterialsKit WOMK WITH (NOLOCK) WHERE WOMK.WorkOrderId = @ReferenceId AND WOMK.ItemMasterId = @ItemMasterId AND WOMK.ConditionCodeId = @ConditionId)
					BEGIN
						DECLARE @SelectedWorkOrderMaterialsKitId INT = 0;
						DECLARE @WorkFlowWorkOrderKitId BIGINT = 0;

						SELECT @SelectedWorkOrderMaterialsKitId = WOMK.WorkOrderMaterialsKitId FROM DBO.WorkOrderMaterialsKit WOMK WITH (NOLOCK) 
						WHERE WOMK.WorkOrderId = @ReferenceId AND WOMK.ItemMasterId = @ItemMasterId AND WOMK.ConditionCodeId = @ConditionId;

						SET @Quantity = 0;
						SET @QuantityReserved = 0;
						SET @QuantityIssued = 0;

						SELECT @Quantity = WOMK.Quantity, @QuantityReserved = ISNULL(WOMK.QuantityReserved, 0), @QuantityIssued = ISNULL(WOMK.QuantityIssued, 0), @WorkFlowWorkOrderKitId = WOMK.WorkFlowWorkOrderId FROM DBO.WorkOrderMaterialsKit WOMK WITH (NOLOCK)
						WHERE WOMK.WorkOrderId = @ReferenceId AND WOMK.ItemMasterId = @ItemMasterId AND WOMK.ConditionCodeId = @ConditionId;

						IF (@Quantity > (@QuantityReserved + @QuantityIssued))
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
								SET @stkWorkOrderMaterialsId = 0;
								SET @stkPurchaseOrderUnitCost = 0;

								SELECT @stkMasterCompanyId = Stk.MasterCompanyId, @stkQty = Stk.Quantity, @stkQuantityAvailable = Stk.QuantityAvailable, @stkQuantityReserved = QuantityReserved,
								@stkQuantityOnOrder = QuantityOnOrder, @stkItemMasterId = Stk.ItemMasterId, @stkConditionId = Stk.ConditionId,
								@stkPurchaseOrderUnitCost = Stk.PurchaseOrderUnitCost
								FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.StockLineId = @StkStocklineId;

								IF (@Quantity > 0 AND @stkQty > 0)
								BEGIN
									IF (@stkQuantityAvailable > = @Quantity)
										SET @Qty = @Quantity - (@QuantityReserved + @QuantityIssued);
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
												SET WOMS.Quantity = @Qty,
												WOMS.StockLineId = @StkStocklineId,
												WOMS.UpdatedDate = GETUTCDATE(),
												WOMS.UpdatedBy = @UpdatedBy,
												WOMS.WorkOrderMaterialsKitId = @SelectedWorkOrderMaterialsKitId,
												WOMS.ItemMasterId = @stkItemMasterId,
												WOMS.ConditionId = @stkConditionId,
												WOMS.IsAltPart = 0,
												WOMS.IsEquPart = 0,
												WOMS.UnitCost = @stkPurchaseOrderUnitCost,
												WOMS.ExtendedCost = (@stkPurchaseOrderUnitCost * @Qty),
												WOMS.UnitPrice = @stkPurchaseOrderUnitCost,
												WOMS.ExtendedPrice = (@stkPurchaseOrderUnitCost * @Qty)
												FROM DBO.WorkOrderMaterialStockLineKit WOMS
												WHERE WOMS.WorkOrderMaterialsKitId = @SelectedWorkOrderMaterialsKitId AND WOMS.StockLineId = @StkStocklineId;

												SET @POReferenceQty = @POReferenceQty - @Qty;
												SET @QuantityReservedIntoModule = @QuantityReservedIntoModule + @Qty;
											END
											ELSE
											BEGIN
												INSERT INTO DBO.WorkOrderMaterialStockLineKit ([WorkOrderMaterialsKitId],[StockLineId],[ItemMasterId],[ConditionId],[Quantity],[QtyReserved],
												[QtyIssued],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[AltPartMasterPartId],[EquPartMasterPartId],
												[IsAltPart],[IsEquPart],[UnitCost],[ExtendedCost],[UnitPrice],[ExtendedPrice],[ProvisionId],[RepairOrderId],[QuantityTurnIn],[Figure],[Item],[RepairOrderPartRecordId])
												SELECT @SelectedWorkOrderMaterialsKitId, @StkStocklineId, @stkItemMasterId, @stkConditionId, @Qty, @WOMSQtyReserved, 
												0, @stkMasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, NULL, NULL, 
												0, 0, @stkPurchaseOrderUnitCost, (@stkPurchaseOrderUnitCost * @Qty), @stkPurchaseOrderUnitCost, (@stkPurchaseOrderUnitCost * @Qty),
												@ReplaceProvisionId, NULL, NULL, NULL, NULL, NULL

												SET @InsertedWorkOrderMaterialsId = SCOPE_IDENTITY();

												SET @POReferenceQty = @POReferenceQty - @Qty;
												SET @QuantityReservedIntoModule = @QuantityReservedIntoModule + @Qty;
											END

											SET @stkWorkOrderMaterialsId = @SelectedWorkOrderMaterialsKitId;

											UPDATE TOP (@Qty) StkDraft
											SET StkDraft.SOQty = 0,
											StkDraft.WOQty = @Qty,
											StkDraft.ForStockQty = CASE WHEN StkDraft.Quantity < @Qty THEN 0 ELSE StkDraft.Quantity - @Qty END
											FROM DBO.StocklineDraft StkDraft
											WHERE StkDraft.StockLineId = @StkStocklineId AND StkDraft.WOQty IS NULL;

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
						GOTO NextStockline;
					END

					UPDATE Stk
					SET Stk.Quantity = @stkQty,
					Stk.QuantityAvailable = @stkQuantityAvailable,
					Stk.QuantityOnHand = @stkQuantityOnHand,
					Stk.QuantityReserved = @stkQuantityReserved,
					Stk.QuantityIssued = @stkQuantityIssued,
					Stk.QuantityOnOrder = @stkQuantityOnOrder
					FROM DBO.Stockline Stk 
					WHERE Stk.StockLineId = @StkStocklineId;

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

				IF (@ModulId = 5) -- Sub Work Order
				BEGIN
					PRINT 'SUB WORK ORDER'
					SET @ItemMasterId = 0;
					SET @ConditionId = 0;
					SET @Requisitioner = 0;
					SET @PONumber = '';

					SELECT @ItemMasterId = POP.ItemMasterId, @ConditionId = POP.ConditionId FROM DBO.PurchaseOrderPart POP WITH (NOLOCK) WHERE PurchaseOrderPartRecordId = @PurchaseOrderPartId;
					SELECT @Requisitioner = PO.RequestedBy, @PONumber = PO.PurchaseOrderNumber FROM DBO.PurchaseOrder PO WITH (NOLOCK) WHERE PO.PurchaseOrderId = @PurchaseOrderId;

					IF EXISTS (SELECT TOP 1 1 FROM DBO.SubWorkOrderMaterials SWOM WITH (NOLOCK) WHERE SWOM.SubWorkOrderId = @ReferenceId AND SWOM.ItemMasterId = @ItemMasterId AND SWOM.ConditionCodeId = @ConditionId)
					BEGIN
						PRINT 'SWO EXISTS'
						DECLARE @SelectedWorkOrderMaterialsIdSWO INT = 0;
					
						SELECT @SelectedWorkOrderMaterialsIdSWO = SWOM.SubWorkOrderMaterialsId FROM DBO.SubWorkOrderMaterials SWOM WITH (NOLOCK) 
						WHERE SWOM.SubWorkOrderId = @ReferenceId AND SWOM.ItemMasterId = @ItemMasterId AND SWOM.ConditionCodeId = @ConditionId;
					
						SET @Quantity = 0;
						SET @QuantityReserved = 0;
						SET @QuantityIssued = 0;

						SELECT @Quantity = SWOM.Quantity, @QuantityReserved = ISNULL(SWOM.QuantityReserved, 0), @QuantityIssued = ISNULL(SWOM.QuantityIssued, 0) FROM DBO.SubWorkOrderMaterials SWOM WITH (NOLOCK)
						WHERE SWOM.SubWorkOrderId = @ReferenceId AND SWOM.ItemMasterId = @ItemMasterId AND SWOM.ConditionCodeId = @ConditionId;

						IF (@Quantity > (@QuantityReserved + @QuantityIssued))
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
										SET @Qty = @Quantity - (@QuantityReserved + @QuantityIssued);
									ELSE
										SET @Qty = @stkQuantityAvailable;
								END

								IF (@Qty > 0)
								BEGIN
									PRINT 'SWO @Qty > 0'
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
												SET SWOMS.Quantity = @Qty,
												SWOMS.StockLineId = @StkStocklineId,
												SWOMS.UpdatedDate = GETUTCDATE(),
												SWOMS.UpdatedBy = @UpdatedBy,
												SWOMS.SubWorkOrderMaterialsId = @SelectedWorkOrderMaterialsIdSWO,
												SWOMS.ItemMasterId = @stkItemMasterId,
												SWOMS.ConditionId = @stkConditionId,
												SWOMS.IsAltPart = 0,
												SWOMS.IsEquPart = 0,
												SWOMS.UnitCost = @stkPurchaseOrderUnitCost,
												SWOMS.ExtendedCost = (@stkPurchaseOrderUnitCost * @Qty),
												SWOMS.UnitPrice = @stkPurchaseOrderUnitCost,
												SWOMS.ExtendedPrice = (@stkPurchaseOrderUnitCost * @Qty)
												FROM DBO.SubWorkOrderMaterialStockLine SWOMS
												WHERE SWOMS.SubWorkOrderMaterialsId = @SelectedWorkOrderMaterialsIdSWO AND SWOMS.StockLineId = @StkStocklineId;

												SET @POReferenceQty = @POReferenceQty - @Qty;
												SET @QuantityReservedIntoModule = @QuantityReservedIntoModule + @Qty;
											END
											ELSE
											BEGIN
												INSERT INTO DBO.SubWorkOrderMaterialStockLine ([SubWorkOrderMaterialsId],[StockLineId],[ItemMasterId],[ConditionId],[Quantity],[QtyReserved],
												[QtyIssued],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[AltPartMasterPartId],[EquPartMasterPartId],
												[IsAltPart],[IsEquPart],[UnitCost],[ExtendedCost],[UnitPrice],[ExtendedPrice],[ProvisionId],[RepairOrderId],[QuantityTurnIn],[Figure],[Item])
												SELECT @SelectedWorkOrderMaterialsIdSWO, @StkStocklineId, @stkItemMasterId, @stkConditionId, @Qty, @WOMSQtyReserved, 
												0, @stkMasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, NULL, NULL, 
												0, 0, @stkPurchaseOrderUnitCost, (@stkPurchaseOrderUnitCost * @Qty), @stkPurchaseOrderUnitCost, (@stkPurchaseOrderUnitCost * @Qty),
												@ReplaceProvisionId, NULL, NULL, NULL, NULL

												SET @InsertedWorkOrderMaterialsId = SCOPE_IDENTITY();

												SET @POReferenceQty = @POReferenceQty - @Qty;
												SET @QuantityReservedIntoModule = @QuantityReservedIntoModule + @Qty;
											END

											SET @stkWorkOrderMaterialsId = @SelectedWorkOrderMaterialsIdSWO;

											UPDATE StkDraft
											SET StkDraft.SOQty = 0,
											StkDraft.WOQty = @Qty,
											StkDraft.ForStockQty = CASE WHEN StkDraft.Quantity < @Qty THEN 0 ELSE StkDraft.Quantity - @Qty END
											FROM DBO.StocklineDraft StkDraft
											WHERE StkDraft.StockLineId = @StkStocklineId AND StkDraft.WOQty IS NULL;

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
						GOTO NextStockline;
					END

					UPDATE Stk
					SET Stk.Quantity = @stkQty,
					Stk.QuantityAvailable = @stkQuantityAvailable,
					Stk.QuantityReserved = @stkQuantityReserved,
					Stk.QuantityOnOrder = @stkQuantityOnOrder
					FROM DBO.Stockline Stk 
					WHERE Stk.StockLineId = @StkStocklineId;

					SET @QuantityReservedForPoPart = @Qty;

					EXEC USP_AddUpdateStocklineHistory @StkStocklineId, 28, @PurchaseOrderId, 16, @ReferenceId, 2, @Qty, @UpdatedBy;

					IF (@stkWorkOrderMaterialsId > 0)
					BEGIN
						UPDATE Stk
						SET Stk.WorkOrderMaterialsId = @stkWorkOrderMaterialsId,
						Stk.WorkOrderId = @ReferenceId
						FROM DBO.Stockline Stk 
						WHERE Stk.StockLineId = @StkStocklineId;
					END
				END

				IF (@ModulId = 3) -- Sales Order
				BEGIN
					PRINT 'SALES ORDER'
					SET @ItemMasterId = 0;
					SET @ConditionId = 0;
					SET @Requisitioner = 0;
					SET @PONumber = '';

					SELECT @ItemMasterId = POP.ItemMasterId, @ConditionId = POP.ConditionId FROM DBO.PurchaseOrderPart POP WITH (NOLOCK) WHERE PurchaseOrderPartRecordId = @PurchaseOrderPartId;
					SELECT @Requisitioner = PO.RequestedBy, @PONumber = PO.PurchaseOrderNumber FROM DBO.PurchaseOrder PO WITH (NOLOCK) WHERE PO.PurchaseOrderId = @PurchaseOrderId;

					IF EXISTS (SELECT TOP 1 1 FROM DBO.SalesOrderPart SOP WITH (NOLOCK) WHERE SOP.SalesOrderId = @ReferenceId AND SOP.ItemMasterId = @ItemMasterId AND SOP.ConditionId = @ConditionId)
					BEGIN
						PRINT 'IF EXISTS (SELECT TOP 1 1 FROM DBO.SalesOrderPart SOP'

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
						SELECT [SalesOrderPartId] FROM DBO.SalesOrderPart SOP WITH (NOLOCK) WHERE SOP.SalesOrderId = @ReferenceId AND SOP.ItemMasterId = @ItemMasterId AND SOP.ConditionId = @ConditionId;

						DECLARE @SOPLoopID BIGINT;

						SELECT @SOPLoopID = MAX(ID) FROM #tmpSalesOrderPart;

						WHILE (@SOPLoopID > 0)
						BEGIN
							DECLARE @SelectedSalesOrderPartId BIGINT = 0;
							DECLARE @QtyRequested INT = 0;
							DECLARE @SOPQty INT = 0;

							SELECT @SelectedSalesOrderPartId = [SalesOrderPartId] FROM #tmpSalesOrderPart WHERE ID = @SOPLoopID;
							
							SELECT @QtyRequested = SOP.QtyRequested FROM DBO.SalesOrderPart SOP WITH (NOLOCK) WHERE SOP.SalesOrderPartId = @SelectedSalesOrderPartId;

							IF EXISTS (SELECT TOP 1 1 FROM DBO.SalesOrderPart SOP WITH (NOLOCK) WHERE SOP.SalesOrderId = @ReferenceId AND SOP.ItemMasterId = @ItemMasterId AND SOP.ConditionId = @ConditionId AND SOP.StockLineId IS NULL)
							BEGIN
								DECLARE @SalesOrderPartIdToUpdate BIGINT = 0;
								SELECT @SalesOrderPartIdToUpdate = SOP.[SalesOrderPartId] FROM DBO.SalesOrderPart SOP WITH (NOLOCK) WHERE SOP.SalesOrderId = @ReferenceId AND SOP.ItemMasterId = @ItemMasterId AND SOP.ConditionId = @ConditionId AND SOP.StockLineId IS NULL;

								PRINT 'IF EXISTS UPDATE SOP'

								SET @Qty = 0;
								SET @SOPQty = 0;

								IF (@stkQuantityAvailable > 0)
								BEGIN
									IF (@stkQuantityAvailable >= @QtyRequested)
										SET @Qty = @QtyRequested;
									ELSE IF (@QtyRequested >= @stkQuantityAvailable)
										SET @Qty = @stkQuantityAvailable;
								END

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
								FROM DBO.SalesOrderPart SOP
								WHERE SOP.SalesOrderPartId = @SalesOrderPartIdToUpdate;

								SET @POReferenceQty = @POReferenceQty - @Qty;
								SET @QuantityReservedIntoModule = @QuantityReservedIntoModule + @Qty;

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

								UPDATE StkDraft
								SET StkDraft.SOQty = @Qty,
								StkDraft.WOQty = 0,
								StkDraft.ForStockQty = CASE WHEN StkDraft.Quantity < @Qty THEN 0 ELSE StkDraft.Quantity - @Qty END
								FROM DBO.StocklineDraft StkDraft
								WHERE StkDraft.StockLineId = @StkStocklineId AND StkDraft.SOQty IS NULL;

								UPDATE StkDraft
								SET 
								StkDraft.ForStockQty = StkDraft.ForStockQty - @Qty
								FROM DBO.StocklineDraft StkDraft
								WHERE StkDraft.StockLineId = @StkStocklineId AND StkDraft.ForStockQty > 0;
							END
							ELSE
							BEGIN
								PRINT 'ELSE UPDATE SOP'
								IF NOT EXISTS (SELECT TOP 1 1 FROM DBO.SalesOrderPart SOP WITH (NOLOCK) WHERE SOP.SalesOrderId = @ReferenceId AND SOP.ItemMasterId = @ItemMasterId AND SOP.ConditionId = @ConditionId AND SOP.StockLineId = @StkStocklineId)
								BEGIN
									PRINT 'ELSE UPDATE SOP IF NOT EXISTS'
									IF EXISTS (SELECT TOP 1 1 FROM DBO.SalesOrderPart SOP WITH (NOLOCK) WHERE SOP.SalesOrderId = @ReferenceId AND SOP.ItemMasterId = @ItemMasterId AND SOP.ConditionId = @ConditionId)
									BEGIN
										PRINT 'ELSE UPDATE SOP IF EXISTS'
										SET @Qty = 0;
										SET @SOPQty = 0;

										DECLARE @qtySumAlreadyAdded AS INT = 0;
										DECLARE @SOPQtyRequested AS INT = 0;
										
										SELECT @SOPQtyRequested = SOP.QtyRequested FROM DBO.SalesOrderPart SOP WITH (NOLOCK) WHERE SOP.SalesOrderId = @ReferenceId AND SOP.ItemMasterId = @ItemMasterId AND SOP.ConditionId = @ConditionId

										SELECT @qtySumAlreadyAdded = SUM(SOP.Qty) FROM DBO.SalesOrderPart SOP WITH (NOLOCK) Where SOP.SalesOrderId = @ReferenceId AND SOP.ItemMasterId = @ItemMasterId AND SOP.ConditionId = @ConditionId;

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
											PRINT 'ELSE UPDATE SOP IF QTY > 0'
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
											[SalesOrderQuotePartId],[IsActive],[CustomerRequestDate],[PromisedDate],[EstimatedShipDate],[PriorityId],[StatusId],[CustomerReference],[QtyRequested],[Notes],[CurrencyId],
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

											UPDATE StkDraft
											SET StkDraft.SOQty = @Qty,
											StkDraft.WOQty = 0,
											StkDraft.ForStockQty = CASE WHEN StkDraft.Quantity < @Qty THEN 0 ELSE StkDraft.Quantity - @Qty END
											FROM DBO.StocklineDraft StkDraft
											WHERE StkDraft.StockLineId = @StkStocklineId;
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

					PRINT 'STK SO'
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

				EXEC UpdateStocklineColumnsWithId @StkStocklineId;

				NextStockline:

				SET @StkLoopID = @StkLoopID - 1;

				UPDATE DBO.PurchaseOrderPartReference 
				SET ReservedQty = ISNULL(ReservedQty, 0) + ISNULL(@QuantityReservedForPoPart, 0)
				WHERE PurchaseOrderPartReferenceId = @SelectedPurchaseOrderPartReferenceId;
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
/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <12/30/2021>  
** Description: <Save Work Order Materials reserve & Issue Stockline Details>  
  
EXEC [usp_ReserveIssueWorkOrderMaterialsStockline] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    12/30/2021  HEMANT SALIYA    Save Work Order Materials reserve & Issue Stockline Details
** 2    07/21/2022  VISHAL SUTHAR    Added new stockline history
** 3    06/27/2024  HEMANT SALIYA	 Update Stockline Qty Issue fox for MTI(Same Stk with multiple Lines)
** 4    08/05/2024  HEMANT SALIYA	 Fixed MTI stk Reserve Qty was not updating
** 5    09/12/2024  RAJESH GAMI		 Implemented Stockline History for the IssueReserve
** 6    09/24/2024  HEMANT SALIYA	 Re-Calculate WOM Qty Res & Qty Issue
** 7   10/04/2024   RAJESH GAMI 	 Implement the ReferenceNumber column data into WOMaterial | Kit Stockline table.

DECLARE @p1 dbo.ReserveWOMaterialsStocklineType

INSERT INTO @p1 values(65,72,87,1073,4,6,1,14,6,N'REPAIR',N'FLYSKY CT6B FS-CT6B',N'USED FOR WING REPAIR',5,3,1,N'CNTL-000463',N'ID_NUM-000001',N'STL-000123',N'',N'ADMIN ADMIN',1)

EXEC dbo.usp_ReserveIssueWorkOrderMaterialsStockline @tbl_MaterialsStocklineType=@p1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_ReserveIssueWorkOrderMaterialsStockline]
	@tbl_MaterialsStocklineType ReserveWOMaterialsStocklineType READONLY
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY

			BEGIN TRANSACTION
				BEGIN
					--CASE 1 UPDATE WORK ORDER MATERILS
					DECLARE @count INT;
					DECLARE @slcount INT;
					DECLARE @TotalCounts INT;
					DECLARE @StocklineId BIGINT; 
					DECLARE @MasterCompanyId INT; 
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
					DECLARE @ProvisionId BIGINT;
					DECLARE @IsSerialised BIT;
					DECLARE @stockLineQty INT;
					DECLARE @stockLineQtyAvailable INT;
					DECLARE @TotalCountsBoth INT;
					DECLARE @MaterialRefNo VARCHAR(100) = 'Reserve Issue';
					DECLARE @RC int;
                    DECLARE @DistributionMasterId bigint;
                    DECLARE @ReferencePartId bigint;
                    DECLARE @ReferencePieceId bigint;
                    DECLARE @InvoiceId bigint=0;
					DECLARE @IssueQty bigint=0;
                    DECLARE @laborType varchar(200)='';
                    DECLARE @issued bit=1;
                    DECLARE @Amount decimal(18,2);
                    DECLARE @ModuleName varchar(200)='WO';
                    DECLARE @UpdateBy varchar(200);
					DECLARE @IsKit BIGINT = 0;

					SELECT @ProvisionId = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'REPLACE' AND IsActive = 1 AND IsDeleted = 0;
					SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 15; -- For WORK ORDER Module
					SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 33; -- For WORK ORDER Materials Module
					select @DistributionMasterId =ID from DistributionMaster WITH(NOLOCK)  where UPPER(DistributionCode)= UPPER('WOMATERIALGRIDTAB')
					SET @ReservePartStatus = 3; -- FOR RESERTVE & ISSUE
					SET @IsAddUpdate = 0;
					SET @ExecuteParentChild = 1;
					SET @UpdateQuantities = 1;
					SET @IsOHUpdated = 0;
					SET @AddHistoryForNonSerialized = 0;					
					SET @slcount = 1;
					SET @count = 1;
					DECLARE @ActionId INT = (SELECT TOP 1 ActionId FROM [dbo].[StklineHistory_Action] WHERE [Type] = 'IssueReserve'); -- Added new action for Issue & Reserve

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
						[IsSerialized] BIT,
						[KitId] BIGINT NULL
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
						[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UnitCost], [IsSerialized], [KitId])
					SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], tblMS.[StockLineId], tblMS.[ItemMasterId], tblMS.[ConditionId], @ProvisionId, 
						[TaskId], [ReservedById], tblMS.[Condition], tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
						tblMS.[StockLineNumber], tblMS.[SerialNumber], [ReservedBy], [IsStocklineAdded], SL.MasterCompanyId, [ReservedBy], SL.UnitCost, SL.isSerialized, tblMS.[KitId]
					FROM @tbl_MaterialsStocklineType tblMS  JOIN dbo.Stockline SL ON SL.StockLineId = tblMS.StockLineId 
					WHERE SL.QuantityAvailable > 0 AND SL.QuantityAvailable >= tblMS.QuantityActReserved AND SL.QuantityOnHand > 0 AND SL.QuantityOnHand >= tblMS.QuantityActReserved

					SELECT @TotalCounts = COUNT(ID) FROM #tmpReserveWOMaterialsStockline;
					SELECT @IsKit = MAX(KitId) FROM #tmpReserveWOMaterialsStockline;
					SELECT @TotalCountsBoth = MAX(ID) FROM #tmpReserveWOMaterialsStockline;

					INSERT INTO #tmpIgnoredStockline ([PartNumber], [Condition], [ControlNo], [ControlId], [StockLineNumber]) 
					SELECT tblMS.[PartNumber], tblMS.[Condition], tblMS.[ControlNo], tblMS.[ControlId], tblMS.[StockLineNumber] FROM @tbl_MaterialsStocklineType tblMS  
					WHERE tblMS.StockLineId NOT IN (SELECT StockLineId FROM #tmpReserveWOMaterialsStockline)

					IF(ISNULL(@IsKit, 0) > 0)
					BEGIN
						--UPDATE WORK ORDER MATERIALS KIT DETAILS
						WHILE @count<= @TotalCounts
						BEGIN
							UPDATE WorkOrderMaterialsKit 
								SET 
									QuantityIssued = ISNULL(WOM.QuantityIssued,0) + ISNULL(tmpWOM.QuantityActReserved,0),
									TotalIssued = ISNULL(WOM.TotalIssued,0) + ISNULL(tmpWOM.QuantityActReserved,0),
									IssuedById = tmpWOM.ReservedById, 
									IssuedDate = GETDATE(), 
									UpdatedDate = GETDATE(),
									PartStatusId = @ReservePartStatus
							FROM dbo.WorkOrderMaterialsKit WOM JOIN #tmpReserveWOMaterialsStockline tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND tmpWOM.ID = @count
							SET @count = @count + 1;
						END;
					
						--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE KIT DETAILS
						IF(@TotalCounts > 0 )
						BEGIN
							MERGE dbo.WorkOrderMaterialStockLinekit AS TARGET
							USING #tmpReserveWOMaterialsStockline AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.WorkOrderMaterialsId = TARGET.WorkOrderMaterialskitId) -- TARGET.ItemMasterId = SOURCE.ItemMasterId AND TARGET.ConditionId = SOURCE.ConditionId) 
							--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
							WHEN MATCHED 				
								THEN UPDATE 						
								SET TARGET.QtyIssued = ISNULL(TARGET.QtyIssued, 0) + ISNULL(SOURCE.QuantityActReserved, 0),
									TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * TARGET.UnitCost,
									TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * TARGET.UnitCost,
									TARGET.UpdatedDate = GETDATE(),
									TARGET.UpdatedBy = SOURCE.ReservedBy,TARGET.ReferenceNumber = @MaterialRefNo
							WHEN NOT MATCHED BY TARGET 
								THEN INSERT (StocklineId, WorkOrderMaterialsKitId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted,ReferenceNumber) 
								VALUES (SOURCE.StocklineId, SOURCE.WorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.QuantityActReserved, 0, SOURCE.QuantityActReserved, SOURCE.UnitCost, (ISNULL(SOURCE.QuantityActReserved, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.QuantityActReserved, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0,@MaterialRefNo);
						END

						--FOR UPDATED WORKORDER MATERIALS STOCKLINE KIT QTY
						UPDATE dbo.WorkOrderMaterialStockLineKit 
						SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) ,ReferenceNumber = @MaterialRefNo
						FROM dbo.WorkOrderMaterialStockLineKit WOMS JOIN #tmpReserveWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsKitId = tmpRSL.WorkOrderMaterialsId 
						WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 

						--FOR UPDATED WORKORDER MATERIALS QTY
						UPDATE dbo.WorkOrderMaterialsKit 
						SET Quantity = GropWOM.Quantity	
						FROM(
							SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId   
							FROM dbo.WorkOrderMaterialsKit WOM 
							JOIN dbo.WorkOrderMaterialStockLineKit WOMS ON WOMS.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId 
							WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
							GROUP BY WOM.WorkOrderMaterialsKitId
						) GropWOM WHERE GropWOM.WorkOrderMaterialsId = dbo.WorkOrderMaterialsKit.WorkOrderMaterialsKitId AND ISNULL(GropWOM.Quantity,0) > ISNULL(dbo.WorkOrderMaterialsKit.Quantity,0)			


						DECLARE @countKitStockline INT = 1;

						--FOR FOR UPDATED STOCKLINE QTY
						WHILE @countKitStockline <= @TotalCountsBoth
						BEGIN
							DECLARE @tmpKitStockLineId BIGINT = 0;

							SELECT @tmpKitStockLineId = StockLineId FROM #tmpReserveWOMaterialsStockline WHERE ID = @countKitStockline

							--FOR UPDATED STOCKLINE QTY
							UPDATE dbo.Stockline
							SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) - ISNULL(tmpRSL.QuantityActReserved,0),
								QuantityOnHand = ISNULL(SL.QuantityOnHand, 0) - ISNULL(tmpRSL.QuantityActReserved,0),
								QuantityIssued = ISNULL(SL.QuantityIssued,0) + ISNULL(tmpRSL.QuantityActReserved,0),
								WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
							FROM dbo.Stockline SL JOIN #tmpReserveWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
							WHERE tmpRSL.ID = @countKitStockline AND Sl.StockLineId = @tmpKitStockLineId

							SET @countKitStockline = @countKitStockline + 1;
						END;

						--FOR UPDATE TOTAL WORK ORDER COST
						WHILE @count<= @TotalCounts
						BEGIN
							SELECT	@WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId
							FROM #tmpReserveWOMaterialsStockline tmpWOM 
							WHERE tmpWOM.ID = @count

							EXEC [dbo].[USP_UpdateWOMaterialsCost]  @WorkOrderMaterialsId = @WorkOrderMaterialsId
						
							SET @count = @count + 1;
						END;

						--FOR STOCK LINE HISTORY
						WHILE @slcount<= @TotalCounts
						BEGIN
							SELECT	@StocklineId = tmpWOM.StockLineId,
									@MasterCompanyId = tmpWOM.MasterCompanyId,
									@ReferenceId = tmpWOM.WorkOrderId,
									@SubReferenceId = tmpWOM.WorkOrderMaterialsId,
									@ReferencePartId=tmpWOM.WorkFlowWorkOrderId,
									@UpdateBy=UpdatedBy,
									@IssueQty=QuantityActReserved,
									@Amount=UnitCost,
									@ReferencePieceId=tmpWOM.WorkOrderMaterialsId
							FROM #tmpReserveWOMaterialsStockline tmpWOM 
							WHERE tmpWOM.ID = @slcount

							SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId

							EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @IssueQty, @UpdatedBy = @UpdateBy;

							-- batch trigger issue qty
							EXEC [dbo].[USP_BatchTriggerBasedonDistribution] 
							@DistributionMasterId,@ReferenceId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdateBy

							SET @slcount = @slcount + 1;
						END;
					END
					ELSE
					BEGIN
						--UPDATE WORK ORDER MATERIALS DETAILS
						WHILE @count<= @TotalCounts
						BEGIN
							UPDATE WorkOrderMaterials
								SET
								QuantityIssued = ISNULL(WOM.QuantityIssued,0) + ISNULL(tmpWOM.QuantityActReserved,0),
								TotalIssued = ISNULL(WOM.TotalIssued,0) + ISNULL(tmpWOM.QuantityActReserved,0),
								IssuedById = tmpWOM.ReservedById, 
								IssuedDate = GETDATE(), 
								UpdatedDate = GETDATE(),
								PartStatusId = @ReservePartStatus
							FROM dbo.WorkOrderMaterials WOM JOIN #tmpReserveWOMaterialsStockline tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.ID = @count
							SET @count = @count + 1;
						END;
					
						--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
						IF(@TotalCounts > 0 )
						BEGIN
							MERGE dbo.WorkOrderMaterialStockLine AS TARGET
							USING #tmpReserveWOMaterialsStockline AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.WorkOrderMaterialsId = TARGET.WorkOrderMaterialsId) -- TARGET.ItemMasterId = SOURCE.ItemMasterId AND TARGET.ConditionId = SOURCE.ConditionId) 
							--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
							WHEN MATCHED 				
								THEN UPDATE 						
								SET TARGET.QtyIssued = ISNULL(TARGET.QtyIssued, 0) + ISNULL(SOURCE.QuantityActReserved, 0),
									TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * TARGET.UnitCost,
									TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * TARGET.UnitCost,
									TARGET.UpdatedDate = GETDATE(),
									TARGET.UpdatedBy = SOURCE.ReservedBy,TARGET.ReferenceNumber = @MaterialRefNo
							WHEN NOT MATCHED BY TARGET 
								THEN INSERT (StocklineId, WorkOrderMaterialsId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted,ReferenceNumber) 
								VALUES (SOURCE.StocklineId, SOURCE.WorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.QuantityActReserved, 0, SOURCE.QuantityActReserved, SOURCE.UnitCost, (ISNULL(SOURCE.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0,@MaterialRefNo);
						END

						--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
						UPDATE dbo.WorkOrderMaterialStockLine 
						SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0),ReferenceNumber = @MaterialRefNo 
						FROM dbo.WorkOrderMaterialStockLine WOMS JOIN #tmpReserveWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId 
						WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 

						--FOR UPDATED WORKORDER MATERIALS QTY
						UPDATE dbo.WorkOrderMaterials 
						SET Quantity = GropWOM.Quantity	
						FROM(
							SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, WOM.WorkOrderMaterialsId   
							FROM dbo.WorkOrderMaterials WOM 
							JOIN dbo.WorkOrderMaterialStockLine WOMS ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId 
							WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
							GROUP BY WOM.WorkOrderMaterialsId
						) GropWOM WHERE GropWOM.WorkOrderMaterialsId = dbo.WorkOrderMaterials.WorkOrderMaterialsId AND ISNULL(GropWOM.Quantity,0) > ISNULL(dbo.WorkOrderMaterials.Quantity,0)			

						DECLARE @countStockline INT = 1;

						--FOR FOR UPDATED STOCKLINE QTY
						WHILE @countStockline <= @TotalCountsBoth
						BEGIN
							DECLARE @tmpStockLineId BIGINT = 0;

							SELECT @tmpStockLineId = StockLineId FROM #tmpReserveWOMaterialsStockline WHERE ID = @countStockline

							--FOR UPDATED STOCKLINE QTY
							UPDATE dbo.Stockline
							SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) - ISNULL(tmpRSL.QuantityActReserved,0),
								QuantityOnHand = ISNULL(SL.QuantityOnHand, 0) - ISNULL(tmpRSL.QuantityActReserved,0),
								QuantityIssued = ISNULL(SL.QuantityIssued,0) + ISNULL(tmpRSL.QuantityActReserved,0),
								WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
							FROM dbo.Stockline SL JOIN #tmpReserveWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
							WHERE tmpRSL.ID = @countStockline AND Sl.StockLineId = @tmpStockLineId

							SET @countStockline = @countStockline + 1;
						END;

						--RE-CALCULATE WOM QTY RES & QTY ISSUE					
						UPDATE dbo.WorkOrderMaterials 
						SET QuantityIssued = GropWOM.QtyIssued, QuantityReserved = GropWOM.QtyReserved
						FROM(
							SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, ISNULL(SUM(WOMS.QtyReserved), 0) QtyReserved, ISNULL(SUM(WOMS.QtyIssued), 0) QtyIssued, WOM.WorkOrderMaterialsId   
							FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)
							JOIN dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId 
							JOIN #tmpReserveWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId 
								AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
							WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
							GROUP BY WOM.WorkOrderMaterialsId
						) GropWOM WHERE GropWOM.WorkOrderMaterialsId = dbo.WorkOrderMaterials.WorkOrderMaterialsId AND 
						(ISNULL(GropWOM.QtyReserved,0) <> ISNULL(dbo.WorkOrderMaterials.QuantityReserved,0)	OR ISNULL(GropWOM.QtyIssued,0) <> ISNULL(dbo.WorkOrderMaterials.QuantityIssued,0))


						--FOR UPDATE TOTAL WORK ORDER COST
						WHILE @count<= @TotalCounts
						BEGIN
							SELECT	@WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId
							FROM #tmpReserveWOMaterialsStockline tmpWOM 
							WHERE tmpWOM.ID = @count

							EXEC [dbo].[USP_UpdateWOMaterialsCost]  @WorkOrderMaterialsId = @WorkOrderMaterialsId
						
							SET @count = @count + 1;
						END;

						--FOR STOCK LINE HISTORY
						WHILE @slcount<= @TotalCounts
						BEGIN
							SELECT	@StocklineId = tmpWOM.StockLineId,
									@MasterCompanyId = tmpWOM.MasterCompanyId,
									@ReferenceId = tmpWOM.WorkOrderId,
									@SubReferenceId = tmpWOM.WorkOrderMaterialsId,
									@ReferencePartId=tmpWOM.WorkFlowWorkOrderId,
									@UpdateBy=UpdatedBy,
									@IssueQty=QuantityActReserved,
									@Amount=UnitCost,
									@ReferencePieceId=tmpWOM.WorkOrderMaterialsId
							FROM #tmpReserveWOMaterialsStockline tmpWOM 
							WHERE tmpWOM.ID = @slcount

							SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId

							EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @IssueQty, @UpdatedBy = @UpdateBy;

							-- batch trigger issue qty
							EXEC [dbo].[USP_BatchTriggerBasedonDistribution] 
							@DistributionMasterId,@ReferenceId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdateBy

							SET @slcount = @slcount + 1;
						END;
					END

					SELECT * FROM #tmpIgnoredStockline

					IF OBJECT_ID(N'tempdb..#tmpIgnoredStockline') IS NOT NULL
					BEGIN
					DROP TABLE #tmpIgnoredStockline
					END

					IF OBJECT_ID(N'tempdb..#tmpReserveWOMaterialsStockline') IS NOT NULL
					BEGIN
					DROP TABLE #tmpReserveWOMaterialsStockline
					END
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
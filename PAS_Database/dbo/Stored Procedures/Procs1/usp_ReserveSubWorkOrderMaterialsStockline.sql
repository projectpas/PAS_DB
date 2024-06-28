/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <12/30/2021>  
** Description: <Save Sub Work Order Materials reserve Stockline Details>  
  
EXEC [usp_ReserveSubWorkOrderMaterialsStockline] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author				Change Description  
** --   --------    -------			 --------------------------------
** 1    12/30/2021  HEMANT SALIYA		Save Sub Work Order Materials reserve Stockline Details
** 2    07/19/2023  VISHAL SUTHAR		Added new stockline history for SWO
** 3    12/14/2023  Devendra Shekh		Changes for manual reserve save and added kit part
** 4    06/27/2024  HEMANT SALIYA		Update Stockline Qty Issue fox for MTI(Same Stk with multiple Lines)

DECLARE @p1 dbo.SubWOMaterialsStocklineType

INSERT INTO @p1 values(65,72,87,1073,4,6,1,14,6,N'REPAIR',N'FLYSKY CT6B FS-CT6B',N'USED FOR WING REPAIR',5,3,1,N'CNTL-000463',N'ID_NUM-000001',N'STL-000123',N'',N'ADMIN ADMIN',1)
INSERT INTO @p1 values(65,72,99,2093,25,6,1,14,6,N'REPAIR',N'WAT0303-01',N'70303-01 RECOGNITION LIGHT 28V 25W',3,3,2,N'CNTL-000526',N'ID_NUM-000001',N'STL-000009',N'',N'ADMIN ADMIN',1)
INSERT INTO @p1 values(65,72,10099,510,15,34,2,14,6,N'INSPECTED',N'AIR-MAZE',N'AIR-MAZE U2-849 AERONCA AIR FILTER',10,7,1,N'CNTL-000308',N'ID_NUM-000001',N'STL-000072',N'',N'ADMIN ADMIN',1)
INSERT INTO @p1 values(65,72,10099,512,15,34,2,14,6,N'INSPECTED',N'AIR-MAZE',N'AIR-MAZE U2-849 AERONCA AIR FILTER',10,7,1,N'CNTL-000310',N'ID_NUM-000001',N'STL-000072',N'',N'ADMIN ADMIN',0)
INSERT INTO @p1 values(65,72,10099,513,15,34,2,14,6,N'INSPECTED',N'AIR-MAZE',N'AIR-MAZE U2-849 AERONCA AIR FILTER',10,7,1,N'CNTL-000311',N'ID_NUM-000001',N'STL-000072',N'',N'ADMIN ADMIN',0)

EXEC dbo.usp_ReserveSubWorkOrderMaterialsStockline @tbl_MaterialsStocklineType=@p1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_ReserveSubWorkOrderMaterialsStockline]
	@tbl_MaterialsStocklineType SubWOMaterialsStocklineType READONLY
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
					DECLARE @SubWorkOrderMaterialsId BIGINT;
					DECLARE @ProvisionId BIGINT;
					DECLARE @IsSerialised BIT;
					DECLARE @stockLineQty INT;
					DECLARE @stockLineQtyAvailable INT;
					DECLARE @UpdateBy varchar(200);
					DECLARE @ReservedQty bigint = 0;
					DECLARE @IsKit BIGINT = 0;
					DECLARE @ActionId INT = 0;
					DECLARE @TotalCountsBoth INT;

					SELECT @ProvisionId = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'REPLACE' AND IsActive = 1 AND IsDeleted = 0;
					SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 16; -- For SUB WORK ORDER Module
					SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'SubWorkOrderMaterials'; -- For Sub WORK ORDER Materials Module
					SET @ReservePartStatus = 1; -- FOR RESERTVE
					SET @IsAddUpdate = 0;
					SET @ExecuteParentChild = 1;
					SET @UpdateQuantities = 1;
					SET @IsOHUpdated = 0;
					SET @AddHistoryForNonSerialized = 0;					
					SET @slcount = 1;
					SET @count = 1;

					IF OBJECT_ID(N'tempdb..#tmpReserveWOMaterialsStockline') IS NOT NULL
					BEGIN
					DROP TABLE #tmpReserveWOMaterialsStockline
					END
			
					CREATE TABLE #tmpReserveWOMaterialsStockline
					(
						ID BIGINT NOT NULL IDENTITY, 
						[WorkOrderId] BIGINT NULL,
						[SubWorkOrderId] BIGINT NULL,
						[SubWOPartNoId] BIGINT NULL,
						[SubWorkOrderMaterialsId] BIGINT NULL,
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
						[KitId] BIGINT NULL,
						[IsAltPart] [BIT] NULL,
						[IsEquPart] [BIT] NULL,
						[AltPartMasterPartId] [bigint] NULL,
						[EquPartMasterPartId] [bigint] NULL
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

					INSERT INTO #tmpReserveWOMaterialsStockline ([WorkOrderId],[SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
						[TaskId], [ReservedById], [Condition], [PartNumber], [PartDescription], [Quantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
						[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UnitCost], [IsSerialized], [KitId], [IsAltPart], [IsEquPart], [AltPartMasterPartId], [EquPartMasterPartId])
					SELECT tblMS.[WorkOrderId],tblMS.[SubWorkOrderId], tblMS.[SubWOPartNoId], tblMS.[SubWorkOrderMaterialsId], tblMS.[StockLineId], tblMS.[ItemMasterId], tblMS.[ConditionId], @ProvisionId, 
						[TaskId], [ReservedById], tblMS.[Condition], tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
						tblMS.[StockLineNumber], tblMS.[SerialNumber], [ReservedBy], [IsStocklineAdded], SL.MasterCompanyId, [ReservedBy], SL.UnitCost, SL.isSerialized, tblMS.[KitId], tblMS.[IsAltPart], tblMS.[IsEquPart], tblMS.[AltPartMasterPartId], tblMS.[EquPartMasterPartId]
					FROM @tbl_MaterialsStocklineType tblMS  JOIN dbo.Stockline SL ON SL.StockLineId = tblMS.StockLineId 
					WHERE SL.QuantityAvailable > 0 AND SL.QuantityAvailable >= tblMS.QuantityActReserved

					SELECT @TotalCounts = COUNT(ID) FROM #tmpReserveWOMaterialsStockline;
					SELECT @IsKit = MAX(KitId) FROM #tmpReserveWOMaterialsStockline;
					SELECT @TotalCountsBoth = COUNT(ID) FROM #tmpReserveWOMaterialsStockline;

					INSERT INTO #tmpIgnoredStockline ([PartNumber], [Condition], [ControlNo], [ControlId], [StockLineNumber]) 
					SELECT tblMS.[PartNumber], tblMS.[Condition], tblMS.[ControlNo], tblMS.[ControlId], tblMS.[StockLineNumber] FROM @tbl_MaterialsStocklineType tblMS  
					WHERE tblMS.StockLineId NOT IN (SELECT StockLineId FROM #tmpReserveWOMaterialsStockline)
		
					IF(ISNULL(@IsKit, 0) > 0)
					BEGIN
						
						--UPDATE SUB WORK ORDER MATERIALS DETAILS
						WHILE @count<= @TotalCounts
						BEGIN
							UPDATE SubWorkOrderMaterialsKit
								SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.QuantityActReserved,0),
									TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.QuantityActReserved,0),
									ReservedById = tmpWOM.ReservedById, 
									ReservedDate = GETDATE(), 
									UpdatedDate = GETDATE(),
									PartStatusId = @ReservePartStatus
							FROM dbo.SubWorkOrderMaterialsKit WOM JOIN #tmpReserveWOMaterialsStockline tmpWOM ON tmpWOM.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId AND tmpWOM.ID = @count
							SET @count = @count + 1;
						END;
					
						--UPDATE/INSERT SUB WORK ORDER MATERIALS STOCKLINE DETAILS
						IF(@TotalCounts > 0 )
						BEGIN
							MERGE dbo.SubWorkOrderMaterialStockLineKit AS TARGET
							USING #tmpReserveWOMaterialsStockline AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.SubWorkOrderMaterialsId = TARGET.SubWorkOrderMaterialsKitId) 
							--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
							WHEN MATCHED 				
								THEN UPDATE 						
								SET TARGET.QtyReserved = ISNULL(TARGET.QtyReserved, 0) + ISNULL(SOURCE.QuantityActReserved, 0),
									TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * TARGET.UnitCost,
									TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * TARGET.UnitCost,
									TARGET.UpdatedDate = GETDATE(),
									TARGET.UpdatedBy = SOURCE.ReservedBy
							WHEN NOT MATCHED BY TARGET 
								THEN INSERT (StocklineId, SubWorkOrderMaterialsKitId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted, AltPartMasterPartId, EquPartMasterPartId, IsAltPart, IsEquPart) 
								VALUES (SOURCE.StocklineId, SOURCE.SubWorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.QuantityActReserved, SOURCE.QuantityActReserved, 0, SOURCE.UnitCost, (ISNULL(SOURCE.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0, SOURCE.AltPartMasterPartId, SOURCE.EquPartMasterPartId, SOURCE.IsAltPart, SOURCE.IsEquPart);
						END

						--FOR UPDATED SUB WORKORDER MATERIALS STOCKLINE QTY
						UPDATE dbo.SubWorkOrderMaterialStockLineKit 
						SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
						FROM dbo.SubWorkOrderMaterialStockLineKit WOMS JOIN #tmpReserveWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.SubWorkOrderMaterialsKitId = tmpRSL.SubWorkOrderMaterialsId 
						WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 

						--FOR UPDATED SUB WORKORDER MATERIALS QTY
						UPDATE dbo.SubWorkOrderMaterialsKit 
						SET Quantity = GropWOM.Quantity	
						FROM (
							SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, WOM.SubWorkOrderMaterialsKitId AS SubWorkOrderMaterialsId
							FROM dbo.SubWorkOrderMaterialsKit WOM 
							JOIN dbo.SubWorkOrderMaterialStockLineKit WOMS ON WOMS.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId 
							WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
							GROUP BY WOM.SubWorkOrderMaterialsKitId
						) GropWOM WHERE GropWOM.SubWorkOrderMaterialsId = dbo.SubWorkOrderMaterialsKit.SubWorkOrderMaterialsKitId AND ISNULL(GropWOM.Quantity,0) > ISNULL(dbo.SubWorkOrderMaterialsKit.Quantity,0)			

						DECLARE @countKitStockline INT = 1;

						--FOR FOR UPDATED STOCKLINE QTY
						WHILE @countKitStockline <= @TotalCountsBoth
						BEGIN
							DECLARE @tmpKitStockLineId BIGINT;

							SELECT @tmpKitStockLineId = StockLineId FROM #tmpReserveWOMaterialsStockline WHERE ID = @countKitStockline

							--FOR UPDATED STOCKLINE QTY
							UPDATE dbo.Stockline
							SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) - ISNULL(tmpRSL.QuantityActReserved,0),
								QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(tmpRSL.QuantityActReserved,0)						
							FROM dbo.Stockline SL JOIN #tmpReserveWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
							WHERE tmpRSL.ID = @countKitStockline AND Sl.StockLineId = @tmpKitStockLineId

							SET @countKitStockline = @countKitStockline + 1;
						END;

						--FOR UPDATE TOTAL WORK ORDER COST
						WHILE @count<= @TotalCounts
						BEGIN
							SELECT	@SubWorkOrderMaterialsId = tmpWOM.SubWorkOrderMaterialsId
							FROM #tmpReserveWOMaterialsStockline tmpWOM 
							WHERE tmpWOM.ID = @count

							EXEC [dbo].[USP_UpdateSubWOMaterialsCost]  @SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId
						
							SET @count = @count + 1;
						END;

						--FOR STOCK LINE HISTORY
						WHILE @slcount<= @TotalCounts
						BEGIN
							SELECT	@StocklineId = tmpWOM.StockLineId,
									@MasterCompanyId = tmpWOM.MasterCompanyId,
									@ReferenceId = tmpWOM.SubWorkOrderId,
									@SubReferenceId = tmpWOM.SubWorkOrderMaterialsId,
									@UpdateBy = UpdatedBy,
									@ReservedQty = QuantityActReserved
							FROM #tmpReserveWOMaterialsStockline tmpWOM 
							WHERE tmpWOM.ID = @slcount

							SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId
							SET @ActionId = 2; -- Reserve
							EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @ReservedQty, @UpdatedBy = @UpdateBy;

							SET @slcount = @slcount + 1;
						END;

					END
					ELSE
					BEGIN

						--UPDATE SUB WORK ORDER MATERIALS DETAILS
						WHILE @count<= @TotalCounts
						BEGIN
							UPDATE SubWorkOrderMaterials 
								SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.QuantityActReserved,0),
									TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.QuantityActReserved,0),
									ReservedById = tmpWOM.ReservedById, 
									ReservedDate = GETDATE(), 
									UpdatedDate = GETDATE(),
									PartStatusId = @ReservePartStatus
							FROM dbo.SubWorkOrderMaterials WOM JOIN #tmpReserveWOMaterialsStockline tmpWOM ON tmpWOM.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND tmpWOM.ID = @count
							SET @count = @count + 1;
						END;
					
						--UPDATE/INSERT SUB WORK ORDER MATERIALS STOCKLINE DETAILS
						IF(@TotalCounts > 0 )
						BEGIN
							MERGE dbo.SubWorkOrderMaterialStockLine AS TARGET
							USING #tmpReserveWOMaterialsStockline AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.SubWorkOrderMaterialsId = TARGET.SubWorkOrderMaterialsId) 
							--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
							WHEN MATCHED 				
								THEN UPDATE 						
								SET TARGET.QtyReserved = ISNULL(TARGET.QtyReserved, 0) + ISNULL(SOURCE.QuantityActReserved, 0),
									TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * TARGET.UnitCost,
									TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * TARGET.UnitCost,
									TARGET.UpdatedDate = GETDATE(),
									TARGET.UpdatedBy = SOURCE.ReservedBy
							WHEN NOT MATCHED BY TARGET 
								THEN INSERT (StocklineId, SubWorkOrderMaterialsId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted, AltPartMasterPartId, EquPartMasterPartId, IsAltPart, IsEquPart)
								VALUES (SOURCE.StocklineId, SOURCE.SubWorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.QuantityActReserved, SOURCE.QuantityActReserved, 0, SOURCE.UnitCost, (ISNULL(SOURCE.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0, SOURCE.AltPartMasterPartId, SOURCE.EquPartMasterPartId, SOURCE.IsAltPart, SOURCE.IsEquPart);
						END

						--FOR UPDATED SUB WORKORDER MATERIALS STOCKLINE QTY
						UPDATE dbo.SubWorkOrderMaterialStockLine 
						SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
						FROM dbo.SubWorkOrderMaterialStockLine WOMS JOIN #tmpReserveWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.SubWorkOrderMaterialsId = tmpRSL.SubWorkOrderMaterialsId 
						WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 

						--FOR UPDATED SUB WORKORDER MATERIALS QTY
						UPDATE dbo.SubWorkOrderMaterials 
						SET Quantity = GropWOM.Quantity	
						FROM (
							SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, WOM.SubWorkOrderMaterialsId   
							FROM dbo.SubWorkOrderMaterials WOM 
							JOIN dbo.SubWorkOrderMaterialStockLine WOMS ON WOMS.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId 
							WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
							GROUP BY WOM.SubWorkOrderMaterialsId
						) GropWOM WHERE GropWOM.SubWorkOrderMaterialsId = dbo.SubWorkOrderMaterials.SubWorkOrderMaterialsId AND ISNULL(GropWOM.Quantity,0) > ISNULL(dbo.SubWorkOrderMaterials.Quantity,0)			

						DECLARE @countStockline INT = 1;

						--FOR FOR UPDATED STOCKLINE QTY
						WHILE @countStockline <= @TotalCountsBoth
						BEGIN
							DECLARE @tmpStockLineId BIGINT;

							SELECT @tmpStockLineId = StockLineId FROM #tmpReserveWOMaterialsStockline WHERE ID = @countStockline

							--FOR UPDATED STOCKLINE QTY
							UPDATE dbo.Stockline
							SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) - ISNULL(tmpRSL.QuantityActReserved,0),
								QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(tmpRSL.QuantityActReserved,0)						
							FROM dbo.Stockline SL JOIN #tmpReserveWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
							WHERE tmpRSL.ID = @countStockline AND Sl.StockLineId = @tmpStockLineId

							SET @countStockline = @countStockline + 1;
						END;
					
						--FOR UPDATE TOTAL WORK ORDER COST
						WHILE @count<= @TotalCounts
						BEGIN
							SELECT	@SubWorkOrderMaterialsId = tmpWOM.SubWorkOrderMaterialsId
							FROM #tmpReserveWOMaterialsStockline tmpWOM 
							WHERE tmpWOM.ID = @count

							EXEC [dbo].[USP_UpdateSubWOMaterialsCost]  @SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId
						
							SET @count = @count + 1;
						END;

						--FOR STOCK LINE HISTORY
						WHILE @slcount<= @TotalCounts
						BEGIN
							SELECT	@StocklineId = tmpWOM.StockLineId,
									@MasterCompanyId = tmpWOM.MasterCompanyId,
									@ReferenceId = tmpWOM.SubWorkOrderId,
									@SubReferenceId = tmpWOM.SubWorkOrderMaterialsId,
									@UpdateBy = UpdatedBy,
									@ReservedQty = QuantityActReserved
							FROM #tmpReserveWOMaterialsStockline tmpWOM 
							WHERE tmpWOM.ID = @slcount

							SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId

							SET @ActionId = 2; -- Reserve
							EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @ReservedQty, @UpdatedBy = @UpdateBy;

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
              , @AdhocComments     VARCHAR(150)    = 'usp_ReserveSubWorkOrderMaterialsStockline' 
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
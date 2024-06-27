/*************************************************************   
** Author:  <Vishal Suthar>  
** Create date: <08/08/2023>  
** Description: <Save Work Order Materials Issue Stockline Details>  
  
EXEC [usp_UnReserveAndUnIssueWorkOrderMaterialsStockline] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date			Author				Change Description  
** --   --------		-------				--------------------------------
** 1    08/08/2023		Vishal Suthar		Created
** 2    08/18/2023	    AMIT GHEDIYA        Update historytext for wohistory.
** 3    06/26/2024	    HEMANT SALIYA       Updated for Handle Stockline Qty Updated Issue 

**************************************************************/ 
CREATE     PROCEDURE [dbo].[usp_UnReserveAndUnIssueWorkOrderMaterialsStockline]
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
					DECLARE @countKIT INT;
					DECLARE @slcount INT;
					DECLARE @TotalCounts INT;
					DECLARE @TotalCountsKIT INT;
					DECLARE @TotalCountsBoth INT;
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
					DECLARE @PartStatus INT;
					DECLARE @WorkOrderMaterialsId BIGINT;
					DECLARE @IsSerialised BIT;
					DECLARE @stockLineQty INT;
					DECLARE @stockLineQtyAvailable INT;
					DECLARE @RC INT;
                    DECLARE @DistributionMasterId BIGINT;
                    DECLARE @ReferencePartId BIGINT;
                    DECLARE @ReferencePieceId BIGINT;
                    DECLARE @InvoiceId BIGINT = 0;
					DECLARE @IssueQty BIGINT = 0;
                    DECLARE @laborType VARCHAR(200) = 'lab';
                    DECLARE @issued BIT = 0;
                    DECLARE @Amount DECIMAL(18,2);
                    DECLARE @ModuleName VARCHAR(200) = 'WOP-PartsIssued';
                    DECLARE @UpdateBy VARCHAR(200);
					DECLARE @IsKit BIGINT = 0;
					DECLARE @Qty BIGINT = 0;
					DECLARE @ActionId INT = 0;
					DECLARE @historyPartNumber VARCHAR(150);

					SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 15; -- For WORK ORDER Module
					SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 33; -- For WORK ORDER Materials Module
					SELECT @DistributionMasterId = ID FROM DistributionMaster WITH(NOLOCK)  where UPPER(DistributionCode)= UPPER('WOMATERIALGRIDTAB')

					SET @PartStatus = 4; -- FOR Un-Issue
					SET @IsAddUpdate = 0;
					SET @ExecuteParentChild = 1;
					SET @UpdateQuantities = 1;
					SET @IsOHUpdated = 0;
					SET @AddHistoryForNonSerialized = 0;					
					SET @slcount = 1;
					SET @count = 1;
					SET @countKIT = 1;

					IF OBJECT_ID(N'tempdb..#tmpUnIssueWOMaterialsStockline') IS NOT NULL
					BEGIN
						DROP TABLE #tmpUnIssueWOMaterialsStockline
					END
			
					CREATE TABLE #tmpUnIssueWOMaterialsStockline
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
						[Condition] VARCHAR(500) NULL,
						[PartNumber] VARCHAR(500) NULL,
						[PartDescription] VARCHAR(max) NULL,
						[Quantity] INT NULL,
						[QtyToBeReserved] INT NULL,
						[QuantityActUnIssued] INT NULL,
						[ControlNo] VARCHAR(500) NULL,
						[ControlId] VARCHAR(500) NULL,
						[StockLineNumber] VARCHAR(500) NULL,
						[SerialNumber] VARCHAR(500) NULL,
						[ReservedBy] VARCHAR(500) NULL,						 
						[IsStocklineAdded] BIT NULL,
						[MasterCompanyId] BIGINT NULL,
						[UpdatedBy] VARCHAR(500) NULL,
						[UpdatedById] BIGINT NULL,
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

					INSERT INTO #tmpUnIssueWOMaterialsStockline ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
						[TaskId], [Condition], [PartNumber], [PartDescription], [Quantity], [QtyToBeReserved], [QuantityActUnIssued], [ControlNo], [ControlId],
						[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UpdatedById],  [UnitCost], [IsSerialized], [KitId])
					SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], tblMS.[StockLineId], tblMS.[ItemMasterId], tblMS.[ConditionId], [ProvisionId], 
						[TaskId], tblMS.[Condition], tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], [QtyToBeReserved], [QuantityActUnIssued], [ControlNo], [ControlId],
						tblMS.[StockLineNumber], tblMS.[SerialNumber], [ReservedBy], [IsStocklineAdded], SL.MasterCompanyId, [ReservedBy], [ReservedById], SL.UnitCost, SL.isSerialized, tblMS.[KitId]
					FROM @tbl_MaterialsStocklineType tblMS  JOIN dbo.Stockline SL ON SL.StockLineId = tblMS.StockLineId 
					WHERE SL.QuantityIssued > 0 AND SL.QuantityIssued >= tblMS.QuantityActUnIssued

					SELECT @TotalCounts = COUNT(ID) FROM #tmpUnIssueWOMaterialsStockline WHERE ISNULL(KitId, 0) = 0;
					SELECT @TotalCountsKIT = COUNT(ID) FROM #tmpUnIssueWOMaterialsStockline WHERE ISNULL(KitId, 0) > 0;
					SELECT @TotalCountsBoth = COUNT(ID) FROM #tmpUnIssueWOMaterialsStockline;

					INSERT INTO #tmpIgnoredStockline ([PartNumber], [Condition], [ControlNo], [ControlId], [StockLineNumber]) 
					SELECT tblMS.[PartNumber], tblMS.[Condition], tblMS.[ControlNo], tblMS.[ControlId], tblMS.[StockLineNumber] FROM @tbl_MaterialsStocklineType tblMS  
					WHERE tblMS.StockLineId NOT IN (SELECT StockLineId FROM #tmpUnIssueWOMaterialsStockline)
		
					--UPDATE WORK ORDER MATERIALS DETAILS
					WHILE @countKIT <= @TotalCountsBoth
					BEGIN
						UPDATE WorkOrderMaterialsKit 
							SET QuantityIssued = ISNULL(WOM.QuantityIssued,0) - ISNULL(tmpWOM.QuantityActUnIssued,0),
								--QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.QuantityActUnIssued,0),
								TotalIssued = ISNULL(WOM.TotalIssued,0) - ISNULL(tmpWOM.QuantityActUnIssued,0),
								--TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.QuantityActUnIssued,0),
								IssuedById = tmpWOM.UpdatedById, 
								IssuedDate = GETDATE(), 
								UpdatedDate = GETDATE(),
								PartStatusId = @PartStatus
						FROM dbo.WorkOrderMaterialsKit WOM JOIN #tmpUnIssueWOMaterialsStockline tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND tmpWOM.ID = @countKIT 
						WHERE ISNULL(tmpWOM.KitId, 0) > 0;

						SET @countKIT = @countKIT + 1;
					END;
					
					--UPDATE WORK ORDER MATERIALS STOCKLINE DETAILS
					IF (@TotalCountsBoth > 0)
					BEGIN
						UPDATE dbo.WorkOrderMaterialStockLineKit 
						SET QtyIssued = ISNULL(QtyIssued, 0) - ISNULL(QuantityActUnIssued, 0),
							--QtyReserved = ISNULL(QtyReserved, 0) + ISNULL(QuantityActUnIssued, 0),
							ExtendedCost = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							ExtendedPrice = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							UpdatedDate = GETDATE(),
							UpdatedBy = ReservedBy
						FROM dbo.WorkOrderMaterialStockLineKit WOMS 
						JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsKitId = tmpRSL.WorkOrderMaterialsId 
						WHERE ISNULL(tmpRSL.KitId, 0) > 0;
					END

					--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
					UPDATE dbo.WorkOrderMaterialStockLineKit 
					SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
					FROM dbo.WorkOrderMaterialStockLineKit WOMS JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsKitId = tmpRSL.WorkOrderMaterialsId 
					WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) AND ISNULL(tmpRSL.KitId, 0) > 0
					

					DECLARE @countKitStockline INT = 1;

					--FOR FOR UPDATED STOCKLINE QTY
					WHILE @countKitStockline <= @TotalCountsBoth
					BEGIN
						DECLARE @tmpKitStockLineId BIGINT;

						SELECT @tmpKitStockLineId = StockLineId FROM #tmpUnIssueWOMaterialsStockline WHERE ID = @countKitStockline

						--FOR UPDATED STOCKLINE QTY
						UPDATE dbo.Stockline
						SET QuantityOnHand = ISNULL(SL.QuantityOnHand, 0) + ISNULL(tmpRSL.QuantityActUnIssued,0),
							QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) + ISNULL(tmpRSL.QuantityActUnIssued, 0),
							QuantityIssued = ISNULL(SL.QuantityIssued,0) - ISNULL(tmpRSL.QuantityActUnIssued,0),
							WorkOrderMaterialsKitId = tmpRSL.WorkOrderMaterialsId
						FROM dbo.Stockline SL JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
						WHERE ISNULL(tmpRSL.KitId, 0) > 0 AND tmpRSL.ID = @countKitStockline AND Sl.StockLineId = @tmpKitStockLineId

						SET @countKitStockline = @countKitStockline + 1;
					END;

					--UPDATE WORK ORDER MATERIALS DETAILS
					WHILE @count <= @TotalCountsBoth
					BEGIN						
						UPDATE WorkOrderMaterials 
							SET QuantityIssued = ISNULL(WOM.QuantityIssued,0) - ISNULL(tmpWOM.QuantityActUnIssued,0),
								--QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.QuantityActUnIssued,0),
								TotalIssued = ISNULL(WOM.TotalIssued,0) - ISNULL(tmpWOM.QuantityActUnIssued,0),
								--TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.QuantityActUnIssued,0),
								IssuedById = tmpWOM.UpdatedById, 
								IssuedDate = GETDATE(), 
								UpdatedDate = GETDATE(),
								PartStatusId = @PartStatus
						FROM dbo.WorkOrderMaterials WOM JOIN #tmpUnIssueWOMaterialsStockline tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.ID = @count AND ISNULL(tmpWOM.KitId, 0) = 0
						SET @count = @count + 1;
					END;
					
					--UPDATE WORK ORDER MATERIALS STOCKLINE DETAILS
					IF (@TotalCountsBoth > 0 )
					BEGIN
						UPDATE dbo.WorkOrderMaterialStockLine 
						SET QtyIssued = ISNULL(QtyIssued, 0) - ISNULL(QuantityActUnIssued, 0),
							--QtyReserved = ISNULL(QtyReserved, 0) + ISNULL(QuantityActUnIssued, 0),
							ExtendedCost = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							ExtendedPrice = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							UpdatedDate = GETDATE(),
							UpdatedBy = ReservedBy
						FROM dbo.WorkOrderMaterialStockLine WOMS 
						JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId AND ISNULL(tmpRSL.KitId, 0) = 0
					END

					--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
					UPDATE dbo.WorkOrderMaterialStockLine 
					SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
					FROM dbo.WorkOrderMaterialStockLine WOMS JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId 
					WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) AND ISNULL(tmpRSL.KitId, 0) = 0 


					DECLARE @countStockline INT = 1;

					--FOR FOR UPDATED STOCKLINE QTY
					WHILE @countStockline <= @TotalCountsBoth
					BEGIN
						DECLARE @tmpStockLineId BIGINT;

						SELECT @tmpStockLineId = StockLineId FROM #tmpUnIssueWOMaterialsStockline WHERE ID = @countStockline

						--FOR UPDATED STOCKLINE QTY
						UPDATE dbo.Stockline
						SET QuantityOnHand = ISNULL(SL.QuantityOnHand, 0) + ISNULL(tmpRSL.QuantityActUnIssued,0),
							QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) + ISNULL(tmpRSL.QuantityActUnIssued,0),
							QuantityIssued = ISNULL(SL.QuantityIssued,0) - ISNULL(tmpRSL.QuantityActUnIssued,0),						
							WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
						FROM dbo.Stockline SL JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
						WHERE ISNULL(tmpRSL.KitId, 0) = 0 AND tmpRSL.ID = @countStockline AND Sl.StockLineId = @tmpStockLineId
						
						SET @countStockline = @countStockline + 1;
					END;

					DECLARE @countBoth INT = 1;

					--FOR UPDATE TOTAL WORK ORDER COST
					WHILE @countBoth <= @TotalCountsBoth
					BEGIN
						SELECT	@WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId
						FROM #tmpUnIssueWOMaterialsStockline tmpWOM 
						WHERE tmpWOM.ID = @countBoth

						EXEC [dbo].[USP_UpdateWOMaterialsCost]  @WorkOrderMaterialsId = @WorkOrderMaterialsId
						
						SET @countBoth = @countBoth + 1;
					END;

					--FOR STOCK LINE HISTORY	
					WHILE @slcount <= @TotalCountsBoth
					BEGIN
						SELECT	@StocklineId = tmpWOM.StockLineId,
								@MasterCompanyId = tmpWOM.MasterCompanyId,
								@ReferenceId = tmpWOM.WorkOrderId,
								@SubReferenceId = tmpWOM.WorkOrderMaterialsId,
								@ReferencePartId = tmpWOM.WorkFlowWorkOrderId,
								@UpdateBy = UpdatedBy,
								@IssueQty = QuantityActUnIssued,
								@Amount = UnitCost,
								@ReferencePieceId = tmpWOM.WorkOrderMaterialsId
						FROM #tmpUnIssueWOMaterialsStockline tmpWOM 
						WHERE tmpWOM.ID = @slcount

						SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId
						
						SET @ActionId = 5; -- UnIssue
						EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @IssueQty, @UpdatedBy = @UpdateBy;

						SET @ActionId = 3; -- UnReserve
						EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @IssueQty, @UpdatedBy = @UpdateBy;

						--Added for WO History 
						DECLARE @HistoryWorkOrderMaterialsId BIGINT,@historyModuleId BIGINT,@historySubModuleId BIGINT,
								@historyWorkOrderId BIGINT,@HistoryQtyReserved VARCHAR(MAX),@HistoryQuantityActReserved VARCHAR(MAX),@historyReservedById BIGINT,
								@historyEmployeeName VARCHAR(100),@historyMasterCompanyId BIGINT,@historytotalReserved VARCHAR(MAX),@TemplateBody NVARCHAR(MAX),
								@WorkOrderNum VARCHAR(MAX),@ConditionId BIGINT,@ConditionCode VARCHAR(MAX),@HistoryStockLineId BIGINT,@HistoryStockLineNum VARCHAR(MAX),
								@WorkFlowWorkOrderId BIGINT,@WorkOrderPartNoId BIGINT,@historyQuantity BIGINT,@historyQtyToBeReserved BIGINT, @KITID BIGINT;

						SELECT @historyModuleId = moduleId FROM Module WHERE ModuleName = 'WorkOrder';
						SELECT @historySubModuleId = moduleId FROM Module WHERE ModuleName = 'WorkOrderMPN';
						SELECT @TemplateBody = TemplateBody FROM HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = 'UnReservedParts';
						SELECT @HistoryWorkOrderMaterialsId = WorkOrderMaterialsId,
							   @historyWorkOrderId = WorkOrderId,  @KITID = ISNULL(KitId,0), @UpdateBy = UpdatedBy,
							   @historyMasterCompanyId = MasterCompanyId,@ConditionId = ConditionId,@HistoryStockLineId = StockLineId,
							   @historyQuantity = Quantity,@historyQtyToBeReserved = QtyToBeReserved,
							   @historyPartNumber = PartNumber
						FROM #tmpUnIssueWOMaterialsStockline WHERE ID = @slcount;

						SELECT @WorkFlowWorkOrderId = WorkFlowWorkOrderId FROM WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @HistoryWorkOrderMaterialsId;
						SELECT @WorkOrderPartNoId = WorkOrderPartNoId FROM WorkOrderWorkFlow WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId;

						SELECT @WorkOrderNum = WorkOrderNum FROM WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @historyWorkOrderId;
						SELECT @ConditionCode = Code FROM Condition WITH(NOLOCK) WHERE ConditionId = @ConditionId;
						SELECT @HistoryStockLineNum = StockLineNumber FROM Stockline WITH(NOLOCK) WHERE StockLineId = @HistoryStockLineId;

						SET @TemplateBody = REPLACE(@TemplateBody, '##PN##', ISNULL(@historyPartNumber,''));
						SET @TemplateBody = REPLACE(@TemplateBody, '##Quantity##', ISNULL(@historyQuantity,''));
						
						SELECT @historyEmployeeName = (FirstName +' '+ LastName) FROM Employee WITH(NOLOCK) WHERE EmployeeId = @historyReservedById;
						SELECT @HistoryQtyReserved = CAST(QuantityReserved AS VARCHAR) FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK) JOIN #tmpUnIssueWOMaterialsStockline tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.ID = @count;
						SELECT @HistoryWorkOrderMaterialsId = WorkOrderPartNoId FROM WorkOrderWorkFlow WITH(NOLOCK);
						
						IF @KITID = 0
						BEGIN
							EXEC [dbo].[USP_History] @historyModuleId,@historyWorkOrderId,@historySubModuleId,@WorkOrderPartNoId,@historyQuantity,@historyQtyToBeReserved,@TemplateBody,'UnReservedParts',@historyMasterCompanyId,@UpdateBy,NULL,@UpdateBy,NULL;
						END

						-- batch trigger unissue qty
						IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
						BEGIN
							EXEC [dbo].[USP_BatchTriggerBasedonDistribution] 
							@DistributionMasterId,@ReferenceId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdateBy
						END

						SET @slcount = @slcount + 1;
					END;

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
              , @AdhocComments     VARCHAR(150)    = 'usp_UnReserveAndUnIssueWorkOrderMaterialsStockline' 
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
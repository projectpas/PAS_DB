﻿/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <12/30/2021>  
** Description: <Save Work Order Materials Un Reserve Stockline Details>  
  
EXEC [usp_UnReserveWorkOrderMaterialsStockline] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    12/30/2021  HEMANT SALIYA    Save Work Order Materials Un Reserve Stockline Details
** 2    07/19/2023	Devendra Shekh    declare new param @KITID and added new if for exec wohistory
** 3    08/18/2023	AMIT GHEDIYA     Update historytext for wohistory.

declare @p1 dbo.ReserveWOMaterialsStocklineType
insert into @p1 values(830,835,122,70530,121,7,1,1,2,N'NEW',N'11022022',N'11022022_DESC',2,0,0,0,2,0,N'CNTL-000556',N'ID_NUM-000001',N'STL-000017',N'552233',N'ADMIN User',1,17)
insert into @p1 values(830,835,121,74937,20343,7,1,1,2,N'NEW',N'0856AE15',N'0856AE15',5,0,0,0,5,0,N'CNTL-000765',N'ID_NUM-000001',N'STL-000012',N'',N'ADMIN User',1,17)

exec dbo.usp_UnReserveWorkOrderMaterialsStockline @tbl_MaterialsStocklineType=@p1
**************************************************************/ 
CREATE       PROCEDURE [dbo].[usp_UnReserveWorkOrderMaterialsStockline]
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
					DECLARE @mcount INT;
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
					DECLARE @IsKit BIGINT = 0;
					DECLARE @historyPartNumber VARCHAR(150);

					SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 15; -- For WORK ORDER Module
					SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 33; -- For WORK ORDER Materials Module
					SET @PartStatus = 2; -- FOR Issue
					SET @IsAddUpdate = 0;
					SET @ExecuteParentChild = 1;
					SET @UpdateQuantities = 1;
					SET @IsOHUpdated = 0;
					SET @AddHistoryForNonSerialized = 0;					
					SET @slcount = 1;
					SET @count = 1;
					SET @countKIT = 1;
					SET @mcount = 1;
					DECLARE @UpdateBy varchar(200);
					DECLARE @Qty bigint = 0;
					DECLARE @ActionId INT = 0;

					IF OBJECT_ID(N'tempdb..#tmpUnReserveWOMaterialsStockline') IS NOT NULL
					BEGIN
					DROP TABLE #tmpUnReserveWOMaterialsStockline
					END
			
					CREATE TABLE #tmpUnReserveWOMaterialsStockline
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
						[QuantityActUnReserved] INT NULL,
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

					INSERT INTO #tmpUnReserveWOMaterialsStockline ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
							[TaskId], [Condition], [PartNumber], [PartDescription], [Quantity], [QtyToBeReserved], [QuantityActUnReserved], [ControlNo], [ControlId],
							[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UpdatedById],  [UnitCost], [IsSerialized], [KitId])
					SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], tblMS.[StockLineId], tblMS.[ItemMasterId], tblMS.[ConditionId], [ProvisionId], 
							[TaskId], tblMS.[Condition], tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], [QtyToBeReserved], [QuantityActUnReserved], [ControlNo], [ControlId],
							tblMS.[StockLineNumber], tblMS.[SerialNumber], [ReservedBy], [IsStocklineAdded], SL.MasterCompanyId, [ReservedBy], [ReservedById], SL.UnitCost, SL.isSerialized, tblMS.[KitId]
					FROM @tbl_MaterialsStocklineType tblMS  JOIN dbo.Stockline SL ON SL.StockLineId = tblMS.StockLineId 
					WHERE SL.QuantityReserved > 0 AND SL.QuantityReserved >= tblMS.QuantityActUnReserved

					SELECT @TotalCounts = COUNT(ID) FROM #tmpUnReserveWOMaterialsStockline WHERE ISNULL(KitId, 0) = 0;
					SELECT @TotalCountsKIT = COUNT(ID) FROM #tmpUnReserveWOMaterialsStockline WHERE ISNULL(KitId, 0) > 0;
					SELECT @TotalCountsBoth = COUNT(ID) FROM #tmpUnReserveWOMaterialsStockline;
					
					INSERT INTO #tmpIgnoredStockline ([PartNumber], [Condition], [ControlNo], [ControlId], [StockLineNumber]) 
					SELECT tblMS.[PartNumber], tblMS.[Condition], tblMS.[ControlNo], tblMS.[ControlId], tblMS.[StockLineNumber] FROM @tbl_MaterialsStocklineType tblMS  
					WHERE tblMS.StockLineId NOT IN (SELECT StockLineId FROM #tmpUnReserveWOMaterialsStockline)
		
					--UPDATE WORK ORDER MATERIALS DETAILS
					WHILE @countKIT <= @TotalCountsBoth
					BEGIN
						UPDATE WorkOrderMaterialsKit 
							SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) - ISNULL(tmpWOM.QuantityActUnReserved,0),								
								TotalReserved = ISNULL(WOM.TotalReserved,0) - ISNULL(tmpWOM.QuantityActUnReserved,0),
								IssuedById = tmpWOM.UpdatedById, 
								IssuedDate = GETDATE(), 
								UpdatedDate = GETDATE(),
								PartStatusId = @PartStatus
						FROM dbo.WorkOrderMaterialsKit WOM JOIN #tmpUnReserveWOMaterialsStockline tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND tmpWOM.ID = @countKIT AND ISNULL(tmpWOM.KitId, 0) > 0
						SET @countKIT = @countKIT + 1;
					END;

					--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
					IF (@TotalCountsKIT > 0 )
					BEGIN						
						UPDATE dbo.WorkOrderMaterialStockLineKit 
						SET QtyReserved = ISNULL(QtyReserved, 0) - ISNULL(QuantityActUnReserved, 0),
							ExtendedCost = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							ExtendedPrice = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							UpdatedDate = GETDATE(),
							UpdatedBy = ReservedBy
						FROM dbo.WorkOrderMaterialStockLineKit WOMS JOIN #tmpUnReserveWOMaterialsStockline tmpRSL ON WOMS.WorkOrderMaterialsKitId = tmpRSL.WorkOrderMaterialsId 
						WHERE WOMS.StockLineId = tmpRSL.StockLineId AND ISNULL(tmpRSL.KitId, 0) > 0
					END

					--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
					UPDATE dbo.WorkOrderMaterialStockLineKit 
					SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
					FROM dbo.WorkOrderMaterialStockLineKit WOMS JOIN #tmpUnReserveWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsKitId = tmpRSL.WorkOrderMaterialsId 
					WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) AND ISNULL(tmpRSL.KitId, 0) > 0

					--FOR UPDATED STOCKLINE QTY
					UPDATE dbo.Stockline
					SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) + ISNULL(tmpRSL.QuantityActUnReserved,0),
						QuantityReserved = ISNULL(SL.QuantityReserved,0) - ISNULL(tmpRSL.QuantityActUnReserved,0),                        
						WorkOrderMaterialsKitId = tmpRSL.WorkOrderMaterialsId
					FROM dbo.Stockline SL JOIN #tmpUnReserveWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
					WHERE ISNULL(tmpRSL.KitId, 0) > 0

					--UPDATE WORK ORDER MATERIALS DETAILS
					WHILE @mcount <= @TotalCountsBoth
					BEGIN
						
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
							   @historyQuantity = QtyToBeReserved,@historyQtyToBeReserved = QuantityActUnReserved,@historyPartNumber = PartNumber
						FROM #tmpUnReserveWOMaterialsStockline WHERE ID = @mcount;

						SELECT @WorkFlowWorkOrderId = WorkFlowWorkOrderId FROM WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @HistoryWorkOrderMaterialsId;
						SELECT @WorkOrderPartNoId = WorkOrderPartNoId FROM WorkOrderWorkFlow WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId;

						SELECT @WorkOrderNum = WorkOrderNum FROM WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @historyWorkOrderId;
						SELECT @ConditionCode = Code FROM Condition WITH(NOLOCK) WHERE ConditionId = @ConditionId;
						SELECT @HistoryStockLineNum = StockLineNumber FROM Stockline WITH(NOLOCK) WHERE StockLineId = @HistoryStockLineId;

						SET @TemplateBody = REPLACE(@TemplateBody, '##PN##', ISNULL(@historyPartNumber,''));
						SET @TemplateBody = REPLACE(@TemplateBody, '##Quantity##', ISNULL(@historyQtyToBeReserved,''));
						
						SELECT @historyEmployeeName = (FirstName +' '+ LastName) FROM Employee WITH(NOLOCK) WHERE EmployeeId = @historyReservedById;
						SELECT @HistoryQtyReserved = CAST(QuantityReserved AS VARCHAR) FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK) JOIN #tmpUnReserveWOMaterialsStockline tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.ID = @count;
						SELECT @HistoryWorkOrderMaterialsId = WorkOrderPartNoId FROM WorkOrderWorkFlow WITH(NOLOCK);
						
						--SET @historytotalReserved = (CAST(@HistoryQtyReserved AS BIGINT) + CAST(@HistoryQuantityActReserved AS BIGINT));
						IF @KITID = 0
						BEGIN
							EXEC [dbo].[USP_History] @historyModuleId,@historyWorkOrderId,@historySubModuleId,@WorkOrderPartNoId,@historyQtyToBeReserved,@historyQuantity,@TemplateBody,'UnReservedParts',@historyMasterCompanyId,@UpdateBy,NULL,@UpdateBy,NULL;
						END
						--EXEC [dbo].[USP_History] @historyModuleId,@historyWorkOrderId,@historySubModuleId,@WorkOrderPartNoId,@historyQuantity,@historyQtyToBeReserved,@TemplateBody,'UnReservedParts',@historyMasterCompanyId,@UpdateBy,NULL,@UpdateBy,NULL;

						UPDATE WorkOrderMaterials 
							SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) - ISNULL(tmpWOM.QuantityActUnReserved,0),								
								TotalReserved = ISNULL(WOM.TotalReserved,0) - ISNULL(tmpWOM.QuantityActUnReserved,0),
								IssuedById = tmpWOM.UpdatedById, 
								IssuedDate = GETDATE(), 
								UpdatedDate = GETDATE(),
								PartStatusId = @PartStatus
						FROM dbo.WorkOrderMaterials WOM JOIN #tmpUnReserveWOMaterialsStockline tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.ID = @mcount AND ISNULL(tmpWOM.KitId, 0) = 0
						SET @mcount = @mcount + 1;
					END;

					--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
					IF (@TotalCounts > 0 )
					BEGIN						
						UPDATE dbo.WorkOrderMaterialStockLine 
						SET QtyReserved = ISNULL(QtyReserved, 0) - ISNULL(QuantityActUnReserved, 0),
							ExtendedCost = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							ExtendedPrice = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							UpdatedDate = GETDATE(),
							UpdatedBy = ReservedBy
						FROM dbo.WorkOrderMaterialStockLine WOMS JOIN #tmpUnReserveWOMaterialsStockline tmpRSL ON WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId 
						WHERE WOMS.StockLineId = tmpRSL.StockLineId AND ISNULL(tmpRSL.KitId, 0) = 0
						
					END

					--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
					UPDATE dbo.WorkOrderMaterialStockLine 
					SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
					FROM dbo.WorkOrderMaterialStockLine WOMS JOIN #tmpUnReserveWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId 
					WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) AND ISNULL(tmpRSL.KitId, 0) = 0

					--FOR UPDATED STOCKLINE QTY
					UPDATE dbo.Stockline
					SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) + ISNULL(tmpRSL.QuantityActUnReserved,0),
						QuantityReserved = ISNULL(SL.QuantityReserved,0) - ISNULL(tmpRSL.QuantityActUnReserved,0),                        
						WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
					FROM dbo.Stockline SL JOIN #tmpUnReserveWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
					WHERE ISNULL(tmpRSL.KitId, 0) = 0

					DECLARE @countBoth INT = 1;

					--FOR UPDATE TOTAL WORK ORDER COST
					WHILE @countBoth <= @TotalCountsBoth
					BEGIN
						SELECT	@WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId
						FROM #tmpUnReserveWOMaterialsStockline tmpWOM 
						WHERE tmpWOM.ID = @countBoth

						EXEC [dbo].[USP_UpdateWOMaterialsCost]  @WorkOrderMaterialsId = @WorkOrderMaterialsId
						
						SET @countBoth = @countBoth + 1;
					END;

					--FOR STOCK LINE HISTORY	
					WHILE @slcount<= @TotalCountsBoth
					BEGIN
						SELECT	@StocklineId = tmpWOM.StockLineId,
								@MasterCompanyId = tmpWOM.MasterCompanyId,
								@ReferenceId = tmpWOM.WorkOrderId,
								@SubReferenceId = tmpWOM.WorkOrderMaterialsId,
								@UpdateBy = UpdatedBy,
								@Qty = QuantityActUnReserved
						FROM #tmpUnReserveWOMaterialsStockline tmpWOM 
						WHERE tmpWOM.ID = @slcount

						SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId

						--IF (@IsSerialised = 0 AND (@stockLineQtyAvailable > 1 OR @stockLineQty > 1))
						--BEGIN
						--	EXEC [dbo].[USP_CreateChildStockline]  @StocklineId = @StocklineId, @MasterCompanyId = @MasterCompanyId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @IsAddUpdate = @IsAddUpdate, @ExecuteParentChild = @ExecuteParentChild, @UpdateQuantities = @UpdateQuantities, @IsOHUpdated = @IsOHUpdated, @AddHistoryForNonSerialized = @AddHistoryForNonSerialized, @SubModuleId = @SubModuleId, @SubReferenceId = @SubReferenceId
						--END
						--ELSE
						--BEGIN
						--	EXEC [dbo].[USP_CreateChildStockline]  @StocklineId = @StocklineId, @MasterCompanyId = @MasterCompanyId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @IsAddUpdate = 0, @ExecuteParentChild = 0, @UpdateQuantities = 0, @IsOHUpdated = 1, @AddHistoryForNonSerialized = 0, @SubModuleId = @SubModuleId, @SubReferenceId = @SubReferenceId
						--END

						SET @ActionId = 3; -- UnReserve
						EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @Qty, @UpdatedBy = @UpdateBy;

						SET @slcount = @slcount + 1;
					END;

					SELECT * FROM #tmpIgnoredStockline

					IF OBJECT_ID(N'tempdb..#tmpIgnoredStockline') IS NOT NULL
					BEGIN
					DROP TABLE #tmpIgnoredStockline
					END

					IF OBJECT_ID(N'tempdb..#tmpUnReserveWOMaterialsStockline') IS NOT NULL
					BEGIN
					DROP TABLE #tmpUnReserveWOMaterialsStockline
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
              , @AdhocComments     VARCHAR(150)    = 'usp_UnReserveWorkOrderMaterialsStockline' 
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
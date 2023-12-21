/*************************************************************   
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
** 2    07/19/2023  VISHAL SUTHAR    Added new stockline history for SWO
** 3    07/19/2023  HEMANT SALIYA    Added KIT PART for SWO

DECLARE @p1 dbo.SubWOMaterialsStocklineType

INSERT INTO @p1 values(65,72,87,1073,4,6,1,14,6,N'REPAIR',N'FLYSKY CT6B FS-CT6B',N'USED FOR WING REPAIR',5,3,1,N'CNTL-000463',N'ID_NUM-000001',N'STL-000123',N'',N'ADMIN ADMIN',1)
INSERT INTO @p1 values(65,72,99,2093,25,6,1,14,6,N'REPAIR',N'WAT0303-01',N'70303-01 RECOGNITION LIGHT 28V 25W',3,3,2,N'CNTL-000526',N'ID_NUM-000001',N'STL-000009',N'',N'ADMIN ADMIN',1)
INSERT INTO @p1 values(65,72,10099,510,15,34,2,14,6,N'INSPECTED',N'AIR-MAZE',N'AIR-MAZE U2-849 AERONCA AIR FILTER',10,7,1,N'CNTL-000308',N'ID_NUM-000001',N'STL-000072',N'',N'ADMIN ADMIN',1)
INSERT INTO @p1 values(65,72,10099,512,15,34,2,14,6,N'INSPECTED',N'AIR-MAZE',N'AIR-MAZE U2-849 AERONCA AIR FILTER',10,7,1,N'CNTL-000310',N'ID_NUM-000001',N'STL-000072',N'',N'ADMIN ADMIN',0)
INSERT INTO @p1 values(65,72,10099,513,15,34,2,14,6,N'INSPECTED',N'AIR-MAZE',N'AIR-MAZE U2-849 AERONCA AIR FILTER',10,7,1,N'CNTL-000311',N'ID_NUM-000001',N'STL-000072',N'',N'ADMIN ADMIN',0)

EXEC dbo.usp_UnReserveWorkOrderMaterialsStockline @tbl_MaterialsStocklineType=@p1

declare @p1 dbo.SubWOMaterialsStocklineType
insert into @p1 values(123,33,33,38,2577,27,5,1,14,31,N'OVERHAUL',N'UAVIONIX',N'UAVIONIX AV-30-C PRIMARY FLIGHT DISPLAY - CERTIFIED',10,0,0,0,1,0,N'CNTL-000557',N'ID_NUM-000001',N'STL-000001',N'',N'hemant saliya',1)

exec dbo.usp_UnReserveSubWorkOrderMaterialsStockline @tbl_MaterialsStocklineType=@p1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_UnReserveSubWorkOrderMaterialsStockline]
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
					DECLARE @SubWorkOrderMaterialsId BIGINT;
					DECLARE @IsSerialised BIT;
					DECLARE @stockLineQty INT;
					DECLARE @stockLineQtyAvailable INT;
					DECLARE @UpdateBy varchar(200);
					DECLARE @UnReservedQty bigint = 0;
					DECLARE @IsKit BIGINT = 0;
					DECLARE @historyPartNumber VARCHAR(150);

					SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 16; -- For SUB WORK ORDER Module
					SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'SubWorkOrderMaterials'; -- For WORK ORDER Materials Module
					SET @PartStatus = 2; -- FOR Issue
					SET @IsAddUpdate = 0;
					SET @ExecuteParentChild = 1;
					SET @UpdateQuantities = 1;
					SET @IsOHUpdated = 0;
					SET @AddHistoryForNonSerialized = 0;					
					SET @slcount = 1;
					SET @count = 1;
					SET @mcount = 1;

					IF OBJECT_ID(N'tempdb..#tmpUnReserveSWOMaterialsStockline') IS NOT NULL
					BEGIN
					DROP TABLE #tmpUnReserveSWOMaterialsStockline
					END
			
					CREATE TABLE #tmpUnReserveSWOMaterialsStockline
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

					INSERT INTO #tmpUnReserveSWOMaterialsStockline ([WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
						[TaskId], [Condition], [PartNumber], [PartDescription], [Quantity], [QtyToBeReserved], [QuantityActUnReserved], [ControlNo], [ControlId],
						[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UpdatedById],  [UnitCost], [IsSerialized] ,[KitId])
					SELECT tblMS.[WorkOrderId],tblMS.[SubWorkOrderId], tblMS.[SubWOPartNoId], tblMS.[SubWorkOrderMaterialsId], tblMS.[StockLineId], tblMS.[ItemMasterId], tblMS.[ConditionId], [ProvisionId], 
						[TaskId], tblMS.[Condition], tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], [QtyToBeReserved], [QuantityActUnReserved], [ControlNo], [ControlId],
						tblMS.[StockLineNumber], tblMS.[SerialNumber], [ReservedBy], [IsStocklineAdded], SL.MasterCompanyId, [ReservedBy], [ReservedById], SL.UnitCost, SL.isSerialized, tblMS.[KitId]
					FROM @tbl_MaterialsStocklineType tblMS  JOIN dbo.Stockline SL ON SL.StockLineId = tblMS.StockLineId 
					WHERE SL.QuantityReserved > 0 AND SL.QuantityReserved >= tblMS.QuantityActUnReserved

					SELECT @TotalCounts = COUNT(ID) FROM #tmpUnReserveSWOMaterialsStockline WHERE ISNULL(KitId, 0) = 0;
					SELECT @TotalCountsKIT = COUNT(ID) FROM #tmpUnReserveSWOMaterialsStockline WHERE ISNULL(KitId, 0) > 0;
					SELECT @TotalCountsBoth = COUNT(ID) FROM #tmpUnReserveSWOMaterialsStockline;

					INSERT INTO #tmpIgnoredStockline ([PartNumber], [Condition], [ControlNo], [ControlId], [StockLineNumber]) 
					SELECT tblMS.[PartNumber], tblMS.[Condition], tblMS.[ControlNo], tblMS.[ControlId], tblMS.[StockLineNumber] FROM @tbl_MaterialsStocklineType tblMS  
					WHERE tblMS.StockLineId NOT IN (SELECT StockLineId FROM #tmpUnReserveSWOMaterialsStockline)

					--UPDATE SUB WORK ORDER MATERIALS KIT DETAILS
					WHILE @countKIT <= @TotalCountsBoth
					BEGIN
						UPDATE SubWorkOrderMaterialsKit 
							SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) - ISNULL(tmpWOM.QuantityActUnReserved,0),								
								TotalReserved = ISNULL(WOM.TotalReserved,0) - ISNULL(tmpWOM.QuantityActUnReserved,0),
								IssuedById = tmpWOM.UpdatedById, 
								IssuedDate = GETDATE(), 
								UpdatedDate = GETDATE(),
								PartStatusId = @PartStatus
						FROM dbo.SubWorkOrderMaterialsKit WOM JOIN #tmpUnReserveSWOMaterialsStockline tmpWOM ON tmpWOM.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId AND tmpWOM.ID = @countKIT AND ISNULL(tmpWOM.KitId, 0) > 0
						SET @countKIT = @countKIT + 1;
					END;

					--UPDATE/INSERT SUB WORK ORDER MATERIALS KIT STOCKLINE DETAILS
					IF (@TotalCountsKIT > 0 )
					BEGIN						
						UPDATE dbo.SubWorkOrderMaterialStockLineKit 
						SET QtyReserved = ISNULL(QtyReserved, 0) - ISNULL(QuantityActUnReserved, 0),
							ExtendedCost = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							ExtendedPrice = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							UpdatedDate = GETDATE(),
							UpdatedBy = ReservedBy
						FROM dbo.SubWorkOrderMaterialStockLineKit WOMS JOIN #tmpUnReserveSWOMaterialsStockline tmpRSL ON WOMS.SubWorkOrderMaterialsKitId = tmpRSL.SubWorkOrderMaterialsId 
						WHERE WOMS.StockLineId = tmpRSL.StockLineId AND ISNULL(tmpRSL.KitId, 0) > 0
					END

					--FOR UPDATED SUB WORKORDER MATERIALS kIT STOCKLINE QTY
					UPDATE dbo.SubWorkOrderMaterialStockLineKit 
					SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
					FROM dbo.SubWorkOrderMaterialStockLineKit WOMS JOIN #tmpUnReserveSWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.SubWorkOrderMaterialsKitId = tmpRSL.SubWorkOrderMaterialsId 
					WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) AND ISNULL(tmpRSL.KitId, 0) > 0

					--FOR UPDATED STOCKLINE QTY
					UPDATE dbo.Stockline
					SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) + ISNULL(tmpRSL.QuantityActUnReserved,0),
						QuantityReserved = ISNULL(SL.QuantityReserved,0) - ISNULL(tmpRSL.QuantityActUnReserved,0),                        
						SubWorkOrderMaterialsKitId = tmpRSL.SubWorkOrderMaterialsId
					FROM dbo.Stockline SL JOIN #tmpUnReserveSWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
					WHERE ISNULL(tmpRSL.KitId, 0) > 0
		
					--UPDATE WORK ORDER MATERIALS DETAILS
					WHILE @mcount <= @TotalCountsBoth
					BEGIN
						
						--Added for WO History 
						DECLARE @HistorySubWorkOrderMaterialsId BIGINT,@historyModuleId BIGINT,@historySubModuleId BIGINT,
								@historySubWorkOrderId BIGINT,@HistoryQtyReserved VARCHAR(MAX),@HistoryQuantityActReserved VARCHAR(MAX),@historyReservedById BIGINT,
								@historyEmployeeName VARCHAR(100),@historyMasterCompanyId BIGINT,@historytotalReserved VARCHAR(MAX),@TemplateBody NVARCHAR(MAX),
								@SubWorkOrderNum VARCHAR(MAX),@ConditionId BIGINT,@ConditionCode VARCHAR(MAX),@HistoryStockLineId BIGINT,@HistoryStockLineNum VARCHAR(MAX),
								@WorkFlowWorkOrderId BIGINT,@SubWorkOrderPartNoId BIGINT,@historyQuantity BIGINT,@historyQtyToBeReserved BIGINT, @KITID BIGINT;

						SELECT @historyModuleId = moduleId FROM Module WHERE ModuleName = 'SubWorkOrder';
						SELECT @historySubModuleId = moduleId FROM Module WHERE ModuleName = 'SubWorkOrderMPN';
						SELECT @TemplateBody = TemplateBody FROM HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = 'UnReservedParts';
						SELECT @HistorySubWorkOrderMaterialsId = SubWorkOrderMaterialsId,
							   @historySubWorkOrderId = SubWorkOrderId,  @KITID = ISNULL(KitId,0), @UpdateBy = UpdatedBy,
							   @historyMasterCompanyId = MasterCompanyId,@ConditionId = ConditionId,@HistoryStockLineId = StockLineId,
							   @historyQuantity = QtyToBeReserved,@historyQtyToBeReserved = QuantityActUnReserved,@historyPartNumber = PartNumber
						FROM #tmpUnReserveSWOMaterialsStockline WHERE ID = @mcount;

						SELECT @SubWorkOrderPartNoId = SubWOPartNoId FROM SubWorkOrderMaterials WITH(NOLOCK) WHERE SubWorkOrderMaterialsId = @HistorySubWorkOrderMaterialsId;

						SELECT @SubWorkOrderNum = SubWorkOrderNo FROM SubWorkOrder WITH(NOLOCK) WHERE WorkOrderId = @historySubWorkOrderId;
						SELECT @ConditionCode = Code FROM Condition WITH(NOLOCK) WHERE ConditionId = @ConditionId;
						SELECT @HistoryStockLineNum = StockLineNumber FROM Stockline WITH(NOLOCK) WHERE StockLineId = @HistoryStockLineId;

						SET @TemplateBody = REPLACE(@TemplateBody, '##PN##', ISNULL(@historyPartNumber,''));
						SET @TemplateBody = REPLACE(@TemplateBody, '##Quantity##', ISNULL(@historyQtyToBeReserved,''));
						
						SELECT @historyEmployeeName = (FirstName +' '+ LastName) FROM Employee WITH(NOLOCK) WHERE EmployeeId = @historyReservedById;
						SELECT @HistoryQtyReserved = CAST(QuantityReserved AS VARCHAR) FROM dbo.SubWorkOrderMaterials WOM WITH(NOLOCK) JOIN #tmpUnReserveSWOMaterialsStockline tmpWOM ON tmpWOM.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND tmpWOM.ID = @count;
						
						IF @KITID = 0
						BEGIN
							EXEC [dbo].[USP_History] @historyModuleId,@historySUbWorkOrderId,@historySubModuleId,@SubWorkOrderPartNoId,@historyQtyToBeReserved,@historyQuantity,@TemplateBody,'UnReservedParts',@historyMasterCompanyId,@UpdateBy,NULL,@UpdateBy,NULL;
						END

						UPDATE SubWorkOrderMaterials 
							SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) - ISNULL(tmpWOM.QuantityActUnReserved,0),								
								TotalReserved = ISNULL(WOM.TotalReserved,0) - ISNULL(tmpWOM.QuantityActUnReserved,0),
								IssuedById = tmpWOM.UpdatedById, 
								IssuedDate = GETDATE(), 
								UpdatedDate = GETDATE(),
								PartStatusId = @PartStatus
						FROM dbo.SubWorkOrderMaterials WOM JOIN #tmpUnReserveSWOMaterialsStockline tmpWOM ON tmpWOM.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND tmpWOM.ID = @mcount AND ISNULL(tmpWOM.KitId, 0) = 0
						SET @mcount = @mcount + 1;
					END;


					--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
					IF(@TotalCounts > 0 )
					BEGIN						
						UPDATE dbo.SubWorkOrderMaterialStockLine 
						SET QtyReserved = ISNULL(QtyReserved, 0) - ISNULL(QuantityActUnReserved, 0),
							ExtendedCost = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							ExtendedPrice = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							UpdatedDate = GETDATE(),
							UpdatedBy = ReservedBy
						FROM dbo.SubWorkOrderMaterialStockLine WOMS JOIN #tmpUnReserveSWOMaterialsStockline tmpRSL ON WOMS.SubWorkOrderMaterialsId = tmpRSL.SubWorkOrderMaterialsId 
						WHERE WOMS.StockLineId = tmpRSL.StockLineId AND ISNULL(tmpRSL.KitId, 0) = 0
						
					END

					--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
					UPDATE dbo.SubWorkOrderMaterialStockLine 
					SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
					FROM dbo.SubWorkOrderMaterialStockLine WOMS JOIN #tmpUnReserveSWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.SubWorkOrderMaterialsId = tmpRSL.SubWorkOrderMaterialsId 
					WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) AND ISNULL(tmpRSL.KitId, 0) = 0
					
					--FOR UPDATED STOCKLINE QTY
					UPDATE dbo.Stockline
					SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) + ISNULL(tmpRSL.QuantityActUnReserved,0),
						QuantityReserved = ISNULL(SL.QuantityReserved,0) - ISNULL(tmpRSL.QuantityActUnReserved,0)
					FROM dbo.Stockline SL JOIN #tmpUnReserveSWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
					WHERE ISNULL(tmpRSL.KitId, 0) = 0

					DECLARE @countBoth INT = 1;

					--FOR UPDATE TOTAL WORK ORDER COST
					WHILE @countBoth <= @TotalCounts
					BEGIN
						SELECT	@SubWorkOrderMaterialsId = tmpWOM.SubWorkOrderMaterialsId
						FROM #tmpUnReserveSWOMaterialsStockline tmpWOM 
						WHERE tmpWOM.ID = @count

						EXEC [dbo].[USP_UpdateSubWOMaterialsCost]  @SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId
						
						SET @countBoth = @countBoth + 1;
					END;

					--FOR STOCK LINE HISTORY	
					WHILE @slcount<= @TotalCountsBoth
					BEGIN
						SELECT	@StocklineId = tmpWOM.StockLineId,
								@MasterCompanyId = tmpWOM.MasterCompanyId,
								@ReferenceId = tmpWOM.SubWorkOrderId,
								@SubReferenceId = tmpWOM.SubWorkOrderMaterialsId,
								@UpdateBy = UpdatedBy,
								@UnReservedQty = QuantityActUnReserved
						FROM #tmpUnReserveSWOMaterialsStockline tmpWOM 
						WHERE tmpWOM.ID = @slcount

						SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId
						
						DECLARE @ActionId INT;
						SET @ActionId = 3; -- Un-Reserve
						EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @UnReservedQty, @UpdatedBy = @UpdateBy;

						SET @slcount = @slcount + 1;
					END;

					SELECT * FROM #tmpIgnoredStockline

					IF OBJECT_ID(N'tempdb..#tmpIgnoredStockline') IS NOT NULL
					BEGIN
					DROP TABLE #tmpIgnoredStockline
					END

					IF OBJECT_ID(N'tempdb..#tmpUnReserveSWOMaterialsStockline') IS NOT NULL
					BEGIN
					DROP TABLE #tmpUnReserveSWOMaterialsStockline
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
              , @AdhocComments     VARCHAR(150)    = 'usp_UnReserveSubWorkOrderMaterialsStockline' 
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
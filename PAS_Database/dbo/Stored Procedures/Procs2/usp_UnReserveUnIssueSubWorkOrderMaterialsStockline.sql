/*************************************************************   
** Author:  <Vishal Suthar>  
** Create date: <08/08/2023>  
** Description: <Save Sub Work Order Materials Un-Reserve & Un-Issue Stockline Details>
  
EXEC [usp_UnIssueSubWorkOrderMaterialsStockline] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------			--------------------------------
** 1    08/08/2023  Vishal Suthar   Created
** 2    08/08/2023  Hemant Saliya   Added KIT Part for Sub WO
** 3    06/27/2024  HEMANT SALIYA    Update Stockline Qty Issue fox for MTI(Same Stk with multiple Lines)

**************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_UnReserveUnIssueSubWorkOrderMaterialsStockline]
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
					DECLARE @IssueQty bigint = 0;

					DECLARE @DistributionMasterId BIGINT;
					DECLARE @ReferencePartId BIGINT;
                    DECLARE @ReferencePieceId BIGINT;
                    DECLARE @InvoiceId BIGINT = 0;
                    DECLARE @laborType VARCHAR(200) = 'lab';
                    DECLARE @issued BIT = 0;
					DECLARE @Amount DECIMAL(18,2);
                    DECLARE @ModuleName VARCHAR(200) = 'WOP-PartsIssued';

					SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 16; -- For SUB WORK ORDER Module
					SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'SubWorkOrderMaterials'; -- For WORK ORDER Materials Module
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

					INSERT INTO #tmpUnIssueWOMaterialsStockline ([WorkOrderId],[SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
						[TaskId], [Condition], [PartNumber], [PartDescription], [Quantity], [QtyToBeReserved], [QuantityActUnIssued], [ControlNo], [ControlId],
						[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UpdatedById],  [UnitCost], [IsSerialized], [KitId])
					SELECT tblMS.[WorkOrderId],tblMS.[SubWorkOrderId],tblMS.[SubWOPartNoId], tblMS.[SubWorkOrderMaterialsId], tblMS.[StockLineId], tblMS.[ItemMasterId], tblMS.[ConditionId], [ProvisionId], 
						[TaskId], tblMS.[Condition], tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], [QtyToBeReserved], [QuantityActUnIssued], [ControlNo], [ControlId],
						tblMS.[StockLineNumber], tblMS.[SerialNumber], [ReservedBy], [IsStocklineAdded], SL.MasterCompanyId, [ReservedBy], [ReservedById], SL.UnitCost, SL.isSerialized, tblMS.[KitId]
					FROM @tbl_MaterialsStocklineType tblMS  JOIN dbo.Stockline SL ON SL.StockLineId = tblMS.StockLineId 
					WHERE SL.QuantityIssued > 0 AND SL.QuantityIssued >= tblMS.QuantityActUnIssued;

					SELECT @TotalCounts = COUNT(ID) FROM #tmpUnIssueWOMaterialsStockline WHERE ISNULL(KitId, 0) = 0;
					SELECT @TotalCountsKIT = COUNT(ID) FROM #tmpUnIssueWOMaterialsStockline WHERE ISNULL(KitId, 0) > 0;
					SELECT @TotalCountsBoth = COUNT(ID) FROM #tmpUnIssueWOMaterialsStockline;

					INSERT INTO #tmpIgnoredStockline ([PartNumber], [Condition], [ControlNo], [ControlId], [StockLineNumber]) 
					SELECT tblMS.[PartNumber], tblMS.[Condition], tblMS.[ControlNo], tblMS.[ControlId], tblMS.[StockLineNumber] FROM @tbl_MaterialsStocklineType tblMS  
					WHERE tblMS.StockLineId NOT IN (SELECT StockLineId FROM #tmpUnIssueWOMaterialsStockline)

					--UPDATE SUB WORK ORDER MATERIALS KIT DETAILS
					WHILE @countKIT <= @TotalCountsBoth
					BEGIN
						UPDATE SubWorkOrderMaterialsKit 
							SET QuantityIssued = ISNULL(WOM.QuantityIssued,0) - ISNULL(tmpWOM.QuantityActUnIssued,0),
								TotalIssued = ISNULL(WOM.TotalIssued,0) - ISNULL(tmpWOM.QuantityActUnIssued,0),
								IssuedById = tmpWOM.UpdatedById, 
								IssuedDate = GETDATE(), 
								UpdatedDate = GETDATE(),
								PartStatusId = @PartStatus
						FROM dbo.SubWorkOrderMaterialsKit WOM JOIN #tmpUnIssueWOMaterialsStockline tmpWOM ON tmpWOM.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId AND tmpWOM.ID = @countKIT 
						WHERE ISNULL(tmpWOM.KitId, 0) > 0;

						SET @countKIT = @countKIT + 1;
					END;

					--UPDATE SUB WORK ORDER MATERIALS STOCKLINE KIT DETAILS
					IF (@TotalCountsBoth > 0)
					BEGIN
						UPDATE dbo.SubWorkOrderMaterialStockLineKit 
						SET QtyIssued = ISNULL(QtyIssued, 0) - ISNULL(QuantityActUnIssued, 0),
							ExtendedCost = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							ExtendedPrice = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							UpdatedDate = GETDATE(),
							UpdatedBy = ReservedBy
						FROM dbo.SubWorkOrderMaterialStockLineKit WOMS 
						JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.SubWorkOrderMaterialsKitId = tmpRSL.SubWorkOrderMaterialsId 
						WHERE ISNULL(tmpRSL.KitId, 0) > 0;
					END

					--FOR UPDATED SUB WORKORDER MATERIALS STOCKLINE KIT QTY
					UPDATE dbo.SubWorkOrderMaterialStockLineKit 
					SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
					FROM dbo.SubWorkOrderMaterialStockLineKit WOMS JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.SubWorkOrderMaterialsKitId = tmpRSL.SubWorkOrderMaterialsId 
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
							WorkOrderMaterialsKitId = tmpRSL.SubWorkOrderMaterialsId
						FROM dbo.Stockline SL JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
						WHERE ISNULL(tmpRSL.KitId, 0) > 0 AND tmpRSL.ID = @countKitStockline AND Sl.StockLineId = @tmpKitStockLineId

						SET @countKitStockline = @countKitStockline + 1;
					END;
		
					--UPDATE SUB WORK ORDER MATERIALS DETAILS
					WHILE @count<= @TotalCountsBoth
					BEGIN
						UPDATE SubWorkOrderMaterials 
							SET QuantityIssued = ISNULL(WOM.QuantityIssued,0) - ISNULL(tmpWOM.QuantityActUnIssued,0),
								TotalIssued = ISNULL(WOM.TotalIssued,0) - ISNULL(tmpWOM.QuantityActUnIssued,0),
								IssuedById = tmpWOM.UpdatedById, 
								IssuedDate = GETDATE(), 
								UpdatedDate = GETDATE(),
								PartStatusId = @PartStatus
						FROM dbo.SubWorkOrderMaterials WOM JOIN #tmpUnIssueWOMaterialsStockline tmpWOM ON tmpWOM.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND tmpWOM.ID = @count AND ISNULL(tmpWOM.KitId, 0) = 0
						SET @count = @count + 1;
					END;
					
					--UPDATE SUB WORK ORDER MATERIALS STOCKLINE DETAILS
					IF(@TotalCountsBoth > 0 )
					BEGIN
						UPDATE dbo.SubWorkOrderMaterialStockLine 
						SET QtyIssued = ISNULL(QtyIssued, 0) - ISNULL(QuantityActUnIssued, 0),
							ExtendedCost = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							ExtendedPrice = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							UpdatedDate = GETDATE(),
							UpdatedBy = ReservedBy
						FROM dbo.SubWorkOrderMaterialStockLine WOMS 
						JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.SubWorkOrderMaterialsId = tmpRSL.SubWorkOrderMaterialsId AND ISNULL(tmpRSL.KitId, 0) = 0
					END

					--FOR UPDATE SUB WORKORDER MATERIALS STOCKLINE QTY
					UPDATE dbo.SubWorkOrderMaterialStockLine 
					SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
					FROM dbo.SubWorkOrderMaterialStockLine WOMS JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.SubWorkOrderMaterialsId = tmpRSL.SubWorkOrderMaterialsId 
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
							QuantityIssued = ISNULL(SL.QuantityIssued,0) - ISNULL(tmpRSL.QuantityActUnIssued,0)
						FROM dbo.Stockline SL JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
						WHERE ISNULL(tmpRSL.KitId, 0) = 0 AND tmpRSL.ID = @countStockline AND Sl.StockLineId = @tmpStockLineId

						SET @countStockline = @countStockline + 1;
					END;

					DECLARE @countBoth INT = 1;

					--FOR UPDATE TOTAL SUB WORK ORDER COST
					WHILE @countBoth <= @TotalCountsBoth
					BEGIN
						SELECT	@SubWorkOrderMaterialsId = tmpWOM.SubWorkOrderMaterialsId
						FROM #tmpUnIssueWOMaterialsStockline tmpWOM 
						WHERE tmpWOM.ID = @count

						EXEC [dbo].[USP_UpdateSubWOMaterialsCost]  @SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId
						
						SET @countBoth = @countBoth + 1;
					END;

					--FOR STOCK LINE HISTORY	
					WHILE @slcount<= @TotalCounts
					BEGIN
						SELECT	@StocklineId = tmpWOM.StockLineId,
								@MasterCompanyId = tmpWOM.MasterCompanyId,
								@ReferenceId = tmpWOM.SubWorkOrderId,
								@SubReferenceId = tmpWOM.SubWorkOrderMaterialsId,
								@UpdateBy = UpdatedBy,
								@IssueQty = QuantityActUnIssued
						FROM #tmpUnIssueWOMaterialsStockline tmpWOM 
						WHERE tmpWOM.ID = @slcount

						SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId

						DECLARE @ActionId INT;
						SET @ActionId = 5; -- UnIssue
						EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @IssueQty, @UpdatedBy = @UpdateBy;

						SET @ActionId = 3; -- UnReserve
						EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @IssueQty, @UpdatedBy = @UpdateBy;

						--Added for WO History 
						DECLARE @HistorySubWorkOrderMaterialsId BIGINT,@historyModuleId BIGINT,@historySubModuleId BIGINT,
								@historySubWorkOrderId BIGINT,@HistoryQtyReserved VARCHAR(MAX),@HistoryQuantityActReserved VARCHAR(MAX),@historyReservedById BIGINT,
								@historyEmployeeName VARCHAR(100),@historyMasterCompanyId BIGINT,@historytotalReserved VARCHAR(MAX),@TemplateBody NVARCHAR(MAX),
								@SubWorkOrderNum VARCHAR(MAX),@ConditionId BIGINT,@ConditionCode VARCHAR(MAX),@HistoryStockLineId BIGINT,@HistoryStockLineNum VARCHAR(MAX),
								@SubWorkOrderPartNoId BIGINT,@historyQuantity BIGINT,@historyQtyToBeReserved BIGINT, @KITID BIGINT, @historyPartNumber NVARCHAR(MAX);

						SELECT @historyModuleId = moduleId FROM Module WHERE ModuleName = 'SubWorkOrder';
						SELECT @historySubModuleId = moduleId FROM Module WHERE ModuleName = 'SubWorkOrderMPN';
						SELECT @TemplateBody = TemplateBody FROM HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = 'UnReservedParts';
						SELECT @HistorySubWorkOrderMaterialsId = SubWorkOrderMaterialsId,
							   @historySubWorkOrderId = SubWorkOrderId,  @KITID = ISNULL(KitId,0), @UpdateBy = UpdatedBy,
							   @historyMasterCompanyId = MasterCompanyId,@ConditionId = ConditionId,@HistoryStockLineId = StockLineId,
							   @historyQuantity = Quantity,@historyQtyToBeReserved = QtyToBeReserved,
							   @historyPartNumber = PartNumber
						FROM #tmpUnIssueWOMaterialsStockline WHERE ID = @slcount;

						SELECT @SubWorkOrderPartNoId = SubWOPartNoId FROM dbo.SubWorkOrderMaterials WITH(NOLOCK) WHERE SubWorkOrderMaterialsId = @HistorySubWorkOrderMaterialsId;

						SELECT @SubWorkOrderNum = SubWorkOrderNo FROM dbo.SubWorkOrder WITH(NOLOCK) WHERE SubWorkOrderId = @historySubWorkOrderId;
						SELECT @ConditionCode = Code FROM Condition WITH(NOLOCK) WHERE ConditionId = @ConditionId;
						SELECT @HistoryStockLineNum = StockLineNumber FROM Stockline WITH(NOLOCK) WHERE StockLineId = @HistoryStockLineId;

						SET @TemplateBody = REPLACE(@TemplateBody, '##PN##', ISNULL(@historyPartNumber,''));
						SET @TemplateBody = REPLACE(@TemplateBody, '##Quantity##', ISNULL(@historyQuantity,''));
						
						SELECT @historyEmployeeName = (FirstName +' '+ LastName) FROM Employee WITH(NOLOCK) WHERE EmployeeId = @historyReservedById;
						SELECT @HistoryQtyReserved = CAST(QuantityReserved AS VARCHAR) FROM dbo.SubWorkOrderMaterials WOM WITH(NOLOCK) JOIN #tmpUnIssueWOMaterialsStockline tmpWOM ON tmpWOM.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND tmpWOM.ID = @count;
						
						IF @KITID = 0
						BEGIN
							EXEC [dbo].[USP_History] @historyModuleId,@historySubWorkOrderId,@historySubModuleId,@SubWorkOrderPartNoId,@historyQuantity,@historyQtyToBeReserved,@TemplateBody,'UnReservedParts',@historyMasterCompanyId,@UpdateBy,NULL,@UpdateBy,NULL;
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
              , @AdhocComments     VARCHAR(150)    = 'usp_UnReserveUnIssueSubWorkOrderMaterialsStockline' 
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
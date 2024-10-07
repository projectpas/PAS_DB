/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <12/30/2021>  
** Description: <Save Work Order Materials Issue Stockline Details>  
  
EXEC [usp_UnIssueWorkOrderMaterialsStockline] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date				Author				Change Description  
** --   --------		 -------			 --------------------------------
** 1    12/30/2021		HEMANT SALIYA		Save Work Order Materials Issued Stockline Details
** 2    07/19/2023		Devendra Shekh		declare new param @KITID and added new if for exec wohistory
** 3    26/07/2023		Satish Gohil		Glaccount id validation added
** 4    04/08/2023      Satish Gohil	    Seprate Accounting Entry WO Type Wise
** 5    08/18/2023      AMIT GHEDIYA	    Update historytext for WOhistory.
** 6    02/19/2024		HEMANT SALIYA	    Updated for Restrict Accounting Entry by Master Company
** 7    07/22/2024		Devendra Shekh	    Modified For Same JE Changes
** 6    09/24/2024      HEMANT SALIYA	    Re-Calculate WOM Qty Res & Qty Issue
** 7    10/04/2024      RAJESH GAMI 	    Implement the ReferenceNumber column data into WOMaterial | Kit Stockline table.

DECLARE @p1 dbo.ReserveWOMaterialsStocklineType

INSERT INTO @p1 values(65,72,87,1073,4,6,1,14,6,N'REPAIR',N'FLYSKY CT6B FS-CT6B',N'USED FOR WING REPAIR',5,3,1,N'CNTL-000463',N'ID_NUM-000001',N'STL-000123',N'',N'ADMIN ADMIN',1)
INSERT INTO @p1 values(65,72,99,2093,25,6,1,14,6,N'REPAIR',N'WAT0303-01',N'70303-01 RECOGNITION LIGHT 28V 25W',3,3,2,N'CNTL-000526',N'ID_NUM-000001',N'STL-000009',N'',N'ADMIN ADMIN',1)
INSERT INTO @p1 values(65,72,10099,510,15,34,2,14,6,N'INSPECTED',N'AIR-MAZE',N'AIR-MAZE U2-849 AERONCA AIR FILTER',10,7,1,N'CNTL-000308',N'ID_NUM-000001',N'STL-000072',N'',N'ADMIN ADMIN',1)
INSERT INTO @p1 values(65,72,10099,512,15,34,2,14,6,N'INSPECTED',N'AIR-MAZE',N'AIR-MAZE U2-849 AERONCA AIR FILTER',10,7,1,N'CNTL-000310',N'ID_NUM-000001',N'STL-000072',N'',N'ADMIN ADMIN',0)
INSERT INTO @p1 values(65,72,10099,513,15,34,2,14,6,N'INSPECTED',N'AIR-MAZE',N'AIR-MAZE U2-849 AERONCA AIR FILTER',10,7,1,N'CNTL-000311',N'ID_NUM-000001',N'STL-000072',N'',N'ADMIN ADMIN',0)

EXEC dbo.usp_IssueWorkOrderMaterialsStockline @tbl_MaterialsStocklineType=@p1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_UnIssueWorkOrderMaterialsStockline]
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
					DECLARE @RC int;
                    DECLARE @DistributionMasterId bigint;
					DECLARE @DistributionCode VARCHAR(50);
                    DECLARE @ReferencePartId bigint;
                    DECLARE @ReferencePieceId bigint;
                    DECLARE @InvoiceId bigint=0;
					DECLARE @IssueQty bigint=0;
                    DECLARE @laborType varchar(200)='lab';
                    DECLARE @issued bit=0;
                    DECLARE @Amount decimal(18,2);
                    DECLARE @ModuleName varchar(200)='WOP-PartsIssued';
                    DECLARE @UpdateBy varchar(200);
					DECLARE @IsKit BIGINT = 0;
					DECLARE @MaterialRefNo VARCHAR(100) = 'UnIssue', @WONumber VARCHAR(100);
					DECLARE @WOBatchTriggerType BatchTriggerWorkOrderType;
					DECLARE @IWOBatchTriggerType BatchTriggerWorkOrderType;
					DECLARE @WOBatchCount INT = 0;
					DECLARE @IWOBatchCount INT = 0;

					SELECT @WONumber=WorkOrderNum from dbo.WorkOrder WO WITH(NOLOCK) WHERE WorkOrderId = (SELECT TOP 1 WorkOrderId FROM @tbl_MaterialsStocklineType)
					SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 15; -- For WORK ORDER Module
					SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 33; -- For WORK ORDER Materials Module
					select @DistributionMasterId =ID, @DistributionCode = DistributionCode from DistributionMaster WITH(NOLOCK)  where UPPER(DistributionCode)= UPPER('WOMATERIALGRIDTAB')
					SET @PartStatus = 4; -- FOR Un-Issue
					SET @IsAddUpdate = 0;
					SET @ExecuteParentChild = 1;
					SET @UpdateQuantities = 1;
					SET @IsOHUpdated = 0;
					SET @AddHistoryForNonSerialized = 0;					
					SET @slcount = 1;
					SET @count = 1;
					SET @countKIT = 1;
					DECLARE @Qty bigint = 0;
					DECLARE @ActionId INT = 0;
					DECLARE @WOTypeId INT= 0;
					DECLARE @CustomerWOTypeId INT= 0;
					DECLARE @InternalWOTypeId INT= 0;
					DECLARE @historyPartNumber VARCHAR(150);

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

					SELECT TOP 1 @CustomerWOTypeId =Id FROM dbo.WorkOrderType WITH (NOLOCK) WHERE [Description] = 'Customer'
					SELECT TOP 1 @InternalWOTypeId =Id FROM dbo.WorkOrderType WITH (NOLOCK) WHERE [Description] = 'Internal'

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
								QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.QuantityActUnIssued,0),
								TotalIssued = ISNULL(WOM.TotalIssued,0) - ISNULL(tmpWOM.QuantityActUnIssued,0),
								TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.QuantityActUnIssued,0),
								IssuedById = tmpWOM.UpdatedById, 
								IssuedDate = GETUTCDATE(), 
								UpdatedDate = GETUTCDATE(),
								PartStatusId = @PartStatus
						FROM dbo.WorkOrderMaterialsKit WOM JOIN #tmpUnIssueWOMaterialsStockline tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsKitId AND tmpWOM.ID = @countKIT 
						WHERE ISNULL(tmpWOM.KitId, 0) > 0
						SET @countKIT = @countKIT + 1;
					END;
					
					--UPDATE WORK ORDER MATERIALS STOCKLINE DETAILS
					IF (@TotalCountsBoth > 0)
					BEGIN
						UPDATE dbo.WorkOrderMaterialStockLineKit 
						SET QtyIssued = ISNULL(QtyIssued, 0) - ISNULL(QuantityActUnIssued, 0),
							QtyReserved = ISNULL(QtyReserved, 0) + ISNULL(QuantityActUnIssued, 0),
							ExtendedCost = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							ExtendedPrice = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							UpdatedDate = GETUTCDATE(),
							UpdatedBy = ReservedBy,ReferenceNumber= @MaterialRefNo + ' - '+@WONumber
						FROM dbo.WorkOrderMaterialStockLineKit WOMS 
						JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsKitId = tmpRSL.WorkOrderMaterialsId 
						WHERE ISNULL(tmpRSL.KitId, 0) > 0
					END

					--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
					UPDATE dbo.WorkOrderMaterialStockLineKit 
					SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) , ReferenceNumber =@MaterialRefNo + ' - '+@WONumber
					FROM dbo.WorkOrderMaterialStockLineKit WOMS JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsKitId = tmpRSL.WorkOrderMaterialsId 
					WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) AND ISNULL(tmpRSL.KitId, 0) > 0
					
					--FOR UPDATED STOCKLINE QTY
					UPDATE dbo.Stockline
					SET QuantityOnHand = ISNULL(SL.QuantityOnHand, 0) + ISNULL(tmpRSL.QuantityActUnIssued,0),
						QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(tmpRSL.QuantityActUnIssued,0),
						QuantityIssued = ISNULL(SL.QuantityIssued,0) - ISNULL(tmpRSL.QuantityActUnIssued,0),						
						WorkOrderMaterialsKitId = tmpRSL.WorkOrderMaterialsId
					FROM dbo.Stockline SL JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
					WHERE ISNULL(tmpRSL.KitId, 0) > 0

					--UPDATE WORK ORDER MATERIALS DETAILS
					WHILE @count <= @TotalCountsBoth
					BEGIN
						
						UPDATE WorkOrderMaterials 
							SET QuantityIssued = ISNULL(WOM.QuantityIssued,0) - ISNULL(tmpWOM.QuantityActUnIssued,0),
								QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.QuantityActUnIssued,0),
								TotalIssued = ISNULL(WOM.TotalIssued,0) - ISNULL(tmpWOM.QuantityActUnIssued,0),
								TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.QuantityActUnIssued,0),
								IssuedById = tmpWOM.UpdatedById, 
								IssuedDate = GETUTCDATE(), 
								UpdatedDate = GETUTCDATE(),
								PartStatusId = @PartStatus
						FROM dbo.WorkOrderMaterials WOM JOIN #tmpUnIssueWOMaterialsStockline tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.ID = @count AND ISNULL(tmpWOM.KitId, 0) = 0
						SET @count = @count + 1;
					END;
					
					--UPDATE WORK ORDER MATERIALS STOCKLINE DETAILS
					IF (@TotalCountsBoth > 0 )
					BEGIN
						UPDATE dbo.WorkOrderMaterialStockLine 
						SET QtyIssued = ISNULL(QtyIssued, 0) - ISNULL(QuantityActUnIssued, 0),
							QtyReserved = ISNULL(QtyReserved, 0) + ISNULL(QuantityActUnIssued, 0),
							ExtendedCost = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							ExtendedPrice = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							UpdatedDate = GETUTCDATE(),
							UpdatedBy = ReservedBy,ReferenceNumber = @MaterialRefNo + ' - '+@WONumber
						FROM dbo.WorkOrderMaterialStockLine WOMS 
						JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId AND ISNULL(tmpRSL.KitId, 0) = 0
					END

					--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
					UPDATE dbo.WorkOrderMaterialStockLine 
					SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) ,ReferenceNumber = @MaterialRefNo + ' - '+@WONumber
					FROM dbo.WorkOrderMaterialStockLine WOMS JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId 
					WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) AND ISNULL(tmpRSL.KitId, 0) = 0 

					--FOR UPDATED STOCKLINE QTY
					UPDATE dbo.Stockline
					SET QuantityOnHand = ISNULL(SL.QuantityOnHand, 0) + ISNULL(tmpRSL.QuantityActUnIssued,0),
						QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(tmpRSL.QuantityActUnIssued,0),
						QuantityIssued = ISNULL(SL.QuantityIssued,0) - ISNULL(tmpRSL.QuantityActUnIssued,0),						
						WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
					FROM dbo.Stockline SL JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
					WHERE ISNULL(tmpRSL.KitId, 0) = 0

					--RE-CALCULATE WOM QTY RES & QTY ISSUE					
					UPDATE dbo.WorkOrderMaterials 
					SET QuantityIssued = GropWOM.QtyIssued, QuantityReserved = GropWOM.QtyReserved
					FROM(
						SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, ISNULL(SUM(WOMS.QtyReserved), 0) QtyReserved, ISNULL(SUM(WOMS.QtyIssued), 0) QtyIssued, WOM.WorkOrderMaterialsId   
						FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)
						JOIN dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId 
						JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId 
							AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
						WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
						GROUP BY WOM.WorkOrderMaterialsId
					) GropWOM WHERE GropWOM.WorkOrderMaterialsId = dbo.WorkOrderMaterials.WorkOrderMaterialsId AND 
					(ISNULL(GropWOM.QtyReserved,0) <> ISNULL(dbo.WorkOrderMaterials.QuantityReserved,0)	OR ISNULL(GropWOM.QtyIssued,0) <> ISNULL(dbo.WorkOrderMaterials.QuantityIssued,0))


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
								@ReferencePartId=tmpWOM.WorkFlowWorkOrderId,
								@UpdateBy=UpdatedBy,
								@IssueQty=QuantityActUnIssued,
								@Amount=UnitCost,
								@ReferencePieceId=tmpWOM.WorkOrderMaterialsId
						FROM #tmpUnIssueWOMaterialsStockline tmpWOM 
						WHERE tmpWOM.ID = @slcount

						SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId

						SELECT TOP 1 @WOTypeId =WorkOrderTypeId FROM dbo.WorkOrder WITH (NOLOCK) WHERE WorkOrderId = @ReferenceId

						SET @ActionId = 5; -- UnIssue
						EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @IssueQty, @UpdatedBy = @UpdateBy;

						--Added for WO History 
						DECLARE @HistoryWorkOrderMaterialsId BIGINT,@historyModuleId BIGINT,@historySubModuleId BIGINT,
								@historyWorkOrderId BIGINT,@HistoryQtyReserved VARCHAR(MAX),@HistoryQuantityActReserved VARCHAR(MAX),@historyReservedById BIGINT,
								@historyEmployeeName VARCHAR(100),@historyMasterCompanyId BIGINT,@historytotalReserved VARCHAR(MAX),@TemplateBody NVARCHAR(MAX),
								@WorkOrderNum VARCHAR(MAX),@ConditionId BIGINT,@ConditionCode VARCHAR(MAX),@HistoryStockLineId BIGINT,@HistoryStockLineNum VARCHAR(MAX),
								@WorkFlowWorkOrderId BIGINT,@WorkOrderPartNoId BIGINT,@historyQuantity BIGINT,@historyQtyToBeReserved BIGINT, @KITID BIGINT;

						SELECT @historyModuleId = moduleId FROM Module WHERE ModuleName = 'WorkOrder';
						SELECT @historySubModuleId = moduleId FROM Module WHERE ModuleName = 'WorkOrderMPN';
						SELECT @TemplateBody = TemplateBody FROM HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = 'UnIssuedParts';
						SELECT @HistoryWorkOrderMaterialsId = WorkOrderMaterialsId,
							   @historyWorkOrderId = WorkOrderId, @KITID = ISNULL(KitId,0),
							   @historyMasterCompanyId = MasterCompanyId,@ConditionId = ConditionId,@HistoryStockLineId = StockLineId,
							   @historyQuantity = Quantity,@historyQtyToBeReserved = QuantityActUnIssued,@historyPartNumber = PartNumber
						FROM #tmpUnIssueWOMaterialsStockline WHERE ID = @slcount;

						SELECT @WorkFlowWorkOrderId = WorkFlowWorkOrderId FROM WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @HistoryWorkOrderMaterialsId;
						SELECT @WorkOrderPartNoId = WorkOrderPartNoId FROM WorkOrderWorkFlow WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId;

						SELECT @WorkOrderNum = WorkOrderNum FROM WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @historyWorkOrderId;
						SELECT @ConditionCode = Code FROM Condition WITH(NOLOCK) WHERE ConditionId = @ConditionId;
						SELECT @HistoryStockLineNum = StockLineNumber FROM Stockline WITH(NOLOCK) WHERE StockLineId = @HistoryStockLineId;

						SET @TemplateBody = REPLACE(@TemplateBody, '##PN##', ISNULL(@historyPartNumber,''));
						SET @TemplateBody = REPLACE(@TemplateBody, '##Quantity##', ISNULL(@historyQtyToBeReserved,''));
						
						SELECT @historyEmployeeName = (FirstName +' '+ LastName) FROM Employee WITH(NOLOCK) WHERE EmployeeId = @historyReservedById;
						SELECT @HistoryQtyReserved = CAST(QuantityReserved AS VARCHAR) FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK) JOIN #tmpUnIssueWOMaterialsStockline tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.ID = @count;
						SELECT @HistoryWorkOrderMaterialsId = WorkOrderPartNoId FROM WorkOrderWorkFlow WITH(NOLOCK);
						
						SET @historytotalReserved = (CAST(@HistoryQtyReserved AS BIGINT) + CAST(@HistoryQuantityActReserved AS BIGINT));

						Declare @OldValue VARCHAR(MAX)='' 
	                    Declare @NewValue VARCHAR(MAX) ='' 

						set @OldValue= (SELECT Cast(@historyQuantity  as varchar))
						set @NewValue= (SELECT Cast(@historyQtyToBeReserved  as varchar))

						print @OldValue
						print @OldValue
						print @UpdateBy

						IF @KITID = 0
						BEGIN
							EXEC [dbo].[USP_History] @historyModuleId,@historyWorkOrderId,@historySubModuleId,@WorkOrderPartNoId,'','UNISSUED PARTS',@TemplateBody,'UnIssuedParts',@historyMasterCompanyId,@UpdateBy,NULL,@UpdateBy,NULL;
						END

						DECLARE @IsRestrict BIT;
					    DECLARE @IsAccountByPass BIT;

						EXEC dbo.USP_GetSubLadgerGLAccountRestriction  @DistributionCode,  @MasterCompanyId,  0,  @UpdateBy, @IsRestrict OUTPUT, @IsAccountByPass OUTPUT;

						-- batch trigger unissue qty
						IF(ISNULL(@WOTypeId,0) = @CustomerWOTypeId AND ISNULL(@IsAccountByPass, 0) = 0)
						BEGIN
							IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
							BEGIN
								INSERT INTO @WOBatchTriggerType VALUES
								(@DistributionMasterId,@ReferenceId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdateBy)
							END
						END
						
						IF(ISNULL(@WOTypeId,0) = @InternalWOTypeId AND ISNULL(@IsAccountByPass, 0) = 0)
						BEGIN
							IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
							BEGIN
								INSERT INTO @IWOBatchTriggerType VALUES
								(@DistributionMasterId,@ReferenceId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdateBy)
							END
						END

						SET @slcount = @slcount + 1;
					END;

					/*** Same JE Changes : Start ***/
					SELECT @WOBatchCount = COUNT(@ReferencePieceId) FROM @WOBatchTriggerType;
					SELECT @IWOBatchCount = COUNT(@ReferencePieceId) FROM @IWOBatchTriggerType;

					DECLARE @IsRestrictNew INT;
					DECLARE @IsAccountByPassNew BIT;

					EXEC dbo.USP_GetSubLadgerGLAccountRestriction  @DistributionCode,  @MasterCompanyId,  0,  @UpdateBy, @IsRestrictNew OUTPUT, @IsAccountByPassNew OUTPUT;

					IF(ISNULL(@WOTypeId,0) = @CustomerWOTypeId AND ISNULL(@IsAccountByPassNew, 0) = 0 AND @WOBatchCount > 0)
					BEGIN
						IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
						BEGIN
							EXEC [USP_BatchTriggerBasedonDistributionForWO] @WOBatchTriggerType;
						END
					END

					IF(ISNULL(@WOTypeId,0) = @InternalWOTypeId AND ISNULL(@IsAccountByPassNew, 0) = 0 AND @IWOBatchCount > 0)
					BEGIN
						IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
						BEGIN
							EXEC [USP_BatchTriggerForInternalWOBasedonDistribution] @IWOBatchTriggerType;
						END
					END
					/*** Same JE Changes : End ***/

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
              , @AdhocComments     VARCHAR(150)    = 'usp_IssueWorkOrderMaterialsStockline' 
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
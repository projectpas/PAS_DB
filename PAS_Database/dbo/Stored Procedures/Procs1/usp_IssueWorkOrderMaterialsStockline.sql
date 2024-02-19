/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <12/30/2021>  
** Description: <Save Work Order Materials Issue Stockline Details>  
  
EXEC [usp_IssueWorkOrderMaterialsStockline] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date			 Author				 Change Description  
** --   --------		-------			 --------------------------------
** 1    12/30/2021		HEMANT SALIYA	  Save Work Order Materials Issued Stockline Details
** 2    07/19/2023		Devendra Shekh    declare new param @KITID and added new if for exec wohistory
** 3    26/07/2023		Satish Gohil	  Glaccount id validation added
** 4    04/08/2023      Satish Gohil	  Seprate Accounting Entry WO Type Wise
** 5    08/17/2023      AMIT GHEDIYA	  Updated HistoryText.
** 6    12/30/2023		HEMANT SALIYA	  Updated Error handling And Resolved Error
** 7    02/16/2024		HEMANT SALIYA	  Updated for Restrict Accounting Entry by Master Company

DECLARE @p1 dbo.ReserveWOMaterialsStocklineType

insert into @p1 values(924,945,1458,79728,3,7,1,1,2,N'NEW',N'0856AE15',N'PITOT STATIC TUBE',1,0,0,1,0,0,N'CNTL-001062',N'ID_NUM-000001',N'STL-000087',N'',N'ADMIN User',1,0,0,0,0,0)

EXEC dbo.usp_IssueWorkOrderMaterialsStockline @tbl_MaterialsStocklineType=@p1
**************************************************************/ 
CREATE  PROCEDURE [dbo].[usp_IssueWorkOrderMaterialsStockline]
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
					DECLARE @IsKit BIGINT = 0;

					DECLARE @RC int
                    DECLARE @DistributionMasterId BIGINT
					DECLARE @DistributionCode VARCHAR(50)
                    DECLARE @ReferencePartId BIGINT
                    DECLARE @ReferencePieceId BIGINT
                    DECLARE @InvoiceId BIGINT=0
					DECLARE @IssueQty BIGINT=0
                    DECLARE @laborType VARCHAR(200)='434'
                    DECLARE @issued bit=1
                    DECLARE @Amount decimal(18,2)
                    DECLARE @ModuleName VARCHAR(200)='WOP-PartsIssued'
                    DECLARE @UpdateBy VARCHAR(200)
					DECLARE @HistoryWorkOrderMaterialsId BIGINT,@historyModuleId BIGINT,@historySubModuleId BIGINT,
							@historyWorkOrderId BIGINT,@HistoryQtyReserved VARCHAR(MAX),@HistoryQuantityActReserved VARCHAR(MAX),@historyReservedById BIGINT,
							@historyEmployeeName VARCHAR(100),@historyMasterCompanyId BIGINT,@historytotalReserved VARCHAR(MAX),@TemplateBody NVARCHAR(MAX),
							@WorkOrderNum VARCHAR(MAX),@ConditionId BIGINT,@ConditionCode VARCHAR(MAX),@HistoryStockLineId BIGINT,@HistoryStockLineNum VARCHAR(MAX),
							@WorkFlowWorkOrderId BIGINT,@WorkOrderPartNoId BIGINT,@historyQuantity BIGINT,@historyQtyToBeReserved BIGINT, @KITID BIGINT,
							@ItemMasterId BIGINT,@Partnumber VARCHAR(200),@MPNPartnumber VARCHAR(200),@historyQuantityActIssued BIGINT,
							@OldValue VARCHAR(MAX)='' ,@NewValue VARCHAR(MAX) ='' 

					SELECT @DistributionMasterId = ID, @DistributionCode = DistributionCode FROM dbo.DistributionMaster WITH(NOLOCK) WHERE UPPER(DistributionCode)= UPPER('WOMATERIALGRIDTAB')
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
					DECLARE @Qty BIGINT = 0;
					DECLARE @ActionId INT = 0;
					DECLARE @WOTypeId INT= 0;
					DECLARE @CustomerWOTypeId INT= 0;
					DECLARE @InternalWOTypeId INT= 0;

					IF OBJECT_ID(N'tempdb..#tmpIssueWOMaterialsStockline') IS NOT NULL
					BEGIN
						DROP TABLE #tmpIssueWOMaterialsStockline
					END
			
					CREATE TABLE #tmpIssueWOMaterialsStockline
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
						[QuantityActIssued] INT NULL,
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

					IF OBJECT_ID(N'tempdb..#tmpIssueWOMaterialsStocklineWithoutKit') IS NOT NULL
					BEGIN
						DROP TABLE #tmpIssueWOMaterialsStocklineWithoutKit
					END
			
					CREATE TABLE #tmpIssueWOMaterialsStocklineWithoutKit
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
						[QuantityActIssued] INT NULL,
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

					IF OBJECT_ID(N'tempdb..#tmpIssueWOMaterialsStocklineKit') IS NOT NULL
					BEGIN
						DROP TABLE #tmpIssueWOMaterialsStocklineKit
					END
			
					CREATE TABLE #tmpIssueWOMaterialsStocklineKit
					(
						ID BIGINT NOT NULL IDENTITY, 
						[WorkOrderId] BIGINT NULL,
						[WorkFlowWorkOrderId] BIGINT NULL,
						[WorkOrderMaterialsKitId] BIGINT NULL,
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
						[QuantityActIssued] INT NULL,
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

					PRINT 'Hem-1'

					INSERT INTO #tmpIssueWOMaterialsStockline ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
							[TaskId], [Condition], [PartNumber], [PartDescription], [Quantity], [QtyToBeReserved], [QuantityActIssued], [ControlNo], [ControlId],
							[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UpdatedById],  [UnitCost], [IsSerialized], [KitId])
					SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], tblMS.[StockLineId], tblMS.[ItemMasterId], tblMS.[ConditionId], [ProvisionId], 
							[TaskId], tblMS.[Condition], tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], [QtyToBeReserved], [QuantityActIssued], [ControlNo], [ControlId],
							tblMS.[StockLineNumber], tblMS.[SerialNumber], [ReservedBy], [IsStocklineAdded], SL.MasterCompanyId, [ReservedBy], [ReservedById], SL.UnitCost, SL.isSerialized, tblMS.[KitId]
					FROM @tbl_MaterialsStocklineType tblMS  JOIN dbo.Stockline SL ON SL.StockLineId = tblMS.StockLineId 
					WHERE SL.QuantityOnHand > 0 AND SL.QuantityOnHand >= tblMS.QuantityActIssued

					INSERT INTO #tmpIssueWOMaterialsStocklineWithoutKit ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
							[TaskId], [Condition], [PartNumber], [PartDescription], [Quantity], [QtyToBeReserved], [QuantityActIssued], [ControlNo], [ControlId],
							[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UpdatedById],  [UnitCost], [IsSerialized], [KitId])
					SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], tblMS.[StockLineId], tblMS.[ItemMasterId], tblMS.[ConditionId], [ProvisionId], 
							[TaskId], tblMS.[Condition], tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], [QtyToBeReserved], [QuantityActIssued], [ControlNo], [ControlId],
							tblMS.[StockLineNumber], tblMS.[SerialNumber], [ReservedBy], [IsStocklineAdded], SL.MasterCompanyId, [ReservedBy], [ReservedById], SL.UnitCost, SL.isSerialized, tblMS.[KitId]
					FROM @tbl_MaterialsStocklineType tblMS  JOIN dbo.Stockline SL ON SL.StockLineId = tblMS.StockLineId 
					WHERE SL.QuantityOnHand > 0 AND SL.QuantityOnHand >= tblMS.QuantityActIssued
					AND ISNULL(tblMS.KitId, 0) = 0

					INSERT INTO #tmpIssueWOMaterialsStocklineKit ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsKitId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
							[TaskId], [Condition], [PartNumber], [PartDescription], [Quantity], [QtyToBeReserved], [QuantityActIssued], [ControlNo], [ControlId],
							[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UpdatedById],  [UnitCost], [IsSerialized], [KitId])
					SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], tblMS.[StockLineId], tblMS.[ItemMasterId], tblMS.[ConditionId], [ProvisionId], 
							[TaskId], tblMS.[Condition], tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], [QtyToBeReserved], [QuantityActIssued], [ControlNo], [ControlId],
							tblMS.[StockLineNumber], tblMS.[SerialNumber], [ReservedBy], [IsStocklineAdded], SL.MasterCompanyId, [ReservedBy], [ReservedById], SL.UnitCost, SL.isSerialized, tblMS.[KitId]
					FROM @tbl_MaterialsStocklineType tblMS  JOIN dbo.Stockline SL ON SL.StockLineId = tblMS.StockLineId 
					WHERE SL.QuantityOnHand > 0 AND SL.QuantityOnHand >= tblMS.QuantityActIssued
					AND ISNULL(tblMS.KitId, 0) > 0

					SELECT @TotalCounts = COUNT(ID) FROM #tmpIssueWOMaterialsStocklineWithoutKit;
					SELECT @TotalCountsKIT = COUNT(ID) FROM #tmpIssueWOMaterialsStocklineKit;
					SELECT @TotalCountsBoth = COUNT(ID) FROM #tmpIssueWOMaterialsStockline;

					INSERT INTO #tmpIgnoredStockline ([PartNumber], [Condition], [ControlNo], [ControlId], [StockLineNumber]) 
					SELECT tblMS.[PartNumber], tblMS.[Condition], tblMS.[ControlNo], tblMS.[ControlId], tblMS.[StockLineNumber] FROM @tbl_MaterialsStocklineType tblMS  
					WHERE tblMS.StockLineId NOT IN (SELECT StockLineId FROM #tmpIssueWOMaterialsStockline)
					
					PRINT 'Hem-2'

					--UPDATE WORK ORDER MATERIALS DETAILS
					WHILE @countKIT <= @TotalCountsBoth
					BEGIN
						UPDATE WorkOrderMaterialsKit 
							SET QuantityIssued = ISNULL(WOM.QuantityIssued,0) + ISNULL(tmpWOM.QuantityActIssued,0),
								QuantityReserved = ISNULL(WOM.QuantityReserved,0) - ISNULL(tmpWOM.QuantityActIssued,0),
								TotalIssued = ISNULL(WOM.TotalIssued,0) + ISNULL(tmpWOM.QuantityActIssued,0),
								TotalReserved = ISNULL(WOM.TotalReserved,0) - ISNULL(tmpWOM.QuantityActIssued,0),
								IssuedById = tmpWOM.UpdatedById, 
								IssuedDate = GETUTCDATE(), 
								UpdatedDate = GETUTCDATE(),
								PartStatusId = @PartStatus
						FROM dbo.WorkOrderMaterialsKit WOM JOIN #tmpIssueWOMaterialsStocklineKit tmpWOM ON tmpWOM.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId AND tmpWOM.ID = @countKIT
						SET @countKIT = @countKIT + 1;
					END;

					--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
					IF (@TotalCountsBoth > 0)
					BEGIN
						MERGE dbo.WorkOrderMaterialStockLineKit AS TARGET
						USING #tmpIssueWOMaterialsStocklineKit AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.WorkOrderMaterialsKitId = TARGET.WorkOrderMaterialsKitId) 
						--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
						WHEN MATCHED 				
							THEN UPDATE 						
							SET TARGET.QtyIssued = ISNULL(TARGET.QtyIssued, 0) + ISNULL(SOURCE.QuantityActIssued, 0),
								TARGET.QtyReserved = ISNULL(TARGET.QtyReserved, 0) - ISNULL(SOURCE.QuantityActIssued, 0),
								TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * TARGET.UnitCost,
								TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * TARGET.UnitCost,
								TARGET.UpdatedDate = GETUTCDATE(),
								TARGET.UpdatedBy = SOURCE.ReservedBy
						WHEN NOT MATCHED BY TARGET 
							THEN INSERT (StocklineId, WorkOrderMaterialsKitId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
							VALUES (SOURCE.StocklineId, SOURCE.WorkOrderMaterialsKitId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.QuantityActIssued, 0, SOURCE.QuantityActIssued, SOURCE.UnitCost, (ISNULL(SOURCE.QuantityActIssued, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.QuantityActIssued, 0) * ISNULL(SOURCE.UnitCost, 0)), GETUTCDATE(), SOURCE.ReservedBy, GETUTCDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0);
					END

					--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
					UPDATE dbo.WorkOrderMaterialStockLineKit 
					SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
					FROM dbo.WorkOrderMaterialStockLineKit WOMS JOIN #tmpIssueWOMaterialsStocklineKit tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsKitId = tmpRSL.WorkOrderMaterialsKitId 
					WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) AND ISNULL(tmpRSL.KitId, 0) > 0

					--FOR UPDATED STOCKLINE QTY
					UPDATE dbo.Stockline
					SET QuantityOnHand = ISNULL(SL.QuantityOnHand, 0) - ISNULL(tmpRSL.QuantityActIssued,0),
						QuantityReserved = ISNULL(SL.QuantityReserved,0) - ISNULL(tmpRSL.QuantityActIssued,0),
						QuantityIssued = ISNULL(SL.QuantityIssued,0) + ISNULL(tmpRSL.QuantityActIssued,0),
						WorkOrderMaterialsKitId = tmpRSL.WorkOrderMaterialsKitId
					FROM dbo.Stockline SL JOIN #tmpIssueWOMaterialsStocklineKit tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
					--UPDATE WORK ORDER MATERIALS DETAILS
					WHILE @count <= @TotalCountsBoth
					BEGIN
						UPDATE WorkOrderMaterials 
							SET QuantityIssued = ISNULL(WOM.QuantityIssued,0) + ISNULL(tmpWOM.QuantityActIssued,0),
								QuantityReserved = ISNULL(WOM.QuantityReserved,0) - ISNULL(tmpWOM.QuantityActIssued,0),
								TotalIssued = ISNULL(WOM.TotalIssued,0) + ISNULL(tmpWOM.QuantityActIssued,0),
								TotalReserved = ISNULL(WOM.TotalReserved,0) - ISNULL(tmpWOM.QuantityActIssued,0),
								IssuedById = tmpWOM.UpdatedById, 
								IssuedDate = GETUTCDATE(), 
								UpdatedDate = GETUTCDATE(),
								PartStatusId = @PartStatus
						FROM dbo.WorkOrderMaterials WOM JOIN #tmpIssueWOMaterialsStocklineWithoutKit tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.ID = @count
						SET @count = @count + 1;
					END;

					PRINT 'Hem-3'

					--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
					IF (@TotalCountsBoth > 0 )
					BEGIN
						PRINT 'Hem-3.1'
						
						MERGE dbo.WorkOrderMaterialStockLine AS TARGET
						USING #tmpIssueWOMaterialsStocklineWithoutKit AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.WorkOrderMaterialsId = TARGET.WorkOrderMaterialsId)
						--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
						WHEN MATCHED 				
							THEN UPDATE 						
							SET TARGET.QtyIssued = ISNULL(TARGET.QtyIssued, 0) + ISNULL(SOURCE.QuantityActIssued, 0),
								TARGET.QtyReserved = ISNULL(TARGET.QtyReserved, 0) - ISNULL(SOURCE.QuantityActIssued, 0),
								TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * TARGET.UnitCost,
								TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * TARGET.UnitCost,
								TARGET.UpdatedDate = GETUTCDATE(),
								TARGET.UpdatedBy = SOURCE.ReservedBy
						WHEN NOT MATCHED BY TARGET 
							THEN INSERT (StocklineId, WorkOrderMaterialsId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
							VALUES (SOURCE.StocklineId, SOURCE.WorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.QuantityActIssued, 0, SOURCE.QuantityActIssued, SOURCE.UnitCost, (ISNULL(SOURCE.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETUTCDATE(), SOURCE.ReservedBy, GETUTCDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0);
					END

					PRINT 'Hem-4'

					--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
					UPDATE dbo.WorkOrderMaterialStockLine 
					SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
					FROM dbo.WorkOrderMaterialStockLine WOMS JOIN #tmpIssueWOMaterialsStocklineWithoutKit tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId 
					WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0)

					PRINT 'Hem-4.1'
					--FOR UPDATED STOCKLINE QTY
					UPDATE dbo.Stockline
					SET QuantityOnHand = ISNULL(SL.QuantityOnHand, 0) - ISNULL(tmpRSL.QuantityActIssued,0),
						QuantityReserved = ISNULL(SL.QuantityReserved,0) - ISNULL(tmpRSL.QuantityActIssued,0),
						QuantityIssued = ISNULL(SL.QuantityIssued,0) + ISNULL(tmpRSL.QuantityActIssued,0),
						WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
					FROM dbo.Stockline SL JOIN #tmpIssueWOMaterialsStocklineWithoutKit tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
					
					PRINT 'Hem-4.2'
					DECLARE @countBoth INT = 1;
					--FOR UPDATE TOTAL WORK ORDER COST
					WHILE @countBoth <= @TotalCountsBoth
					BEGIN
						SELECT	@WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId
						FROM #tmpIssueWOMaterialsStockline tmpWOM 
						WHERE tmpWOM.ID = @countBoth
						EXEC [dbo].[USP_UpdateWOMaterialsCost]  @WorkOrderMaterialsId = @WorkOrderMaterialsId
						SET @countBoth = @countBoth + 1;
					END;

					PRINT 'Hem-5'

					--FOR STOCK LINE HISTORY	
					WHILE @slcount <= @TotalCountsBoth
					BEGIN
						SELECT	@StocklineId = tmpWOM.StockLineId,
								@MasterCompanyId = tmpWOM.MasterCompanyId,
								@ReferenceId = tmpWOM.WorkOrderId,
								@SubReferenceId = tmpWOM.WorkOrderMaterialsId,
								@ReferencePartId=tmpWOM.WorkFlowWorkOrderId,
								@UpdateBy=UpdatedBy,
								@IssueQty=QuantityActIssued,
								@Amount=UnitCost,
								@ReferencePieceId=tmpWOM.WorkOrderMaterialsId
								
						FROM #tmpIssueWOMaterialsStockline tmpWOM 
						WHERE tmpWOM.ID = @slcount

						SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) WHERE StockLineId = @StocklineId

						SELECT TOP 1 @WOTypeId =WorkOrderTypeId FROM dbo.WorkOrder WITH (NOLOCK) WHERE WorkOrderId = @ReferenceId
						
						SET @ActionId = 4; -- Issue
						EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @IssueQty, @UpdatedBy = @UpdateBy;

						--Added for WO History 
						SELECT @historyModuleId = moduleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'WorkOrder';
						SELECT @historySubModuleId = moduleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'WorkOrderMPN';
						SELECT @TemplateBody = TemplateBody FROM HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = 'IssuedParts';
						SELECT @HistoryWorkOrderMaterialsId = WorkOrderMaterialsId,
							   @historyMasterCompanyId = MasterCompanyId,@ConditionId = ConditionId,@HistoryStockLineId = StockLineId,
							   @historyQuantity = Quantity,@historyQtyToBeReserved = QtyToBeReserved, @KITID = ISNULL(KitId,0),
							   @Partnumber = PartNumber,@historyQuantityActIssued = QuantityActIssued 
						FROM #tmpIssueWOMaterialsStockline WHERE ID = @slcount;
						
						SELECT @WorkFlowWorkOrderId = WorkFlowWorkOrderId FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @HistoryWorkOrderMaterialsId;
						SELECT @WorkOrderPartNoId = WorkOrderPartNoId,@historyWorkOrderId = WorkOrderId FROM dbo.WorkOrderWorkFlow WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId;
						SELECT @ItemMasterId = ItemMasterId FROM dbo.WorkOrderPartNumber WITH(NOLOCK) WHERE ID = @WorkOrderPartNoId;
						SELECT @MPNPartnumber = partnumber FROM dbo.ItemMaster WITH(NOLOCK) WHERE ItemMasterId = @ItemMasterId;

						SELECT @WorkOrderNum = WorkOrderNum FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @historyWorkOrderId;
						SELECT @ConditionCode = Code FROM dbo.Condition WITH(NOLOCK) WHERE ConditionId = @ConditionId;
						SELECT @HistoryStockLineNum = StockLineNumber FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId = @HistoryStockLineId;

						SELECT @historyEmployeeName = (FirstName +' '+ LastName) FROM dbo.Employee WITH(NOLOCK) WHERE EmployeeId = @historyReservedById;
						SELECT @HistoryQtyReserved = CAST(QuantityReserved AS VARCHAR) FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK) JOIN #tmpIssueWOMaterialsStocklineWithoutKit tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.ID = @count;
						
						SET @historytotalReserved = (CAST(@HistoryQtyReserved AS BIGINT) + CAST(@HistoryQuantityActReserved AS BIGINT));
						
						SET @TemplateBody = REPLACE(@TemplateBody, '##PN##', ISNULL(@Partnumber,''));
						SET @TemplateBody = REPLACE(@TemplateBody, '##MPN##', ISNULL(@MPNPartnumber,''));
						SET @TemplateBody = REPLACE(@TemplateBody, '##Qty##', ISNULL(@historyQuantityActIssued,0));

						SET @OldValue= '';
						SET @NewValue= 'ISSUED PARTS';

						PRINT 'Hem-6'
						
						IF @KITID = 0
						BEGIN
							EXEC [dbo].[USP_History] @historyModuleId,@historyWorkOrderId,@historySubModuleId,@WorkOrderPartNoId,@OldValue,@NewValue,@TemplateBody,'IssuedParts',@historyMasterCompanyId,@UpdateBy,NULL,@UpdateBy,NULL;
						END
						DECLARE @IsRestrict INT;

						EXEC dbo.USP_GetSubLadgerGLAccountRestriction @DistributionCode = @DistributionCode, @MasterCompanyId = @MasterCompanyId, @AccountingCalendarId = 0, @UpdateBy = @UpdateBy, @IsRestrict = @IsRestrict OUTPUT;

						IF(ISNULL(@WOTypeId,0) = @CustomerWOTypeId AND ISNULL(@IsRestrict, 0) = 0)
						BEGIN
							PRINT '7'
							IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
							BEGIN
								PRINT '7.1.1'
								 EXEC [dbo].[USP_BatchTriggerBasedonDistribution] 
								 @DistributionMasterId,@ReferenceId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdateBy
							END
							PRINT '7.1'
						END

						IF(ISNULL(@WOTypeId,0) = @InternalWOTypeId AND ISNULL(@IsRestrict, 0) = 0)
						BEGIN
							PRINT '8'
							IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
							BEGIN
								EXEC [dbo].[USP_BatchTriggerBasedonDistributionForInternalWO] 
								@DistributionMasterId,@ReferenceId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdateBy
							END
							PRINT '8.1'
						END

						SET @slcount = @slcount + 1;
					END;

					SELECT * FROM #tmpIgnoredStockline

					IF OBJECT_ID(N'tempdb..#tmpIgnoredStockline') IS NOT NULL
					BEGIN
						DROP TABLE #tmpIgnoredStockline
					END

					IF OBJECT_ID(N'tempdb..#tmpIssueWOMaterialsStockline') IS NOT NULL
					BEGIN
						DROP TABLE #tmpIssueWOMaterialsStockline
					END

					IF OBJECT_ID(N'tempdb..#tmpIssueWOMaterialsStocklineKit') IS NOT NULL
					BEGIN
						DROP TABLE #tmpIssueWOMaterialsStocklineKit
					END

					IF OBJECT_ID(N'tempdb..#tmpIssueWOMaterialsStocklineWithoutKit') IS NOT NULL
					BEGIN
						DROP TABLE #tmpIssueWOMaterialsStocklineWithoutKit
					END
				END

			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
					SELECT
					ERROR_NUMBER() AS ErrorNumber,
					ERROR_STATE() AS ErrorState,
					ERROR_SEVERITY() AS ErrorSeverity,
					ERROR_PROCEDURE() AS ErrorProcedure,
					ERROR_LINE() AS ErrorLine,
					ERROR_MESSAGE() AS ErrorMessage;
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
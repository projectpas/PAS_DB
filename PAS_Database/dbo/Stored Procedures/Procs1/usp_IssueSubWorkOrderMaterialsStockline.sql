/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <12/30/2021>  
** Description: <Save Sub Work Order Materials Issue Stockline Details>  
  
EXEC [usp_IssueSubWorkOrderMaterialsStockline] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    12/30/2021  HEMANT SALIYA    Save Sub Work Order Materials Issued Stockline Details
** 2    07/18/2023  VISHAL SUTHAR    Added new stockline history
** 3    08/28/2023  Moin Bloch       Added Subworkorder Material Batch Entry Code

DECLARE @p1 dbo.ReserveWOMaterialsStocklineType

INSERT INTO @p1 values(65,72,87,1073,4,6,1,14,6,N'REPAIR',N'FLYSKY CT6B FS-CT6B',N'USED FOR WING REPAIR',5,3,1,N'CNTL-000463',N'ID_NUM-000001',N'STL-000123',N'',N'ADMIN ADMIN',1)
INSERT INTO @p1 values(65,72,99,2093,25,6,1,14,6,N'REPAIR',N'WAT0303-01',N'70303-01 RECOGNITION LIGHT 28V 25W',3,3,2,N'CNTL-000526',N'ID_NUM-000001',N'STL-000009',N'',N'ADMIN ADMIN',1)
INSERT INTO @p1 values(65,72,10099,510,15,34,2,14,6,N'INSPECTED',N'AIR-MAZE',N'AIR-MAZE U2-849 AERONCA AIR FILTER',10,7,1,N'CNTL-000308',N'ID_NUM-000001',N'STL-000072',N'',N'ADMIN ADMIN',1)
INSERT INTO @p1 values(65,72,10099,512,15,34,2,14,6,N'INSPECTED',N'AIR-MAZE',N'AIR-MAZE U2-849 AERONCA AIR FILTER',10,7,1,N'CNTL-000310',N'ID_NUM-000001',N'STL-000072',N'',N'ADMIN ADMIN',0)
INSERT INTO @p1 values(65,72,10099,513,15,34,2,14,6,N'INSPECTED',N'AIR-MAZE',N'AIR-MAZE U2-849 AERONCA AIR FILTER',10,7,1,N'CNTL-000311',N'ID_NUM-000001',N'STL-000072',N'',N'ADMIN ADMIN',0)

EXEC dbo.usp_IssueSubWorkOrderMaterialsStockline @tbl_MaterialsStocklineType=@p1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_IssueSubWorkOrderMaterialsStockline]
@tbl_MaterialsStocklineType SubWOMaterialsStocklineType READONLY
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					--CASE 1 UPDATE SUB WORK ORDER MATERILS
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
					DECLARE @WOTypeId INT= 0;
					DECLARE @WorkOrderId BIGINT;
					DECLARE @CustomerWOTypeId INT= 0;
					DECLARE @InternalWOTypeId INT= 0;
					DECLARE @DistributionMasterId BIGINT = 0
					DECLARE @ReferencePartId BIGINT = 0
					DECLARE @issued BIT = 1
					DECLARE @Amount decimal(18,2) = 0
					DECLARE @ModuleName varchar(200)='SWOP-PartsIssued'

					DECLARE @HistorySubWorkOrderMaterialsId BIGINT,@historyModuleId BIGINT,@historySubModuleId BIGINT,
								@historySubWorkOrderId BIGINT,@HistoryQtyReserved VARCHAR(MAX),@HistoryQuantityActReserved VARCHAR(MAX),@historyReservedById BIGINT,
								@historyEmployeeName VARCHAR(100),@historyMasterCompanyId BIGINT,@historytotalReserved VARCHAR(MAX),@TemplateBody NVARCHAR(MAX),
								@SubWorkOrderNum VARCHAR(MAX),@ConditionId BIGINT,@ConditionCode VARCHAR(MAX),@HistoryStockLineId BIGINT,@HistoryStockLineNum VARCHAR(MAX),
								@SubWorkOrderPartNoId BIGINT,@historyQuantity BIGINT,@historyQtyToBeReserved BIGINT, @KITID BIGINT,
								@ItemMasterId BIGINT,@Partnumber VARCHAR(200),@MPNPartnumber VARCHAR(200),@historyQuantityActIssued BIGINT
								,@OldValue VARCHAR(MAX)='' ,@NewValue VARCHAR(MAX) ='' 

					SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 16; -- For SUB WORK ORDER Module
					SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'SubWorkOrderMaterials'; -- For SUB WORK ORDER Materials Module
					SET @PartStatus = 2; -- FOR Issue
					SET @IsAddUpdate = 0;
					SET @ExecuteParentChild = 1;
					SET @UpdateQuantities = 1;
					SET @IsOHUpdated = 0;
					SET @AddHistoryForNonSerialized = 0;					
					SET @slcount = 1;
					SET @count = 1;
					SET @countKIT = 1;

					SELECT TOP 1 @CustomerWOTypeId =Id FROM dbo.WorkOrderType WITH (NOLOCK) WHERE [Description] = 'Customer'
					SELECT TOP 1 @InternalWOTypeId =Id FROM dbo.WorkOrderType WITH (NOLOCK) WHERE [Description] = 'Internal'

					SELECT @DistributionMasterId =ID from DistributionMaster WITH(NOLOCK)  where UPPER(DistributionCode)= UPPER('WOMATERIALGRIDTAB')

					IF OBJECT_ID(N'tempdb..#tmpIssueSWOMaterialsStockline') IS NOT NULL
					BEGIN
					DROP TABLE #tmpIssueSWOMaterialsStockline
					END
			
					CREATE TABLE #tmpIssueSWOMaterialsStockline
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

					IF OBJECT_ID(N'tempdb..#tmpIssueSWOMaterialsStocklineWithoutKit') IS NOT NULL
					BEGIN
						DROP TABLE #tmpIssueSWOMaterialsStocklineWithoutKit
					END
			
					CREATE TABLE #tmpIssueSWOMaterialsStocklineWithoutKit
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

					IF OBJECT_ID(N'tempdb..#tmpIssueSWOMaterialsStocklineKit') IS NOT NULL
					BEGIN
						DROP TABLE #tmpIssueSWOMaterialsStocklineKit
					END
			
					CREATE TABLE #tmpIssueSWOMaterialsStocklineKit
					(
						ID BIGINT NOT NULL IDENTITY, 
						[WorkOrderId] BIGINT NULL,
						[SubWorkOrderId] BIGINT NULL,
						[SubWOPartNoId] BIGINT NULL,
						[SubWorkOrderMaterialsKitId] BIGINT NULL,
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

					--Select * from @tbl_MaterialsStocklineType

					INSERT INTO #tmpIssueSWOMaterialsStockline ([WorkOrderId],[SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
						[TaskId], [Condition], [PartNumber], [PartDescription], [Quantity], [QtyToBeReserved], [QuantityActIssued], [ControlNo], [ControlId],
						[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UpdatedById],  [UnitCost], [IsSerialized], [KitId])
					SELECT tblMS.[WorkOrderId],tblMS.[SubWorkOrderId], tblMS.[SubWOPartNoId], tblMS.[SubWorkOrderMaterialsId], tblMS.[StockLineId], tblMS.[ItemMasterId], tblMS.[ConditionId], [ProvisionId], 
						[TaskId], tblMS.[Condition], tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], [QtyToBeReserved], [QuantityActIssued], [ControlNo], [ControlId],
						tblMS.[StockLineNumber], tblMS.[SerialNumber], [ReservedBy], [IsStocklineAdded], SL.MasterCompanyId, [ReservedBy], [ReservedById], SL.UnitCost, SL.isSerialized, tblMS.[KitId]
					FROM @tbl_MaterialsStocklineType tblMS  JOIN dbo.Stockline SL ON SL.StockLineId = tblMS.StockLineId 
					WHERE SL.QuantityOnHand > 0 AND SL.QuantityOnHand >= tblMS.QuantityActIssued

					INSERT INTO #tmpIssueSWOMaterialsStocklineWithoutKit ([WorkOrderId],[SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
							[TaskId], [Condition], [PartNumber], [PartDescription], [Quantity], [QtyToBeReserved], [QuantityActIssued], [ControlNo], [ControlId],
							[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UpdatedById],  [UnitCost], [IsSerialized], [KitId])
					SELECT tblMS.[WorkOrderId],tblMS.[SubWorkOrderId], tblMS.[SubWOPartNoId], tblMS.[SubWorkOrderMaterialsId], tblMS.[StockLineId], tblMS.[ItemMasterId], tblMS.[ConditionId], [ProvisionId], 
							[TaskId], tblMS.[Condition], tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], [QtyToBeReserved], [QuantityActIssued], [ControlNo], [ControlId],
							tblMS.[StockLineNumber], tblMS.[SerialNumber], [ReservedBy], [IsStocklineAdded], SL.MasterCompanyId, [ReservedBy], [ReservedById], SL.UnitCost, SL.isSerialized, tblMS.[KitId]
					FROM @tbl_MaterialsStocklineType tblMS  JOIN dbo.Stockline SL ON SL.StockLineId = tblMS.StockLineId 
					WHERE SL.QuantityOnHand > 0 AND SL.QuantityOnHand >= tblMS.QuantityActIssued
					AND ISNULL(tblMS.KitId, 0) = 0

					INSERT INTO #tmpIssueSWOMaterialsStocklineKit ([WorkOrderId],[SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsKitId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
							[TaskId], [Condition], [PartNumber], [PartDescription], [Quantity], [QtyToBeReserved], [QuantityActIssued], [ControlNo], [ControlId],
							[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UpdatedById],  [UnitCost], [IsSerialized], [KitId])
					SELECT tblMS.[WorkOrderId],tblMS.[SubWorkOrderId], tblMS.[SubWOPartNoId], tblMS.[SubWorkOrderMaterialsId], tblMS.[StockLineId], tblMS.[ItemMasterId], tblMS.[ConditionId], [ProvisionId], 
							[TaskId], tblMS.[Condition], tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], [QtyToBeReserved], [QuantityActIssued], [ControlNo], [ControlId],
							tblMS.[StockLineNumber], tblMS.[SerialNumber], [ReservedBy], [IsStocklineAdded], SL.MasterCompanyId, [ReservedBy], [ReservedById], SL.UnitCost, SL.isSerialized, tblMS.[KitId]
					FROM @tbl_MaterialsStocklineType tblMS  JOIN dbo.Stockline SL ON SL.StockLineId = tblMS.StockLineId 
					WHERE SL.QuantityOnHand > 0 AND SL.QuantityOnHand >= tblMS.QuantityActIssued
					AND ISNULL(tblMS.KitId, 0) > 0

					SELECT @TotalCounts = COUNT(ID) FROM #tmpIssueSWOMaterialsStocklineWithoutKit;
					SELECT @TotalCountsKIT = COUNT(ID) FROM #tmpIssueSWOMaterialsStocklineKit;
					SELECT @TotalCountsBoth = COUNT(ID) FROM #tmpIssueSWOMaterialsStockline;

					INSERT INTO #tmpIgnoredStockline ([PartNumber], [Condition], [ControlNo], [ControlId], [StockLineNumber]) 
					SELECT tblMS.[PartNumber], tblMS.[Condition], tblMS.[ControlNo], tblMS.[ControlId], tblMS.[StockLineNumber] FROM @tbl_MaterialsStocklineType tblMS  
					WHERE tblMS.StockLineId NOT IN (SELECT StockLineId FROM #tmpIssueSWOMaterialsStockline)

					--Select * from #tmpIssueSWOMaterialsStockline
					--Select * from #tmpIssueSWOMaterialsStocklineKit

					--UPDATE SUB WORK ORDER MATERIALS KIT DETAILS
					WHILE @countKIT <= @TotalCountsBoth
					BEGIN
						PRINT '1'				
						UPDATE SubWorkOrderMaterialsKit 
							SET QuantityIssued = ISNULL(WOM.QuantityIssued,0) + ISNULL(tmpWOM.QuantityActIssued,0),
								QuantityReserved = ISNULL(WOM.QuantityReserved,0) - ISNULL(tmpWOM.QuantityActIssued,0),
								TotalIssued = ISNULL(WOM.TotalIssued,0) + ISNULL(tmpWOM.QuantityActIssued,0),
								TotalReserved = ISNULL(WOM.TotalReserved,0) - ISNULL(tmpWOM.QuantityActIssued,0),
								IssuedById = tmpWOM.UpdatedById, 
								IssuedDate = GETDATE(), 
								UpdatedDate = GETDATE(),
								PartStatusId = @PartStatus
						FROM dbo.SubWorkOrderMaterialsKit WOM JOIN #tmpIssueSWOMaterialsStocklineKit tmpWOM ON tmpWOM.SubWorkOrderMaterialsKitId = WOM.SubWorkOrderMaterialsKitId AND tmpWOM.ID = @countKIT
						SET @countKIT = @countKIT + 1;

						PRINT '1.1'
					END;

					--UPDATE/INSERT SUB WORK ORDER MATERIALS STOCKLINE KIT DETAILS
					IF (@TotalCountsBoth > 0)
					BEGIN
						PRINT '2'
						MERGE dbo.SubWorkOrderMaterialStockLineKit AS TARGET
						USING #tmpIssueSWOMaterialsStocklineKit AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.SubWorkOrderMaterialsKitId = TARGET.SubWorkOrderMaterialsKitId) 
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
							THEN INSERT (StocklineId, SubWorkOrderMaterialsKitId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
							VALUES (SOURCE.StocklineId, SOURCE.SubWorkOrderMaterialsKitId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.QuantityActIssued, 0, SOURCE.QuantityActIssued, SOURCE.UnitCost, (ISNULL(SOURCE.QuantityActIssued, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.QuantityActIssued, 0) * ISNULL(SOURCE.UnitCost, 0)), GETUTCDATE(), SOURCE.ReservedBy, GETUTCDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0);
					END

					PRINT '3'
					--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
					UPDATE dbo.SubWorkOrderMaterialStockLineKit 
					SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
					FROM dbo.SubWorkOrderMaterialStockLineKit WOMS JOIN #tmpIssueSWOMaterialsStocklineKit tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.SubWorkOrderMaterialsKitId = tmpRSL.SubWorkOrderMaterialsKitId 
					WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) AND ISNULL(tmpRSL.KitId, 0) > 0

					PRINT '4'
					--FOR UPDATED STOCKLINE QTY
					UPDATE dbo.Stockline
					SET QuantityOnHand = ISNULL(SL.QuantityOnHand, 0) - ISNULL(tmpRSL.QuantityActIssued,0),
						QuantityReserved = ISNULL(SL.QuantityReserved,0) - ISNULL(tmpRSL.QuantityActIssued,0),
						QuantityIssued = ISNULL(SL.QuantityIssued,0) + ISNULL(tmpRSL.QuantityActIssued,0),
						SubWorkOrderMaterialsKitId = tmpRSL.SubWorkOrderMaterialsKitId
					FROM dbo.Stockline SL JOIN #tmpIssueSWOMaterialsStocklineKit tmpRSL ON SL.StockLineId = tmpRSL.StockLineId

					PRINT '5'
					--UPDATE SUB WORK ORDER MATERIALS DETAILS
					WHILE @count<= @TotalCountsBoth
					BEGIN
						UPDATE SubWorkOrderMaterials 
							SET QuantityIssued = ISNULL(WOM.QuantityIssued,0) + ISNULL(tmpWOM.QuantityActIssued,0),
								QuantityReserved = ISNULL(WOM.QuantityReserved,0) - ISNULL(tmpWOM.QuantityActIssued,0),
								TotalIssued = ISNULL(WOM.TotalIssued,0) + ISNULL(tmpWOM.QuantityActIssued,0),
								TotalReserved = ISNULL(WOM.TotalReserved,0) - ISNULL(tmpWOM.QuantityActIssued,0),
								IssuedById = tmpWOM.UpdatedById, 
								IssuedDate = GETDATE(), 
								UpdatedDate = GETDATE(),
								PartStatusId = @PartStatus
						FROM dbo.SubWorkOrderMaterials WOM JOIN #tmpIssueSWOMaterialsStockline tmpWOM ON tmpWOM.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND tmpWOM.ID = @count
						SET @count = @count + 1;
					END;
					
					PRINT '6'
					--UPDATE/INSERT SUB WORK ORDER MATERIALS STOCKLINE DETAILS
					IF(@TotalCountsBoth > 0 )
					BEGIN
						MERGE dbo.SubWorkOrderMaterialStockLine AS TARGET
						USING #tmpIssueSWOMaterialsStockline AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.SubWorkOrderMaterialsId = TARGET.SubWorkOrderMaterialsId) 
						--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
						WHEN MATCHED 				
							THEN UPDATE 						
							SET TARGET.QtyIssued = ISNULL(TARGET.QtyIssued, 0) + ISNULL(SOURCE.QuantityActIssued, 0),
								TARGET.QtyReserved = ISNULL(TARGET.QtyReserved, 0) - ISNULL(SOURCE.QuantityActIssued, 0),
								TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * TARGET.UnitCost,
								TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * TARGET.UnitCost,
								TARGET.UpdatedDate = GETDATE(),
								TARGET.UpdatedBy = SOURCE.ReservedBy
						WHEN NOT MATCHED BY TARGET 
							THEN INSERT (StocklineId, SubWorkOrderMaterialsId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
							VALUES (SOURCE.StocklineId, SOURCE.SubWorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.QuantityActIssued, 0, SOURCE.QuantityActIssued, SOURCE.UnitCost, (ISNULL(SOURCE.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0);
					END

					PRINT '7'
					--FOR UPDATED SUB WORK ORDER MATERIALS STOCKLINE QTY
					UPDATE dbo.SubWorkOrderMaterialStockLine 
					SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
					FROM dbo.SubWorkOrderMaterialStockLine WOMS JOIN #tmpIssueSWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.SubWorkOrderMaterialsId = tmpRSL.SubWorkOrderMaterialsId 
					WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 
					
					PRINT '8'
					--FOR UPDATED STOCKLINE QTY
					UPDATE dbo.Stockline
					SET QuantityOnHand = ISNULL(SL.QuantityOnHand, 0) - ISNULL(tmpRSL.QuantityActIssued,0),
						QuantityReserved = ISNULL(SL.QuantityReserved,0) - ISNULL(tmpRSL.QuantityActIssued,0),
                        QuantityIssued = ISNULL(SL.QuantityIssued,0) + ISNULL(tmpRSL.QuantityActIssued,0)						
					FROM dbo.Stockline SL JOIN #tmpIssueSWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
					
					PRINT '9'
					DECLARE @countBoth INT = 1;
					--FOR UPDATE TOTAL SUB WORK ORDER COST
					WHILE @countBoth<= @TotalCountsBoth
					BEGIN
						SELECT	@SubWorkOrderMaterialsId = tmpWOM.SubWorkOrderMaterialsId
						FROM #tmpIssueSWOMaterialsStockline tmpWOM 
						WHERE tmpWOM.ID = @countBoth

						EXEC [dbo].[USP_UpdateSubWOMaterialsCost]  @SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId
						
						SET @countBoth = @countBoth + 1;
					END;

					PRINT '10'
					--FOR STOCK LINE HISTORY	
					WHILE @slcount<= @TotalCountsBoth
					BEGIN
						SELECT	@StocklineId = tmpWOM.StockLineId,
								@MasterCompanyId = tmpWOM.MasterCompanyId,
								@WorkOrderId = tmpWOM.WorkOrderId,
								@ReferenceId = tmpWOM.SubWorkOrderId,
								@ReferencePartId = tmpWOM.SubWOPartNoId,
								@SubReferenceId = tmpWOM.SubWorkOrderMaterialsId,								
								@UpdateBy = UpdatedBy,
								@IssueQty = QuantityActIssued,
								@Amount = UnitCost
						FROM #tmpIssueSWOMaterialsStockline tmpWOM 
						WHERE tmpWOM.ID = @slcount

						SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId

						SELECT TOP 1 @WOTypeId = [WorkOrderTypeId] FROM dbo.WorkOrder WITH (NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;						

						DECLARE @ActionId INT;
						SET @ActionId = 4; -- Issue
						EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @IssueQty, @UpdatedBy = @UpdateBy;

						--Added for WO History 
						SELECT @historyModuleId = moduleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'SubWorkOrder';
						SELECT @historySubModuleId = moduleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'SubWorkOrderMPN';
						SELECT @TemplateBody = TemplateBody FROM HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = 'IssuedParts';
						SELECT @HistorySubWorkOrderMaterialsId = SubWorkOrderMaterialsId,
							   @historyMasterCompanyId = MasterCompanyId,@ConditionId = ConditionId,@HistoryStockLineId = StockLineId,
							   @historyQuantity = Quantity,@historyQtyToBeReserved = QtyToBeReserved, @KITID = ISNULL(KitId,0),
							   @Partnumber = PartNumber,@historyQuantityActIssued = QuantityActIssued 
						FROM #tmpIssueSWOMaterialsStockline WHERE ID = @slcount;

						SELECT @SubWorkOrderPartNoId = SubWOPartNoId, @historySubWorkOrderId = SubWorkOrderId FROM dbo.SubWorkOrderMaterials WITH(NOLOCK) WHERE SubWorkOrderMaterialsId = @HistorySubWorkOrderMaterialsId;
						SELECT @ItemMasterId = SWOP.ItemMasterId, @MPNPartnumber = IM.partnumber FROM dbo.SubWorkOrderPartNumber AS SWOP WITH(NOLOCK)
							JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = SWOP.ItemMasterId
						 WHERE SubWOPartNoId = @SubWorkOrderPartNoId;
						
						SELECT @SubWorkOrderNum = SubWorkOrderNo FROM dbo.SubWorkOrder WITH(NOLOCK) WHERE SubWorkOrderId = @historysUBWorkOrderId;
						SELECT @ConditionCode = Code FROM dbo.Condition WITH(NOLOCK) WHERE ConditionId = @ConditionId;
						SELECT @HistoryStockLineNum = StockLineNumber FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId = @HistoryStockLineId;

						SELECT @historyEmployeeName = (FirstName +' '+ LastName) FROM dbo.Employee WITH(NOLOCK) WHERE EmployeeId = @historyReservedById;
						SELECT @HistoryQtyReserved = CAST(QuantityReserved AS VARCHAR) FROM dbo.SubWorkOrderMaterials WOM WITH(NOLOCK) JOIN #tmpIssueSWOMaterialsStocklineWithoutKit tmpWOM ON tmpWOM.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND tmpWOM.ID = @count;

						SET @historytotalReserved = (CAST(@HistoryQtyReserved AS BIGINT) + CAST(@HistoryQuantityActReserved AS BIGINT));
						
						SET @TemplateBody = REPLACE(@TemplateBody, '##PN##', ISNULL(@Partnumber,''));
						SET @TemplateBody = REPLACE(@TemplateBody, '##MPN##', ISNULL(@MPNPartnumber,''));
						SET @TemplateBody = REPLACE(@TemplateBody, '##Qty##', ISNULL(@historyQuantityActIssued,0));

						SET @OldValue= '';--(SELECT Cast(@historyQuantity  as varchar))
						SET @NewValue= 'ISSUED PARTS';--(SELECT Cast(@historyQtyToBeReserved  as varchar))
						
						IF @KITID = 0
						BEGIN
							EXEC [dbo].[USP_History] @historyModuleId,@historySubWorkOrderId,@historySubModuleId,@SubWorkOrderPartNoId,@OldValue,@NewValue,@TemplateBody,'IssuedParts',@historyMasterCompanyId,@UpdateBy,NULL,@UpdateBy,NULL;
						END

						-- Sub Work Order Accounting Batch Entry --

						IF(ISNULL(@WOTypeId,0) = @CustomerWOTypeId)
						BEGIN
							IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId = @DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
							BEGIN
								EXEC [dbo].[USP_BatchTriggerBasedonDistributionForSubWorkOrder] @DistributionMasterId,@ReferenceId,@ReferencePartId,@SubReferenceId,0,@StocklineId,@IssueQty,'',@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdateBy
							END
						END

						IF(ISNULL(@WOTypeId,0) = @InternalWOTypeId)
						BEGIN
							IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
							BEGIN
								EXEC [dbo].[USP_BatchTriggerBasedonDistributionForInternalSubWorkOrder] @DistributionMasterId,@ReferenceId,@ReferencePartId,@SubReferenceId,0,@StocklineId,@IssueQty,'',@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdateBy
							END
						END

						SET @slcount = @slcount + 1;
					END;

					SELECT * FROM #tmpIgnoredStockline

					IF OBJECT_ID(N'tempdb..#tmpIgnoredStockline') IS NOT NULL
					BEGIN
					DROP TABLE #tmpIgnoredStockline
					END

					IF OBJECT_ID(N'tempdb..#tmpIssueSWOMaterialsStockline') IS NOT NULL
					BEGIN
					DROP TABLE #tmpIssueSWOMaterialsStockline
					END

					IF OBJECT_ID(N'tempdb..#tmpIssueSWOMaterialsStocklineKit') IS NOT NULL
					BEGIN
						DROP TABLE #tmpIssueSWOMaterialsStocklineKit
					END

					IF OBJECT_ID(N'tempdb..#tmpIssueSWOMaterialsStocklineWithoutKit') IS NOT NULL
					BEGIN
						DROP TABLE #tmpIssueSWOMaterialsStocklineWithoutKit
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
              , @AdhocComments     VARCHAR(150)    = 'usp_IssueSubWorkOrderMaterialsStockline' 
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
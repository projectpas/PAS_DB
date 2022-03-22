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

DECLARE @p1 dbo.ReserveWOMaterialsStocklineType

INSERT INTO @p1 values(65,72,87,1073,4,6,1,14,6,N'REPAIR',N'FLYSKY CT6B FS-CT6B',N'USED FOR WING REPAIR',5,3,1,N'CNTL-000463',N'ID_NUM-000001',N'STL-000123',N'',N'ADMIN ADMIN',1)
INSERT INTO @p1 values(65,72,99,2093,25,6,1,14,6,N'REPAIR',N'WAT0303-01',N'70303-01 RECOGNITION LIGHT 28V 25W',3,3,2,N'CNTL-000526',N'ID_NUM-000001',N'STL-000009',N'',N'ADMIN ADMIN',1)
INSERT INTO @p1 values(65,72,10099,510,15,34,2,14,6,N'INSPECTED',N'AIR-MAZE',N'AIR-MAZE U2-849 AERONCA AIR FILTER',10,7,1,N'CNTL-000308',N'ID_NUM-000001',N'STL-000072',N'',N'ADMIN ADMIN',1)
INSERT INTO @p1 values(65,72,10099,512,15,34,2,14,6,N'INSPECTED',N'AIR-MAZE',N'AIR-MAZE U2-849 AERONCA AIR FILTER',10,7,1,N'CNTL-000310',N'ID_NUM-000001',N'STL-000072',N'',N'ADMIN ADMIN',0)
INSERT INTO @p1 values(65,72,10099,513,15,34,2,14,6,N'INSPECTED',N'AIR-MAZE',N'AIR-MAZE U2-849 AERONCA AIR FILTER',10,7,1,N'CNTL-000311',N'ID_NUM-000001',N'STL-000072',N'',N'ADMIN ADMIN',0)

EXEC dbo.usp_IssueSubWorkOrderMaterialsStockline @tbl_MaterialsStocklineType=@p1


**************************************************************/ 
CREATE PROCEDURE [dbo].[usp_IssueSubWorkOrderMaterialsStockline]
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
					DECLARE @PartStatus INT;
					DECLARE @SubWorkOrderMaterialsId BIGINT;
					DECLARE @IsSerialised BIT;
					DECLARE @stockLineQty INT;
					DECLARE @stockLineQtyAvailable INT;

					SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 16; -- For SUB WORK ORDER Module
					SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 33; -- For SUB WORK ORDER Materials Module
					SET @PartStatus = 2; -- FOR Issue
					SET @IsAddUpdate = 0;
					SET @ExecuteParentChild = 1;
					SET @UpdateQuantities = 1;
					SET @IsOHUpdated = 0;
					SET @AddHistoryForNonSerialized = 0;					
					SET @slcount = 1;
					SET @count = 1;

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
								 [IsSerialized] BIT
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

					INSERT INTO #tmpIssueSWOMaterialsStockline ([WorkOrderId],[SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
							[TaskId], [Condition], [PartNumber], [PartDescription], [Quantity], [QtyToBeReserved], [QuantityActIssued], [ControlNo], [ControlId],
							[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UpdatedById],  [UnitCost], [IsSerialized])
					SELECT tblMS.[WorkOrderId],tblMS.[SubWorkOrderId], tblMS.[SubWOPartNoId], tblMS.[SubWorkOrderMaterialsId], tblMS.[StockLineId], tblMS.[ItemMasterId], tblMS.[ConditionId], [ProvisionId], 
							[TaskId], tblMS.[Condition], tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], [QtyToBeReserved], [QuantityActIssued], [ControlNo], [ControlId],
							tblMS.[StockLineNumber], tblMS.[SerialNumber], [ReservedBy], [IsStocklineAdded], SL.MasterCompanyId, [ReservedBy], [ReservedById], SL.UnitCost, SL.isSerialized
					FROM @tbl_MaterialsStocklineType tblMS  JOIN dbo.Stockline SL ON SL.StockLineId = tblMS.StockLineId 
					WHERE SL.QuantityOnHand > 0 AND SL.QuantityOnHand >= tblMS.QuantityActIssued

					SELECT @TotalCounts = COUNT(ID) FROM #tmpIssueSWOMaterialsStockline;

					INSERT INTO #tmpIgnoredStockline ([PartNumber], [Condition], [ControlNo], [ControlId], [StockLineNumber]) 
					SELECT tblMS.[PartNumber], tblMS.[Condition], tblMS.[ControlNo], tblMS.[ControlId], tblMS.[StockLineNumber] FROM @tbl_MaterialsStocklineType tblMS  
					WHERE tblMS.StockLineId NOT IN (SELECT StockLineId FROM #tmpIssueSWOMaterialsStockline)
		
					--UPDATE SUB WORK ORDER MATERIALS DETAILS
					WHILE @count<= @TotalCounts
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
					
					--UPDATE/INSERT SUB WORK ORDER MATERIALS STOCKLINE DETAILS
					IF(@TotalCounts > 0 )
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

					--FOR UPDATED SUB WORK ORDER MATERIALS STOCKLINE QTY
					UPDATE dbo.SubWorkOrderMaterialStockLine 
					SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
					FROM dbo.SubWorkOrderMaterialStockLine WOMS JOIN #tmpIssueSWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.SubWorkOrderMaterialsId = tmpRSL.SubWorkOrderMaterialsId 
					WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 
					
					--FOR UPDATED STOCKLINE QTY
					UPDATE dbo.Stockline
					SET QuantityOnHand = ISNULL(SL.QuantityOnHand, 0) - ISNULL(tmpRSL.QuantityActIssued,0),
						QuantityReserved = ISNULL(SL.QuantityReserved,0) - ISNULL(tmpRSL.QuantityActIssued,0),
                        QuantityIssued = ISNULL(SL.QuantityIssued,0) + ISNULL(tmpRSL.QuantityActIssued,0)						
					FROM dbo.Stockline SL JOIN #tmpIssueSWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
					
					--FOR UPDATE TOTAL SUB WORK ORDER COST
					WHILE @count<= @TotalCounts
					BEGIN
						SELECT	@SubWorkOrderMaterialsId = tmpWOM.SubWorkOrderMaterialsId
						FROM #tmpIssueSWOMaterialsStockline tmpWOM 
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
								@SubReferenceId = tmpWOM.SubWorkOrderMaterialsId
						FROM #tmpIssueSWOMaterialsStockline tmpWOM 
						WHERE tmpWOM.ID = @slcount

						SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId

						IF (@IsSerialised = 0 AND (@stockLineQtyAvailable > 1 OR @stockLineQty > 1))
						BEGIN
							EXEC [dbo].[USP_CreateChildStockline]  @StocklineId = @StocklineId, @MasterCompanyId = @MasterCompanyId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @IsAddUpdate = @IsAddUpdate, @ExecuteParentChild = @ExecuteParentChild, @UpdateQuantities = @UpdateQuantities, @IsOHUpdated = @IsOHUpdated, @AddHistoryForNonSerialized = @AddHistoryForNonSerialized, @SubModuleId = @SubModuleId, @SubReferenceId = @SubReferenceId
						END
						ELSE
						BEGIN
							EXEC [dbo].[USP_CreateChildStockline]  @StocklineId = @StocklineId, @MasterCompanyId = @MasterCompanyId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @IsAddUpdate = 0, @ExecuteParentChild = 0, @UpdateQuantities = 0, @IsOHUpdated = 1, @AddHistoryForNonSerialized = 0, @SubModuleId = @SubModuleId, @SubReferenceId = @SubReferenceId
						END

						SET @slcount = @slcount + 1;
					END;

					SELECT * FROM #tmpIgnoredStockline

					IF OBJECT_ID(N'tempdb..#tmpIgnoredStockline') IS NOT NULL
					BEGIN
					DROP TABLE #tmpIgnoredStockline
					END

					IF OBJECT_ID(N'tempdb..#tmpReserveSWOMaterialsStockline') IS NOT NULL
					BEGIN
					DROP TABLE #tmpReserveSWOMaterialsStockline
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
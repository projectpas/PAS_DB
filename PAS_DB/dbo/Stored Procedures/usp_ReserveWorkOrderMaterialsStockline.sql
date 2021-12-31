
/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <12/30/2021>  
** Description: <Save Work Order Materials reserve Stockline Details>  
  
EXEC [usp_ReserveWorkOrderMaterialsStockline] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    12/30/2021  HEMANT SALIYA    Save Work Order Materials reserve Stockline Details

DECLARE @p1 dbo.ReserveWOMaterialsStocklineType

INSERT INTO @p1 values(65,72,87,1073,4,6,1,14,6,N'REPAIR',N'FLYSKY CT6B FS-CT6B',N'USED FOR WING REPAIR',5,3,1,N'CNTL-000463',N'ID_NUM-000001',N'STL-000123',N'',N'ADMIN ADMIN',1)
INSERT INTO @p1 values(65,72,99,2093,25,6,1,14,6,N'REPAIR',N'WAT0303-01',N'70303-01 RECOGNITION LIGHT 28V 25W',3,3,2,N'CNTL-000526',N'ID_NUM-000001',N'STL-000009',N'',N'ADMIN ADMIN',1)
INSERT INTO @p1 values(65,72,10099,510,15,34,2,14,6,N'INSPECTED',N'AIR-MAZE',N'AIR-MAZE U2-849 AERONCA AIR FILTER',10,7,1,N'CNTL-000308',N'ID_NUM-000001',N'STL-000072',N'',N'ADMIN ADMIN',1)
INSERT INTO @p1 values(65,72,10099,512,15,34,2,14,6,N'INSPECTED',N'AIR-MAZE',N'AIR-MAZE U2-849 AERONCA AIR FILTER',10,7,1,N'CNTL-000310',N'ID_NUM-000001',N'STL-000072',N'',N'ADMIN ADMIN',0)
INSERT INTO @p1 values(65,72,10099,513,15,34,2,14,6,N'INSPECTED',N'AIR-MAZE',N'AIR-MAZE U2-849 AERONCA AIR FILTER',10,7,1,N'CNTL-000311',N'ID_NUM-000001',N'STL-000072',N'',N'ADMIN ADMIN',0)

EXEC dbo.usp_ReserveWorkOrderMaterialsStockline @tbl_MaterialsStocklineType=@p1


**************************************************************/ 
CREATE PROCEDURE [dbo].[usp_ReserveWorkOrderMaterialsStockline]
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

					SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 15; -- For WORK ORDER Module
					SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 31; -- For WORK ORDER Materials Module
					SET @ReservePartStatus = 1; -- FOR RESERTVE
					SET @IsAddUpdate = 0;
					SET @ExecuteParentChild = 1;
					SET @UpdateQuantities = 1;
					SET @IsOHUpdated = 0;
					SET @AddHistoryForNonSerialized = 1;					
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
								 [IsSerialized] BIT
							)

					INSERT INTO #tmpReserveWOMaterialsStockline ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
							[TaskId], [ReservedById], [Condition], [PartNumber], [PartDescription], [Quantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
							[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UnitCost], [IsSerialized])
					SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], tblMS.[StockLineId], tblMS.[ItemMasterId], tblMS.[ConditionId], [ProvisionId], 
							[TaskId], [ReservedById], tblMS.[Condition], tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
							tblMS.[StockLineNumber], tblMS.[SerialNumber], [ReservedBy], [IsStocklineAdded], SL.MasterCompanyId, [ReservedBy], SL.UnitCost, SL.isSerialized
					FROM @tbl_MaterialsStocklineType tblMS  JOIN dbo.Stockline SL ON SL.StockLineId = tblMS.StockLineId 
					WHERE SL.QuantityAvailable > 0 AND SL.QuantityAvailable >= tblMS.QuantityActReserved

					SELECT @TotalCounts = COUNT(ID) FROM #tmpReserveWOMaterialsStockline;
		
					--UPDATE WORK ORDER MATERIALS DETAILS
					WHILE @count<= @TotalCounts
					BEGIN
						UPDATE WorkOrderMaterials 
							SET QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.QuantityActReserved,0),
								TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.QuantityActReserved,0),
								ReservedById = tmpWOM.ReservedById, 
								ReservedDate = GETDATE(), 
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
							SET TARGET.QtyReserved = ISNULL(TARGET.QtyReserved, 0) + ISNULL(SOURCE.QuantityActReserved, 0),
								TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * TARGET.UnitCost,
								TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * TARGET.UnitCost,
								TARGET.UpdatedDate = GETDATE(),
								TARGET.UpdatedBy = SOURCE.ReservedBy
						WHEN NOT MATCHED BY TARGET 
							THEN INSERT (StocklineId, WorkOrderMaterialsId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
							VALUES (SOURCE.StocklineId, SOURCE.WorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.QuantityActReserved, SOURCE.QuantityActReserved, 0, SOURCE.UnitCost, (ISNULL(SOURCE.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0);
					END

					--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
					UPDATE dbo.WorkOrderMaterialStockLine 
					SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
					FROM dbo.WorkOrderMaterialStockLine WOMS JOIN #tmpReserveWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId 
					WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 
					
					--FOR UPDATED STOCKLINE QTY
					UPDATE dbo.Stockline
					SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) - ISNULL(tmpRSL.QuantityActReserved,0),
                        QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(tmpRSL.QuantityActReserved,0),
						WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
					FROM dbo.Stockline SL JOIN #tmpReserveWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId

					--FOR STOCK LINE HISTORY
					WHILE @slcount<= @TotalCounts
					BEGIN
						SELECT	@StocklineId = tmpWOM.StockLineId,
								@MasterCompanyId = tmpWOM.MasterCompanyId,
								@ReferenceId = tmpWOM.WorkOrderId,
								@SubReferenceId = tmpWOM.WorkOrderMaterialsId
						FROM #tmpReserveWOMaterialsStockline tmpWOM 
						WHERE tmpWOM.ID = @slcount

						EXEC [dbo].[USP_CreateChildStockline]  @StocklineId = @StocklineId, @MasterCompanyId = @MasterCompanyId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @IsAddUpdate = @IsAddUpdate, @ExecuteParentChild = @ExecuteParentChild, @UpdateQuantities = @UpdateQuantities, @IsOHUpdated = @IsOHUpdated, @AddHistoryForNonSerialized = @AddHistoryForNonSerialized, @SubModuleId = @SubModuleId, @SubReferenceId = @SubReferenceId
						
						SET @slcount = @slcount + 1;
						PRINT @slcount;
					END;

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
              , @AdhocComments     VARCHAR(150)    = 'usp_ReserveWorkOrderMaterialsStockline' 
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
/*************************************************************           
 ** File:   [USP_BulkStockLineAdjustmentDetails_AddUpdate]           
 ** Author: AMIT GHEDIYA
 ** Description: This stored procedure is used to Add & Update Bulk StockLine Adjustment Details
 ** Date:   10/10/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 ******************************************************************************           
  ** Change History           
 ******************************************************************************           
 ** PR   Date         Author  		  Change Description            
 ** --   --------     -------		  ---------------------------     
    1    10/10/2023   AMIT GHEDIYA     Created
	2    16/10/2023   AMIT GHEDIYA     added UnitCost adjustment.
	3    24/10/2023   AMIT GHEDIYA     added Intra Company adjustment.
	4    20/12/2023   BHARGAV SALIYA   added Customer Stock adjustment.
	5    22/12/2023   BHARGAV SALIYA   added Customer Stock adjustment.
	6    20/03/2024   Abhishek Jirawla Added reserve Quantity and history when a stock is transfered Inter/Intra company and transfer Customer Stock

*******************************************************************************/
CREATE      PROCEDURE [dbo].[USP_BulkStockLineAdjustmentDetails_AddUpdate]
	@BulkStkLineAdjHeaderId BIGINT,
	@CreatedBy VARCHAR(50),
	@UpdatedBy VARCHAR(50),
	@MasterCompanyId INT,
	@BulkStockLineAdjustmentDetails BulkStockLineAdjustmentDetailsType READONLY
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY    
	BEGIN TRANSACTION

		DECLARE @MasterLoopID INT,
				@BulkStockLineAdjustmentDetailsId BIGINT,
				@Qty INT,
				@NewQty INT,
				@QtyAdjustment INT,
				@UnitCost DECIMAL(18,2),
				@NewUnitCost DECIMAL(18,2),
				@UnitCostAdjustment DECIMAL(18,2),
				@AdjustmentAmount DECIMAL(18,2),
				@FreightAdjustment DECIMAL(18,2),
				@TaxAdjustment DECIMAL(18,2),
				@IsDeleted BIT,
				@StandAloneCreditMemoDetailsId BIGINT,
				@ManagementStructureId BIGINT,
				@FromManagementStructureId BIGINT,
				@ToManagementStructureId BIGINT,
				@LastMSLevel VARCHAR(256),
				@AllMSlevels VARCHAR(256),
				@ModuleId INT,
				@StockLineAdjustmentTypeId INT,
				@NewUnitCostTotransfer DECIMAL(18,2),
				@QuantityOnHand DECIMAL(18,2),
				@UnitOfMeasure VARCHAR(100),
				@BulkStockAdjusmentStocklineId BIGINT,
				@BulkStockModuleId INT;

		SELECT @ModuleId = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName='BulkStocklineAdjustmnet';
		SELECT @BulkStockModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName='BulkStockAdjustments';

	    IF OBJECT_ID(N'tempdb..#tmpBulkStockLineAdjustmentDetails') IS NOT NULL
		BEGIN
			DROP TABLE #tmpBulkStockLineAdjustmentDetails
		END
				
		CREATE TABLE #tmpBulkStockLineAdjustmentDetails
		(
			[ID] INT IDENTITY,
			[BulkStockLineAdjustmentDetailsId] [bigint] NULL,
			[BulkStkLineAdjId] [bigint] NOT NULL,
			[StockLineId] [bigint] NULL,
			[Qty] [int] NOT NULL,
			[NewQty] [int] NULL,
			[QtyAdjustment] [int] NULL,
			[UnitCost] [decimal](18,2) NULL,
			[NewUnitCost] [decimal](18,2) NULL,
			[UnitCostAdjustment] [decimal](18,2) NULL,
			[AdjustmentAmount] [decimal](18,2) NULL,
			[FreightAdjustment] [decimal](18,2) NULL,
			[TaxAdjustment] [decimal](18,2) NULL,
			[StockLineAdjustmentTypeId] [int] NOT NULL,
			[ManagementStructureId] [bigint] NULL,
			[FromManagementStructureId] [bigint] NULL,
			[ToManagementStructureId] [bigint] NULL,
			[LastMSLevel] [varchar](200) NULL,
			[AllMSlevels] [varchar](MAX) NULL,
			[IsDeleted] [bit] NOT NULL,
			[NewUnitCostTotransfer] [decimal](18, 2) NULL,
			[QuantityOnHand] [decimal](18, 2) NULL,
			[UnitOfMeasure] [varchar](100) NULL
		)

		INSERT INTO #tmpBulkStockLineAdjustmentDetails ([BulkStockLineAdjustmentDetailsId],[BulkStkLineAdjId],[StockLineId],[Qty],[NewQty],[QtyAdjustment],[UnitCost],[NewUnitCost],[UnitCostAdjustment],[AdjustmentAmount],[FreightAdjustment],[TaxAdjustment],[StockLineAdjustmentTypeId],[IsDeleted],
													 [ManagementStructureId],[FromManagementStructureId],[ToManagementStructureId],[LastMSLevel],[AllMSlevels],[NewUnitCostTotransfer],[QuantityOnHand],[UnitOfMeasure])
		SELECT [BulkStockLineAdjustmentDetailsId],[BulkStkLineAdjId],[StockLineId],[Qty],[NewQty],[QtyAdjustment],[UnitCost],[NewUnitCost],[UnitCostAdjustment],[AdjustmentAmount],[FreightAdjustment],[TaxAdjustment],[StockLineAdjustmentTypeId],[IsDeleted],
													 [ManagementStructureId],[FromManagementStructureId],[ToManagementStructureId],[LastMSLevel],[AllMSlevels],[NewUnitCostTotransfer],[QuantityOnHand],[UnitOfMeasure] FROM @BulkStockLineAdjustmentDetails;

		SELECT  @MasterLoopID = MAX(ID) FROM #tmpBulkStockLineAdjustmentDetails

		WHILE(@MasterLoopID > 0)
		BEGIN
			SELECT @BulkStockLineAdjustmentDetailsId = [BulkStockLineAdjustmentDetailsId],
				   @NewQty = NewQty,
				   @QtyAdjustment = QtyAdjustment,
				   @UnitCost = UnitCost,
				   @NewUnitCost = NewUnitCost,
				   @UnitCostAdjustment = UnitCostAdjustment,
				   @AdjustmentAmount = AdjustmentAmount,
				   @FreightAdjustment = FreightAdjustment,
				   @TaxAdjustment = TaxAdjustment,
				   @ManagementStructureId = ManagementStructureId,
				   @FromManagementStructureId = FromManagementStructureId,
				   @ToManagementStructureId = ToManagementStructureId,
				   @LastMSLevel = LastMSLevel,
				   @AllMSlevels = AllMSlevels,
				   @IsDeleted = IsDeleted,
				   @StockLineAdjustmentTypeId = StockLineAdjustmentTypeId,
				   @NewUnitCostTotransfer = NewUnitCostTotransfer,
				   @QuantityOnHand = QuantityOnHand,
				   @UnitOfMeasure = UnitOfMeasure

			FROM #tmpBulkStockLineAdjustmentDetails WHERE [ID] = @MasterLoopID;
			
			IF(@BulkStockLineAdjustmentDetailsId = 0)
			BEGIN 
				IF(@StockLineAdjustmentTypeId = 1) -- For Quntity
				BEGIN
					INSERT INTO [dbo].[BulkStockLineAdjustmentDetails]([BulkStkLineAdjId],[StockLineId],[Qty],[NewQty],[QtyAdjustment],[UnitCost],[AdjustmentAmount],[FreightAdjustment],[TaxAdjustment],[StockLineAdjustmentTypeId],
																[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],
																[ManagementStructureId],[FromManagementStructureId],[ToManagementStructureId],[LastMSLevel],[AllMSlevels])
										SELECT [BulkStkLineAdjId],[StockLineId],[Qty],[NewQty],[QtyAdjustment],[UnitCost],[AdjustmentAmount],[FreightAdjustment],[TaxAdjustment],[StockLineAdjustmentTypeId],
												@MasterCompanyId,@CreatedBy,GETUTCDATE(),@UpdatedBy,GETUTCDATE(),1,0,
												[ManagementStructureId],[FromManagementStructureId],[ToManagementStructureId],[LastMSLevel],[AllMSlevels]
										FROM #tmpBulkStockLineAdjustmentDetails WHERE [ID] = @MasterLoopID;
				END
				ELSE IF(@StockLineAdjustmentTypeId = 2) -- For UnitCost
				BEGIN
					INSERT INTO [dbo].[BulkStockLineAdjustmentDetails]([BulkStkLineAdjId],[StockLineId],[Qty],[NewQty],[QtyAdjustment],[UnitCost],[NewUnitCost],[UnitCostAdjustment],[AdjustmentAmount],[FreightAdjustment],[TaxAdjustment],[StockLineAdjustmentTypeId],
															[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],
															[ManagementStructureId],[LastMSLevel],[AllMSlevels])
							        SELECT [BulkStkLineAdjId],[StockLineId],[Qty],NULL,NULL,[UnitCost],[NewUnitCost],[UnitCostAdjustment],[AdjustmentAmount],[FreightAdjustment],[TaxAdjustment],[StockLineAdjustmentTypeId],
											@MasterCompanyId,@CreatedBy,GETUTCDATE(),@UpdatedBy,GETUTCDATE(),1,0,
											[ManagementStructureId],[LastMSLevel],[AllMSlevels]
									FROM #tmpBulkStockLineAdjustmentDetails WHERE [ID] = @MasterLoopID;
				END
				ELSE IF(@StockLineAdjustmentTypeId = 3 OR @StockLineAdjustmentTypeId = 4)  -- For Quantity and Inter/Intra Company transfer
				BEGIN
					INSERT INTO [dbo].[BulkStockLineAdjustmentDetails]([BulkStkLineAdjId],[StockLineId],[Qty],[NewQty],[QtyAdjustment],[UnitCost],[AdjustmentAmount],[FreightAdjustment],[TaxAdjustment],[StockLineAdjustmentTypeId],
																[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],
																[ManagementStructureId],[FromManagementStructureId],[ToManagementStructureId],[LastMSLevel],[AllMSlevels])
										SELECT [BulkStkLineAdjId],[StockLineId],[Qty],[NewQty],[QtyAdjustment],[UnitCost],[AdjustmentAmount],[FreightAdjustment],[TaxAdjustment],[StockLineAdjustmentTypeId],
												@MasterCompanyId,@CreatedBy,GETUTCDATE(),@UpdatedBy,GETUTCDATE(),1,0,
												[ManagementStructureId],[FromManagementStructureId],[ToManagementStructureId],[LastMSLevel],[AllMSlevels]
										FROM #tmpBulkStockLineAdjustmentDetails WHERE [ID] = @MasterLoopID;					

					SELECT @BulkStockAdjusmentStocklineId = StocklineId FROM #tmpBulkStockLineAdjustmentDetails WHERE [ID] = @MasterLoopID;

					UPDATE Stockline
					SET QuantityReserved = QuantityReserved + @NewQty,
						QuantityAvailable = QuantityAvailable - @NewQty
					WHERE StockLineId = @BulkStockAdjusmentStocklineId;

					EXEC USP_AddUpdateStocklineHistory @BulkStockAdjusmentStocklineId, @BulkStockModuleId, NULL, NULL, NULL, 2, @NewQty, @UpdatedBy;
					
					
				END

				ELSE IF(@StockLineAdjustmentTypeId = 5) -- For Customer Stock
				BEGIN
					INSERT INTO [dbo].[BulkStockLineAdjustmentDetails]([BulkStkLineAdjId],[StockLineId],[Qty],[NewQty],[QtyAdjustment],[UnitCost],[NewUnitCost],[UnitCostAdjustment],[AdjustmentAmount],[FreightAdjustment],[TaxAdjustment],[StockLineAdjustmentTypeId],
															[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],
															[ManagementStructureId],[FromManagementStructureId],[ToManagementStructureId],[LastMSLevel],[AllMSlevels],[NewUnitCostTotransfer],[QuantityOnHand],[UnitOfMeasure])
							        SELECT [BulkStkLineAdjId],[StockLineId],[Qty],[NewQty],NULL,[UnitCost],NULL,NULL,[AdjustmentAmount],NULL,NULL,[StockLineAdjustmentTypeId],
											@MasterCompanyId,@CreatedBy,GETUTCDATE(),@UpdatedBy,GETUTCDATE(),1,0,
											[ManagementStructureId],[FromManagementStructureId],[ToManagementStructureId],[LastMSLevel],[AllMSlevels],[NewUnitCostTotransfer],[QuantityOnHand],[UnitOfMeasure]
									FROM #tmpBulkStockLineAdjustmentDetails WHERE [ID] = @MasterLoopID;

					SELECT @BulkStockAdjusmentStocklineId = StocklineId FROM #tmpBulkStockLineAdjustmentDetails WHERE [ID] = @MasterLoopID;

					UPDATE Stockline
					SET QuantityReserved = QuantityReserved + @NewQty,
						QuantityAvailable = QuantityAvailable - @NewQty
					WHERE StockLineId = @BulkStockAdjusmentStocklineId;

					EXEC USP_AddUpdateStocklineHistory @BulkStockAdjusmentStocklineId, @BulkStockModuleId, NULL, NULL, NULL, 2, @NewQty, @UpdatedBy;

					
				END


				SELECT @BulkStockLineAdjustmentDetailsId = SCOPE_IDENTITY();

				--Add into PROCAddUpdateCustomerRMAMSData
				EXEC PROCAddUpdateCustomerRMAMSData @BulkStockLineAdjustmentDetailsId,@ManagementStructureId,@MasterCompanyId,@CreatedBy,@UpdatedBy,@ModuleId,1,0
			END
			ELSE IF(@BulkStockLineAdjustmentDetailsId > 0)
			BEGIN 
				IF(@StockLineAdjustmentTypeId = 1) -- For Quntity
				BEGIN
					UPDATE [dbo].[BulkStockLineAdjustmentDetails] 
					SET [NewQty] = @NewQty,
						[QtyAdjustment] = @QtyAdjustment,
						[AdjustmentAmount] = @AdjustmentAmount,
						[UpdatedBy] = @UpdatedBy,
						[UpdatedDate] = GETUTCDATE(),
						[ManagementStructureId] = @ManagementStructureId,
						[FromManagementStructureId] = @FromManagementStructureId,
						[ToManagementStructureId] = @ToManagementStructureId,
						[LastMSLevel] = @LastMSLevel,
						[AllMSlevels] = @AllMSlevels
					WHERE BulkStkLineAdjDetailsId = @BulkStockLineAdjustmentDetailsId;
				END
				ELSE IF(@StockLineAdjustmentTypeId = 2)-- For UnitCost
				BEGIN
					UPDATE [dbo].[BulkStockLineAdjustmentDetails] 
					SET [NewUnitCost] = @NewUnitCost,
						[UnitCostAdjustment] = @UnitCostAdjustment,
						[AdjustmentAmount] = @AdjustmentAmount,
						[FreightAdjustment] = @FreightAdjustment,
				        [TaxAdjustment] = @TaxAdjustment,
						[UpdatedBy] = @UpdatedBy,
						[UpdatedDate] = GETUTCDATE(),
						[ManagementStructureId] = @ManagementStructureId,
						[LastMSLevel] = @LastMSLevel,
						[AllMSlevels] = @AllMSlevels
					WHERE BulkStkLineAdjDetailsId = @BulkStockLineAdjustmentDetailsId;
				END
				ELSE IF(@StockLineAdjustmentTypeId = 3 OR @StockLineAdjustmentTypeId = 4) -- For Quantity and Inter/Intra Company transfer
				BEGIN
					UPDATE [dbo].[BulkStockLineAdjustmentDetails] 
					SET [NewQty] = @NewQty,
						[QtyAdjustment] = @QtyAdjustment,
						[AdjustmentAmount] = @AdjustmentAmount,
						[UpdatedBy] = @UpdatedBy,
						[UpdatedDate] = GETUTCDATE(),
						[ManagementStructureId] = @ManagementStructureId,
						[FromManagementStructureId] = @FromManagementStructureId,
						[ToManagementStructureId] = @ToManagementStructureId,
						[LastMSLevel] = @LastMSLevel,
						[AllMSlevels] = @AllMSlevels
					WHERE BulkStkLineAdjDetailsId = @BulkStockLineAdjustmentDetailsId;

					SELECT @BulkStockAdjusmentStocklineId = StocklineId FROM [dbo].[BulkStockLineAdjustmentDetails] WHERE BulkStkLineAdjDetailsId = @BulkStockLineAdjustmentDetailsId;

					UPDATE Stockline
					SET QuantityReserved = QuantityReserved + @NewQty,
						QuantityAvailable = QuantityAvailable - @NewQty
					WHERE StockLineId = @BulkStockAdjusmentStocklineId

					EXEC USP_AddUpdateStocklineHistory @BulkStockAdjusmentStocklineId, @BulkStockModuleId, NULL, NULL, NULL, 2, @NewQty, @UpdatedBy;
					
				END

				ELSE IF(@StockLineAdjustmentTypeId = 5)-- For CustomerStock
				BEGIN
					UPDATE [dbo].[BulkStockLineAdjustmentDetails] 
					SET [NewQty] = @NewQty,
						[NewUnitCostTotransfer] = @NewUnitCostTotransfer,
						[UpdatedBy] = @UpdatedBy,
						[UpdatedDate] = GETUTCDATE(),
						[ManagementStructureId] = @ManagementStructureId,
						[LastMSLevel] = @LastMSLevel,
						[AllMSlevels] = @AllMSlevels
					WHERE BulkStkLineAdjDetailsId = @BulkStockLineAdjustmentDetailsId;

					SELECT @BulkStockAdjusmentStocklineId = StocklineId FROM [dbo].[BulkStockLineAdjustmentDetails] WHERE BulkStkLineAdjDetailsId = @BulkStockLineAdjustmentDetailsId;

					UPDATE Stockline
					SET QuantityReserved = QuantityReserved + @NewQty,
						QuantityAvailable = QuantityAvailable - @NewQty
					WHERE StockLineId = @BulkStockAdjusmentStocklineId

					EXEC USP_AddUpdateStocklineHistory @BulkStockAdjusmentStocklineId, @BulkStockModuleId, NULL, NULL, NULL, 2, @NewQty, @UpdatedBy;
				END


				--Update Existing PROCAddUpdateCustomerRMAMSData
				EXEC PROCAddUpdateCustomerRMAMSData @BulkStockLineAdjustmentDetailsId,@ManagementStructureId,@MasterCompanyId,@CreatedBy,@UpdatedBy,@ModuleId,2,0
			END

			--Update Header table with StockLineAdjustmentTypeId
			UPDATE [dbo].[BulkStockLineAdjustment] SET StockLineAdjustmentTypeId = @StockLineAdjustmentTypeId
			WHERE BulkStkLineAdjId = @BulkStkLineAdjHeaderId;

			--Delete detail records
			IF(@IsDeleted > 0)
			BEGIN
				UPDATE [dbo].[BulkStockLineAdjustmentDetails] SET IsActive = 0,IsDeleted = 1 
				WHERE BulkStkLineAdjDetailsId = @BulkStockLineAdjustmentDetailsId;
			END

			SET @MasterLoopID = @MasterLoopID - 1;
	   END

	   SELECT @BulkStkLineAdjHeaderId AS BulkStkLineAdjHeaderId;

	COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRANSACTION;
		    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_BulkStockLineAdjustmentDetails_AddUpdate]'			
			,@ProcedureParameters VARCHAR(3000) = '@BulkStkLineAdjHeaderId = ''' + CAST(ISNULL(@BulkStkLineAdjHeaderId, '') AS varchar(100))				 
            ,@ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END
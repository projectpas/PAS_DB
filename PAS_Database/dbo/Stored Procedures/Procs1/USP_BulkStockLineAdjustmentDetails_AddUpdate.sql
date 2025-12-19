


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
	7    01/04/2024   Abhishek Jirawla Added unreserve the quantity when deleted is true
	8    24/09/2024   RAJESH GAMI      Added @BulkStkLineAdjHeaderId(Adjement number as a reference) into stockline history 
	9    22/01/2025   AMIT GHEDIYA     Handle Stockline update when delete item.
	10   16/12/2025   RAJESH GAMI      Quantity Related Fields Change the Type INT to DECIMAL
*******************************************************************************/
CREATE     PROCEDURE [dbo].[USP_BulkStockLineAdjustmentDetails_AddUpdate]
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
				@Qty DECIMAL(18,6),
				@NewQty DECIMAL(18,6),
				@QtyAdjustment DECIMAL(18,6),
				@UnitCost DECIMAL(18,6),
				@NewUnitCost DECIMAL(18,6),
				@UnitCostAdjustment DECIMAL(18,6),
				@AdjustmentAmount DECIMAL(18,6),
				@FreightAdjustment DECIMAL(18,6),
				@TaxAdjustment DECIMAL(18,6),
				@IsDeleted BIT,
				@StandAloneCreditMemoDetailsId BIGINT,
				@ManagementStructureId BIGINT,
				@FromManagementStructureId BIGINT,
				@ToManagementStructureId BIGINT,
				@LastMSLevel VARCHAR(256),
				@AllMSlevels VARCHAR(256),
				@ModuleId INT,
				@StockLineAdjustmentTypeId INT,
				@NewUnitCostTotransfer DECIMAL(18,6),
				@QuantityOnHand DECIMAL(18,6),
				@UnitOfMeasure VARCHAR(100),
				@BulkStockAdjusmentStocklineId BIGINT,
				@BulkStockModuleId INT, 
				@OldQuantity  DECIMAL(18,6),
				@UpdatedQuantity  DECIMAL(18,6),
				@StatusId INT,
				@AdjustmentReasonId BIGINT;

		SELECT @ModuleId = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName='BulkStocklineAdjustmnet';
		SELECT @BulkStockModuleId = [ModuleId]  FROM [DBO].[Module] WITH(NOLOCK) WHERE [CodePrefix] = 'STKADJ';
		SELECT @StatusId = [Id] FROM [DBO].[StocklineAdjustmentStatus] WITH(NOLOCK) WHERE [Name] = 'Posted';

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
			[Qty]  DECIMAL(18,6) NOT NULL,
			[NewQty]  DECIMAL(18,6) NULL,
			[QtyAdjustment]  DECIMAL(18,6) NULL,
			[UnitCost] DECIMAL(18,6) NULL,
			[NewUnitCost] DECIMAL(18,6) NULL,
			[UnitCostAdjustment] DECIMAL(18,6) NULL,
			[AdjustmentAmount] DECIMAL(18,6) NULL,
			[FreightAdjustment] DECIMAL(18,6) NULL,
			[TaxAdjustment] DECIMAL(18,6) NULL,
			[StockLineAdjustmentTypeId] [int] NOT NULL,
			[ManagementStructureId] [bigint] NULL,
			[FromManagementStructureId] [bigint] NULL,
			[ToManagementStructureId] [bigint] NULL,
			[LastMSLevel] [varchar](200) NULL,
			[AllMSlevels] [varchar](MAX) NULL,
			[IsDeleted] [bit] NOT NULL,
			[NewUnitCostTotransfer] DECIMAL(18,6) NULL,
			[QuantityOnHand] DECIMAL(18,6) NULL,
			[UnitOfMeasure] [varchar](100) NULL,
			[AdjustmentReasonId] [bigint] NULL
		)

		INSERT INTO #tmpBulkStockLineAdjustmentDetails ([BulkStockLineAdjustmentDetailsId],[BulkStkLineAdjId],[StockLineId],[Qty],[NewQty],[QtyAdjustment],[UnitCost],[NewUnitCost],[UnitCostAdjustment],[AdjustmentAmount],[FreightAdjustment],[TaxAdjustment],[StockLineAdjustmentTypeId],[IsDeleted],
													 [ManagementStructureId],[FromManagementStructureId],[ToManagementStructureId],[LastMSLevel],[AllMSlevels],[NewUnitCostTotransfer],[QuantityOnHand],[UnitOfMeasure],[AdjustmentReasonId])
		SELECT [BulkStockLineAdjustmentDetailsId],[BulkStkLineAdjId],[StockLineId],[Qty],[NewQty],[QtyAdjustment],[UnitCost],[NewUnitCost],[UnitCostAdjustment],[AdjustmentAmount],[FreightAdjustment],[TaxAdjustment],[StockLineAdjustmentTypeId],[IsDeleted],
													 [ManagementStructureId],[FromManagementStructureId],[ToManagementStructureId],[LastMSLevel],[AllMSlevels],[NewUnitCostTotransfer],[QuantityOnHand],[UnitOfMeasure],[AdjustmentReasonId] FROM @BulkStockLineAdjustmentDetails;

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
				   @UnitOfMeasure = UnitOfMeasure,
				   @AdjustmentReasonId = [AdjustmentReasonId]

			FROM #tmpBulkStockLineAdjustmentDetails WHERE [ID] = @MasterLoopID;
			
			IF(@BulkStockLineAdjustmentDetailsId = 0)
			BEGIN 
				IF(@StockLineAdjustmentTypeId = 1) -- For Quntity
				BEGIN
					INSERT INTO [dbo].[BulkStockLineAdjustmentDetails]([BulkStkLineAdjId],[StockLineId],[Qty],[NewQty],[QtyAdjustment],[UnitCost],[AdjustmentAmount],[FreightAdjustment],[TaxAdjustment],[StockLineAdjustmentTypeId],
																[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],
																[ManagementStructureId],[FromManagementStructureId],[ToManagementStructureId],[LastMSLevel],[AllMSlevels],[AdjustmentReasonId])
										SELECT [BulkStkLineAdjId],[StockLineId],[Qty],[NewQty],[QtyAdjustment],[UnitCost],[AdjustmentAmount],[FreightAdjustment],[TaxAdjustment],[StockLineAdjustmentTypeId],
												@MasterCompanyId,@CreatedBy,GETUTCDATE(),@UpdatedBy,GETUTCDATE(),1,0,
												[ManagementStructureId],[FromManagementStructureId],[ToManagementStructureId],[LastMSLevel],[AllMSlevels],[AdjustmentReasonId]
										FROM #tmpBulkStockLineAdjustmentDetails WHERE [ID] = @MasterLoopID;
				END
				ELSE IF(@StockLineAdjustmentTypeId = 2) -- For UnitCost
				BEGIN
					INSERT INTO [dbo].[BulkStockLineAdjustmentDetails]([BulkStkLineAdjId],[StockLineId],[Qty],[NewQty],[QtyAdjustment],[UnitCost],[NewUnitCost],[UnitCostAdjustment],[AdjustmentAmount],[FreightAdjustment],[TaxAdjustment],[StockLineAdjustmentTypeId],
															[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],
															[ManagementStructureId],[LastMSLevel],[AllMSlevels],[AdjustmentReasonId])
							        SELECT [BulkStkLineAdjId],[StockLineId],[Qty],NULL,NULL,[UnitCost],[NewUnitCost],[UnitCostAdjustment],[AdjustmentAmount],[FreightAdjustment],[TaxAdjustment],[StockLineAdjustmentTypeId],
											@MasterCompanyId,@CreatedBy,GETUTCDATE(),@UpdatedBy,GETUTCDATE(),1,0,
											[ManagementStructureId],[LastMSLevel],[AllMSlevels],[AdjustmentReasonId]
									FROM #tmpBulkStockLineAdjustmentDetails WHERE [ID] = @MasterLoopID;
				END
				ELSE IF(@StockLineAdjustmentTypeId = 3 OR @StockLineAdjustmentTypeId = 4)  -- For Inter/Intra Company transfer
				BEGIN
					INSERT INTO [dbo].[BulkStockLineAdjustmentDetails]([BulkStkLineAdjId],[StockLineId],[Qty],[NewQty],[QtyAdjustment],[UnitCost],[AdjustmentAmount],[FreightAdjustment],[TaxAdjustment],[StockLineAdjustmentTypeId],
																[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],
																[ManagementStructureId],[FromManagementStructureId],[ToManagementStructureId],[LastMSLevel],[AllMSlevels],[AdjustmentReasonId])
										SELECT [BulkStkLineAdjId],[StockLineId],[Qty],[NewQty],[QtyAdjustment],[UnitCost],[AdjustmentAmount],[FreightAdjustment],[TaxAdjustment],[StockLineAdjustmentTypeId],
												@MasterCompanyId,@CreatedBy,GETUTCDATE(),@UpdatedBy,GETUTCDATE(),1,0,
												[ManagementStructureId],[FromManagementStructureId],[ToManagementStructureId],[LastMSLevel],[AllMSlevels],[AdjustmentReasonId]
										FROM #tmpBulkStockLineAdjustmentDetails WHERE [ID] = @MasterLoopID;					

					SELECT @BulkStockAdjusmentStocklineId = StocklineId FROM #tmpBulkStockLineAdjustmentDetails WHERE [ID] = @MasterLoopID;

					UPDATE Stockline
					SET QuantityReserved = QuantityReserved + @NewQty,
						QuantityAvailable = QuantityAvailable - @NewQty
					WHERE StockLineId = @BulkStockAdjusmentStocklineId;

					EXEC USP_AddUpdateStocklineHistory @BulkStockAdjusmentStocklineId, @BulkStockModuleId, @BulkStkLineAdjHeaderId, NULL, NULL, 2, @NewQty, @UpdatedBy;
				END

				ELSE IF(@StockLineAdjustmentTypeId = 5) -- For Customer Stock
				BEGIN
					INSERT INTO [dbo].[BulkStockLineAdjustmentDetails]([BulkStkLineAdjId],[StockLineId],[Qty],[NewQty],[QtyAdjustment],[UnitCost],[NewUnitCost],[UnitCostAdjustment],[AdjustmentAmount],[FreightAdjustment],[TaxAdjustment],[StockLineAdjustmentTypeId],
															[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],
															[ManagementStructureId],[FromManagementStructureId],[ToManagementStructureId],[LastMSLevel],[AllMSlevels],[NewUnitCostTotransfer],[QuantityOnHand],[UnitOfMeasure],[AdjustmentReasonId])
							        SELECT [BulkStkLineAdjId],[StockLineId],[Qty],[NewQty],NULL,[UnitCost],NULL,NULL,[AdjustmentAmount],NULL,NULL,[StockLineAdjustmentTypeId],
											@MasterCompanyId,@CreatedBy,GETUTCDATE(),@UpdatedBy,GETUTCDATE(),1,0,
											[ManagementStructureId],[FromManagementStructureId],[ToManagementStructureId],[LastMSLevel],[AllMSlevels],[NewUnitCostTotransfer],[QuantityOnHand],[UnitOfMeasure],[AdjustmentReasonId]
									FROM #tmpBulkStockLineAdjustmentDetails WHERE [ID] = @MasterLoopID;

					SELECT @BulkStockAdjusmentStocklineId = StocklineId FROM #tmpBulkStockLineAdjustmentDetails WHERE [ID] = @MasterLoopID;

					UPDATE Stockline
					SET QuantityReserved = QuantityReserved + @NewQty,
						QuantityAvailable = QuantityAvailable - @NewQty
					WHERE StockLineId = @BulkStockAdjusmentStocklineId;

					EXEC USP_AddUpdateStocklineHistory @BulkStockAdjusmentStocklineId, @BulkStockModuleId, @BulkStkLineAdjHeaderId, NULL, NULL, 2, @NewQty, @UpdatedBy;					
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
						[AllMSlevels] = @AllMSlevels,
						[AdjustmentReasonId] = @AdjustmentReasonId
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
						[AllMSlevels] = @AllMSlevels,
						[AdjustmentReasonId] = @AdjustmentReasonId
					WHERE BulkStkLineAdjDetailsId = @BulkStockLineAdjustmentDetailsId;
				END
				ELSE IF(@StockLineAdjustmentTypeId = 3 OR @StockLineAdjustmentTypeId = 4) -- For Inter/Intra Company transfer
				BEGIN
					SELECT @OldQuantity = [NewQty] FROM [dbo].[BulkStockLineAdjustmentDetails] WHERE BulkStkLineAdjDetailsId = @BulkStockLineAdjustmentDetailsId;
					IF @OldQuantity > @NewQty
					BEGIN
						SET @UpdatedQuantity = @OldQuantity - @NewQty;
					END
					IF @OldQuantity < @NewQty
					BEGIN
						SET @UpdatedQuantity = @NewQty - @OldQuantity;
					END

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
						[AllMSlevels] = @AllMSlevels,
						[AdjustmentReasonId] = @AdjustmentReasonId
					WHERE BulkStkLineAdjDetailsId = @BulkStockLineAdjustmentDetailsId;

					SELECT @BulkStockAdjusmentStocklineId = StocklineId FROM [dbo].[BulkStockLineAdjustmentDetails] WHERE BulkStkLineAdjDetailsId = @BulkStockLineAdjustmentDetailsId;

					IF @OldQuantity <> @NewQty
					BEGIN
						IF @OldQuantity < @NewQty
						BEGIN 
							UPDATE Stockline
							SET QuantityReserved = QuantityReserved + @UpdatedQuantity,
								QuantityAvailable = QuantityAvailable - @UpdatedQuantity
							WHERE StockLineId = @BulkStockAdjusmentStocklineId

							EXEC USP_AddUpdateStocklineHistory @BulkStockAdjusmentStocklineId, @BulkStockModuleId, @BulkStkLineAdjHeaderId, NULL, NULL, 2, @UpdatedQuantity, @UpdatedBy;
						END
						IF @OldQuantity > @NewQty
						BEGIN
							UPDATE Stockline
							SET QuantityReserved = QuantityReserved - @UpdatedQuantity,
								QuantityAvailable = QuantityAvailable + @UpdatedQuantity
							WHERE StockLineId = @BulkStockAdjusmentStocklineId

							EXEC USP_AddUpdateStocklineHistory @BulkStockAdjusmentStocklineId, @BulkStockModuleId, @BulkStkLineAdjHeaderId, NULL, NULL, 3, @UpdatedQuantity, @UpdatedBy;
						END
					END
				END

				ELSE IF(@StockLineAdjustmentTypeId = 5)-- For CustomerStock
				BEGIN
					SELECT @OldQuantity = [NewQty] FROM [dbo].[BulkStockLineAdjustmentDetails] WHERE BulkStkLineAdjDetailsId = @BulkStockLineAdjustmentDetailsId;
					IF @OldQuantity > @NewQty
					BEGIN
						SET @UpdatedQuantity = @OldQuantity - @NewQty;
					END
					IF @OldQuantity < @NewQty
					BEGIN
						SET @UpdatedQuantity = @NewQty - @OldQuantity;
					END

					UPDATE [dbo].[BulkStockLineAdjustmentDetails] 
					SET [NewQty] = @NewQty,
						[NewUnitCostTotransfer] = @NewUnitCostTotransfer,
						[UpdatedBy] = @UpdatedBy,
						[UpdatedDate] = GETUTCDATE(),
						[ManagementStructureId] = @ManagementStructureId,
						[LastMSLevel] = @LastMSLevel,
						[AllMSlevels] = @AllMSlevels,
						[AdjustmentReasonId] = @AdjustmentReasonId
					WHERE BulkStkLineAdjDetailsId = @BulkStockLineAdjustmentDetailsId;

					SELECT @BulkStockAdjusmentStocklineId = StocklineId FROM [dbo].[BulkStockLineAdjustmentDetails] WHERE BulkStkLineAdjDetailsId = @BulkStockLineAdjustmentDetailsId;

					IF @OldQuantity <> @NewQty
					BEGIN
						IF @OldQuantity < @NewQty
						BEGIN 
							UPDATE Stockline
							SET QuantityReserved = QuantityReserved + @UpdatedQuantity,
								QuantityAvailable = QuantityAvailable - @UpdatedQuantity
							WHERE StockLineId = @BulkStockAdjusmentStocklineId

							EXEC USP_AddUpdateStocklineHistory @BulkStockAdjusmentStocklineId, @BulkStockModuleId, @BulkStkLineAdjHeaderId, NULL, NULL, 2, @UpdatedQuantity, @UpdatedBy;
						END
						IF @OldQuantity > @NewQty
						BEGIN
							UPDATE Stockline
							SET QuantityReserved = QuantityReserved - @UpdatedQuantity,
								QuantityAvailable = QuantityAvailable + @UpdatedQuantity
							WHERE StockLineId = @BulkStockAdjusmentStocklineId

							EXEC USP_AddUpdateStocklineHistory @BulkStockAdjusmentStocklineId, @BulkStockModuleId, @BulkStkLineAdjHeaderId, NULL, NULL, 3, @UpdatedQuantity, @UpdatedBy;
						END
					END
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

				DECLARE @DeletedQty INT,@StocklineAdjustmentStatusId BIGINT = 0;

				--Get data for get adjustment status
				SELECT @StocklineAdjustmentStatusId = StatusId FROM [dbo].[BulkStockLineAdjustment] WITH(NOLOCK) WHERE [BulkStkLineAdjId] = @BulkStkLineAdjHeaderId;

				SELECT @BulkStockAdjusmentStocklineId = StocklineId, @DeletedQty = NewQty FROM [dbo].[BulkStockLineAdjustmentDetails] WITH(NOLOCK) WHERE BulkStkLineAdjDetailsId = @BulkStockLineAdjustmentDetailsId;

				--If Adjustment Posted then it will be update
				IF(@StatusId = @StocklineAdjustmentStatusId)
				BEGIN
					UPDATE Stockline
					SET QuantityReserved = QuantityReserved - @NewQty,
						QuantityAvailable = QuantityAvailable + @NewQty
					WHERE StockLineId = @BulkStockAdjusmentStocklineId

					EXEC USP_AddUpdateStocklineHistory @BulkStockAdjusmentStocklineId, @BulkStockModuleId, @BulkStkLineAdjHeaderId, NULL, NULL, 3, @NewQty, @UpdatedBy;
				END
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
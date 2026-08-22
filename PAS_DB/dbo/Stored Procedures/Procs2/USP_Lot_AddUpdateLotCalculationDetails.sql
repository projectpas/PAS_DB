/*************************************************************           
 ** File:   [USP_Lot_AddUpdateLotCalculationDetails]           
 ** Author:  Rajesh Gami
 ** Description: This stored procedure is used to add lot calculation.
 ** Purpose:         
 ** Date:   04/10/2023      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------    ---------		--------------------------------          
    1    04/10/2023  Rajesh Gami    Created
	2    10/16/2024	 Abhishek Jirawla	Implemented the new tables for SalesOrder related tables
    3   07-Aug-2025  RAJESH GAMI       New SO Shipping and Invoiced status related change(PN-8302)
	4   03-June-2026  RAJESH GAMI      [PN-16687] Original Cost Should Include All PO-Received Stocklines
	5   12-Aug-2026   RAJESH GAMI      [PN-17647] Fixed: reposting the same SO invoice (e.g. after Re-Open) was inserting a
									   brand-new 'Trans Out (SO)' row into LotCalculationDetails every single time,
									   instead of finding the one already created for this LotTransInOutId and
									   updating it - producing duplicate rows with identical ReferenceId/ChildId on
									   every repost. Now checks for an existing row (LotId + Type + LotTransInOutId)
									   first: if found, updates its cost/amount fields instead of inserting; if not,
									   inserts as before. Also skips the Stockline.LOTQty decrement on repost (it
									   already ran the first time - re-running it on every repost was double/triple
									   decrementing LOTQty).
	6   14-Aug-2026   RAJESH GAMI      PN-17673 : Update LOT Commission Cost Calculation for Multiple Commission Methods (% Of Revenue, % Of Margin OR Fixed Commision Amount)
	7   21-Aug-2026   RAJESH GAMI      [PN-17745] "Create Stockline from Lot" now sends @Type = 'Turn In' instead of
									   'Trans In (Lot)'. Added 'Turn In' alongside the existing 'Trans In (Lot)' check
									   in both the insert gate above and the Stockline.LOTQty/IsLotAssigned update gate
									   below - 'Trans In (Lot)' is left in place since the manual Lot Trans-In quantity
									   transfer flow (USP_Lot_AddUpdateLotTransInOutDetails) still legitimately uses it.
-- EXEC USP_Lot_AddUpdateLotCalculationDetails
************************************************************************/
CREATE PROCEDURE [dbo].[USP_Lot_AddUpdateLotCalculationDetails]
	@tbl_LotCalculationDetailsType LotCalculationDetailsType READONLY,
	@LotCalculationId BIGINT = NULL,
	@LotId BIGINT = NULL,
	@Type VARCHAR(50) = NULL,
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(200),
	@UpdatedBy VARCHAR(200),
	@CreatedDate DATETIME,
	@UpdatedDate DATETIME
AS
BEGIN
	  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	  BEGIN TRANSACTION
		DECLARE @lotModuleId int = (SELECT TOP 1 ModuleId FROM dbo.Module WHERE	UPPER(ModuleName) = 'LOT')
		DECLARE @TotalCounts INT,@count INT,@LatestId BIGINT,@LastOrignalCost DECIMAL(18,2),@UpdatedUnitCost DECIMAL(18,2),@TotalMarginCost DECIMAL(18,2)=0,@CommissionCost DECIMAL(18,2)=0,@TotalSalesCost DECIMAL(18,2)=0;
		DECLARE @LastLotTransInOutId BIGINT =NULL, @LastStockLineId BIGINT =NULL,@LastQty int =NULL;
		DECLARE @IsMaintainStkLine bit = 0,@IsUseMargin bit = 0,@IsInitialPO bit = 0,@InitialPOCost DECIMAL(18,2),@InitialPOId BIGINT = 0;
		DECLARE @MarginPercentageId BIGINT = 0,@PercentValue DECIMAL(18,2),@Qty INT = 0, @lotNumber varchar(20) ='', @lotDesc varchar(max);
		-- Used by the 'Trans Out (SO)' branch to dedup on repost after Re-Open: if a row already exists
		-- for this LotTransInOutId + Type, update it instead of inserting a duplicate. NULL = not checked
		-- yet / no existing row found for the current loop iteration.
		DECLARE @ExistingLotCalculationId BIGINT = NULL;
		Select @lotNumber = LotNumber, @lotDesc = LotName from dbo.Lot WITH(NOLOCK) WHERE LotId = @LotId
		DECLARE @ConsignmentRevenuePercent DECIMAL(18,2),@ConsignmentMarginPercent DECIMAL(18,2),@ConsignmentFixedAmt DECIMAL(18,2), @IsRevenue bit =0, @IsMargin bit = 0, @IsFixedAmount bit = 0,@IsRevenueSplit bit = 0, @ConPercentId bigint =0,@QtyLot int = 0;
		SET @count = 1;
		SELECT TOP 1 @IsMaintainStkLine = ISNULL(IsMaintainStkLine,0),@IsUseMargin =ISNULL(IsUseMargin,0)  ,@MarginPercentageId = ISNULL(MarginPercentageId,0)  FROM DBO.LotSetupMaster WITH(NOLOCK) WHERE LotId = @LotId
		IF OBJECT_ID(N'tempdb..#tmpLotCalculationDetailsType') IS NOT NULL
		BEGIN
			DROP TABLE #tmpLotCalculationDetailsType
		END
		
		CREATE TABLE #tmpLotCalculationDetailsType
		(
			ID BIGINT NOT NULL IDENTITY, 
			[LotCalculationId] BIGINT NULL,
			[LotId] BIGINT NULL,
			[LotTransInOutId] BIGINT NULL,
			[Type] VARCHAR(100) NULL,
			[ReferenceId] BIGINT NULL,
			[ChildId] BIGINT NULL,
			[OriginalCost] DECIMAL(18, 2) NULL,
			[RepairCost] DECIMAL(18, 2) NULL,
			[AdjustedLotCost] DECIMAL(18, 2) NULL,
			[RepCost] DECIMAL(18, 2) NULL,
			[Qty] INT NULL,
			[TransferredInCost] DECIMAL(18, 2) NULL,
			[TransferredOutCost] DECIMAL(18, 2) NULL,
			[RemainingCost] DECIMAL(18, 2) NULL,
			[OtherCost] DECIMAL(18, 2) NULL,
			[TotalLotCost] DECIMAL(18, 2) NULL,
			[Revenue] DECIMAL(18, 2) NULL,
			[CogsPartsCost] DECIMAL(18, 2) NULL,
			[CommissionExpense] DECIMAL(18, 2) NULL,
			[TotalExpense] DECIMAL(18, 2) NULL,
			[MarginAmt] DECIMAL(18, 2) NULL,
			[MarginPercent] [decimal](18, 2) NULL,
			[FreightCost] [decimal](18, 2) NULL,
			[InsuranceCost] [decimal](18, 2) NULL,
			[HandlingCost] [decimal](18, 2) NULL,
			[TeardownCost] [decimal](18, 2) NULL,
			[SoldCost] [decimal](18, 2) NULL,
			[SalesUnitPrice] [decimal](18, 2) NULL,
			[PreCostStocklinePrice] [decimal](18, 2) NULL,
			[ExtPreCostStocklinePrice] [decimal](18, 2) NULL,
			[IsFromPreCostStk][bit] NULL
		)
		
		IF(UPPER(@Type) = UPPER('Trans In (Lot)') OR UPPER(@Type) = UPPER('Turn In') OR UPPER(@Type) = UPPER('PO') OR UPPER(@Type) = UPPER('RO') OR UPPER(@Type) = UPPER('SO') OR UPPER(@Type) = UPPER('WO') OR UPPER(@Type) = UPPER('Trans In (PO)') OR UPPER(@Type) = UPPER('Trans In (RO)')OR UPPER(@Type) = UPPER('Shipped') OR UPPER(@Type) = UPPER('Trans In (SO)') OR UPPER(@Type) = UPPER('Trans In (WO)') )
		BEGIN		

			INSERT INTO #tmpLotCalculationDetailsType ([LotCalculationId], [LotId], [LotTransInOutId], [Type], [ReferenceId], [ChildId], [OriginalCost],
												  [RepairCost], [AdjustedLotCost], [RepCost], [Qty],[TransferredInCost], [TransferredOutCost] , [RemainingCost], [OtherCost], [TotalLotCost], [Revenue],
												  [CogsPartsCost], [CommissionExpense], [TotalExpense], [MarginAmt], [MarginPercent],[FreightCost],[InsuranceCost],[HandlingCost],[TeardownCost],[SoldCost],[PreCostStocklinePrice],[ExtPreCostStocklinePrice],[IsFromPreCostStk])
						SELECT [LotCalculationId], [LotId], [LotTransInOutId], [Type], [ReferenceId], [ChildId], [OriginalCost],
												  [RepairCost], [AdjustedLotCost], [RepCost],[Qty],[TransferredInCost], [TransferredOutCost] , [RemainingCost], [OtherCost], ISNULL([OtherCost],0) + ISNULL([TransferredInCost],0), [Revenue],
												  [CogsPartsCost], [CommissionExpense], [TotalExpense], [MarginAmt], [MarginPercent],[FreightCost],[InsuranceCost],[HandlingCost],[TeardownCost],[SoldCost],[PreCostStocklinePrice],[ExtPreCostStocklinePrice],[IsFromPreCostStk]
						FROM @tbl_LotCalculationDetailsType
		
			SELECT @TotalCounts = COUNT(ID) FROM #tmpLotCalculationDetailsType;
		
			WHILE @count<= @TotalCounts
			BEGIN			
				SELECT top 1 @LastOrignalCost = ISNULL(OriginalCost,0) FROM [DBO].[LotCalculationDetails] WITH (NOLOCK) 
				WHERE LotId = @LotId ORDER BY LotCalculationId DESC;

				INSERT INTO [DBO].[LotCalculationDetails]([LotId], [LotTransInOutId], [Type], [ReferenceId], [ChildId], [OriginalCost],
												  [RepairCost], [AdjustedLotCost], [RepCost], [Qty],[TransferredInCost], [TransferredOutCost] , [RemainingCost], [OtherCost], [TotalLotCost], [Revenue],
												  [CogsPartsCost], [CommissionExpense], [TotalExpense], [MarginAmt], [MarginPercent],
												  MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,[FreightCost],[InsuranceCost],[HandlingCost],[TeardownCost],[SoldCost],[PreCostStocklinePrice],[ExtPreCostStocklinePrice],[IsFromPreCostStk],SalesUnitPrice)
				SELECT [LotId], [LotTransInOutId], [Type], [ReferenceId], [ChildId], [OriginalCost],
												  [RepairCost], [AdjustedLotCost], (CASE WHEN UPPER(@Type) = UPPER('Shipped') THEN 0 ELSE RepCost END), [Qty],[TransferredInCost], [TransferredOutCost] , [RemainingCost], [OtherCost], [TotalLotCost], [Revenue],
												  [CogsPartsCost], [CommissionExpense], [TotalExpense], [MarginAmt], [MarginPercent],
					@MasterCompanyId,@CreatedBy,GETUTCDATE(),@UpdatedBy,GETUTCDATE(),[FreightCost],[InsuranceCost],[HandlingCost],[TeardownCost],[SoldCost],[PreCostStocklinePrice],[ExtPreCostStocklinePrice],[IsFromPreCostStk],
					(CASE WHEN UPPER(@Type) = UPPER('Shipped') THEN RepCost ELSE 0 END)
				FROM #tmpLotCalculationDetailsType lot 
				WHERE lot.ID = @count;

				SELECT @LatestId = SCOPE_IDENTITY();	

				SELECT @UpdatedUnitCost = ISNULL(OriginalCost,0),@LastLotTransInOutId = ISNULL(LotTransInOutId,0), @LastQty = Qty FROM [DBO].[LotCalculationDetails] WITH (NOLOCK) WHERE LotCalculationId = @LatestId;
				Select @LastStockLineId = ISNULL(StockLineId,0) From DBO.LotTransInOutDetails  WITH (NOLOCK) Where LotTransInOutId = @LastLotTransInOutId
				
				IF(UPPER(@Type) != UPPER('Shipped'))
				BEGIN
					IF(ISNULL(@LastOrignalCost,0) > 0)
					BEGIN
						SET @LastOrignalCost = @LastOrignalCost + @UpdatedUnitCost;
					END
					ELSE
					BEGIN
						SET @LastOrignalCost =  @UpdatedUnitCost;
					END		
				END
				UPDATE [DBO].[LotCalculationDetails] SET OriginalCost = @LastOrignalCost WHERE LotCalculationId = @LatestId; 
				
				IF(UPPER(@Type) = UPPER('Trans In (Lot)') OR UPPER(@Type) = UPPER('Turn In') OR (UPPER(@Type) = UPPER('Trans In (RO)') ))
				BEGIN
					Update dbo.Stockline set 
										LOTQty = ISNULL(LOTQty,0) + ISNULL(@LastQty,0), LotId =@LotId, IsLotAssigned = 1,LotNumber = @lotNumber, LotDescription = @lotDesc WHERE StockLineId = @LastStockLineId

					EXEC USP_AddUpdateStocklineHistory @LastStockLineId, @lotModuleId, @LotId, NULL, NULL, 1, @LastQty, @UpdatedBy;
				END	
				
				IF(@LotId >0)
				BEGIN
					SELECT @IsInitialPO = ISNULL(IsInitialPO,0) FROM DBO.LOT WITH(NOLOCK) WHERE LotId = @LotId;
					IF(UPPER(@Type) = UPPER('Trans In (PO)'))
					BEGIN		
							SELECT Top 1 @InitialPOCost =TransferredInCost,@InitialPOId = ReferenceId from #tmpLotCalculationDetailsType WITH(NOLOCK)
							IF(@IsInitialPO = 0)
							BEGIN
								UPDATE LOT Set IsInitialPO = 1, InitialPOCost = ISNULL(InitialPOCost,0) + @InitialPOCost,InitialPOId =@InitialPOId WHERE LOTID = @LotId;
							END
							ELSE
							BEGIN
								UPDATE LOT Set InitialPOCost = ISNULL(InitialPOCost,0) + @InitialPOCost WHERE LOTID = @LotId;
							END
							Update dbo.Stockline set LotNumber = @lotNumber, LotDescription = @lotDesc WHERE StockLineId = @LastStockLineId
							EXEC USP_AddUpdateStocklineHistory @LastStockLineId, @lotModuleId, @LotId, NULL, NULL, 1, @LastQty, @UpdatedBy;
					END

					--IF(@IsMaintainStkLine =0 AND  UPPER(@Type) = UPPER('Trans In(PO)'))
					--BEGIN
					--	IF(@IsInitialPO = 0)
					--	BEGIN
					--		Update dbo.Stockline set 
					--						UnitCost = PurchaseOrderUnitCost,RepairOrderUnitCost = 0,PurchaseOrderUnitCost = PurchaseOrderUnitCost, LotId =@LotId, IsLotAssigned = 1  WHERE StockLineId = @LastStockLineId
					--	END
					--	ELSE
					--	BEGIN
					--		Update dbo.Stockline set 
					--						UnitCost = 0,RepairOrderUnitCost = 0,PurchaseOrderUnitCost = 0, OriginalCost =UnitCost, POOriginalCost = PurchaseOrderUnitCost, ROOriginalCost = RepairOrderUnitCost, LotId =@LotId, IsLotAssigned = 1  WHERE StockLineId = @LastStockLineId
					--	END
						
					--END	

				END
					
				SET @count = @count + 1;
			END

			
		END
		ELSE IF(UPPER(@Type) = UPPER('Trans Out (RO)') OR UPPER(@Type) = UPPER('Trans Out (PO)') OR UPPER(@Type) = UPPER('Trans Out (Lot)')OR UPPER(@Type) = UPPER('Trans Out (WO)'))
		BEGIN		

			INSERT INTO #tmpLotCalculationDetailsType ([LotCalculationId], [LotId], [LotTransInOutId], [Type], [ReferenceId], [ChildId], [OriginalCost],
												  [RepairCost], [AdjustedLotCost], [RepCost], [Qty],[TransferredInCost], [TransferredOutCost] , [RemainingCost], [OtherCost], [TotalLotCost], [Revenue],
												  [CogsPartsCost], [CommissionExpense], [TotalExpense], [MarginAmt], [MarginPercent],SalesUnitPrice)
						SELECT [LotCalculationId], [LotId], [LotTransInOutId], [Type], [ReferenceId], [ChildId], [OriginalCost],
												  [RepairCost], [AdjustedLotCost], 0,[Qty],[TransferredInCost], [TransferredOutCost] , [RemainingCost], [OtherCost], ISNULL([OtherCost],0) + ISNULL([TransferredOutCost],0), [Revenue],
												  [CogsPartsCost], [CommissionExpense], [TotalExpense], [MarginAmt], [MarginPercent],(CASE WHEN UPPER(@Type) = UPPER('Trans Out (SO)') THEN RepCost ELSE 0 END)
						FROM @tbl_LotCalculationDetailsType
		
			SELECT @TotalCounts = COUNT(ID) FROM #tmpLotCalculationDetailsType;
		
			WHILE @count<= @TotalCounts
			BEGIN		
			
				SELECT top 1 @LastOrignalCost = OriginalCost FROM [DBO].[LotCalculationDetails] WITH (NOLOCK)
				WHERE LotId = @LotId ORDER BY LotCalculationId DESC;

				INSERT INTO [DBO].[LotCalculationDetails]([LotId], [LotTransInOutId], [Type], [ReferenceId], [ChildId], [OriginalCost],
												  [RepairCost], [AdjustedLotCost], [RepCost], [Qty],[TransferredInCost], [TransferredOutCost] , [RemainingCost], [OtherCost], [TotalLotCost], [Revenue],
												  [CogsPartsCost], [CommissionExpense], [TotalExpense], [MarginAmt], [MarginPercent],
												  MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,[FreightCost],[InsuranceCost],[HandlingCost],[TeardownCost],[SoldCost],SalesUnitPrice)
				SELECT [LotId], [LotTransInOutId], [Type], [ReferenceId], [ChildId], [OriginalCost],
												  [RepairCost], [AdjustedLotCost], [RepCost], [Qty],[TransferredInCost], [TransferredOutCost] , [RemainingCost], [OtherCost], [TotalLotCost], [Revenue],
												  [CogsPartsCost], [CommissionExpense], [TotalExpense], [MarginAmt], [MarginPercent],
					@MasterCompanyId,@CreatedBy,GETUTCDATE(),@UpdatedBy,GETUTCDATE(),[FreightCost],[InsuranceCost],[HandlingCost],[TeardownCost],[SoldCost],SalesUnitPrice
				FROM #tmpLotCalculationDetailsType lot 
				WHERE lot.ID = @count;

				SELECT @LatestId = SCOPE_IDENTITY();	

				SELECT @UpdatedUnitCost = ISNULL(OriginalCost,0),@LastLotTransInOutId = ISNULL(LotTransInOutId,0), @LastQty = Qty FROM [DBO].[LotCalculationDetails] WITH (NOLOCK) WHERE LotCalculationId = @LatestId;
				Select @LastStockLineId = ISNULL(StockLineId,0) From DBO.LotTransInOutDetails Where LotTransInOutId = @LastLotTransInOutId
				
				IF(@LastOrignalCost > 0)
				BEGIN
					SET @LastOrignalCost = CASE WHEN ISNULL(@LastOrignalCost,0) - ISNULL(@UpdatedUnitCost,0) <0 THEN 0 ELSE ISNULL(@LastOrignalCost,0) - ISNULL(@UpdatedUnitCost,0) END;
				END
				ELSE
				BEGIN
					SET @LastOrignalCost =  @UpdatedUnitCost;
				END				

					UPDATE [DBO].[LotCalculationDetails] SET OriginalCost = @LastOrignalCost WHERE LotCalculationId = @LatestId; 
						
					IF(UPPER(@Type) = UPPER('Trans Out (RO)'))
					BEGIN
						Update dbo.Stockline set LotNumber = @lotNumber, LotDescription = @lotDesc WHERE StockLineId = @LastStockLineId
						EXEC USP_AddUpdateStocklineHistory @LastStockLineId, @lotModuleId, @LotId, NULL, NULL, 2, @LastQty, @UpdatedBy;
					END	
					IF(UPPER(@Type) = UPPER('Trans Out (Lot)'))
					BEGIN
						Update dbo.Stockline set LotNumber = @lotNumber, LotDescription = @lotDesc WHERE StockLineId = @LastStockLineId
						EXEC USP_AddUpdateStocklineHistory @LastStockLineId, @lotModuleId, @LotId, NULL, NULL, 1, @LastQty, @UpdatedBy;
					END	
					SET @count = @count + 1;
			END
		END
		ELSE IF(UPPER(@Type) = UPPER('Trans Out (SO)'))
		BEGIN	
			Set @PercentValue = ISNULL((SELECT TOP 1 ISNULL(PercentValue,0) FROM DBO.[Percent] Where PercentId = @MarginPercentageId),0);
			INSERT INTO #tmpLotCalculationDetailsType ([LotCalculationId], [LotId], [LotTransInOutId], [Type], [ReferenceId], [ChildId], [OriginalCost],
												  [RepairCost], [AdjustedLotCost], [RepCost], [Qty],[TransferredInCost], [TransferredOutCost] , [RemainingCost], [OtherCost], [TotalLotCost], [Revenue],
												  [CogsPartsCost], [CommissionExpense], [TotalExpense], [MarginAmt], [MarginPercent],SalesUnitPrice)
						SELECT [LotCalculationId], [LotId], [LotTransInOutId], [Type], [ReferenceId], [ChildId], [OriginalCost],
												  [RepairCost], [AdjustedLotCost], 0,[Qty],[TransferredInCost], [TransferredOutCost] , [RemainingCost], [OtherCost], ISNULL([OtherCost],0) + ISNULL([TransferredOutCost],0), [Revenue],
												  [CogsPartsCost], [CommissionExpense], [TotalExpense], [MarginAmt], [MarginPercent],(CASE WHEN UPPER(@Type) = UPPER('Trans Out (SO)') THEN RepCost ELSE 0 END)
						FROM @tbl_LotCalculationDetailsType
		
			SELECT @TotalCounts = COUNT(ID) FROM #tmpLotCalculationDetailsType;
			SELECT TOP 1 @ConPercentId = ISNULL(LC.PercentId,0),@ConsignmentMarginPercent  = ISNULL((SELECT TOP 1 ISNULL(PercentValue,0) FROM DBO.[Percent] P WITH(NOLOCK) WHERE P.PercentId = ISNULL(LC.MarginPercentId,0)),0) , @ConsignmentRevenuePercent = ISNULL((SELECT TOP 1 ISNULL(PercentValue,0) FROM DBO.[Percent] P WITH(NOLOCK) WHERE P.PercentId = ISNULL(LC.PercentId,0)),0), @ConsignmentFixedAmt = ISNULL(LC.PerAmount,0),@IsRevenue = ISNULL(LC.IsRevenue,0), @IsMargin = ISNULL(LC.IsMargin,0), @IsFixedAmount = ISNULL(LC.IsFixedAmount,0), @IsRevenueSplit = ISNULL(LC.IsRevenueSplit,0)   FROM DBO.LotConsignment LC WHERE LotId = @LotId

			WHILE @count<= @TotalCounts
			BEGIN	
				
				SELECT top 1 @LastOrignalCost = OriginalCost FROM [DBO].[LotCalculationDetails] WITH (NOLOCK)
				WHERE LotId = @LotId ORDER BY LotCalculationId DESC;

					
				Set @Qty = (SELECT ISNULL(Qty,0) FROM #tmpLotCalculationDetailsType WHERE ID= @count)

				-- Dedup for repost-after-Re-Open: if a 'Trans Out (SO)' row already exists for this
				-- LotTransInOutId, this SO invoice line was already posted once before - update that
				-- existing row (below) instead of inserting a brand-new duplicate every time the
				-- invoice is reposted. First-time posting (no existing row) falls through to the
				-- normal insert unchanged.
				SET @ExistingLotCalculationId = NULL
				SELECT TOP 1 @ExistingLotCalculationId = LotCalculationId
				FROM [DBO].[LotCalculationDetails] WITH (NOLOCK)
				WHERE LotId = @LotId
				  AND Type = @Type
				  AND LotTransInOutId = (SELECT LotTransInOutId FROM #tmpLotCalculationDetailsType WHERE ID = @count)
				ORDER BY LotCalculationId DESC

				IF (@ExistingLotCalculationId IS NULL)
				BEGIN
					INSERT INTO [DBO].[LotCalculationDetails]([LotId], [LotTransInOutId], [Type], [ReferenceId], [ChildId], [OriginalCost],
													  [RepairCost], [AdjustedLotCost], [RepCost], [Qty],[TransferredInCost], [TransferredOutCost] , [RemainingCost], [OtherCost], [TotalLotCost], [Revenue],
													  [CogsPartsCost], [CommissionExpense], [TotalExpense], [MarginAmt], [MarginPercent],
													  MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,[FreightCost],[InsuranceCost],[HandlingCost],[TeardownCost],[SoldCost],SalesUnitPrice,ExtSalesUnitPrice
													  ,Margin
													  ,MarginAmount
													  ,COGS)
					SELECT [LotId], [LotTransInOutId], [Type], [ReferenceId], [ChildId], [OriginalCost],
													  [RepairCost], [AdjustedLotCost], [RepCost], [Qty],[TransferredInCost], [TransferredOutCost] , [RemainingCost], [OtherCost], [TotalLotCost], [Revenue],
													  [CogsPartsCost], [CommissionExpense], [TotalExpense], [MarginAmt], [MarginPercent],
													  @MasterCompanyId,@CreatedBy,GETUTCDATE(),@UpdatedBy,GETUTCDATE(),[FreightCost],[InsuranceCost],[HandlingCost],[TeardownCost],[SoldCost],SalesUnitPrice, ISNULL(SalesUnitPrice,0) * Qty
													  ,(CASE WHEN @IsUseMargin = 0 THEN 0 ELSE @PercentValue END)
													  ,(CASE WHEN @IsUseMargin = 0 THEN (ISNULL(SalesUnitPrice,0) * Qty) - ((SELECT TOP 1 SPC.UnitCost FROM dbo.SalesOrderPartV1 SP WITH(NOLOCK) INNER JOIN dbo.SalesOrderPartCost SPC WITH(NOLOCK) ON SPC.SalesOrderPartId = SP.SalesOrderPartId AND SPC.IsDeleted = 0 WHERE SP.SalesOrderPartId = [ChildId] AND SP.SalesOrderId = [ReferenceId])*lot.Qty) ELSE  (ISNULL(SalesUnitPrice,0) * Qty) - (Convert(DECIMAL(18,2),(((ISNULL(SalesUnitPrice,0) * Qty) * @PercentValue)/100))) END)
													  ,(CASE WHEN @IsUseMargin = 0 THEN ISNULL((SELECT TOP 1 ISNULL(SPC.UnitCost,0) FROM dbo.SalesOrderPartV1 SP WITH(NOLOCK) INNER JOIN dbo.SalesOrderPartCost SPC WITH(NOLOCK) ON SPC.SalesOrderPartId = SP.SalesOrderPartId AND SPC.IsDeleted = 0  WHERE SP.SalesOrderPartId = [ChildId] AND SP.SalesOrderId = [ReferenceId]),0)* Qty ELSE (Convert(DECIMAL(18,2),(((ISNULL(SalesUnitPrice,0) * Qty) * @PercentValue)/100))) END)
					FROM #tmpLotCalculationDetailsType lot
					WHERE lot.ID = @count;

					SELECT @LatestId = SCOPE_IDENTITY();
				END
				ELSE
				BEGIN
					-- Already posted once before (repost after Re-Open) - refresh the existing row's
					-- cost/amount fields from the freshly-recalculated values instead of inserting.
					UPDATE LCD
					SET LCD.[ReferenceId] = lot.[ReferenceId], LCD.[ChildId] = lot.[ChildId], LCD.[OriginalCost] = lot.[OriginalCost],
						LCD.[RepairCost] = lot.[RepairCost], LCD.[AdjustedLotCost] = lot.[AdjustedLotCost], LCD.[RepCost] = lot.[RepCost], LCD.[Qty] = lot.[Qty],
						LCD.[TransferredInCost] = lot.[TransferredInCost], LCD.[TransferredOutCost] = lot.[TransferredOutCost], LCD.[RemainingCost] = lot.[RemainingCost],
						LCD.[OtherCost] = lot.[OtherCost], LCD.[TotalLotCost] = lot.[TotalLotCost], LCD.[Revenue] = lot.[Revenue],
						LCD.[CogsPartsCost] = lot.[CogsPartsCost], LCD.[CommissionExpense] = lot.[CommissionExpense], LCD.[TotalExpense] = lot.[TotalExpense],
						LCD.[MarginAmt] = lot.[MarginAmt], LCD.[MarginPercent] = lot.[MarginPercent],
						LCD.[UpdatedBy] = @UpdatedBy, LCD.[UpdatedDate] = GETUTCDATE(),
						LCD.[FreightCost] = lot.[FreightCost], LCD.[InsuranceCost] = lot.[InsuranceCost], LCD.[HandlingCost] = lot.[HandlingCost],
						LCD.[TeardownCost] = lot.[TeardownCost], LCD.[SoldCost] = lot.[SoldCost], LCD.[SalesUnitPrice] = lot.[SalesUnitPrice],
						LCD.[ExtSalesUnitPrice] = ISNULL(lot.[SalesUnitPrice],0) * lot.[Qty]
					FROM [DBO].[LotCalculationDetails] LCD
					INNER JOIN #tmpLotCalculationDetailsType lot ON lot.ID = @count
					WHERE LCD.LotCalculationId = @ExistingLotCalculationId

					SELECT @LatestId = @ExistingLotCalculationId
				END

				SELECT @UpdatedUnitCost = ISNULL(COGS,0),@LastLotTransInOutId = ISNULL(LotTransInOutId,0), @LastQty = Qty FROM [DBO].[LotCalculationDetails] WITH (NOLOCK) WHERE LotCalculationId = @LatestId;
				Select @LastStockLineId = ISNULL(StockLineId,0) From DBO.LotTransInOutDetails Where LotTransInOutId = @LastLotTransInOutId
				
				
				IF(@LastOrignalCost > 0)
				BEGIN
					SET @LastOrignalCost = CASE WHEN ISNULL(@LastOrignalCost,0) - ISNULL(@UpdatedUnitCost,0) <0 THEN 0 ELSE ISNULL(@LastOrignalCost,0) - ISNULL(@UpdatedUnitCost,0) END;
				END
				ELSE
				BEGIN
					SET @LastOrignalCost =  @UpdatedUnitCost;
				END				

				UPDATE [DBO].[LotCalculationDetails] SET OriginalCost = @LastOrignalCost,
						--TransferredOutCost = COGS , 
						IsRevenue = @IsRevenue, IsMargin = @IsMargin, IsFixedAmount = @IsFixedAmount, PercentId = @ConPercentId, PerAmount = (CASE WHEN @IsFixedAmount = 1 THEN @ConsignmentFixedAmt ELSE @ConsignmentRevenuePercent END)  WHERE LotCalculationId = @LatestId; 

				IF(@IsFixedAmount = 1)
				BEGIN
					SET @QtyLot = ISNULL((SELECT ISNULL(Qty,0) FROM DBO.LotCalculationDetails where LotCalculationId = @LatestId),0)
						SET @CommissionCost = CONVERT(Decimal(18,2),ISNULL((@ConsignmentFixedAmt * @QtyLot),0))
					--SET @CommissionCost =ISNULL(CONVERT(Decimal(18,2),(ISNULL(CONVERT(Decimal(18,2),@ConsignmentFixedAmt),0) * @QtyLot)),0);
				END
				ELSE IF(@IsRevenue =1 OR @IsMargin = 1)
				BEGIN
					DECLARE @RevenueCommissionCost Decimal(18,2) = 0,  @MarginCommissionCost Decimal(18,2) = 0;
						IF(@IsRevenue =1)
						BEGIN
							SET @TotalSalesCost = ISNULL((SELECT ISNULL(ExtSalesUnitPrice,0) from DBO.LotCalculationDetails WITH (NOLOCK) WHERE LotCalculationId = @LatestId),0)
							SET @RevenueCommissionCost = ISNULL(CONVERT(Decimal(18,2),((@TotalSalesCost * @ConsignmentRevenuePercent)/100)),0)
						END					
						IF(@IsMargin = 1)
						BEGIN
							SET @TotalMarginCost = ISNULL((SELECT ISNULL(MarginAmount,0) from DBO.LotCalculationDetails WITH (NOLOCK) WHERE LotCalculationId = @LatestId),0)
							SET @MarginCommissionCost = ISNULL(CONVERT(Decimal(18,2),((@TotalMarginCost * @ConsignmentMarginPercent)/100)),0)
						END
						SET @CommissionCost = ISNULL(@RevenueCommissionCost,0) + ISNULL(@MarginCommissionCost,0);
				END
				--ELSE IF(@IsRevenueSplit =1)
				--BEGIN
				--	SET @TotalSalesCost = ISNULL((SELECT ISNULL(ExtSalesUnitPrice,0) from DBO.LotCalculationDetails WITH (NOLOCK) WHERE LotCalculationId = @LatestId),0)
				--	SET @CommissionCost = ISNULL(CONVERT(Decimal(18,2),((@TotalSalesCost * @ConsignmentRevenuePercent)/100)),0)
				--END
				UPDATE [DBO].[LotCalculationDetails] SET CommissionExpense =@CommissionCost WHERE LotCalculationId = @LatestId; 

				-- Skip on repost (@ExistingLotCalculationId was found above) - this Stockline.LOTQty
				-- decrement already ran the first time this line was posted; re-running it on every
				-- repost after Re-Open would double (or triple, per repost) decrement LOTQty.
				IF(UPPER(@Type) = UPPER('Trans Out (SO)') AND @ExistingLotCalculationId IS NULL)
				BEGIN
					IF(@Qty = 1)
					BEGIN
						Update dbo.Stockline set RepairOrderUnitCost = 0,
						--PurchaseOrderUnitCost = @UpdatedUnitCost,UnitCost = @UpdatedUnitCost,
						LOTQty = (CASE WHEN (ISNULL(LOTQty,0) - ISNULL(@LastQty,0))  < 0 THEN 0 ELSE (ISNULL(LOTQty,0) - ISNULL(@LastQty,0)) END) WHERE StockLineId = @LastStockLineId
					END
					ELSE
					BEGIN
						Update dbo.Stockline set LOTQty = (CASE WHEN (ISNULL(LOTQty,0) - ISNULL(@LastQty,0))  < 0 THEN 0 ELSE (ISNULL(LOTQty,0) - ISNULL(@LastQty,0)) END) , LotId =@LotId, IsLotAssigned = 1 WHERE StockLineId = @LastStockLineId
					END

				END
				
				SET @count = @count + 1;
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
            , @AdhocComments     VARCHAR(150)    = 'USP_Lot_AddUpdateLotCalculationDetails' 
            , @ProcedureParameters VARCHAR(3000) = '@LotCalculationId = ''' + CAST(ISNULL(@LotCalculationId, '') as varchar(100))
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
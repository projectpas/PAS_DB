/*************************************************************             
 ** File:   [USP_Lot_UpdateCOGSByStocklineId]             
 ** Author:   
 ** Description: This stored procedure is used to update  Stockline Adjustment,Freight Adjustment,Tax Adjustment
 ** Date:   02/09/2026
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    02/09/2026   Moin Bloch    Created 
	2    03-Sep-2026   RAJESH GAMI   [PN-17853] Implemented the update logic. For the Stockline's already-posted
	                                 'Trans Out (SO)' LotCalculationDetails row(s) (found via
	                                 LotTransInOutDetails.StockLineId -> LotTransInOutId -> LotCalculationDetails,
	                                 same join used by USP_Lot_AddUpdateLotCalculationDetails's 'Trans Out (SO)'
	                                 branch): COGS = COGS + (@FreightAdjustment + @MiscAdjustment + @TaxAdjustment).
	                                 MarginAmount is kept in sync as ExtSalesUnitPrice - COGS (holds true
	                                 regardless of margin-% vs unit-cost SO pricing - both are computed from the
	                                 same source at insert time in the reference SP, see that SP's 'Trans Out
	                                 (SO)' INSERT). CommissionExpense is then recalculated per the Lot's
	                                 LotConsignment setup (Fixed Amount / %Revenue / %Margin / both), mirroring
	                                 the exact same formula as the reference SP's post-insert commission block -
	                                 Revenue-based commission is unaffected by a COGS change, Margin-based
	                                 commission changes because MarginAmount just changed. Not yet wired to any
	                                 API/Angular caller - Rajesh asked for the DB-side logic only this round; the
	                                 caller (presumably a Stockline Freight/Misc/Tax Adjustment edit flow) is not
	                                 yet known/confirmed. NOTE for future work: when this branch's related work
	                                 is ported to another branch, this SP (currently ONLY in the large PAS_DB
	                                 project's dbo/Stored Procedures/ folder, not Procs2/ where its sibling
	                                 Lot SPs live, and not yet in PAS_DB.sqlproj) needs to be created there too.
	       
EXEC [dbo].[USP_Lot_UpdateCOGSByStocklineId] 217

************************************************************************/
CREATE PROCEDURE [dbo].[USP_Lot_UpdateCOGSByStocklineId]
@StocklineId BIGINT,
@FreightAdjustment DECIMAL(18,2) = 0,
@MiscAdjustment DECIMAL(18,2) = 0,
@TaxAdjustment  DECIMAL(18,2) = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @LOT_TransOut_SO VARCHAR(100) = 'Trans Out (SO)';
		DECLARE @TotalAdjustment DECIMAL(18,2) = ISNULL(@FreightAdjustment,0) + ISNULL(@MiscAdjustment,0) + ISNULL(@TaxAdjustment,0);

		-- Rows this call touches: the Trans Out (SO) LotCalculationDetails row(s) for this Stockline. Table
		-- variable (not a #temp table) since this SP's whole body runs inside one transaction/batch - matches
		-- the @tbl-style temp storage already used by USP_Lot_AddUpdateLotCalculationDetails.
		DECLARE @tblAffected TABLE (ID INT IDENTITY(1,1), LotCalculationId BIGINT, LotId BIGINT, ExtSalesUnitPrice DECIMAL(18,2), NewCogs DECIMAL(18,2), NewMarginAmount DECIMAL(18,2));

		IF (@TotalAdjustment <> 0)
		BEGIN
			-- Step 1: COGS = COGS + (Freight + Misc + Tax Adjustment); MarginAmount kept in sync as
			-- ExtSalesUnitPrice - COGS(new) so the %Margin commission recalculation below (and every other
			-- reader of MarginAmount) sees a consistent value immediately.
			UPDATE LCD
				SET LCD.COGS = ISNULL(LCD.COGS,0) + @TotalAdjustment,
				    LCD.MarginAmount = ISNULL(LCD.ExtSalesUnitPrice,0) - (ISNULL(LCD.COGS,0) + @TotalAdjustment),
				    LCD.UpdatedDate = GETUTCDATE()
				OUTPUT inserted.LotCalculationId, inserted.LotId, inserted.ExtSalesUnitPrice, inserted.COGS, inserted.MarginAmount
				INTO @tblAffected(LotCalculationId, LotId, ExtSalesUnitPrice, NewCogs, NewMarginAmount)
			FROM DBO.LotCalculationDetails LCD
			INNER JOIN DBO.LotTransInOutDetails LTIN WITH(NOLOCK) ON LTIN.LotTransInOutId = LCD.LotTransInOutId
			WHERE LTIN.StockLineId = @StocklineId
			  AND UPPER(REPLACE(LCD.[Type],' ','')) = UPPER(REPLACE(@LOT_TransOut_SO,' ',''));

			-- Step 2: recompute CommissionExpense per affected row, per that row's Lot's LotConsignment setup -
			-- identical formula to USP_Lot_AddUpdateLotCalculationDetails's 'Trans Out (SO)' post-insert block
			-- (Fixed Amount = PerAmount * Qty; %Revenue = ExtSalesUnitPrice * RevenuePercent/100; %Margin =
			-- MarginAmount(new) * MarginPercent/100; both summed when both flags are set).
			DECLARE @i INT = 1, @TotalAffected INT = (SELECT COUNT(*) FROM @tblAffected);
			DECLARE @CurLotCalculationId BIGINT, @CurLotId BIGINT, @CurExtSalesUnitPrice DECIMAL(18,2), @CurMarginAmount DECIMAL(18,2), @CurQty INT;
			DECLARE @ConPercentId BIGINT, @ConsignmentMarginPercent DECIMAL(18,2), @ConsignmentRevenuePercent DECIMAL(18,2), @ConsignmentFixedAmt DECIMAL(18,2);
			DECLARE @IsRevenue BIT, @IsMargin BIT, @IsFixedAmount BIT;
			DECLARE @RevenueCommissionCost DECIMAL(18,2), @MarginCommissionCost DECIMAL(18,2), @CommissionCost DECIMAL(18,2);

			WHILE @i <= @TotalAffected
			BEGIN
				SELECT @CurLotCalculationId = LotCalculationId, @CurLotId = LotId, @CurExtSalesUnitPrice = ExtSalesUnitPrice, @CurMarginAmount = NewMarginAmount
				FROM @tblAffected WHERE ID = @i;

				SET @ConPercentId = 0; SET @ConsignmentMarginPercent = 0; SET @ConsignmentRevenuePercent = 0; SET @ConsignmentFixedAmt = 0;
				SET @IsRevenue = 0; SET @IsMargin = 0; SET @IsFixedAmount = 0;
				SET @RevenueCommissionCost = 0; SET @MarginCommissionCost = 0; SET @CommissionCost = 0;

				SELECT TOP 1
					@ConPercentId = ISNULL(LC.PercentId,0),
					@ConsignmentMarginPercent = ISNULL((SELECT TOP 1 ISNULL(PercentValue,0) FROM DBO.[Percent] P WITH(NOLOCK) WHERE P.PercentId = ISNULL(LC.MarginPercentId,0)),0),
					@ConsignmentRevenuePercent = ISNULL((SELECT TOP 1 ISNULL(PercentValue,0) FROM DBO.[Percent] P WITH(NOLOCK) WHERE P.PercentId = ISNULL(LC.PercentId,0)),0),
					@ConsignmentFixedAmt = ISNULL(LC.PerAmount,0),
					@IsRevenue = ISNULL(LC.IsRevenue,0), @IsMargin = ISNULL(LC.IsMargin,0), @IsFixedAmount = ISNULL(LC.IsFixedAmount,0)
				FROM DBO.LotConsignment LC WITH(NOLOCK) WHERE LC.LotId = @CurLotId;

				IF (@IsFixedAmount = 1)
				BEGIN
					SELECT @CurQty = ISNULL(Qty,0) FROM DBO.LotCalculationDetails WITH(NOLOCK) WHERE LotCalculationId = @CurLotCalculationId;
					SET @CommissionCost = CONVERT(DECIMAL(18,2), ISNULL((@ConsignmentFixedAmt * @CurQty),0));
				END
				ELSE IF (@IsRevenue = 1 OR @IsMargin = 1)
				BEGIN
					IF (@IsRevenue = 1)
					BEGIN
						SET @RevenueCommissionCost = ISNULL(CONVERT(DECIMAL(18,2),((@CurExtSalesUnitPrice * @ConsignmentRevenuePercent)/100)),0);
					END
					IF (@IsMargin = 1)
					BEGIN
						SET @MarginCommissionCost = ISNULL(CONVERT(DECIMAL(18,2),((@CurMarginAmount * @ConsignmentMarginPercent)/100)),0);
					END
					SET @CommissionCost = ISNULL(@RevenueCommissionCost,0) + ISNULL(@MarginCommissionCost,0);
				END

				UPDATE DBO.LotCalculationDetails SET CommissionExpense = @CommissionCost, UpdatedDate = GETUTCDATE() WHERE LotCalculationId = @CurLotCalculationId;

				SET @i = @i + 1;
			END
		END

		SELECT LotCalculationId, LotId, ExtSalesUnitPrice, NewCogs AS Cogs, NewMarginAmount AS MarginAmount FROM @tblAffected;
	END
    COMMIT  TRANSACTION
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0			
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_Lot_UpdateCOGSByStocklineId' 
			, @ProcedureParameters VARCHAR(3000) = '@StocklineId = ''' + CAST(ISNULL(@StocklineId, '') AS VARCHAR(100)) + ''', @FreightAdjustment = ''' + CAST(ISNULL(@FreightAdjustment, '') AS VARCHAR(100)) + ''', @MiscAdjustment = ''' + CAST(ISNULL(@MiscAdjustment, '') AS VARCHAR(100)) + ''', @TaxAdjustment = ''' + CAST(ISNULL(@TaxAdjustment, '') AS VARCHAR(100))
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

/*************************************************************           
 ** File:   [USP_UpdateSOQPartCostDetails]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to Recalculate SOQ Part Total Cost    
 ** Purpose:         
 ** Date:   07/25/2024
          
 ** PARAMETERS:
 
 ** RETURN VALUE:

 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/25/2024   Vishal Suthar Created
     
 EXECUTE USP_UpdateSOQPartCostDetails 590, 551, 'ADMIN User', 1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_UpdateSOQPartCostDetails]
(
	@SalesOrderQuoteId BIGINT = NULL,
	@SalesOrderQuotePartId BIGINT = NULL,
	@UpdatedBy VARCHAR(100) = NULL,
	@MasterCompanyId INT = NULL
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				IF OBJECT_ID(N'tempdb..#SOQPartCostDetails') IS NOT NULL
				BEGIN
					DROP TABLE #SOQPartCostDetails
				END
				
				CREATE TABLE #SOQPartCostDetails
				(
					ID BIGINT NOT NULL IDENTITY, 
					[SalesOrderQuoteId] [bigint] NOT NULL,
					[SalesOrderQuotePartId] [bigint] NOT NULL,
					[UnitSalesPrice] [decimal](18, 4) NULL,
					[SalesPriceExtended] [decimal](18, 4) NULL,
					[MarkUpPercentage] [decimal](18, 4) NULL,
					[MarkUpAmount] [decimal](18, 4) NULL,
					[DiscountAmount] [decimal](18, 4) NULL,
					[GrossSaleAmount] [decimal](18, 4) NULL,
					[NetSaleAmount] [decimal](18, 4) NULL,
					[MiscCharges] [decimal](18, 4) NULL,
					[Freight] [decimal](18, 4) NULL,
					[TaxAmount] [decimal](18, 4) NULL,
					[TaxPercentage] [decimal](18, 4) NULL,
					[UnitCost] [decimal](18, 4) NULL,
					[UnitCostExtended] [decimal](18, 4) NULL,
					[MarginAmount] [decimal](18, 4) NULL,
					[MarginPercentage] [decimal](18, 4) NULL
				)

				INSERT INTO #SOQPartCostDetails (SalesOrderQuoteId, SalesOrderQuotePartId)
				SELECT @SalesOrderQuoteId, @SalesOrderQuotePartId
				
				IF((SELECT COUNT(1) FROM DBO.SalesOrderQuotePartCost SOQC WITH(NOLOCK) WHERE SOQC.SalesOrderQuoteId = @SalesOrderQuoteId AND SOQC.SalesOrderQuotePartId = @SalesOrderQuotePartId) > 0)
				BEGIN
					PRINT 'IF'
					DECLARE @MasterLoopID AS INT;
					DECLARE @SalesOrderQuoteStocklineId AS BIGINT;

					IF OBJECT_ID(N'tempdb..#SOQStocklineDetails') IS NOT NULL
					BEGIN
					  DROP TABLE #SOQStocklineDetails
					END

					CREATE TABLE #SOQStocklineDetails (
					  ID bigint NOT NULL IDENTITY,
					  [SalesOrderQuoteId] [bigint] NOT NULL,
					  [SalesOrderQuotePartId] [bigint] NOT NULL,
					  [SalesOrderQuoteStocklineId] [bigint] NOT NULL,
					  [UnitSalesPrice] [decimal](18, 4) NULL,
					  [SalesPriceExtended] [decimal](18, 4) NULL,
					  [MarkUpPercentage] [decimal](18, 4) NULL,
					  [MarkUpAmount] [decimal](18, 4) NULL,
					  [DiscountPercentage] [decimal](18, 4) NULL,
					  [DiscountAmount] [decimal](18, 4) NULL,
					  [UnitCost] [decimal](18, 4) NULL,
					  [UnitCostExtended] [decimal](18, 4) NULL,
					  [MarginAmount] [decimal](18, 4) NULL,
					  [MarginPercentage] [decimal](18, 4) NULL
					)

					DECLARE @Freight_S AS [decimal](18, 4);
					DECLARE @Charges_S AS [decimal](18, 4);
					DECLARE @SalesOrderQuoteModuleId BIGINT;

					SELECT @Freight_S = ISNULL(SUM(F.BillingAmount), 0) FROM [DBO].[SalesOrderQuoteFreight] F WITH (NOLOCK)
					WHERE F.SalesOrderQuotePartId = @SalesOrderQuotePartId;

					SELECT @Charges_S = ISNULL(SUM(C.BillingAmount), 0) FROM [DBO].[SalesOrderQuoteCharges] C WITH (NOLOCK)
					WHERE C.SalesOrderQuotePartId = @SalesOrderQuotePartId;

					DECLARE @UnitSalesPrice_S AS [decimal](18, 4) = 0;
					DECLARE @SalesPriceExtended_S AS [decimal](18, 4) = 0;
					DECLARE @UnitCost_S AS [decimal](18, 4);
					DECLARE @UnitCostExtended_S AS [decimal](18, 4);
					DECLARE @DiscountAmount_S AS [decimal](18, 4);

					INSERT INTO #SOQStocklineDetails ([SalesOrderQuoteId], [SalesOrderQuotePartId], [SalesOrderQuoteStocklineId], [UnitSalesPrice], [SalesPriceExtended], [MarkUpPercentage], [MarkUpAmount], [DiscountPercentage], [DiscountAmount], [UnitCost],[UnitCostExtended],[MarginAmount],[MarginPercentage])
					SELECT [SalesOrderQuoteId], [SalesOrderQuotePartId], [SalesOrderQuoteStocklineId], [UnitSalesPrice], [UnitSalesPriceExtended], [MarkUpPercentage], [MarkUpAmount], [DiscountPercentage], [DiscountAmount], [UnitCost],[UnitCostExtended],[MarginAmount],[MarginPercentage]
					FROM [DBO].[SalesOrderQuoteStockLineCost] WITH (NOLOCK) WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId;

					IF EXISTS (SELECT TOP 1 * FROM [DBO].[SalesOrderQuoteStockLineCost] WITH (NOLOCK) WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId)
					BEGIN
						PRINT 'IF EXISTS'
						SELECT @MasterLoopID = MAX(ID) FROM #SOQStocklineDetails;
						WHILE (@MasterLoopID > 0)
						BEGIN
							PRINT '1'
							DECLARE @SOQPartId BIGINT;
							DECLARE @SOQStocklineId BIGINT;
							DECLARE @PartQty INT = 0;
							DECLARE @StockLineQty INT = 0;

							SELECT @SOQPartId = [SalesOrderQuotePartId], @SOQStocklineId = [SalesOrderQuoteStocklineId] FROM #SOQStocklineDetails WHERE ID  = @MasterLoopID

							SELECT @PartQty = QtyQuoted FROM [DBO].[SalesOrderQuotePartV1] WITH (NOLOCK) WHERE SalesOrderQuotePartId = @SOQPartId;
							SELECT @StockLineQty = QtyQuoted FROM [DBO].[SalesOrderQuoteStocklineV1] WITH (NOLOCK) WHERE SalesOrderQuotePartId = @SOQPartId AND SalesOrderQuoteStocklineId = @SOQStocklineId;

							DECLARE @calculatedCharges BIGINT;

							SET @calculatedCharges = CASE WHEN ISNULL(@Charges_S, 0) > 0 THEN ((CASE WHEN @PartQty > 0 THEN (ISNULL(@Charges_S, 0) / ISNULL(@PartQty, 0)) ELSE 0 END) * ISNULL(@StockLineQty, 0)) ELSE 0 END;

							UPDATE DBO.SalesOrderQuoteStockLineCost
							SET UnitSalesPriceExtended = (ISNULL(UnitSalesPrice, 0) * @StockLineQty),
							NetSaleAmount = (ISNULL(UnitSalesPrice, 0) * @StockLineQty),
							MarginAmount = (ISNULL((ISNULL(UnitSalesPrice, 0) * @StockLineQty), 0) + @calculatedCharges) - ISNULL(UnitCostExtended, 0),
							MarginPercentage = CASE WHEN (ISNULL((ISNULL(UnitSalesPrice, 0) * @StockLineQty), 0) + @calculatedCharges) > 0 THEN ((((ISNULL((ISNULL(UnitSalesPrice, 0) * @StockLineQty), 0) + @calculatedCharges) - ISNULL(UnitCostExtended, 0)) * 100) / (ISNULL((ISNULL(UnitSalesPrice, 0) * @StockLineQty), 0) + @calculatedCharges)) ELSE 0 END
							WHERE SalesOrderQuotePartId = @SOQPartId AND SalesOrderQuoteStocklineId = @SOQStocklineId;

							PRINT '2'
							SET @MasterLoopID = @MasterLoopID - 1;
						END

						UPDATE DBO.SalesOrderQuotePartCost
						SET UnitSalesPrice = (SELECT SUM(ISNULL(SOQSC.UnitSalesPrice, 0)) FROM DBO.SalesOrderQuoteStockLineCost SOQSC WHERE SOQSC.SalesOrderQuotePartId = @SalesOrderQuotePartId),
						UnitSalesPriceExtended = (SELECT SUM(SOQSC.UnitSalesPriceExtended) FROM DBO.SalesOrderQuoteStockLineCost SOQSC WHERE SOQSC.SalesOrderQuotePartId = @SalesOrderQuotePartId),
						UnitCost = (SELECT SUM(ISNULL(SOQSC.UnitCost, 0)) FROM DBO.SalesOrderQuoteStockLineCost SOQSC WHERE SOQSC.SalesOrderQuotePartId = @SalesOrderQuotePartId),
						UnitCostExtended = (SELECT SUM(ISNULL(SOQSC.UnitCostExtended, 0)) FROM DBO.SalesOrderQuoteStockLineCost SOQSC WHERE SOQSC.SalesOrderQuotePartId = @SalesOrderQuotePartId)
						WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId;
					END
					ELSE
					BEGIN
						PRINT 'ELSE IF EXISTS'
						DECLARE @QtyRequested AS INT;
						SELECT @QtyRequested = [QtyRequested] FROM [DBO].[SalesOrderQuotePartV1] WITH (NOLOCK) WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId;

						SELECT @SalesPriceExtended_S = (@QtyRequested * ISNULL(UnitSalesPrice, 0)),
						@UnitCostExtended_S = (@QtyRequested * ISNULL(UnitCost, 0)),
						@DiscountAmount_S = DiscountAmount
						FROM [DBO].[SalesOrderQuotePartCost] WITH (NOLOCK) WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId;
					END

					DECLARE @CustomerId bigint = 0;
					DECLARE @SalesTax AS [decimal](18, 4) = 0;

					SELECT @CustomerId = [CustomerId] FROM [dbo].[SalesOrderQuote] WITH(NOLOCK) WHERE SalesOrderQuoteId = @SalesOrderQuoteId;
					
					PRINT '@Freight_S'
					PRINT @Freight_S
					PRINT '@Charges_S'
					PRINT @Charges_S

					UPDATE DBO.SalesOrderQuotePartCost
					SET 
					GrossSaleAmount = ISNULL(UnitSalesPriceExtended, 0) + ISNULL(MarkUpAmount, 0),
					NetSaleAmount = (UnitSalesPriceExtended + MarkUpAmount) - DiscountAmount,
					Freight = ISNULL(@Freight_S, 0),
					MiscCharges = ISNULL(@Charges_S, 0),
					MarkUpAmount = ISNULL(MarkUpAmount, 0),
					MarginAmount = (((ISNULL(UnitSalesPriceExtended, 0) + ISNULL(MarkUpAmount, 0)) - ISNULL(DiscountAmount, 0)) + ISNULL(@Charges_S, 0)) - ISNULL(UnitCostExtended, 0),
					TotalRevenue = ((UnitSalesPriceExtended + MarkUpAmount) - DiscountAmount) + @Charges_S,
					MarginPercentage = CASE WHEN UnitSalesPriceExtended > 0 THEN ((((((UnitSalesPriceExtended + MarkUpAmount) - DiscountAmount) + @Charges_S) - UnitCostExtended) * 100) / (((UnitSalesPriceExtended + MarkUpAmount) - DiscountAmount) + @Charges_S)) ELSE 0 END,
					TaxPercentage = @SalesTax,
					TaxAmount = ((((UnitSalesPriceExtended + MarkUpAmount) - DiscountAmount) * @SalesTax) / 100)
					WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId
				END
				ELSE
				BEGIN
					PRINT 'ELSE'
					INSERT INTO dbo.SalesOrderQuotePartCost (
							 [SalesOrderQuoteId]
							,[SalesOrderQuotePartId]
							,[UnitSalesPrice]
							,[UnitSalesPriceExtended]
							,[MarkUpPercentage]
							,[MarkUpAmount]
							,[DiscountAmount]
							,[GrossSaleAmount]
							,[NetSaleAmount]
							,[MiscCharges]
							,[Freight]
							,[TaxAmount]
							,[TaxPercentage]
							,[UnitCost]
							,[UnitCostExtended]
							,[MarginAmount]
							,[MarginPercentage]
							,[MasterCompanyId]
							,[CreatedBy]
							,[CreatedDate]
							,[UpdatedBy]
							,[UpdatedDate]
							,[IsActive]
							,[IsDeleted]
					)
					SELECT  SOQCD.[SalesOrderQuoteId],
							SOQCD.[SalesOrderQuotePartId],
							SOQCD.[UnitSalesPrice],
							SOQCD.[SalesPriceExtended],
							SOQCD.[MarkUpPercentage],
							SOQCD.[MarkUpAmount],
							SOQCD.[DiscountAmount],
							SOQCD.[GrossSaleAmount],
							SOQCD.[NetSaleAmount],
							SOQCD.[MiscCharges],
							SOQCD.[Freight],
							SOQCD.[TaxAmount],
							SOQCD.[TaxPercentage],
							SOQCD.[UnitCost],
							SOQCD.[UnitCostExtended],
							SOQCD.[MarginAmount],
							SOQCD.[MarginPercentage],
							@MasterCompanyId,
							@UpdatedBy,
							GETUTCDATE(),
							@UpdatedBy,
							GETUTCDATE(),
							1,
							0
					FROM #SOQPartCostDetails SOQCD
				END

				IF EXISTS (SELECT TOP 1 1 FROM DBO.SalesOrderQuoteStocklineV1 SOQS WHERE SOQS.SalesOrderQuotePartId = @SalesOrderQuotePartId)
				BEGIN
					UPDATE DBO.SalesOrderQuotePartV1 
					SET QtyQuoted = (SELECT SUM(ISNULL(SOQS.QtyQuoted, 0)) FROM DBO.SalesOrderQuoteStocklineV1 SOQS WHERE SOQS.SalesOrderQuotePartId = @SalesOrderQuotePartId)
					WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId;
				END

				IF OBJECT_ID(N'tempdb..#SOQPartCostDetails') IS NOT NULL
				BEGIN
					DROP TABLE #SOQPartCostDetails
				END

				EXEC [DBO].[USP_UpdateSOQCostDetails] @SalesOrderQuoteId, @UpdatedBy, @MasterCompanyId;
			END
		COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH
		SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
		IF @@trancount > 0
			PRINT 'ROLLBACK'
		ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID int,
        @DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        ,@AdhocComments varchar(150) = 'USP_UpdateSOQPartCostDetails',
        @ProcedureParameters varchar(3000) = '@SalesOrderQuoteId = ''' + CAST(ISNULL(@SalesOrderQuoteId, '') AS varchar(100))
        + '@Parameter2 = ''' + CAST(ISNULL(@SalesOrderQuotePartId, '') AS varchar(100))
        + '@Parameter3 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))
        + '@Parameter4 = ''' + CAST(ISNULL(@UpdatedBy, '') AS varchar(100)),
        @ApplicationName varchar(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------
	EXEC spLogException @DatabaseName = @DatabaseName,
						@AdhocComments = @AdhocComments,
						@ProcedureParameters = @ProcedureParameters,
						@ApplicationName = @ApplicationName,
						@ErrorLogID = @ErrorLogID OUTPUT;
	RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
	RETURN (1);
	END CATCH
END
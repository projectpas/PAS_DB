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
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    07/25/2024   Vishal Suthar		Created
	2   11/13/2014    Abhishek Jirawla  Resolved errors of divide by zero
	3   12/12/2014    Vishal Suthar		Resolved issue with price calculation
	4   21-01-2025    Shrey Chandegara  Add Charge in total Revenue
	5   12-03-2026    Hemant Saliya		Corrected Charges Calucation
	6   17-Apr-026    Bhargav Saliya	 UOM Changes
     
 EXECUTE USP_UpdateSOQPartCostDetails 1536, 5530, 'ADMIN User', 1
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
					[UnitSalesPrice] [decimal](18, 6) NULL,
					[SalesPriceExtended] [decimal](18, 6) NULL,
					[MarkUpPercentage] [decimal](18, 6) NULL,
					[MarkUpAmount] [decimal](18, 6) NULL,
					[DiscountAmount] [decimal](18, 6) NULL,
					[GrossSaleAmount] [decimal](18, 6) NULL,
					[NetSaleAmount] [decimal](18, 6) NULL,
					[MiscCharges] [decimal](18, 6) NULL,
					[Freight] [decimal](18, 6) NULL,
					[TaxAmount] [decimal](18, 6) NULL,
					[TaxPercentage] [decimal](18, 6) NULL,
					[UnitCost] [decimal](18, 6) NULL,
					[UnitCostExtended] [decimal](18, 6) NULL,
					[MarginAmount] [decimal](18, 6) NULL,
					[MarginPercentage] [decimal](18, 6) NULL
				)

				INSERT INTO #SOQPartCostDetails (SalesOrderQuoteId, SalesOrderQuotePartId)
				SELECT @SalesOrderQuoteId, @SalesOrderQuotePartId
				
				IF((SELECT COUNT(1) FROM DBO.SalesOrderQuotePartCost SOQC WITH(NOLOCK) WHERE SOQC.SalesOrderQuoteId = @SalesOrderQuoteId AND SOQC.SalesOrderQuotePartId = @SalesOrderQuotePartId) > 0)
				BEGIN
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
					  [UnitSalesPrice] [decimal](18, 6) NULL,
					  [SalesPriceExtended] [decimal](18, 6) NULL,
					  [MarkUpPercentage] [decimal](18, 6) NULL,
					  [MarkUpAmount] [decimal](18, 6) NULL,
					  [DiscountPercentage] [decimal](18, 6) NULL,
					  [DiscountAmount] [decimal](18, 6) NULL,
					  [UnitCost] [decimal](18, 6) NULL,
					  [UnitCostExtended] [decimal](18, 6) NULL,
					  [MarginAmount] [decimal](18, 6) NULL,
					  [MarginPercentage] [decimal](18, 6) NULL
					)

					DECLARE @Freight_S AS [decimal](18, 6);
					DECLARE @Charges_S AS [decimal](18, 6);
					DECLARE @SalesOrderQuoteModuleId BIGINT;

					SELECT @Freight_S = ISNULL(SUM(F.BillingAmount), 0) FROM [DBO].[SalesOrderQuoteFreight] F WITH (NOLOCK)
					WHERE F.SalesOrderQuotePartId = @SalesOrderQuotePartId AND ISNULL(IsDeleted, 0) = 0;

					SELECT @Charges_S = ISNULL(SUM(C.BillingAmount), 0) FROM [DBO].[SalesOrderQuoteCharges] C WITH (NOLOCK)
					WHERE C.SalesOrderQuotePartId = @SalesOrderQuotePartId AND ISNULL(IsDeleted, 0) = 0;

					DECLARE @UnitSalesPrice_S AS [decimal](18, 6) = 0;
					DECLARE @SalesPriceExtended_S AS [decimal](18, 6) = 0;
					DECLARE @UnitCost_S AS [decimal](18, 6);
					DECLARE @UnitCostExtended_S AS [decimal](18, 6);
					DECLARE @DiscountAmount_S AS [decimal](18, 6);

					INSERT INTO #SOQStocklineDetails ([SalesOrderQuoteId], [SalesOrderQuotePartId], [SalesOrderQuoteStocklineId], [UnitSalesPrice], [SalesPriceExtended], [MarkUpPercentage], [MarkUpAmount], [DiscountPercentage], [DiscountAmount], [UnitCost],[UnitCostExtended],[MarginAmount],[MarginPercentage])
					SELECT [SalesOrderQuoteId], [SalesOrderQuotePartId], [SalesOrderQuoteStocklineId], [UnitSalesPrice], [UnitSalesPriceExtended], [MarkUpPercentage], [MarkUpAmount], [DiscountPercentage], [DiscountAmount], [UnitCost],[UnitCostExtended],[MarginAmount],[MarginPercentage]
					FROM [DBO].[SalesOrderQuoteStockLineCost] WITH (NOLOCK) WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId;

					IF EXISTS (SELECT TOP 1 * FROM [DBO].[SalesOrderQuoteStockLineCost] WITH (NOLOCK) WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId)
					BEGIN
						SELECT @MasterLoopID = MAX(ID) FROM #SOQStocklineDetails;
						WHILE (@MasterLoopID > 0)
						BEGIN
							DECLARE @SOQPartId BIGINT;
							DECLARE @SOQStocklineId BIGINT;
							DECLARE @PartQty [decimal](18, 6) = 0;
							DECLARE @StockLineQty [decimal](18, 6) = 0;

							SELECT @SOQPartId = [SalesOrderQuotePartId], @SOQStocklineId = [SalesOrderQuoteStocklineId] FROM #SOQStocklineDetails WHERE ID  = @MasterLoopID

							SELECT @PartQty = QtyQuoted FROM [DBO].[SalesOrderQuotePartV1] WITH (NOLOCK) WHERE SalesOrderQuotePartId = @SOQPartId;
							SELECT @StockLineQty = QtyQuoted FROM [DBO].[SalesOrderQuoteStocklineV1] WITH (NOLOCK) WHERE SalesOrderQuotePartId = @SOQPartId AND SalesOrderQuoteStocklineId = @SOQStocklineId AND ISNULL(IsDeleted, 0) = 0;

							DECLARE @calculatedCharges BIGINT;

							SET @calculatedCharges = CASE WHEN ISNULL(@Charges_S, 0) > 0 THEN ((CASE WHEN @PartQty > 0 THEN (ISNULL(@Charges_S, 0) / ISNULL(@PartQty, 0)) ELSE 0 END) * ISNULL(@StockLineQty, 0)) ELSE 0 END;

							UPDATE DBO.SalesOrderQuoteStockLineCost
							SET UnitSalesPriceExtended = (ISNULL(UnitSalesPrice, 0) * @StockLineQty),
							UnitCostExtended = (ISNULL(UnitCost, 0) * @StockLineQty),
							NetSaleAmountPerUnit = (ISNULL(UnitSalesPrice, 0) + (MarkUpAmount / @StockLineQty)) - (DiscountAmount / @StockLineQty),
							NetSaleAmount = ((ISNULL(UnitSalesPrice, 0) * @StockLineQty) + MarkUpAmount) - DiscountAmount,
							MarginAmount = (((ISNULL(UnitSalesPrice, 0) * @StockLineQty) + MarkUpAmount) - DiscountAmount) - ISNULL(UnitCostExtended, 0),
							MarginPercentage = CASE WHEN (((ISNULL(UnitSalesPrice, 0) * @StockLineQty) + MarkUpAmount) - DiscountAmount) > 0 THEN
												((((((ISNULL(UnitSalesPrice, 0) * @StockLineQty) + MarkUpAmount) - DiscountAmount) - ISNULL(UnitCostExtended, 0)) * 100) / (((ISNULL(UnitSalesPrice, 0) * @StockLineQty) + MarkUpAmount) - DiscountAmount))
												ELSE 0 END
							--((((((ISNULL(UnitSalesPrice, 0) * @StockLineQty) + MarkUpAmount) - DiscountAmount) - ISNULL(UnitCostExtended, 0)) * 100) / (((ISNULL(UnitSalesPrice, 0) * @StockLineQty) + MarkUpAmount) - DiscountAmount))
							WHERE SalesOrderQuotePartId = @SOQPartId AND SalesOrderQuoteStocklineId = @SOQStocklineId AND ISNULL(IsDeleted, 0) = 0;

							SET @MasterLoopID = @MasterLoopID - 1;
						END

						UPDATE DBO.SalesOrderQuotePartCost
						SET UnitSalesPriceExtended = (SELECT SUM(SOSC.UnitSalesPriceExtended) FROM DBO.SalesOrderQuoteStockLineCost SOSC WHERE SOSC.SalesOrderQuotePartId = @SalesOrderQuotePartId),
						UnitCostExtended = (SELECT SUM(ISNULL(SOSC.UnitCostExtended, 0)) FROM DBO.SalesOrderQuoteStockLineCost SOSC WHERE SOSC.SalesOrderQuotePartId = @SalesOrderQuotePartId),
						NetSaleAmount = (SELECT SUM(ISNULL(SOSC.NetSaleAmount, 0)) FROM DBO.SalesOrderQuoteStockLineCost SOSC WHERE SOSC.SalesOrderQuotePartId = @SalesOrderQuotePartId),
						TotalRevenue = (SELECT SUM(ISNULL(SOSC.NetSaleAmount, 0)) + ISNULL(@Charges_S, 0) FROM DBO.SalesOrderQuoteStockLineCost SOSC WHERE SOSC.SalesOrderQuotePartId = @SalesOrderQuotePartId)
						WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId;
					END
					ELSE
					BEGIN
						SELECT @PartQty = QtyQuoted FROM [DBO].[SalesOrderQuotePartV1] WITH (NOLOCK) WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId;

						UPDATE DBO.SalesOrderQuotePartCost
						SET UnitSalesPriceExtended = ISNULL(UnitSalesPrice, 0) * @PartQty,
						UnitCostExtended = ISNULL(UnitCost, 0) * @PartQty,
						NetSaleAmount = (ISNULL((ISNULL(UnitSalesPrice, 0) * @PartQty), 0) + MarkUpAmount) - DiscountAmount,
						TotalRevenue = ((ISNULL((ISNULL(UnitSalesPrice, 0) * @PartQty), 0) + MarkUpAmount) - DiscountAmount) + ISNULL(@Charges_S, 0)
						WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId;
					END

					DECLARE @CustomerId bigint = 0;
					DECLARE @SalesTax AS [decimal](18, 6) = 0;

					SELECT @CustomerId = [CustomerId] FROM [dbo].[SalesOrderQuote] WITH(NOLOCK) WHERE SalesOrderQuoteId = @SalesOrderQuoteId;
					
					UPDATE DBO.SalesOrderQuotePartCost
					SET 
					Freight = ISNULL(@Freight_S, 0),
					MiscCharges = ISNULL(@Charges_S, 0),
					MarkUpAmount = ISNULL(MarkUpAmount, 0),
					MarginAmount = (((ISNULL(UnitSalesPriceExtended, 0) + ISNULL(MarkUpAmount, 0)) - ISNULL(DiscountAmount, 0)) + ISNULL(@Charges_S, 0)) - ISNULL(UnitCostExtended, 0),
					MarginPercentage = CASE WHEN (((UnitSalesPriceExtended + MarkUpAmount) - DiscountAmount) + @Charges_S) > 0 THEN ((((((UnitSalesPriceExtended + MarkUpAmount) - DiscountAmount) + @Charges_S) - UnitCostExtended) * 100) / (((UnitSalesPriceExtended + MarkUpAmount) - DiscountAmount) + @Charges_S)) ELSE 0 END,
					TaxPercentage = @SalesTax,
					TaxAmount = ((((UnitSalesPriceExtended + MarkUpAmount) - DiscountAmount) * @SalesTax) / 100)
					WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId
				END
				ELSE
				BEGIN
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
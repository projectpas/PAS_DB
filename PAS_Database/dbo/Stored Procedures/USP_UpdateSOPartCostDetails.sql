/*************************************************************           
 ** File:   [USP_UpdateSOPartCostDetails]           
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
     
 EXECUTE USP_UpdateSOPartCostDetails 766, 1, 'ADMIN User', 1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_UpdateSOPartCostDetails]
(
	@SalesOrderId BIGINT = NULL,
	@SalesOrderPartId BIGINT = NULL,
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
				IF OBJECT_ID(N'tempdb..#SOPartCostDetails') IS NOT NULL
				BEGIN
					DROP TABLE #SOPartCostDetails
				END
				
				CREATE TABLE #SOPartCostDetails
				(
					ID BIGINT NOT NULL IDENTITY, 
					[SalesOrderId] [bigint] NOT NULL,
					[SalesOrderPartId] [bigint] NOT NULL,
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

				INSERT INTO #SOPartCostDetails (SalesOrderId, SalesOrderPartId)
				SELECT @SalesOrderId, @SalesOrderPartId
				
				IF((SELECT COUNT(1) FROM DBO.SalesOrderPartCost SOC WITH(NOLOCK) WHERE SOC.SalesOrderId = @SalesOrderId AND SOC.SalesOrderPartId = @SalesOrderPartId) > 0)
				BEGIN
					DECLARE @MasterLoopID AS INT;
					DECLARE @SalesOrderStocklineId AS BIGINT;

					IF OBJECT_ID(N'tempdb..#SOStocklineDetails') IS NOT NULL
					BEGIN
					  DROP TABLE #SOStocklineDetails
					END

					CREATE TABLE #SOStocklineDetails (
					  ID bigint NOT NULL IDENTITY,
					  [SalesOrderId] [bigint] NOT NULL,
					  [SalesOrderPartId] [bigint] NOT NULL,
					  [SalesOrderStocklineId] [bigint] NOT NULL,
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

					SELECT @Freight_S = ISNULL(SUM(F.BillingAmount), 0) FROM [DBO].[SalesOrderFreight] F WITH (NOLOCK)
					WHERE F.SalesOrderPartId = @SalesOrderPartId;

					SELECT @Charges_S = ISNULL(SUM(C.BillingAmount), 0) FROM [DBO].[SalesOrderCharges] C WITH (NOLOCK)
					WHERE C.SalesOrderPartId = @SalesOrderPartId;

					DECLARE @UnitSalesPrice_S AS [decimal](18, 4) = 0;
					DECLARE @SalesPriceExtended_S AS [decimal](18, 4) = 0;
					DECLARE @UnitCost_S AS [decimal](18, 4);
					DECLARE @UnitCostExtended_S AS [decimal](18, 4);
					DECLARE @DiscountAmount_S AS [decimal](18, 4);

					INSERT INTO #SOStocklineDetails ([SalesOrderId], [SalesOrderPartId], [SalesOrderStocklineId], [UnitSalesPrice], [SalesPriceExtended], [MarkUpPercentage], [MarkUpAmount], [DiscountPercentage], [DiscountAmount], [UnitCost],[UnitCostExtended],[MarginAmount],[MarginPercentage])
					SELECT [SalesOrderId], [SalesOrderPartId], [SalesOrderStocklineId], [UnitSalesPrice], [UnitSalesPriceExtended], [MarkUpPercentage], [MarkUpAmount], [DiscountPercentage], [DiscountAmount], [UnitCost],[UnitCostExtended],[MarginAmount],[MarginPercentage]
					FROM [DBO].[SalesOrderStockLineCost] WITH (NOLOCK) WHERE SalesOrderPartId = @SalesOrderPartId;

					IF EXISTS (SELECT TOP 1 * FROM [DBO].[SalesOrderStockLineCost] WITH (NOLOCK) WHERE SalesOrderPartId = @SalesOrderPartId)
					BEGIN
						SELECT @MasterLoopID = MAX(ID) FROM #SOStocklineDetails;
						WHILE (@MasterLoopID > 0)
						BEGIN
							DECLARE @SOPartId BIGINT;
							DECLARE @SOStocklineId BIGINT;
							DECLARE @PartQty INT = 0;
							DECLARE @StockLineQty INT = 0;

							SELECT @SOPartId = [SalesOrderPartId], @SOStocklineId = [SalesOrderStocklineId] FROM #SOStocklineDetails WHERE ID  = @MasterLoopID

							SELECT @PartQty = QtyOrder FROM [DBO].[SalesOrderPartV1] WITH (NOLOCK) WHERE SalesOrderPartId = @SOPartId;
							SELECT @StockLineQty = QtyOrder FROM [DBO].[SalesOrderStocklineV1] WITH (NOLOCK) WHERE SalesOrderPartId = @SOPartId AND SalesOrderStocklineId = @SOStocklineId;

							DECLARE @calculatedCharges BIGINT;

							SET @calculatedCharges = CASE WHEN ISNULL(@Charges_S, 0) > 0 THEN (CASE WHEN ISNULL(@PartQty, 0) > 0 THEN (ISNULL(@Charges_S, 0) / ISNULL(@PartQty, 0)) ELSE 0 END * ISNULL(@StockLineQty, 0)) ELSE 0 END;

							UPDATE DBO.SalesOrderStockLineCost
							SET UnitSalesPriceExtended = (ISNULL(UnitSalesPrice, 0) * @StockLineQty),
							NetSaleAmount = ((ISNULL(UnitSalesPrice, 0) * @StockLineQty) + MarkUpAmount) - DiscountAmount, --(ISNULL(UnitSalesPrice, 0) * @StockLineQty),
							MarginAmount = (ISNULL((ISNULL(UnitSalesPrice, 0) * @StockLineQty), 0) + @calculatedCharges) - ISNULL(UnitCostExtended, 0),
							MarginPercentage = CASE WHEN (ISNULL((ISNULL(UnitSalesPrice, 0) * @StockLineQty), 0) + @calculatedCharges) > 0 THEN ((((ISNULL((ISNULL(UnitSalesPrice, 0) * @StockLineQty), 0) + @calculatedCharges) - ISNULL(UnitCostExtended, 0)) * 100) / (ISNULL((ISNULL(UnitSalesPrice, 0) * @StockLineQty), 0) + @calculatedCharges)) ELSE 0 END
							WHERE SalesOrderPartId = @SOPartId AND SalesOrderStocklineId = @SOStocklineId;

							SET @MasterLoopID = @MasterLoopID - 1;
						END

						UPDATE DBO.SalesOrderPartCost
						SET UnitSalesPrice = (SELECT SUM(ISNULL(SOSC.UnitSalesPrice, 0)) FROM DBO.SalesOrderStockLineCost SOSC WHERE SOSC.SalesOrderPartId = @SalesOrderPartId),
						UnitSalesPriceExtended = (SELECT SUM(SOSC.UnitSalesPriceExtended) FROM DBO.SalesOrderStockLineCost SOSC WHERE SOSC.SalesOrderPartId = @SalesOrderPartId),
						UnitCost = (SELECT SUM(ISNULL(SOSC.UnitCost, 0)) FROM DBO.SalesOrderStockLineCost SOSC WHERE SOSC.SalesOrderPartId = @SalesOrderPartId),
						UnitCostExtended = (SELECT SUM(ISNULL(SOSC.UnitCostExtended, 0)) FROM DBO.SalesOrderStockLineCost SOSC WHERE SOSC.SalesOrderPartId = @SalesOrderPartId)
						WHERE SalesOrderPartId = @SalesOrderPartId;
					END
					ELSE
					BEGIN
						DECLARE @QtyRequested AS INT;
						SELECT @QtyRequested = [QtyRequested] FROM [DBO].[SalesOrderPartV1] WITH (NOLOCK) WHERE SalesOrderPartId = @SalesOrderPartId;

						SELECT @SalesPriceExtended_S = (@QtyRequested * ISNULL(UnitSalesPrice, 0)),
						@UnitCostExtended_S = (@QtyRequested * ISNULL(UnitCost, 0)),
						@DiscountAmount_S = DiscountAmount
						FROM [DBO].[SalesOrderPartCost] WITH (NOLOCK) WHERE SalesOrderPartId = @SalesOrderPartId;

						UPDATE DBO.SalesOrderPartV1
						SET QtyRequested = [QtyRequested] FROM [DBO].[SalesOrderPartV1] WITH (NOLOCK) WHERE SalesOrderPartId = @SalesOrderPartId;
					END

					DECLARE @CustomerId bigint = 0;
					DECLARE @SalesTax AS [decimal](18, 4) = 0;

					SELECT @CustomerId = [CustomerId] FROM [dbo].[SalesOrder] WITH(NOLOCK) WHERE SalesOrderId = @SalesOrderId;
					
					UPDATE DBO.SalesOrderPartCost
					SET 
					NetSaleAmount = (UnitSalesPriceExtended + MarkUpAmount) - DiscountAmount,
					Freight = ISNULL(@Freight_S, 0),
					MiscCharges = ISNULL(@Charges_S, 0),
					MarkUpAmount = ISNULL(MarkUpAmount, 0),
					MarginAmount = (((ISNULL(UnitSalesPriceExtended, 0) + ISNULL(MarkUpAmount, 0)) - ISNULL(DiscountAmount, 0)) + ISNULL(@Charges_S, 0)) - ISNULL(UnitCostExtended, 0),
					TotalRevenue = ((UnitSalesPriceExtended + MarkUpAmount) - DiscountAmount) + @Charges_S,
					MarginPercentage = CASE WHEN (((UnitSalesPriceExtended + MarkUpAmount) - DiscountAmount) + @Charges_S) > 0 THEN ((((((UnitSalesPriceExtended + MarkUpAmount) - DiscountAmount) + @Charges_S) - UnitCostExtended) * 100) / (((UnitSalesPriceExtended + MarkUpAmount) - DiscountAmount) + @Charges_S)) ELSE 0 END,
					TaxPercentage = @SalesTax,
					TaxAmount = ((((UnitSalesPriceExtended + MarkUpAmount) - DiscountAmount) * @SalesTax) / 100)
					WHERE SalesOrderPartId = @SalesOrderPartId
				END
				ELSE
				BEGIN
					INSERT INTO dbo.SalesOrderPartCost (
							 [SalesOrderId]
							,[SalesOrderPartId]
							,[UnitSalesPrice]
							,[UnitSalesPriceExtended]
							,[MarkUpPercentage]
							,[MarkUpAmount]
							,[DiscountAmount]
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
					SELECT  SOCD.[SalesOrderId],
							SOCD.[SalesOrderPartId],
							SOCD.[UnitSalesPrice],
							SOCD.[SalesPriceExtended],
							SOCD.[MarkUpPercentage],
							SOCD.[MarkUpAmount],
							SOCD.[DiscountAmount],
							SOCD.[NetSaleAmount],
							SOCD.[MiscCharges],
							SOCD.[Freight],
							SOCD.[TaxAmount],
							SOCD.[TaxPercentage],
							SOCD.[UnitCost],
							SOCD.[UnitCostExtended],
							SOCD.[MarginAmount],
							SOCD.[MarginPercentage],
							@MasterCompanyId,
							@UpdatedBy,
							GETUTCDATE(),
							@UpdatedBy,
							GETUTCDATE(),
							1,
							0
					FROM #SOPartCostDetails SOCD
				END

				IF EXISTS (SELECT TOP 1 1 FROM DBO.SalesOrderStocklineV1 SOS WHERE SOS.SalesOrderPartId = @SalesOrderPartId)
				BEGIN
					UPDATE DBO.SalesOrderPartV1 
					SET QtyOrder = (SELECT SUM(ISNULL(SOS.QtyOrder, 0)) FROM DBO.SalesOrderStocklineV1 SOS WHERE SOS.SalesOrderPartId = @SalesOrderPartId)
					WHERE SalesOrderPartId = @SalesOrderPartId;
				END

				IF OBJECT_ID(N'tempdb..#SOPartCostDetails') IS NOT NULL
				BEGIN
					DROP TABLE #SOPartCostDetails
				END

				EXEC [DBO].[USP_UpdateSOCostDetails] @SalesOrderId, @UpdatedBy, @MasterCompanyId;
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
        @ProcedureParameters varchar(3000) = '@SalesOrderId = ''' + CAST(ISNULL(@SalesOrderId, '') AS varchar(100))
        + '@Parameter2 = ''' + CAST(ISNULL(@SalesOrderPartId, '') AS varchar(100))
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
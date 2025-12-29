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
    2    11/11/2024   Vishal Suthar Fix the calculations for part cost and stockline cost
    3    11/13/2024   Vishal Suthar Fixed issue with unit price and unit cost calculation
    4    11/26/2024   Vishal Suthar Fixed divide by zero error
    5    12/09/2024   Vishal Suthar Modified to remove Pick Ticket Qty on Unreserve
    6    01/06/2025   Vishal Suthar Added one parameter to identify if it's been called from unreserve action
	7    01/08/2025   AMIT GHEDIYA  Added one parameter to identify if it's been called from shipping or not
	8    21-01-2025   Shrey Chandegara   Add charge In totalRevenue
	9    22-01-2025   Abhishek Jirawla Commented the section for "Remove/Modify Pick Ticket on Un-Reserve" after discussion with Vishalbhai as it was creating problem after SO shipping 
	10	 06/18/2025	  AMIT GHEDIYA      Updated the sp for add paramm @IsFromRRO
  	11	 07/18/2025	  RAJESH GAMI     Calculate NetSaleAmountPerUnit in partCost table  
 EXECUTE USP_UpdateSOPartCostDetails 1283, 1467, 'ADMIN User', 1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_UpdateSOPartCostDetails]
(
	@SalesOrderId BIGINT = NULL,
	@SalesOrderPartId BIGINT = NULL,
	@UpdatedBy VARCHAR(100) = NULL,
	@MasterCompanyId INT = NULL,
	@IsUnreservedAction BIT = 0,
	@IsFromShipping BIT = 0,
	@isReserveOrUnreserve BIT = NULL,
	@IsFromRRO BIT = 0
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				
				DECLARE @SendStatusId INT = 0;

				SELECT @SendStatusId = Id FROM DBO.MasterSalesOrderStatus WITH(NOLOCK) WHERE [Name] = 'Sent';

				IF OBJECT_ID(N'tempdb..#SOPartCostDetails') IS NOT NULL
				BEGIN
					DROP TABLE #SOPartCostDetails
				END
				
				CREATE TABLE #SOPartCostDetails
				(
					ID BIGINT NOT NULL IDENTITY, 
					[SalesOrderId] [bigint] NOT NULL,
					[SalesOrderPartId] [bigint] NOT NULL,
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

					SELECT @Freight_S = ISNULL(SUM(F.BillingAmount), 0) FROM [DBO].[SalesOrderFreight] F WITH (NOLOCK)
					WHERE F.SalesOrderPartId = @SalesOrderPartId;

					SELECT @Charges_S = ISNULL(SUM(C.BillingAmount), 0) FROM [DBO].[SalesOrderCharges] C WITH (NOLOCK)
					WHERE C.SalesOrderPartId = @SalesOrderPartId;

					DECLARE @UnitSalesPrice_S AS [decimal](18, 6) = 0;
					DECLARE @SalesPriceExtended_S AS [decimal](18, 6) = 0;
					DECLARE @UnitCost_S AS [decimal](18, 6);
					DECLARE @UnitCostExtended_S AS [decimal](18, 6);
					DECLARE @DiscountAmount_S AS [decimal](18, 6);

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
							DECLARE @PartQty DECIMAL(18,6) = 0;
							DECLARE @StockLineQty DECIMAL(18,6) = 0;

							SELECT @SOPartId = [SalesOrderPartId], @SOStocklineId = [SalesOrderStocklineId] FROM #SOStocklineDetails WHERE ID  = @MasterLoopID

							SELECT @PartQty = QtyOrder FROM [DBO].[SalesOrderPartV1] WITH (NOLOCK) WHERE SalesOrderPartId = @SOPartId;
							SELECT @StockLineQty = QtyOrder FROM [DBO].[SalesOrderStocklineV1] WITH (NOLOCK) WHERE SalesOrderPartId = @SOPartId AND SalesOrderStocklineId = @SOStocklineId;

							DECLARE @calculatedCharges BIGINT;

							SET @calculatedCharges = CASE WHEN ISNULL(@Charges_S, 0) > 0 THEN (CASE WHEN ISNULL(@PartQty, 0) > 0 THEN (ISNULL(@Charges_S, 0) / ISNULL(@PartQty, 0)) ELSE 0 END * ISNULL(@StockLineQty, 0)) ELSE 0 END;

							UPDATE DBO.SalesOrderStockLineCost
							SET UnitSalesPriceExtended = (ISNULL(UnitSalesPrice, 0) * @StockLineQty),
							UnitCostExtended = (ISNULL(UnitCost, 0) * @StockLineQty),
							--NetSaleAmountPerUnit = (ISNULL(UnitSalesPrice, 0) + (MarkUpAmount / @StockLineQty)) - (DiscountAmount / @StockLineQty),
							NetSaleAmountPerUnit = 
								(ISNULL(UnitSalesPrice, 0) + 
								(CASE WHEN @StockLineQty = 0 THEN 0 ELSE MarkUpAmount / @StockLineQty END)) 
								- (CASE WHEN @StockLineQty = 0 THEN 0 ELSE DiscountAmount / @StockLineQty END),
							NetSaleAmount = ((ISNULL(UnitSalesPrice, 0) * @StockLineQty) + MarkUpAmount) - DiscountAmount,
							MarginAmount = (((ISNULL(UnitSalesPrice, 0) * @StockLineQty) + MarkUpAmount) - DiscountAmount) - ISNULL(UnitCostExtended, 0),
							--MarginPercentage = CASE WHEN (((ISNULL(UnitSalesPrice, 0) * @StockLineQty) + MarkUpAmount) - DiscountAmount) > 0 THEN
							--					((((((ISNULL(UnitSalesPrice, 0) * @StockLineQty) + MarkUpAmount) - DiscountAmount) - ISNULL(UnitCostExtended, 0)) * 100) / (((ISNULL(UnitSalesPrice, 0) * @StockLineQty) + MarkUpAmount) - DiscountAmount))
							--					ELSE 0 END
							MarginPercentage = 
								CASE 
									WHEN (((ISNULL(UnitSalesPrice, 0) * @StockLineQty) + MarkUpAmount) - DiscountAmount) = 0 THEN 0
									ELSE 
										((((ISNULL(UnitSalesPrice, 0) * @StockLineQty) + MarkUpAmount - DiscountAmount) - ISNULL(UnitCostExtended, 0)) * 100.0) 
										/ (((ISNULL(UnitSalesPrice, 0) * @StockLineQty) + MarkUpAmount - DiscountAmount))
								END
							WHERE SalesOrderPartId = @SOPartId AND SalesOrderStocklineId = @SOStocklineId;

							SET @MasterLoopID = @MasterLoopID - 1;
						END

						UPDATE DBO.SalesOrderPartCost
						SET 
						UnitSalesPriceExtended = (SELECT SUM(SOSC.UnitSalesPriceExtended) FROM DBO.SalesOrderStockLineCost SOSC WHERE SOSC.SalesOrderPartId = @SalesOrderPartId),
						UnitCostExtended = (SELECT SUM(ISNULL(SOSC.UnitCostExtended, 0)) FROM DBO.SalesOrderStockLineCost SOSC WHERE SOSC.SalesOrderPartId = @SalesOrderPartId),
						NetSaleAmount = (SELECT SUM(ISNULL(SOSC.NetSaleAmount, 0)) FROM DBO.SalesOrderStockLineCost SOSC WHERE SOSC.SalesOrderPartId = @SalesOrderPartId),
						TotalRevenue = (SELECT SUM(ISNULL(SOSC.NetSaleAmount, 0)) + ISNULL(@Charges_S, 0) FROM DBO.SalesOrderStockLineCost SOSC WHERE SOSC.SalesOrderPartId = @SalesOrderPartId)
						WHERE SalesOrderPartId = @SalesOrderPartId;
					END
					ELSE
					BEGIN
						SELECT @PartQty = QtyOrder FROM [DBO].[SalesOrderPartV1] WITH (NOLOCK) WHERE SalesOrderPartId = @SalesOrderPartId;

						UPDATE DBO.SalesOrderPartCost
						SET UnitSalesPriceExtended = ISNULL(UnitSalesPrice, 0) * @PartQty,
						UnitCostExtended = ISNULL(UnitCost, 0) * @PartQty,
						NetSaleAmount = (ISNULL((ISNULL(UnitSalesPrice, 0) * @PartQty), 0) + MarkUpAmount) - DiscountAmount,
						NetSaleAmountPerUnit = ((ISNULL((ISNULL(UnitSalesPrice, 0) * @PartQty), 0) + MarkUpAmount) - DiscountAmount)/ (CASE WHEN @PartQty > 0 THEN @PartQty ELSE 1 END),
						TotalRevenue = ((ISNULL((ISNULL(UnitSalesPrice, 0) * @PartQty), 0) + MarkUpAmount) - DiscountAmount) + ISNULL(@Charges_S, 0)
						WHERE SalesOrderPartId = @SalesOrderPartId;
					END

					DECLARE @SalesTax AS [decimal](18, 6) = 0;

					UPDATE DBO.SalesOrderPartCost
					SET 
					Freight = ISNULL(@Freight_S, 0),
					MiscCharges = ISNULL(@Charges_S, 0),
					MarkUpAmount = ISNULL(MarkUpAmount, 0),
					MarginAmount = (((ISNULL(UnitSalesPriceExtended, 0) + ISNULL(MarkUpAmount, 0)) - ISNULL(DiscountAmount, 0)) + ISNULL(@Charges_S, 0)) - ISNULL(UnitCostExtended, 0),
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

					IF(@IsFromRRO = 1)
					BEGIN
						UPDATE DBO.SalesOrderPartV1 
						SET QtyOrder = (SELECT SUM(ISNULL(SOS.QtyOrder, 0)) FROM DBO.SalesOrderStocklineV1 SOS WHERE SOS.SalesOrderPartId = @SalesOrderPartId AND SOS.StatusId = @SendStatusId),
						QtyReserved = (SELECT SUM(ISNULL(SOS.QtyReserved, 0)) FROM DBO.SalesOrderStocklineV1 SOS WHERE SOS.SalesOrderPartId = @SalesOrderPartId AND SOS.StatusId = @SendStatusId)
						WHERE SalesOrderPartId = @SalesOrderPartId;
					END
					ELSE
					BEGIN
						UPDATE DBO.SalesOrderPartV1 
						SET QtyOrder = (SELECT SUM(ISNULL(SOS.QtyOrder, 0)) FROM DBO.SalesOrderStocklineV1 SOS WHERE SOS.SalesOrderPartId = @SalesOrderPartId ),
						QtyReserved = (SELECT SUM(ISNULL(SOS.QtyReserved, 0)) FROM DBO.SalesOrderStocklineV1 SOS WHERE SOS.SalesOrderPartId = @SalesOrderPartId )
						WHERE SalesOrderPartId = @SalesOrderPartId;
					END
				END

				IF OBJECT_ID(N'tempdb..#SOPartCostDetails') IS NOT NULL
				BEGIN
					DROP TABLE #SOPartCostDetails
				END

				/* Remove/Modify Pick Ticket on Un-Reserve  */
				IF (@IsFromShipping = 0 AND @isReserveOrUnreserve = 0)
				BEGIN
					IF OBJECT_ID(N'tempdb..#tmpSOPickTicket') IS NOT NULL
					BEGIN
						DROP TABLE #tmpSOPickTicket 
					END
				
					CREATE TABLE #tmpSOPickTicket 
					(
						 ID BIGINT NOT NULL IDENTITY, 
						 SalesOrderPartId BIGINT NULL,
						 SalesOrderStocklineId BIGINT NULL,
						 StocklineId BIGINT NULL,
						 QtyToReserve DECIMAL(18,6) NULL,
						 QtyToShip DECIMAL(18,6) NULL,
						 QtyPtickTicketRemove DECIMAL(18,6) NULL,
					)

					INSERT INTO #tmpSOPickTicket (SalesOrderPartId, SalesOrderStocklineId, StocklineId, QtyToReserve, QtyToShip)
					SELECT SalesOrderPartId, SalesOrderStocklineId, StockLineId, QtyReserved,
					(SELECT SUM(QtyToShip) FROM DBO.SOPickTicket WITH (NOLOCK) WHERE SalesOrderPartStocklineId = sos.SalesOrderStocklineId AND SalesOrderId = @SalesOrderId AND StocklineId = sos.StockLineId)
					FROM dbo.SalesOrderStocklineV1 sos WHERE sos.SalesOrderPartId = @SalesOrderPartId

					UPDATE #tmpSOPickTicket SET QtyPtickTicketRemove = ISNULL(QtyToShip, 0) -  ISNULL(QtyToReserve, 0) FROM #tmpSOPickTicket;

					IF OBJECT_ID(N'tempdb..#tmpremovePT') IS NOT NULL
					BEGIN
						DROP TABLE #tmpremovePT 
					END
				
					CREATE TABLE #tmpremovePT 
					(
						ID BIGINT NOT NULL IDENTITY, 
						SalesOrderPartId BIGINT NULL,
						SalesOrderStocklineId BIGINT NULL,
						StocklineId BIGINT NULL,
						QtyToReserve DECIMAL(18,6) NULL,
						QtyToShip DECIMAL(18,6) NULL,
						QtyPtickTicketRemove DECIMAL(18,6) NULL,
						PickTicketId BIGINT NULL,
						PickTicketQtyToShip DECIMAL(18,6) NULL,
					)
					
					INSERT INTO #tmpremovePT  SELECT  TMP.SalesOrderPartId, TMP.SalesOrderStocklineId, TMP.StocklineId, TMP.QtyToReserve, TMP.QtyToShip, TMP.QtyPtickTicketRemove, SOP.SOPickTicketId, SOP.QtyToShip FROM dbo.SOPickTicket SOP INNER JOIN  #tmpSOPickTicket TMP
					ON TMP.SalesOrderPartId = SOP.SalesOrderPartId AND TMP.SalesOrderStocklineId = SOP.SalesOrderPartStocklineId WHERE TMP.QtyPtickTicketRemove > 0 AND  SOP.QtyToShip > 0 ORDER BY SOP.SOPickTicketId
		
					DECLARE @LoopID AS INT;
					SELECT  @LoopID = MAX(ID) FROM #tmpremovePT;

					DECLARE @PickTicketId BIGINT = 0;
					DECLARE @QtyRemove DECIMAL(18,6) = 0;
					DECLARE @QtyAvilable DECIMAL(18,6) = 0;
					DECLARE @PTQtytoShip DECIMAL(18,6) = 0;

					WHILE (@LoopID > 0)
					BEGIN
						SELECT @PickTicketId = PickTicketId, @QtyRemove = QtyPtickTicketRemove, @QtyAvilable = PickTicketQtyToShip FROM #tmpremovePT WHERE ID = @LoopID;

						IF @QtyRemove = 0 
						BEGIN
						   SET @QtyAvilable = 0
						END 

						IF @QtyRemove >= @QtyAvilable 
						BEGIN
							SET  @PTQtytoShip =  @QtyAvilable 
							SET @QtyRemove = @QtyRemove - @QtyAvilable
						END
						ELSE
						BEGIN
							SET  @PTQtytoShip = @QtyRemove
							SET @QtyRemove  = @PTQtytoShip
						END 
				
						UPDATE #tmpremovePT SET QtyPtickTicketRemove = @QtyRemove
								
						UPDATE dbo.SOPickTicket SET QtyToShip = (QtyToShip - @PTQtytoShip) WHERE SOPickTicketId = @PickTicketId;

						DELETE FROM dbo.SOPickTicket WHERE QtyToShip = 0 AND SOPickTicketId = @PickTicketId;
				
						SET @LoopID = @LoopID - 1;
					END

					IF OBJECT_ID(N'tempdb..#tmpremovePT') IS NOT NULL
					BEGIN
						DROP TABLE #tmpremovePT 
					END

					IF OBJECT_ID(N'tempdb..#tmpSOPickTicket') IS NOT NULL
					BEGIN
						DROP TABLE #tmpSOPickTicket 
					END
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
        ,@AdhocComments varchar(150) = 'USP_UpdateSOPartCostDetails',
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
/***************************************************************  
 ** File:   [USP_AddUpdateSalesOrderQuotePart]             
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used add or update sales order quote part details
 ** Purpose:
 ** Date:   07/25/2024

 ** Change History
 **************************************************************
 ** PR   Date         Author  		 Change Description
 ** --   --------     -------		 --------------------------------
    1    07/25/2024   Vishal Suthar	 Created

declare @p1 dbo.SOQPartListType
insert into @p1 values(1,766,3,7,3,180079,1,1,1,2,1,1,NULL,NULL,1.000000,250,0,0,250,0,90,160.00,'2024-09-18 00:00:00','2024-09-19 00:00:00','2024-09-20 00:00:00',250.00,0,0,250,90,64,0,NULL,N'',NULL,1,N'ADMIN User')
insert into @p1 values(1,766,3,7,3,180078,1,2,1,2,1,1,NULL,NULL,1.000000,120,0,0,120,0,90,30.00,'2024-09-18 00:00:00','2024-09-19 00:00:00','2024-09-20 00:00:00',120.00,0,0,120,90,25,0,NULL,N'',NULL,1,N'ADMIN User')
insert into @p1 values(NULL,766,7,7,3,NULL,1,NULL,1,1,1,0,NULL,19,1.000000,2000,0,0,2000,200,2000,0,'2024-09-18 00:00:00','2024-09-19 00:00:00','2024-09-20 00:00:00',2000.00,0,0,2000,2000,0,10,NULL,N'',NULL,1,N'ADMIN User')

exec USP_AddUpdateSalesOrderQuotePart @tbl_SalesOrderQuotePartList=@p1

***************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddUpdateSalesOrderQuotePart]
	@tbl_SalesOrderQuotePartList SOQPartListType READONLY
	--@tbl_SalesOrderQuoteStocklineList SOQStockLineListType READONLY
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	DECLARE @SOQPartLoopID AS INT;

	IF OBJECT_ID(N'tempdb..#SOQPartDetails') IS NOT NULL
	BEGIN
		DROP TABLE #SOQPartDetails
	END

	CREATE TABLE #SOQPartDetails
	(
		ID bigint NOT NULL IDENTITY,
		SalesOrderQuotePartId bigint,
		SalesOrderQuoteId bigint,
		ItemMasterId bigint,
		ConditionId bigint,
		PriorityId bigint,
		StocklineId bigint,
		QuantityQuote int,
		SalesOrderQuoteStocklineId bigint,
		StatusId int,
		QtyRequested int,
		QtyQuoted int,
		QtyAvailable int,
		QtyOH int,
		CurrencyId int,
		FxRate decimal(18,4),
		GrossSaleAmount decimal(18,4),
		DiscountAmount decimal(18,4),
		NetSaleAmount decimal(18,4),
		TaxAmount decimal(18,4),
		UnitCostExtended decimal(18,4),
		MarginAmount decimal(18,4),
		CustomerRequestDate datetime2(7),
		PromisedDate datetime2(7),
		EstimatedShipDate datetime2(7),
		UnitSalesPrice decimal(18,4),
		MarkUpPercentage decimal(18,4),
		DiscountPercentage decimal(18,4),
		MarkUpAmount decimal(18,4),
		SalesPriceExtended decimal(18,4),
		UnitCost decimal(18,4),
		MarginPercentage decimal(18,4),
		TaxPercentage decimal(18,4),
		StatusName varchar(100),
		AltOrEqType varchar(25),
		Notes nvarchar(max),
		MasterCompanyId int,
		CreatedBy varchar(100)
	)

	INSERT INTO #SOQPartDetails (SalesOrderQuotePartId,SalesOrderQuoteId,ItemMasterId,ConditionId,PriorityId,StocklineId,QuantityQuote,SalesOrderQuoteStocklineId,StatusId,
	QtyRequested,QtyQuoted,QtyAvailable,QtyOH,CurrencyId,FxRate,GrossSaleAmount,DiscountAmount,NetSaleAmount,TaxAmount,UnitCostExtended,MarginAmount,
	CustomerRequestDate,PromisedDate,EstimatedShipDate,UnitSalesPrice,MarkUpPercentage,DiscountPercentage,MarkUpAmount,SalesPriceExtended,UnitCost,
	MarginPercentage,TaxPercentage,StatusName,AltOrEqType,Notes,MasterCompanyId,CreatedBy)
	SELECT SalesOrderQuotePartId,SalesOrderQuoteId,ItemMasterId,ConditionId,PriorityId,StocklineId,QuantityQuote,SalesOrderQuoteStocklineId,StatusId,
	QtyRequested,QtyQuoted,QtyAvailable,QtyOH,CurrencyId,FxRate,GrossSaleAmount,DiscountAmount,NetSaleAmount,TaxAmount,UnitCostExtended,MarginAmount,
	CustomerRequestDate,PromisedDate,EstimatedShipDate,UnitSalesPrice,MarkUpPercentage,DiscountPercentage,MarkUpAmount,SalesPriceExtended,UnitCost,
	MarginPercentage,TaxPercentage,StatusName,AltOrEqType,Notes,MasterCompanyId,CreatedBy 
	FROM @tbl_SalesOrderQuotePartList;

	SELECT @SOQPartLoopID = MAX(ID) FROM #SOQPartDetails;

	WHILE (@SOQPartLoopID > 0)
	BEGIN
		DECLARE @SalesOrderQuotePartId BIGINT = 0;
		DECLARE @SalesOrderQuoteStocklineId BIGINT = 0;
		DECLARE @SalesOrderQuoteId BIGINT = 0;
		DECLARE @ItemMasterId BIGINT = 0;
		DECLARE @ConditionId BIGINT = 0;
		DECLARE @StocklineId BIGINT = 0;
		DECLARE @MasterCompanyId BIGINT = 0;
		DECLARE @UnitSalesPrice AS decimal(18,4);
		DECLARE @MarkUpAmount AS decimal(18,4);
		DECLARE @MarkUpPercentage AS decimal(18,4);
		DECLARE @DiscountAmount AS decimal(18,4);
		DECLARE @MarginAmount AS decimal(18,4);
		DECLARE @UnitCost AS decimal(18,4);
		DECLARE @MarginPercentage AS decimal(18,4);
		DECLARE @DiscountPercentage AS decimal(18,4);
		DECLARE @QtyQuoted AS INT;
		DECLARE @QtyRequested AS INT;
		DECLARE @QuantityToQuote AS INT;
		DECLARE @CreatedBy AS VARCHAR(100);
		DECLARE @Notes AS VARCHAR(MAX);
		DECLARE @CustomerRequestDate AS Datetime2(7);
		DECLARE @PromisedDate AS Datetime2(7);
		DECLARE @EstimatedShipDate AS Datetime2(7);

		SELECT @SalesOrderQuotePartId = SalesOrderQuotePartId, @SalesOrderQuoteId = SalesOrderQuoteId, @ItemMasterId = ItemMasterId, @ConditionId = ConditionId, @StocklineId = StocklineId,
		@SalesOrderQuoteStocklineId = SalesOrderQuoteStocklineId, @MasterCompanyId = MasterCompanyId, @UnitSalesPrice = UnitSalesPrice, @MarkUpAmount = MarkUpAmount, @DiscountAmount = DiscountAmount, @QtyQuoted = QtyQuoted,
		@CreatedBy = CreatedBy, @MarkUpPercentage = MarkUpPercentage, @UnitCost = UnitCost, @MarginAmount = MarginAmount, @MarginPercentage = MarginPercentage,
		@DiscountPercentage = DiscountPercentage, @QtyRequested = QtyRequested, @QuantityToQuote = QuantityQuote, @Notes = Notes, 
		@CustomerRequestDate = CustomerRequestDate, @PromisedDate = PromisedDate, @EstimatedShipDate = EstimatedShipDate
		FROM #SOQPartDetails WHERE ID = @SOQPartLoopID;
		
		IF (ISNULL(@SalesOrderQuotePartId, 0) = 0) -- Add New Part
		BEGIN
			DECLARE @SOQPartStatus BIGINT;
			SELECT @SOQPartStatus = SOPartStatusId FROM [DBO].[SOPartStatus] WITH (NOLOCK) WHERE [PartStatus] = 'Open';

			IF NOT EXISTS (SELECT * FROM [dbo].[SalesOrderQuotePartV1] WITH (NOLOCK) WHERE SalesOrderQuoteId = @SalesOrderQuoteId AND ItemMasterId = @ItemMasterId AND ConditionId = @ConditionId)
			BEGIN
				DECLARE @CurrencyCode VARCHAR(10) = '';
				DECLARE @CurrencyId BIGINT = 0;
			
				SELECT @CurrencyId = Curr.CurrencyId, @CurrencyCode = Curr.Code FROM [DBO].[CustomerFinancial] CF WITH (NOLOCK) 
				LEFT JOIN [DBO].[Currency] Curr WITH (NOLOCK) ON CF.CurrencyId = Curr.CurrencyId 
				LEFT JOIN [DBO].[SalesOrderQuote] SOQ WITH (NOLOCK) ON SOQ.CustomerId = CF.CustomerId
				WHERE SOQ.SalesOrderQuoteId = @SalesOrderQuoteId;

				INSERT INTO [dbo].[SalesOrderQuotePartV1] ([SalesOrderQuoteId],[ItemMasterId],[ConditionId],[QtyRequested],[QtyQuoted],[CurrencyId],[FxRate],[PriorityId],[StatusId],[CustomerRequestDate],[PromisedDate],[EstimatedShipDate],[Notes],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted])
				SELECT SalesOrderQuoteId, ItemMasterId, ConditionId, QtyRequested, QtyQuoted, CurrencyId, FxRate, PriorityId, @SOQPartStatus, CustomerRequestDate, PromisedDate, EstimatedShipDate, Notes, MasterCompanyId, CreatedBy, GETUTCDATE(), CreatedBy, GETUTCDATE(), 1, 0
				FROM #SOQPartDetails WHERE ID = @SOQPartLoopID;

				SET @SalesOrderQuotePartId = @@IDENTITY;

				DECLARE @SalesPrice AS decimal(18,4);
				DECLARE @MarkUpAmt AS decimal(18,4);
				DECLARE @DiscAmt AS decimal(18,4);
				DECLARE @GrossAmt AS decimal(18,4);
				DECLARE @NetSalesAmt AS decimal(18,4);

				SET @SalesPrice = ISNULL(@UnitSalesPrice, 0);
				SET @MarkUpAmt = ISNULL(@MarkUpAmount, 0);
				SET @DiscAmt = ISNULL(@DiscountAmount, 0);
				SET @GrossAmt = (@SalesPrice + @MarkUpAmt) * @QtyQuoted;
				SET @NetSalesAmt = @GrossAmt - (@DiscAmt * @QtyQuoted);

				INSERT INTO [dbo].[SalesOrderQuotePartCost] ([SalesOrderQuoteId], [SalesOrderQuotePartId], [UnitSalesPrice], [UnitSalesPriceExtended], [MarkUpPercentage], [MarkUpAmount], [DiscountPercentage], [DiscountAmount],
				[GrossSaleAmount], [NetSaleAmount], [MiscCharges], [Freight], [TaxAmount], [TaxPercentage], [UnitCost], [UnitCostExtended], [MarginAmount], [MarginPercentage], [TotalRevenue], 
				[MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
				SELECT SalesOrderQuoteId, @SalesOrderQuotePartId, UnitSalesPrice, ISNULL((UnitSalesPrice * QtyQuoted), 0), MarkUpPercentage, ISNULL((MarkUpAmount * QtyQuoted), 0), DiscountPercentage, ISNULL((DiscountAmount * QtyQuoted), 0),
				ISNULL(@GrossAmt, 0), @NetSalesAmt, NULL, NULL, TaxAmount, TaxPercentage, UnitCost, ISNULL((UnitCost * QtyQuoted), 0), MarginAmount, MarginPercentage, 0,
				MasterCompanyId, CreatedBy, GETUTCDATE(), CreatedBy, GETUTCDATE(), 1, 0
				FROM #SOQPartDetails WHERE ID = @SOQPartLoopID;
			END
			ELSE
			BEGIN
				SELECT @SalesOrderQuotePartId = SalesOrderQuotePartId FROM [dbo].[SalesOrderQuotePartV1] WITH (NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ConditionId = @ConditionId AND SalesOrderQuoteId = @SalesOrderQuoteId;
			END

			IF (@StockLineId IS NOT NULL AND @StockLineId > 0) -- Added at Stockline Level
			BEGIN
				DECLARE @InsertedSalesOrderQuoteStocklineId BIGINT;
				--DECLARE @MasterLoopID AS INT;

				--IF OBJECT_ID(N'tempdb..#SOQPartStocklineDetails') IS NOT NULL
				--BEGIN
				--  DROP TABLE #SOQPartStocklineDetails
				--END

				--CREATE TABLE #SOQPartStocklineDetails (
				--  ID bigint NOT NULL IDENTITY,
				--  [SalesOrderQuoteId] bigint NULL,
				--  [SalesOrderQuotePartId] bigint NULL,
				--  [SalesOrderQuoteStocklineId] bigint NULL,
				--  [StockLineId] bigint NULL,
				--  [QuantityToQuote] int NULL
				--)

				--INSERT INTO #SOQPartStocklineDetails (SalesOrderQuoteId, SalesOrderQuotePartId, SalesOrderQuoteStocklineId, StockLineId, QuantityToQuote)
				--SELECT SalesOrderQuoteId, SalesOrderQuotePartId, SalesOrderQuoteStocklineId, StockLineId, QuantityToQuoted FROM @tbl_SalesOrderQuoteStocklineList;

				--SELECT @MasterLoopID = MAX(ID) FROM #SOQPartStocklineDetails;

				--WHILE (@MasterLoopID > 0)
				--BEGIN
					--SELECT @StockLineId = StockLineId, @QtyQuoted = QuantityToQuote FROM #SOQPartStocklineDetails WHERE ID  = @MasterLoopID

					INSERT INTO [dbo].[SalesOrderQuoteStocklineV1] ([SalesOrderQuotePartId], [StockLineId], [ConditionId], [QtyQuoted], [QtyAvailable], [QtyOH], [CustomerRequestDate], [PromisedDate], [EstimatedShipDate], [StatusId], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
					SELECT @SalesOrderQuotePartId, STK.StockLineId, @ConditionId, @QuantityToQuote, STK.QuantityAvailable, STK.QuantityOnHand, @CustomerRequestDate, @PromisedDate, @EstimatedShipDate, @SOQPartStatus, @MasterCompanyId, @CreatedBy, GETUTCDATE(), @CreatedBy, GETUTCDATE(), 1, 0
					FROM DBO.Stockline STK WHERE STK.StockLineId = @StockLineId;

					SET @InsertedSalesOrderQuoteStocklineId = @@IDENTITY;

					SET @SalesPrice = ISNULL(@UnitSalesPrice, 0);
					SET @MarkUpAmt = ISNULL(@MarkUpAmount, 0);
					SET @DiscAmt = ISNULL(@DiscountAmount, 0);
					SET @GrossAmt = (@SalesPrice + @MarkUpAmt) * @QtyQuoted;
					SET @NetSalesAmt = @GrossAmt - (@DiscAmt * @QtyQuoted);

					INSERT INTO [dbo].[SalesOrderQuoteStockLineCost] ([SalesOrderQuoteId], [SalesOrderQuotePartId], [SalesOrderQuoteStocklineId], [UnitSalesPrice], [UnitSalesPriceExtended], [MarkUpPercentage], [MarkUpAmount], [NetSaleAmount],
					[UnitCost], [UnitCostExtended], [MarginAmount], [MarginPercentage], [DiscountPercentage], [DiscountAmount],
					[MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
				
					SELECT @SalesOrderQuoteId, @SalesOrderQuotePartId, @InsertedSalesOrderQuoteStocklineId, @UnitSalesPrice, ISNULL((@UnitSalesPrice * @QuantityToQuote), 0), @MarkUpPercentage, ISNULL((@MarkUpAmount * @QtyQuoted), 0), @NetSalesAmt,
					@UnitCost, ISNULL((@UnitCost * @QuantityToQuote), 0), @MarginAmount, @MarginPercentage, @DiscountPercentage, ISNULL((@DiscountAmount * @QtyQuoted), 0), 
					@MasterCompanyId, @CreatedBy, GETUTCDATE(), @CreatedBy, GETUTCDATE(), 1, 0
					FROM [DBO].[StockLine] Stkl 
					--LEFT JOIN #SOQPartStocklineDetails S_Stkl ON S_Stkl.StockLineId = Stkl.StockLineId
					WHERE Stkl.StockLineId = @StockLineId

					--SET @MasterLoopID = @MasterLoopID - 1;
				--END
			END
		END
		ELSE
		BEGIN
			UPDATE [DBO].[SalesOrderQuotePartV1]
			SET Notes = @Notes
			WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId

			-- Update Part Details
			DECLARE @QtyQuoted_U AS INT = 0;

			DECLARE @SalesPrice_U AS decimal(18,4);
			DECLARE @MarkUpAmt_U AS decimal(18,4);
			DECLARE @DiscAmt_U AS decimal(18,4);
			DECLARE @GrossAmt_U AS decimal(18,4);
			DECLARE @NetSalesAmt_U AS decimal(18,4);

			SET @SalesPrice_U = ISNULL(@UnitSalesPrice, 0);
			SET @MarkUpAmt_U = ISNULL(@MarkUpAmount, 0) * @QtyQuoted;
			SET @DiscAmt_U = ISNULL(@DiscountAmount, 0) * @QtyQuoted;
			SET @GrossAmt_U = (@SalesPrice_U + @MarkUpAmt_U) * @QtyQuoted;
			SET @NetSalesAmt_U = @GrossAmt_U - (@DiscAmt_U * @QtyQuoted);

			UPDATE [DBO].[SalesOrderQuotePartCost]
			SET UnitSalesPrice = @SalesPrice_U,
			MarkUpPercentage = @MarkUpPercentage,
			MarkUpAmount = @MarkUpAmt_U,
			DiscountPercentage = @DiscountPercentage,
			DiscountAmount = @DiscAmt_U,
			GrossSaleAmount = ISNULL(@GrossAmt_U, 0),
			NetSaleAmount = ISNULL(@NetSalesAmt_U, 0)
			WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId

			IF (@SalesOrderQuoteStocklineId IS NOT NULL AND @SalesOrderQuoteStocklineId > 0) -- Added at Stockline Level
			BEGIN
				UPDATE [DBO].[SalesOrderQuoteStocklineV1]
				SET CustomerRequestDate = @CustomerRequestDate,
				PromisedDate = @PromisedDate,
				EstimatedShipDate = @EstimatedShipDate
				WHERE SalesOrderQuoteStocklineId = @SalesOrderQuoteStocklineId;

				UPDATE [DBO].[SalesOrderQuoteStockLineCost]
				SET UnitSalesPrice = @UnitSalesPrice
				WHERE SalesOrderQuoteStocklineId = @SalesOrderQuoteStocklineId;
			END

			UPDATE [DBO].[SalesOrderQuotePartV1]
			SET QtyRequested = @QtyRequested,
			QtyQuoted = @QtyQuoted_U
			WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId;
		END

		SELECT @SalesOrderQuoteId, @SalesOrderQuotePartId, @CreatedBy, @MasterCompanyId;

		EXEC [dbo].[USP_UpdateSOQPartCostDetails] @SalesOrderQuoteId, @SalesOrderQuotePartId, @CreatedBy, @MasterCompanyId;

		SET @SOQPartLoopID = @SOQPartLoopID - 1;
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
		ROLLBACK TRAN;
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = 'USP_SalesOrderQuote_AddUpdateSalesOrderQuotePart',
            @ProcedureParameters varchar(3000) = '@SalesOrderQuoteId = ''' + CAST(ISNULL(@SalesOrderQuoteId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
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
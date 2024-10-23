/***************************************************************  
 ** File:   [USP_AddUpdateSalesOrderPart]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used add or update sales order part details
 ** Purpose:
 ** Date:   09/24/2024

 ** Change History
 **************************************************************
 ** PR   Date         Author  		 Change Description
 ** --   --------     -------		 --------------------------------
    1    09/24/2024   Vishal Suthar	 Created

declare @p1 dbo.SOPartListType
insert into @p1 values(1,1103,3,7,2,180079,NULL,1,1,1,NULL,NULL,1,1,120,0,0,120,0,90,0,'2024-09-24 00:00:00','2024-09-25 00:00:00','2024-09-26 00:00:00',120.00,0,0,120,90,85.4839,0,NULL,N'',N'<p>Note1</p>',1,N'ADMIN User')
insert into @p1 values(2,1103,7,7,2,NULL,NULL,1,1,1,NULL,NULL,1,1,2000,0,0,2000,0,2000,0,'2024-09-27 00:00:00','2024-09-28 00:00:00','2024-09-29 00:00:00',2000.00,0,0,2000,2000,0,0,NULL,N'',N'<p>Note21</p>',1,N'ADMIN User')

exec USP_AddUpdateSalesOrderPart @tbl_SalesOrderPartList=@p1

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddUpdateSalesOrderPart]
	@tbl_SalesOrderPartList SOPartListType READONLY
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	DECLARE @SOPartLoopID AS INT;

	IF OBJECT_ID(N'tempdb..#SOPartDetails') IS NOT NULL
	BEGIN
		DROP TABLE #SOPartDetails
	END

	CREATE TABLE #SOPartDetails
	(
		ID bigint NOT NULL IDENTITY,
		SalesOrderPartId bigint,
		SalesOrderId bigint,
		ItemMasterId bigint,
		ConditionId bigint,
		PriorityId bigint,
		StocklineId bigint,
		SalesOrderStocklineId bigint,
		StatusId int,
		QtyRequested int,
		QtyOrder int,
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

	INSERT INTO #SOPartDetails (SalesOrderPartId,SalesOrderId,ItemMasterId,ConditionId,PriorityId,StocklineId,SalesOrderStocklineId,StatusId,
	QtyRequested,QtyOrder,QtyAvailable,QtyOH,CurrencyId,FxRate,GrossSaleAmount,DiscountAmount,NetSaleAmount,TaxAmount,UnitCostExtended,MarginAmount,
	CustomerRequestDate,PromisedDate,EstimatedShipDate,UnitSalesPrice,MarkUpPercentage,DiscountPercentage,MarkUpAmount,SalesPriceExtended,UnitCost,
	MarginPercentage,TaxPercentage,StatusName,AltOrEqType,Notes,MasterCompanyId,CreatedBy)
	SELECT SalesOrderPartId,SalesOrderId,ItemMasterId,ConditionId,PriorityId,StocklineId,SalesOrderStocklineId,StatusId,
	QtyRequested,QtyOrder,QtyAvailable,QtyOH,CurrencyId,FxRate,GrossSaleAmount,DiscountAmount,NetSaleAmount,TaxAmount,UnitCostExtended,MarginAmount,
	CustomerRequestDate,PromisedDate,EstimatedShipDate,UnitSalesPrice,MarkUpPercentage,DiscountPercentage,MarkUpAmount,SalesPriceExtended,UnitCost,
	MarginPercentage,TaxPercentage,StatusName,AltOrEqType,Notes,MasterCompanyId,CreatedBy 
	FROM @tbl_SalesOrderPartList;

	SELECT @SOPartLoopID = MAX(ID) FROM #SOPartDetails;

	WHILE (@SOPartLoopID > 0)
	BEGIN
		DECLARE @SalesOrderPartId BIGINT = 0;
		DECLARE @SalesOrderStocklineId BIGINT = 0;
		DECLARE @SalesOrderId BIGINT = 0;
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
		DECLARE @QtyOrder AS INT;
		DECLARE @QtyRequested AS INT;
		DECLARE @CreatedBy AS VARCHAR(100);
		DECLARE @Notes AS VARCHAR(MAX);
		DECLARE @CustomerRequestDate AS Datetime2(7);
		DECLARE @PromisedDate AS Datetime2(7);
		DECLARE @EstimatedShipDate AS Datetime2(7);

		SELECT @SalesOrderPartId = SalesOrderPartId, @SalesOrderId = SalesOrderId, @ItemMasterId = ItemMasterId, @ConditionId = ConditionId, @StocklineId = StocklineId,
		@SalesOrderStocklineId = SalesOrderStocklineId, @MasterCompanyId = MasterCompanyId, @UnitSalesPrice = UnitSalesPrice, @MarkUpAmount = MarkUpAmount, @DiscountAmount = DiscountAmount, @QtyOrder = QtyOrder,
		@CreatedBy = CreatedBy, @MarkUpPercentage = MarkUpPercentage, @UnitCost = UnitCost, @MarginAmount = MarginAmount, @MarginPercentage = MarginPercentage,
		@DiscountPercentage = DiscountPercentage, @QtyRequested = QtyRequested, @Notes = Notes, 
		@CustomerRequestDate = CustomerRequestDate, @PromisedDate = PromisedDate, @EstimatedShipDate = EstimatedShipDate
		FROM #SOPartDetails WHERE ID = @SOPartLoopID;
		
		IF (ISNULL(@SalesOrderPartId, 0) = 0) -- Add New Part
		BEGIN
			DECLARE @SOPartStatus BIGINT;
			SELECT @SOPartStatus = SOPartStatusId FROM [DBO].[SOPartStatus] WITH (NOLOCK) WHERE [PartStatus] = 'Open';

			IF NOT EXISTS (SELECT * FROM [dbo].[SalesOrderPartV1] WITH (NOLOCK) WHERE SalesOrderId = @SalesOrderId AND ItemMasterId = @ItemMasterId AND ConditionId = @ConditionId)
			BEGIN
				DECLARE @CurrencyCode VARCHAR(10) = '';
				DECLARE @CurrencyId BIGINT = 0;
			
				SELECT @CurrencyId = Curr.CurrencyId, @CurrencyCode = Curr.Code FROM [DBO].[CustomerFinancial] CF WITH (NOLOCK) 
				LEFT JOIN [DBO].[Currency] Curr WITH (NOLOCK) ON CF.CurrencyId = Curr.CurrencyId 
				LEFT JOIN [DBO].[SalesOrder] SO WITH (NOLOCK) ON SO.CustomerId = CF.CustomerId
				WHERE SO.SalesOrderId = @SalesOrderId;

				INSERT INTO [dbo].[SalesOrderPartV1] ([SalesOrderId],[ItemMasterId],[ConditionId],[QtyRequested],[QtyOrder],[QtyReserved],[CurrencyId],[FxRate],[PriorityId],[StatusId],[CustomerRequestDate],[PromisedDate],[EstimatedShipDate],[Notes],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted])
				SELECT SalesOrderId, ItemMasterId, ConditionId, QtyRequested, QtyOrder, 0, CurrencyId, FxRate, PriorityId, @SOPartStatus, CustomerRequestDate, PromisedDate, EstimatedShipDate, Notes, MasterCompanyId, CreatedBy, GETUTCDATE(), CreatedBy, GETUTCDATE(), 1, 0
				FROM #SOPartDetails WHERE ID = @SOPartLoopID;

				SET @SalesOrderPartId = @@IDENTITY;

				DECLARE @SalesPrice AS decimal(18,4);
				DECLARE @MarkUpAmt AS decimal(18,4);
				DECLARE @DiscAmt AS decimal(18,4);
				DECLARE @GrossAmt AS decimal(18,4);
				DECLARE @NetSalesAmt AS decimal(18,4);

				SET @SalesPrice = ISNULL(@UnitSalesPrice, 0);
				SET @MarkUpAmt = ISNULL(@MarkUpAmount, 0);
				SET @DiscAmt = ISNULL(@DiscountAmount, 0);
				SET @GrossAmt = (@SalesPrice + @MarkUpAmt) * @QtyOrder;
				SET @NetSalesAmt = @GrossAmt - (@DiscAmt * @QtyOrder);

				INSERT INTO [dbo].[SalesOrderPartCost] ([SalesOrderId], [SalesOrderPartId], [UnitSalesPrice], [UnitSalesPriceExtended], [MarkUpPercentage], [MarkUpAmount], [DiscountPercentage], [DiscountAmount],
				[NetSaleAmount], [MiscCharges], [Freight], [TaxAmount], [TaxPercentage], [UnitCost], [UnitCostExtended], [MarginAmount], [MarginPercentage], [TotalRevenue], 
				[MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
				SELECT SalesOrderId, @SalesOrderPartId, UnitSalesPrice, ISNULL((UnitSalesPrice * QtyOrder), 0), MarkUpPercentage, ISNULL((MarkUpAmount * QtyOrder), 0), DiscountPercentage, ISNULL((DiscountAmount * QtyOrder), 0),
				@NetSalesAmt, NULL, NULL, TaxAmount, TaxPercentage, UnitCost, ISNULL((UnitCost * QtyOrder), 0), MarginAmount, MarginPercentage, 0,
				MasterCompanyId, CreatedBy, GETUTCDATE(), CreatedBy, GETUTCDATE(), 1, 0
				FROM #SOPartDetails WHERE ID = @SOPartLoopID;
			END
			ELSE
			BEGIN
				SELECT @SalesOrderPartId = SalesOrderPartId FROM [dbo].[SalesOrderPartV1] WITH (NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ConditionId = @ConditionId AND SalesOrderId = @SalesOrderId;
			END

			IF (@StockLineId IS NOT NULL AND @StockLineId > 0) -- Added at Stockline Level
			BEGIN
				DECLARE @InsertedSalesOrderStocklineId BIGINT;

				INSERT INTO [dbo].[SalesOrderStocklineV1] ([SalesOrderPartId], [StockLineId], [ConditionId], [QtyOrder], [QtyReserved], [QtyAvailable], [QtyOH], [CustomerRequestDate], [PromisedDate], [EstimatedShipDate], [StatusId], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
				SELECT @SalesOrderPartId, STK.StockLineId, @ConditionId, @QtyOrder, 0, STK.QuantityAvailable, STK.QuantityOnHand, @CustomerRequestDate, @PromisedDate, @EstimatedShipDate, @SOPartStatus, @MasterCompanyId, @CreatedBy, GETUTCDATE(), @CreatedBy, GETUTCDATE(), 1, 0
				FROM DBO.Stockline STK WHERE STK.StockLineId = @StockLineId;

				SET @InsertedSalesOrderStocklineId = @@IDENTITY;

				SET @SalesPrice = ISNULL(@UnitSalesPrice, 0);
				SET @MarkUpAmt = ISNULL(@MarkUpAmount, 0);
				SET @DiscAmt = ISNULL(@DiscountAmount, 0);
				SET @GrossAmt = (@SalesPrice + @MarkUpAmt) * @QtyOrder;
				SET @NetSalesAmt = @GrossAmt - (@DiscAmt * @QtyOrder);

				INSERT INTO [dbo].[SalesOrderStockLineCost] ([SalesOrderId], [SalesOrderPartId], [SalesOrderStocklineId], [UnitSalesPrice], [UnitSalesPriceExtended], [MarkUpPercentage], [MarkUpAmount], [NetSaleAmount],
				[UnitCost], [UnitCostExtended], [MarginAmount], [MarginPercentage], [DiscountPercentage], [DiscountAmount],
				[MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
				
				SELECT @SalesOrderId, @SalesOrderPartId, @InsertedSalesOrderStocklineId, @UnitSalesPrice, ISNULL((@UnitSalesPrice * @QtyOrder), 0), @MarkUpPercentage, ISNULL((@MarkUpAmount * @QtyOrder), 0), @NetSalesAmt,
				@UnitCost, ISNULL((@UnitCost * @QtyOrder), 0), @MarginAmount, @MarginPercentage, @DiscountPercentage, ISNULL((@DiscountAmount * @QtyOrder), 0), 
				@MasterCompanyId, @CreatedBy, GETUTCDATE(), @CreatedBy, GETUTCDATE(), 1, 0
				FROM [DBO].[StockLine] Stkl 
				WHERE Stkl.StockLineId = @StockLineId
			END
		END
		ELSE
		BEGIN
			UPDATE [DBO].[SalesOrderPartV1]
			SET Notes = @Notes,
			CustomerRequestDate = @CustomerRequestDate,
			PromisedDate = @PromisedDate,
			EstimatedShipDate = @EstimatedShipDate
			WHERE SalesOrderPartId = @SalesOrderPartId;

			-- Update Part Details
			DECLARE @QtyQuoted_U AS INT = 0;

			DECLARE @SalesPrice_U AS decimal(18,4);
			DECLARE @MarkUpAmt_U AS decimal(18,4);
			DECLARE @DiscAmt_U AS decimal(18,4);
			DECLARE @GrossAmt_U AS decimal(18,4);
			DECLARE @NetSalesAmt_U AS decimal(18,4);

			SET @SalesPrice_U = ISNULL(@UnitSalesPrice, 0);
			SET @MarkUpAmt_U = ISNULL(@MarkUpAmount, 0) * @QtyOrder;
			SET @DiscAmt_U = ISNULL(@DiscountAmount, 0) * @QtyOrder;
			SET @GrossAmt_U = (@SalesPrice_U + @MarkUpAmt_U) * @QtyOrder;
			SET @NetSalesAmt_U = @GrossAmt_U - (@DiscAmt_U * @QtyOrder);

			UPDATE [DBO].[SalesOrderPartCost]
			SET UnitSalesPrice = @SalesPrice_U,
			MarkUpPercentage = @MarkUpPercentage,
			MarkUpAmount = @MarkUpAmt_U,
			DiscountPercentage = @DiscountPercentage,
			DiscountAmount = @DiscAmt_U,
			NetSaleAmount = ISNULL(@NetSalesAmt_U, 0)
			WHERE SalesOrderPartId = @SalesOrderPartId

			PRINT @SalesOrderStocklineId;

			IF (@SalesOrderStocklineId IS NOT NULL AND @SalesOrderStocklineId > 0) -- Added at Stockline Level
			BEGIN
				SELECT @CustomerRequestDate, @PromisedDate, @EstimatedShipDate, @SalesOrderStocklineId;

				UPDATE [DBO].[SalesOrderStocklineV1]
				SET CustomerRequestDate = @CustomerRequestDate,
				PromisedDate = @PromisedDate,
				EstimatedShipDate = @EstimatedShipDate
				WHERE SalesOrderStocklineId = @SalesOrderStocklineId;

				UPDATE [DBO].[SalesOrderStockLineCost]
				SET UnitSalesPrice = @UnitSalesPrice
				WHERE SalesOrderStocklineId = @SalesOrderStocklineId;
			END

			--UPDATE [DBO].[SalesOrderPartV1]
			--SET QtyRequested = @QtyRequested,
			--QtyOrder = @QtyQuoted_U
			--WHERE SalesOrderPartId = @SalesOrderPartId;
		END

		SELECT @SalesOrderId, @SalesOrderPartId, @CreatedBy, @MasterCompanyId;

		EXEC [dbo].[USP_UpdateSOPartCostDetails] @SalesOrderId, @SalesOrderPartId, @CreatedBy, @MasterCompanyId;

		SET @SOPartLoopID = @SOPartLoopID - 1;
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
            ,@AdhocComments varchar(150) = 'USP_AddUpdateSalesOrderPart',
            @ProcedureParameters varchar(3000) = '@SalesOrderId = ''' + CAST(ISNULL(@SalesOrderId, '') AS varchar(100)),
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
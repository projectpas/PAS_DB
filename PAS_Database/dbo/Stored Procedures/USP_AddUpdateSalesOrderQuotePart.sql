/***************************************************************  
 ** File:   [USP_AddUpdateSalesOrderQuotePart]             
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used add or update sales order quote part details
 ** Purpose:
 ** Date:   07/25/2024

 ** Change History
 **************************************************************
 ** PR   Date         Author  			 Change Description
 ** --   --------     -------			 --------------------------------
    1    07/25/2024   Vishal Suthar		 Created
	2    12-11-2024   Shrey Chandegara	 Updated for IsNOQuote
	3    19-11-2024   AMIT GHEDIYA		 Added LOT Id
	4    12-12-2024   Vishal Suthar		 Modified query that updates QtyQuoted to Part Cost when No stockline is there
	5    05-07-2015   BHARGAV SALIYA	 Change the Save SOQ Order Using @MinsoqId
	6    15-09-2025	  Amit Ghediya		 Update for Reset Approval Process
	7    20-11-2025	  Rajesh Gami		Added UnitSalesPrice in SalesOrderQuotePartV1 table
	8    10-Apr-026   Bhargav Saliya	 UOM Changes 
declare @p1 dbo.SOQPartListType
insert into @p1 values(909,871,318,7,3,NULL,3,NULL,1,3,3,NULL,NULL,1,1.000000,378.2,5,6.12,348.84,0,0,348.84,'2024-11-06 00:00:00','2024-11-07 00:00:00',NULL,120.00,2,2.4,360.00,0,100,0,NULL,N'',NULL,1,N'admin')
insert into @p1 values(910,871,20753,9,3,NULL,3,NULL,1,3,3,NULL,NULL,NULL,1.000000,6.0,5,105.57,0,0,0,0,NULL,NULL,'2024-11-05 00:00:00',230.00,2,2.0,105.57,0,0,0,NULL,N'',NULL,1,N'admin')

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
	DECLARE @MinsoqId AS INT;

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
		QuantityQuote decimal(18,6),
		SalesOrderQuoteStocklineId bigint,
		StatusId int,
		QtyRequested decimal(18,6),
		QtyQuoted decimal(18,6),
		QtyAvailable decimal(18,6),
		QtyOH decimal(18,6),
		CurrencyId int,
		FxRate decimal(18,4),
		GrossSaleAmount decimal(18,6),
		DiscountAmount decimal(18,6),
		NetSaleAmount decimal(18,6),
		TaxAmount decimal(18,6),
		UnitCostExtended decimal(18,6),
		MarginAmount decimal(18,6),
		CustomerRequestDate datetime2(7),
		PromisedDate datetime2(7),
		EstimatedShipDate datetime2(7),
		UnitSalesPrice decimal(18,6),
		MarkUpPercentage decimal(18,6),
		DiscountPercentage decimal(18,6),
		MarkUpAmount decimal(18,6),
		SalesPriceExtended decimal(18,6),
		UnitCost decimal(18,6),
		MarginPercentage decimal(18,6),
		TaxPercentage decimal(18,6),
		StatusName varchar(100),
		AltOrEqType varchar(25),
		Notes nvarchar(max),
		MasterCompanyId int,
		CreatedBy varchar(100),
		IsNoQuote BIT NULL,
		IsLotAssigned BIT NULL,
		LotId BIGINT NULL
	)

	INSERT INTO #SOQPartDetails (SalesOrderQuotePartId,SalesOrderQuoteId,ItemMasterId,ConditionId,PriorityId,StocklineId,QuantityQuote,SalesOrderQuoteStocklineId,StatusId,
	QtyRequested,QtyQuoted,QtyAvailable,QtyOH,CurrencyId,FxRate,GrossSaleAmount,DiscountAmount,NetSaleAmount,TaxAmount,UnitCostExtended,MarginAmount,
	CustomerRequestDate,PromisedDate,EstimatedShipDate,UnitSalesPrice,MarkUpPercentage,DiscountPercentage,MarkUpAmount,SalesPriceExtended,UnitCost,
	MarginPercentage,TaxPercentage,StatusName,AltOrEqType,Notes,MasterCompanyId,CreatedBy,IsNoQuote,IsLotAssigned,LotId)
	SELECT SalesOrderQuotePartId,SalesOrderQuoteId,ItemMasterId,ConditionId,PriorityId,StocklineId,QuantityQuote,SalesOrderQuoteStocklineId,StatusId,
	QtyRequested,QtyQuoted,QtyAvailable,QtyOH,CurrencyId,FxRate,GrossSaleAmount,DiscountAmount,NetSaleAmount,TaxAmount,UnitCostExtended,MarginAmount,
	CustomerRequestDate,PromisedDate,EstimatedShipDate,UnitSalesPrice,MarkUpPercentage,DiscountPercentage,MarkUpAmount,SalesPriceExtended,UnitCost,
	MarginPercentage,TaxPercentage,StatusName,AltOrEqType,Notes,MasterCompanyId,CreatedBy,IsNoQuote,IsLotAssigned,LotId 
	FROM @tbl_SalesOrderQuotePartList;

	SELECT @SOQPartLoopID = MAX(ID) FROM #SOQPartDetails;
	select @MinsoqId = MIN(ID) FROM #SOQPartDetails;

	WHILE (@MinsoqId <= @SOQPartLoopID)
	BEGIN
		DECLARE @SalesOrderQuotePartId BIGINT = 0;
		DECLARE @SalesOrderQuoteStocklineId BIGINT = 0;
		DECLARE @SalesOrderQuoteId BIGINT = 0;
		DECLARE @ItemMasterId BIGINT = 0;
		DECLARE @ConditionId BIGINT = 0;
		DECLARE @StocklineId BIGINT = 0;
		DECLARE @MasterCompanyId BIGINT = 0;
		DECLARE @UnitSalesPrice AS decimal(18,6);
		DECLARE @MarkUpAmount AS decimal(18,6);
		DECLARE @MarkUpPercentage AS decimal(18,6);
		DECLARE @DiscountAmount AS decimal(18,6);
		DECLARE @MarginAmount AS decimal(18,6);
		DECLARE @UnitCost AS decimal(18,6);
		DECLARE @MarginPercentage AS decimal(18,6);
		DECLARE @DiscountPercentage AS decimal(18,6);
		DECLARE @QtyQuoted AS decimal(18,6);
		DECLARE @QtyRequested AS decimal(18,6);
		DECLARE @QuantityToQuote AS decimal(18,6);
		DECLARE @CreatedBy AS VARCHAR(100);
		DECLARE @Notes AS VARCHAR(MAX);
		DECLARE @CustomerRequestDate AS Datetime2(7);
		DECLARE @PromisedDate AS Datetime2(7);
		DECLARE @EstimatedShipDate AS Datetime2(7);
		DECLARE @IsNoQuote AS BIT = NULL;
		DECLARE @IsLotAssigned AS BIT = NULL;
		DECLARE @LotId AS BIGINT = 0;
		DECLARE @PriorityId BIGINT = 0,@StocklineCount INT =0;

		UPDATE TEMP_TABLE
		SET QuantityQuote =  ([dbo].[fn_ConvertUOM](ISNULL(QuantityQuote, 0),IM.[ConsumeUnitOfMeasure],IM.[StockUnitOfMeasure] ,0,TEMP_TABLE.MasterCompanyId)),
		QtyRequested =  ([dbo].[fn_ConvertUOM](ISNULL(QtyRequested, 0),IM.[ConsumeUnitOfMeasure],IM.[StockUnitOfMeasure] ,0,TEMP_TABLE.MasterCompanyId)),
		QtyQuoted =  ([dbo].[fn_ConvertUOM](ISNULL(QtyQuoted, 0),IM.[ConsumeUnitOfMeasure],IM.[StockUnitOfMeasure] ,0,TEMP_TABLE.MasterCompanyId)),
		QtyAvailable =  ([dbo].[fn_ConvertUOM](ISNULL(QtyAvailable, 0),IM.[ConsumeUnitOfMeasure],IM.[StockUnitOfMeasure] ,0,TEMP_TABLE.MasterCompanyId)),
		QtyOH =  ([dbo].[fn_ConvertUOM](ISNULL(QtyOH, 0),IM.[ConsumeUnitOfMeasure],IM.[StockUnitOfMeasure] ,0,TEMP_TABLE.MasterCompanyId)),
		GrossSaleAmount =  ([dbo].[fn_ConvertUOM](ISNULL(GrossSaleAmount, 0),IM.[ConsumeUnitOfMeasure],IM.[StockUnitOfMeasure] ,1,TEMP_TABLE.MasterCompanyId)),
		DiscountAmount =  ([dbo].[fn_ConvertUOM](ISNULL(DiscountAmount, 0),IM.[ConsumeUnitOfMeasure],IM.[StockUnitOfMeasure] ,1,TEMP_TABLE.MasterCompanyId)),
		NetSaleAmount =  ([dbo].[fn_ConvertUOM](ISNULL(NetSaleAmount, 0),IM.[ConsumeUnitOfMeasure],IM.[StockUnitOfMeasure] ,1,TEMP_TABLE.MasterCompanyId)),
		TaxAmount =  ([dbo].[fn_ConvertUOM](ISNULL(TaxAmount, 0),IM.[ConsumeUnitOfMeasure],IM.[StockUnitOfMeasure] ,1,TEMP_TABLE.MasterCompanyId)),
		UnitCostExtended =  ([dbo].[fn_ConvertUOM](ISNULL(UnitCostExtended, 0),IM.[ConsumeUnitOfMeasure],IM.[StockUnitOfMeasure] ,1,TEMP_TABLE.MasterCompanyId)),
		MarginAmount =  ([dbo].[fn_ConvertUOM](ISNULL(MarginAmount, 0),IM.[ConsumeUnitOfMeasure],IM.[StockUnitOfMeasure] ,1,TEMP_TABLE.MasterCompanyId)),
		UnitSalesPrice =  ([dbo].[fn_ConvertUOM](ISNULL(UnitSalesPrice, 0),IM.[ConsumeUnitOfMeasure],IM.[StockUnitOfMeasure] ,1,TEMP_TABLE.MasterCompanyId)),
		MarkUpAmount =  ([dbo].[fn_ConvertUOM](ISNULL(MarkUpAmount, 0),IM.[ConsumeUnitOfMeasure],IM.[StockUnitOfMeasure] ,1,TEMP_TABLE.MasterCompanyId)),
		SalesPriceExtended =  ([dbo].[fn_ConvertUOM](ISNULL(SalesPriceExtended, 0),IM.[ConsumeUnitOfMeasure],IM.[StockUnitOfMeasure] ,1,TEMP_TABLE.MasterCompanyId)),
		TEMP_TABLE.UnitCost =  ([dbo].[fn_ConvertUOM](ISNULL(TEMP_TABLE.UnitCost, 0),IM.[ConsumeUnitOfMeasure],IM.[StockUnitOfMeasure] ,1,TEMP_TABLE.MasterCompanyId))
		FROM #SOQPartDetails TEMP_TABLE
		JOIN dbo.ItemMaster IM WITH(NOLOCK) ON TEMP_TABLE.ItemMasterId = IM.ItemMasterId
		WHERE ID = @MinsoqId;

		SELECT @SalesOrderQuotePartId = SalesOrderQuotePartId, @SalesOrderQuoteId = SalesOrderQuoteId, @ItemMasterId = ItemMasterId, @ConditionId = ConditionId, @StocklineId = StocklineId,
		@SalesOrderQuoteStocklineId = SalesOrderQuoteStocklineId, @MasterCompanyId = MasterCompanyId, @UnitSalesPrice = UnitSalesPrice, @MarkUpAmount = MarkUpAmount, @DiscountAmount = DiscountAmount, @QtyQuoted = QtyQuoted,
		@CreatedBy = CreatedBy, @MarkUpPercentage = MarkUpPercentage, @UnitCost = UnitCost, @MarginAmount = MarginAmount, @MarginPercentage = MarginPercentage,
		@DiscountPercentage = DiscountPercentage, @QtyRequested = QtyRequested, @QuantityToQuote = QuantityQuote, @Notes = Notes, 
		@CustomerRequestDate = CustomerRequestDate, @PromisedDate = PromisedDate, @EstimatedShipDate = EstimatedShipDate,@IsNoQuote = IsNoQuote,
		@IsLotAssigned = IsLotAssigned,@LotId = LotId,@PriorityId = PriorityId
		FROM #SOQPartDetails WHERE ID = @MinsoqId;

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

				INSERT INTO [dbo].[SalesOrderQuotePartV1] ([SalesOrderQuoteId],[ItemMasterId],[ConditionId],[QtyRequested],[QtyQuoted],[CurrencyId],[FxRate],[PriorityId],[StatusId],[CustomerRequestDate],[PromisedDate],[EstimatedShipDate],[Notes],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],[IsLotAssigned],[LotId],UnitSalesPrice)
				SELECT SalesOrderQuoteId, ItemMasterId, ConditionId, QtyRequested, QtyQuoted, CurrencyId, FxRate, PriorityId, @SOQPartStatus, CustomerRequestDate, PromisedDate, EstimatedShipDate, Notes, MasterCompanyId, CreatedBy, GETUTCDATE(), CreatedBy, GETUTCDATE(), 1, 0,IsLotAssigned,LotId,UnitSalesPrice
				FROM #SOQPartDetails WHERE ID = @MinsoqId;

				SET @SalesOrderQuotePartId = SCOPE_IDENTITY();

				DECLARE @SalesPrice AS decimal(18,6);
				DECLARE @MarkUpAmt AS decimal(18,6);
				DECLARE @DiscAmt AS decimal(18,6);
				DECLARE @GrossAmt AS decimal(18,6);
				DECLARE @NetSalesAmt AS decimal(18,6);
				DECLARE @NetSalesPerUnitAmt AS decimal(18,6);

				SET @SalesPrice = ISNULL(@UnitSalesPrice, 0);
				SET @MarkUpAmt = ISNULL(@MarkUpAmount, 0);
				SET @DiscAmt = ISNULL(@DiscountAmount, 0);
				SET @GrossAmt = (@SalesPrice + @MarkUpAmt) * @QtyQuoted;
				SET @NetSalesAmt = @GrossAmt - (@DiscAmt * @QtyQuoted);
				SET @NetSalesPerUnitAmt = (@SalesPrice + @MarkUpAmt) - @DiscAmt;

				INSERT INTO [dbo].[SalesOrderQuotePartCost] ([SalesOrderQuoteId], [SalesOrderQuotePartId], [UnitSalesPrice], [UnitSalesPriceExtended], [MarkUpPercentage], [MarkUpAmount], [DiscountPercentage], [DiscountAmount],
				[GrossSaleAmount], [NetSaleAmount], [MiscCharges], [Freight], [TaxAmount], [TaxPercentage], [UnitCost], [UnitCostExtended], [MarginAmount], [MarginPercentage], [TotalRevenue], 
				[MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [NetSaleAmountPerUnit])
				SELECT SalesOrderQuoteId, @SalesOrderQuotePartId, UnitSalesPrice, ISNULL((UnitSalesPrice * QtyQuoted), 0), MarkUpPercentage, ISNULL((MarkUpAmount * QtyQuoted), 0), DiscountPercentage, ISNULL((DiscountAmount * QtyQuoted), 0),
				ISNULL(@GrossAmt, 0), @NetSalesAmt, NULL, NULL, TaxAmount, TaxPercentage, UnitCost, ISNULL((UnitCost * QtyQuoted), 0), MarginAmount, MarginPercentage, 0,
				MasterCompanyId, CreatedBy, GETUTCDATE(), CreatedBy, GETUTCDATE(), 1, 0, @NetSalesPerUnitAmt
				FROM #SOQPartDetails WHERE ID = @MinsoqId;
			END
			ELSE
			BEGIN
				SELECT @SalesOrderQuotePartId = SalesOrderQuotePartId FROM [dbo].[SalesOrderQuotePartV1] WITH (NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ConditionId = @ConditionId AND SalesOrderQuoteId = @SalesOrderQuoteId;
			END

			IF (@StockLineId IS NOT NULL AND @StockLineId > 0) -- Added at Stockline Level
			BEGIN
				DECLARE @InsertedSalesOrderQuoteStocklineId BIGINT;
				INSERT INTO [dbo].[SalesOrderQuoteStocklineV1] ([SalesOrderQuotePartId], [StockLineId], [ConditionId], [QtyQuoted], [QtyAvailable], [QtyOH], [CustomerRequestDate], [PromisedDate], [EstimatedShipDate], [StatusId], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [Notes])
				SELECT @SalesOrderQuotePartId, STK.StockLineId, @ConditionId, @QuantityToQuote, STK.QuantityAvailable, STK.QuantityOnHand, @CustomerRequestDate, @PromisedDate, @EstimatedShipDate, @SOQPartStatus, @MasterCompanyId, @CreatedBy, GETUTCDATE(), @CreatedBy, GETUTCDATE(), 1, 0, @Notes
				FROM DBO.Stockline STK WHERE STK.StockLineId = @StockLineId;

				SET @InsertedSalesOrderQuoteStocklineId = SCOPE_IDENTITY();

				SET @SalesPrice = ISNULL(@UnitSalesPrice, 0);
				SET @MarkUpAmt = ISNULL(@MarkUpAmount, 0);
				SET @DiscAmt = ISNULL(@DiscountAmount, 0);
				SET @GrossAmt = (@SalesPrice + @MarkUpAmt) * @QtyQuoted;
				SET @NetSalesAmt = @GrossAmt - (@DiscAmt * @QtyQuoted);
				SET @NetSalesPerUnitAmt = (@SalesPrice + @MarkUpAmt) - @DiscAmt;

				INSERT INTO [dbo].[SalesOrderQuoteStockLineCost] ([SalesOrderQuoteId], [SalesOrderQuotePartId], [SalesOrderQuoteStocklineId], [UnitSalesPrice], [UnitSalesPriceExtended], [MarkUpPercentage], [MarkUpAmount], [NetSaleAmount],
				[UnitCost], [UnitCostExtended], [MarginAmount], [MarginPercentage], [DiscountPercentage], [DiscountAmount],
				[MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [NetSaleAmountPerUnit])
				
				SELECT @SalesOrderQuoteId, @SalesOrderQuotePartId, @InsertedSalesOrderQuoteStocklineId, @UnitSalesPrice, ISNULL((@UnitSalesPrice * @QuantityToQuote), 0), @MarkUpPercentage, ISNULL((@MarkUpAmount * @QtyQuoted), 0), @NetSalesAmt,
				@UnitCost, ISNULL((@UnitCost * @QuantityToQuote), 0), @MarginAmount, @MarginPercentage, @DiscountPercentage, ISNULL((@DiscountAmount * @QtyQuoted), 0), 
				@MasterCompanyId, @CreatedBy, GETUTCDATE(), @CreatedBy, GETUTCDATE(), 1, 0, @NetSalesPerUnitAmt
				FROM [DBO].[StockLine] Stkl
				WHERE Stkl.StockLineId = @StockLineId;
			END

			--Update Reset Approve Process
			EXEC [dbo].[USP_SOQResetApprovalProcess] @SalesOrderQuoteId, @SalesOrderQuotePartId,@MasterCompanyId
		END
		ELSE
		BEGIN
			DECLARE @IsQtyRequestedModified BIT,@IsPriorityModified BIT,@IsUnitSalesModified BIT;;
			DECLARE @ExistingQtyReq DECIMAL(18,6),@ExistingPriority INT,@ExistingUnitSales DECIMAL(18,6);;

			SELECT @ExistingQtyReq = SOP.QtyRequested,@ExistingPriority = SOP.PriorityId FROM [DBO].[SalesOrderQuotePartV1] SOP WITH (NOLOCK) WHERE SOP.SalesOrderQuotePartId = @SalesOrderQuotePartId;
			
			IF(@SalesOrderQuoteStocklineId > 0)
			BEGIN
				 SELECT @ExistingUnitSales = SOPC.UnitSalesPrice  FROM [DBO].[SalesOrderQuoteStockLineCost] SOPC WITH (NOLOCK) WHERE SOPC.SalesOrderQuoteStocklineId = @SalesOrderQuoteStocklineId;
			END
			ELSE
			BEGIN
			     SELECT @ExistingUnitSales = SOPC.UnitSalesPrice  FROM [DBO].[SalesOrderQuotePartCost] SOPC WITH (NOLOCK) WHERE SOPC.SalesOrderQuotePartId = @SalesOrderQuotePartId;
			END

			SET @IsQtyRequestedModified = CASE WHEN @ExistingQtyReq <> @QtyRequested THEN 1 ELSE 0 END;
			SET @IsPriorityModified = CASE WHEN @ExistingPriority <> @PriorityId THEN 1 ELSE 0 END;
			SET @IsUnitSalesModified = CASE WHEN @ExistingUnitSales <> CAST(ROUND(@UnitSalesPrice, 0) AS INT) THEN 1 ELSE 0 END;
			SET @StocklineCount = ISNULL((SELECT COUNT(SalesOrderQuotePartId) FROM #SOQPartDetails WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId AND ISNULL(StocklineId,0) > 0),0)

			UPDATE [DBO].[SalesOrderQuotePartV1]
			SET 
			CustomerRequestDate = @CustomerRequestDate,
			PromisedDate = @PromisedDate,
			EstimatedShipDate = @EstimatedShipDate,
			Notes = @Notes,
			IsNoQuote = @IsNoQuote,
			QtyRequested = @QtyRequested,
			QtyQuoted = @QtyQuoted,
			UnitSalesPrice = (CASE WHEN @StocklineCount > 0 THEN UnitSalesPrice ELSE @UnitSalesPrice END)
			WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId

			-- Update Part Details
			DECLARE @QtyQuoted_U AS DECIMAL(18,6) = 0;

			DECLARE @SalesPrice_U AS decimal(18,6);
			DECLARE @MarkUpAmt_U AS decimal(18,6);
			DECLARE @DiscAmt_U AS decimal(18,6);
			DECLARE @GrossAmt_U AS decimal(18,6);
			DECLARE @NetSalesAmt_U AS decimal(18,6);
			DECLARE @NetSalesPerUnitAmt_U AS decimal(18,6);

			SET @SalesPrice_U = ISNULL(@UnitSalesPrice, 0);
			SET @MarkUpAmt_U = ISNULL(@MarkUpAmount, 0) * @QtyQuoted;
			SET @DiscAmt_U = ISNULL(@DiscountAmount, 0) * @QtyQuoted;
			SET @GrossAmt_U = ((@SalesPrice_U * @QtyQuoted) + @MarkUpAmt_U);
			SET @NetSalesAmt_U = @GrossAmt_U - (@DiscAmt_U);
			SET @NetSalesPerUnitAmt_U = ((@SalesPrice_U) + ISNULL(@MarkUpAmount, 0)) - (ISNULL(@DiscountAmount, 0));

			UPDATE [DBO].[SalesOrderQuotePartCost]
			SET UnitSalesPrice = @SalesPrice_U,
			MarkUpPercentage = @MarkUpPercentage,
			MarkUpAmount = @MarkUpAmt_U,
			DiscountPercentage = @DiscountPercentage,
			DiscountAmount = @DiscAmt_U,
			GrossSaleAmount = ISNULL(@GrossAmt_U, 0),
			NetSaleAmount = ISNULL(@NetSalesAmt_U, 0),
			NetSaleAmountPerUnit = @NetSalesPerUnitAmt_U
			WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId

			IF (@SalesOrderQuoteStocklineId IS NOT NULL AND @SalesOrderQuoteStocklineId > 0) -- Added at Stockline Level
			BEGIN
				UPDATE [DBO].[SalesOrderQuoteStocklineV1]
				SET CustomerRequestDate = @CustomerRequestDate,
				PromisedDate = @PromisedDate,
				EstimatedShipDate = @EstimatedShipDate,
				Notes = @Notes
				WHERE SalesOrderQuoteStocklineId = @SalesOrderQuoteStocklineId;

				UPDATE [DBO].[SalesOrderQuoteStockLineCost]
				SET UnitSalesPrice = @UnitSalesPrice,
				MarkUpPercentage = @MarkUpPercentage,
				DiscountPercentage = @DiscountPercentage,
				MarkUpAmount = @MarkUpAmt_U,
				DiscountAmount = @DiscAmt_U
				WHERE SalesOrderQuoteStocklineId = @SalesOrderQuoteStocklineId;
			END

			;WITH QuotedSums AS (
				SELECT SOP.SalesOrderQuotePartId, SUM(ISNULL(SOS.QtyQuoted, 0)) AS TotalQtyQuoted
				FROM [DBO].[SalesOrderQuotePartV1] SOP
				LEFT JOIN [DBO].[SalesOrderQuoteStocklineV1] SOS ON SOP.SalesOrderQuotePartId = SOS.SalesOrderQuotePartId
				WHERE SOS.SalesOrderQuotePartId IS NOT NULL
				GROUP BY SOP.SalesOrderQuotePartId
			)

			UPDATE SOP
			SET SOP.QtyRequested = @QtyRequested,
				SOP.QtyQuoted = CASE WHEN QS.TotalQtyQuoted > 0 THEN QS.TotalQtyQuoted ELSE SOP.QtyQuoted END
			FROM [DBO].[SalesOrderQuotePartV1] SOP
			INNER JOIN QuotedSums QS ON SOP.SalesOrderQuotePartId = QS.SalesOrderQuotePartId
			WHERE SOP.SalesOrderQuotePartId = @SalesOrderQuotePartId;

			IF NOT EXISTS (SELECT TOP 1 1 FROM [DBO].[SalesOrderQuoteStocklineV1] SOS WITH (NOLOCK) WHERE SOS.SalesOrderQuotePartId = @SalesOrderQuotePartId)
			BEGIN
				UPDATE SOP
				SET SOP.QtyQuoted = CASE WHEN @IsQtyRequestedModified = 1 THEN @QtyRequested ELSE @QtyQuoted END
				FROM [DBO].[SalesOrderQuotePartV1] SOP
				WHERE SOP.SalesOrderQuotePartId = @SalesOrderQuotePartId;
			END
			
			--Reset Approval Process
			IF(@IsQtyRequestedModified > 0 OR @IsPriorityModified > 0 OR @IsUnitSalesModified > 0)
			BEGIN
				 EXEC [dbo].[USP_SOQResetApprovalProcess] @SalesOrderQuoteId, @SalesOrderQuotePartId,@MasterCompanyId
			END
		END

		SELECT @SalesOrderQuoteId, @SalesOrderQuotePartId, @CreatedBy, @MasterCompanyId;

		EXEC [dbo].[USP_UpdateSOQPartCostDetails] @SalesOrderQuoteId, @SalesOrderQuotePartId, @CreatedBy, @MasterCompanyId;

		SET @MinsoqId = @MinsoqId + 1;
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
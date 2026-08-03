-- ===== PROCEDURE: [dbo].[USP_AddUpdateSalesOrderPart]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs2/USP_AddUpdateSalesOrderPart.sql) =====
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
	2    11/13/2014   Abhishek Jirawla  Modified to add Not only Stockline COst but also part cost in Quantity update
	3    11/21/2014   RAJESH GAMI       Modified to implemented the statusid while update 
	4    11/21/2014   Amit Ghediya		Modified to add ECCN & Dimension (L,W,H) add update time.
	5    12/07/2014   Moin Bloch		Modified to add AltOrEqType
	6    12-12-2024   Vishal Suthar		Modified query that updates QtyOrder to Part Cost when No stockline is there
	7    16-12-2024   Shrey Chandegara  Updated for @PriorityId in  not update proper
	5    05-07-2015   BHARGAV SALIYA	Change the Save SOQ Order Using @SOMInID
	6    15-09-2025	  Amit Ghediya		Update for Reset Approval Process
	7    20-11-2025	  Rajesh Gami		Added UnitSalesPrice in SalesOrderPartV1 table
	8    09/July/2026	  RAJESH GAMI		[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	9    20/July/2026	  RAJESH GAMI		[PN-17350] - Allow Non-Stock Inventory Parts in Sales Order Quote and Sales Order: removed IsNonStock=0 filters that excluded Non-Stock Stockline when creating a SO part stockline.
	10   30/July/2026	  MOIN BLOCH        [PN-17485] - Added [IsService],[IsNonStock] Conditions If IsNonStock then Create StockLine
	11   01/July/2026	  MOIN BLOCH        [PN-17485] - Update QtyOnhand And Qty Reserved in Stockline on update Part Qty
declare @p1 dbo.SOPartListType
insert into @p1 values(497,1269,216,12,2,178289,NULL,1,5,2,NULL,NULL,3,1,1200,0,0,1200,0,670,330.00,NULL,NULL,NULL,600.00,0,0,1200,335,44.17,0,NULL,N'',NULL,1,N'Jim Roberts')
insert into @p1 values(501,1269,264,2,2,NULL,NULL,1,3,0,NULL,NULL,3,1,0,0,0,0,0,0,0,NULL,NULL,NULL,300.00,0,0,900,0,100.00,0,NULL,N'',NULL,1,N'Jim Roberts')

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
	DECLARE @SOMInID AS INT;

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
		CreatedBy varchar(100),
		ECCN varchar(200),
		HSCODE varchar(200),
		Weight decimal(18,4),
		SizeLength decimal(18,4),
		SizeWidth decimal(18,4),
		SizeHeight decimal(18,4)
	)

	INSERT INTO #SOPartDetails (SalesOrderPartId,SalesOrderId,ItemMasterId,ConditionId,PriorityId,StocklineId,SalesOrderStocklineId,StatusId,
	QtyRequested,QtyOrder,QtyAvailable,QtyOH,CurrencyId,FxRate,GrossSaleAmount,DiscountAmount,NetSaleAmount,TaxAmount,UnitCostExtended,MarginAmount,
	CustomerRequestDate,PromisedDate,EstimatedShipDate,UnitSalesPrice,MarkUpPercentage,DiscountPercentage,MarkUpAmount,SalesPriceExtended,UnitCost,
	MarginPercentage,TaxPercentage,StatusName,AltOrEqType,Notes,MasterCompanyId,CreatedBy,
	ECCN,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight)
	SELECT SalesOrderPartId,SalesOrderId,ItemMasterId,ConditionId,PriorityId,StocklineId,SalesOrderStocklineId,StatusId,
	QtyRequested,QtyOrder,QtyAvailable,QtyOH,CurrencyId,FxRate,GrossSaleAmount,DiscountAmount,NetSaleAmount,TaxAmount,UnitCostExtended,MarginAmount,
	CustomerRequestDate,PromisedDate,EstimatedShipDate,UnitSalesPrice,MarkUpPercentage,DiscountPercentage,MarkUpAmount,SalesPriceExtended,UnitCost,
	MarginPercentage,TaxPercentage,StatusName,AltOrEqType,Notes,MasterCompanyId,CreatedBy,
	ECCN,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight
	FROM @tbl_SalesOrderPartList;

	SELECT @SOPartLoopID = MAX(ID) FROM #SOPartDetails;
	SELECT @SOMInID = MIN(ID) FROM #SOPartDetails;

	WHILE (@SOMInID <= @SOPartLoopID)
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
		DECLARE @SOPartStatus BIGINT;
		DECLARE @ECCN AS VARCHAR(200);
		DECLARE @HSCODE AS VARCHAR(200);
		DECLARE @Weight AS decimal(18,4);
		DECLARE @SizeLength AS decimal(18,4);
		DECLARE @SizeWidth AS decimal(18,4);
		DECLARE @SizeHeight AS decimal(18,4);
		DECLARE @PriorityId BIGINT = 0, @StocklineCount int = 0;

		SELECT @SalesOrderPartId = SalesOrderPartId, @SalesOrderId = SalesOrderId, @ItemMasterId = ItemMasterId, @ConditionId = ConditionId, @StocklineId = StocklineId,
		@SalesOrderStocklineId = SalesOrderStocklineId, @MasterCompanyId = MasterCompanyId, @UnitSalesPrice = UnitSalesPrice, @MarkUpAmount = MarkUpAmount, @DiscountAmount = DiscountAmount, @QtyOrder = QtyOrder,
		@CreatedBy = CreatedBy, @MarkUpPercentage = MarkUpPercentage, @UnitCost = UnitCost, @MarginAmount = MarginAmount, @MarginPercentage = MarginPercentage,
		@DiscountPercentage = DiscountPercentage, @QtyRequested = QtyRequested, @Notes = Notes, 
		@CustomerRequestDate = CustomerRequestDate, @PromisedDate = PromisedDate, @EstimatedShipDate = EstimatedShipDate,@SOPartStatus = StatusId,
		@ECCN = ECCN,@HSCODE = HSCODE, @Weight = [Weight], @SizeLength = SizeLength, @SizeWidth = SizeWidth, @SizeHeight = SizeHeight,@PriorityId = PriorityId
		FROM #SOPartDetails WHERE ID = @SOMInID;
		
		IF (ISNULL(@SalesOrderPartId, 0) = 0) -- Add New Part
		BEGIN
			SELECT @SOPartStatus = SOPartStatusId FROM [DBO].[SOPartStatus] WITH (NOLOCK) WHERE [PartStatus] = 'Open';

			IF NOT EXISTS (SELECT * FROM [dbo].[SalesOrderPartV1] WITH (NOLOCK) WHERE SalesOrderId = @SalesOrderId AND ItemMasterId = @ItemMasterId AND ConditionId = @ConditionId)
			BEGIN
				DECLARE @CurrencyCode VARCHAR(10) = '';
				DECLARE @CurrencyId BIGINT = 0,@IsService BIT = 0,@IsNonStock BIT = 0								 
			
				SELECT @CurrencyId = Curr.CurrencyId, @CurrencyCode = Curr.Code FROM [DBO].[CustomerFinancial] CF WITH (NOLOCK) 
				LEFT JOIN [DBO].[Currency] Curr WITH (NOLOCK) ON CF.CurrencyId = Curr.CurrencyId 
				LEFT JOIN [DBO].[SalesOrder] SO WITH (NOLOCK) ON SO.CustomerId = CF.CustomerId
				WHERE SO.SalesOrderId = @SalesOrderId;

				INSERT INTO [dbo].[SalesOrderPartV1] ([SalesOrderId],[ItemMasterId],[ConditionId],[QtyRequested],[QtyOrder],[QtyReserved],[CurrencyId],[FxRate],[PriorityId],[StatusId],[CustomerRequestDate],[PromisedDate],[EstimatedShipDate],[Notes],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],[ECCN],[HSCODE],[Weight],[SizeLength],[SizeWidth],[SizeHeight],[AltOrEqType],UnitSalesPrice)
				SELECT SalesOrderId, ItemMasterId, ConditionId, QtyRequested, QtyOrder, 0, CurrencyId, FxRate, PriorityId, @SOPartStatus, CustomerRequestDate, PromisedDate, EstimatedShipDate, Notes, MasterCompanyId, CreatedBy, GETUTCDATE(), CreatedBy, GETUTCDATE(), 1, 0,ECCN,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight,[AltOrEqType],UnitSalesPrice
				FROM #SOPartDetails WHERE ID = @SOMInID;

				SET @SalesOrderPartId = SCOPE_IDENTITY();

				DECLARE @SalesPrice AS decimal(18,4);
				DECLARE @MarkUpAmt AS decimal(18,4);
				DECLARE @DiscAmt AS decimal(18,4);
				DECLARE @GrossAmt AS decimal(18,4);
				DECLARE @NetSalesAmt AS decimal(18,4);
				DECLARE @NetSalesPerUnitAmt AS decimal(18,4);

				SET @SalesPrice = ISNULL(@UnitSalesPrice, 0);
				SET @MarkUpAmt = ISNULL(@MarkUpAmount, 0);
				SET @DiscAmt = ISNULL(@DiscountAmount, 0);
				SET @GrossAmt = (@SalesPrice + @MarkUpAmt) * @QtyOrder;
				SET @NetSalesAmt = @GrossAmt - (@DiscAmt * @QtyOrder);
				SET @NetSalesPerUnitAmt = (@SalesPrice + @MarkUpAmt) - @DiscAmt;

				INSERT INTO [dbo].[SalesOrderPartCost] ([SalesOrderId], [SalesOrderPartId], [UnitSalesPrice], [UnitSalesPriceExtended], [MarkUpPercentage], [MarkUpAmount], [DiscountPercentage], [DiscountAmount],
				[NetSaleAmount], [MiscCharges], [Freight], [TaxAmount], [TaxPercentage], [UnitCost], [UnitCostExtended], [MarginAmount], [MarginPercentage], [TotalRevenue], 
				[MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [NetSaleAmountPerUnit])
				SELECT SalesOrderId, @SalesOrderPartId, UnitSalesPrice, ISNULL((UnitSalesPrice * QtyOrder), 0), MarkUpPercentage, ISNULL((MarkUpAmount * QtyOrder), 0), DiscountPercentage, ISNULL((DiscountAmount * QtyOrder), 0),
				@NetSalesAmt, NULL, NULL, TaxAmount, TaxPercentage, UnitCost, ISNULL((UnitCost * QtyOrder), 0), MarginAmount, MarginPercentage, 0,
				MasterCompanyId, CreatedBy, GETUTCDATE(), CreatedBy, GETUTCDATE(), 1, 0, @NetSalesPerUnitAmt
				FROM #SOPartDetails WHERE ID = @SOMInID;				

				SELECT @IsService = ISNULL([IsService],0), @IsNonStock = ISNULL([IsNonStock],0) FROM [dbo].[ItemMaster] WITH (NOLOCK) WHERE [ItemMasterId] = @ItemMasterId;
			
				IF(@IsService = 1 AND @IsNonStock = 1 AND ISNULL(@StockLineId, 0) = 0)
				BEGIN				
					EXEC [dbo].[USP_CreateStocklineForNosStockSalesOrderPart] 
							   @SalesOrderId = @SalesOrderId,
							   @SalesOrderPartId = @SalesOrderPartId,
							   @ItemMasterId = @ItemMasterId,
							   @CreatedBy = @CreatedBy,
							   @MasterCompanyId = @MasterCompanyId,
							   @StockLineId = @StockLineId OUTPUT;
				END
			END
			ELSE
			BEGIN
				SELECT @SalesOrderPartId = SalesOrderPartId FROM [dbo].[SalesOrderPartV1] WITH (NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ConditionId = @ConditionId AND SalesOrderId = @SalesOrderId;
			END

			IF (@StockLineId IS NOT NULL AND @StockLineId > 0) -- Added at Stockline Level
			BEGIN
				DECLARE @InsertedSalesOrderStocklineId BIGINT;
				
				INSERT INTO [dbo].[SalesOrderStocklineV1] ([SalesOrderPartId], [StockLineId], [ConditionId], [QtyOrder], [QtyReserved], [QtyAvailable], [QtyOH], [CustomerRequestDate], [PromisedDate], [EstimatedShipDate], [StatusId], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [Notes],[ECCN],[HSCODE],[Weight],[SizeLength],[SizeWidth],[SizeHeight],[PriorityId])
				SELECT @SalesOrderPartId, STK.StockLineId, @ConditionId, @QtyOrder, 0, STK.QuantityAvailable, STK.QuantityOnHand, @CustomerRequestDate, @PromisedDate, @EstimatedShipDate, @SOPartStatus, @MasterCompanyId, @CreatedBy, GETUTCDATE(), @CreatedBy, GETUTCDATE(), 1, 0, @Notes,@ECCN,@HSCODE,@Weight,@SizeLength,@SizeWidth,@SizeHeight,@PriorityId
				FROM DBO.Stockline STK WHERE STK.StockLineId = @StockLineId;

				SET @InsertedSalesOrderStocklineId = SCOPE_IDENTITY();

				SET @SalesPrice = ISNULL(@UnitSalesPrice, 0);
				SET @MarkUpAmt = ISNULL(@MarkUpAmount, 0);
				SET @DiscAmt = ISNULL(@DiscountAmount, 0);
				SET @GrossAmt = (@SalesPrice + @MarkUpAmt) * @QtyOrder;
				SET @NetSalesAmt = @GrossAmt - (@DiscAmt * @QtyOrder);
				SET @NetSalesPerUnitAmt = (@SalesPrice + @MarkUpAmt) - @DiscAmt;

				INSERT INTO [dbo].[SalesOrderStockLineCost] ([SalesOrderId], [SalesOrderPartId], [SalesOrderStocklineId], [UnitSalesPrice], [UnitSalesPriceExtended], [MarkUpPercentage], [MarkUpAmount], [NetSaleAmount],
				[UnitCost], [UnitCostExtended], [MarginAmount], [MarginPercentage], [DiscountPercentage], [DiscountAmount],
				[MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [NetSaleAmountPerUnit])
				
				SELECT @SalesOrderId, @SalesOrderPartId, @InsertedSalesOrderStocklineId, @UnitSalesPrice, ISNULL((@UnitSalesPrice * @QtyOrder), 0), @MarkUpPercentage, ISNULL((@MarkUpAmount * @QtyOrder), 0), @NetSalesAmt,
				@UnitCost, ISNULL((@UnitCost * @QtyOrder), 0), @MarginAmount, @MarginPercentage, @DiscountPercentage, ISNULL((@DiscountAmount * @QtyOrder), 0), 
				@MasterCompanyId, @CreatedBy, GETUTCDATE(), @CreatedBy, GETUTCDATE(), 1, 0, @NetSalesPerUnitAmt
				FROM [DBO].[StockLine] Stkl 
				WHERE Stkl.StockLineId = @StockLineId
			END

			--Update Reset Approve Process
			EXEC [dbo].[USP_SOResetApprovalProcess] @SalesOrderId, @SalesOrderPartId,@MasterCompanyId
		END
		ELSE
		BEGIN
		
			DECLARE @IsQtyRequestedModified BIT,@IsPriorityModified BIT,@IsUnitSalesModified BIT;
			DECLARE @ExistingQtyReq INT,@ExistingPriority INT,@ExistingUnitSales DECIMAL;

			SELECT @ExistingQtyReq = SOP.QtyRequested,@ExistingPriority = PriorityId  FROM [DBO].[SalesOrderPartV1] SOP WITH (NOLOCK) WHERE SOP.SalesOrderPartId = @SalesOrderPartId;
			IF(@SalesOrderStocklineId > 0)
			BEGIN
				 SELECT @ExistingUnitSales = SOPC.UnitSalesPrice  FROM [DBO].[SalesOrderStockLineCost] SOPC WITH (NOLOCK) WHERE SOPC.SalesOrderStocklineId = @SalesOrderStocklineId;
			END
			ELSE
			BEGIN
			     SELECT @ExistingUnitSales = SOPC.UnitSalesPrice  FROM [DBO].[SalesOrderPartCost] SOPC WITH (NOLOCK) WHERE SOPC.SalesOrderPartId = @SalesOrderPartId;
			END
			SET @StocklineCount = ISNULL((SELECT COUNT(SalesOrderPartId) FROM #SOPartDetails WHERE SalesOrderPartId = @SalesOrderPartId AND ISNULL(StocklineId,0) > 0),0)

			UPDATE [DBO].[SalesOrderPartV1]
			SET Notes = @Notes,
			CustomerRequestDate = @CustomerRequestDate,
			PromisedDate = @PromisedDate,
			EstimatedShipDate = @EstimatedShipDate,
			StatusId =  CASE WHEN StatusId != @SOPartStatus AND ISNULL(@SOPartStatus,0) != 0 THEN @SOPartStatus ELSE StatusId END,			
			ECCN = @ECCN,
			HSCODE = @HSCODE,
			[Weight] = @Weight,
			SizeLength = @SizeLength,
			SizeWidth = @SizeWidth,
			SizeHeight = @SizeHeight,
			PriorityId = @PriorityId,
			UnitSalesPrice = (CASE WHEN @StocklineCount > 0 THEN UnitSalesPrice ELSE @UnitSalesPrice END)
			WHERE SalesOrderPartId = @SalesOrderPartId;

			UPDATE [DBO].[SalesOrderPartV1]
			SET  PriorityId = @PriorityId
			WHERE SalesOrderPartId = @SalesOrderPartId AND ItemMasterId = @ItemMasterId;

			-- Update Part Details
			DECLARE @QtyQuoted_U AS INT = 0;

			DECLARE @SalesPrice_U AS decimal(18,4);
			DECLARE @MarkUpAmt_U AS decimal(18,4);
			DECLARE @DiscAmt_U AS decimal(18,4);
			DECLARE @GrossAmt_U AS decimal(18,4);
			DECLARE @NetSalesAmt_U AS decimal(18,4);
			DECLARE @NetSalesPerUnitAmt_U AS decimal(18,4);

			SET @SalesPrice_U = ISNULL(@UnitSalesPrice, 0);
			SET @MarkUpAmt_U = ISNULL(@MarkUpAmount, 0) * @QtyOrder;
			SET @DiscAmt_U = ISNULL(@DiscountAmount, 0) * @QtyOrder;
			SET @GrossAmt_U = (@SalesPrice_U + @MarkUpAmt_U) * @QtyOrder;
			SET @NetSalesAmt_U = @GrossAmt_U - (@DiscAmt_U * @QtyOrder);
			SET @NetSalesPerUnitAmt_U = ((@SalesPrice_U) + ISNULL(@MarkUpAmount, 0)) - (ISNULL(@DiscountAmount, 0));

			UPDATE [DBO].[SalesOrderPartCost]
			SET UnitSalesPrice = @SalesPrice_U,
			MarkUpPercentage = @MarkUpPercentage,
			MarkUpAmount = @MarkUpAmt_U,
			DiscountPercentage = @DiscountPercentage,
			DiscountAmount = @DiscAmt_U,
			NetSaleAmount = ISNULL(@NetSalesAmt_U, 0),
			NetSaleAmountPerUnit = @NetSalesPerUnitAmt_U
			WHERE SalesOrderPartId = @SalesOrderPartId

			IF (@SalesOrderStocklineId IS NOT NULL AND @SalesOrderStocklineId > 0) -- Added at Stockline Level
			BEGIN
				UPDATE [DBO].[SalesOrderStocklineV1]
				SET QtyOrder = @QtyOrder,
				CustomerRequestDate = @CustomerRequestDate,
				PromisedDate = @PromisedDate,
				EstimatedShipDate = @EstimatedShipDate,
				Notes = @Notes,
				StatusId = CASE WHEN StatusId != @SOPartStatus AND ISNULL(@SOPartStatus,0) != 0 THEN @SOPartStatus ELSE StatusId END,
				ECCN = @ECCN,
				HSCODE = @HSCODE,
				[Weight] = @Weight,
				SizeLength = @SizeLength,
				SizeWidth = @SizeWidth,
				SizeHeight = @SizeHeight,
				PriorityId = @PriorityId
				WHERE SalesOrderStocklineId = @SalesOrderStocklineId;

				DECLARE @GrossAmt_S AS decimal(18,4);
				DECLARE @NetSalesAmt_S AS decimal(18,4);

				SET @MarkUpAmount = ISNULL(@MarkUpAmount, 0) * @QtyOrder;
				SET @DiscountAmount = ISNULL(@DiscountAmount, 0) * @QtyOrder;

				SET @GrossAmt_S = (@UnitSalesPrice + @MarkUpAmount);
				SET @NetSalesAmt_S = @GrossAmt_S - (@DiscountAmount);

				UPDATE [DBO].[SalesOrderStockLineCost]
				SET UnitSalesPrice = @UnitSalesPrice,
				MarkUpPercentage = @MarkUpPercentage,
				MarkUpAmount = @MarkUpAmount,
				DiscountPercentage = @DiscountPercentage,
				DiscountAmount = @DiscountAmount,
				NetSaleAmount = ISNULL(@NetSalesAmt_S, 0)
				WHERE SalesOrderStocklineId = @SalesOrderStocklineId;
			END


			SELECT @ExistingQtyReq = SOP.QtyRequested FROM [DBO].[SalesOrderPartV1] SOP WITH (NOLOCK) WHERE SOP.SalesOrderPartId = @SalesOrderPartId;
			SET @IsQtyRequestedModified = CASE WHEN @ExistingQtyReq <> @QtyRequested THEN 1 ELSE 0 END;
			SET @IsPriorityModified = CASE WHEN @ExistingPriority <> @PriorityId THEN 1 ELSE 0 END;
			SET @IsUnitSalesModified = CASE WHEN @ExistingUnitSales <> @UnitSalesPrice THEN 1 ELSE 0 END;

			;WITH QuotedSums AS (
				SELECT SOP.SalesOrderPartId, SUM(ISNULL(SOS.QtyOrder, 0)) AS TotalQtyQuoted
				FROM [DBO].[SalesOrderPartV1] SOP WITH (NOLOCK)
				LEFT JOIN [DBO].[SalesOrderStocklineV1] SOS WITH (NOLOCK) ON SOP.SalesOrderPartId = SOS.SalesOrderPartId
				WHERE SOS.SalesOrderPartId IS NOT NULL
				GROUP BY SOP.SalesOrderPartId
			)

			UPDATE SOP
			SET SOP.QtyRequested = @QtyRequested,
				SOP.QtyOrder = QS.TotalQtyQuoted
			FROM [DBO].[SalesOrderPartV1] SOP
				INNER JOIN QuotedSums QS ON SOP.SalesOrderPartId = QS.SalesOrderPartId
			WHERE SOP.SalesOrderPartId = @SalesOrderPartId;


			IF EXISTS(SELECT * FROM #SOPartDetails WHERE  SalesOrderPartId = @SalesOrderPartId)
			BEGIN
				;WITH QuotedSumsNoStockline AS (
					SELECT SOP.SalesOrderPartId, SUM(ISNULL(SOS.QtyOrder, 0)) AS TotalQtyQuoted
					FROM [DBO].[SalesOrderPartV1] SOP WITH (NOLOCK)
						INNER JOIN #SOPartDetails AS SPD  WITH (NOLOCK) ON  SPD.SalesOrderPartId = SOP.SalesOrderPartId
						LEFT JOIN [DBO].[SalesOrderStocklineV1] SOS WITH (NOLOCK) ON SOP.SalesOrderPartId = SOS.SalesOrderPartId
					WHERE SOS.SalesOrderPartId IS NULL
					GROUP BY SOP.SalesOrderPartId
				)

				UPDATE SOP
				SET SOP.QtyRequested = @QtyRequested,
					SOP.QtyOrder = CASE WHEN QS.TotalQtyQuoted > 0 THEN QS.TotalQtyQuoted ELSE SOP.QtyOrder END
				FROM [DBO].[SalesOrderPartV1] SOP
					INNER JOIN QuotedSumsNoStockline QS ON SOP.SalesOrderPartId = QS.SalesOrderPartId
				WHERE SOP.SalesOrderPartId = @SalesOrderPartId;
			END

			IF NOT EXISTS (SELECT TOP 1 1 FROM [DBO].[SalesOrderStocklineV1] SOS WITH (NOLOCK) WHERE SOS.SalesOrderPartId = @SalesOrderPartId)
			BEGIN
				UPDATE SOP
				SET SOP.QtyOrder = CASE WHEN @IsQtyRequestedModified = 1 THEN @QtyRequested ELSE @QtyOrder END
				FROM [DBO].[SalesOrderPartV1] SOP
				WHERE SOP.SalesOrderPartId = @SalesOrderPartId;
			END
			
			-- Update Stock Line For Non-Stock On Update
			IF (@SalesOrderStocklineId IS NOT NULL AND @SalesOrderStocklineId > 0) 
			BEGIN
				SELECT @StockLineId = [StockLineId] FROM [dbo].[SalesOrderStocklineV1] WITH(NOLOCK) WHERE [SalesOrderStocklineId] = @SalesOrderStocklineId;

				SELECT @IsService = ISNULL([IsService],0), @IsNonStock = ISNULL([IsNonStock],0) FROM [dbo].[Stockline] WITH (NOLOCK) WHERE [StockLineId] = @StockLineId
				IF(@IsService = 1 AND @IsNonStock = 1 AND ISNULL(@StockLineId, 0) > 0)
				BEGIN				
					UPDATE [dbo].[Stockline] 
					   SET [QuantityOnHand] = @QtyRequested,							   
						   [QuantityReserved] = @QtyRequested
					 WHERE [StockLineId] = @StockLineId

					UPDATE [dbo].[SalesOrderStocklineV1]
					   SET [QtyOrder] = @QtyRequested,							   
						   [QtyReserved] = @QtyRequested
					 WHERE [StockLineId] = @StockLineId
				END	
			END

			--Reset Approval Process
			IF(@IsQtyRequestedModified > 0 OR @IsPriorityModified > 0 OR @IsUnitSalesModified > 0)
			BEGIN
				 EXEC [dbo].[USP_SOResetApprovalProcess] @SalesOrderId, @SalesOrderPartId,@MasterCompanyId
			END
			
		END

		SELECT @SalesOrderId, @SalesOrderPartId, @CreatedBy, @MasterCompanyId;

		EXEC [dbo].[USP_UpdateSOPartCostDetails] @SalesOrderId, @SalesOrderPartId, @CreatedBy, @MasterCompanyId;	
		
		SET @SOMInID = @SOMInID + 1;
	END

	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
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
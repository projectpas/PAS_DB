/*************************************************************           
 ** File:   [SalesOrderReserveUnReserveParts]          
 ** Author:   AMIT GHEDIYA
 ** Description: This stored procedure is used to get SO approval list
 ** Purpose:         
 ** Date:   08/10/2024        
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    08/10/2024   AMIT GHEDIYA		Created
	2    21 Nov 2024  RAJESH GAMI		Modified to implemented change the status to OPEN/FULFILLED while RESERVE UN-RESERVE
	3    03 DEC 2024  Vishal Suthar		Fixed calculating markup and discount while adding stockline throught reservation
	4    05 DEC 2024  Vishal Suthar		Use stockline unitcost when stockline is added through reservation
	5    13 DEC 2024  AMIT GHEDIYA		Add RefrenceNumber in stocktable.
	6    17 DEC 2024   Shrey Chandegara  Add condition while execute USP_UpdateSOPartCostDetails this procedure 
	7    08 JAN 2025   AMIT GHEDIYA		 Added one parameter to identify if it's been called from shipping or not

declare @p1 dbo.SalesOrderReserveIssueParts
insert into @p1 values(NULL,1357,1629,161088,119,N'3100454',N'SENSOR',NULL,NULL,0,NULL,NULL,0,5,2,2,N'OH',0,NULL,50,3,NULL,0,NULL,2,NULL,NULL,NULL,NULL,0,NULL,2,'2024-11-18 13:51:53.2864044',NULL,N'OEM',0,NULL,1,NULL,0,0,0,0,0,NULL,N'STL-000004',N'CNTL--001282',47,N'CASCO CIRCUITS INC',NULL,NULL,1,N'ADMIN User',N'ADMIN User','2024-11-18 13:51:53.2864029','2024-11-18 13:51:53.2864029',1,0)
insert into @p1 values(NULL,1357,1629,161083,119,N'3100454',N'SENSOR',NULL,NULL,0,NULL,NULL,0,39,33,2,N'OH',0,NULL,50,3,NULL,0,NULL,33,NULL,NULL,NULL,NULL,0,NULL,2,'2024-11-18 13:51:53.2864063',NULL,N'OEM',0,NULL,1,NULL,0,0,0,0,0,NULL,N'STL000003',N'CNTL-001277',47,N'CASCO CIRCUITS INC',NULL,NULL,1,N'ADMIN User',N'ADMIN User','2024-11-18 13:51:53.2864060','2024-11-18 13:51:53.2864060',1,0)

exec dbo.SalesOrderReserveUnReserveParts @tbl_SalesOrderReserveIssueParts=@p1
**************************************************************/
CREATE   PROCEDURE [dbo].[SalesOrderReserveUnReserveParts] 
(
	@tbl_SalesOrderReserveIssueParts SalesOrderReserveIssueParts READONLY,
	@afterShipping BIT,
	@autoReserve BIT,
	@isFromShipping BIT = 0,
	@isReserveOrUnreserve BIT = NULL
)
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON

    BEGIN TRY
    BEGIN TRANSACTION
      BEGIN
		DECLARE @MasterLoopID INT = 0,
				@SalesOrderReservePartId BIGINT = 0,
				@SalesOrderPartId BIGINT = 0,
				@SalesOrderId BIGINT = 0,
				@ItemMasterId BIGINT = 0,
				@ConditionId BIGINT = 0,
				@StockLineId BIGINT = 0,
				@StocklineUnitCost DECIMAL(18,2) = 0,
				@Quantity INT = 0,
				@QtyToReserve INT = 0,
				@QtyToUnReserve INT = 0,
				@PartStatusId INT = 0,
				@CreatedBy VARCHAR(100),
				@MasterCompanyId BIGINT = 0,
				@SOPartStatus BIGINT,
				@SOPartStatusFulFill BIGINT,
				@ReservedById BIGINT = 0,
				@ReservedDate DATETIME2,
				@ReserveStatusId INT = 1,
				@IssueStatusId INT = 2,
				@ReserveAndIssueStatusId INT = 3,
				@UnIssueStatusId INT = 4,
				@UnReserveStatusId INT = 5,
				@ReservePartQtyToReserve INT = 0,
				@ReservePartTotalReserved INT = 0,
				@ReservePartQtyReserved INT = 0,
				@SalesOrderNumber VARCHAR(50) = NULL,
				@StkAutoReserveRefNumber VARCHAR(100) = 'Auto Reserve Stock - ',
				@StkReserveRefNumber VARCHAR(100) = 'Reserve Stock - ',
				@StkUnReserveRefNumber VARCHAR(100) = 'UnReserve - ',
				@RefNumber VARCHAR(100) = '';

		DECLARE @AlreadyQtyOrder INT = 0;
		DECLARE @AlreadyReservedQty INT = 0;

		SELECT @SOPartStatus = SOPartStatusId FROM [DBO].[SOPartStatus] WITH(NOLOCK) WHERE [PartStatus] = 'Open';
		SELECT @SOPartStatusFulFill = SOPartStatusId FROM [DBO].[SOPartStatus] WITH(NOLOCK) WHERE [PartStatus] = 'Fulfilled';

		IF OBJECT_ID(N'tempdb..#SalesOrderReserveIssueParts') IS NOT NULL
        BEGIN
            DROP TABLE #SalesOrderReserveIssueParts
        END

		CREATE TABLE #SalesOrderReserveIssueParts
        (
			[ID] [bigint] NOT NULL IDENTITY,
			[SalesOrderReservePartId] [bigint] NULL,
			[SalesOrderId] [bigint] NULL,
			[SalesOrderPartId] [bigint] NULL,
			[StockLineId] [bigint] NULL,
			[ItemMasterId] [bigint] NULL,
			[PartNumber] [varchar](500) NULL,
			[PartDescription] [varchar](500) NULL,
			[AltPartDescription] [varchar](500) NULL,
			[EquPartDescription] [varchar](500) NULL,
			[EquPartId] [bigint] NULL,
			[EquPartNumber] [varchar](500) NULL,
			[AltPartNumber] [varchar](500) NULL,
			[AltPartId] [bigint] NULL,
			[QuantityOnHand] [int] NULL,
			[QuantityAvailable] [int] NULL,
			[ConditionId] [bigint] NULL,
			[Condition] [varchar](200) NULL,
			[IsAltPart] [bit] NULL,
			[AltPartMasterPartId] [bigint] NULL,
			[Quantity] [int] NULL,
			[QuantityReserved] [int] NULL,
			[QuantityIssued] [int] NULL,
			[QuantityOnOrder] [int] NULL,
			[QuantityToReceive] [int] NULL,
			[QtyToReserve] [int] NULL,
			[QtyToIssued] [int] NULL,
			[QtyToUnReserve] [int] NULL,
			[QtyToUnIssued] [int] NULL,
			[QtyToReserveAndIssue] [int] NULL,
			[IssuedById] [bigint] NULL,
			[IssuedDate] [datetime2](7) NULL,
			[ReservedById] [bigint] NULL,
			[ReservedDate] [datetime2](7) NULL,
			[OemDer] [varchar](200) NULL,
			[StockType] [varchar](200) NULL,
			[IsEquPart] [bit] NULL,
			[EquPartMasterPartId] [bigint] NULL,
			[PartStatusId] [int] NULL,
			[TotalReserved] [int] NULL,
			[TotalIssued] [int] NULL,
			[UnitCost] [decimal](18, 4) NULL,
			[ExtendedCost] [decimal](18, 4) NULL,
			[UnitPrice] [decimal](18, 4) NULL,
			[ExtendedPrice] [decimal](18, 4) NULL,
			[AlternateFor] [varchar](200) NULL,
			[StockLineNumber] [varchar](200) NULL,
			[ControlNumber] [varchar](200) NULL,
			[QtyToBeReserved] [int] NULL,
			[ManufacturerName] [varchar](200) NULL,
			[LotId] [bigint] NULL,
			[IsLotQty] [bit] NULL,
			[MasterCompanyId] [int] NULL,
			[CreatedBy] [varchar](100) NULL,
			[UpdatedBy] [varchar](256) NULL,
			[CreatedDate] [datetime2](7) NULL,
			[UpdatedDate] [datetime2](7) NULL,
			[IsActive] [bit] NULL,
			[IsDeleted] [bit] NULL
		)

		INSERT INTO #SalesOrderReserveIssueParts
		([SalesOrderReservePartId], [SalesOrderId], [SalesOrderPartId], [StockLineId], [ItemMasterId], [PartNumber], [PartDescription],
		 [AltPartDescription], [EquPartDescription], [EquPartId], [EquPartNumber], [AltPartNumber], [AltPartId], [QuantityOnHand],
		 [QuantityAvailable], [ConditionId], [Condition], [IsAltPart], [AltPartMasterPartId], [Quantity], [QuantityReserved],
		 [QuantityIssued], [QuantityOnOrder], [QuantityToReceive], [QtyToReserve], [QtyToIssued], [QtyToUnReserve], [QtyToUnIssued],
		 [QtyToReserveAndIssue], [IssuedById], [IssuedDate], [ReservedById], [ReservedDate], [OemDer], [StockType],
		 [IsEquPart], [EquPartMasterPartId], [PartStatusId], [TotalReserved], [TotalIssued], [UnitCost], [ExtendedCost],
		 [UnitPrice], [ExtendedPrice], [AlternateFor], [StockLineNumber], [ControlNumber], [QtyToBeReserved], [ManufacturerName],
		 [LotId], [IsLotQty], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
		 [IsActive], [IsDeleted])
		SELECT [SalesOrderReservePartId], [SalesOrderId], [SalesOrderPartId], [StockLineId], [ItemMasterId], [PartNumber], [PartDescription],
		 [AltPartDescription], [EquPartDescription], [EquPartId], [EquPartNumber], [AltPartNumber], [AltPartId], [QuantityOnHand],
		 [QuantityAvailable], [ConditionId], [Condition], [IsAltPart], [AltPartMasterPartId], [Quantity], [QuantityReserved],
		 [QuantityIssued], [QuantityOnOrder], [QuantityToReceive], [QtyToReserve], [QtyToIssued], [QtyToUnReserve], [QtyToUnIssued],
		 [QtyToReserveAndIssue], [IssuedById], [IssuedDate], [ReservedById], [ReservedDate], [OemDer], [StockType],
		 [IsEquPart], [EquPartMasterPartId], [PartStatusId], [TotalReserved], [TotalIssued], [UnitCost], [ExtendedCost],
		 [UnitPrice], [ExtendedPrice], [AlternateFor], [StockLineNumber], [ControlNumber], [QtyToBeReserved], [ManufacturerName],
		 [LotId], [IsLotQty], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
		 [IsActive], [IsDeleted]
		FROM @tbl_SalesOrderReserveIssueParts;

		SELECT  @MasterLoopID = MAX(ID) FROM #SalesOrderReserveIssueParts;
		
		WHILE(@MasterLoopID > 0)
		BEGIN
			SELECT @SalesOrderReservePartId = [SalesOrderReservePartId],
						   @SalesOrderPartId = [SalesOrderPartId],
						   @SalesOrderId = [SalesOrderId],
						   @ItemMasterId = [ItemMasterId],
						   @ConditionId = [ConditionId],
						   @StockLineId = [StockLineId],
						   @Quantity = Quantity,
						   @QtyToReserve = [QtyToReserve],
						   @QtyToUnReserve = [QtyToUnReserve],
						   @PartStatusId = [PartStatusId],
						   @CreatedBy = [CreatedBy],
						   @ReservedById = [ReservedById],
						   @ReservedDate = [ReservedDate],
						   @MasterCompanyId = [MasterCompanyId]
					FROM #SalesOrderReserveIssueParts WITH(NOLOCK) WHERE [ID] = @MasterLoopID;

			DECLARE @PartQty INT = 0,
					@PartQtyRequested INT = 0,
					@PartCurrencyId INT = 0,
					@PartFxRate DECIMAL(18,2) = 0,
					@PartPriorityId BIGINT = 0,
					@PartUnitSalePrice DECIMAL(18,2) = 0,
					@PartUnitCost DECIMAL(18,2) = 0,
					@PartMarginAmount DECIMAL(18,2) = 0,
					@PartSalesPriceExtended DECIMAL(18,2) = 0,
					@PartUnitCostExtended DECIMAL(18,2) = 0,
					@PartMarginAmountExtended DECIMAL(18,2) = 0,
					@PartMarginPercentage DECIMAL(18,2) = 0,
					@PartSalesOrderPartId BIGINT = 0,
					@CustomerRequestDate AS Datetime2(7),
					@PromisedDate AS Datetime2(7),
					@EstimatedShipDate AS Datetime2(7),
					@InsertedSalesOrderStocklineId BIGINT,
					@PartMarkUpPercentage DECIMAL(18,2) = 0,
					@PartMarkUpAmount DECIMAL(18,2) = 0,
					@PartDiscountPercentage DECIMAL(18,2) = 0,
					@PartDiscountAmount DECIMAL(18,2) = 0,

					@ECCN AS varchar(200),
					@HSCODE AS varchar(200),
					@Weight AS decimal(18,4),
					@SizeLength AS decimal(18,4),
					@SizeWidth AS decimal(18,4),
					@SizeHeight AS decimal(18,4)

			--Get SalesOrderNumber for RefrenceNumber
			SELECT @SalesOrderNumber = [SalesOrderNumber] FROM [DBO].[SalesOrder] WITH(NOLOCK) WHERE [SalesOrderId] = @SalesOrderId;			
			
			DECLARE @IsUnreserve BIT = NULL;
			SET @IsUnreserve = CASE WHEN @UnReserveStatusId = @PartStatusId THEN 1 ELSE 0 END;

			--Set RefrenceNumber
			IF(@autoReserve = 1)
			BEGIN
				 SET @RefNumber = @StkAutoReserveRefNumber + @SalesOrderNumber;
			END
			ELSE
			BEGIN
				 IF(@ReserveStatusId = @PartStatusId)
				 BEGIN
					  SET @RefNumber = @StkReserveRefNumber + @SalesOrderNumber;
				 END
				 ELSE
				 BEGIN
					  SET @RefNumber = @StkUnReserveRefNumber + @SalesOrderNumber;
				 END
			END

			--If Part Status is Reserve
			IF(@ReserveStatusId = @PartStatusId)
			BEGIN 
				--Checking for part data without stockline
				IF NOT EXISTS(SELECT SOP.SalesOrderPartId FROM [DBO].[SalesOrderPartV1] SOP WITH(NOLOCK)
					  LEFT JOIN [DBO].[SalesOrderStocklineV1] SOSP WITH(NOLOCK) ON SOSP.SalesOrderPartId = SOP.SalesOrderPartId
					  WHERE SOP.SalesOrderId = @SalesOrderId AND SOSP.StockLineId = @StockLineId)
				BEGIN 
					DECLARE @QtyRequested BIGINT = NULL;
					DECLARE @QtyAdded BIGINT = NULL;
					DECLARE @QtyAfterReserve BIGINT = NULL;

					--Get Part Data
					SELECT 
						   @QtyRequested = SOP.QtyRequested,
						   @PartQty = SOP.QtyOrder, 
						   @PartUnitSalePrice = SOPC.UnitSalesPrice, 
						   @PartUnitCost = SOPC.UnitCost,
						   @PartMarginAmount = SOPC.MarginAmount,
					       @PartSalesOrderPartId = SOP.SalesOrderPartId,
					       @CustomerRequestDate = SOP.CustomerRequestDate,
					       @PromisedDate = SOP.PromisedDate,
					       @EstimatedShipDate = SOP.EstimatedShipDate,
					       @PartMarkUpPercentage = SOPC.MarkUpPercentage,
					       @PartMarkUpAmount = SOPC.MarkUpAmount,
					       @PartDiscountPercentage = SOPC.DiscountPercentage,
					       @PartDiscountAmount = SOPC.DiscountAmount,

						   @ECCN = SOP.ECCN,
						   @HSCODE = SOP.HSCODE,
						   @Weight = SOP.[Weight],
						   @SizeLength = SOP.SizeLength,
						   @SizeWidth = SOP.SizeWidth,
						   @SizeHeight = SOP.SizeHeight
					FROM [DBO].[SalesOrderPartV1] SOP WITH(NOLOCK)
					LEFT JOIN [DBO].[SalesOrderPartCost] SOPC WITH(NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId AND SOPC.SalesOrderId = SOP.SalesOrderId
					WHERE SOP.SalesOrderId = @SalesOrderId AND SOP.ItemMasterId = @ItemMasterId
					AND SOP.ConditionId = @ConditionId;

					SELECT @QtyAdded = ISNULL(SUM(SOPS.QtyOrder), 0) FROM [DBO].[SalesOrderStocklineV1] SOPS WITH(NOLOCK) WHERE SOPS.SalesOrderPartId = @PartSalesOrderPartId;

				    SET @QtyAfterReserve = @QtyAdded + @QtyToReserve;
					
					IF (@QtyAfterReserve <= @QtyRequested)
					BEGIN
						--Get Stockline UnitCost
						SELECT @StocklineUnitCost = ISNULL(UnitCost,0) FROM [DBO].[Stockline] WITH(NOLOCK) WHERE StockLineId = @StockLineId;

						SET @PartUnitCostExtended = ISNULL(@StocklineUnitCost,0) * ISNULL(@PartQty,0);
						SET @PartMarginAmount = ISNULL(@PartUnitSalePrice,0) - ISNULL(@PartUnitCost,0);
						SET @PartMarginAmountExtended = ISNULL(@PartMarginAmount,0) * ISNULL(@PartQty,0);

						IF(ISNULL(@PartUnitSalePrice,0) > 0)
						BEGIN
							SET @PartMarginPercentage = (ISNULL(@PartMarginAmount,0) / ISNULL(@PartUnitSalePrice,0)) * 100
						END
						ELSE
						BEGIN
							SET @PartMarginPercentage = 0;
						END
						
						SET @PartSalesPriceExtended = ISNULL(@PartUnitSalePrice,0) * ISNULL(@PartQty,0);
				
						--Update SO Part While Create Stockline On Reserve
						UPDATE [dbo].[SalesOrderPartV1]
						SET QtyReserved = @QtyToReserve
						WHERE SalesOrderId = @SalesOrderId AND SalesOrderPartId = @PartSalesOrderPartId;

						-- Added at Stockline Level
						INSERT INTO [dbo].[SalesOrderStocklineV1] ([SalesOrderPartId], [StockLineId], [ConditionId], [QtyOrder], [QtyReserved], [QtyAvailable], [QtyOH], [CustomerRequestDate], [PromisedDate], [EstimatedShipDate], [StatusId], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted],[ECCN],[HSCODE],[Weight],[SizeLength],[SizeWidth],[SizeHeight])
						SELECT @PartSalesOrderPartId, STK.StockLineId, @ConditionId, @QtyToReserve, @QtyToReserve, STK.QuantityAvailable, STK.QuantityOnHand, @CustomerRequestDate, @PromisedDate, @EstimatedShipDate, @SOPartStatus, @MasterCompanyId, @CreatedBy, GETUTCDATE(), @CreatedBy, GETUTCDATE(), 1, 0,@ECCN,@HSCODE,@Weight,@SizeLength,@SizeWidth,@SizeHeight
						FROM DBO.Stockline STK WHERE STK.StockLineId = @StockLineId;

						SET @InsertedSalesOrderStocklineId = SCOPE_IDENTITY();

						INSERT INTO [dbo].[SalesOrderStockLineCost] ([SalesOrderId], [SalesOrderPartId], [SalesOrderStocklineId], [UnitSalesPrice], [UnitSalesPriceExtended], [MarkUpPercentage], [MarkUpAmount], [NetSaleAmount],
						[UnitCost], [UnitCostExtended], [MarginAmount], [MarginPercentage], [DiscountPercentage], [DiscountAmount],
						[MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
				
						SELECT @SalesOrderId, @PartSalesOrderPartId, @InsertedSalesOrderStocklineId, @PartUnitSalePrice, @PartUnitCostExtended, @PartMarkUpPercentage, ((@PartMarkUpAmount / @QtyRequested) * @QtyToReserve), 0,
						Stkl.UnitCost, (Stkl.UnitCost * @QtyToReserve), @PartMarginAmount, @PartMarginPercentage, @PartDiscountPercentage, ((@PartDiscountAmount / @QtyRequested) * @QtyToReserve), 
						@MasterCompanyId, @CreatedBy, GETUTCDATE(), @CreatedBy, GETUTCDATE(), 1, 0
						FROM [DBO].[StockLine] Stkl 
						WHERE Stkl.StockLineId = @StockLineId;

						DECLARE @IsReserve BIT;
						SET @IsReserve = CASE WHEN @ReserveStatusId = @PartStatusId THEN 1 ELSE 0 END;
						EXEC [dbo].[USP_UpdateSOPartCostDetails] @SalesOrderId, @PartSalesOrderPartId, @CreatedBy, @MasterCompanyId, @IsUnreserve, @IsFromShipping, @IsReserve;
					END
				END
				ELSE
				BEGIN 
					--Checking for part data with stockline
					IF EXISTS(SELECT TOP 1 1 FROM [DBO].[SalesOrderPartV1] SOP WITH(NOLOCK)
						 LEFT JOIN [DBO].[SalesOrderStocklineV1] SOS WITH(NOLOCK) ON SOS.SalesOrderPartId = SOP.SalesOrderPartId
						 WHERE SOP.SalesOrderId = @SalesOrderId AND SOS.StockLineId = @StockLineId)
					BEGIN
						--Get Part Data
						SELECT @PartSalesOrderPartId = SOP.SalesOrderPartId
						FROM [DBO].[SalesOrderPartV1] SOP WITH(NOLOCK)
						INNER JOIN [DBO].[SalesOrderPartCost] SOPC WITH(NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId AND SOPC.SalesOrderId = SOP.SalesOrderId
						WHERE SOP.SalesOrderId = @SalesOrderId AND SOP.ItemMasterId = @ItemMasterId
						AND SOP.ConditionId = @ConditionId;

						--Update SO Part While Create Stockline On Reserve
						--UPDATE [dbo].[SalesOrderPartV1]
						--SET QtyReserved = @QtyToReserve
						--WHERE SalesOrderId = @SalesOrderId AND SalesOrderPartId = @PartSalesOrderPartId;

						SELECT @AlreadyQtyOrder = ISNULL(STK.QtyOrder, 0), @AlreadyReservedQty = ISNULL(STK.QtyReserved, 0) FROM [dbo].[SalesOrderStocklineV1] STK WITH (NOLOCK) WHERE SalesOrderPartId = @PartSalesOrderPartId AND StockLineId = @StockLineId;

						IF (@AlreadyReservedQty < @AlreadyQtyOrder)
						BEGIN
							UPDATE [dbo].[SalesOrderStocklineV1]
							SET QtyReserved = @QtyToReserve,
							--QtyOrder = @QtyToReserve,
							StatusId = (CASE WHEN (@ReservePartTotalReserved = QtyOrder) THEN @SOPartStatusFulFill ELSE StatusId END )
							WHERE SalesOrderPartId = @PartSalesOrderPartId AND StockLineId = @StockLineId;
						END

						DECLARE @IsReserved BIT;

						SET @IsReserved = CASE WHEN @ReserveStatusId = @PartStatusId THEN 1 ELSE 0 END;
						EXEC [dbo].[USP_UpdateSOPartCostDetails] @SalesOrderId, @PartSalesOrderPartId, @CreatedBy, @MasterCompanyId, @IsUnreserve, @IsFromShipping, @IsReserved;
					END
				END
			END
			
			--Checking in ReservePart Table for add/update
			IF EXISTS(SELECT TOP 1 1 FROM [DBO].[SalesOrderReserveParts] WITH(NOLOCK)
					 WHERE StockLineId = @StockLineId AND SalesOrderId = @SalesOrderId AND ItemMasterId = @ItemMasterId)
			BEGIN 
				--Get Part Data
				SELECT @ReservePartQtyReserved = SORP.QtyToReserve,
					   @ReservePartTotalReserved = SORP.TotalReserved
					FROM [DBO].[SalesOrderReserveParts] SORP WITH(NOLOCK)
					WHERE SORP.SalesOrderId = @SalesOrderId AND SORP.ItemMasterId = @ItemMasterId
					AND SORP.StockLineId = @StockLineId;

				--For Reserve
				IF(@ReserveStatusId = @PartStatusId)
				BEGIN
					SET @ReservePartQtyToReserve = CASE WHEN ISNULL(@ReservePartQtyReserved,0) = NULL THEN 0 ELSE (ISNULL(@ReservePartQtyReserved,0) + ISNULL(@QtyToReserve,0)) END;
					SET @ReservePartTotalReserved = CASE WHEN ISNULL(@ReservePartTotalReserved,0) = NULL THEN 0 ELSE (ISNULL(@ReservePartTotalReserved,0) + ISNULL(@QtyToReserve,0)) END;

					IF((ISNULL(@PartQty,0) >= 0) AND (@ReservePartQtyReserved = ISNULL(@Quantity,0)))
					BEGIN
						--Update Part Status to fulfilled
						UPDATE [DBO].[SalesOrderPartV1] SET StatusId = @SOPartStatusFulFill WHERE SalesOrderPartId = @SalesOrderPartId;
					END
				END

				--For Unreserve
				IF(@UnReserveStatusId = @PartStatusId)
				BEGIN
					SET @ReservePartQtyToReserve = CASE WHEN ISNULL(@ReservePartQtyReserved,0) = NULL THEN 0 ELSE (ISNULL(@ReservePartQtyReserved,0) - ISNULL(@QtyToUnReserve,0)) END;
					SET @ReservePartTotalReserved = CASE WHEN ISNULL(@ReservePartQtyReserved,0) = NULL THEN 0 ELSE (ISNULL(@ReservePartQtyReserved,0) - ISNULL(@QtyToUnReserve,0)) END;
					
					IF((ISNULL(@PartQty,0) >= 0) AND (@ReservePartQtyReserved = ISNULL(@PartQty,0)))
					BEGIN
						--Update Part Status to open
						UPDATE [DBO].[SalesOrderPartV1] SET StatusId = @SOPartStatus WHERE SalesOrderPartId = @SalesOrderPartId;
					END
				END

				--Update Reserve Part into SalesOrderReserveParts
				UPDATE [DBO].[SalesOrderReserveParts] 
				SET ReservedById = @ReservedById,
					ReservedDate = @ReservedDate,
					UpdatedBy = @CreatedBy,
					UpdatedDate = GETUTCDATE(),
					PartStatusId = @PartStatusId,
					QtyToReserve = @ReservePartQtyToReserve,
					TotalReserved = @ReservePartTotalReserved
				WHERE SalesOrderPartId = @SalesOrderPartId 
					AND SalesOrderId = @SalesOrderId
					AND StockLineId = @StockLineId
					AND ItemMasterId = @ItemMasterId;

				--Update Reserve Part into SalesOrderReserveParts
				UPDATE [DBO].[SalesOrderStocklineV1] 
				SET UpdatedBy = @CreatedBy,
					UpdatedDate = GETUTCDATE(),
					QtyReserved = @ReservePartTotalReserved,
					ReferenceNumber = @RefNumber,
					StatusId = (CASE WHEN (@ReservePartTotalReserved = QtyOrder) AND (@ReserveStatusId = @PartStatusId) THEN @SOPartStatusFulFill ELSE StatusId END )
				WHERE SalesOrderPartId = @SalesOrderPartId AND StockLineId = @StockLineId

				IF(@ReserveStatusId = @PartStatusId)
				BEGIN
					UPDATE DBO.Stockline
					SET QuantityAvailable = QuantityAvailable - @QtyToReserve,
					QuantityReserved = QuantityReserved + @QtyToReserve
					WHERE StockLineId = @StockLineId;
				END
				ELSE IF(@UnReserveStatusId = @PartStatusId)
				BEGIN
					UPDATE DBO.Stockline
					SET QuantityAvailable = CASE WHEN @afterShipping = 1 THEN QuantityAvailable ELSE QuantityAvailable + @QtyToUnReserve END, --QuantityAvailable + @QtyToUnReserve,
					QuantityReserved = QuantityReserved - @QtyToUnReserve
					WHERE StockLineId = @StockLineId;

					UPDATE [DBO].[SalesOrderStocklineV1] 
					SET UpdatedBy = @CreatedBy,
						UpdatedDate = GETUTCDATE(),
						StatusId = @SOPartStatus,
						ReferenceNumber = @RefNumber
					WHERE SalesOrderPartId = @SalesOrderPartId 
					AND StockLineId = @StockLineId AND ISNULL(QtyReserved,0) = 0
				END

				DECLARE @IsReserved1 BIT;

				SET @IsReserved1 = CASE WHEN @ReserveStatusId = @PartStatusId THEN 1 ELSE 0 END;
				EXEC [dbo].[USP_UpdateSOPartCostDetails] @SalesOrderId, @SalesOrderPartId, @CreatedBy, @MasterCompanyId, @IsUnreserve, @IsFromShipping, @IsReserved1;
			END
			ELSE
			BEGIN 
				IF(ISNULL(@SalesOrderPartId,0) > 0)
				BEGIN 
					DECLARE @ReservedQty BIGINT = 0;

					SELECT @ReservedQty = SOS.QtyReserved FROM DBO.SalesOrderStocklineV1 SOS WITH (NOLOCK) WHERE SOS.SalesOrderPartId = @SalesOrderPartId AND SOS.StockLineId = @StockLineId;

					IF (ISNULL(@ReservedQty, 0) > 0)
					BEGIN
						--Get Part Data
						SELECT @PartQty = SOP.QtyOrder 
							FROM [DBO].[SalesOrderPartV1] SOP WITH(NOLOCK)
							WHERE SOP.SalesOrderId = @SalesOrderId AND SOP.ItemMasterId = @ItemMasterId
							AND SOP.ConditionId = @ConditionId;

						--For Reserve
						IF(@ReserveStatusId = @PartStatusId)
						BEGIN
							SET @ReservePartQtyToReserve = ISNULL(@QtyToReserve,0);
							SET @ReservePartTotalReserved = ISNULL(@QtyToReserve,0);

							IF((ISNULL(@PartQty,0) >= 0) AND (@QtyToReserve = ISNULL(@PartQty,0)))
							BEGIN
								--Update Part Status to fulfilled
								UPDATE [DBO].[SalesOrderPartV1] SET StatusId = @SOPartStatusFulFill WHERE SalesOrderPartId = @SalesOrderPartId;
							END

							--Add RefenceNumber
							UPDATE [DBO].[SalesOrderStocklineV1] 
								SET ReferenceNumber = @RefNumber									
								WHERE SalesOrderPartId = @SalesOrderPartId 
								AND StockLineId = @StockLineId AND ISNULL(QtyReserved,0) > 0
						END

						--For Unreserve
						IF(@UnReserveStatusId = @PartStatusId)
						BEGIN
							SET @ReservePartQtyToReserve = ISNULL(@QtyToUnReserve,0);
							SET @ReservePartTotalReserved = ISNULL(@QtyToUnReserve,0);

							IF(ISNULL(@PartQty,0) >= 0)
							BEGIN
								--Update Part Status to open
								UPDATE [DBO].[SalesOrderPartV1] SET StatusId = @SOPartStatus WHERE SalesOrderPartId = @SalesOrderPartId;
							END
							UPDATE [DBO].[SalesOrderStocklineV1] 
								SET UpdatedBy = @CreatedBy,
									UpdatedDate = GETUTCDATE(),
									StatusId = @SOPartStatus									
								WHERE SalesOrderPartId = @SalesOrderPartId 
								AND StockLineId = @StockLineId AND ISNULL(QtyReserved,0) = 0
						END


						--Add Reserve Part into SalesOrderReserveParts
						INSERT INTO [DBO].[SalesOrderReserveParts](SalesOrderId,StockLineId,ItemMasterId,PartStatusId,IsEquPart,EquPartMasterPartId,
									   IsAltPart,AltPartMasterPartId,QtyToReserve,QtyToIssued,ReservedById,ReservedDate,
									   IssuedById,IssuedDate,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,
									   IsActive,IsDeleted,SalesOrderPartId,TotalReserved,TotalIssued,MasterCompanyId)
						SELECT @SalesOrderId,@StockLineId,@ItemMasterId,@PartStatusId,0,NULL,
							   0,NULL,@ReservePartQtyToReserve,0,@ReservedById,@ReservedDate,
							   0,NULL,@CreatedBy,GETUTCDATE(),@CreatedBy,GETUTCDATE(),
							   1,0,@SalesOrderPartId,@ReservePartTotalReserved,0,@MasterCompanyId;

						IF(@ReserveStatusId = @PartStatusId)
						BEGIN
							UPDATE DBO.Stockline
							SET QuantityAvailable = QuantityAvailable - @ReservePartQtyToReserve,
							QuantityReserved = QuantityReserved + @ReservePartQtyToReserve
							WHERE StockLineId = @StockLineId;

							UPDATE [DBO].[SalesOrderStocklineV1] 
								SET UpdatedBy = @CreatedBy,
									UpdatedDate = GETUTCDATE(),
									StatusId = @SOPartStatusFulFill
								WHERE SalesOrderPartId = @SalesOrderPartId 
								AND StockLineId = @StockLineId AND ISNULL(QtyOrder,0) = ISNULL(QtyReserved,0)

						END
						ELSE IF(@UnReserveStatusId = @PartStatusId)
						BEGIN
							UPDATE DBO.Stockline
							SET QuantityAvailable = CASE WHEN @afterShipping = 1 THEN QuantityAvailable ELSE QuantityAvailable + @ReservePartQtyToReserve END,
							QuantityReserved = QuantityReserved - @ReservePartQtyToReserve
							WHERE StockLineId = @StockLineId;
						END
					END
				END
			END

			SET @MasterLoopID = @MasterLoopID - 1;			
		END

		--Return Data
		SELECT @SalesOrderPartId AS 'SalesOrderPartId',@SalesOrderId AS 'SalesOrderId';
	  END
    COMMIT TRANSACTION

  END TRY
  BEGIN CATCH
    IF @@trancount > 0
		ROLLBACK TRAN;
		DECLARE @ErrorLogID int
		,@DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
		,@AdhocComments varchar(150) = 'SalesOrderReserveUnReserveParts'
		,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL('', '') + ''
		,@ApplicationName varchar(100) = 'PAS'
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
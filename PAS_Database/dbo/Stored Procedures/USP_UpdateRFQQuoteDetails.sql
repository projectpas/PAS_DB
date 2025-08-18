/*************************************************************           
 ** File:   [USP_UpdateQuoteDetails]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used for update old quote parice & if new will add parts.
 ** Purpose:         
 ** Date:   18-08-2025      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    18-08-2025	   Amit Ghediya       Created
	
-- EXEC USP_UpdateQuoteDetails
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateRFQQuoteDetails]
	@tbl_IlsRfqQuoteDetailsType IlsRfqQuoteDetailsType READONLY,
	@CustomerRfqQuoteId BIGINT = NULL,
	@CustomerRfqId BIGINT,
	@RfqId NVARCHAR(250),
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(200)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
				DECLARE @RfqQuoteLoopID AS INT,
						@MinRFQId AS INT,
						@IlsPrice AS DECIMAL(18,2),
						@ConditionId AS INT,
						@ILSQty AS INT,
						@RefrenceId AS BIGINT=0,
						@RFQModuleId AS INT,
						@ModuleId AS INT,
						@QtyQuoted AS INT,
						@MarkUpAmount AS decimal(18,4) = 0,
						@DiscountAmount AS decimal(18,4) = 0,
						@MarkUpPercentage AS decimal(18,4) = 0,
						@DiscountPercentage AS decimal(18,4) = 0,
						@SalesOrderQuotePartId BIGINT = 0,
						@PriorityId BIGINT,
						@SOQPartStatus BIGINT,
						@CurrencyId INT = 0,
						@CurrencyCode VARCHAR(10) = '',
						@LinePartNumber VARCHAR(256),
						@RFQItemMasterId BIGINT;

				SELECT @ModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [CodePrefix] = 'SOQ';

				-- Fetch Sales order quote settings details
				SELECT TOP 1
				@PriorityId = [DefaultPriorityId]
				FROM [dbo].[SalesOrderQuoteSettings] WITH(NOLOCK)
				WHERE IsActive = 1 AND IsDeleted = 0 
				AND MasterCompanyId = @MasterCompanyId ;

				SELECT @CurrencyId = [CurrencyId] FROM [dbo].[Currency] WITH(NOLOCK) WHERE Code = 'USD' AND MasterCompanyId = @MasterCompanyId;

				--Read all part which from RFQ
				IF OBJECT_ID(N'tempdb..#RfqQuoteDetail') IS NOT NULL
				BEGIN
					DROP TABLE #RfqQuoteDetail
				END

				CREATE TABLE #RfqQuoteDetail
				(
					ID bigint NOT NULL IDENTITY,
					[CustomerRfqQuoteDetailsId] [bigint] NULL,
					[CustomerRfqQuoteId] [bigint] NULL,
					[IlsQty] [int] NULL,
					[IlsTraceability] [varchar](50) NULL,
					[IlsUom] [varchar](50) NULL,
					[IlsPrice] [decimal](10, 2) NULL,
					[IlsPriceType] [varchar](50) NULL,
					[IlsTagDate] [datetime2](7) NULL,
					[IlsLeadTime] [varchar](50) NULL,
					[IlsMinQty] [int] NULL,
					[IlsComment] [varchar](max) NULL,
					[IlsCondition] [varchar](50) NULL,
					[ConditionId] [bigint] NULL,
					[ItemMasterId] [bigint] NULL
				)

				INSERT  INTO #RfqQuoteDetail([CustomerRfqQuoteDetailsId],[CustomerRfqQuoteId],[IlsQty],[IlsTraceability],[IlsUom],
												[IlsPrice],[IlsPriceType],[IlsTagDate],[IlsLeadTime],[IlsMinQty],
												[IlsComment],[IlsCondition],[ConditionId],[ItemMasterId])
										SELECT [CustomerRfqQuoteDetailsId],[CustomerRfqQuoteId],[IlsQty],[IlsTraceability],[IlsUom],
												[IlsPrice],[IlsPriceType],[IlsTagDate],[IlsLeadTime],[IlsMinQty],
												[IlsComment],[IlsCondition],[ConditionId],[ItemMasterId]
										FROM @tbl_IlsRfqQuoteDetailsType;

				SELECT @RfqQuoteLoopID = MAX(ID) FROM #RfqQuoteDetail;
				SELECT @MinRFQId = MIN(ID) FROM #RfqQuoteDetail;

				WHILE (@MinRFQId <= @RfqQuoteLoopID)
				BEGIN
					 SELECT @IlsPrice = [IlsPrice],
					 	   @ConditionId = [ConditionId],
					 	   @ILSQty = [IlsQty]
					 FROM #RfqQuoteDetail WHERE ID = @MinRFQId;
					 
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
					 	CreatedBy varchar(100),
					 	IsNoQuote BIT NULL,
					 	IsLotAssigned BIT NULL,
					 	LotId BIGINT NULL
					 )

					 --Get SOQ Added in RFQ
					 SELECT @RefrenceId = [ReferenceId], @RFQModuleId = [ModuleId],@LinePartNumber = LinePartNumber FROM [dbo].[CustomerRfq] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqId;

					 --Get ItemasterId based on RFQ part
					 SELECT @RFQItemMasterId = [ItemMasterId] 
					 FROM [dbo].[ItemMaster] WITH(NOLOCK) 
					 WHERE LOWER(TRIM([PartNumber])) = LOWER(TRIM(@LinePartNumber));
					 
					 IF(ISNULL(@RefrenceId,0) > 0 AND @RFQModuleId = @ModuleId)
					 BEGIN						
						  IF EXISTS(SELECT TOP 1 SalesOrderQuotePartId FROM [dbo].[SalesOrderQuotePartv1] WITH(NOLOCK) WHERE [SalesOrderQuoteId] = @RefrenceId AND [ItemMasterId] = @RFQItemMasterId AND [ConditionId] = @ConditionId)
						  BEGIN
							   SELECT @SalesOrderQuotePartId = [SalesOrderQuotePartId] 
							   FROM [dbo].[SalesOrderQuotePartv1] WITH(NOLOCK) 
							   WHERE [SalesOrderQuoteId] = @RefrenceId 
							   AND [ItemMasterId] = @RFQItemMasterId
							   AND [ConditionId] = @ConditionId;

							   --Set ILs Qty as Part Qty
							   SET @QtyQuoted = @ILSQty;

							   DECLARE @SalesPrice_U AS decimal(18,4);
							   DECLARE @MarkUpAmt_U AS decimal(18,4);
							   DECLARE @DiscAmt_U AS decimal(18,4);
							   DECLARE @GrossAmt_U AS decimal(18,4);
							   DECLARE @NetSalesAmt_U AS decimal(18,4);
							   DECLARE @NetSalesPerUnitAmt_U AS decimal(18,4);
							   
							   SET @SalesPrice_U = ISNULL(@IlsPrice, 0);
							   SET @MarkUpAmt_U = ISNULL(@MarkUpAmount, 0) * @QtyQuoted;
							   SET @DiscAmt_U = ISNULL(@DiscountAmount, 0) * @QtyQuoted;
							   SET @GrossAmt_U = ((@SalesPrice_U * @QtyQuoted) + @MarkUpAmt_U);
							   SET @NetSalesAmt_U = @GrossAmt_U - (@DiscAmt_U);
							   SET @NetSalesPerUnitAmt_U = ((@SalesPrice_U) + ISNULL(@MarkUpAmount, 0)) - (ISNULL(@DiscountAmount, 0));
							   
							   --Update qty in part table
							   UPDATE [dbo].[SalesOrderQuotePartV1]
							   SET QtyRequested = @ILSQty,
							   QtyQuoted = @ILSQty
							   WHERE [SalesOrderQuotePartId] = @SalesOrderQuotePartId

							   --Update Price in existing records
							   UPDATE [DBO].[SalesOrderQuotePartCost]
							   SET UnitSalesPrice = @SalesPrice_U,
							   MarkUpPercentage = @MarkUpPercentage,
							   MarkUpAmount = @MarkUpAmt_U,
							   DiscountPercentage = @DiscountPercentage,
							   DiscountAmount = @DiscAmt_U,
							   GrossSaleAmount = ISNULL(@GrossAmt_U, 0),
							   NetSaleAmount = ISNULL(@NetSalesAmt_U, 0),
							   NetSaleAmountPerUnit = @NetSalesPerUnitAmt_U
							   WHERE [SalesOrderQuotePartId] = @SalesOrderQuotePartId
						  END
						  ELSE
						  BEGIN							
								--Set ILs Qty as Part Qty
							    SET @QtyQuoted = @ILSQty;

								--Get Part Status
								SELECT @SOQPartStatus = [SOPartStatusId] FROM [DBO].[SOPartStatus] WITH (NOLOCK) WHERE [PartStatus] = 'Open';

								INSERT INTO #SOQPartDetails (SalesOrderQuotePartId,SalesOrderQuoteId,ItemMasterId,ConditionId,PriorityId,StocklineId,QuantityQuote,SalesOrderQuoteStocklineId,StatusId,
									QtyRequested,QtyQuoted,QtyAvailable,QtyOH,CurrencyId,FxRate,GrossSaleAmount,DiscountAmount,NetSaleAmount,TaxAmount,UnitCostExtended,MarginAmount,
									CustomerRequestDate,PromisedDate,EstimatedShipDate,UnitSalesPrice,MarkUpPercentage,DiscountPercentage,MarkUpAmount,SalesPriceExtended,UnitCost,
									MarginPercentage,TaxPercentage,StatusName,AltOrEqType,Notes,MasterCompanyId,CreatedBy,IsNoQuote,IsLotAssigned,LotId)
									SELECT 0,@RefrenceId,@RFQItemMasterId,@ConditionId,@PriorityId,NULL,@ILSQty,@ILSQty,NULL,
									@ILSQty,@ILSQty,0,0,@CurrencyId,1,0,0,@IlsPrice,0,0,@IlsPrice,
									NULL,NULL,NULL,@IlsPrice,0,0,0,0,0,
									0,0,NULL,NULL,'Created From AI',@MasterCompanyId,@CreatedBy,NULL,0,NULL;

							   SELECT @CurrencyId = Curr.CurrencyId, @CurrencyCode = Curr.Code 
							   FROM [DBO].[CustomerFinancial] CF WITH (NOLOCK) 
							   LEFT JOIN [DBO].[Currency] Curr WITH (NOLOCK) ON CF.CurrencyId = Curr.CurrencyId 
							   LEFT JOIN [DBO].[SalesOrderQuote] SOQ WITH (NOLOCK) ON SOQ.CustomerId = CF.CustomerId
							   WHERE SOQ.SalesOrderQuoteId = @RefrenceId;
							   
							   INSERT INTO [dbo].[SalesOrderQuotePartV1] ([SalesOrderQuoteId],[ItemMasterId],[ConditionId],[QtyRequested],[QtyQuoted],[CurrencyId],[FxRate],[PriorityId],[StatusId],[CustomerRequestDate],[PromisedDate],[EstimatedShipDate],[Notes],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],[IsLotAssigned],[LotId])
							   SELECT SalesOrderQuoteId, ItemMasterId, ConditionId, QtyRequested, QtyQuoted, CurrencyId, FxRate, PriorityId, @SOQPartStatus, CustomerRequestDate, PromisedDate, EstimatedShipDate, Notes, MasterCompanyId, CreatedBy, GETUTCDATE(), CreatedBy, GETUTCDATE(), 1, 0,IsLotAssigned,LotId
							   FROM #SOQPartDetails;
							   
							   SET @SalesOrderQuotePartId = SCOPE_IDENTITY();
							   
							   DECLARE @SalesPrice AS decimal(18,4);
							   DECLARE @MarkUpAmt AS decimal(18,4);
							   DECLARE @DiscAmt AS decimal(18,4);
							   DECLARE @GrossAmt AS decimal(18,4);
							   DECLARE @NetSalesAmt AS decimal(18,4);
							   DECLARE @NetSalesPerUnitAmt AS decimal(18,4);
							   
							   SET @SalesPrice = ISNULL(@IlsPrice, 0);
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
							   FROM #SOQPartDetails;
						  END

						  --Update SOQ Part Cost
						  EXEC [dbo].[USP_UpdateSOQPartCostDetails] @RefrenceId, @SalesOrderQuotePartId, @CreatedBy, @MasterCompanyId;
					 END
					 
					 SET @SalesOrderQuotePartId = 0;

					 SET @MinRFQId = @MinRFQId + 1;
				END						
				
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			SELECT  
    ERROR_NUMBER() AS ErrorNumber  
    ,ERROR_SEVERITY() AS ErrorSeverity  
    ,ERROR_STATE() AS ErrorState  
    ,ERROR_PROCEDURE() AS ErrorProcedure  
    ,ERROR_LINE() AS ErrorLine  
    ,ERROR_MESSAGE() AS ErrorMessage;  
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_UpdateQuoteDetails' 
            , @ProcedureParameters VARCHAR(3000) = '@CustomerRfqId = ''' + CAST(ISNULL(@CustomerRfqId, '') as varchar(100))
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
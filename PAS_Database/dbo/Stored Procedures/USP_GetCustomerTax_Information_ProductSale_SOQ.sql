/*************************************************************           
 ** File:   [USP_GetCustomerTax_Information_ProductSale_SOQ]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to get Customer Tax Information based on ProductSale
 ** Purpose:         
 ** Date:   01/31/2024        
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    01/31/2024   Moin Bloch		Created
	2    05/03/2024   Moin Bloch		Updated changed join ItemMaster To [Stockline]
	3    09/23/2024   Vishal Suthar		Modified for Old tables with new tables
     
-- EXEC [USP_GetCustomerTax_Information_ProductSale_SOQ] 766
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCustomerTax_Information_ProductSale_SOQ]
	@SalesOrderQuoteId bigint
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
	DECLARE @SalesTax Decimal(18,2) = 0;
	DECLARE @OtherTax Decimal(18,2) = 0;
	DECLARE @TotalRecord INT = 0; 
	DECLARE @MinId BIGINT = 1;    
	DECLARE @SOQModuleId BIGINT = 0;
	DECLARE @OriginSiteId BIGINT = 0;
	DECLARE @ShipToSiteId BIGINT = 0;
	DECLARE	@CustomerId  BIGINT = 0;
	DECLARE @SalesOrderQuotePartId BIGINT = 0;
	DECLARE @TotalSalesTax Decimal(18,2) = 0;
	DECLARE @TotalOtherTax Decimal(18,2) = 0;
	DECLARE @Total DECIMAL(18,2) = 0;
	DECLARE @FreightBilingMethodId INT = 3
	DECLARE @ChargesBilingMethodId INT = 3	
	DECLARE @TotalFreight DECIMAL(18,2) = 0;
	DECLARE @TotalCharges DECIMAL(18,2) = 0;	
	DECLARE @SubTotal DECIMAL(18,2) = 0;	
	DECLARE @TotalSalesTaxes DECIMAL(18,2) = 0;	
	DECLARE @TotalOtherTaxes DECIMAL(18,2) = 0;	
	DECLARE @FinalSalesTaxes DECIMAL(18,2) = 0;	
	DECLARE @FinalOtherTaxes DECIMAL(18,2) = 0;	
	DECLARE @TotalRecord2 INT = 0; 
	DECLARE @MinId2 BIGINT = 1; 
	DECLARE @FreightMethodId INT = 0
	DECLARE @ChargesMethodId INT = 0
	DECLARE @TotalFreightPartWise DECIMAL(18,2) = 0;	
	DECLARE @TotalChargePartWise DECIMAL(18,2) = 0;	
	DECLARE @TaxableFreight DECIMAL(18,2) = 0;	
	DECLARE @TaxableCharge DECIMAL(18,2) = 0;	
	DECLARE @FreighFlag INT = 0
	DECLARE @ChargeFlag INT = 0
	DECLARE @FreighSalesTax DECIMAL(18,2) = 0;
	DECLARE @FreighOtherTax DECIMAL(18,2) = 0;
	DECLARE @ChargeSalesTax DECIMAL(18,2) = 0;	
	DECLARE @ChargeOtherTax DECIMAL(18,2) = 0;

	SELECT @SOQModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesQuote';

	IF OBJECT_ID(N'tempdb..#tmprShipDetails') IS NOT NULL
	BEGIN
		DROP TABLE #tmprShipDetails
	END

	IF OBJECT_ID(N'tempdb..#tmprShipDetails2') IS NOT NULL
	BEGIN
		DROP TABLE #tmprShipDetails2
	END
		
	CREATE TABLE #tmprShipDetails
	(
		[ID] BIGINT NOT NULL IDENTITY, 		
		[OriginSiteId] BIGINT NULL,
		[ShipToSiteId] BIGINT NULL,
		[CustomerId]  BIGINT NULL,
		[SalesOrderQuoteId] BIGINT NULL,
		[SalesOrderQuotePartId] BIGINT NULL,
		[SalesTax] DECIMAL(18,2) NULL,
		[OtherTax]  DECIMAL(18,2) NULL
	)
	
	CREATE TABLE #tmprShipDetails2
	(
		[ID] BIGINT NOT NULL IDENTITY, 		
		[OriginSiteId] BIGINT NULL,
		[ShipToSiteId] BIGINT NULL,
		[CustomerId]  BIGINT NULL,
		[SalesOrderQuoteId] BIGINT NULL,		
		[SalesTax] DECIMAL(18,2) NULL,
		[OtherTax]  DECIMAL(18,2) NULL
	)

	INSERT INTO #tmprShipDetails ([OriginSiteId],[ShipToSiteId],[CustomerId],[SalesOrderQuoteId],[SalesOrderQuotePartId])
			SELECT CASE WHEN STK.[SiteId] IS NOT NULL THEN STK.[SiteId] ELSE ITM.[SiteId] END,
			       CASE WHEN AAD.[SiteId] IS NOT NULL THEN AAD.[SiteId] ELSE CDS.CustomerDomensticShippingId END,
				   SOQ.[CustomerId],
				   SOQ.[SalesOrderQuoteId],
				   SOQP.[SalesOrderQuotePartId]
			FROM [dbo].[SalesOrderQuote] SOQ WITH(NOLOCK) 
			INNER JOIN [dbo].[SalesOrderQuotePartV1] SOQP WITH(NOLOCK) ON SOQ.[SalesOrderQuoteId] = SOQP.[SalesOrderQuoteId] 
			 LEFT JOIN [dbo].[SalesOrderQuoteStocklineV1] SOQS WITH(NOLOCK) ON SOQS.[SalesOrderQuotePartId] = SOQP.[SalesOrderQuotePartId]
			 LEFT JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON SOQS.[StockLineId] = STK.[StockLineId]
			 LEFT JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON SOQP.[ItemMasterId] = ITM.[ItemMasterId]
			 LEFT JOIN [dbo].[AllAddress] AAD WITH(NOLOCK) ON SOQP.[SalesOrderQuoteId] = AAD.[ReffranceId] AND [IsShippingAdd] = 1 AND [ModuleId] = @SOQModuleId
			 LEFT JOIN [dbo].[CustomerDomensticShipping] CDS WITH(NOLOCK) ON CDS.[CustomerId] = SOQ.[CustomerId] AND CDS.[IsPrimary] = 1
   		     WHERE SOQ.[SalesOrderQuoteId] = @SalesOrderQuoteId;

	SELECT @FreightMethodId = SO.[FreightBilingMethodId],
	       @ChargesMethodId = SO.[ChargesBilingMethodId] 
	  FROM [dbo].[SalesOrderQuote] SO WITH(NOLOCK) 
      WHERE SO.[SalesOrderQuoteId] = @SalesOrderQuoteId;
	
	SELECT @TotalFreight = CASE WHEN SOQ.FreightBilingMethodId = @FreightBilingMethodId 
	                            THEN ISNULL(SOQ.TotalFreight,0)
								ELSE								
									ISNULL(SUM(SOQF.BillingAmount),0) 
								END			
	FROM [dbo].[SalesOrderQuote] SOQ WITH(NOLOCK) 
	LEFT JOIN [dbo].[SalesOrderQuoteFreight] SOQF WITH(NOLOCK) ON SOQ.SalesOrderQuoteId = SOQF.SalesOrderQuoteId AND SOQF.IsActive = 1 AND SOQF.IsDeleted = 0  
   	WHERE SOQ.[SalesOrderQuoteId] = @SalesOrderQuoteId
	GROUP BY SOQ.[FreightBilingMethodId],SOQ.[TotalFreight]

	SELECT @TotalCharges = CASE WHEN SOQ.ChargesBilingMethodId = @ChargesBilingMethodId
	                            THEN ISNULL(SOQ.TotalCharges,0)
								ELSE								
									ISNULL(SUM(SOQC.BillingAmount),0) 
								END			
	FROM [dbo].[SalesOrderQuote] SOQ WITH(NOLOCK) 
	LEFT JOIN [dbo].[SalesOrderQuoteCharges] SOQC WITH(NOLOCK) ON SOQ.[SalesOrderQuoteId] = SOQC.[SalesOrderQuoteId] AND SOQC.IsActive = 1 AND SOQC.IsDeleted = 0  
   	WHERE SOQ.[SalesOrderQuoteId] = @SalesOrderQuoteId 
	GROUP BY SOQ.ChargesBilingMethodId,SOQ.TotalCharges
	
	IF(@FreightMethodId = @FreightBilingMethodId)
	BEGIN
			SELECT @TotalFreightPartWise = ISNULL(SO.TotalFreight,0) FROM [dbo].[SalesOrderQuote] SO WITH(NOLOCK)  WHERE SO.[SalesOrderQuoteId] = @SalesOrderQuoteId;
			SET @TaxableFreight = @TotalFreightPartWise;
			SET @FreighFlag = 1;
	END

	IF(@ChargesMethodId = @ChargesBilingMethodId)
	BEGIN
			SELECT @TotalChargePartWise = ISNULL(SO.TotalCharges,0) FROM [dbo].[SalesOrderQuote] SO WITH(NOLOCK)  WHERE SO.[SalesOrderQuoteId] = @SalesOrderQuoteId;
			SET @TaxableCharge = @TotalChargePartWise;
			SET @ChargeFlag = 1;
	END
												
	SELECT @TotalRecord = COUNT(*), @MinId = MIN(ID) FROM #tmprShipDetails    
	
	WHILE @MinId <= @TotalRecord
	BEGIN
		SELECT @OriginSiteId = [OriginSiteId],
	           @ShipToSiteId = [ShipToSiteId],
		       @CustomerId   = [CustomerId],
			   @SalesOrderQuotePartId = [SalesOrderQuotePartId]
		FROM #tmprShipDetails WHERE ID = @MinId

		IF(@FreighFlag = 0)
		BEGIN
			SELECT @TotalFreightPartWise = ISNULL(SUM(SOF.[BillingAmount]),0) 											
	        FROM [dbo].[SalesOrderQuoteFreight] SOF WITH(NOLOCK)
   	        WHERE SOF.[SalesOrderQuoteId] = @SalesOrderQuoteId 
			  AND SOF.[SalesOrderQuotePartId] = @SalesOrderQuotePartId 
			  AND SOF.[IsActive] = 1 
			  AND SOF.[IsDeleted] = 0   
		END			   
		
		IF(@ChargeFlag = 0)
		BEGIN
			SELECT @TotalChargePartWise = ISNULL(SUM(SOC.[BillingAmount]),0) 											
	        FROM [dbo].[SalesOrderQuoteCharges] SOC WITH(NOLOCK)
   	        WHERE SOC.[SalesOrderQuoteId] = @SalesOrderQuoteId 
			  AND SOC.[SalesOrderQuotePartId] = @SalesOrderQuotePartId 
			  AND SOC.[IsActive] = 1 
			  AND SOC.[IsDeleted] = 0; 
		END	
								
		EXEC [dbo].[USP_GetCustomerTax_Information_ProductSale] 
		     @CustomerId,
			 @ShipToSiteId,
			 @OriginSiteId,
		     @TotalSalesTax = @TotalSalesTax OUTPUT,
		     @TotalOtherTax = @TotalOtherTax OUTPUT	
			 
		--SELECT @Total = (ISNULL(SOQP.UnitSalesPricePerUnit, 0) * ISNULL(SOQP.QtyQuoted,0))
		--	FROM [dbo].[SalesOrderQuotePart] SOQP WITH(NOLOCK)
		--	WHERE [SOQP].[SalesOrderQuoteId] = @SalesOrderQuoteId 
		--	  AND [SOQP].[SalesOrderQuotePartId] = @SalesOrderQuotePartId;

		SELECT @Total = ISNULL(SOQC.SubTotal, 0)
			FROM [dbo].[SalesOrderQuoteCost] SOQC WITH(NOLOCK)
			WHERE [SOQC].[SalesOrderQuoteId] = @SalesOrderQuoteId;

	    SET @SubTotal = ISNULL(@Total,0);
	    SET @SalesTax = (ISNULL(@Total,0)  * ISNULL(@TotalSalesTax,0) / 100)
	    SET @OtherTax = (ISNULL(@Total,0)  * ISNULL(@TotalOtherTax,0) / 100)

		IF(@FreighFlag = 0 AND @ChargeFlag = 0)
		BEGIN
			SET @FreighSalesTax = (ISNULL(@TotalFreightPartWise,0)  * ISNULL(@TotalSalesTax,0) / 100)
			SET @FreighOtherTax = (ISNULL(@TotalFreightPartWise,0)  * ISNULL(@TotalOtherTax,0) / 100)
			SET @ChargeSalesTax = (ISNULL(@TotalChargePartWise,0)  * ISNULL(@TotalSalesTax,0) / 100)
			SET @ChargeOtherTax = (ISNULL(@TotalChargePartWise,0)  * ISNULL(@TotalOtherTax,0) / 100)
							
			UPDATE #tmprShipDetails SET [SalesTax] = @SalesTax + @FreighSalesTax + @ChargeSalesTax, 
										[OtherTax] = @OtherTax + @FreighOtherTax + @ChargeOtherTax									
								  WHERE [ID] = @MinId
		END
		IF(@FreighFlag = 1 AND @ChargeFlag = 1)
		BEGIN
			IF(@TaxableFreight > 0)
			BEGIN
				SET @FreighSalesTax = (ISNULL(@TaxableFreight / @TotalRecord,0) * ISNULL(@TotalSalesTax,0) / 100)
				SET @FreighOtherTax = (ISNULL(@TaxableFreight / @TotalRecord,0) * ISNULL(@TotalOtherTax,0) / 100)
			END
			IF(@TaxableCharge > 0)
			BEGIN
				SET @ChargeSalesTax = (ISNULL(@TaxableCharge / @TotalRecord,0) * ISNULL(@TotalSalesTax,0) / 100)
				SET @ChargeOtherTax = (ISNULL(@TaxableCharge / @TotalRecord,0) * ISNULL(@TotalOtherTax,0) / 100)
			END							
			UPDATE #tmprShipDetails SET [SalesTax] = @SalesTax + @FreighSalesTax + @ChargeSalesTax, 
										[OtherTax] = @OtherTax + @FreighOtherTax + @ChargeOtherTax									
								  WHERE [ID] = @MinId
		END
		IF(@FreighFlag = 1 AND @ChargeFlag = 0)
		BEGIN
			SET @ChargeSalesTax = (ISNULL(@TotalChargePartWise,0)  * ISNULL(@TotalSalesTax,0) / 100)
			SET @ChargeOtherTax = (ISNULL(@TotalChargePartWise,0)  * ISNULL(@TotalOtherTax,0) / 100)	

			IF(@TaxableFreight > 0)
			BEGIN
				SET @FreighSalesTax = (ISNULL(@TaxableFreight / @TotalRecord,0) * ISNULL(@TotalSalesTax,0) / 100)
				SET @FreighOtherTax = (ISNULL(@TaxableFreight / @TotalRecord,0) * ISNULL(@TotalOtherTax,0) / 100)
			END
							
			UPDATE #tmprShipDetails SET [SalesTax] = @SalesTax + @FreighSalesTax + @ChargeSalesTax, 
										[OtherTax] = @OtherTax + @FreighOtherTax + @ChargeOtherTax								
								  WHERE [ID] = @MinId
		END
		IF(@FreighFlag = 0 AND @ChargeFlag = 1)
		BEGIN			
			SET @FreighSalesTax = (ISNULL(@TotalFreightPartWise,0)  * ISNULL(@TotalSalesTax,0) / 100)
			SET @FreighOtherTax = (ISNULL(@TotalFreightPartWise,0)  * ISNULL(@TotalOtherTax,0) / 100)	

			IF(@TaxableCharge > 0)
			BEGIN
				SET @ChargeSalesTax = (ISNULL(@TaxableCharge / @TotalRecord,0) * ISNULL(@TotalSalesTax,0) / 100)
				SET @ChargeOtherTax = (ISNULL(@TaxableCharge / @TotalRecord,0) * ISNULL(@TotalOtherTax,0) / 100)
			END
							
			UPDATE #tmprShipDetails SET [SalesTax] = @SalesTax + @FreighSalesTax + @ChargeSalesTax, 
										[OtherTax] = @OtherTax + @FreighOtherTax + @ChargeOtherTax									
								  WHERE [ID] = @MinId
		END	
		
		--UPDATE #tmprShipDetails SET [SalesTax] = @SalesTax, [OtherTax] = @OtherTax  WHERE [ID] = @MinId
		
		IF(@TotalSalesTax > 0 OR @TotalOtherTax > 0)
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM #tmprShipDetails2 WHERE [OriginSiteId] = @OriginSiteId AND [ShipToSiteId] = @ShipToSiteId and [CustomerId]=@CustomerId)
			BEGIN
				INSERT INTO #tmprShipDetails2 ([OriginSiteId],[ShipToSiteId],[CustomerId],[SalesOrderQuoteId],[SalesTax],[OtherTax])
				     SELECT @OriginSiteId,@ShipToSiteId,@CustomerId,@SalesOrderQuoteId,ISNULL(@TotalSalesTax,0),ISNULL(@TotalOtherTax,0);
			END	
			IF(@FreighFlag = 0)
			BEGIN
				SET @TaxableFreight += @TotalFreightPartWise;			
			END
			IF(@ChargeFlag = 0)
			BEGIN
				SET @TaxableCharge += @TotalChargePartWise;			
			END	
		END
			 			
		SET @MinId = @MinId + 1
	END
	
	SELECT @TotalRecord2 = COUNT(*), @MinId2 = MIN(ID) FROM #tmprShipDetails2    

	WHILE @MinId2 <= @TotalRecord2
	BEGIN
		DECLARE @STX DECIMAL(18,2)=0
		DECLARE @OTX DECIMAL(18,2)=0

		SELECT @STX = [SalesTax],
		       @OTX = [OtherTax]			  
		FROM #tmprShipDetails2 WHERE ID = @MinId2

		SET @TotalSalesTaxes += @STX
	    SET @TotalOtherTaxes += @OTX

		SET @MinId2 = @MinId2 + 1
	END
					
	--SELECT @FinalSalesTaxes = SUM(SalesTax)+(ISNULL(@TotalFreight,0)  * ISNULL(@TotalSalesTaxes,0) / 100)+(ISNULL(@TotalCharges,0)  * ISNULL(@TotalSalesTaxes,0) / 100),
	--       @FinalOtherTaxes = SUM(OtherTax)+(ISNULL(@TotalFreight,0)  * ISNULL(@TotalOtherTaxes,0) / 100)+(ISNULL(@TotalCharges,0)  * ISNULL(@TotalOtherTaxes,0) / 100)		 
	--  FROM #tmprShipDetails

	 --SELECT @FinalSalesTaxes = SUM(SalesTax)+(ISNULL(@TaxableFreight,0)  * ISNULL(@TotalSalesTaxes,0) / 100)+(ISNULL(@TaxableCharge,0)  * ISNULL(@TotalSalesTaxes,0) / 100),
	 --       @FinalOtherTaxes = SUM(OtherTax)+(ISNULL(@TaxableFreight,0)  * ISNULL(@TotalOtherTaxes,0) / 100)+(ISNULL(@TaxableCharge,0)  * ISNULL(@TotalOtherTaxes,0) / 100)		 
	 -- FROM #tmprShipDetails
	 
	 SELECT @FinalSalesTaxes = SUM([SalesTax]), @FinalOtherTaxes = SUM([OtherTax]) FROM #tmprShipDetails	
	  
	  SELECT  ISNULL(@TotalFreight,0) AS TotalFreight,
	          ISNULL(@TotalCharges,0) AS TotalCharges,	
	          ISNULL((@SubTotal + @TotalFreight + @TotalCharges),0) AS SubTotal,
	          ISNULL((@SubTotal + @TotalFreight + @TotalCharges + @FinalSalesTaxes +  @FinalOtherTaxes),0) AS GrandTotal,
			  ISNULL(@FinalSalesTaxes,0) AS SalesTax,
			  ISNULL(@FinalOtherTaxes,0) AS OtherTax
	
  END TRY

  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[USP_GetCustomerTax_Information_ProductSale_SOQ]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesOrderQuoteId, '') AS VARCHAR(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END
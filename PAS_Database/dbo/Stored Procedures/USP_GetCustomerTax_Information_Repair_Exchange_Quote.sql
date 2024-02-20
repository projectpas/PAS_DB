/*************************************************************           
 ** File:   [USP_GetCustomerTax_Information_Repair_Exchange_Quote]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to get Customer Tax Information based on Repair
 ** Purpose:         
 ** Date:   16/02/2024        
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    16/02/2024   Moin Bloch    Created

     
-- EXEC [USP_GetCustomerTax_Information_Repair_Exchange_Quote] 368
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetCustomerTax_Information_Repair_Exchange_Quote] 
@ExchangeQuoteId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
	DECLARE @SalesTax Decimal(18,2) = 0;
	DECLARE @OtherTax Decimal(18,2) = 0;
	DECLARE @TotalRecord INT = 0; 
	DECLARE @MinId BIGINT = 1;    
	DECLARE @EXSOQModuleId BIGINT = 0;
	DECLARE @OriginSiteId BIGINT = 0;
	DECLARE @ShipToSiteId BIGINT = 0;
	DECLARE	@CustomerId  BIGINT = 0;
	DECLARE @ExchangeQuotePartId BIGINT = 0;
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

	SELECT @EXSOQModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeQuote';
	
	IF OBJECT_ID(N'tempdb..#tmprExchangeDetailsQuote') IS NOT NULL
	BEGIN
		DROP TABLE #tmprExchangeDetailsQuote
	END

	IF OBJECT_ID(N'tempdb..#tmprExchangeDetailsQuote2') IS NOT NULL
	BEGIN
		DROP TABLE #tmprExchangeDetailsQuote2
	END
		
	CREATE TABLE #tmprExchangeDetailsQuote
	(
		[ID] BIGINT NOT NULL IDENTITY, 		
		[OriginSiteId] BIGINT NULL,
		[ShipToSiteId] BIGINT NULL,
		[CustomerId]  BIGINT NULL,
		[ExchangeQuoteId] BIGINT NULL,
		[ExchangeQuotePartId] BIGINT NULL,
		[SalesTax] DECIMAL(18,2) NULL,
		[OtherTax]  DECIMAL(18,2) NULL
	)
	
	CREATE TABLE #tmprExchangeDetailsQuote2
	(
		[ID] BIGINT NOT NULL IDENTITY, 		
		[OriginSiteId] BIGINT NULL,
		[ShipToSiteId] BIGINT NULL,
		[CustomerId]  BIGINT NULL,
		[ExchangeQuoteId] BIGINT NULL,		
		[SalesTax] DECIMAL(18,2) NULL,
		[OtherTax]  DECIMAL(18,2) NULL
	)
	
	INSERT INTO #tmprExchangeDetailsQuote ([OriginSiteId],[ShipToSiteId],[CustomerId],[ExchangeQuoteId],[ExchangeQuotePartId])
			SELECT ITM.[SiteId],
			       CASE WHEN AAD.[SiteId] IS NOT NULL THEN AAD.[SiteId] ELSE CDS.CustomerDomensticShippingId END,
				   SO.[CustomerId],
				   SO.[ExchangeQuoteId],
				   SOP.[ExchangeQuotePartId]
			  FROM [dbo].[ExchangeQuote] SO WITH(NOLOCK) 
	    INNER JOIN [dbo].[ExchangeQuotePart] SOP WITH(NOLOCK) ON SO.[ExchangeQuoteId] = SOP.[ExchangeQuoteId] 
		 LEFT JOIN [dbo].[AllAddress] AAD WITH(NOLOCK) ON SO.[ExchangeQuoteId] = AAD.[ReffranceId] AND [IsShippingAdd] = 1 AND [ModuleId] = @EXSOQModuleId
		 LEFT JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON SOP.[ItemMasterId] = ITM.[ItemMasterId]
		 LEFT JOIN [dbo].[CustomerDomensticShipping] CDS WITH(NOLOCK) ON CDS.[CustomerId] = SO.[CustomerId] AND CDS.[IsPrimary] = 1
	         WHERE SO.[ExchangeQuoteId] = @ExchangeQuoteId
	
   -----------------------------------------------------------------------------------------
 	SELECT @TotalFreight = CASE WHEN ESO.IsFreightFlatRate = 1 THEN ISNULL(ESO.FreightFlatRate,0) ELSE ISNULL(SUM(ESOF.BillingAmount),0) END						
	FROM [dbo].[ExchangeQuote] ESO WITH(NOLOCK) 
	LEFT JOIN [dbo].[ExchangeQuoteFreight] ESOF WITH(NOLOCK) ON ESO.[ExchangeQuoteId] = ESOF.[ExchangeQuoteId] AND ESOF.IsActive = 1 AND ESOF.IsDeleted = 0  
   	WHERE ESO.[ExchangeQuoteId] = @ExchangeQuoteId
	GROUP BY ESO.FreightFlatRate,ESO.IsFreightFlatRate
	----------------------------------------------------------------------------------------
	
	SELECT @TotalCharges = CASE WHEN ESO.IsChargeFlatRate = 1 THEN ISNULL(ESO.ChargeFlatRate,0) ELSE ISNULL(SUM(ESOC.BillingAmount),0) END 
	FROM [dbo].[ExchangeQuote] ESO WITH(NOLOCK) 			
	LEFT JOIN [dbo].[ExchangeQuoteCharges] ESOC WITH(NOLOCK) ON ESO.[ExchangeQuoteId] = ESOC.[ExchangeQuoteId] AND ESOC.IsActive = 1 AND ESOC.IsDeleted = 0  
    WHERE ESO.[ExchangeQuoteId] = @ExchangeQuoteId
	GROUP BY ESO.IsChargeFlatRate,ESO.ChargeFlatRate
												
	SELECT @TotalRecord = COUNT(*), @MinId = MIN(ID) FROM #tmprExchangeDetailsQuote    
	
	WHILE @MinId <= @TotalRecord
	BEGIN
		SELECT @OriginSiteId = [OriginSiteId],
	           @ShipToSiteId = [ShipToSiteId],
		       @CustomerId   = [CustomerId],
			   @ExchangeQuotePartId = [ExchangeQuotePartId]
		FROM #tmprExchangeDetailsQuote WHERE ID = @MinId
						
		EXEC [dbo].[USP_GetCustomerTax_Information_Repair] 
		     @CustomerId,
			 @ShipToSiteId,
			 @OriginSiteId,
		     @TotalSalesTax = @TotalSalesTax OUTPUT,
		     @TotalOtherTax = @TotalOtherTax OUTPUT	
			 
		SELECT @Total = (ISNULL(SOP.ExchangeListPrice, 0) * ISNULL(SOP.QtyQuoted,0))
			FROM [dbo].[ExchangeQuotePart] SOP WITH(NOLOCK)
		   WHERE [SOP].[ExchangeQuoteId] = @ExchangeQuoteId 
			 AND [SOP].[ExchangeQuotePartId] = @ExchangeQuotePartId;

	    SET @SubTotal += ISNULL(@Total,0);
	    SET @SalesTax = (ISNULL(@Total,0) * ISNULL(@TotalSalesTax,0) / 100)
	    SET @OtherTax = (ISNULL(@Total,0) * ISNULL(@TotalOtherTax,0) / 100)

		UPDATE #tmprExchangeDetailsQuote SET [SalesTax] = @SalesTax, [OtherTax] = @OtherTax  WHERE [ID] = @MinId
		
		IF(@TotalSalesTax > 0 OR @TotalOtherTax > 0)
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM #tmprExchangeDetailsQuote2 WHERE [OriginSiteId] = @OriginSiteId AND [ShipToSiteId] = @ShipToSiteId AND [CustomerId] = @CustomerId)
			BEGIN
				INSERT INTO #tmprExchangeDetailsQuote2 ([OriginSiteId],[ShipToSiteId],[CustomerId],[ExchangeQuoteId],[SalesTax],[OtherTax])
				     SELECT @OriginSiteId,@ShipToSiteId,@CustomerId,@ExchangeQuoteId,ISNULL(@TotalSalesTax,0),ISNULL(@TotalOtherTax,0);
			END		
		END
			 			
		SET @MinId = @MinId + 1
	END
	
	SELECT @TotalRecord2 = COUNT(*), @MinId2 = MIN(ID) FROM #tmprExchangeDetailsQuote2    

	WHILE @MinId2 <= @TotalRecord2
	BEGIN
		DECLARE @STX DECIMAL(18,2)=0
		DECLARE @OTX DECIMAL(18,2)=0

		SELECT @STX = [SalesTax],
		       @OTX = [OtherTax]			  
		FROM #tmprExchangeDetailsQuote2 WHERE ID = @MinId2

		SET @TotalSalesTaxes += @STX
	    SET @TotalOtherTaxes += @OTX

		SET @MinId2 = @MinId2 + 1
	END
					
	SELECT @FinalSalesTaxes = SUM([SalesTax])+(ISNULL(@TotalFreight,0)  * ISNULL(@TotalSalesTaxes,0) / 100)+(ISNULL(@TotalCharges,0)  * ISNULL(@TotalSalesTaxes,0) / 100),
	       @FinalOtherTaxes = SUM([OtherTax])+(ISNULL(@TotalFreight,0)  * ISNULL(@TotalOtherTaxes,0) / 100)+(ISNULL(@TotalCharges,0)  * ISNULL(@TotalOtherTaxes,0) / 100)		 
	  FROM #tmprExchangeDetailsQuote;

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
            @AdhocComments varchar(150) = '[USP_GetCustomerTax_Information_Repair_Exchange_Quote]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ExchangeQuoteId, '') AS VARCHAR(100)),
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
/*************************************************************           
 ** File:   [USP_GetExchangeQuoteAnalysisList]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to USP_GetExchangeQuoteAnalysisList
 ** Purpose:         
 ** Date:   07/07/2025      
          
 ** PARAMETERS:  @ExchangeQuoteId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    07/07/2025   Ekta Chandegra     Created
    2    07/28/2025   Ekta Chandegra     Retrieve billing amount as OtherCharges and ExtendedCost as OtherCost
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
     
  EXEC USP_GetExchangeQuoteAnalysisList @ExchangeQuoteId = 113

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetExchangeQuoteAnalysisList]
    @ExchangeQuoteId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @MasterCompanyId BIGINT,
				@COGSPercentValue DECIMAL(18, 2) = 0,
				@Charges DECIMAL(18, 2) = 0,
				@OtherCharges DECIMAL(18, 2) = 0,
				@MiscCharges DECIMAL(18, 2) = 0,
				@ChargeFlatRate DECIMAL(18, 2) = 0,
				@IsChargeFlatRate BIT = 0,
				@BillingMethodId INT = 0,
				@Freights DECIMAL(18, 2) = 0,
				@FlatRateBillingMethodId BIGINT;

		SELECT @FlatRateBillingMethodId = BillingMethodId FROM [dbo].[BillingMethod] WITH(NOLOCK) WHERE Description = 'Flate Rate';
		
		-- Get MasterCompanyId and Flat Rate settings
		SELECT TOP 1
			@MasterCompanyId = MasterCompanyId,
			@IsChargeFlatRate = ISNULL(IsChargeFlatRate, 0),
			@ChargeFlatRate = ISNULL(ChargeFlatRate, 0)
		FROM [dbo].[ExchangeQuote] WITH(NOLOCK)
		WHERE ExchangeQuoteId = @ExchangeQuoteId;

		-- Get COGS Percent Value
		SELECT TOP 1 @COGSPercentValue = ISNULL(p.PercentValue, 0)
		FROM [dbo].[ExchangeQuoteSetting] s WITH(NOLOCK)
		LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON s.COGS = p.PercentId
		WHERE s.MasterCompanyId = @MasterCompanyId;

		-- Get Charges and OtherCharges
		SELECT TOP 1 
			@Charges = ISNULL(BillingAmount, 0),
			@OtherCharges = ISNULL(ExtendedCost, 0),
			@BillingMethodId = ISNULL(BillingMethodId, 0)
		FROM [dbo].[ExchangeQuoteCharges] WITH(NOLOCK)
		WHERE ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0;

		IF @OtherCharges = 0
		BEGIN
			SELECT TOP 1
				@OtherCharges = ISNULL(ExtendedCost, 0),
				@Charges = ISNULL(BillingAmount, 0)
			FROM [dbo].[ExchangeQuoteCharges] WITH(NOLOCK)
			WHERE ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(IsActive,0) = 1;
		END

		IF @IsChargeFlatRate = 1
		BEGIN
			SET @Charges = @ChargeFlatRate;
			SET @OtherCharges = @ChargeFlatRate;
		END

		IF @BillingMethodId = @FlatRateBillingMethodId
		BEGIN
			SELECT TOP 1
				@OtherCharges = ISNULL(MarkupFixedPrice, 0),
				@MiscCharges = ISNULL(MarkupFixedPrice, 0)
			FROM [dbo].[ExchangeQuoteCharges] WITH(NOLOCK)
			WHERE ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(IsActive,0) = 1;
		END

		-- Get Freight
		SELECT 
			@Freights = 
			CASE 
				WHEN MIN(BillingMethodId) = @FlatRateBillingMethodId
					THEN MAX(ISNULL(MarkupFixedPrice, 0))
				ELSE SUM(ISNULL(BillingAmount, 0))
			END
		FROM [dbo].[ExchangeQuoteFreight] WITH(NOLOCK)
		WHERE ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0;

		-- Final Select
		SELECT 
			eq.ExchangeQuoteId,
			ExchangeFees = (SELECT SUM(ISNULL(PeriodicBillingAmount, 0)) 
							FROM [dbo].[ExchangeQuoteScheduleBilling] WITH(NOLOCK)
							WHERE ExchangeQuoteId = eq.ExchangeQuoteId),
			OverhaulPrice = part.ExchangeOverhaulPrice,
			OtherCharges = @Charges,
			COGSFees = 
				CASE 
					WHEN epc.PercentValue IS NOT NULL AND opc.PercentValue IS NOT NULL THEN
						((SELECT SUM(ISNULL(PeriodicBillingAmount, 0)) 
						  FROM [dbo].[ExchangeQuoteScheduleBilling] WITH(NOLOCK) 
						  WHERE ExchangeQuoteId = eq.ExchangeQuoteId) * (epc.PercentValue / 100.0)) + 
						(part.ExchangeOverhaulPrice * (opc.PercentValue / 100.0))
					ELSE 0
				END,
			OverhaulCost = part.ExchangeOverhaulCost,
			OtherCost = @OtherCharges,
			UOM = im.PurchaseUnitOfMeasure,
			ExchFees = part.ExchangeListPrice,
			ExchFeesCOGS = ISNULL(epc.PercentValue, 0),
			OverHaulCOGS = ISNULL(opc.PercentValue, 0)
		FROM [dbo].[ExchangeQuote] eq  WITH(NOLOCK) 
		INNER JOIN [dbo].[ExchangeQuotePart] part WITH(NOLOCK)  ON eq.ExchangeQuoteId = part.ExchangeQuoteId
		LEFT JOIN [dbo].[ItemMasterExchangeLoan] iml WITH(NOLOCK)  ON part.ItemMasterId = iml.ItemMasterId
		LEFT JOIN [dbo].[ItemMaster] im WITH(NOLOCK)  ON part.ItemMasterId = im.ItemMasterId
		 AND ISNULL(im.IsNonStock,0) = 0
		LEFT JOIN [dbo].[Percent] epc WITH(NOLOCK)  ON iml.EFcogs = epc.PercentId
		LEFT JOIN [dbo].[Percent] opc WITH(NOLOCK)  ON iml.OPcogs = opc.PercentId
		WHERE eq.ExchangeQuoteId = @ExchangeQuoteId;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeQuoteAnalysisList'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeQuoteId = ''' + CAST(ISNULL(@ExchangeQuoteId, '') AS VARCHAR(100))
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
            RETURN(1);
	END CATCH
END;
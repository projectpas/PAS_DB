/*************************************************************           
 ** File:   [USP_GetCustomerTax_Information_Repair_Exchange]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to get Customer Tax Information based on Repair
 ** Purpose:         
 ** Date:   01/02/2024        
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    01/02/2024   Moin Bloch    Created
	2    14-02-2024   Shrey Chandegara Updated for change @TotalFreight and @TotalCharge value.
     
-- EXEC [USP_GetCustomerTax_Information_Repair_Exchange] 368
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetCustomerTax_Information_Repair_Exchange] 
@ExchangeSalesOrderId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
	DECLARE @SalesTax Decimal(18,2) = 0;
	DECLARE @OtherTax Decimal(18,2) = 0;
	DECLARE @TotalRecord INT = 0; 
	DECLARE @MinId BIGINT = 1;    
	DECLARE @EXSOModuleId BIGINT = 0;
	DECLARE @OriginSiteId BIGINT = 0;
	DECLARE @ShipToSiteId BIGINT = 0;
	DECLARE	@CustomerId  BIGINT = 0;
	DECLARE @ExchangeSalesOrderPartId BIGINT = 0;
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

	SELECT @EXSOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';

	IF OBJECT_ID(N'tempdb..#tmprExchangeDetails') IS NOT NULL
	BEGIN
		DROP TABLE #tmprExchangeDetails
	END

	IF OBJECT_ID(N'tempdb..#tmprExchangeDetails2') IS NOT NULL
	BEGIN
		DROP TABLE #tmprExchangeDetails2
	END
		
	CREATE TABLE #tmprExchangeDetails
	(
		[ID] BIGINT NOT NULL IDENTITY, 		
		[OriginSiteId] BIGINT NULL,
		[ShipToSiteId] BIGINT NULL,
		[CustomerId]  BIGINT NULL,
		[ExchangeSalesOrderId] BIGINT NULL,
		[ExchangeSalesOrderPartId] BIGINT NULL,
		[SalesTax] DECIMAL(18,2) NULL,
		[OtherTax]  DECIMAL(18,2) NULL
	)
	
	CREATE TABLE #tmprExchangeDetails2
	(
		[ID] BIGINT NOT NULL IDENTITY, 		
		[OriginSiteId] BIGINT NULL,
		[ShipToSiteId] BIGINT NULL,
		[CustomerId]  BIGINT NULL,
		[ExchangeSalesOrderId] BIGINT NULL,		
		[SalesTax] DECIMAL(18,2) NULL,
		[OtherTax]  DECIMAL(18,2) NULL
	)

	
	INSERT INTO #tmprExchangeDetails ([OriginSiteId],[ShipToSiteId],[CustomerId],[ExchangeSalesOrderId],[ExchangeSalesOrderPartId])	
	                      SELECT ESOS.[OriginSiteId],ESOS.[ShipToSiteId],ESOS.[CustomerId],ESOS.[ExchangeSalesOrderId],ESOSI.[ExchangeSalesOrderPartId]
	                         FROM [dbo].[ExchangeSalesOrderShipping] ESOS WITH(NOLOCK)  
							 INNER JOIN [dbo].[ExchangeSalesOrderShippingItem] ESOSI WITH(NOLOCK) ON ESOS.[ExchangeSalesOrderShippingId]  = ESOSI.[ExchangeSalesOrderShippingId]
	                        WHERE ESOS.[ExchangeSalesOrderId] = @ExchangeSalesOrderId;
	
	INSERT INTO #tmprExchangeDetails ([OriginSiteId],[ShipToSiteId],[CustomerId],[ExchangeSalesOrderId],[ExchangeSalesOrderPartId])
			SELECT ITM.[SiteId],
			       CASE WHEN AAD.[SiteId] IS NOT NULL THEN AAD.[SiteId] ELSE CDS.CustomerDomensticShippingId END,
				   SO.[CustomerId],
				   SO.[ExchangeSalesOrderId],
				   SOP.[ExchangeSalesOrderPartId]
			  FROM [dbo].[ExchangeSalesOrder] SO WITH(NOLOCK) 
	    INNER JOIN [dbo].[ExchangeSalesOrderPart] SOP WITH(NOLOCK) ON SO.[ExchangeSalesOrderId] = SOP.[ExchangeSalesOrderId] 
		 LEFT JOIN [dbo].[AllAddress] AAD WITH(NOLOCK) ON SO.[ExchangeSalesOrderId] = AAD.[ReffranceId] AND [IsShippingAdd] = 1 AND [ModuleId] = @EXSOModuleId
		 LEFT JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON SOP.[ItemMasterId] = ITM.[ItemMasterId]
		 LEFT JOIN [dbo].[CustomerDomensticShipping] CDS WITH(NOLOCK) ON CDS.[CustomerId] = SO.[CustomerId] AND CDS.[IsPrimary] = 1
	         WHERE SO.[ExchangeSalesOrderId] = @ExchangeSalesOrderId AND SOP.[ExchangeSalesOrderPartId] NOT IN (SELECT SOSI.[ExchangeSalesOrderPartId] FROM [dbo].[ExchangeSalesOrderShipping] SOS WITH(NOLOCK)  
							 INNER JOIN [dbo].[ExchangeSalesOrderShippingItem] SOSI WITH(NOLOCK) ON SOS.[ExchangeSalesOrderShippingId]  = SOSI.[ExchangeSalesOrderShippingId]
	                        WHERE SOS.[ExchangeSalesOrderId] = @ExchangeSalesOrderId);		   
	     
	--SELECT @TotalFreight = CASE WHEN ESO.FreightBilingMethodId = @FreightBilingMethodId 
	--                            THEN ISNULL(ESOF.BillingAmount,0)
	--							ELSE								
	--								ISNULL(SUM(ESOF.BillingAmount),0) 
	--							END			
	--FROM [dbo].[ExchangeSalesOrder] ESO WITH(NOLOCK) 
	--INNER JOIN [dbo].[ExchangeSalesOrderFreight] ESOF WITH(NOLOCK) ON ESO.[ExchangeSalesOrderId] = SOF.[ExchangeSalesOrderId] AND SOF.IsActive = 1 AND SOF.IsDeleted = 0  
 --  	WHERE ESO.[ExchangeSalesOrderId] = @ExchangeSalesOrderId GROUP BY ESO.FreightBilingMethodId,SO.TotalFreight

   --------------------------------- Flat Rate Not Included Due TO Flat Rate Functionality Remain in Exchange--------------------------------------------------------
 	
	--SELECT @TotalFreight = CASE WHEN ISNULL(SUM(ESOF.BillingAmount),0) = 0 THEN ISNULL(ESO.FreightFlatRate,0) ELSE 0 END 							
	SELECT @TotalFreight = CASE WHEN ESO.IsFreightFlatRate = 1 THEN ISNULL(ESO.FreightFlatRate,0) ELSE ISNULL(SUM(ESOF.BillingAmount),0) END						
	FROM [dbo].[ExchangeSalesOrder] ESO WITH(NOLOCK) 
	LEFT JOIN [dbo].[ExchangeSalesOrderFreight] ESOF WITH(NOLOCK) ON ESO.[ExchangeSalesOrderId] = ESOF.[ExchangeSalesOrderId] AND ESOF.IsActive = 1 AND ESOF.IsDeleted = 0  
   	WHERE ESO.[ExchangeSalesOrderId] = @ExchangeSalesOrderId
	GROUP BY ESO.FreightFlatRate,ESO.IsFreightFlatRate
	-------------------------------- Flat Rate Not Included Due TO Flat Rate Functionality Remain in Exchange--------------------------------------------------------
	
	SELECT @TotalCharges = CASE WHEN ESO.IsChargeFlatRate = 1 THEN ISNULL(ESO.ChargeFlatRate,0) ELSE ISNULL(SUM(ESOC.BillingAmount),0) END 
	FROM [dbo].[ExchangeSalesOrder] ESO WITH(NOLOCK) 			
	LEFT JOIN [dbo].[ExchangeSalesOrderCharges] ESOC WITH(NOLOCK) ON ESO.[ExchangeSalesOrderId] = ESOC.[ExchangeSalesOrderId] AND ESOC.IsActive = 1 AND ESOC.IsDeleted = 0  
    WHERE ESO.[ExchangeSalesOrderId] = @ExchangeSalesOrderId
	GROUP BY ESO.IsChargeFlatRate,ESO.ChargeFlatRate
												
	SELECT @TotalRecord = COUNT(*), @MinId = MIN(ID) FROM #tmprExchangeDetails    
	
	WHILE @MinId <= @TotalRecord
	BEGIN
		SELECT @OriginSiteId = [OriginSiteId],
	           @ShipToSiteId = [ShipToSiteId],
		       @CustomerId   = [CustomerId],
			   @ExchangeSalesOrderPartId = [ExchangeSalesOrderPartId]
		FROM #tmprExchangeDetails WHERE ID = @MinId
						
		EXEC [dbo].[USP_GetCustomerTax_Information_Repair] 
		     @CustomerId,
			 @ShipToSiteId,
			 @OriginSiteId,
		     @TotalSalesTax = @TotalSalesTax OUTPUT,
		     @TotalOtherTax = @TotalOtherTax OUTPUT	
			 
		SELECT @Total = (ISNULL(SOP.ExchangeListPrice, 0) * ISNULL(SOP.QtyQuoted,0))
			FROM [dbo].[ExchangeSalesOrderPart] SOP WITH(NOLOCK)
		   WHERE [SOP].[ExchangeSalesOrderId] = @ExchangeSalesOrderId 
			 AND [SOP].[ExchangeSalesOrderPartId] = @ExchangeSalesOrderPartId;

	    SET @SubTotal += ISNULL(@Total,0);
	    SET @SalesTax = (ISNULL(@Total,0) * ISNULL(@TotalSalesTax,0) / 100)
	    SET @OtherTax = (ISNULL(@Total,0) * ISNULL(@TotalOtherTax,0) / 100)

		UPDATE #tmprExchangeDetails SET [SalesTax] = @SalesTax, [OtherTax] = @OtherTax  WHERE [ID] = @MinId
		
		IF(@TotalSalesTax > 0 OR @TotalOtherTax > 0)
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM #tmprExchangeDetails2 WHERE [OriginSiteId] = @OriginSiteId AND [ShipToSiteId] = @ShipToSiteId AND [CustomerId] = @CustomerId)
			BEGIN
				INSERT INTO #tmprExchangeDetails2 ([OriginSiteId],[ShipToSiteId],[CustomerId],[ExchangeSalesOrderId],[SalesTax],[OtherTax])
				     SELECT @OriginSiteId,@ShipToSiteId,@CustomerId,@ExchangeSalesOrderId,ISNULL(@TotalSalesTax,0),ISNULL(@TotalOtherTax,0);
			END		
		END
			 			
		SET @MinId = @MinId + 1
	END
	
	SELECT @TotalRecord2 = COUNT(*), @MinId2 = MIN(ID) FROM #tmprExchangeDetails2    

	WHILE @MinId2 <= @TotalRecord2
	BEGIN
		DECLARE @STX DECIMAL(18,2)=0
		DECLARE @OTX DECIMAL(18,2)=0

		SELECT @STX = [SalesTax],
		       @OTX = [OtherTax]			  
		FROM #tmprExchangeDetails2 WHERE ID = @MinId2

		SET @TotalSalesTaxes += @STX
	    SET @TotalOtherTaxes += @OTX

		SET @MinId2 = @MinId2 + 1
	END
					
	SELECT @FinalSalesTaxes = SUM([SalesTax])+(ISNULL(@TotalFreight,0)  * ISNULL(@TotalSalesTaxes,0) / 100)+(ISNULL(@TotalCharges,0)  * ISNULL(@TotalSalesTaxes,0) / 100),
	       @FinalOtherTaxes = SUM([OtherTax])+(ISNULL(@TotalFreight,0)  * ISNULL(@TotalOtherTaxes,0) / 100)+(ISNULL(@TotalCharges,0)  * ISNULL(@TotalOtherTaxes,0) / 100)		 
	  FROM #tmprExchangeDetails;

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
            @AdhocComments varchar(150) = '[USP_GetCustomerTax_Information_Repair_Exchange]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ExchangeSalesOrderId, '') AS VARCHAR(100)),
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
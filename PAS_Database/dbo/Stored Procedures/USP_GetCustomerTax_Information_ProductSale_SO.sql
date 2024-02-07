﻿/*************************************************************           
 ** File:   [USP_GetCustomerTax_Information_ProductSale_SO]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to get Customer Tax Information based on ProductSale
 ** Purpose:         
 ** Date:   01/29/2024        
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    01/29/2024   Moin Bloch    Created
     
-- EXEC [USP_GetCustomerTax_Information_ProductSale_SO] 804  798  --798
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCustomerTax_Information_ProductSale_SO] 
@salesOrderId bigint
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
	DECLARE @SalesTax Decimal(18,2) = 0;
	DECLARE @OtherTax Decimal(18,2) = 0;
	DECLARE @TotalRecord INT = 0; 
	DECLARE @MinId BIGINT = 1;    
	DECLARE @SOModuleId BIGINT = 0;
	DECLARE @OriginSiteId BIGINT = 0;
	DECLARE @ShipToSiteId BIGINT = 0;
	DECLARE	@CustomerId  BIGINT = 0;
	DECLARE @SalesOrderPartId BIGINT = 0;
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

	SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

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
		[SalesOrderId] BIGINT NULL,
		[SalesOrderPartId] BIGINT NULL,
		[SalesTax] DECIMAL(18,2) NULL,
		[OtherTax]  DECIMAL(18,2) NULL
	)
	
	CREATE TABLE #tmprShipDetails2
	(
		[ID] BIGINT NOT NULL IDENTITY, 		
		[OriginSiteId] BIGINT NULL,
		[ShipToSiteId] BIGINT NULL,
		[CustomerId]  BIGINT NULL,
		[SalesOrderId] BIGINT NULL,		
		[SalesTax] DECIMAL(18,2) NULL,
		[OtherTax]  DECIMAL(18,2) NULL
	)

	
	INSERT INTO #tmprShipDetails ([OriginSiteId],[ShipToSiteId],[CustomerId],[SalesOrderId],[SalesOrderPartId])	
	                       SELECT SOS.[OriginSiteId],SOS.[ShipToSiteId],SOS.[CustomerId],SOS.[SalesOrderId],SOSI.[SalesOrderPartId]
	                         FROM [dbo].[SalesOrderShipping] SOS WITH(NOLOCK)  
							 INNER JOIN [dbo].[SalesOrderShippingItem] SOSI WITH(NOLOCK) ON SOS.[SalesOrderShippingId]  = SOSI.[SalesOrderShippingId]
	                        WHERE [SalesOrderId] = @SalesOrderId;
	
	INSERT INTO #tmprShipDetails ([OriginSiteId],[ShipToSiteId],[CustomerId],[SalesOrderId],[SalesOrderPartId])
			SELECT ITM.[SiteId],
			       CASE WHEN AAD.[SiteId] IS NOT NULL THEN AAD.[SiteId] ELSE CDS.CustomerDomensticShippingId END,
				   SO.[CustomerId],
				   SO.[SalesOrderId],
				   SOP.[SalesOrderPartId]
			  FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
	    INNER JOIN [dbo].[SalesOrderPart] SOP WITH(NOLOCK) ON SO.[SalesOrderId] = SOP.[SalesOrderId] 
		 LEFT JOIN [dbo].[AllAddress] AAD WITH(NOLOCK) ON SO.[SalesOrderId] = AAD.[ReffranceId] AND [IsShippingAdd] = 1 AND [ModuleId] = @SOModuleId
		 LEFT JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON SOP.[ItemMasterId] = ITM.[ItemMasterId]
		 LEFT JOIN [dbo].[CustomerDomensticShipping] CDS WITH(NOLOCK) ON CDS.[CustomerId] = SO.[CustomerId] AND CDS.[IsPrimary] = 1
	         WHERE SO.[SalesOrderId] = @SalesOrderId AND SOP.SalesOrderPartId NOT IN (SELECT SOSI.SalesOrderPartId FROM [dbo].[SalesOrderShipping] SOS WITH(NOLOCK)  
							 INNER JOIN [dbo].[SalesOrderShippingItem] SOSI WITH(NOLOCK) ON SOS.[SalesOrderShippingId]  = SOSI.[SalesOrderShippingId]
	                        WHERE [SalesOrderId] = @SalesOrderId);

	SELECT @TotalFreight = CASE WHEN SO.FreightBilingMethodId = @FreightBilingMethodId 
	                            THEN ISNULL(SO.TotalFreight,0)
								ELSE								
									ISNULL(SUM(SOF.BillingAmount),0) 
								END			
	FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
	INNER JOIN [dbo].[SalesOrderFreight] SOF WITH(NOLOCK) ON so.SalesOrderId = SOF.SalesOrderId AND SOF.IsActive = 1 AND SOF.IsDeleted = 0  
   	WHERE SO.SalesOrderId = @SalesOrderId GROUP BY SO.FreightBilingMethodId,SO.TotalFreight

	SELECT @TotalCharges = CASE WHEN SO.ChargesBilingMethodId = @ChargesBilingMethodId
	                            THEN ISNULL(SO.TotalCharges,0)
								ELSE								
									ISNULL(SUM(SOC.BillingAmount),0) 
								END			
	FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
	INNER JOIN [dbo].[SalesOrderCharges] SOC WITH(NOLOCK) ON so.SalesOrderId = SOC.SalesOrderId AND SOC.IsActive = 1 AND SOC.IsDeleted = 0  
   	WHERE SO.SalesOrderId = @SalesOrderId GROUP BY SO.ChargesBilingMethodId,SO.TotalCharges
												
	SELECT @TotalRecord = COUNT(*), @MinId = MIN(ID) FROM #tmprShipDetails    
	
	WHILE @MinId <= @TotalRecord
	BEGIN
		SELECT @OriginSiteId = [OriginSiteId],
	           @ShipToSiteId = [ShipToSiteId],
		       @CustomerId   = [CustomerId],
			   @SalesOrderPartId = [SalesOrderPartId]
		FROM #tmprShipDetails WHERE ID = @MinId
						
		EXEC [dbo].[USP_GetCustomerTax_Information_ProductSale] 
		     @CustomerId,
			 @ShipToSiteId,
			 @OriginSiteId,
		     @TotalSalesTax = @TotalSalesTax OUTPUT,
		     @TotalOtherTax = @TotalOtherTax OUTPUT	
			 
		SELECT @Total = (ISNULL(SOP.UnitSalesPricePerUnit, 0) * ISNULL(SOP.Qty,0))
			FROM [dbo].[SalesOrderPart] SOP WITH(NOLOCK)
			WHERE [SOP].[SalesOrderId] = @SalesOrderId 
			  AND [SOP].[SalesOrderPartId] = @SalesOrderPartId;

	    SET @SubTotal += ISNULL(@Total,0);
	    SET @SalesTax = (ISNULL(@Total,0)  * ISNULL(@TotalSalesTax,0) / 100)
	    SET @OtherTax = (ISNULL(@Total,0)  * ISNULL(@TotalOtherTax,0) / 100)

		UPDATE #tmprShipDetails SET [SalesTax] = @SalesTax, [OtherTax] = @OtherTax  WHERE [ID] = @MinId
		
		IF(@TotalSalesTax > 0 OR @TotalOtherTax > 0)
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM #tmprShipDetails2 WHERE [OriginSiteId] = @OriginSiteId AND [ShipToSiteId] = @ShipToSiteId and [CustomerId]=@CustomerId)
			BEGIN
				INSERT INTO #tmprShipDetails2 ([OriginSiteId],[ShipToSiteId],[CustomerId],[SalesOrderId],[SalesTax],[OtherTax])
				     SELECT @OriginSiteId,@ShipToSiteId,@CustomerId,@SalesOrderId,ISNULL(@TotalSalesTax,0),ISNULL(@TotalOtherTax,0);
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
					
	SELECT @FinalSalesTaxes = SUM(SalesTax)+(ISNULL(@TotalFreight,0)  * ISNULL(@TotalSalesTaxes,0) / 100)+(ISNULL(@TotalCharges,0)  * ISNULL(@TotalSalesTaxes,0) / 100),
	       @FinalOtherTaxes = SUM(OtherTax)+(ISNULL(@TotalFreight,0)  * ISNULL(@TotalOtherTaxes,0) / 100)+(ISNULL(@TotalCharges,0)  * ISNULL(@TotalOtherTaxes,0) / 100)		 
	  FROM #tmprShipDetails

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
            @AdhocComments varchar(150) = '[USP_GetCustomerTax_Information_ProductSale_SO]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesOrderId, '') AS VARCHAR(100)),
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
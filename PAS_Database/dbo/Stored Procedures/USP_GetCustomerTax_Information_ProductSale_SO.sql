/*************************************************************           
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
	2    02/21/2024   Moin Bloch    Flat SO Freigh AND Charge Amount Tax 
    3    11/05/2024	  Vishal Suthar	Modified to make use of new SO Part tables
    4    11/11/2024	  Vishal Suthar	Modified to return proper Sub Total for Print PDF
    5    12/05/2024	  Vishal Suthar	Fixed an issue with SO Print after shipping is completed
    6    12/19/2024	  Vishal Suthar	If only part level record is there then Sub Total not coming in SO Print
	7    07/22/2025	  RAJESH GAMI	Calculate sales and other taxes on sub total instead of line level.
	8    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	9    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	10    20/July/2026			 RAJESH GAMI						[PN-17350] - Allow Non-Stock Inventory Parts in Sales Order Quote and Sales Order: removed IsNonStock=0 filters from Stockline and ItemMaster joins used for tax site lookup.
-- EXEC [USP_GetCustomerTax_Information_ProductSale_SO] 608
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetCustomerTax_Information_ProductSale_SO] 
@salesOrderId bigint
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
	DECLARE @SalesTax DECIMAL(18,2) = 0;
	DECLARE @OtherTax DECIMAL(18,2) = 0;
	DECLARE @FreighSalesTax DECIMAL(18,2) = 0;
	DECLARE @FreighOtherTax DECIMAL(18,2) = 0;
	DECLARE @ChargeSalesTax DECIMAL(18,2) = 0;	
	DECLARE @ChargeOtherTax DECIMAL(18,2) = 0;
	DECLARE @TotalRecord INT = 0; 
	DECLARE @MinId BIGINT = 1;    
	DECLARE @SOModuleId BIGINT = 0;
	DECLARE @OriginSiteId BIGINT = 0;
	DECLARE @ShipToSiteId BIGINT = 0;
	DECLARE	@CustomerId  BIGINT = 0;
	DECLARE @SalesOrderPartId BIGINT = 0;
	DECLARE @SalesOrderStocklineId BIGINT = 0;
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
	DECLARE @FreighFlag INT = 0
	DECLARE @ChargeFlag INT = 0
	DECLARE @TotalFreightPartWise DECIMAL(18,2) = 0;	
	DECLARE @TotalChargePartWise DECIMAL(18,2) = 0;	
	DECLARE @TaxableFreight DECIMAL(18,2) = 0;	
	DECLARE @TaxableCharge DECIMAL(18,2) = 0;

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
		[SalesOrderStocklineId] BIGINT NULL,
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
	
	INSERT INTO #tmprShipDetails ([OriginSiteId],[ShipToSiteId],[CustomerId],[SalesOrderId],[SalesOrderPartId],[SalesOrderStocklineId])	
	                       SELECT SOS.[OriginSiteId],SOS.[ShipToSiteId],SOS.[CustomerId],SOS.[SalesOrderId],SOSI.[SalesOrderPartId],SOPT.SalesOrderPartStocklineId
	                       FROM [dbo].[SalesOrderShipping] SOS WITH(NOLOCK)  
						   INNER JOIN [dbo].[SalesOrderShippingItem] SOSI WITH(NOLOCK) ON SOS.[SalesOrderShippingId]  = SOSI.[SalesOrderShippingId]
						   INNER JOIN [dbo].[SOPickTicket] SOPT WITH(NOLOCK) ON SOPT.[SOPickTicketId]  = SOSI.[SOPickTicketId]
	                       WHERE SOS.[SalesOrderId] = @SalesOrderId;
	

	INSERT INTO #tmprShipDetails ([OriginSiteId],[ShipToSiteId],[CustomerId],[SalesOrderId],[SalesOrderPartId],[SalesOrderStocklineId])
			SELECT CASE WHEN STK.[SiteId] IS NOT NULL THEN STK.[SiteId] ELSE ITM.[SiteId] END,
			       CASE WHEN AAD.[SiteId] IS NOT NULL THEN AAD.[SiteId] ELSE CDS.CustomerDomensticShippingId END,
				   SO.[CustomerId],
				   SO.[SalesOrderId],
				   SOP.[SalesOrderPartId],
				   SOPS.SalesOrderStocklineId
			  FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
	    INNER JOIN [dbo].[SalesOrderPartV1] SOP WITH(NOLOCK) ON SO.[SalesOrderId] = SOP.[SalesOrderId] 
	     LEFT JOIN [dbo].[SalesOrderStocklineV1] SOPS WITH(NOLOCK) ON SOPS.[SalesOrderPartId] = SOP.[SalesOrderPartId] 
		 LEFT JOIN [dbo].[AllAddress] AAD WITH(NOLOCK) ON SO.[SalesOrderId] = AAD.[ReffranceId] AND [IsShippingAdd] = 1 AND [ModuleId] = @SOModuleId
		 LEFT JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON SOPS.[StockLineId] = STK.[StockLineId]
		 LEFT JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON SOP.[ItemMasterId] = ITM.[ItemMasterId]
		  LEFT JOIN [dbo].[CustomerDomensticShipping] CDS WITH(NOLOCK) ON CDS.[CustomerId] = SO.[CustomerId] AND CDS.[IsPrimary] = 1
	         WHERE SO.[SalesOrderId] = @SalesOrderId AND 
							SOP.SalesOrderPartId NOT IN (SELECT SOSI.SalesOrderPartId FROM [dbo].[SalesOrderShipping] SOS WITH(NOLOCK)  
							INNER JOIN [dbo].[SalesOrderShippingItem] SOSI WITH(NOLOCK) ON SOS.[SalesOrderShippingId]  = SOSI.[SalesOrderShippingId]
	                        WHERE [SalesOrderId] = @SalesOrderId);
							
	SELECT @FreightMethodId = SO.[FreightBilingMethodId],
	       @ChargesMethodId = SO.[ChargesBilingMethodId] 
	  FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
     WHERE SO.[SalesOrderId] = @SalesOrderId;

	SELECT @TotalFreight = CASE WHEN SO.FreightBilingMethodId = @FreightBilingMethodId 
	                            THEN ISNULL(SO.TotalFreight,0)
								ELSE								
									ISNULL(SUM(SOF.BillingAmount),0) 
								END			
	FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
	LEFT JOIN [dbo].[SalesOrderFreight] SOF WITH(NOLOCK) ON so.SalesOrderId = SOF.SalesOrderId AND SOF.IsActive = 1 AND SOF.IsDeleted = 0  
   	WHERE SO.SalesOrderId = @SalesOrderId GROUP BY SO.FreightBilingMethodId,SO.TotalFreight

	SELECT @TotalCharges = CASE WHEN SO.ChargesBilingMethodId = @ChargesBilingMethodId
	                            THEN ISNULL(SO.TotalCharges,0)
								ELSE								
									ISNULL(SUM(SOC.BillingAmount),0) 
								END			
	FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
	LEFT JOIN [dbo].[SalesOrderCharges] SOC WITH(NOLOCK) ON so.SalesOrderId = SOC.SalesOrderId AND SOC.IsActive = 1 AND SOC.IsDeleted = 0  
   	WHERE SO.SalesOrderId = @SalesOrderId GROUP BY SO.ChargesBilingMethodId,SO.TotalCharges
	
	IF(@FreightMethodId = @FreightBilingMethodId)
	BEGIN
			SELECT @TotalFreightPartWise = ISNULL(SO.TotalFreight,0) FROM [dbo].[SalesOrder] SO WITH(NOLOCK) WHERE [SO].[SalesOrderId] = @SalesOrderId 
			SET @TaxableFreight = @TotalFreightPartWise;
			SET @FreighFlag = 1;
	END

	IF(@ChargesMethodId = @ChargesBilingMethodId)
	BEGIN
			SELECT @TotalChargePartWise = ISNULL(SO.TotalCharges,0) FROM [dbo].[SalesOrder] SO WITH(NOLOCK) WHERE [SO].[SalesOrderId] = @SalesOrderId 
			SET @TaxableCharge = @TotalChargePartWise;
			SET @ChargeFlag = 1;
	END
														
	SELECT @TotalRecord = COUNT(*), @MinId = MIN(ID) FROM #tmprShipDetails    
	
	WHILE @MinId <= @TotalRecord
	BEGIN
		DECLARE @ConditionId BIGINT = 0
		DECLARE @ItemMasterId BIGINT = 0

		SELECT @OriginSiteId = [OriginSiteId],
	           @ShipToSiteId = [ShipToSiteId],
		       @CustomerId   = [CustomerId],
			   @SalesOrderPartId = [SalesOrderPartId],
			   @SalesOrderStocklineId = [SalesOrderStocklineId]
		FROM #tmprShipDetails WHERE ID = @MinId

		IF(@FreighFlag = 0)
		BEGIN
			SELECT @TotalFreightPartWise = ISNULL(SUM(SOF.[BillingAmount]),0) 											
	        FROM [dbo].[SalesOrderFreight] SOF WITH(NOLOCK)
   	        WHERE SOF.[SalesOrderId] = @SalesOrderId 
			  AND SOF.[SalesOrderPartId] = @SalesOrderPartId 
			  AND SOF.[IsActive] = 1 
			  AND SOF.[IsDeleted] = 0   
		END			   
		
		IF(@ChargeFlag = 0)
		BEGIN
			SELECT @TotalChargePartWise = ISNULL(SUM(SOC.[BillingAmount]),0) 											
	        FROM [dbo].[SalesOrderCharges] SOC WITH(NOLOCK)
   	        WHERE SOC.[SalesOrderId] = @SalesOrderId 
			  AND SOC.[SalesOrderPartId] = @SalesOrderPartId 
			  AND SOC.[IsActive] = 1 
			  AND SOC.[IsDeleted] = 0; 
		END				

		EXEC [dbo].[USP_GetCustomerTax_Information_ProductSale] 
		     @CustomerId,
			 @ShipToSiteId,
			 @OriginSiteId,
		     @TotalSalesTax = @TotalSalesTax OUTPUT,
		     @TotalOtherTax = @TotalOtherTax OUTPUT	
			 
		IF (@SalesOrderStocklineId IS NOT NULL)
		BEGIN
			SELECT @Total = (ISNULL(SOSC.NetSaleAmount, 0))
				FROM [dbo].[SalesOrderPartV1] SOP WITH(NOLOCK)
				LEFT JOIN [dbo].[SalesOrderStocklineV1] STK WITH(NOLOCK) ON STK.SalesOrderPartId = SOP.SalesOrderPartId
				LEFT JOIN [dbo].[SalesOrderPartCost] SOPC WITH(NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
				LEFT JOIN [dbo].[SalesOrderStocklineCost] SOSC WITH(NOLOCK) ON SOSC.SalesOrderStocklineId = STK.SalesOrderStocklineId
				WHERE [SOP].[SalesOrderId] = @SalesOrderId 
				  AND [SOP].[SalesOrderPartId] = @SalesOrderPartId
				  AND [STK].SalesOrderStocklineId = @SalesOrderStocklineId;
		END
		ELSE
		BEGIN
			SELECT @Total = (ISNULL(SOPC.NetSaleAmount, 0))
				FROM [dbo].[SalesOrderPartV1] SOP WITH(NOLOCK)
				LEFT JOIN [dbo].[SalesOrderStocklineV1] STK WITH(NOLOCK) ON STK.SalesOrderPartId = SOP.SalesOrderPartId
				LEFT JOIN [dbo].[SalesOrderPartCost] SOPC WITH(NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
				LEFT JOIN [dbo].[SalesOrderStocklineCost] SOSC WITH(NOLOCK) ON SOSC.SalesOrderStocklineId = STK.SalesOrderStocklineId
				WHERE [SOP].[SalesOrderId] = @SalesOrderId 
				  AND [SOP].[SalesOrderPartId] = @SalesOrderPartId;
		END
			  
	    SET @SubTotal += ISNULL(@Total,0);
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
		ELSE
		BEGIN
			IF(@TotalRecord = 1)
			BEGIN
				IF(@FreighFlag = 1)
				BEGIN
					SET @FreighSalesTax = (ISNULL(@TotalFreightPartWise,0)  * ISNULL(@TotalSalesTax,0) / 100);
					SET @FreighOtherTax = (ISNULL(@TotalFreightPartWise,0)  * ISNULL(@TotalOtherTax,0) / 100);
				END
				IF(@FreighFlag = 0)
				BEGIN
					SET @FreighSalesTax = (ISNULL(@TaxableFreight,0)  * ISNULL(@TotalSalesTax,0) / 100);
					SET @FreighOtherTax = (ISNULL(@TaxableFreight,0)  * ISNULL(@TotalOtherTax,0) / 100);
				END
				IF(@ChargeFlag = 1)
				BEGIN
					SET @ChargeSalesTax = (ISNULL(@TotalChargePartWise,0)  * ISNULL(@TotalSalesTax,0) / 100);
					SET @ChargeOtherTax = (ISNULL(@TotalChargePartWise,0)  * ISNULL(@TotalOtherTax,0) / 100);
				END
				IF(@ChargeFlag = 0)
				BEGIN
					SET @ChargeSalesTax = (ISNULL(@TaxableCharge,0)  * ISNULL(@TotalSalesTax,0) / 100);
					SET @ChargeOtherTax = (ISNULL(@TaxableCharge,0)  * ISNULL(@TotalOtherTax,0) / 100);
				END		

				UPDATE #tmprShipDetails SET [SalesTax] = @SalesTax + @FreighSalesTax + @ChargeSalesTax, 
											[OtherTax] = @OtherTax + @FreighOtherTax + @ChargeOtherTax									
									  WHERE [ID] = @MinId;
			END
			ELSE
			BEGIN
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
					print @FreighSalesTax
					print @FreighOtherTax
					print @ChargeSalesTax
					print @ChargeOtherTax
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
			END
		END
		IF(@TotalSalesTax > 0 OR @TotalOtherTax > 0)
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM #tmprShipDetails2 WHERE [OriginSiteId] = @OriginSiteId AND [ShipToSiteId] = @ShipToSiteId and [CustomerId]=@CustomerId)
			BEGIN
				INSERT INTO #tmprShipDetails2 ([OriginSiteId],[ShipToSiteId],[CustomerId],[SalesOrderId],[SalesTax],[OtherTax])
				     SELECT @OriginSiteId,@ShipToSiteId,@CustomerId,@SalesOrderId,ISNULL(@TotalSalesTax,0),ISNULL(@TotalOtherTax,0);
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
					
	--SELECT @FinalSalesTaxes = SUM([SalesTax]), @FinalOtherTaxes = SUM([OtherTax]) FROM #tmprShipDetails	

	SET @FinalSalesTaxes = (ISNULL((@SubTotal + @TotalFreight + @TotalCharges),0)  * ISNULL(@TotalSalesTax,0) / 100);
	SET @FinalOtherTaxes = (ISNULL((@SubTotal + @TotalFreight + @TotalCharges),0)  * ISNULL(@TotalOtherTax,0) / 100);
	
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
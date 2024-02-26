/*************************************************************           
 ** File:   [USP_GetCustomerTax_Information_Repair_WO_BeforAfter_Shipping]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to get Customer Tax Information based on ProductSale
 ** Purpose:         
 ** Date:   02/15/2024        
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/15/2024   Moin Bloch    Created
	2    02/22/2024   Moin Bloch    Updated For Multiple MPN
     
-- EXEC [USP_GetCustomerTax_Information_Repair_WO_BeforAfter_Shipping] 10403,4111,77,1
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetCustomerTax_Information_Repair_WO_BeforAfter_Shipping] 
@WoBillingInvoicingId BIGINT,
@WorkOrderId BIGINT,
@CustomerId BIGINT,
@MasterCompanyId INT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
	DECLARE @SalesTax Decimal(18,2) = 0;
	DECLARE @OtherTax Decimal(18,2) = 0;
	DECLARE @FreighSalesTax DECIMAL(18,2) = 0;
	DECLARE @FreighOtherTax DECIMAL(18,2) = 0;
	DECLARE @ChargeSalesTax DECIMAL(18,2) = 0;	
	DECLARE @ChargeOtherTax DECIMAL(18,2) = 0;
	DECLARE @TotalRecord INT = 0; 
	DECLARE @MinId BIGINT = 1;    
	DECLARE @MinPartId BIGINT = 1;    
	DECLARE @OriginSiteId BIGINT = 0;
	DECLARE @ShipToSiteId BIGINT = 0;
	DECLARE @WorkOrderPartId BIGINT = 0;
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
	DECLARE @WorkOrderSettingId BIGINT = 0;
	DECLARE @TotalShippingRecords INT = 0;
	DECLARE @TotalDirectBillingRecords INT = 0;	
	DECLARE @TotalPart INT = 0;	

	IF OBJECT_ID(N'tempdb..#tmprwoShipDetails') IS NOT NULL
	BEGIN
		DROP TABLE #tmprwoShipDetails
	END

	IF OBJECT_ID(N'tempdb..#tmprwoShipDetails2') IS NOT NULL
	BEGIN
		DROP TABLE #tmprwoShipDetails2
	END

	IF OBJECT_ID(N'tempdb..#tmprwoBillingPartDetails') IS NOT NULL
	BEGIN
		DROP TABLE #tmprwoBillingPartDetails
	END
		
	CREATE TABLE #tmprwoShipDetails
	(
		[ID] BIGINT NOT NULL IDENTITY, 		
		[OriginSiteId] BIGINT NULL,
		[ShipToSiteId] BIGINT NULL,
		[CustomerId]  BIGINT NULL,
		[WorkOrderId] BIGINT NULL,
		[WorkOrderPartId] BIGINT NULL,
		[SalesTax] DECIMAL(18,2) NULL,
		[OtherTax]  DECIMAL(18,2) NULL				
	)
	
	CREATE TABLE #tmprwoShipDetails2
	(
		[ID] BIGINT NOT NULL IDENTITY, 		
		[OriginSiteId] BIGINT NULL,
		[ShipToSiteId] BIGINT NULL,
		[CustomerId]  BIGINT NULL,
		[WorkOrderId] BIGINT NULL,		
		[SalesTax] DECIMAL(18,2) NULL,
		[OtherTax]  DECIMAL(18,2) NULL
	)

	CREATE TABLE #tmprwoBillingPartDetails
	(
		[ID] BIGINT NOT NULL IDENTITY,
		[WorkOrderId] BIGINT NULL,
		[WorkOrderPartId] BIGINT NULL
	)

	SELECT @WorkOrderSettingId = ISNULL([WorkOrderSettingId],0) 
	  FROM [dbo].[WorkOrderSettings] SOS WITH(NOLOCK) 
	  WHERE SOS.[MasterCompanyId] = @MasterCompanyId AND SOS.[IsActive] = 1 AND SOS.[IsDeleted] = 0 AND SOS.[AllowInvoiceBeforeShipping] = 1;
	  	
	 SELECT @TotalPart = COUNT(*) FROM [dbo].[WorkOrderBillingInvoicingItem] WOBII WITH(NOLOCK) 
	 WHERE WOBII.[BillingInvoicingId]  = @WoBillingInvoicingId AND WOBII.[IsVersionIncrease] = 0;

	 IF(@TotalPart = 1)
	 BEGIN
		 IF(@WorkOrderSettingId > 0)
		 BEGIN	 
			INSERT INTO #tmprwoShipDetails ([OriginSiteId],[ShipToSiteId],[CustomerId],[WorkOrderId],[WorkOrderPartId])	
			  SELECT WOS.[OriginSiteId],WOS.[ShipToSiteId],WOS.[CustomerId],WOS.[WorkOrderId],WOSI.[WorkOrderPartNumId]
				  FROM [dbo].[WorkOrderBillingInvoicingItem] WOBII WITH(NOLOCK)	
				  INNER JOIN [dbo].[WorkOrderBillingInvoicing] WOBI WITH(NOLOCK) ON WOBII.[BillingInvoicingId]  = WOBI.[BillingInvoicingId] AND WOBI.[IsVersionIncrease] = 0
				  INNER JOIN [dbo].[WorkOrderShipping] WOS WITH(NOLOCK) ON WOBI.[WorkOrderShippingId]  = WOS.[WorkOrderShippingId] AND WOBI.[WorkOrderId] = WOS.[WorkOrderId]
				  INNER JOIN [dbo].[WorkOrderShippingItem] WOSI WITH(NOLOCK) ON WOS.[WorkOrderShippingId]  = WOSI.[WorkOrderShippingId] AND WOBII.[WorkOrderPartId] = WOSI.[WorkOrderPartNumId]
				  WHERE WOBII.[BillingInvoicingId]  = @WoBillingInvoicingId AND [WOBII].[IsActive] = 1 AND [WOBII].[IsDeleted] = 0;
					  
			SELECT @TotalShippingRecords = COUNT(*) FROM #tmprwoShipDetails  
		
			IF(@TotalShippingRecords = 0)
			BEGIN			
				INSERT INTO #tmprwoBillingPartDetails ([WorkOrderId],[WorkOrderPartId])				
				SELECT @WorkOrderId,WOBI.[WorkOrderPartId]
					   FROM [dbo].[WorkOrderBillingInvoicingItem] WOBI WITH(NOLOCK)	
				WHERE WOBI.[BillingInvoicingId] = @WoBillingInvoicingId AND WOBI.[IsVersionIncrease] = 0 AND WOBI.[IsActive] = 1 AND WOBI.[IsDeleted] = 0;
					
			   SELECT @TotalDirectBillingRecords = COUNT(*),@MinPartId = MIN(ID) FROM #tmprwoBillingPartDetails
			   IF(@TotalDirectBillingRecords > 0)
			   BEGIN
					WHILE @MinPartId <= @TotalDirectBillingRecords
					BEGIN
						  DECLARE @BillingOriginSiteId BIGINT = 0
						  DECLARE @BillingShipToSiteId BIGINT = 0

						  SELECT @WorkOrderPartId = [WorkOrderPartId] FROM #tmprwoBillingPartDetails WHERE ID = @MinPartId					  

						  EXEC [dbo].[USP_GetCustomerTax_Information_ProductSale_WO_INVBS_Parts] 
							   @WorkOrderId,
							   @WorkOrderPartId,						   
							   @BillingOriginSiteId = @BillingOriginSiteId OUTPUT,
							   @BillingShipToSiteId = @BillingShipToSiteId OUTPUT

						  INSERT INTO #tmprwoShipDetails ([OriginSiteId],[ShipToSiteId],[CustomerId],[WorkOrderId],[WorkOrderPartId])	
							   SELECT @BillingOriginSiteId,@BillingShipToSiteId,@CustomerId,@WorkOrderId,@WorkOrderPartId

						SET @MinPartId = @MinPartId + 1
					END
			   END		
			END
		 END
		 ELSE
		 BEGIN		
				INSERT INTO #tmprwoShipDetails ([OriginSiteId],[ShipToSiteId],[CustomerId],[WorkOrderId],[WorkOrderPartId])	
				 SELECT WOS.[OriginSiteId],WOS.[ShipToSiteId],WOS.[CustomerId],WOS.[WorkOrderId],WOSI.[WorkOrderPartNumId]
				  FROM [dbo].[WorkOrderBillingInvoicingItem] WOBII WITH(NOLOCK)	
				  INNER JOIN [dbo].[WorkOrderBillingInvoicing] WOBI WITH(NOLOCK) ON WOBII.[BillingInvoicingId]  = WOBI.[BillingInvoicingId] AND WOBI.[IsVersionIncrease] = 0
				  INNER JOIN [dbo].[WorkOrderShipping] WOS WITH(NOLOCK) ON WOBI.[WorkOrderShippingId]  = WOS.[WorkOrderShippingId] AND WOBI.[WorkOrderId] = WOS.[WorkOrderId]
				  INNER JOIN [dbo].[WorkOrderShippingItem] WOSI WITH(NOLOCK) ON WOS.[WorkOrderShippingId]  = WOSI.[WorkOrderShippingId] AND WOBII.[WorkOrderPartId] = WOSI.[WorkOrderPartNumId]
				  WHERE WOBII.[BillingInvoicingId]  = @WoBillingInvoicingId AND [WOBII].[IsActive] = 1 AND [WOBII].[IsDeleted] = 0;
		  END		
														
		SELECT @TotalRecord = COUNT(*), @MinId = MIN(ID) FROM #tmprwoShipDetails    
	
		WHILE @MinId <= @TotalRecord
		BEGIN
			SELECT @OriginSiteId = [OriginSiteId],
				   @ShipToSiteId = [ShipToSiteId],
				   @CustomerId   = [CustomerId],
				   @WorkOrderPartId = [WorkOrderPartId]
			  FROM #tmprwoShipDetails WHERE ID = @MinId
			---------------------------------------------Freight----------------------------------------------------------		  				
			SELECT @TotalFreightPartWise = ISNULL(SUM(WOF.[Amount]),0) 
				  FROM [dbo].[WorkOrderFreight] WOF WITH(NOLOCK)	
				INNER JOIN [dbo].[WorkOrderWorkFlow] WWF WITH(NOLOCK) ON WOF.[WorkFlowWorkOrderId] = wwf.[WorkFlowWorkOrderId]
				INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WOP.[ID] = WWF.[WorkOrderPartNoId]
				WHERE WOF.[WorkOrderId] = @WorkOrderId 
				  AND WWF.[WorkOrderPartNoId] = @WorkOrderPartId 
				  AND WOF.IsActive = 1 
				  AND WOF.IsDeleted = 0
			---------------------------------------------Charges----------------------------------------------------------
			SELECT @TotalChargePartWise = ISNULL(SUM(WOC.[ExtendedCost]),0) 
				  FROM [dbo].[WorkOrderCharges] WOC WITH(NOLOCK)	
				INNER JOIN [dbo].[WorkOrderWorkFlow] WWF WITH(NOLOCK) ON WOC.[WorkFlowWorkOrderId] = wwf.[WorkFlowWorkOrderId]
				INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WOP.[ID] = WWF.[WorkOrderPartNoId]
				WHERE WOC.[WorkOrderId] = @WorkOrderId 
				  AND WWF.[WorkOrderPartNoId] = @WorkOrderPartId 
				  AND WOC.IsActive = 1 
				  AND WOC.IsDeleted = 0
			--------------------------------------------------------------------------------------------------------------		
			EXEC [dbo].[USP_GetCustomerTax_Information_Repair] 
				 @CustomerId,
				 @ShipToSiteId,
				 @OriginSiteId,
				 @TotalSalesTax = @TotalSalesTax OUTPUT,
				 @TotalOtherTax = @TotalOtherTax OUTPUT	
				
			SELECT  @Total = WOBII.[SubTotal] FROM [dbo].[WorkOrderBillingInvoicing] WOBI WITH(NOLOCK)
				INNER JOIN  [dbo].[WorkOrderBillingInvoicingItem] WOBII WITH(NOLOCK) ON WOBII.[BillingInvoicingId]  = WOBI.[BillingInvoicingId] AND WOBI.[IsVersionIncrease] = 0
				WHERE [WOBI].[WorkOrderId] = @WorkOrderId 
				  AND [WOBII].[WorkOrderPartId] = @WorkOrderPartId;	
				  
			SET @SubTotal += ISNULL(@Total,0);
			SET @SalesTax = (ISNULL(@Total,0) * ISNULL(@TotalSalesTax,0) / 100)
			SET @OtherTax = (ISNULL(@Total,0) * ISNULL(@TotalOtherTax,0) / 100)
										
			UPDATE #tmprwoShipDetails SET [SalesTax] = @SalesTax, 
										  [OtherTax] = @OtherTax 									
									WHERE [ID] = @MinId	
		
			IF(@TotalSalesTax > 0 OR @TotalOtherTax > 0)
			BEGIN
				IF NOT EXISTS(SELECT 1 FROM #tmprwoShipDetails2 WHERE [OriginSiteId] = @OriginSiteId AND [ShipToSiteId] = @ShipToSiteId AND [CustomerId]=@CustomerId)
				BEGIN
					INSERT INTO #tmprwoShipDetails2 ([OriginSiteId],[ShipToSiteId],[CustomerId],[WorkOrderId],[SalesTax],[OtherTax])
						 SELECT @OriginSiteId,@ShipToSiteId,@CustomerId,@WorkOrderId,ISNULL(@TotalSalesTax,0),ISNULL(@TotalOtherTax,0);
				END		
			END		
			SET @MinId = @MinId + 1
		END
	
		SELECT @TotalRecord2 = COUNT(*), @MinId2 = MIN(ID) FROM #tmprwoShipDetails2    

		WHILE @MinId2 <= @TotalRecord2
		BEGIN
			DECLARE @STX DECIMAL(18,2)=0
			DECLARE @OTX DECIMAL(18,2)=0

			SELECT @STX = [SalesTax],
				   @OTX = [OtherTax]			  
			FROM #tmprwoShipDetails2 WHERE ID = @MinId2

			SET @TotalSalesTaxes += @STX
			SET @TotalOtherTaxes += @OTX

			SET @MinId2 = @MinId2 + 1
		END	
			
		SELECT @FinalSalesTaxes = SUM([SalesTax]), @FinalOtherTaxes = SUM([OtherTax]) FROM #tmprwoShipDetails	
		
		SELECT  ISNULL(@TotalFreight,0) AS TotalFreight,
				ISNULL(@TotalCharges,0) AS TotalCharges,
				ISNULL((@SubTotal),0) AS Total,			
				ISNULL((@SubTotal + @TotalFreight + @TotalCharges),0) AS SubTotal,
				ISNULL((@SubTotal + @TotalFreight + @TotalCharges + @FinalSalesTaxes +  @FinalOtherTaxes),0) AS GrandTotal,
				ISNULL(@FinalSalesTaxes,0) AS SalesTax,
				ISNULL(@FinalOtherTaxes,0) AS OtherTax;
	 END
	 ELSE IF(@TotalPart > 1)
	 BEGIN
		IF(@WorkOrderSettingId > 0)
		 BEGIN	 
			INSERT INTO #tmprwoShipDetails ([OriginSiteId],[ShipToSiteId],[CustomerId],[WorkOrderId],[WorkOrderPartId])	
			  SELECT WOS.[OriginSiteId],WOS.[ShipToSiteId],WOS.[CustomerId],WOS.[WorkOrderId],WOSI.[WorkOrderPartNumId]
				  FROM [dbo].[WorkOrderBillingInvoicingItem] WOBII WITH(NOLOCK)	
				  INNER JOIN [dbo].[WorkOrderBillingInvoicing] WOBI WITH(NOLOCK) ON WOBII.[BillingInvoicingId]  = WOBI.[BillingInvoicingId] AND WOBI.[IsVersionIncrease] = 0
				  INNER JOIN [dbo].[WorkOrderShipping] WOS WITH(NOLOCK) ON WOBI.[WorkOrderShippingId]  = WOS.[WorkOrderShippingId] AND WOBI.[WorkOrderId] = WOS.[WorkOrderId]
				  INNER JOIN [dbo].[WorkOrderShippingItem] WOSI WITH(NOLOCK) ON WOS.[WorkOrderShippingId]  = WOSI.[WorkOrderShippingId] AND WOBII.[WorkOrderPartId] = WOSI.[WorkOrderPartNumId]
				  WHERE WOBII.[BillingInvoicingId]  = @WoBillingInvoicingId AND [WOBII].[IsActive] = 1 AND [WOBII].[IsDeleted] = 0;
					  
			SELECT @TotalShippingRecords = COUNT(*) FROM #tmprwoShipDetails  
		
			IF(@TotalShippingRecords = 0)
			BEGIN			
				INSERT INTO #tmprwoBillingPartDetails ([WorkOrderId],[WorkOrderPartId])				
				SELECT @WorkOrderId,WOBI.[WorkOrderPartId]
					   FROM [dbo].[WorkOrderBillingInvoicingItem] WOBI WITH(NOLOCK)	
				WHERE WOBI.[BillingInvoicingId] = @WoBillingInvoicingId AND WOBI.[IsVersionIncrease] = 0 AND WOBI.[IsActive] = 1 AND WOBI.[IsDeleted] = 0;
					
			   SELECT @TotalDirectBillingRecords = COUNT(*),@MinPartId = MIN(ID) FROM #tmprwoBillingPartDetails
			   IF(@TotalDirectBillingRecords > 0)
			   BEGIN
					WHILE @MinPartId <= @TotalDirectBillingRecords
					BEGIN
						  DECLARE @BillingOriginSiteId2 BIGINT = 0
						  DECLARE @BillingShipToSiteId2 BIGINT = 0

						  SELECT @WorkOrderPartId = [WorkOrderPartId] FROM #tmprwoBillingPartDetails WHERE ID = @MinPartId					  

						  EXEC [dbo].[USP_GetCustomerTax_Information_ProductSale_WO_INVBS_Parts] 
							   @WorkOrderId,
							   @WorkOrderPartId,						   
							   @BillingOriginSiteId = @BillingOriginSiteId2 OUTPUT,
							   @BillingShipToSiteId = @BillingShipToSiteId2 OUTPUT
						  print @BillingOriginSiteId2
						  print @BillingShipToSiteId2

						  INSERT INTO #tmprwoShipDetails ([OriginSiteId],[ShipToSiteId],[CustomerId],[WorkOrderId],[WorkOrderPartId])	
							   SELECT @BillingOriginSiteId2,@BillingShipToSiteId2,@CustomerId,@WorkOrderId,@WorkOrderPartId

						SET @MinPartId = @MinPartId + 1
					END
			   END		
			END
		 END
		 ELSE
		 BEGIN		
				INSERT INTO #tmprwoShipDetails ([OriginSiteId],[ShipToSiteId],[CustomerId],[WorkOrderId],[WorkOrderPartId])	
				 SELECT WOS.[OriginSiteId],WOS.[ShipToSiteId],WOS.[CustomerId],WOS.[WorkOrderId],WOSI.[WorkOrderPartNumId]
				  FROM [dbo].[WorkOrderBillingInvoicingItem] WOBII WITH(NOLOCK)	
				  INNER JOIN [dbo].[WorkOrderBillingInvoicing] WOBI WITH(NOLOCK) ON WOBII.[BillingInvoicingId]  = WOBI.[BillingInvoicingId] AND WOBI.[IsVersionIncrease] = 0
				  INNER JOIN [dbo].[WorkOrderShipping] WOS WITH(NOLOCK) ON WOBI.[WorkOrderShippingId]  = WOS.[WorkOrderShippingId] AND WOBI.[WorkOrderId] = WOS.[WorkOrderId]
				  INNER JOIN [dbo].[WorkOrderShippingItem] WOSI WITH(NOLOCK) ON WOS.[WorkOrderShippingId]  = WOSI.[WorkOrderShippingId] AND WOBII.[WorkOrderPartId] = WOSI.[WorkOrderPartNumId]
				  WHERE WOBII.[BillingInvoicingId]  = @WoBillingInvoicingId AND [WOBII].[IsActive] = 1 AND [WOBII].[IsDeleted] = 0;
		  END		
														
		SELECT @TotalRecord = COUNT(*), @MinId = MIN(ID) FROM #tmprwoShipDetails    
	
		WHILE @MinId <= @TotalRecord
		BEGIN
			SELECT @OriginSiteId = [OriginSiteId],
				   @ShipToSiteId = [ShipToSiteId],
				   @CustomerId   = [CustomerId],
				   @WorkOrderPartId = [WorkOrderPartId]
			  FROM #tmprwoShipDetails WHERE ID = @MinId
					
			EXEC [dbo].[USP_GetCustomerTax_Information_Repair] 
				 @CustomerId,
				 @ShipToSiteId,
				 @OriginSiteId,
				 @TotalSalesTax = @TotalSalesTax OUTPUT,
				 @TotalOtherTax = @TotalOtherTax OUTPUT	
				
			SELECT @Total = WOBII.[SubTotal] FROM [dbo].[WorkOrderBillingInvoicing] WOBI WITH(NOLOCK)
				INNER JOIN  [dbo].[WorkOrderBillingInvoicingItem] WOBII WITH(NOLOCK) ON WOBII.[BillingInvoicingId]  = WOBI.[BillingInvoicingId] AND WOBI.[IsVersionIncrease] = 0
				WHERE [WOBI].[WorkOrderId] = @WorkOrderId 
				  AND [WOBII].[WorkOrderPartId] = @WorkOrderPartId;	
				  
			 SET @SubTotal = ISNULL(@Total,0);

			IF(@TotalSalesTax > 0 OR @TotalOtherTax > 0)
			BEGIN
				IF NOT EXISTS(SELECT 1 FROM #tmprwoShipDetails2 WHERE [OriginSiteId] = @OriginSiteId AND [ShipToSiteId] = @ShipToSiteId AND [CustomerId]=@CustomerId)
				BEGIN
					INSERT INTO #tmprwoShipDetails2 ([OriginSiteId],[ShipToSiteId],[CustomerId],[WorkOrderId],[SalesTax],[OtherTax])
						 SELECT @OriginSiteId,@ShipToSiteId,@CustomerId,@WorkOrderId,ISNULL(@TotalSalesTax,0),ISNULL(@TotalOtherTax,0);
				END		
			END		
			SET @MinId = @MinId + 1
		END
	
		SELECT @TotalRecord2 = COUNT(*), @MinId2 = MIN(ID) FROM #tmprwoShipDetails2    

		WHILE @MinId2 <= @TotalRecord2
		BEGIN
			DECLARE @STX2 DECIMAL(18,2)=0
			DECLARE @OTX2 DECIMAL(18,2)=0

			SELECT @STX2 = [SalesTax],
				   @OTX2 = [OtherTax]			  
			FROM #tmprwoShipDetails2 WHERE ID = @MinId2

			SET @TotalSalesTaxes += @STX2
			SET @TotalOtherTaxes += @OTX2

			SET @MinId2 = @MinId2 + 1
		END	

		SELECT @FinalSalesTaxes = (ISNULL(@SubTotal,0)  * ISNULL(@TotalSalesTaxes,0) / 100),
	           @FinalOtherTaxes = (ISNULL(@SubTotal,0)  * ISNULL(@TotalOtherTaxes,0) / 100)
		
		SELECT 	ISNULL((@SubTotal),0) AS SubTotal,
				ISNULL(@FinalSalesTaxes,0) AS SalesTax,
				ISNULL(@FinalOtherTaxes,0) AS OtherTax;
	END
		
  END TRY

  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[USP_GetCustomerTax_Information_Repair_WO_BeforAfter_Shipping]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100)),
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
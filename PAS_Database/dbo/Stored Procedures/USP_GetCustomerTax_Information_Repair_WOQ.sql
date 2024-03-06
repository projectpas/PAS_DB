/*************************************************************           
 ** File:   [USP_GetCustomerTax_Information_Repair_WOQ]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to get Customer Tax Information based on Repair in WOQ
 ** Purpose:         
 ** Date:   14/02/2024        
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    14/02/2024   Moin Bloch    Created
	2    05/03/2024   Moin Bloch    Updated changed join ItemMaster To [Stockline]
     
--   EXEC [USP_GetCustomerTax_Information_Repair_WOQ] 2169,4106,3596
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetCustomerTax_Information_Repair_WOQ] 
@WorkOrderQuoteId BIGINT,
@WorkorderId BIGINT,
@workOrderPartNoId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
	DECLARE @SalesTax Decimal(18,2) = 0;
	DECLARE @OtherTax Decimal(18,2) = 0;
	DECLARE @TotalRecord INT = 0; 
	DECLARE @MinId BIGINT = 1;    
	DECLARE @OriginSiteId BIGINT = 0;
	DECLARE @ShipToSiteId BIGINT = 0;
	DECLARE	@CustomerId  BIGINT = 0;
	DECLARE @WorkOrderPartNumId BIGINT = 0;
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
	DECLARE @FreighSalesTax DECIMAL(18,2) = 0;
	DECLARE @FreighOtherTax DECIMAL(18,2) = 0;
	DECLARE @ChargeSalesTax DECIMAL(18,2) = 0;	
	DECLARE @ChargeOtherTax DECIMAL(18,2) = 0;	

	IF OBJECT_ID(N'tempdb..#tmprWorkorderquoteDetails') IS NOT NULL
	BEGIN
		DROP TABLE #tmprWorkorderquoteDetails
	END

	IF OBJECT_ID(N'tempdb..#tmprWorkorderquoteDetails2') IS NOT NULL
	BEGIN
		DROP TABLE #tmprWorkorderquoteDetails2
	END
		
	CREATE TABLE #tmprWorkorderquoteDetails
	(
		[ID] BIGINT NOT NULL IDENTITY, 		
		[OriginSiteId] BIGINT NULL,
		[ShipToSiteId] BIGINT NULL,
		[CustomerId]  BIGINT NULL,
		[WorkOrderId] BIGINT NULL,
		[WorkOrderQuoteId] BIGINT NULL,
		[WorkOrderPartNumId] BIGINT NULL,
		[SalesTax] DECIMAL(18,2) NULL,
		[OtherTax]  DECIMAL(18,2) NULL
	)
	
	CREATE TABLE #tmprWorkorderquoteDetails2
	(
		[ID] BIGINT NOT NULL IDENTITY, 		
		[OriginSiteId] BIGINT NULL,
		[ShipToSiteId] BIGINT NULL,
		[CustomerId]  BIGINT NULL,
		[WorkOrderQuoteId] BIGINT NULL,	
		[SalesTax] DECIMAL(18,2) NULL,
		[OtherTax]  DECIMAL(18,2) NULL
	)
			
	INSERT INTO #tmprWorkorderquoteDetails ([OriginSiteId],[ShipToSiteId],[CustomerId],[WorkOrderId],[WorkOrderQuoteId],[WorkOrderPartNumId])
			SELECT STK.[SiteId],
			       CDS.CustomerDomensticShippingId,
				   WOQ.[CustomerId],
				   WOQ.[WorkOrderId],
				   WOQ.[WorkOrderQuoteId],
				   WOP.[ID]
			  FROM [dbo].[WorkOrderQuote] WOQ WITH(NOLOCK) 
	    INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WOQ.[WorkOrderId] = WOP.[WorkOrderId] 
   	    INNER JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON WOP.[StockLineId] = STK.[StockLineId]
		  LEFT JOIN [dbo].[CustomerDomensticShipping] CDS WITH(NOLOCK) ON CDS.[CustomerId] = WOQ.[CustomerId] AND CDS.[IsPrimary] = 1
		 WHERE WOQ.[WorkOrderQuoteId] = @WorkOrderQuoteId 
		   AND WOP.[ID] = @workOrderPartNoId 
		   AND WOQ.[IsActive] = 1 
		   AND WOQ.[IsDeleted] = 0;
		 	      
   ---------------------------------Freight--------------------------------------------------------
 	
	SELECT @TotalFreight = CASE WHEN ISNULL(WQD.[QuoteMethod],0) > 0 THEN 0.00 ELSE ISNULL(SUM(WQD.[FreightFlatBillingAmount]),0) END 
	FROM [dbo].[WorkOrder] WO WITH(NOLOCK)
		 INNER JOIN [dbo].[WorkOrderQuote] WOQ WITH(NOLOCK) ON WO.[WorkOrderId] = WOQ.WorkOrderId  
		 INNER JOIN [dbo].[WorkOrderQuoteDetails] WQD WITH(NOLOCK) ON WOQ.[WorkOrderQuoteId] = WQD.[WorkOrderQuoteId]  
		 INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WQD.[WOPartNoId] = WOP.[ID]  		 
	WHERE WOQ.[WorkOrderQuoteId] = @WorkOrderQuoteId AND WOP.[ID] = @workOrderPartNoId AND WOQ.[IsActive] = 1 AND WOQ.[IsDeleted] = 0
	GROUP BY WQD.[QuoteMethod]

	-------------------------------- Charges--------------------------------------------------------

	SELECT @TotalCharges = CASE WHEN ISNULL(WQD.[QuoteMethod],0) > 0 THEN 0.00 ELSE ISNULL(SUM(WQD.[ChargesFlatBillingAmount]),0) END
	FROM [dbo].[WorkOrder] WO WITH(NOLOCK)
		 INNER JOIN [dbo].[WorkOrderQuote] WOQ WITH(NOLOCK) ON WO.[WorkOrderId] = WOQ.[WorkOrderId]  
		 INNER JOIN [dbo].[WorkOrderQuoteDetails] WQD WITH(NOLOCK) ON WOQ.[WorkOrderQuoteId] = WQD.[WorkOrderQuoteId]  
		 INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WQD.[WOPartNoId] = WOP.[ID]  		 
	WHERE WOQ.[WorkOrderQuoteId] = @WorkOrderQuoteId AND WOP.[ID] = @workOrderPartNoId AND WOQ.[IsActive] = 1 AND WOQ.[IsDeleted] = 0
	GROUP BY WQD.[QuoteMethod]
	-----------------------------------------------------------------------------------------
												
	SELECT @TotalRecord = COUNT(*), @MinId = MIN(ID) FROM #tmprWorkorderquoteDetails
	
	WHILE @MinId <= @TotalRecord
	BEGIN
		SELECT @OriginSiteId = [OriginSiteId],
	           @ShipToSiteId = [ShipToSiteId],
		       @CustomerId   = [CustomerId],
			   @WorkOrderPartNumId = [WorkOrderPartNumId]
		FROM #tmprWorkorderquoteDetails WHERE ID = @MinId
						
		EXEC [dbo].[USP_GetCustomerTax_Information_Repair] 
		     @CustomerId,
			 @ShipToSiteId,
			 @OriginSiteId,
		     @TotalSalesTax = @TotalSalesTax OUTPUT,
		     @TotalOtherTax = @TotalOtherTax OUTPUT	

		SELECT @Total = CASE WHEN ISNULL(WQD.[QuoteMethod],0) > 0 THEN ISNULL(WQD.[CommonFlatRate],0) 
			ELSE SUM(ISNULL(WQD.[MaterialFlatBillingAmount], 0) + ISNULL(WQD.[LaborFlatBillingAmount], 0) +  ISNULL(WQD.[ChargesFlatBillingAmount], 0) + ISNULL(WQD.[FreightFlatBillingAmount],0))
		 END 
		 FROM [dbo].[WorkOrder] WO WITH(NOLOCK)
			 INNER JOIN [dbo].[WorkOrderQuote] WOQ WITH(NOLOCK) ON WO.[WorkOrderId] = WOQ.[WorkOrderId] 
			 INNER JOIN [dbo].[WorkOrderQuoteDetails] WQD WITH(NOLOCK) ON WOQ.[WorkOrderQuoteId] = WQD.[WorkOrderQuoteId]  
			 INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WQD.[WOPartNoId] = WOP.[ID]  		 
	     WHERE WOQ.[WorkOrderQuoteId] = @WorkOrderQuoteId AND WOP.[ID] = @workOrderPartNoId AND WOQ.[IsActive] = 1 AND WOQ.[IsDeleted] = 0
	     GROUP BY WQD.[QuoteMethod],WQD.[CommonFlatRate]
	
	    SET @SubTotal += ISNULL(@Total,0);
	    SET @SalesTax = (ISNULL(@Total,0) * ISNULL(@TotalSalesTax,0) / 100);
	    SET @OtherTax = (ISNULL(@Total,0) * ISNULL(@TotalOtherTax,0) / 100);
									
		UPDATE #tmprWorkorderquoteDetails SET [SalesTax] = @SalesTax,[OtherTax] = @OtherTax WHERE [ID] = @MinId
		
		IF(@TotalSalesTax > 0 OR @TotalOtherTax > 0)
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM #tmprWorkorderquoteDetails2 WHERE [OriginSiteId] = @OriginSiteId AND [ShipToSiteId] = @ShipToSiteId AND [CustomerId] = @CustomerId)
			BEGIN
				INSERT INTO #tmprWorkorderquoteDetails2 ([OriginSiteId],[ShipToSiteId],[CustomerId],[WorkOrderQuoteId],[SalesTax],[OtherTax])
				     SELECT @OriginSiteId,@ShipToSiteId,@CustomerId,@WorkOrderQuoteId,ISNULL(@TotalSalesTax,0),ISNULL(@TotalOtherTax,0);
			END		
		END
			 			
		SET @MinId = @MinId + 1
	END
	
	SELECT @TotalRecord2 = COUNT(*), @MinId2 = MIN(ID) FROM #tmprWorkorderquoteDetails2    

	WHILE @MinId2 <= @TotalRecord2
	BEGIN
		DECLARE @STX DECIMAL(18,2)=0
		DECLARE @OTX DECIMAL(18,2)=0

		SELECT @STX = [SalesTax],
		       @OTX = [OtherTax]			  
		FROM #tmprWorkorderquoteDetails2 WHERE ID = @MinId2

		SET @TotalSalesTaxes += @STX
	    SET @TotalOtherTaxes += @OTX

		SET @MinId2 = @MinId2 + 1
	END

	SELECT @FinalSalesTaxes = SUM([SalesTax]), 
	       @FinalOtherTaxes = SUM([OtherTax]) 
	FROM #tmprWorkorderquoteDetails	
					
	SELECT  ISNULL(@TotalFreight,0) AS WOQTotalFreight,
	        ISNULL(@TotalCharges,0) AS WOQTotalCharges,	
	        ISNULL((@SubTotal),0) AS WOQSubTotal,
	        ISNULL((@SubTotal + @FinalSalesTaxes + @FinalOtherTaxes),0) AS WOQGrandTotal,
			ISNULL(@FinalSalesTaxes,0) AS WOQSalesTax,
			ISNULL(@FinalOtherTaxes,0) AS WOQOtherTax
	
  END TRY

  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[USP_GetCustomerTax_Information_Repair_WOQ]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderQuoteId, '') AS VARCHAR(100)),
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
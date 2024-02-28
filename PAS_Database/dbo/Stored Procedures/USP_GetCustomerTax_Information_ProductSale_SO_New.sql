/*************************************************************           
 ** File:   [USP_GetCustomerTax_Information_ProductSale_SO_New]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to get Customer Tax Information based on product sale
 ** Purpose:         
 ** Date:   02/23/2024        
          
 ** PARAMETERS: @SalesOrderId BIGINT,@SalesOrderPartId BIGINT,@CustomerId BIGINT,@MasterCompanyId INT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/26/2024   Moin Bloch    Created
     
-- EXEC [USP_GetCustomerTax_Information_ProductSale_SO_New] 20845,11,77
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCustomerTax_Information_ProductSale_SO_New] 
@SalesOrderId BIGINT,
@SalesOrderPartId BIGINT,
@CustomerId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
	  DECLARE @TotalRecord INT = 0; 
	  DECLARE @MinId BIGINT = 1; 
	  DECLARE @OriginSiteId BIGINT = 0;
	  DECLARE @ShipToSiteId BIGINT = 0;
	  DECLARE @TotalSalesTax Decimal(18,2) = 0;
	  DECLARE @TotalOtherTax Decimal(18,2) = 0;	 
	  DECLARE @SOModuleId BIGINT = 0;
	  SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

		IF OBJECT_ID(N'tempdb..#tmprsoShipDetails') IS NOT NULL
		BEGIN
			DROP TABLE #tmprsoShipDetails
		END
		
		CREATE TABLE #tmprsoShipDetails
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

		INSERT INTO #tmprsoShipDetails ([OriginSiteId],[ShipToSiteId],[CustomerId],[SalesOrderId],[SalesOrderPartId])	
		   SELECT SOS.[OriginSiteId],SOS.[ShipToSiteId],SOS.[CustomerId],SOS.[SalesOrderId],SOSI.[SalesOrderPartId]
	                         FROM [dbo].[SalesOrderShipping] SOS WITH(NOLOCK)  
							 INNER JOIN [dbo].[SalesOrderShippingItem] SOSI WITH(NOLOCK) ON SOS.[SalesOrderShippingId]  = SOSI.[SalesOrderShippingId]
	                        WHERE [SalesOrderId] = @SalesOrderId 
							AND  SOSI.[SalesOrderPartId] = @SalesOrderPartId
							AND SOS.[IsActive] = 1 
							AND SOS.[IsDeleted] = 0;

		INSERT INTO #tmprsoShipDetails ([OriginSiteId],[ShipToSiteId],[CustomerId],[SalesOrderId],[SalesOrderPartId])
			SELECT CASE WHEN STK.[SiteId] IS NOT NULL THEN STK.[SiteId] ELSE ITM.[SiteId] END,
			       CASE WHEN AAD.[SiteId] IS NOT NULL THEN AAD.[SiteId] ELSE CDS.CustomerDomensticShippingId END,
				   SO.[CustomerId],
				   SO.[SalesOrderId],
				   SOP.[SalesOrderPartId]
			  FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
	    INNER JOIN [dbo].[SalesOrderPart] SOP WITH(NOLOCK) ON SO.[SalesOrderId] = SOP.[SalesOrderId] 
		 LEFT JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON SOP.[StockLineId] = STK.[StockLineId]
		 LEFT JOIN [dbo].[AllAddress] AAD WITH(NOLOCK) ON SO.[SalesOrderId] = AAD.[ReffranceId] AND [IsShippingAdd] = 1 AND [ModuleId] = @SOModuleId
		 LEFT JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON SOP.[ItemMasterId] = ITM.[ItemMasterId]
		 LEFT JOIN [dbo].[CustomerDomensticShipping] CDS WITH(NOLOCK) ON CDS.[CustomerId] = SO.[CustomerId] AND CDS.[IsPrimary] = 1
	         WHERE SO.[SalesOrderId] = @SalesOrderId 
			  AND SOP.[SalesOrderPartId] NOT IN (SELECT [SalesOrderPartId] FROM #tmprsoShipDetails);
           											
		SELECT @TotalRecord = MAX(ID), @MinId = MIN(ID) FROM #tmprsoShipDetails    
	
		WHILE @MinId <= @TotalRecord
		BEGIN
			SELECT @OriginSiteId = [OriginSiteId],
				   @ShipToSiteId = [ShipToSiteId],
				   @CustomerId   = [CustomerId]				  
			  FROM #tmprsoShipDetails WHERE ID = @MinId		
					
			EXEC [dbo].[USP_GetCustomerTax_Information_Repair] 
					 @CustomerId,
					 @ShipToSiteId,
					 @OriginSiteId,
					 @TotalSalesTax = @TotalSalesTax OUTPUT,
					 @TotalOtherTax = @TotalOtherTax OUTPUT										
				
			SET @MinId = @MinId + 1
		END
				
		SELECT  ISNULL(@TotalSalesTax,0) AS SalesTax,ISNULL(@TotalOtherTax,0) AS OtherTax;
	 	
  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[USP_GetCustomerTax_Information_ProductSale_SO_New]',
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
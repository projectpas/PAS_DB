/*************************************************************           
 ** File:   [USP_GetCustomerTax_Information_ProductSale_SO_Analysis]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to get Customer Tax Information based on ProductSale
 ** Purpose:         
 ** Date:   07/02/2024        
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/02/2024   Moin Bloch    Created
     
-- EXEC [USP_GetCustomerTax_Information_ProductSale_SO_Analysis] 10810,11249,77 
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_GetCustomerTax_Information_ProductSale_SO_Analysis] 
@SalesOrderId BIGINT,
@SalesOrderPartId BIGINT,
@CustomerId BIGINT 
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
        DECLARE @OriginSiteId BIGINT = 0;
	    DECLARE @ShipToSiteId BIGINT = 0;
		DECLARE @TotalSalesTax Decimal(18,2) = 0;
		DECLARE @TotalOtherTax Decimal(18,2) = 0;
        DECLARE @SOModuleId BIGINT = 0;
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

		IF OBJECT_ID(N'tempdb..#tmprShipDetailsbs') IS NOT NULL
		BEGIN
			DROP TABLE #tmprShipDetailsbs
		END

		CREATE TABLE #tmprShipDetailsbs
		(
			[ID] BIGINT NOT NULL IDENTITY, 		
			[OriginSiteId] BIGINT NULL,
			[ShipToSiteId] BIGINT NULL			
		)
		INSERT INTO #tmprShipDetailsbs ([OriginSiteId],[ShipToSiteId])	
		 SELECT SOS.[OriginSiteId],
		        SOS.[ShipToSiteId]
	           FROM [dbo].[SalesOrderShipping] SOS WITH(NOLOCK)  
		 INNER JOIN [dbo].[SalesOrderShippingItem] SOSI WITH(NOLOCK) ON SOS.[SalesOrderShippingId]  = SOSI.[SalesOrderShippingId]
	          WHERE SOS.[SalesOrderId] = @SalesOrderId AND SOSI.[SalesOrderPartId] = @SalesOrderPartId;
			  			  
		INSERT INTO #tmprShipDetailsbs ([OriginSiteId],[ShipToSiteId])	
        SELECT ITM.[SiteId],
			   CASE WHEN AAD.[SiteId] IS NOT NULL THEN AAD.[SiteId] ELSE CDS.[CustomerDomensticShippingId] END 		   
			  FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
	    INNER JOIN [dbo].[SalesOrderPart] SOP WITH(NOLOCK) ON SO.[SalesOrderId] = SOP.[SalesOrderId] 
		 LEFT JOIN [dbo].[AllAddress] AAD WITH(NOLOCK) ON SO.[SalesOrderId] = AAD.[ReffranceId] AND [IsShippingAdd] = 1 AND [ModuleId] = @SOModuleId
		 LEFT JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON SOP.[ItemMasterId] = ITM.[ItemMasterId]
		 LEFT JOIN [dbo].[CustomerDomensticShipping] CDS WITH(NOLOCK) ON CDS.[CustomerId] = SO.[CustomerId] AND CDS.[IsPrimary] = 1
	         WHERE SO.[SalesOrderId] = @SalesOrderId  
			   AND SOP.[SalesOrderPartId] = @SalesOrderPartId
			   AND SOP.[SalesOrderPartId] NOT IN (SELECT SOSI.SalesOrderPartId FROM [dbo].[SalesOrderShipping] SOS WITH(NOLOCK)  
							 INNER JOIN [dbo].[SalesOrderShippingItem] SOSI WITH(NOLOCK) ON SOS.[SalesOrderShippingId]  = SOSI.[SalesOrderShippingId]
	                        WHERE [SalesOrderId] = @SalesOrderId AND SOSI.[SalesOrderPartId] = @SalesOrderPartId);

		SELECT @OriginSiteId = ISNULL([OriginSiteId],0),
		       @ShipToSiteId = ISNULL([ShipToSiteId],0)
		 FROM #tmprShipDetailsbs
		 
		 EXEC [dbo].[USP_GetCustomerTax_Information_ProductSale] 
		     @CustomerId,
			 @ShipToSiteId,
			 @OriginSiteId,
		     @TotalSalesTax = @TotalSalesTax OUTPUT,
		     @TotalOtherTax = @TotalOtherTax OUTPUT	

		SELECT ISNULL(@TotalSalesTax,0) AS SalesTax,
		       ISNULL(@TotalOtherTax,0) AS OtherTax,
			   ISNULL((@TotalSalesTax + @TotalOtherTax),0) AS TotalTax;		
		  
  END TRY

  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[USP_GetCustomerTax_Information_ProductSale_SO_Analysis]',
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
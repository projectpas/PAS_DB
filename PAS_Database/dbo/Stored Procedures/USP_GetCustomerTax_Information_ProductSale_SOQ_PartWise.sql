/*************************************************************           
 ** File:   [USP_GetCustomerTax_Information_ProductSale_SOQ_PartWise]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to get Customer Tax Information based on ProductSale
 ** Purpose:         
 ** Date:   08/02/2024        
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/02/2024   Moin Bloch    Created
	3    05/03/2024   Moin Bloch    Updated changed join ItemMaster To [Stockline]
     
-- EXEC [USP_GetCustomerTax_Information_ProductSale_SOQ_PartWise] 10425,10666,77 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCustomerTax_Information_ProductSale_SOQ_PartWise] 
@SalesOrderQuoteId BIGINT,
@SalesOrderQuotePartId BIGINT,
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
        DECLARE @SOQModuleId BIGINT = 0;
		 SELECT @SOQModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesQuote';

		IF OBJECT_ID(N'tempdb..#tmprShipDetailsbssoq') IS NOT NULL
		BEGIN
			DROP TABLE #tmprShipDetailsbssoq
		END

		CREATE TABLE #tmprShipDetailsbssoq
		(
			[ID] BIGINT NOT NULL IDENTITY, 		
			[OriginSiteId] BIGINT NULL,
			[ShipToSiteId] BIGINT NULL			
		)
		
		INSERT INTO #tmprShipDetailsbssoq ([OriginSiteId],[ShipToSiteId])
			SELECT CASE WHEN STK.[SiteId] IS NOT NULL THEN STK.[SiteId] ELSE ITM.[SiteId] END,
			       CASE WHEN AAD.[SiteId] IS NOT NULL THEN AAD.[SiteId] ELSE CDS.CustomerDomensticShippingId END				  
			FROM [dbo].[SalesOrderQuote] SOQ WITH(NOLOCK) 
			INNER JOIN [dbo].[SalesOrderQuotePart] SOQP WITH(NOLOCK) ON SOQ.[SalesOrderQuoteId] = SOQP.[SalesOrderQuoteId] 
			 LEFT JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON SOQP.[StockLineId] = STK.[StockLineId]
			 LEFT JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON SOQP.[ItemMasterId] = ITM.[ItemMasterId]
			 LEFT JOIN [dbo].[AllAddress] AAD WITH(NOLOCK) ON SOQP.[SalesOrderQuoteId] = AAD.[ReffranceId] AND [IsShippingAdd] = 1 AND [ModuleId] = @SOQModuleId
			 LEFT JOIN [dbo].[CustomerDomensticShipping] CDS WITH(NOLOCK) ON CDS.[CustomerId] = SOQ.[CustomerId] AND CDS.[IsPrimary] = 1
   		     WHERE SOQ.[SalesOrderQuoteId] = @SalesOrderQuoteId 
			   AND SOQP.[SalesOrderQuotePartId] = @SalesOrderQuotePartId

		SELECT @OriginSiteId = ISNULL([OriginSiteId],0),
		       @ShipToSiteId = ISNULL([ShipToSiteId],0)
		 FROM #tmprShipDetailsbssoq
		 
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
            @AdhocComments varchar(150) = '[USP_GetCustomerTax_Information_ProductSale_SOQ_PartWise]',
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
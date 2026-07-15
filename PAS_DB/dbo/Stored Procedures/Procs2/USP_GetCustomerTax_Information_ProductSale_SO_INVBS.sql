-- ===== PROCEDURE: [dbo].[USP_GetCustomerTax_Information_ProductSale_SO_INVBS]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs2/USP_GetCustomerTax_Information_ProductSale_SO_INVBS.sql) =====
/*************************************************************           
 ** File:   [USP_GetCustomerTax_Information_ProductSale_SO_INVBS]           
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
    2    11/05/2024	  Vishal Suthar	Modified to make use of new SO Part tables
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	4    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0

-- EXEC [USP_GetCustomerTax_Information_ProductSale_SO_INVBS] 10803,11245 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCustomerTax_Information_ProductSale_SO_INVBS] 
@SalesOrderId BIGINT,
@SalesOrderPartId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
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
        SELECT CASE WHEN STK.[SiteId] IS NOT NULL THEN STK.[SiteId] ELSE ITM.[SiteId] END,
			   CASE WHEN AAD.[SiteId] IS NOT NULL THEN AAD.[SiteId] ELSE CDS.[CustomerDomensticShippingId] END 		   
			  FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
	    INNER JOIN [dbo].[SalesOrderPartV1] SOP WITH(NOLOCK) ON SO.[SalesOrderId] = SOP.[SalesOrderId] 
	    LEFT JOIN [dbo].[SalesOrderStocklineV1] SOPS WITH(NOLOCK) ON SOPS.[SalesOrderPartId] = SOP.[SalesOrderPartId] 
		 LEFT JOIN [dbo].[AllAddress] AAD WITH(NOLOCK) ON SO.[SalesOrderId] = AAD.[ReffranceId] AND [IsShippingAdd] = 1 AND [ModuleId] = @SOModuleId
		 LEFT JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON SOPS.[StockLineId] = STK.[StockLineId] AND ISNULL(STK.IsNonStock,0) = 0
		 LEFT JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON SOP.[ItemMasterId] = ITM.[ItemMasterId]
		  AND ISNULL(ITM.IsNonStock,0) = 0
		  LEFT JOIN [dbo].[CustomerDomensticShipping] CDS WITH(NOLOCK) ON CDS.[CustomerId] = SO.[CustomerId] AND CDS.[IsPrimary] = 1
	         WHERE SO.[SalesOrderId] = @SalesOrderId  
			   AND SOP.[SalesOrderPartId] = @SalesOrderPartId
			   AND SOP.[SalesOrderPartId] NOT IN (SELECT SOSI.SalesOrderPartId FROM [dbo].[SalesOrderShipping] SOS WITH(NOLOCK)  
							 INNER JOIN [dbo].[SalesOrderShippingItem] SOSI WITH(NOLOCK) ON SOS.[SalesOrderShippingId]  = SOSI.[SalesOrderShippingId]
	                        WHERE [SalesOrderId] = @SalesOrderId AND SOSI.[SalesOrderPartId] = @SalesOrderPartId);

		SELECT ISNULL([OriginSiteId],0) AS [OriginSiteId],ISNULL([ShipToSiteId],0) AS [ShipToSiteId]  FROM #tmprShipDetailsbs
		  
  END TRY

  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[USP_GetCustomerTax_Information_ProductSale_SO_INVBS]',
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
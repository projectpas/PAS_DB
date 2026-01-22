/*************************************************************           
 ** File:   [USP_GetCustomerTax_Information_ProductSale_WO_INVBS_Parts]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to get Customer Tax Information based on Repair
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
     
-- EXEC [USP_GetCustomerTax_Information_ProductSale_WO_INVBS_Parts] 10803,11245 
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetCustomerTax_Information_ProductSale_WO_INVBS_Parts] 
@WorkOrderId BIGINT,
@WorkOrderPartId BIGINT,
@BillingOriginSiteId BIGINT OUTPUT,
@BillingShipToSiteId BIGINT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
      
		IF OBJECT_ID(N'tempdb..#tmprwoShipDetailsbs') IS NOT NULL
		BEGIN
			DROP TABLE #tmprwoShipDetailsbs
		END

		CREATE TABLE #tmprwoShipDetailsbs
		(
			[ID] BIGINT NOT NULL IDENTITY, 		
			[OriginSiteId] BIGINT NULL,
			[ShipToSiteId] BIGINT NULL			
		)
		INSERT INTO #tmprwoShipDetailsbs ([OriginSiteId],[ShipToSiteId])	
		 SELECT WOS.[OriginSiteId],
		        WOS.[ShipToSiteId]
	           FROM [dbo].[WorkOrderShipping] WOS WITH(NOLOCK)  
		 INNER JOIN [dbo].[WorkOrderShippingItem] WOSI WITH(NOLOCK) ON WOS.[WorkOrderShippingId]  = WOSI.[WorkOrderShippingId]
	          WHERE WOS.[WorkOrderId] = @WorkOrderId AND WOSI.[WorkOrderPartNumId] = @WorkOrderPartId;
			  			  
		INSERT INTO #tmprwoShipDetailsbs ([OriginSiteId],[ShipToSiteId])	
        SELECT ITM.[SiteId],
			   CDS.[CustomerDomensticShippingId] 		   
			  FROM [dbo].[WorkOrder] WO WITH(NOLOCK) 
	    INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WO.[WorkOrderId] = WOP.[WorkOrderId] 
		INNER JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON WOP.[ItemMasterId] = ITM.[ItemMasterId]
		INNER JOIN [dbo].[CustomerDomensticShipping] CDS WITH(NOLOCK) ON CDS.[CustomerId] = WO.[CustomerId] AND CDS.[IsPrimary] = 1
	         WHERE WO.[WorkOrderId] = @WorkOrderId  
			   AND WOP.[ID] = @WorkOrderPartId
			   AND WOP.[ID] NOT IN (SELECT WOSI.WorkOrderPartNumId FROM [dbo].[WorkOrderShipping] WOS WITH(NOLOCK)  
							 INNER JOIN [dbo].[WorkOrderShippingItem] WOSI WITH(NOLOCK) ON WOS.[WorkOrderShippingId]  = WOSI.[WorkOrderShippingId]
	                        WHERE [WorkOrderId] = @WorkOrderId AND WOSI.[WorkOrderPartNumId] = @WorkOrderPartId);

		SELECT @BillingOriginSiteId = ISNULL([OriginSiteId],0),@BillingShipToSiteId = ISNULL([ShipToSiteId],0) FROM #tmprwoShipDetailsbs
				  
  END TRY

  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[USP_GetCustomerTax_Information_ProductSale_WO_INVBS]',
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
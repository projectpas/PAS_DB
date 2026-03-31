/*************************************************************             
 ** File:   [GetSalesOrderPickTicketBySalesOrderId]            
 ** Author:  EKTA CHANDEGRA
 ** Description: This stored procedure is used GetSalesOrderPickTicketBySalesOrderId
 ** Purpose:           
 ** Date:  06/12/2024        
            
 ** PARAMETERS: @SalesOrderId bigint  , @SOPickTicketId bigint
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    06/12/2024		EKTA CHANDEGRA	 Created  
	2    31/03/2026		Moin Bloch	     UOM Changes PN-15067

 EXEC GetSalesOrderPickTicketBySalesOrderId 1 , 1
************************************************************************/   
CREATE   PROCEDURE [dbo].[GetSalesOrderPickTicketBySalesOrderId] 
    @SalesOrderId BIGINT,
    @SOPickTicketId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	SET NOCOUNT ON;   
	BEGIN TRY
	BEGIN
		DECLARE @SalesOrderModuleId BIGINT = 10;
		DECLARE @SalesOrderPartId BIGINT = 0,@ItemMasterId BIGINT = 0
		DECLARE @PurchaseUnitOfMeasureId BIGINT = 0,  @StockUnitOfMeasureId BIGINT = 0,@ConsumeUnitOfMeasureId BIGINT = 0
        DECLARE @POUnitOfMeasure VARCHAR(100), @StockUnitOfMeasure VARCHAR(100),@ConsumeUnitOfMeasure VARCHAR(100)
				
		SELECT TOP 1 @SalesOrderPartId = [SalesOrderPartId] FROM [dbo].[SOPickTicket] WITH(NOLOCK) WHERE [SalesOrderId] = @SalesOrderId AND [SOPickTicketId] = @SOPickTicketId	
		SELECT @ItemMasterId = [ItemMasterId] FROM [dbo].[SalesOrderPartV1] WITH(NOLOCK) WHERE [SalesOrderId] = @SalesOrderId AND [SalesOrderPartId] = @SalesOrderPartId		

		SELECT @PurchaseUnitOfMeasureId = [PurchaseUnitOfMeasureId],@StockUnitOfMeasureId =[StockUnitOfMeasureId], @ConsumeUnitOfMeasureId = [ConsumeUnitOfMeasureId] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @ItemMasterId;
 		SET @POUnitOfMeasure = (SELECT [ShortCode] FROM [dbo].[UnitOfMeasure] WITH(NOLOCK) WHERE [UnitOfMeasureId] = @PurchaseUnitOfMeasureId)
		SET @StockUnitOfMeasure = (SELECT [ShortCode] FROM [dbo].[UnitOfMeasure] WITH(NOLOCK) WHERE [UnitOfMeasureId] = @StockUnitOfMeasureId)
		SET @ConsumeUnitOfMeasure = (SELECT [ShortCode] FROM [dbo].[UnitOfMeasure] WITH(NOLOCK) WHERE [UnitOfMeasureId] = @ConsumeUnitOfMeasureId)
		
		SELECT TOP 1
        sopkt.SOPickTicketId,
        sopkt.SOPickTicketNumber,
        sopkt.SOPickTicketNumber AS SOPickTicketBarcode, 
        soq.SalesOrderId,
        soq.SalesOrderQuoteId,
        soq.SalesOrderNumber,
        soq.ShippedDate,
        soq.NumberOfItems,
        soq.CustomerId,
        ISNULL(cust.Name, '') AS CustomerName,
        ISNULL(cust.CustomerCode, '') AS CustomerCode,
        ISNULL(cuad.Line1, '') AS CustToAddress1,
        ISNULL(cuad.Line2, '') AS CustToAddress2,
        ISNULL(cuad.City, '') AS CustToCity,
        ISNULL(cuad.StateOrProvince, '') AS CustToState,
        ISNULL(cuad.PostalCode, '') AS CustToPostalCode,
        ISNULL(ccnty.countries_name, '') AS CustToCountry,
        CONCAT(ISNULL(cont.FirstName, ''), ' ', ISNULL(cont.LastName, '')) AS CustomerContactName,
        posadd.SiteName AS ShipToSiteName,
        posadd.Line1 AS ShipToAddress1,
        posadd.Line2 AS ShipToAddress2,
        posadd.City AS ShipToCity,
        posadd.StateOrProvince AS ShipToState,
        posadd.PostalCode AS ShipToPostalCode,
        posadd.Country AS ShipToCountry,
        posadd.ContactName AS ShipToContactName,
        posv.ShipVia AS ShipViaName,
        soq.CreatedBy,
        soq.CreatedDate,
        soq.UpdatedBy,
        soq.UpdatedDate,
        soq.ManagementStructureId,
        --soq.QtyRequested,
		ISNULL([dbo].[fn_ConvertUOM](ISNULL(soq.[QtyRequested],0),@StockUnitOfMeasure, @ConsumeUnitOfMeasure,0,soq.[MasterCompanyId]),0) AS [QtyRequested],
		--soq.QtyToBeQuoted,
		ISNULL([dbo].[fn_ConvertUOM](ISNULL(soq.[QtyToBeQuoted],0),@StockUnitOfMeasure, @ConsumeUnitOfMeasure,0,soq.[MasterCompanyId]),0) AS [QtyToBeQuoted],
        ISNULL(emp.FirstName, '') + ' ' + ISNULL(emp.LastName, '') AS PickedByName,
        sopkt.CreatedDate AS PickedDate,
        ISNULL(empy.FirstName, '') + ' ' + ISNULL(empy.LastName, '') AS ConfirmedByName,
        sopkt.ConfirmedDate,
        sopkt.CreatedDate AS PTCreatedDate,
        soq.CustomerReference
		FROM [dbo].[SalesOrder] soq WITH(NOLOCK)
			LEFT JOIN [dbo].[SOPickTicket] sopkt WITH(NOLOCK) ON soq.SalesOrderId = sopkt.SalesOrderId AND sopkt.SOPickTicketId = @SOPickTicketId
			LEFT JOIN [dbo].[Customer] cust WITH(NOLOCK) ON soq.CustomerId = cust.CustomerId
			LEFT JOIN [dbo].[Address] cuad WITH(NOLOCK) ON cust.AddressId = cuad.AddressId
			LEFT JOIN [dbo].[Countries] ccnty WITH(NOLOCK) ON cuad.CountryId = ccnty.countries_id
			LEFT JOIN [dbo].[CustomerContact] cust_cont WITH(NOLOCK) ON soq.CustomerContactId = cust_cont.CustomerContactId
			LEFT JOIN [dbo].[Contact] cont WITH(NOLOCK) ON cust_cont.ContactId = cont.ContactId
			LEFT JOIN [dbo].[AllAddress] posadd WITH(NOLOCK) ON soq.SalesOrderId = posadd.ReffranceId AND posadd.IsShippingAdd = 1 AND posadd.ModuleId = @SalesOrderModuleId  
			LEFT JOIN [dbo].[AllShipVia] posv WITH(NOLOCK) ON soq.SalesOrderId = posv.ReferenceId AND posv.ModuleId = @SalesOrderModuleId
			LEFT JOIN [dbo].[Employee] emp WITH(NOLOCK) ON sopkt.PickedById = emp.EmployeeId
			LEFT JOIN [dbo].[Employee] empy WITH(NOLOCK) ON sopkt.ConfirmedById = empy.EmployeeId
		WHERE sopkt.SalesOrderId = @SalesOrderId
			ORDER BY sopkt.SOPickTicketId
		END
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetSalesOrderPickTicketBySalesOrderId'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''',
													 @Parameter2 = ' + ISNULL(@SOPickTicketId, '') +''
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
            RETURN(1); 
	END CATCH
END
/*************************************************************             
 ** File:   [GetRepairOrderPickTicketByRepairOrderId]            
 ** Author:  Vishal Suthar
 ** Description: This stored procedure is used GetRepairOrderPickTicketByRepairOrderId
 ** Purpose:           
 ** Date:  04/15/2025        
            
 ** PARAMETERS: @SalesOrderId bigint  , @SOPickTicketId bigint
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    04/15/2025		Vishal Suthar	Created  

 EXEC GetRepairOrderPickTicketByRepairOrderId 2547, 1
************************************************************************/   
CREATE   PROCEDURE [dbo].[GetRepairOrderPickTicketByRepairOrderId]
    @RepairOrderId BIGINT,
    @ROPickTicketId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	SET NOCOUNT ON;   
	BEGIN TRY
		DECLARE @RepairOrderModuleId BIGINT = 10;

		BEGIN
		SELECT TOP 1
			ropkt.ROPickTicketId,
			ropkt.ROPickTicketNumber,
			ropkt.ROPickTicketNumber AS ROPickTicketBarcode, 
			roq.RepairOrderId,
			roq.RepairOrderNumber,
			--roq.ShippedDate,
			--roq.NumberOfItems,
			roq.VendorId,
			ISNULL(vend.VendorName, '') AS VendorName,
			ISNULL(vend.VendorCode, '') AS VendorCode,
			ISNULL(cuad.Line1, '') AS VendToAddress1,
			ISNULL(cuad.Line2, '') AS VendToAddress2,
			ISNULL(cuad.City, '') AS VendToCity,
			ISNULL(cuad.StateOrProvince, '') AS VendToState,
			ISNULL(cuad.PostalCode, '') AS VendToPostalCode,
			ISNULL(ccnty.countries_name, '') AS VendToCountry,
			CONCAT(ISNULL(cont.FirstName, ''), ' ', ISNULL(cont.LastName, '')) AS VendorContactName,
			posadd.SiteName AS ShipToSiteName,
			posadd.Line1 AS ShipToAddress1,
			posadd.Line2 AS ShipToAddress2,
			posadd.City AS ShipToCity,
			posadd.StateOrProvince AS ShipToState,
			posadd.PostalCode AS ShipToPostalCode,
			posadd.Country AS ShipToCountry,
			posadd.ContactName AS ShipToContactName,
			posv.ShipVia AS ShipViaName,
			roq.CreatedBy,
			roq.CreatedDate,
			roq.UpdatedBy,
			roq.UpdatedDate,
			roq.ManagementStructureId,
			ISNULL(emp.FirstName, '') + ' ' + ISNULL(emp.LastName, '') AS PickedByName,
			ropkt.CreatedDate AS PickedDate,
			ISNULL(empy.FirstName, '') + ' ' + ISNULL(empy.LastName, '') AS ConfirmedByName,
			ropkt.ConfirmedDate,
			ropkt.CreatedDate AS PTCreatedDate
		FROM [dbo].[RepairOrder] roq WITH(NOLOCK)
		LEFT JOIN [dbo].[ROPickTicket] ropkt WITH(NOLOCK) ON roq.RepairOrderId = ropkt.RepairOrderId AND ropkt.ROPickTicketId = @ROPickTicketId
		LEFT JOIN [dbo].[Vendor] vend WITH(NOLOCK) ON roq.VendorId = vend.VendorId
		LEFT JOIN [dbo].[Address] cuad WITH(NOLOCK) ON vend.AddressId = cuad.AddressId
		LEFT JOIN [dbo].[Countries] ccnty WITH(NOLOCK) ON cuad.CountryId = ccnty.countries_id
		LEFT JOIN [dbo].[VendorContact] vend_cont WITH(NOLOCK) ON roq.VendorContactId = vend_cont.VendorContactId
		LEFT JOIN [dbo].[Contact] cont WITH(NOLOCK) ON vend_cont.ContactId = cont.ContactId
		LEFT JOIN [dbo].[AllAddress] posadd WITH(NOLOCK) ON roq.RepairOrderId = posadd.ReffranceId AND posadd.IsShippingAdd = 1 AND posadd.ModuleId = @RepairOrderModuleId  
		LEFT JOIN [dbo].[AllShipVia] posv WITH(NOLOCK) ON roq.RepairOrderId = posv.ReferenceId AND posv.ModuleId = @RepairOrderModuleId
		LEFT JOIN [dbo].[Employee] emp WITH(NOLOCK) ON ropkt.PickedById = emp.EmployeeId
		LEFT JOIN [dbo].[Employee] empy WITH(NOLOCK) ON ropkt.ConfirmedById = empy.EmployeeId
		WHERE ropkt.RepairOrderId = @RepairOrderId
		ORDER BY ropkt.ROPickTicketId
		END
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetRepairOrderPickTicketByRepairOrderId'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RepairOrderId, '') + ''',
													 @Parameter2 = ' + ISNULL(@ROPickTicketId, '') +''
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
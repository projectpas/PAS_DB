-- ===== PROCEDURE: [dbo].[USP_GetVendorRMAPickTicketBySalesOrderId]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs2/USP_GetVendorRMAPickTicketBySalesOrderId.sql) =====
/*************************************************************           
 ** File:   [USP_GetVendorRMAPickTicketBySalesOrderId]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get GetVendorRMAPickTicketBySalesOrderId Pdf
 ** Purpose:         
 ** Date:   04-06-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    04-06-2025    Sahdev Saliya       Created  
    2    09/July/2026    RAJESH GAMI       [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetVendorRMAPickTicketBySalesOrderId]
    @VendorRMAId BIGINT,
    @RMAPickTicketId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
		 BEGIN TRY

		 DECLARE @ModuleId BIGINT = (SELECT ModuleId FROM [dbo].Module WITH(NOLOCK) WHERE ModuleName = 'SalesOrder')

			SELECT
				sopkt.RMAPickTicketId,
				sopkt.RMAPickTicketNumber,
				'' AS RMAPickTicketBarcode,
				soq.VendorRMAId,
				soq.RMANumber AS RMANum,
				soq.VendorId AS CustomerId,
				ISNULL(cust.VendorName, '') AS VendorName,
				ISNULL(cust.VendorCode, '') AS VendorCode,
				ISNULL(cuad.Line1, '') AS VendorToAddress1,
				ISNULL(cuad.Line2, '') AS VendorToAddress2,
				ISNULL(cuad.City, '') AS VendorToCity,
				ISNULL(cuad.StateOrProvince, '') AS VendorToState,
				ISNULL(cuad.PostalCode, '') AS VendorToPostalCode,
				ISNULL(ccnty.countries_name, '') AS VendorToCountry,
				ISNULL(cust.VendorName, '') AS VendorContactName,
				posadd.SiteName AS ShipToSiteName,
				posadd.Line1 AS ShipToAddress1,
				posadd.Line2 AS ShipToAddress2,
				posadd.City AS ShipToCity,
				posadd.StateOrProvince AS ShipToState,
				posadd.PostalCode AS ShipToPostalCode,
				posadd.Country AS ShipToCountry,
				posadd.ContactName AS ShipToContactName,
				posvname.Name AS ShipViaName,
				soq.CreatedBy,
				soq.CreatedDate,
				soq.UpdatedBy,
				soq.UpdatedDate,
				sl.ManagementStructureId,
				vrma.Qty AS QtyRequested,
				ISNULL(emp.FirstName + ' ' + emp.LastName, '') AS PickedByName,
				sopkt.CreatedDate AS PickedDate,
				ISNULL(empy.FirstName + ' ' + empy.LastName, '') AS ConfirmedByName,
				sopkt.ConfirmedDate,
				sopkt.CreatedDate AS PTCreatedDate
			FROM [dbo].VendorRMA soq WITH(NOLOCK)
			LEFT JOIN [dbo].VendorRMADetail vrma WITH(NOLOCK) ON soq.VendorRMAId = vrma.VendorRMAId
			LEFT JOIN [dbo].StockLine sl WITH(NOLOCK) ON vrma.StockLineId = sl.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
			LEFT JOIN [dbo].RMAPickTicket sopkt WITH(NOLOCK) ON soq.VendorRMAId = sopkt.VendorRMAId AND sopkt.RMAPickTicketId = @RMAPickTicketId
			LEFT JOIN [dbo].Vendor cust WITH(NOLOCK) ON soq.VendorId = cust.VendorId
			LEFT JOIN [dbo].Address cuad WITH(NOLOCK) ON cust.AddressId = cuad.AddressId
			LEFT JOIN [dbo].Countries ccnty WITH(NOLOCK) ON cuad.CountryId = ccnty.countries_id
			LEFT JOIN [dbo].AllAddress posadd WITH(NOLOCK) ON soq.VendorRMAId = posadd.ReffranceId AND ISNULL(posadd.IsShippingAdd,0) = 1 AND posadd.ModuleId = @ModuleId
			LEFT JOIN [dbo].RMAShipping posv WITH(NOLOCK) ON soq.VendorRMAId = posv.VendorRMAId
			LEFT JOIN [dbo].ShippingVia posvname WITH(NOLOCK) ON posv.ShipviaId = posvname.ShippingViaId
			LEFT JOIN [dbo].Employee emp WITH(NOLOCK) ON sopkt.PickedById = emp.EmployeeId
			LEFT JOIN [dbo].Employee empy WITH(NOLOCK) ON sopkt.ConfirmedById = empy.EmployeeId
			WHERE sopkt.VendorRMAId = @VendorRMAId;
	 END TRY    
   BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorRMAPickTicketBySalesOrderId' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRMAId, '') + ''',
				    @Parameter2 = ' + ISNULL(@RMAPickTicketId ,'') 

				  , @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

				  exec spLogException 
						   @DatabaseName			= @DatabaseName
						 , @AdhocComments			= @AdhocComments
						 , @ProcedureParameters		= @ProcedureParameters
						 , @ApplicationName			= @ApplicationName
						 , @ErrorLogID              = @ErrorLogID OUTPUT ;
				  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
				  RETURN
	END CATCH
END
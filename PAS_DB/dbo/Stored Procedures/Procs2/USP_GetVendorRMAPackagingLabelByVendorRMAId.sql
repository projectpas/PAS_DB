-- ===== PROCEDURE: [dbo].[USP_GetVendorRMAPackagingLabelByVendorRMAId]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs2/USP_GetVendorRMAPackagingLabelByVendorRMAId.sql) =====
/*************************************************************           
 ** File:   [USP_GetVendorRMAPackagingLabelByVendorRMAId]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get VendorRMAPackagingLabel By VendorRMAId pdf
 ** Purpose:         
 ** Date:   10-06-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    10-06-2025    Sahdev Saliya       Created  
    2    09/July/2026    RAJESH GAMI       [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	3    23/July/2026    RAJESH GAMI      [PN-17350] - Removed 1 leftover IsNonStock=0 exclusion filter.
	4    27-07-2026      Bhargav Saliya    Get Ship ShipViaName [PN-17341]
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetVendorRMAPackagingLabelByVendorRMAId]
    @VendorRMAId BIGINT,
    @RMAPickTicketId BIGINT,
    @VendorRMADetailId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
			 BEGIN TRY

			  DECLARE @ModuleId BIGINT = (SELECT ModuleId FROM [dbo].Module WITH(NOLOCK) WHERE ModuleName = 'VendorRMA')

				SELECT 
					sopkt.RMAPickTicketId AS SOPickTicketId,
					ISNULL(spb.PackagingSlipNo, '') AS PackagingSlipNo,
                    ISNULL(spb.PackagingSlipNo, '') AS PackagingLabelBarcode, 
					soq.VendorRMAId AS SalesOrderId,
					soq.RMANumber AS SalesOrderNumber,
					ISNULL(po.PurchaseOrderNumber, '') + CASE WHEN ro.RepairOrderNumber IS NOT NULL THEN '/' + ro.RepairOrderNumber ELSE '' END AS PORONum,
					soq.VendorId AS CustomerId,
					ISNULL(cust.VendorName, '') AS CustomerName,
					ISNULL(cust.VendorCode, '') AS CustomerCode,
					ISNULL(cuad.Line1, '') AS CustToAddress1,
					ISNULL(cuad.Line2, '') AS CustToAddress2,
					ISNULL(cuad.City, '') AS CustToCity,
					ISNULL(cuad.StateOrProvince, '') AS CustToState,
					ISNULL(cuad.PostalCode, '') AS CustToPostalCode,
					ISNULL(ccnty.countries_name, '') AS CustToCountry,
					posadd.SiteName AS ShipToSiteName,
					posadd.Line1 AS ShipToAddress1,
					posadd.Line2 AS ShipToAddress2,
					posadd.City AS ShipToCity,
					posadd.StateOrProvince AS ShipToState,
					posadd.PostalCode AS ShipToPostalCode,
					posadd.Country AS ShipToCountry,
					posadd.ContactName AS ShipToContactName,
					soq.CreatedBy,
					soq.CreatedDate,
					soq.UpdatedBy,
					soq.UpdatedDate,
					qs.ManagementStructureId,
					ISNULL(sv.Name, '')        AS ShipViaName,
					rsh.ShipDate                    AS ShipDate,
					ISNULL(rsh.AirwayBill, '')      AS AWB,
					ISNULL(rsh.RMAShippingNum, '')  AS ShippingOrderNo,
					rsh.NoOfContainer               AS NoOfContainer,
					ISNULL(soq.Notes, '')           AS Notes,
					soq.OpenDate                    AS OpenDate
				FROM [dbo].RMAPickTicket sopkt WITH(NOLOCK)
				INNER JOIN [dbo].VendorRMA soq WITH(NOLOCK) ON sopkt.VendorRMAId = soq.VendorRMAId
				INNER JOIN [dbo].VendorRMADetail part WITH(NOLOCK) ON soq.VendorRMAId = part.VendorRMAId
				LEFT JOIN [dbo].Vendor cust WITH(NOLOCK) ON soq.VendorId = cust.VendorId
				LEFT JOIN [dbo].Address cuad WITH(NOLOCK) ON cust.AddressId = cuad.AddressId
				LEFT JOIN [dbo].Countries ccnty WITH(NOLOCK) ON cuad.CountryId = ccnty.countries_id
				LEFT JOIN [dbo].AllAddress posadd WITH(NOLOCK) ON posadd.ReffranceId = soq.VendorRMAId AND ISNULL(posadd.IsShippingAdd, 0) = 1 AND posadd.ModuleId = @ModuleId  
				LEFT JOIN [dbo].AllShipVia posv WITH(NOLOCK) ON posv.ReferenceId = soq.VendorRMAId AND posv.ModuleId = @ModuleId
				LEFT JOIN [dbo].VendorRMAPackaginSlipItems spi WITH(NOLOCK) ON sopkt.RMAPickTicketId = spi.RMAPickTicketId
				LEFT JOIN [dbo].VendorRMAPackaginSlipHeader spb WITH(NOLOCK) ON spi.PackagingSlipId = spb.PackagingSlipId
				LEFT JOIN [dbo].StockLine qs WITH(NOLOCK) ON part.StockLineId = qs.StockLineId
				LEFT JOIN [dbo].PurchaseOrder po WITH(NOLOCK) ON qs.PurchaseOrderId = po.PurchaseOrderId
				LEFT JOIN [dbo].RepairOrder ro WITH(NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId
				LEFT JOIN [dbo].RMAShipping rsh WITH(NOLOCK) ON spb.RMAShippingId = rsh.RMAShippingId
				LEFT JOIN [dbo].ShippingVia sv WITH(NOLOCK) ON rsh.ShipviaId = sv.ShippingViaId
				WHERE sopkt.VendorRMAId = @VendorRMAId
				  AND sopkt.VendorRMADetailId = @VendorRMADetailId;
			END TRY    

   BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorRMAPackagingLabelByVendorRMAId' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRMAId, '') + ''',
				    @Parameter2 = ' + ISNULL(@RMAPickTicketId ,'') + ''',
					@Parameter3 = ' + ISNULL(@VendorRMADetailId ,'')

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
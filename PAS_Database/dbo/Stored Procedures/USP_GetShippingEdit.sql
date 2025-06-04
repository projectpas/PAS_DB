/*************************************************************           
 ** File:   [USP_GetShippingEdit]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get ShippingEdit List
 ** Purpose:         
 ** Date:   04-06-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    04-06-2025    Sahdev Saliya       Created  

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetShippingEdit]
    @salesOrderShippingId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
	     BEGIN TRY

				SELECT
					shcu.VendorName AS ShipToCustomer,
					sos.ShipToVendorId AS ShipToCustomerId,
					sos.SoldToSiteId,
					sos.SoldToSiteName,
					sos.Notes,
					org.countries_name AS OrginCountry,
					sv.Name AS ShipVia,
					ss.Status AS ShippingStatus,
					sos.AirwayBill,
					'' AS CertNum,
					sos.CreatedBy,
					sos.CreatedDate,
					cus.VendorCode,
					sos.VendorId,
					cus.VendorName AS CustomerName,
					sos.HouseAirwayBill,
					sos.IsActive,
					sos.IsDeleted,
					sos.MasterCompanyId,
					sos.OpenDate,
					sos.OriginAddress1,
					sos.OriginAddress2,
					sos.OriginCity,
					sos.OriginCountryId,
					sos.OriginName,
					sos.OriginState,
					sos.OriginZip,
					sos.ShipDate,
					sos.ShipToAddress1,
					sos.ShipToAddress2,
					sos.ShipToCity,
					sos.ShipToCountryId,
					sos.ShipToName,
					sos.ShipToSiteId,
					sos.ShipToSiteName,
					sos.ShipToState,
					sos.ShipToZip,
					CASE WHEN sos.IsVendorShipping = 1 THEN sos.VendorDomensticShippingShipViaId ELSE sos.ShipviaId END AS ShipviaId,
					sos.SoldToAddress1,
					sos.SoldToAddress2,
					sos.SoldToCity,
					sos.SoldToCountryId,
					sos.SoldToName,
					sos.SoldToState,
					sos.SoldToZip,
					sos.TrackingNum,
					sos.UpdatedBy,
					sos.UpdatedDate,
					sos.Weight,
					sos.VendorRMAId,
					so.RMANumber,
					sos.RMAShippingId,
					sos.RMAShippingNum,
					sos.RMAShippingStatusId,
					sos.Shipment,
					sos.OriginCountryName,
					sos.OriginSiteId,
					sos.IsSameForShipTo,
					wci.VendorRMACustomsInfoId, 
					wci.RMAShippingId,
					wci.EntryType, 
					wci.EPU,
					wci.CustomsValue, 
					wci.NetMass, 
					wci.EntryStatus, 
					wci.EntryNumber, 
					wci.VATValue,
					wci.UCR, 
					wci.MasterUCR,
					wci.MovementRefNo,
					wci.CommodityCode, 
					wci.CustomCurrencyId, 
					sos.ShipWeightUnit,
					sos.ShipSizeUnitOfMeasureId,
					sos.ShipSizeLength,
					sos.ShipSizeWidth,
					sos.ShipSizeHeight,
					shc.countries_name AS ShipToCountryName,
					stc.countries_name AS SoldToCountryName,
					sos.NoOfContainer,
					sos.NoOfItems,
					sos.ShippingAccountNo,
					sos.IsVendorShipping,
					sos.IsManualShipping,
					sos.ManufactureCountryId,
					sos.QtyUOM,
					sos.UnitPriceCurrencyId,
					sos.UnitPrice
				FROM [dbo].RMAShipping sos WITH(NOLOCK)
				INNER JOIN [dbo].VendorRMA so WITH(NOLOCK) ON sos.VendorRMAId = so.VendorRMAId
				LEFT JOIN [dbo].Vendor cus WITH(NOLOCK) ON so.VendorId = cus.VendorId
				INNER JOIN [dbo].Countries stc WITH(NOLOCK) ON sos.SoldToCountryId = stc.countries_id
				INNER JOIN [dbo].Countries shc WITH(NOLOCK) ON sos.ShipToCountryId = shc.countries_id
				INNER JOIN [dbo].Countries org WITH(NOLOCK) ON sos.OriginCountryId = org.countries_id
				INNER JOIN [dbo].ShippingStatus ss WITH(NOLOCK) ON sos.RMAShippingStatusId = ss.ShippingStatusId
				LEFT JOIN [dbo].ShippingVia sv WITH(NOLOCK) ON sos.ShipviaId = sv.ShippingViaId
				INNER JOIN [dbo].Vendor shcu WITH(NOLOCK) ON sos.ShipToVendorId = shcu.VendorId
				LEFT JOIN [dbo].VendorRMACustomsInfo wci WITH(NOLOCK) ON sos.RMAShippingId = wci.RMAShippingId
				WHERE sos.RMAShippingId = @salesOrderShippingId
		 END TRY    
   BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetShippingEdit' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@salesOrderShippingId, '')
			 
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
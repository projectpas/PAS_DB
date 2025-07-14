/*************************************************************           
 ** File:   [GetExchangeSalesOrderShippingEditById]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to GetExchangeSalesOrderShippingEditById
 ** Purpose:         
 ** Date:   06/30/2025      
          
 ** PARAMETERS:  @ExchangeSalesOrderShippingId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    06/30/2025   Ekta Chandegra     Created
     
  EXEC GetExchangeSalesOrderShippingEditById @ExchangeSalesOrderShippingId = 108

************************************************************************/
CREATE   PROCEDURE [dbo].[GetExchangeSalesOrderShippingEditById]
    @ExchangeSalesOrderShippingId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT TOP 1
			ISNULL(shcu.Name, shven.VendorName) AS ShipToCustomer,
			sos.ShipToCustomerId,
			sos.SoldToSiteId,
			sos.SoldToSiteName,
			org.countries_name AS OrginCountry,
			sv.Name AS ShipVia,
			ss.Status AS ShippingStatus,
			sos.AirwayBill,
			'' AS CertNum,
			sos.CreatedBy,
			sos.CreatedDate,
			CASE 
				WHEN so.IsVendor = 1 THEN ven.VendorCode 
				ELSE cus.CustomerCode 
			END AS CustomerCode,
			sos.CustomerId,
			CASE 
				WHEN so.IsVendor = 1 THEN ven.VendorName 
				ELSE cus.Name 
			END AS CustomerName,
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
			CASE 
				WHEN sos.IsCustomerShipping = 1 THEN sos.CustomerDomensticShippingShipViaId
				ELSE sos.ShipviaId 
			END AS ShipviaId,
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
			sos.ExchangeSalesOrderId,
			so.ExchangeSalesOrderNumber,
			sos.ExchangeSalesOrderShippingId,
			sos.SOShippingNum,
			sos.SOShippingStatusId,
			sos.Shipment,
			sos.OriginCountryName,
			sos.OriginSiteId,
			sos.IsSameForShipTo,

			-- ExchangeSalesOrderShippingCustomsInfo
			wci.ExchangeSalesOrderCustomsInfoId,
			wci.ExchangeSalesOrderShippingId,
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
			wci.CreatedDate AS CustomsCreatedDate,
			wci.CreatedBy AS CustomsCreatedBy,
			-- ExchangeSalesOrderShippingCustomsInfo

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
			sos.IsCustomerShipping,
			sos.IsManualShipping,
			sos.UnitPrice,
			sos.ManufactureCountryId,
			sos.QtyUOM,
			sos.UnitPriceCurrencyId,
			sos.PackagingSlipNotes
		FROM [dbo].[ExchangeSalesOrderShipping] sos WITH(NOLOCK)
		INNER JOIN [dbo].[ExchangeSalesOrder] so WITH(NOLOCK) ON sos.ExchangeSalesOrderId = so.ExchangeSalesOrderId
		LEFT JOIN [dbo].[Customer] cus WITH(NOLOCK) ON so.CustomerId = cus.CustomerId
		LEFT JOIN [dbo].[Vendor] ven WITH(NOLOCK) ON so.CustomerId = ven.VendorId
		INNER JOIN [dbo].[Countries] stc WITH(NOLOCK) ON sos.SoldToCountryId = stc.countries_id
		INNER JOIN [dbo].[Countries] shc WITH(NOLOCK) ON sos.ShipToCountryId = shc.countries_id
		INNER JOIN [dbo].[Countries] org WITH(NOLOCK) ON sos.OriginCountryId = org.countries_id
		INNER JOIN [dbo].[ShippingStatus] ss WITH(NOLOCK) ON sos.SOShippingStatusId = ss.ShippingStatusId
		INNER JOIN [dbo].[ShippingVia] sv WITH(NOLOCK) ON sos.ShipviaId = sv.ShippingViaId
		LEFT JOIN [dbo].[Customer] shcu WITH(NOLOCK) ON sos.ShipToCustomerId = shcu.CustomerId
		LEFT JOIN [dbo].[Vendor] shven WITH(NOLOCK) ON sos.ShipToCustomerId = shven.VendorId
		LEFT JOIN [dbo].[ExchangeSalesOrderShippingCustomsInfo] wci WITH(NOLOCK) ON sos.ExchangeSalesOrderShippingId = wci.ExchangeSalesOrderShippingId
		WHERE sos.ExchangeSalesOrderShippingId = @ExchangeSalesOrderShippingId;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetExchangeSalesOrderShippingEditById'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeSalesOrderPartId = ''' + CAST(ISNULL(@ExchangeSalesOrderShippingId, '') AS VARCHAR(100))
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
            RETURN(1);
	END CATCH
END
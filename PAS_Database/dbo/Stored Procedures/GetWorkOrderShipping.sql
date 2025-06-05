/*************************************************************               
 ** File:  [GetWorkOrderShipping]               
 ** Author:  Bhargav Saliya
 ** Description: This stored procedure is used to GetWorkOrderShipping By Id.    
 ** Purpose:             
 ** Date:   05-Mar-2025          
              
 ** PARAMETERS: @@workOrderShippingId BIGINT    
             
 ** RETURN VALUE:               
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date         Author			Change Description                
 ** --   --------     -------		--------------------------------              
    1    05-Mar-2025  Bhargav Saliya		Created    
	2    28-May-2025  Devendra Shekh		changes to read [ShipviaId]
	3    29-Mar-2025  Amit Ghediya			Added isBypass flag for shipping. 
         
	exec dbo.GetWorkOrderShipping @workOrderShippingId=3554
************************************************************************/    
CREATE   PROCEDURE [dbo].[GetWorkOrderShipping]
    @workOrderShippingId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

    -- Retrieve Customer Reference
		DECLARE @CustomerReference NVARCHAR(255);
		SELECT TOP 1 @CustomerReference = wop.CustomerReference
		FROM WorkOrderShippingItem t WITH(NOLOCK)
		JOIN WorkOrderPartNumber wop WITH(NOLOCK) ON t.WorkOrderPartNumId = wop.ID
		WHERE t.WorkOrderShippingId = @workOrderShippingId;

		-- Retrieve Work Order Shipping Details
		SELECT
			wos.WorkOrderShippingId,
			wos.WOShippingNum,
			wos.WOShippingStatusId,
			wos.OpenDate,
			wos.CustomerId,
			cus.Name AS CustomerName,
			cus.CustomerCode,
			@CustomerReference AS CustomerReference,
			--CASE WHEN wos.IsCustomerShipping = 1 THEN wos.CustomerDomensticShippingShipViaId ELSE wos.ShipviaId END AS ShipviaId,
			wos.ShipviaId AS ShipviaId,
			ss.Status AS ShippingStatus,
			wos.ShipDate,
			wos.AirwayBill,
			CASE WHEN ISNULL(wos.HouseAirwayBill,NULL) = NULL THEN NULL ELSE wos.HouseAirwayBill END HouseAirwayBill,
			wos.TrackingNum,
			wos.Weight,
			wos.SoldToName,
			wos.SoldToAddress1,
			wos.SoldToAddress2,
			wos.SoldToCity,
			wos.SoldToState,
			wos.SoldToZip,
			wos.SoldToCountryId,
			wos.ShipToName,
			wos.ShipToSiteName,
			wos.ShipToSiteId,
			wos.ShipToAddress1,
			wos.ShipToAddress2,
			wos.ShipToCity,
			wos.ShipToState,
			wos.ShipToZip,
			wos.ShipToCountryId,
			wos.OriginName,
			wos.OriginAddress1,
			wos.OriginAddress2,
			wos.OriginCity,
			wos.OriginState,
			wos.OriginZip,
			wos.OriginCountryId,
			wos.MasterCompanyId,
			wos.CreatedBy,
			wos.UpdatedBy,
			wos.CreatedDate,
			wos.UpdatedDate,
			wos.Shipment,
			wos.SoldToSiteId,
			wos.SoldToSiteName,
			wos.SoldToCountryName,
			wos.ShipToCustomerId,
			wos.ShipToCountryName,
			wos.OriginCountryName,
			wos.OriginSiteId,
			wos.IsSameForShipTo,
			wos.ShipSizeLength,
			wos.ShipSizeWidth,
			wos.ShipSizeHeight,
			wos.ShipWeightUnit,
			wos.ShipSizeUnitOfMeasureId,
			CASE WHEN ISNULL(wos.PickTicketid,NULL) = NULL THEN NULL ELSE wos.PickTicketId END PickTicketId,
			wos.NoOfContainer,
			wos.shipAttention AS ShipAttention,
			wos.soldAttention AS SoldAttention,
			wos.CustomerDomensticShippingShipViaId,
			wos.ShippingAccountInfo,
			wos.NoOfItems,
			uoi.ShortName AS ShipSizeUnitOfMeasure,
			CASE WHEN ISNULL(wos.SoldToState,'') = '' THEN '' ELSE wos.SoldToState END SoldStateCode,
			CASE WHEN ISNULL(wos.OriginState,'') = '' THEN '' ELSE wos.OriginState END OriginStateCode,
			CASE WHEN ISNULL(wos.ShipToState,'') = '' THEN '' ELSE wos.ShipToState END ShipStateCode,
			CASE WHEN ISNULL(soldcon.countries_iso_code,NULL) = NULL THEN '' ELSE soldcon.countries_iso_code END SoldCountryCode,
			CASE WHEN ISNULL(ocon.countries_iso_code,NULL) = NULL THEN '' ELSE ocon.countries_iso_code END OriginCountryCode,
			CASE WHEN ISNULL(shipcon.countries_iso_code,NULL) = NULL THEN '' ELSE shipcon.countries_iso_code END ShipCountryCode,
			shipcont.CustomerPhone AS ShipPhoneNumber,
			cus.CustomerPhone AS SoldPhoneNumber,
			cont.WorkPhone AS OriginPhoneNumber,
			wos.ShipToName AS ShipContactpersonName,
			wos.SoldToName AS SoldContactpersonName,
			wos.OriginName AS OrignContactpersonName,
			shipcont.CustomerPhoneExt AS ShipphoneExtension,
			cus.CustomerPhoneExt AS SoldphoneExtension,
			CASE WHEN ISNULL(cont.WorkPhoneExtn,NULL) = NULL THEN '' ELSE cont.WorkPhoneExtn END OrignphoneExtension,
			wos.IsCustomerShipping,
			wos.IsManualShipping,
			wos.ManufactureCountryId,
			wos.QtyUOM,
			wos.UnitPrice,
			wos.UnitPriceCurrencyId,
			quoi.ShortName AS QtyUOMVal,
			ccur.Code AS CustomCurrency,
			cur.Code AS UnitCurrency,
			CASE WHEN ISNULL(mocon.countries_iso_code,NULL) = NULL THEN '' ELSE mocon.countries_iso_code END ManufactureCountry,
			woc.CommodityCode,
			woc.CustomsValue,
			wos.Notes,
			wos.isIgnoreAWB,
			wci.WorkOrderShippingId,
			wci.EntryType,
			wci.EPU,
			wci.CustomsValue,
			CASE WHEN ISNULL(wci.NetMass,NULL) = NULL THEN NULL ELSE wci.NetMass END NetMass,
			wci.EntryStatus,
			CASE WHEN ISNULL(wci.VATValue,NULL) = NULL THEN NULL ELSE wci.VATValue END VATValue,
			wci.UCR,
			wci.MasterUCR,
			wci.MovementRefNo,
			wci.CommodityCode,
			wci.CustomCurrencyId,
			ISNULL(wos.isBypassShipping,0) AS isBypassShipping
		FROM [dbo].[WorkOrderShipping] wos WITH(NOLOCK)
		JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON wos.WorkOrderId = wo.WorkOrderId
		JOIN [dbo].[Customer] cus WITH(NOLOCK) ON wos.CustomerId = cus.CustomerId
		JOIN [dbo].[ShippingStatus] ss WITH(NOLOCK) ON wos.WOShippingStatusId = ss.ShippingStatusId
		LEFT JOIN [dbo].[UnitOfMeasure] uoi WITH(NOLOCK) ON wos.ShipWeightUnit = uoi.UnitOfMeasureId
		LEFT JOIN [dbo].[Countries] ocon WITH(NOLOCK) ON wos.OriginCountryId = ocon.countries_id
		LEFT JOIN [dbo].[Countries] shipcon WITH(NOLOCK) ON wos.ShipToCountryId = shipcon.countries_id
		LEFT JOIN [dbo].[Countries] soldcon WITH(NOLOCK) ON wos.SoldToCountryId = soldcon.countries_id
		LEFT JOIN [dbo].[Customer] shipcont WITH(NOLOCK) ON wos.ShipToCustomerId = shipcont.CustomerId
		LEFT JOIN [dbo].[CustomerContact] custcon WITH(NOLOCK) ON wo.CustomerContactId = custcon.CustomerContactId
		LEFT JOIN [dbo].[Contact] cont WITH(NOLOCK) ON custcon.ContactId = cont.ContactId
		LEFT JOIN [dbo].[Countries] mocon WITH(NOLOCK)ON wos.ManufactureCountryId = mocon.countries_id
		LEFT JOIN [dbo].[UnitOfMeasure] quoi WITH(NOLOCK) ON wos.QtyUOM = quoi.UnitOfMeasureId
		LEFT JOIN [dbo].[WorkOrderCustomsInfo] woc WITH(NOLOCK) ON wos.WorkOrderShippingId = woc.WorkOrderShippingId
		LEFT JOIN [dbo].[WorkOrderCustomsInfo] wci WITH(NOLOCK) ON wos.WorkOrderShippingId = wci.WorkOrderShippingId
		LEFT JOIN [dbo].[Currency] cur WITH(NOLOCK) ON wos.UnitPriceCurrencyId = cur.CurrencyId
		LEFT JOIN [dbo].[Currency] ccur WITH(NOLOCK) ON woc.CustomCurrencyId = ccur.CurrencyId
		WHERE wos.WorkOrderShippingId = @workOrderShippingId;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
        , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderShipping'     
        ,@ProcedureParameters VARCHAR(3000) = '@OldValue = ''' + CAST(ISNULL(@workOrderShippingId, '') AS varchar(100))      
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
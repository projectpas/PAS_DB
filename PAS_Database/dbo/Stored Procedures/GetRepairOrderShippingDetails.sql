/*************************************************************           
 ** File:   [GetRepairOrderShippingDetails]           
 ** Author: Amit Ghediya
 ** Description: This stored procedure is used to Get WorkOrder/SubWorkOrder CostAnalysis Details.
 ** Purpose:         
 ** Date:   04/23/2025

 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    04/23/2025   Vishal Suthar		Created

-- EXEC [dbo].[GetRepairOrderShippingDetails] 4
**************************************************************/
CREATE   PROCEDURE [dbo].[GetRepairOrderShippingDetails]
    @RepairOrderShippingId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT TOP 1
        shcu.CompanyName AS shipToCustomer,
        sos.ShipToCustomerId shipToCustomerId,
        sos.SoldToSiteId soldToSiteId,
        sos.SoldToSiteName soldToSiteName,
        sos.Notes notes,
        org.countries_name AS orginCountry,
        sv.Name AS shipVia,
        ss.Status AS shippingStatus,
        sos.AirwayBill airwayBill,
        '' AS certNum,
        sos.CreatedBy createdBy,
        sos.CreatedDate createdDate,
        cus.VendorCode vendorCode,
        sos.VendorId vendorId,
        cus.VendorName AS customerName,
        sos.HouseAirwayBill houseAirwayBill,
        sos.IsActive isActive,
        sos.IsDeleted isDeleted,
        sos.MasterCompanyId masterCompanyId,
        sos.OpenDate openDate,
        sos.OriginAddress1 originAddress1,
        sos.OriginAddress2 originAddress2,
        sos.OriginCity originCity,
        sos.OriginCountryId originCountryId,
        sos.OriginName originName,
        sos.OriginState originState,
        sos.OriginZip originZip,
        sos.ShipDate shipDate,
        sos.ShipToAddress1 shipToAddress1,
        sos.ShipToAddress2 shipToAddress2,
        sos.ShipToCity shipToCity,
        sos.ShipToCountryId shipToCountryId,
        sos.ShipToName shipToName,
        sos.ShipToSiteId shipToSiteId,
        sos.ShipToSiteName shipToSiteName,
        sos.ShipToState shipToState,
        sos.ShipToZip shipToZip,
        CASE 
            WHEN sos.IsVendorShipping = 1 THEN sos.CustomerDomensticShippingShipViaId
            ELSE sos.ShipviaId 
        END AS shipviaId,
        sos.SoldToAddress1 soldToAddress1,
        sos.SoldToAddress2 soldToAddress2,
        sos.SoldToCity soldToCity,
        sos.SoldToCountryId soldToCountryId,
        sos.SoldToName soldToName,
        sos.SoldToState soldToState,
        sos.SoldToZip soldToZip,
        sos.TrackingNum trackingNum,
        sos.UpdatedBy updatedBy,
        sos.UpdatedDate updatedDate,
        sos.Weight weight,
        sos.RepairOrderId repairOrderId,
        so.RepairOrderNumber repairOrderNumber,
        sos.RepairOrderShippingId repairOrderShippingId,
        sos.ROShippingNum roShippingNum,
        sos.ROShippingStatusId roShippingStatusId,
        sos.Shipment shipment,
        sos.OriginCountryName originCountryName,
        sos.OriginSiteId originSiteId,
        sos.IsSameForShipTo isSameForShipTo,
        wci.*,
        sos.ShipWeightUnit shipWeightUnit,
        sos.ShipSizeUnitOfMeasureId shipSizeUnitOfMeasureId,
        sos.ShipSizeLength shipSizeLength,
        sos.ShipSizeWidth shipSizeWidth,
        sos.ShipSizeHeight shipSizeHeight,
        shc.countries_name AS shipToCountryName,
        stc.countries_name AS soldToCountryName,
        sos.NoOfContainer noOfContainer,
        sos.NoOfItems noOfItems,
        sos.ShippingAccountNo shippingAccountNo,
        sos.IsVendorShipping isVendorShipping,
        sos.IsManualShipping isManualShipping,
        sos.ManufactureCountryId manufactureCountryId,
        sos.QtyUOM qtyUOM,
        sos.UnitPriceCurrencyId unitPriceCurrencyId,
        sos.UnitPrice unitPrice
    FROM dbo.RepairOrderShipping sos WITH (NOLOCK)
    INNER JOIN dbo.RepairOrder so WITH (NOLOCK) ON sos.RepairOrderId = so.RepairOrderId
    INNER JOIN dbo.Vendor cus WITH (NOLOCK) ON sos.VendorId = cus.VendorId
    INNER JOIN dbo.Countries stc WITH (NOLOCK) ON sos.SoldToCountryId = stc.countries_id
    INNER JOIN dbo.Countries shc WITH (NOLOCK) ON sos.ShipToCountryId = shc.countries_id
    INNER JOIN dbo.Countries org WITH (NOLOCK) ON sos.OriginCountryId = org.countries_id
    INNER JOIN dbo.ShippingStatus ss WITH (NOLOCK) ON sos.ROShippingStatusId = ss.ShippingStatusId
    INNER JOIN dbo.ShippingVia sv WITH (NOLOCK) ON sos.ShipviaId = sv.ShippingViaId
    INNER JOIN dbo.LegalEntity shcu WITH (NOLOCK) ON sos.ShipToCustomerId = shcu.LegalEntityId
    LEFT JOIN dbo.RepairOrderCustomsInfo wci WITH (NOLOCK) ON sos.RepairOrderShippingId = wci.RepairOrderShippingId
    WHERE sos.RepairOrderShippingId = @RepairOrderShippingId;
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetRepairOrderShippingDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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
END;
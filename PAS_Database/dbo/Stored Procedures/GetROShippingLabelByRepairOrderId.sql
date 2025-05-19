/*************************************************************           
 ** File:   [GetROShippingLabelByRepairOrderId]           
 ** Author:    Vishal Suthar
 ** Description:  Get data for RepairOrder shipping lable
 ** Purpose:         
 ** Date:   15-MAY-2025
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------  
	1    05/15/2025		Vishal Suthar	    CREATED

exec GetROShippingLabelByRepairOrderId 1570,1973,621
**************************************************************/ 
CREATE     PROCEDURE [dbo].[GetROShippingLabelByRepairOrderId]
    @RepairOrderId INT,
    @RepairOrderPartId INT,
    @RoShippingId INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT TOP 1
					sos.ServiceClass,
					'' AS CustomerRef,
					so.RepairOrderNumber,
					sos.ShipDate,
					sos.Weight,
					uom.ShortName AS UOM,
					uomn.ShortName AS UOMDimention,
					CASE WHEN ISNULL(sos.AirwayBill,'') = '' THEN '' ELSE  sos.AirwayBill END AS ShippingLabelBarcode,
					sos.OriginName AS OriginCompanyName,
					sos.OriginAddress1,
					sos.OriginCity,
					sos.OriginState,
					sos.OriginZip AS OriginPostalCode,
					sos.OriginCountryName AS OriginCountry,
					sos.ShipToName AS ShipToComanyName,
					--shipToSite.SiteName AS ShipToSiteName,
					'' AS ShipToSiteName,
					--shipToSite.Attention AS ShipToAttention,
					'' AS ShipToAttention,
					sos.ShipToAddress1,
					sos.ShipToCity,
					sos.ShipToState,
					sos.ShipToZip AS ShipToPostalCode,
					country.countries_name AS ShipToCountry,
					cust.VendorPhone AS ShipToPhone,
					@RoShippingId AS ROShippingId,
					sos.ShipSizeLength AS Length,
					sos.ShipSizeWidth AS Width,
					sos.ShipSizeHeight AS Height,
					sos.NoOfContainer,
					sosi.QtyShipped AS NoOfPiece,
					so.UpdatedDate
				FROM 
					dbo.[RepairOrder] so WITH(NOLOCK)
					JOIN dbo.[RepairOrderShipping] sos WITH(NOLOCK) ON so.RepairOrderId = sos.RepairOrderId
					LEFT JOIN dbo.[RepairOrderShippingItem] sosi WITH(NOLOCK) ON sos.RepairOrderShippingId = sosi.RepairOrderShippingId
					--JOIN dbo.[CustomerDomensticShipping] shipToSite WITH(NOLOCK) ON sos.ShipToSiteId = shipToSite.CustomerDomensticShippingId
					JOIN dbo.[Vendor] cust WITH(NOLOCK) ON so.VendorId = cust.VendorId
					LEFT JOIN dbo.[UnitOfMeasure] uom WITH(NOLOCK) ON sos.ShipWeightUnit = uom.UnitOfMeasureId
					LEFT JOIN dbo.[UnitOfMeasure] uomn WITH(NOLOCK) ON sos.ShipSizeUnitOfMeasureId = uomn.UnitOfMeasureId
					LEFT JOIN dbo.[Countries] country WITH(NOLOCK) ON sos.ShipToCountryId = country.countries_id
				WHERE 
					sos.RepairOrderId = @RepairOrderId 
					AND sosi.RepairOrderPartId = @RepairOrderPartId
					AND sos.RepairOrderShippingId = @RoShippingId;
			END
		COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetROShippingLabelByRepairOrderId' 
              , @ProcedureParameters VARCHAR(3000)  = '@RepairOrderId = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH	
END
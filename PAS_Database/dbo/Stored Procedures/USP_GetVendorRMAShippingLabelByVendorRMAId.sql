/*************************************************************           
 ** File:   [USP_GetVendorRMAShippingLabelByVendorRMAId]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get VendorRMAShippingLabel By VendorRMAId pdf
 ** Purpose:         
 ** Date:   09-06-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    09-06-2025    Sahdev Saliya       Created  
	2    06-04-2026	   Amit Ghediya		   UOM Conversion Changes [PN-15140]
	3	 19/06/2026	   Ayushi			   [PN-16911]Skip fn_ConvertUOM call when ToUOM = FromUOM
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetVendorRMAShippingLabelByVendorRMAId]
    @VendorRMAId BIGINT,
    @VendorRMADetailId BIGINT,
    @RMAShippingId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
		     BEGIN TRY

				SELECT
					sos.ServiceClass,
					'' AS CustomerRef,
					so.RMANumber AS SalesOrderNumber,
					sos.ShipDate,
					sos.Weight,
					uom.ShortName AS UOM,
					uomn.ShortName AS UOMDimention,
					ISNULL(sos.AirwayBill, '') AS ShippingLabelBarcode, 
					sos.OriginName AS OriginCompanyName,
					sos.OriginAddress1,
					sos.OriginCity,
					sos.OriginState,
					sos.OriginZip AS OriginPostalCode,
					sos.OriginCountryName AS OriginCountry,
					sos.ShipToName AS ShipToComanyName,
					cds.SiteName AS ShipToSiteName,
					cds.Attention AS ShipToAttention,
					sos.ShipToAddress1,
					sos.ShipToCity,
					sos.ShipToState,
					sos.ShipToZip AS ShipToPostalCode,
					country.countries_name AS ShipToCountry,
					cust.VendorPhone AS ShipToPhone,
					sos.RMAShippingId,
					sos.ShipSizeLength AS Length,
					sos.ShipSizeWidth AS Width,
					sos.ShipSizeHeight AS Height,
					sos.NoOfContainer,
					CASE WHEN ISNULL(IM.PurchaseUnitOfMeasure,'') = ISNULL(IM.StockUnitOfMeasure,'') THEN ISNULL(sosi.QtyShipped,0) ELSE dbo.fn_ConvertUOM(ISNULL(sosi.QtyShipped,0),IM.PurchaseUnitOfMeasure,IM.StockUnitOfMeasure,0,IM.MasterCompanyId) END AS NoOfPiece,
					so.UpdatedDate
				FROM [dbo].VendorRMA so WITH(NOLOCK)
				LEFT JOIN [dbo].RMAShipping sos WITH(NOLOCK) ON so.VendorRMAId = sos.VendorRMAId AND sos.RMAShippingId = @RMAShippingId
				LEFT JOIN [dbo].RMAShippingItem sosi WITH(NOLOCK) ON sos.RMAShippingId = sosi.RMAShippingId
				LEFT JOIN [dbo].[VendorRMADetail] vrd WITH(NOLOCK) ON sosi.VendorRMADetailId = vrd.VendorRMADetailId
				LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON vrd.[ItemMasterId] = IM.[ItemMasterId]
				LEFT JOIN [dbo].CustomerDomensticShipping cds WITH(NOLOCK) ON sos.ShipToSiteId = cds.CustomerDomensticShippingId
				LEFT JOIN [dbo].Vendor cust WITH(NOLOCK) ON so.VendorId = cust.VendorId
				LEFT JOIN [dbo].UnitOfMeasure uom WITH(NOLOCK) ON sos.ShipWeightUnit = uom.UnitOfMeasureId
				LEFT JOIN [dbo].UnitOfMeasure uomn WITH(NOLOCK) ON sos.ShipSizeUnitOfMeasureId = uomn.UnitOfMeasureId
				LEFT JOIN [dbo].Countries country WITH(NOLOCK) ON sos.ShipToCountryId = country.countries_id
				WHERE sos.VendorRMAId = @VendorRMAId
				  AND sosi.VendorRMADetailId = @VendorRMADetailId;
		    END TRY    

   BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorRMAShippingLabelByVendorRMAId' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRMAId, '') + ''',
				    @Parameter2 = ' + ISNULL(@VendorRMADetailId ,'') + ''',
					@Parameter3 = ' + ISNULL(@RMAShippingId ,'')

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
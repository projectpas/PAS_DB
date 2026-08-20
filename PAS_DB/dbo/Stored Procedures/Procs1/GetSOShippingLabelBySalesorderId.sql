/*************************************************************           
 ** File:   [GetSOShippingLabelBySalesorderId]           
 ** Author:    Shrey Chandegara
 ** Description:  Get data for SalesOrder shipping lable
 ** Purpose:         
 ** Date:   23-SEP-2024
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------  
	1    11/12/2024   Shrey Chandegara	     CREATED

exec GetSOShippingLabelBySalesorderId 1570,1973,621
**************************************************************/ 
CREATE   PROCEDURE [dbo].[GetSOShippingLabelBySalesorderId]
    @SalesOrderId INT,
    @SalesOrderPartId INT,
    @SoShippingId INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT TOP 1
					sos.ServiceClass,
					so.CustomerReference AS CustomerRef,
					so.SalesOrderNumber,
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
					shipToSite.SiteName AS ShipToSiteName,
					shipToSite.Attention AS ShipToAttention,
					sos.ShipToAddress1,
					sos.ShipToCity,
					sos.ShipToState,
					sos.ShipToZip AS ShipToPostalCode,
					country.countries_name AS ShipToCountry,
					cust.CustomerPhone AS ShipToPhone,
					@SoShippingId AS SOShippingId,
					sos.ShipSizeLength AS Length,
					sos.ShipSizeWidth AS Width,
					sos.ShipSizeHeight AS Height,
					sos.NoOfContainer,
					Sum(sosi.QtyShipped) AS NoOfPiece,
					so.UpdatedDate
				FROM 
					dbo.[SalesOrder] so WITH(NOLOCK)
					JOIN dbo.[SalesOrderShipping] sos WITH(NOLOCK) ON so.SalesOrderId = sos.SalesOrderId
					LEFT JOIN dbo.[SalesOrderShippingItem] sosi WITH(NOLOCK) ON sos.SalesOrderShippingId = sosi.SalesOrderShippingId
					JOIN dbo.[CustomerDomensticShipping] shipToSite WITH(NOLOCK) ON sos.ShipToSiteId = shipToSite.CustomerDomensticShippingId
					JOIN dbo.[Customer] cust WITH(NOLOCK) ON so.CustomerId = cust.CustomerId
					LEFT JOIN dbo.[UnitOfMeasure] uom WITH(NOLOCK) ON sos.ShipWeightUnit = uom.UnitOfMeasureId
					LEFT JOIN dbo.[UnitOfMeasure] uomn WITH(NOLOCK) ON sos.ShipSizeUnitOfMeasureId = uomn.UnitOfMeasureId
					LEFT JOIN dbo.[Countries] country WITH(NOLOCK) ON sos.ShipToCountryId = country.countries_id
				WHERE 
					sos.SalesOrderId = @SalesOrderId 
					--AND sosi.SalesOrderPartId = @SalesOrderPartId
					AND sos.SalesOrderShippingId = @SoShippingId

					GROUP BY sos.ServiceClass,so.CustomerReference,	so.SalesOrderNumber,sos.ShipDate,sos.Weight,uom.ShortName,
					uomn.ShortName,sos.AirwayBill,sos.OriginName,sos.OriginAddress1,	sos.OriginCity,
					sos.OriginState,sos.OriginZip,sos.OriginCountryName,sos.ShipToName,	shipToSite.SiteName,
					shipToSite.Attention ,sos.ShipToAddress1,sos.ShipToCity,sos.ShipToState,sos.ShipToZip,country.countries_name,
					cust.CustomerPhone,	sos.ShipSizeLength,	sos.ShipSizeWidth,	sos.ShipSizeHeight,	sos.NoOfContainer,	so.UpdatedDate;
			END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetSOShippingLabelBySalesorderId' 
              , @ProcedureParameters VARCHAR(3000)  = '@SalesOrderId = '''
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
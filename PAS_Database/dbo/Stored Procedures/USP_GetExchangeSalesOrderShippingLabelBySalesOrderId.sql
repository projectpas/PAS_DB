/*************************************************************           
 ** File:   [USP_GetExchangeSalesOrderShippingLabelBySalesOrderId]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to USP_GetExchangeSalesOrderShippingLabelBySalesOrderId
 ** Purpose:         
 ** Date:   07/01/2025      
          
 ** PARAMETERS:  @ExchangeSalesOrderId BIGINT, @ExchangeSalesOrderPartId BIGINT, @EXSOShippingId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    07/01/2025   Ekta Chandegra     Created
     
  EXEC USP_GetExchangeSalesOrderShippingLabelBySalesOrderId @ExchangeSalesOrderId = 194 , @ExchangeSalesOrderPartId = 174 , @EXSOShippingId = 111

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetExchangeSalesOrderShippingLabelBySalesOrderId]
    @ExchangeSalesOrderId BIGINT,
    @ExchangeSalesOrderPartId BIGINT,
    @EXSOShippingId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @IsVendor BIT;

		SELECT @IsVendor = 
			CASE 
				WHEN IsVendor IS NOT NULL THEN CAST(IsVendor AS BIT) 
				ELSE 0 
			END
		FROM [dbo].[ExchangeSalesOrder] WITH(NOLOCK)
		WHERE ExchangeSalesOrderId = @ExchangeSalesOrderId;

		IF @IsVendor = 1
		BEGIN
			SELECT TOP 1
				sos.ServiceClass,
				so.CustomerReference AS CustomerRef,
				so.ExchangeSalesOrderNumber,
				sos.ShipDate,
				sos.Weight,
				uom.ShortName AS UOM,
				uomn.ShortName AS UOMDimention,
				sos.AirwayBill,
				sos.OriginName AS OriginCompanyName,
				sos.OriginAddress1 AS OriginAddress1,
				sos.OriginCity AS OriginCity,
				sos.OriginState AS OriginState,
				sos.OriginZip AS OriginPostalCode,
				sos.OriginCountryName AS OriginCountry,
				sos.ShipToName AS ShipToComanyName,
				sos.ShipToSiteName,
				'' AS ShipToAttention,
				sos.ShipToAddress1,
				sos.ShipToCity,
				sos.ShipToState,
				sos.ShipToZip AS ShipToPostalCode,
				c.countries_name AS ShipToCountry,
				v.VendorPhone AS ShipToPhone,
				sos.ExchangeSalesOrderShippingId AS SOShippingId,
				CAST(sos.ShipSizeLength AS INT) AS Length,
				CAST(sos.ShipSizeWidth AS INT) AS Width,
				CAST(sos.ShipSizeHeight AS INT) AS Height,
				sos.NoOfContainer,
				sosi.QtyShipped AS NoOfPiece,
				so.UpdatedDate
			FROM [dbo].[ExchangeSalesOrder] so WITH(NOLOCK)
			LEFT JOIN [dbo].[ExchangeSalesOrderShipping] sos WITH(NOLOCK) ON so.ExchangeSalesOrderId = sos.ExchangeSalesOrderId AND sos.ExchangeSalesOrderShippingId = @EXSOShippingId
			LEFT JOIN [dbo].[ExchangeSalesOrderShippingItem] sosi WITH(NOLOCK) ON sos.ExchangeSalesOrderShippingId = sosi.ExchangeSalesOrderShippingId
			LEFT JOIN [dbo].[Vendor] v WITH(NOLOCK) ON so.CustomerId = v.VendorId
			LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON sos.ShipWeightUnit = uom.UnitOfMeasureId
			LEFT JOIN [dbo].[UnitOfMeasure] uomn WITH(NOLOCK) ON sos.ShipSizeUnitOfMeasureId = uomn.UnitOfMeasureId
			LEFT JOIN [dbo].[Countries] c WITH(NOLOCK) ON sos.ShipToCountryId = c.countries_id
			WHERE sos.ExchangeSalesOrderId = @ExchangeSalesOrderId 
			  AND sosi.ExchangeSalesOrderPartId = @ExchangeSalesOrderPartId;
		END
		ELSE
		BEGIN
			SELECT TOP 1
				sos.ServiceClass,
				so.CustomerReference AS CustomerRef,
				so.ExchangeSalesOrderNumber,
				sos.ShipDate,
				sos.Weight,
				uom.ShortName AS UOM,
				uomn.ShortName AS UOMDimention,
				sos.AirwayBill,
				sos.OriginName AS OriginCompanyName,
				sos.OriginAddress1 AS OriginAddress1,
				sos.OriginCity AS OriginCity,
				sos.OriginState AS OriginState,
				sos.OriginZip AS OriginPostalCode,
				sos.OriginCountryName AS OriginCountry,
				sos.ShipToName AS ShipToComanyName,
				cds.SiteName AS ShipToSiteName,
				cds.Attention AS ShipToAttention,
				sos.ShipToAddress1,
				sos.ShipToCity,
				sos.ShipToState,
				sos.ShipToZip AS ShipToPostalCode,
				c.countries_name AS ShipToCountry,
				cust.CustomerPhone AS ShipToPhone,
				sos.ExchangeSalesOrderShippingId AS SOShippingId,
				CAST(sos.ShipSizeLength AS INT) AS Length,
				CAST(sos.ShipSizeWidth AS INT) AS Width,
				CAST(sos.ShipSizeHeight AS INT) AS Height,
				sos.NoOfContainer,
				sosi.QtyShipped AS NoOfPiece,
				so.UpdatedDate
			FROM [dbo].[ExchangeSalesOrder] so WITH(NOLOCK)
			LEFT JOIN [dbo].[ExchangeSalesOrderShipping] sos WITH(NOLOCK) ON so.ExchangeSalesOrderId = sos.ExchangeSalesOrderId AND sos.ExchangeSalesOrderShippingId = @EXSOShippingId
			LEFT JOIN [dbo].[ExchangeSalesOrderShippingItem] sosi WITH(NOLOCK) ON sos.ExchangeSalesOrderShippingId = sosi.ExchangeSalesOrderShippingId
			LEFT JOIN [dbo].[CustomerDomensticShipping] cds WITH(NOLOCK) ON sos.ShipToSiteId = cds.CustomerDomensticShippingId
			LEFT JOIN [dbo].[Customer] cust WITH(NOLOCK) ON so.CustomerId = cust.CustomerId
			LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON sos.ShipWeightUnit = uom.UnitOfMeasureId
			LEFT JOIN [dbo].[UnitOfMeasure] uomn WITH(NOLOCK) ON sos.ShipSizeUnitOfMeasureId = uomn.UnitOfMeasureId
			LEFT JOIN [dbo].[Countries] c WITH(NOLOCK) ON sos.ShipToCountryId = c.countries_id
			WHERE sos.ExchangeSalesOrderId = @ExchangeSalesOrderId 
			  AND sosi.ExchangeSalesOrderPartId = @ExchangeSalesOrderPartId;
		END
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeSalesOrderShippingLabelBySalesOrderId'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeSalesOrderId = ''' + CAST(ISNULL(@ExchangeSalesOrderId, '') AS VARCHAR(100)) + ''', '+
													'@ExchangeSalesOrderPartId = ''' + CAST(ISNULL(@ExchangeSalesOrderPartId, '') AS VARCHAR(100)) + ''', '+
													'@EXSOShippingId = ''' + CAST(ISNULL(@EXSOShippingId, '') AS VARCHAR(100)) 
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
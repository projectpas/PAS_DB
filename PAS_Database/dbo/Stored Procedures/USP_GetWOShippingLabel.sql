/*************************************************************           
 ** File:   [USP_GetWOShippingLabel]           
 ** Author:   Bhargav Saliya 
 ** Description: Get Data for WO Shipping Label 
 ** Purpose:         
 ** Date:   28-April-2025      
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author			Change Description            
 ** --   --------		 -------		--------------------------------          
    1    28-April-2025   Bhargav Saliya		Created

**************************************************************/
CREATE	   PROCEDURE [dbo].[USP_GetWOShippingLabel]
    @WorkOrderId BIGINT,
    @WorkOrderPartNoId BIGINT,
    @WOShippingId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		SELECT TOP 1
        WOP.CustomerReference AS CustomerRef,
        wo.WorkOrderNum AS WorkOrderNumber,
        wo.WorkOrderId,
        wos.ShipDate,
        ISNULL(wos.Weight, 0) AS Weight,
        uom.ShortName AS UOM,
        uomn.ShortName AS UOMDimention,
        wos.Notes,
		ISNULL(wos.AirwayBill,'') AS AirwayBill,
        wos.OriginName AS OriginCompanyName,
        wos.OriginAddress1 AS OriginAddress1,
        wos.OriginCity AS OriginCity,
        wos.OriginState AS OriginState,
        wos.OriginZip AS OriginPostalCode,
        wos.OriginCountryName AS OriginCountry,
        wos.ShipToName AS ShipToComanyName,
        shipToSite.SiteName AS ShipToSiteName,
        shipToSite.Attention AS ShipToAttention,
        wos.ShipToAddress1,
        wos.ShipToCity,
        wos.ShipToState,
        wos.ShipToZip AS ShipToPostalCode,
        country.countries_name AS ShipToCountry,
        cust.CustomerPhone AS ShipToPhone,
        @WOShippingId AS WOShippingId,
        wos.ShipSizeLength AS Length,
        wos.ShipSizeWidth AS Width,
        wos.ShipSizeHeight AS Height,
        wos.NoOfContainer,
        wosi.QtyShipped AS NoOfPiece,
        wo.UpdatedDate
    FROM [dbo].[WorkOrder] wo WITH(NOLOCK)
    INNER JOIN [dbo].[WorkOrderShipping] wos WITH(NOLOCK) ON wo.WorkOrderId = wos.WorkOrderId
    LEFT JOIN [dbo].[WorkOrderShippingItem] wosi WITH(NOLOCK) ON wos.WorkOrderShippingId = wosi.WorkOrderShippingId
    INNER JOIN [dbo].[CustomerDomensticShipping] shipToSite WITH(NOLOCK) ON wos.ShipToSiteId = shipToSite.CustomerDomensticShippingId
    INNER JOIN [dbo].[Customer] cust WITH(NOLOCK) ON wo.CustomerId = cust.CustomerId
    LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON wos.ShipWeightUnit = uom.UnitOfMeasureId
    LEFT JOIN [dbo].[UnitOfMeasure] uomn WITH(NOLOCK) ON wos.ShipSizeUnitOfMeasureId = uomn.UnitOfMeasureId
    LEFT JOIN [dbo].[Countries] country WITH(NOLOCK) ON wos.ShipToCountryId = country.countries_id
    LEFT JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WOP.WorkOrderId = wo.WorkOrderId
    WHERE wos.WorkOrderId = @WorkOrderId AND wosi.WorkOrderPartNumId = @WorkOrderPartNoId AND wos.WorkOrderShippingId = @WOShippingId;
	END TRY
	BEGIN CATCH  
   
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = 'USP_GetWOShippingLabel',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS varchar(100)) +    
            '@Parameter2 = ''' + CAST(ISNULL(@WorkOrderPartNoId, '') AS varchar(100)) +  
            '@Parameter3 = ''' + CAST(ISNULL(@WOShippingId, '') AS varchar(100)),  
            @ApplicationName varchar(100) = 'PAS'   
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR (  
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'  
    , 16, 1, @ErrorLogID)  
  
    RETURN (1);  
	END CATCH  
END
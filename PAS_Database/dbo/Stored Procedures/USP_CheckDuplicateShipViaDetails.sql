/************************************************************************************           
 ** File:   [USP_CheckDuplicateShipViaDetails]           
 ** Author: 
 ** Description: This stored procedure is used to Check Duplicate Ship Via Details.
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************************************           
  ** Change History           
 **************************************************************************************           
 ** PR    Date				 	Author				       Change Description            
 ** --    --------			 -----------				--------------------------------          
	 1    06-Jun-2025		Bhargav Saliya			        Created

EXEC [USP_CheckDuplicateShipViaDetails] @ShipViaId = 6,@MasterCompanyId=1,@ShippingId=7875,@ModuleId=3,@ShippingAccountInfo='test by bhaf g'
****************************************************************************************/

Create      PROCEDURE [dbo].[USP_CheckDuplicateShipViaDetails]
	@ShipViaId BIGINT,
	@MasterCompanyId BIGINT,
	@ShippingId BIGINT,
	@ModuleId BIGINT,
	@ShippingAccountInfo varchar(200) = null
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
	DECLARE @CustModuleIds BIGINT = (SELECT ModuleId from [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Customer');
	DECLARE @VendorModuleIds BIGINT = (SELECT ModuleId from [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Vendor');
	DECLARE @LegalModuleIds BIGINT = (SELECT ModuleId from [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'LegalEntity');

	IF(@CustModuleIds = @ModuleId)
	BEGIN
		SELECT CDS.CustomerId
			,CDS.CustomerDomensticShippingId
			,CDS.ShipViaId
			,CDS.ShippingAccountinfo
			,CDS.MasterCompanyId
		FROM [dbo].[CustomerDomensticShippingShipVia] CDS WITH(NOLOCK) 
		WHERE CDS.ShipViaId = @ShipViaId AND CDS.MasterCompanyId = @MasterCompanyId and CDS.CustomerDomensticShippingId = @ShippingId
			 AND CDS.ShippingAccountInfo = @ShippingAccountInfo
	END

	ELSE IF(@VendorModuleIds = @ModuleId)
	BEGIN
		SELECT VS.VendorId
			,VS.VendorShippingAddressId
			,VS.ShipViaId
			,VS.ShippingAccountInfo
			,VS.MasterCompanyId
		FROM [dbo].[VendorShipping] VS WITH(NOLOCK) 
		WHERE VS.ShipViaId = @ShipViaId AND VS.MasterCompanyId = @MasterCompanyId and VS.VendorShippingAddressId = @ShippingId
			 AND VS.ShippingAccountInfo = @ShippingAccountInfo
	END

	ELSE IF(@LegalModuleIds = @ModuleId)
	BEGIN
		SELECT LS.LegalEntityId
			,LS.LegalEntityShippingAddressId
			,LS.ShipViaId
			,LS.ShippingAccountInfo
			,LS.MasterCompanyId
		FROM [dbo].[LegalEntityShipping] LS WITH(NOLOCK) 
		WHERE LS.ShipViaId = @ShipViaId AND LS.MasterCompanyId = @MasterCompanyId and LS.LegalEntityShippingAddressId = @ShippingId
			 AND LS.ShippingAccountInfo = @ShippingAccountInfo
	END
	
  END TRY  
  BEGIN CATCH  
  
   DECLARE @ErrorLogID int,  
           @DatabaseName varchar(100) = DB_NAME(),  
           -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
           @AdhocComments varchar(150) = 'USP_CheckDuplicateShipViaDetails',  
           @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ShipViaId, '') AS varchar(100)) +    
           '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) +  
           '@Parameter3 = ''' + CAST(ISNULL(@ShippingId, '') AS varchar(100)) +
		   '@Parameter4 = ''' + CAST(ISNULL(@ShippingAccountInfo, '') AS varchar(100)) + 
		   '@Parameter5 = ''' + CAST(ISNULL(@ModuleId, '') AS varchar(100)),  
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
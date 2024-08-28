/*************************************************************               
 ** File:   [GetVendorRMAPartShippingAddress]               
 ** Author:  AMIT GHEDIYA    
 ** Description:  This Store Procedure use to get part level vendor rma shipping address.   
 ** Purpose:             
 ** Date:   12/08/2024          
              
 ** RETURN VALUE:               
 **********************************************************               
 ** check customer emial & phone exists.             
 **********************************************************               
 ** PR   Date			Author			Change Description                
 ** --   --------		-------			--------------------------------              
    1    27/08/2024  	AMIT GHEDIYA	Created     
 
 EXEC [GetVendorRMAPartShippingAddress] 158,2222
********************************************************************/ 
CREATE     PROCEDURE [dbo].[GetVendorRMAPartShippingAddress]
	@VendorRMAId BIGINT = 0,
	@VendorRMADetailId BIGINT = 0
AS
BEGIN
		BEGIN TRY
				DECLARE @VendorId BIGINT,
						@VendorShippingAddressId BIGINT,
						@PartCount BIGINT = 0;

				--Get VendorId for add
				SELECT @VendorId = [VendorId] FROM [dbo].[VendorRMA] WITH(NOLOCK) 
				WHERE [VendorRMAId] = @VendorRMAId;

				--Check is multiple part
				SELECT @PartCount = COUNT(VendorRMADetailId) FROM [dbo].[VendorRMADetail] WITH(NOLOCK) 
				WHERE [VendorRMAId] = @VendorRMAId;

				--Get part level vendor rma shipping add.
				SELECT @VendorShippingAddressId = ISNULL([VendorShippingAddressId],0) FROM [dbo].[VendorRMADetail] WITH(NOLOCK) 
				WHERE [VendorRMAId] = @VendorRMAId AND [VendorRMADetailId] = @VendorRMADetailId;
				
				IF(@VendorShippingAddressId > 0 AND @PartCount = 1)
				BEGIN
					SELECT 
						UPPER(VSA.SiteName) AS ShipToSiteName,
						UPPER(AD.Line1) AS ShipToAddress1,
						UPPER(AD.Line2) AS ShipToAddress2,
						UPPER(AD.City) AS ShipToCity,
						UPPER(AD.StateOrProvince) AS ShipToState,
						UPPER(AD.PostalCode) AS ShipToPostalCode,
						UPPER(CO.countries_name) AS ShipToCountry
					FROM [dbo].[VendorShippingAddress] VSA WITH(NOLOCK)
					JOIN [dbo].[Address] AD WITH(NOLOCK) ON VSA.AddressId = AD.AddressId
					JOIN [dbo].[Countries] CO WITH(NOLOCK) ON AD.CountryId = CO.countries_id
					WHERE VSA.AddressId = @VendorShippingAddressId AND VSA.VendorId = @VendorId
				END
				ELSE
				BEGIN
					SELECT 
						UPPER(VSA.SiteName) AS ShipToSiteName,
						UPPER(AD.Line1) AS ShipToAddress1,
						UPPER(AD.Line2) AS ShipToAddress2,
						UPPER(AD.City) AS ShipToCity,
						UPPER(AD.StateOrProvince) AS ShipToState,
						UPPER(AD.PostalCode) AS ShipToPostalCode,
						UPPER(CO.countries_name) AS ShipToCountry
					FROM [dbo].[VendorShippingAddress] VSA WITH(NOLOCK)
					JOIN [dbo].[Address] AD WITH(NOLOCK) ON VSA.AddressId = AD.AddressId
					JOIN [dbo].[Countries] CO WITH(NOLOCK) ON AD.CountryId = CO.countries_id
					WHERE VSA.IsPrimary = 1 AND VSA.VendorId = @VendorId
				END
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetVendorRMAPartShippingAddress' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRMAId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END
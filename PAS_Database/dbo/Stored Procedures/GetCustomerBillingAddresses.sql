/*************************************************************           
    ** File:  [GetCustomerBillingAddresses]       
    ** Author:   Ekta Chandegra
    ** Description: This stored procedure is used to GetCustomerBillingAddresses
    ** Purpose:         
    ** Date:  07-May-2025 
            
    ** RETURN VALUE: 
    **************************************************************           
     ** Change History           
    **************************************************************           
    ** PR   Date			Author			Change Description            
    ** --   --------		-------			--------------------------------          
       1    07-May-2025   Ekta Chandegra	Created
        
    exec [dbo].[GetCustomerBillingAddresses] @CustomerId=4295
 **************************************************************/
CREATE   PROCEDURE [dbo].[GetCustomerBillingAddresses]
    @CustomerId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT 
			ad.Line1 AS Address1,
			ad.Line2 AS Address2,
			ad.Line3 AS Address3,
			ad.AddressId,
			ad.PostalCode,
			ad.City,
			ad.StateOrProvince,
			v.SiteName,
			v.CustomerBillingAddressId,
			v.CreatedDate,
			v.UpdatedDate,
			v.CustomerId,
			ISNULL(v.IsActive,0) AS IsActive,
			ISNULL(v.IsDeleted,0) AS IsDeleted,
			ISNULL(v.IsPrimary,0) AS IsPrimary,
			c.countries_id AS CountryId,
			c.countries_name AS CountryName,
			ISNULL(v.TagName,'')AS TagName,
			v.ContactTagId,
			ISNULL(v.Attention,'') AS Attention,
			v.InvDelPrefStatusId,
			v.Email,
			ISNULL(iv.Status, '') AS InvoiceDeliveryPrefStatus
		FROM [dbo].[CustomerBillingAddress] v WITH(NOLOCK)
		INNER JOIN [dbo].[Address] ad WITH(NOLOCK) ON v.AddressId = ad.AddressId
		LEFT JOIN [dbo].[Countries] c WITH(NOLOCK) ON ad.CountryId = c.countries_id
		LEFT JOIN [dbo].[InvoiceDeliveryPrefStatus] iv WITH(NOLOCK) ON v.InvDelPrefStatusId = iv.InvDelPrefStatusId
		WHERE v.CustomerId = @CustomerId
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT
    	,@DatabaseName VARCHAR(100) = db_name()
    	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
    	,@AdhocComments VARCHAR(150) = 'USP_GetCustomerTaxTypeRateMapping'
    	,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CustomerId, '') AS varchar(100)) + ''
    	,@ApplicationName VARCHAR(100) = 'PAS'
   		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
   		EXEC spLogException @DatabaseName = @DatabaseName
   			,@AdhocComments = @AdhocComments
   			,@ProcedureParameters = @ProcedureParameters
   			,@ApplicationName = @ApplicationName
   			,@ErrorLogID = @ErrorLogID OUTPUT;
    
   		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
   		RETURN (1);
	END CATCH
END
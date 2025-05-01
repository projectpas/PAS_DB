/*************************************************************           
   ** File:   [USP_GetAllShippingAddressDetails]           
   ** Author:   Ekta Chandegra
   ** Description: This stored procedure is used to GetAllShippingAddressDetails
   ** Purpose:         
   ** Date:  01-May-2025 
           
   ** RETURN VALUE: 
   **************************************************************           
    ** Change History           
   **************************************************************           
   ** PR   Date			Author			Change Description            
   ** --   --------		-------			--------------------------------          
      1    01-May-2025   Ekta Chandegra	Created
       
   exec [dbo].[USP_GetAllShippingAddressDetails] @CustomerId=4293
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetAllShippingAddressDetails]
    @CustomerId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT 
            c.CustomerDomensticShippingId,
            c.CustomerId,
            c.IsPrimary,
            ad.Line1 AS Address1,
            ad.Line2 AS Address2,
            ad.Line3 AS Address3,
            ad.AddressId,
            ad.PostalCode,
            ad.City,
            ad.StateOrProvince,
            c.SiteName,
            c.CreatedDate,
            c.UpdatedDate,
            c.IsActive,
            c.IsDeleted,
            co.countries_name AS CountryName,
            co.countries_id AS CountryId,
            c.TagName,
            c.ContactTagId,
            c.Attention
        FROM [dbo].[CustomerDomensticShipping] c WITH(NOLOCK)
        INNER JOIN [dbo].[Address] ad WITH(NOLOCK) ON c.AddressId = ad.AddressId
        LEFT JOIN [dbo].[Countries] co WITH(NOLOCK) ON ad.CountryId = co.countries_id
        WHERE c.CustomerId = @CustomerId;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT
   			,@DatabaseName VARCHAR(100) = db_name()
   			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
   			,@AdhocComments VARCHAR(150) = 'USP_GetAllShippingAddressDetails'
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
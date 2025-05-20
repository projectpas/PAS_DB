/*************************************************************           
 ** File:   [USP_GetVendorInternationalShippingDetails]       
 ** Author:   Ayushi Patel
 ** Description: Get Vendor International Shipping Details
 ** Purpose:         
 ** Date:  19/05/2025 
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1	 19-MAY-2025   AYUSHI PATEL 		Created
	exec [USP_GetVendorInternationalShippingDetails] 4784
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetVendorInternationalShippingDetails]
    @VendorId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY
        SELECT 
            vsi.VendorInternationalShippingId,
            vsi.VendorId,
            vsi.ExportLicense,
            vsi.StartDate,
            vsi.Amount,
            ISNULL(vsi.IsPrimary,0) AS IsPrimary,
            vsi.Description,
            vsi.ExpirationDate,
            vsi.ShipToCountryId,
            co.countries_name AS ShipToCountry,
            ISNULL(vsi.IsActive,0) AS IsActive,
            ISNULL(vsi.IsDeleted,0) AS IsDeleted,
            vsi.UpdatedDate,
            vsi.UpdatedBy,
            vsi.CreatedBy,
            vsi.CreatedDate
        FROM dbo.VendorInternationalShipping AS vsi WITH (NOLOCK)
        LEFT JOIN dbo.Countries AS co WITH (NOLOCK) ON vsi.ShipToCountryId = co.countries_id
        WHERE vsi.VendorId = @VendorId
        ORDER BY vsi.CreatedDate DESC
    END TRY
    BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetVendorInternationalShippingDetails'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = '', '
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);           
	END CATCH
END
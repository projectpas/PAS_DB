/*************************************************************           
 ** File:  [USP_GetVendorInternationalShippingDetailsAudit]       
 ** Author:   Ayushi Patel
 ** Description: Get Vendor International Shipping Details History
 ** Purpose:         
 ** Date:  19/05/2025 
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1	 19-MAY-2025   AYUSHI PATEL 		Created
	exec [USP_GetVendorInternationalShippingDetailsAudit] 4784
**************************************************************/ 
CREATE PROCEDURE [dbo].[USP_GetVendorInternationalShippingDetailsAudit]
    @VendorInternationalShippingId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY
        SELECT 
            a.AuditVendorInternationalShippingId,
            a.VendorInternationalShippingId,
            a.VendorId,
            a.ExportLicense,
            a.StartDate,
            a.Amount,
            ISNULL(a.IsPrimary,0) AS IsPrimary,
            a.Description,
            a.ExpirationDate,
            a.ShipToCountryId,
            ISNULL(c.countries_name, '') AS ShipToCountry,
            ISNULL(a.IsActive,0) AS IsActive,
            ISNULL(a.IsDeleted,0) AS IsDeleted,
            a.UpdatedDate,
            a.CreatedBy,
            a.UpdatedBy,
            a.CreatedDate
        FROM dbo.VendorInternationalShippingAudit a WITH (NOLOCK)
        LEFT JOIN dbo.Countries c WITH (NOLOCK) ON a.ShipToCountryId = c.countries_id
        WHERE a.VendorInternationalShippingId = @VendorInternationalShippingId
        ORDER BY a.AuditVendorInternationalShippingId DESC;
    END TRY
    BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetVendorInternationalShippingDetailsAudit'
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
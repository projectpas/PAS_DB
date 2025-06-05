/***************************************************************  
 ** File:   [USP_GetVendorAuditHistory]             
 ** Author: Ayushi Patel 
 ** Description: Get audit history for a specific vendor
 ** Purpose:   
 ** Date:  27-May-2025  
            
 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    2025-05-27		  Ayushi Patel				Created

	exec [USP_GetVendorAuditHistory] 4787 , 229
*************************************************************/
CREATE PROCEDURE [dbo].[USP_GetVendorAuditHistory]
    @VendorId BIGINT,
    @EmployeeId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY
		DECLARE @VendorModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE NAME = 'Vendor');
        DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
		SELECT 
				@CurrntEmpTimeZoneDesc = COALESCE(
					ETZ.[Description],  -- Prefer Employee's TimeZone description if available
					LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
				)
			FROM 
				dbo.Employee E WITH (NOLOCK) 
			LEFT JOIN 
				dbo.TimeZone ETZ WITH (NOLOCK) 
				ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN 
				dbo.LegalEntity LE WITH (NOLOCK) 
				ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN 
				dbo.TimeZone LTZ WITH (NOLOCK) 
				ON LE.TimeZoneId = LTZ.TimeZoneId
			WHERE 
				E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

        SELECT 
            va.AuditVendorId,
            va.VendorId,
            ISNULL(va.VendorEmail, '') AS VendorEmail,
            ISNULL(va.IsActive,0) AS IsActive,
            ad.Line1 AS Address1,
            ad.Line2 AS Address2,
            ad.Line3 AS Address3,
            va.VendorCode,
            va.VendorName,
            ad.City,
            ad.StateOrProvince,
            vt.Description,
			(Cast(DBO.ConvertUTCtoLocal(va.CreatedDate, @CurrntEmpTimeZoneDesc) as datetime)) CreatedDate,
            va.CreatedBy,
            va.UpdatedBy,
			(Cast(DBO.ConvertUTCtoLocal(va.UpdatedDate, @CurrntEmpTimeZoneDesc) as datetime)) UpdatedDate,
            ad.AddressId,
            ad.CountryId,
            ad.PostalCode,
            va.EDI,
            va.EDIDescription,
            va.CreditLimit,
            ISNULL(va.IsDeleted,0) AS IsDeleted,
            cu.Code AS CurrencyId,
            ct.Name AS CreditTermsId,
            ISNULL(di.DiscontValue, 0) AS DiscountLevel,
            CONCAT(ISNULL(va.VendorPhone, ''), ' - ', ISNULL(va.VendorPhoneExt, '')) AS VendorPhoneContact,
            va.IsVendorOnHold,
            (
                SELECT STRING_AGG(vc.ClassificationName, ',')
                FROM dbo.ClassificationMapping cm WITH (NOLOCK)
                INNER JOIN dbo.VendorClassification vc WITH (NOLOCK) ON cm.ClasificationId = vc.VendorClassificationId
                WHERE cm.ReferenceId = va.VendorId AND cm.ModuleId = @VendorModuleId
            ) AS VendorClassificationName
        FROM dbo.VendorAudit va WITH (NOLOCK)
        INNER JOIN dbo.Address ad WITH (NOLOCK) ON va.AddressId = ad.AddressId
        LEFT JOIN dbo.VendorType vt WITH (NOLOCK) ON va.VendorTypeId = vt.VendorTypeId
        LEFT JOIN dbo.CreditTerms ct WITH (NOLOCK) ON va.CreditTermsId = ct.CreditTermsId
        LEFT JOIN dbo.Currency cu WITH (NOLOCK) ON va.CurrencyId = cu.CurrencyId
        LEFT JOIN dbo.Discount di WITH (NOLOCK) ON va.DiscountId = di.DiscountId
        WHERE va.VendorId = @VendorId
        ORDER BY va.AuditVendorId DESC;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = 'USP_GetVendorAuditHistory',
                @ProcedureParameters VARCHAR(3000) = '@VendorId = ' + CAST(ISNULL(@VendorId, 0) AS VARCHAR),
                @ApplicationName VARCHAR(100) = 'PAS';
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR (
            'Unexpected error occurred in the database. Please let the support team know of the error number: %d',
            16, 1, @ErrorLogID
        );
        RETURN (1);
    END CATCH
END
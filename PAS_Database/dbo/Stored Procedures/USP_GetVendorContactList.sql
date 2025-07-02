/*************************************************************
** File:     [USP_GetVendorContactList]
** Author:   Ayushi Patel
** Description: Get Vendor ContactList
** Purpose:  
** Date:     02-07-2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author         Change Description
** --   ----------   ------------   --------------------------------
** 1    02-07-2025   Ayushi Patel   Created

-- EXEC USP_GetVendorContactList 4797
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetVendorContactList] 
    @VendorId BIGINT,
    @EmployeeId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

        SELECT
            @CurrntEmpTimeZoneDesc = COALESCE(
                ETZ.[Description],
                LTZ.[Description]
            )
        FROM dbo.Employee E WITH (NOLOCK)
        LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
        LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
        LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
        WHERE E.EmployeeId = @EmployeeId;

        SELECT 
            c.ContactId,
            c.ContactTitle,
            c.AlternatePhone,
            c.CreatedBy,
            c.UpdatedBy,
            c.Email,
            ISNULL(ct.TagName, '') AS TagName,
            c.Fax,
            c.FirstName,
            c.LastName,
            c.MiddleName,
            c.MobilePhone,
            c.Notes,
            c.Prefix,
            c.Suffix,
            c.WebsiteURL,
            c.WorkPhone,
            c.IsActive,
            vc.VendorContactId,
            c.ContactTagId,
            c.Attention,
            vc.VendorId,
            CAST(dbo.ConvertUTCtoLocal(c.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME) AS CreatedDate,
            CAST(dbo.ConvertUTCtoLocal(c.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME) AS UpdatedDate,
            c.WorkPhoneExtn,
            vc.IsDefaultContact,
            vc.IsDeleted,
            CASE WHEN ISNULL(c.WorkPhoneExtn, '') = '' THEN c.WorkPhone ELSE c.WorkPhone + ' - ' + c.WorkPhoneExtn END AS FullContactNo,
            vc.IsRestrictedParty,
            CASE WHEN vc.IsRestrictedParty = 1 THEN 'YES' ELSE 'NO' END AS RestrictedParty
        FROM dbo.Contact c WITH (NOLOCK)
        INNER JOIN dbo.VendorContact vc WITH (NOLOCK) ON c.ContactId = vc.ContactId
        LEFT JOIN dbo.ContactTag ct WITH (NOLOCK) ON c.ContactTagId = ct.ContactTagId
        WHERE vc.VendorId = @VendorId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_GetVendorContactList',
                @ProcedureParameters VARCHAR(3000) = '@VendorId = ' + CAST(@VendorId AS VARCHAR) + ', @EmployeeId = ' + CAST(@EmployeeId AS VARCHAR),
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END
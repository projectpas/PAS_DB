
/*************************************************************
 ** File:   [USP_PublicApi_GetVendorContacts]
 ** Author: Moin Bloch
 ** Description: 4.20 Active contacts of the vendors on one page (@VendorIds: comma separated), default contact first.
 **              Same rows as dbo.USP_GetVendorContactDataByVendorId (PAS vendor Contacts tab).
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/vendors (contacts)
 ** Date:   12/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    12/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_GetVendorContacts] @MasterCompanyId = 1, @VendorIds = '1,2,3'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetVendorContacts]
    @MasterCompanyId INT,
    @VendorIds       VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        VC.[VendorId],   -- used by the API to attach the contacts; not returned to clients
        NULLIF(LTRIM(RTRIM(C.[Prefix])), '') AS [Prefix],
        NULLIF(LTRIM(RTRIM(C.[FirstName])), '') AS [FirstName],
        NULLIF(LTRIM(RTRIM(C.[MiddleName])), '') AS [MiddleName],
        NULLIF(LTRIM(RTRIM(C.[LastName])), '') AS [LastName],
        NULLIF(LTRIM(RTRIM(C.[Suffix])), '') AS [Suffix],
        NULLIF(LTRIM(RTRIM(C.[ContactTitle])), '') AS [Title],
        NULLIF(LTRIM(RTRIM(C.[Email])), '') AS [Email],
        NULLIF(LTRIM(RTRIM(C.[WorkPhone])), '') AS [WorkPhone],
        NULLIF(LTRIM(RTRIM(C.[WorkPhoneExtn])), '') AS [WorkPhoneExtension],
        NULLIF(LTRIM(RTRIM(C.[MobilePhone])), '') AS [MobilePhone],
        NULLIF(LTRIM(RTRIM(C.[AlternatePhone])), '') AS [AlternatePhone],
        NULLIF(LTRIM(RTRIM(C.[Fax])), '') AS [Fax],
        CTG.[TagName] AS [Tag],
        CAST(ISNULL(VC.[IsDefaultContact], 0) AS BIT) AS [IsDefaultContact]
    FROM [dbo].[VendorContact] VC WITH (NOLOCK)
    INNER JOIN [dbo].[Vendor] V WITH (NOLOCK) ON V.[VendorId] = VC.[VendorId] AND V.[MasterCompanyId] = @MasterCompanyId
    INNER JOIN [dbo].[Contact] C WITH (NOLOCK) ON C.[ContactId] = VC.[ContactId]
    LEFT JOIN [dbo].[ContactTag] CTG WITH (NOLOCK) ON CTG.[ContactTagId] = VC.[ContactTagId]
    WHERE VC.[VendorId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@VendorIds, ','))
      AND ISNULL(VC.[IsDeleted], 0) = 0
      AND ISNULL(VC.[IsActive], 0) = 1
    ORDER BY VC.[VendorId], CAST(ISNULL(VC.[IsDefaultContact], 0) AS BIT) DESC, VC.[VendorContactId];
END
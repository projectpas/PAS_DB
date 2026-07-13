/***************************************************************  
 ** File:   [USP_GetVendorDataById]             
 ** Author: Ayushi Patel 
 ** Description: Get vendor Data By Id  
 ** Purpose:   
 ** Date:     2025-05-26  
            
 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    2025-05-26		  Ayushi Patel				Created
    2    2026-04-22		  Moin Bloch				Added QuickBooksReferenceId PN-16009
	3    24-06-2026       Sahdev Saliya             Added Notes [PN-16968]
	4    02-07-2026       Sahdev Saliya             Added Resale Number [PN-17018]
    5    06-07-2026       Divyesh Kathitiya         Added VAT Number [PN-17124] 

	exec [USP_GetVendorDataById] 4787
*************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetVendorDataById]
    @VendorId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
    BEGIN TRY
	DECLARE @VendorModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE NAME = 'Vendor');
        SELECT 
            v.VendorId,
            v.VendorName,
            v.VendorCode,
            v.VendorTypeId,
            v.DoingBusinessAsName,
            v.IsParent AS Parent,
            vp1.VendorName AS ParentName,
            v.VendorContractReference,
            v.AddressId,
            v.IsVendorAlsoCustomer,
            v.RelatedCustomerId,
            v.VendorEmail,
            ISNULL(v.IsPreferredVendor,0) as IsPreferredVendor,
            v.LicenseNumber,
            v.VendorURL,
            ISNULL(v.IsCertified,0) as IsCertified,
            v.VendorAudit,
            v.MasterCompanyId,
            v.CreatedBy,
            v.UpdatedBy,
            v.CreatedDate,
            v.UpdatedDate,
            ISNULL(v.IsActive,0) as IsActive,
            v.VendorPhone,
            ISNULL(v.IsDeleted,0) as IsDeleted,
            vp1.VendorName AS VendorParentName,
            v.VendorPhoneExt,
            ISNULL(v.IsAddressForBilling,0) as IsAddressForBilling,
            ISNULL(v.IsAddressForShipping,0) as IsAddressForShipping,
            ISNULL(v.IsAllowNettingAPAR,0) as IsAllowNettingAPAR,
            vt.Description,
            ad.Line1 AS Address1,
            ad.Line2 AS Address2,
            ad.City,
            ad.StateOrProvince,
            ad.PostalCode,
            cont.countries_name AS Country,
            cont.countries_id AS CountryId,
            v.VendorParentId,
			v.Notes,
			v.ResaleNumber,
            v.VatNumber,
            VendorClassificationNames = (
                SELECT STRING_AGG(vc.ClassificationName, ',')
                FROM DBO.ClassificationMapping mp WITH (NOLOCK)
                INNER JOIN DBO.VendorClassification vc WITH (NOLOCK) ON mp.ClasificationId = vc.VendorClassificationId
                WHERE mp.ReferenceId = v.VendorId AND mp.ModuleId = @VendorModuleId
            ),

            VendorClassificationIds = (
                SELECT STRING_AGG(CAST(vc.VendorClassificationId AS VARCHAR), ',')
                FROM DBO.ClassificationMapping mp WITH (NOLOCK)
                INNER JOIN DBO.VendorClassification vc WITH (NOLOCK) ON mp.ClasificationId = vc.VendorClassificationId
                WHERE mp.ReferenceId = v.VendorId AND mp.ModuleId = @VendorModuleId
            ),

            IntegrationPortalNames = (
                SELECT STRING_AGG(ip.Description, ',')
                FROM DBO.IntegrationPortalMapping ipm WITH (NOLOCK)
                INNER JOIN DBO.IntegrationPortal ip WITH (NOLOCK) ON ipm.IntegrationPortalId = ip.IntegrationPortalId
                WHERE ipm.ReferenceId = v.VendorId AND ipm.ModuleId = @VendorModuleId
            ),

            IntegrationPortalIds = (
                SELECT STRING_AGG(CAST(ip.IntegrationPortalId AS VARCHAR), ',')
                FROM DBO.IntegrationPortalMapping ipm WITH (NOLOCK)
                INNER JOIN DBO.IntegrationPortal ip WITH (NOLOCK) ON ipm.IntegrationPortalId = ip.IntegrationPortalId
                WHERE ipm.ReferenceId = v.VendorId AND ipm.ModuleId = @VendorModuleId
            ),

            ISNULL(v.IsTradeRestricted,0) as IsTradeRestricted,
            v.TradeRestrictedMemo,
            ISNULL(v.IsTrackScoreCard,0) as IsTrackScoreCard,
            ISNULL(v.IsVendorOnHold,0) as IsVendorOnHold,
            v.CreditTermsId,
            ISNULL(v.IsWarningRestriction,0) as IsWarningRestriction,
			v.QuickBooksReferenceId,
			v.IntegrationTypeId
		FROM [dbo].[Vendor] v WITH (NOLOCK)
		LEFT JOIN [dbo].[Address] ad WITH (NOLOCK) ON v.AddressId = ad.AddressId
		LEFT JOIN [dbo].[Countries] cont WITH (NOLOCK) ON ad.CountryId = cont.countries_id
		LEFT JOIN [dbo].[VendorType] vt WITH (NOLOCK) ON v.VendorTypeId = vt.VendorTypeId
		LEFT JOIN [dbo].[Vendor] vp1 WITH (NOLOCK) ON v.VendorParentId = vp1.VendorId

        WHERE v.VendorId = @VendorId

    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------- 
                @AdhocComments VARCHAR(150) = 'USP_GetVendorDataById',
                @ProcedureParameters VARCHAR(3000) = '@VendorId = ' + CAST(@VendorId AS VARCHAR),
                @ApplicationName VARCHAR(100) = 'PAS';
 -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in USP_GetVendorDataById. Error ID: %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END
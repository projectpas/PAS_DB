/*************************************************************
** File:     [USP_GetVendorDefaultPaymentDetails]
** Author:   Ayushi Patel
** Description: Get Vendor Default Payment + Vendor info
** Purpose:  Replaces EF GetVendorDefault with SP
** Date:     02-07-2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author         Change Description
** --   ----------   ------------   --------------------------------
** 1    02-07-2025   Ayushi Patel   Created

-- EXEC USP_GetVendorDefaultPaymentDetails 4797
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetVendorDefaultPaymentDetails]
    @VendorId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            vp.BankAddressId,
            vp.BankName,
            vp.CreatedBy,
            vp.CreatedDate,
            vp.DefaultPaymentMethod,
            vp.MasterCompanyId,
            vp.UpdatedBy,
            vp.UpdatedDate,
            vp.VendorId,
            vp.VendorPaymentId,
            ISNULL(vpm.Description, '') AS PaymentType,

            v.VendorId AS [Vendor.VendorId],
            v.VendorName AS [Vendor.VendorName],
            v.VendorCode AS [Vendor.VendorCode],
            v.VendorTypeId AS [Vendor.VendorTypeId],
            v.VendorParentId AS [Vendor.VendorParentId],
            v.DoingBusinessAsName AS [Vendor.DoingBusinessAsName],
            v.IsParent AS [Vendor.IsParent],
            v.VendorContractReference AS [Vendor.VendorContractReference],
            v.AddressId AS [Vendor.AddressId],
            v.IsVendorAlsoCustomer AS [Vendor.IsVendorAlsoCustomer],
            v.RelatedCustomerId AS [Vendor.RelatedCustomerId],
            v.VendorEmail AS [Vendor.VendorEmail],
            v.IsPreferredVendor AS [Vendor.IsPreferredVendor],
            v.LicenseNumber AS [Vendor.LicenseNumber],
            v.VendorURL AS [Vendor.VendorURL],
            v.IsCertified AS [Vendor.IsCertified],
            v.VendorAudit AS [Vendor.VendorAudit],
            v.EDI AS [Vendor.EDI],
            v.EDIDescription AS [Vendor.EDIDescription],
            v.AeroExchange AS [Vendor.AeroExchange],
            v.AeroExchangeDescription AS [Vendor.AeroExchangeDescription],
            v.CreditLimit AS [Vendor.CreditLimit],
            v.CurrencyId AS [Vendor.CurrencyId],
            v.DiscountId AS [Vendor.DiscountId],
            v.Is1099Required AS [Vendor.Is1099Required],
            v.CreditTermsId AS [Vendor.CreditTermsId],
            v.ManagementStructureId AS [Vendor.ManagementStructureId],
            v.VendorPhone AS [Vendor.VendorPhone],
            v.VendorPhoneExt AS [Vendor.VendorPhoneExt],
            v.IsAddressForBilling AS [Vendor.IsAddressForBilling],
            v.IsAddressForShipping AS [Vendor.IsAddressForShipping],
            v.IsAllowNettingAPAR AS [Vendor.IsAllowNettingAPAR],
            v.IsAllow AS [Vendor.IsAllow],
            v.IsRestrict AS [Vendor.IsRestrict],
            v.IsWarning AS [Vendor.IsWarning],
            v.BillingAddressId AS [Vendor.BillingAddressId],
            v.ShippingAddressId AS [Vendor.ShippingAddressId],
            v.IsTradeRestricted AS [Vendor.IsTradeRestricted],
            v.TradeRestrictedMemo AS [Vendor.TradeRestrictedMemo],
            v.IsTrackScoreCard AS [Vendor.IsTrackScoreCard],
            v.IsVendorOnHold AS [Vendor.IsVendorOnHold],
            v.TaxIdNumber AS [Vendor.TaxIdNumber],
            v.IsUpdated AS [Vendor.IsUpdated],
            v.QuickBooksReferenceId AS [Vendor.QuickBooksReferenceId],
            v.IsWarningRestriction AS [Vendor.IsWarningRestriction],
			v.MasterCompanyId AS [Vendor.MasterCompanyId],
			v.CreatedBy AS [Vendor.CreatedBy],
			v.UpdatedBy AS [Vendor.UpdatedBy],
			v.CreatedDate AS [Vendor.CreatedDate],
			v.UpdatedDate AS [Vendor.UpdatedDate],
			v.IsActive AS [Vendor.IsActive],
			v.IsDeleted AS [Vendor.IsDeleted]
        FROM VendorPayment vp WITH (NOLOCK)
        LEFT JOIN VendorPaymentMethod vpm WITH (NOLOCK) ON vp.DefaultPaymentMethod = vpm.VendorPaymentMethodId
        INNER JOIN Vendor v WITH (NOLOCK) ON vp.VendorId = v.VendorId
        WHERE vp.VendorId = @VendorId
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_GetVendorDefaultPaymentDetails',
                @ProcedureParameters VARCHAR(MAX) = 'VendorId=' + CAST(@VendorId AS VARCHAR),
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC dbo.spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR('Database error occurred. ErrorLogID = %d', 16, 1, @ErrorLogID);
    END CATCH
END
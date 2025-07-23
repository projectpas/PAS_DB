/*************************************************************           
** File:   [USP_UpdateVendorFinance]
** Author:    Ayushi Patel  
** Description: Add/Update Vendor Finance and return updated data
** Date:      14-07-2025  
**************************************************************           
** Change History           
**************************************************************           
** PR     Date         Author         Change Description            
** --     ----------   ------------   ------------------------------          
** 1      14-07-2025   Ayushi Patel   Created  
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateVendorFinance]
    @VendorId BIGINT,
    @EDI BIT,
    @EDIDescription VARCHAR(500),
    @AeroExchange BIT,
    @AeroExchangeDescription VARCHAR(500),
    @CreditLimit DECIMAL(18, 2),
    @CreditTermsId BIGINT,
    @CurrencyId BIGINT,
    @Is1099Required BIT,
    @DiscountId BIGINT,
    @TaxIdNumber VARCHAR(100),
    @IsAllowNettingAPAR BIT,
    @UpdatedBy VARCHAR(100),
    @UpdatedDate DATETIME2,
    @CreatedBy VARCHAR(100),
    @CreatedDate DATETIME2,
    @MasterCompanyId INT,
    @Vendor1099List dbo.UT_VendorProcess1099 READONLY
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.Vendor
        SET
            EDI = @EDI,
            EDIDescription = @EDIDescription,
            AeroExchange = @AeroExchange,
            AeroExchangeDescription = @AeroExchangeDescription,
            CreditLimit = @CreditLimit,
            CreditTermsId = @CreditTermsId,
            CurrencyId = @CurrencyId,
            Is1099Required = @Is1099Required,
            DiscountId = @DiscountId,
            TaxIdNumber = @TaxIdNumber,
            IsAllowNettingAPAR = @IsAllowNettingAPAR,
            UpdatedBy = @UpdatedBy,
            UpdatedDate = @UpdatedDate
        WHERE VendorId = @VendorId;

        UPDATE existing
        SET
            existing.Master1099Id = input.Master1099Id,
            existing.IsDefaultRadio = input.IsDefaultRadio,
            existing.IsDefaultCheck = input.IsDefaultCheck,
            existing.UpdatedBy = @UpdatedBy,
            existing.UpdatedDate = @UpdatedDate
        FROM dbo.VendorProcess1099 AS existing
        INNER JOIN @Vendor1099List AS input
            ON existing.VendorProcess1099Id = input.VendorProcess1099Id;

        INSERT INTO dbo.VendorProcess1099 (
            VendorId, Master1099Id, IsDefaultRadio, IsDefaultCheck,
            CreatedBy, CreatedDate, UpdatedBy, UpdatedDate,
            MasterCompanyId, IsActive
        )
        SELECT
            @VendorId, input.Master1099Id, input.IsDefaultRadio, input.IsDefaultCheck,
            @CreatedBy, @CreatedDate, @UpdatedBy, @UpdatedDate,
            @MasterCompanyId, 1
        FROM @Vendor1099List AS input
        WHERE input.VendorProcess1099Id IS NULL OR input.VendorProcess1099Id = 0;

        SELECT 
			v.VendorId,
			v.VendorName,
			v.VendorCode,
			v.VendorTypeId,
			v.VendorParentId,
			v.DoingBusinessAsName,
			v.IsParent,
			v.VendorContractReference,
			v.AddressId,
			v.IsVendorAlsoCustomer,
			v.RelatedCustomerId,
			v.VendorEmail,
			v.IsPreferredVendor,
			v.LicenseNumber,
			v.VendorURL,
			v.IsCertified,
			v.VendorAudit,
			v.EDI,
			v.EDIDescription,
			v.AeroExchange,
			v.AeroExchangeDescription,
			v.CreditLimit,
			v.CurrencyId,
			v.DiscountId,
			v.Is1099Required,
			v.CreditTermsId,
			v.ManagementStructureId,
			v.VendorPhone,
			v.VendorPhoneExt,
			v.IsAddressForBilling,
			v.IsAddressForShipping,
			v.IsAllowNettingAPAR,
			v.IsAllow,
			v.IsRestrict,
			v.IsWarning,
			v.BillingAddressId,
			v.ShippingAddressId,
			v.IsTradeRestricted,
			ISNULL(v.TradeRestrictedMemo, '') AS TradeRestrictedMemo,
			v.IsTrackScoreCard,
			v.IsVendorOnHold,
			v.TaxIdNumber,
			v.IsUpdated,
			v.QuickBooksReferenceId,
			ISNULL(v.IsWarningRestriction, 0) AS IsWarningRestriction,
			v.MasterCompanyId,
			v.CreatedBy,
			v.CreatedDate,
			v.UpdatedBy,
			v.UpdatedDate,
			v.IsActive,
			v.IsDeleted
		FROM dbo.Vendor v
		WHERE v.VendorId = @VendorId;

        COMMIT;
    END TRY
    BEGIN CATCH
          SELECT  
            ERROR_NUMBER() AS ErrorNumber  
            ,ERROR_SEVERITY() AS ErrorSeverity  
            ,ERROR_STATE() AS ErrorState  
            ,ERROR_PROCEDURE() AS ErrorProcedure  
            ,ERROR_LINE() AS ErrorLine  
            ,ERROR_MESSAGE() AS ErrorMessage;  

		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_UpdateVendorFinance]',
            @ProcedureParameters varchar(3000) = '',
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END
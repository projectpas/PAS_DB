/*************************************************************            
** File:   [USP_ShippingBillingAddressHistory]        
** Author:  Ayushi Patel
** Description: Logs audit history for shipping and billing addresses across modules: Customer, Vendor, Legal Entity.
** Purpose: Called by multiple modules to capture address changes for audit purposes.
** Date:   28/04/2025     
        
** PARAMETERS: 
    @ReferenceId BIGINT,
    @ModuleId INT,
    @BillingShippingId BIGINT,
    @AddressType INT,
    @UpdatedBy VARCHAR(100)

** RETURN VALUE: None
**************************************************************           
** Change History           
**************************************************************           
** PR   Date         Author		    Change Description            
** --   --------     -------		--------------------------------          
   1    28/04/2025   Ayushi Patel    Created

  --exec [dbo].[USP_ShippingBillingAddressHistory] 4777 , 3 , 7791 , 1 , 'ADMIN User'
************************************************************************/

CREATE   PROCEDURE [dbo].[USP_ShippingBillingAddressHistory]
(
    @ReferenceId BIGINT,
    @ModuleId INT,
    @BillingShippingId BIGINT,
    @AddressType INT,
    @UpdatedBy NVARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY
        DECLARE @AddressId BIGINT = 0;
        DECLARE @AuditAddressId BIGINT; 
        DECLARE @IsPrimary BIT;
        DECLARE @IsActive BIT;
        DECLARE @IsDeleted BIT;
        DECLARE @MasterCompanyId INT;
        DECLARE @SiteName NVARCHAR(200);
        DECLARE @ContactTagId BIGINT;
        DECLARE @Attention NVARCHAR(200);
        DECLARE @CreatedDate DATETIME;

        DECLARE @Line1 NVARCHAR(200);
        DECLARE @Line2 NVARCHAR(200);
        DECLARE @City NVARCHAR(100);
        DECLARE @StateOrProvince NVARCHAR(100);
        DECLARE @CountryId BIGINT;
        DECLARE @PostalCode NVARCHAR(20);

		    DECLARE @CustomerModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Customer');
		    DECLARE @VendorModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Vendor');
		    DECLARE @LegalEntityModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'LegalEntity');
		    DECLARE @BillingAddressId INT = 1;
		    DECLARE @ShippingAddressId INT = 2;
		    DECLARE @CheckPaymentId INT = 3;

        IF @ModuleId = @CustomerModuleId 
        BEGIN
            IF @AddressType = @ShippingAddressId 
            BEGIN
                SELECT 
                    @AuditAddressId = cs.CustomerDomensticShippingId,  
                    @AddressId = cs.AddressId,
                    @IsPrimary = ISNULL(cs.IsPrimary, 0),
                    @IsActive = ISNULL(cs.IsActive, 1),
                    @IsDeleted = ISNULL(cs.IsDeleted, 0),
                    @MasterCompanyId = cs.MasterCompanyId,
                    @SiteName = cs.SiteName,
                    @ContactTagId = cs.ContactTagId,
                    @Attention = cs.Attention,
                    @CreatedDate = cs.CreatedDate
                FROM dbo.CustomerDomensticShipping cs WITH (NOLOCK)
                WHERE cs.CustomerDomensticShippingId = @BillingShippingId;
            END
            ELSE IF @AddressType = @BillingAddressId 
            BEGIN
                SELECT 
                    @AuditAddressId = cb.CustomerBillingAddressId,  
                    @AddressId = cb.AddressId,
                    @IsPrimary = ISNULL(cb.IsPrimary, 0),
                    @IsActive = ISNULL(cb.IsActive, 1),
                    @IsDeleted = ISNULL(cb.IsDeleted, 0),
                    @MasterCompanyId = cb.MasterCompanyId,
                    @SiteName = cb.SiteName,
                    @ContactTagId = cb.ContactTagId,
                    @Attention = cb.Attention,
                    @CreatedDate = cb.CreatedDate
                FROM dbo.CustomerBillingAddress cb WITH (NOLOCK)
                WHERE cb.CustomerBillingAddressId = @BillingShippingId;
            END
        END
      
        ELSE IF @ModuleId = @VendorModuleId  
        BEGIN
            IF @AddressType = @ShippingAddressId 
            BEGIN
                SELECT 
                    @AuditAddressId = vs.VendorShippingAddressId,  
                    @AddressId = vs.AddressId,
                    @IsPrimary = ISNULL(vs.IsPrimary, 0),
                    @IsActive = ISNULL(vs.IsActive, 1),
                    @IsDeleted = ISNULL(vs.IsDeleted, 0),
                    @MasterCompanyId = vs.MasterCompanyId,
                    @SiteName = vs.SiteName,
                    @ContactTagId = vs.ContactTagId,
                    @Attention = vs.Attention,
                    @CreatedDate = vs.CreatedDate
                FROM dbo.VendorShippingAddress vs WITH (NOLOCK)
                WHERE vs.VendorShippingAddressId = @BillingShippingId;
            END
            ELSE IF @AddressType = @BillingAddressId 
            BEGIN
                SELECT 
                    @AuditAddressId = vb.VendorBillingAddressId,  
                    @AddressId = vb.AddressId,
                    @IsPrimary = ISNULL(vb.IsPrimary, 0),
                    @IsActive = ISNULL(vb.IsActive, 1),
                    @IsDeleted = ISNULL(vb.IsDeleted, 0),
                    @MasterCompanyId = vb.MasterCompanyId,
                    @SiteName = vb.SiteName,
                    @ContactTagId = vb.ContactTagId,
                    @Attention = vb.Attention,
                    @CreatedDate = vb.CreatedDate
                FROM dbo.VendorBillingAddress vb WITH (NOLOCK)
                WHERE vb.VendorBillingAddressId = @BillingShippingId;
            END
            ELSE  
            BEGIN
                SELECT 
                    @AuditAddressId = cp.CheckPaymentId,  
                    @AddressId = cp.AddressId,
                    @IsPrimary = ISNULL(cp.IsPrimayPayment, 0),
                    @IsActive = ISNULL(vcp.IsActive, cp.IsActive),
                    @IsDeleted = ISNULL(cp.IsDeleted, 0),
                    @MasterCompanyId = cp.MasterCompanyId,
                    @SiteName = cp.SiteName,
                    @ContactTagId = cp.ContactTagId,
                    @Attention = cp.Attention,
                    @CreatedDate = cp.CreatedDate
                FROM dbo.CheckPayment cp WITH (NOLOCK)
                LEFT JOIN dbo.VendorCheckPayment vcp WITH (NOLOCK) ON cp.CheckPaymentId = vcp.CheckPaymentId
                WHERE cp.CheckPaymentId = @BillingShippingId;
            END
        END
        
        ELSE IF @ModuleId = @LegalEntityModuleId  
        BEGIN
            IF @AddressType = @ShippingAddressId  
            BEGIN
                SELECT 
                    @AuditAddressId = ls.LegalEntityShippingAddressId,  
                    @AddressId = ls.AddressId,
                    @IsPrimary = ISNULL(ls.IsPrimary, 0),
                    @IsActive = ISNULL(ls.IsActive, 1),
                    @IsDeleted = ISNULL(ls.IsDeleted, 0),
                    @MasterCompanyId = ls.MasterCompanyId,
                    @SiteName = ls.SiteName,
                    @Attention = ls.Attention,
                    @CreatedDate = ls.CreatedDate
                FROM dbo.LegalEntityShippingAddress ls WITH (NOLOCK)
                WHERE ls.LegalEntityShippingAddressId = @BillingShippingId;
            END
            ELSE IF @AddressType = @BillingAddressId  
            BEGIN
                SELECT 
                    @AuditAddressId = lb.LegalEntityBillingAddressId,  
                    @AddressId = lb.AddressId,
                    @IsPrimary = ISNULL(lb.IsPrimary, 0),
                    @IsActive = ISNULL(lb.IsActive, 1),
                    @IsDeleted = ISNULL(lb.IsDeleted, 0),
                    @MasterCompanyId = lb.MasterCompanyId,
                    @SiteName = lb.SiteName,
                    @Attention = lb.Attention,
                    @CreatedDate = lb.CreatedDate
                FROM dbo.LegalEntityBillingAddress lb WITH (NOLOCK)
                WHERE lb.LegalEntityBillingAddressId = @BillingShippingId;
            END
        END

        IF @AddressId IS NOT NULL
        BEGIN
            SELECT 
                @Line1 = Line1,
                @Line2 = Line2,
                @City = City,
                @StateOrProvince = StateOrProvince,
                @CountryId = CountryId,
                @PostalCode = PostalCode
            FROM dbo.Address WITH (NOLOCK)
            WHERE AddressId = @AddressId;
        END

        INSERT INTO dbo.ShippingBillingAddressAudit
        (
            AddressId,
            AddressType,
            IsPrimary,
            IsActive,
            MasterCompanyId,
            ModuleId,
            ReferenceId,
            SiteName,
            ContactTagId,
            Attention,
            CreatedBy,
            UpdatedBy,
            CreatedDate,
            UpdatedDate,
            IsDeleted,
            Line1,
            Line2,
            City,
            StateOrProvince,
            CountryId,
            PostalCode
        )
        VALUES
        (
            @AuditAddressId,  
            @AddressType,
            @IsPrimary,
            @IsActive,
            @MasterCompanyId,
            @ModuleId,
            @ReferenceId,
            @SiteName,
            @ContactTagId,
            @Attention,
            @UpdatedBy,
            @UpdatedBy,
            @CreatedDate,
            GETUTCDATE(),
            @IsDeleted,
            @Line1,
            @Line2,
            @City,
            @StateOrProvince,
            @CountryId,
            @PostalCode
        );

    END TRY

    BEGIN CATCH
        DECLARE @ErrorLogID INT, 
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = 'USP_ShippingBillingAddressHistory',
                @ProcedureParameters VARCHAR(3000) = '',
                @ApplicationName VARCHAR(100) = 'PAS';
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC dbo.spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred. Inform Support with Error Number: %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END
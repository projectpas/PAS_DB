/*************************************************************           
** File:      [USP_UpdateVendorShippingAddressActiveStatus] 
** Author:    Ayushi Patel  
** Description: Update IsActive status of Vendor Shipping Address and call audit history
** Date:      14-07-2025  
**************************************************************           
** Change History           
**************************************************************           
** PR     Date         Author         Change Description            
** --     ----------   ------------   ------------------------------          
** 1      14-07-2025   Ayushi Patel   Created  
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateVendorShippingAddressActiveStatus]
    @VendorShippingAddressId BIGINT,
    @IsActive BIT,
    @UpdatedBy VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
       DECLARE @VendorModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Vendor');
	   DECLARE @ShippingAddress INT = 2;
        UPDATE dbo.VendorShippingAddress
        SET 
            IsActive = @IsActive,
            UpdatedBy = @UpdatedBy,
            UpdatedDate = GETUTCDATE()
        WHERE VendorShippingAddressId = @VendorShippingAddressId;

        DECLARE @VendorId BIGINT;

        SELECT @VendorId = VendorId
        FROM dbo.VendorShippingAddress WITH (NOLOCK)
        WHERE VendorShippingAddressId = @VendorShippingAddressId;

        IF @VendorId IS NOT NULL
        BEGIN
            EXEC dbo.USP_ShippingBillingAddressHistory 
                @VendorId,
                @VendorModuleId,  -- ModuleEnum.Vendor
                @VendorShippingAddressId,
                @ShippingAddress,  -- AddressTypeEnum.ShippingAddress
                @UpdatedBy;
        END

        SELECT 
            VendorShippingAddressId,
            VendorId,
            SiteName,
            AddressId,
            ISNULL(IsPrimary,0) AS IsPrimary,
            Attention,
            ContactTagId,
            MasterCompanyId,
            CreatedBy,
            CreatedDate,
            UpdatedBy,
            UpdatedDate,
            ISNULL(IsActive,0) AS IsActive,
            ISNULL(IsDeleted,0) AS IsDeleted
        FROM dbo.VendorShippingAddress WITH (NOLOCK)
        WHERE VendorShippingAddressId = @VendorShippingAddressId;
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000), @ErrSeverity INT;
        SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity = ERROR_SEVERITY();
        RAISERROR(@ErrMsg, @ErrSeverity, 1);
    END CATCH
END
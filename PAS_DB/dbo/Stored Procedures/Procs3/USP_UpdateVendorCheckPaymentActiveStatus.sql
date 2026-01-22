/*************************************************************           
** File:      [USP_UpdateVendorCheckPaymentActiveStatus] 
** Author:    Ayushi Patel  
** Description: Update IsActive status of Vendor Check Payment and call audit history
** Date:      10-07-2025  
**************************************************************           
** Change History           
**************************************************************           
** PR     Date         Author         Change Description            
** --     ----------   ------------   ------------------------------          
** 1      10-07-2025   Ayushi Patel   Created  
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateVendorCheckPaymentActiveStatus]
    @CheckPaymentId BIGINT,
    @IsActive BIT,
    @UpdatedBy VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
	DECLARE @VendorModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Vendor');
	DECLARE @CheckPayment INT = 3;
        
		UPDATE DBO.VendorCheckPayment
        SET 
            IsActive = @IsActive,
            UpdatedDate = GETUTCDATE(),
            UpdatedBy = @UpdatedBy
        WHERE CheckPaymentId = @CheckPaymentId;

        DECLARE @VendorId BIGINT;

        SELECT @VendorId = VendorId
        FROM VendorCheckPayment WITH(NOLOCK)
        WHERE CheckPaymentId = @CheckPaymentId;

        IF @VendorId IS NOT NULL
        BEGIN
            EXEC dbo.USP_ShippingBillingAddressHistory 
                @VendorId,
                @VendorModuleId,                        
                @CheckPaymentId,
                @CheckPayment,                       
                @UpdatedBy;
        END

		SELECT 
            VendorCheckPaymentId,
            VendorId,
            CheckPaymentId,
            MasterCompanyId,
            CreatedBy,
            CreatedDate,
            UpdatedBy,
            UpdatedDate,
            ISNULL(IsActive,0) AS IsActive,
            ISNULL(IsDeleted,0) AS IsDeleted
        FROM VendorCheckPayment WITH(NOLOCK)
        WHERE CheckPaymentId = @CheckPaymentId;
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000), @ErrSeverity INT;
        SELECT 
            @ErrMsg = ERROR_MESSAGE(),
            @ErrSeverity = ERROR_SEVERITY();
        RAISERROR(@ErrMsg, @ErrSeverity, 1);
    END CATCH
END
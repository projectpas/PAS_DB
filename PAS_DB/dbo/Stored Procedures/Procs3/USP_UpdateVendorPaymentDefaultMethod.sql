/****************************************************************************************** 
** File:        [USP_UpdateVendorPaymentDefaultMethod]
** Author:      Ayushi Patel
** Description: update Vendor Payment Default.
** Date:        18-07-2025
*******************************************************************************************
** Change History
*******************************************************************************************
** PR     Date         Author         Change Description
** --     ----------   ------------   -----------------------------------------------------
** 1      18-07-2025   Ayushi Patel   Created
*******************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateVendorPaymentDefaultMethod]
    @VendorPaymentId BIGINT,
    @VendorId BIGINT,
    @DefaultPaymentMethod NVARCHAR(100),
    @MasterCompanyId INT,
    @UpdatedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        UPDATE DBO.VendorPayment
        SET 
            VendorId = @VendorId,
            DefaultPaymentMethod = @DefaultPaymentMethod,
            MasterCompanyId = @MasterCompanyId,
            UpdatedBy = @UpdatedBy,
            UpdatedDate = GETUTCDATE()
        WHERE VendorPaymentId = @VendorPaymentId;

        SELECT 
            VendorPaymentId,
            VendorId,
            DefaultPaymentMethod,
            MasterCompanyId,
			CreatedBy,
            UpdatedBy,
            UpdatedDate,
            ISNULL(IsActive,0) AS IsActive,
            ISNULL(IsDeleted,0) AS IsDeleted
        FROM DBO.VendorPayment WITH (NOLOCK)
        WHERE VendorPaymentId = @VendorPaymentId;
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        RAISERROR(@ErrMsg, @ErrSeverity, 1);
    END CATCH
END
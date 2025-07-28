/****************************************************************************************** 
** File:        [USP_AddVendorInternationalWirePayment]
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
CREATE PROCEDURE [dbo].[USP_AddVendorInternationalWirePayment]
    @InternationalWirePaymentId BIGINT,
    @VendorId BIGINT,
    @MasterCompanyId INT,
    @IsActive BIT,
    @CreatedBy NVARCHAR(100),
    @UpdatedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO DBO.VendorInternationlWirePayment
        (
            InternationalWirePaymentId,
            VendorId,
            MasterCompanyId,
            IsActive,
            CreatedBy,
            CreatedDate,
            UpdatedBy,
            UpdatedDate,
            IsDeleted
        )
        VALUES
        (
            @InternationalWirePaymentId,
            @VendorId,
            @MasterCompanyId,
            @IsActive,
            @CreatedBy,
            GETUTCDATE(),
            @UpdatedBy,
            GETUTCDATE(),
            0
        );

        SELECT SCOPE_IDENTITY() AS NewId;
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH
END
/****************************************************************************************** 
** File:        [USP_CreateVendorPaymentDefaultMethod]
** Author:      Ayushi Patel
** Description: Create Vendor Payment Default.
** Date:        18-07-2025
*******************************************************************************************
** Change History
*******************************************************************************************
** PR     Date         Author         Change Description
** --     ----------   ------------   -----------------------------------------------------
** 1      18-07-2025   Ayushi Patel   Created
*******************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateVendorPaymentDefaultMethod]
    @VendorPaymentId BIGINT OUTPUT,
    @VendorId BIGINT,
    @DefaultPaymentMethod NVARCHAR(100),
    @MasterCompanyId INT,
    @CreatedBy NVARCHAR(100),
    @UpdatedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @CreatedDate DATETIME = GETUTCDATE();
        DECLARE @UpdatedDate DATETIME = GETUTCDATE();

        INSERT INTO DBO.VendorPayment
        (
            VendorId,
            DefaultPaymentMethod,
            MasterCompanyId,
            CreatedBy,
            CreatedDate,
            UpdatedBy,
            UpdatedDate,
            IsActive,
            IsDeleted
        )
        VALUES
        (
            @VendorId,
            @DefaultPaymentMethod,
            @MasterCompanyId,
            @CreatedBy,
            @CreatedDate,
            @UpdatedBy,
            @UpdatedDate,
            1, 
            0  
        );

        SET @VendorPaymentId = SCOPE_IDENTITY();

        SELECT 
            VendorPaymentId,
            VendorId,
            DefaultPaymentMethod,
            MasterCompanyId,
            CreatedBy,
            CreatedDate,
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
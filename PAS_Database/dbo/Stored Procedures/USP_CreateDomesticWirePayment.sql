/****************************************************************************************** 
** File:        [USP_CreateDomesticWirePayment]
** Author:      Ayushi Patel
** Description: Update International Wire Payment record for a Vendor, including Address.
** Date:        17-07-2025
*******************************************************************************************
** Change History
*******************************************************************************************
** PR     Date         Author         Change Description
** --     ----------   ------------   -----------------------------------------------------
** 1      17-07-2025   Ayushi Patel   Created
*******************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateDomesticWirePayment]
    @VendorId BIGINT,
    @DomesticWirePaymentId BIGINT,
    @MasterCompanyId BIGINT,
    @CreatedBy NVARCHAR(100),
    @UpdatedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @CreatedDate DATETIME = GETDATE();
        DECLARE @UpdatedDate DATETIME = GETDATE();

        INSERT INTO [dbo].[VendorDomesticWirePayment] (
            VendorId,
            DomesticWirePaymentId,
            MasterCompanyId,
            CreatedBy,
            UpdatedBy,
            CreatedDate,
            UpdatedDate,
            IsActive,
            IsDeleted
        )
        VALUES (
            @VendorId,
            @DomesticWirePaymentId,
            @MasterCompanyId,
            @CreatedBy,
            @UpdatedBy,
            @CreatedDate,
            @UpdatedDate,
            1,               -- IsActive
            0                -- IsDeleted
        );

        SELECT TOP 1 
            VendorDomesticWirePaymentId,
            VendorId,
            DomesticWirePaymentId,
            MasterCompanyId,
            CreatedBy,
            UpdatedBy,
            CreatedDate,
            UpdatedDate,
            IsActive,
            IsDeleted
        FROM [dbo].[VendorDomesticWirePayment]
        WHERE VendorDomesticWirePaymentId = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;

        DECLARE 
            @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME(),
            @AdhocComments VARCHAR(150) = '[USP_CreateDomesticWirePayment]',
            @ProcedureParameters VARCHAR(3000) = '',
            @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected Error Occurred. Please contact support. ErrorLogID: %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END
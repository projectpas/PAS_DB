/******************************************************************************************
** File:         [USP_AddUpdateVendorCheckPayment]
** Author:       Ayushi Patel
** Description:  Adds a record to VendorCheckPayment table.
** Date:         16-07-2025
*******************************************************************************************
** Change History
*******************************************************************************************
** PR     Date         Author         Change Description
** --     ----------   ------------   -----------------------------------------------------
** 1      16-07-2025   Ayushi Patel   Created
*******************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddUpdateVendorCheckPayment]
    @VendorId BIGINT,
    @CheckPaymentId BIGINT,
    @MasterCompanyId INT,
    @CreatedBy VARCHAR(100),
    @UpdatedBy VARCHAR(100),
    @CreatedDate DATETIME2 = NULL,
    @UpdatedDate DATETIME2 = NULL,
	@OutputVendorCheckPaymentId BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;


        INSERT INTO dbo.VendorCheckPayment (
            VendorId,
            CheckPaymentId,
            MasterCompanyId,
            IsActive,
            IsDeleted,
            CreatedBy,
            CreatedDate,
            UpdatedBy,
            UpdatedDate
        )
        VALUES (
            @VendorId,
            @CheckPaymentId,
            @MasterCompanyId,
            1,              -- IsActive = true
            0,              -- IsDeleted = false
            @CreatedBy,
            GETUTCDATE(),
            @UpdatedBy,
            GETUTCDATE()
        );
		 SET @OutputVendorCheckPaymentId = SCOPE_IDENTITY();
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_AddUpdateVendorCheckPayment',
                @ProcedureParameters VARCHAR(3000) = '',
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected error occurred. Refer to ErrorLogID: %d', 16, 1, @ErrorLogID);
    END CATCH
END
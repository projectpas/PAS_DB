
/***************************************************************  
** File:     USP_DeleteCheckPaymentById
** Author:   Ayushi Patel  
** Description: Soft delete check payment and vendor payment data  
**              and insert audit history for CheckPayment  
** Date:     07-Aug-2025  
***************************************************************  
** Change History  
***************************************************************  
** PR   Date         Author         Change Description  
** --   ----------   ------------   --------------------------------  
** 1    07-Aug-2025  Ayushi Patel   Created 
***************************************************************/
CREATE   PROCEDURE [dbo].[USP_DeleteCheckPaymentById]
    @CheckPaymentId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @VendorId BIGINT,
                @UpdatedBy NVARCHAR(100);
		Declare @VendorModuleId BIGINT = (SELECT AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) where Name = 'Vendor')
		Declare @CheckPaymentAddressType BIGINT = 3;
        SELECT 
            @VendorId = VendorId,
            @UpdatedBy = UpdatedBy
        FROM DBO.VendorCheckPayment WITH(NOLOCK)
        WHERE CheckPaymentId = @CheckPaymentId;

        UPDATE DBO.VendorPayment
        SET 
            IsDeleted = 1,
            UpdatedDate = GETUTCDATE()
        WHERE VendorPaymentId = @CheckPaymentId;

        UPDATE DBO.VendorCheckPayment
        SET 
            IsDeleted = 1,
            UpdatedDate = GETUTCDATE()
        WHERE CheckPaymentId = @CheckPaymentId;

        EXEC [dbo].[USP_ShippingBillingAddressHistory]
            @ReferenceId = @VendorId,
            @ModuleId = @VendorModuleId, 
            @BillingShippingId = @CheckPaymentId,
            @AddressType = @CheckPaymentAddressType,
            @UpdatedBy = @UpdatedBy;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH  
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE @ErrorLogID int,    
			@DatabaseName varchar(100) = DB_NAME()    
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
			,@AdhocComments varchar(150) = 'USP_DeleteCheckPaymentById',    
			@ProcedureParameters varchar(3000) = '',    
			@ApplicationName varchar(100) = 'PAS'    
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
			EXEC spLogException @DatabaseName = @DatabaseName,    
				@AdhocComments = @AdhocComments,    
				@ProcedureParameters = @ProcedureParameters,    
				@ApplicationName = @ApplicationName,    
				@ErrorLogID = @ErrorLogID OUTPUT;    
			RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
	END CATCH 
END
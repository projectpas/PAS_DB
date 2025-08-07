
/***************************************************************  
 ** File:     USP_DeleteVendorContactByContactId     
 ** Author:   Ayushi Patel  
 ** Description: Soft delete a vendor contact by ContactId and log audit history  
 ** Date:     07-Aug-2025  
 ***************************************************************  
 ** Change History  
 ***************************************************************  
 ** PR   Date         Author         Change Description  
 ** --   ----------   ------------   --------------------------------  
 ** 1    07-Aug-2025  Ayushi Patel   Created 
 ***************************************************************/
CREATE   PROCEDURE [dbo].[USP_DeleteVendorContactByContactId]
    @ContactId BIGINT,
    @UpdatedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @VendorContactId BIGINT, @VendorId BIGINT;
		Declare @VendorModuleId BIGINT = (SELECT AttachmentModuleId FROM AttachmentModule where Name = 'Vendor')
        
        IF EXISTS (SELECT 1 FROM VendorContact WITH(NOLOCK) WHERE ContactId = @ContactId AND IsDeleted = 0)
        BEGIN
           
            UPDATE VendorContact
            SET 
                IsDeleted = 1,
                UpdatedBy = @UpdatedBy,
                UpdatedDate = GETUTCDATE()
            WHERE ContactId = @ContactId;

            
            SELECT 
                @VendorContactId = VendorContactId,
                @VendorId = VendorId
            FROM VendorContact WITH(NOLOCK)
            WHERE ContactId = @ContactId;

           
            EXEC [dbo].[USP_ContactsHistory] 
                @ReferenceId = @VendorId,
                @ModuleId = @VendorModuleId, 
                @ContactId = @VendorContactId,
                @UpdatedBy = @UpdatedBy;
        END
        ELSE
        BEGIN
            RAISERROR('VendorContact with provided ContactId not found or already deleted.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

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
			,@AdhocComments varchar(150) = 'USP_DeleteVendorContactByContactId',    
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
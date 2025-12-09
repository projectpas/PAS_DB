/*************************************************************
** File:     [USP_UpdateVendorContact]
** Author:   Bhargav Saliya
** Description: Update Vendor Contact
** Purpose:  
** Date:     02-07-2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author         Change Description
** --   ----------   ------------   --------------------------------
** 1    08-12-2025   Bhargav Saliya   Created

-- EXEC [USP_UpdateVendorContact] @VendorId = 5428,@VendorEmail = 'testing55555@gmail.com',@VendorPhone = '6543210',@VendorPhoneExt = '22',@UpdatedBy='Admin'
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateVendorContact] 
    @VendorId BIGINT,
	@VendorEmail NVARCHAR(100),
	@VendorPhone NVARCHAR(50),
	@VendorPhoneExt NVARCHAR(50),
	@UpdatedBy NVARCHAR(100)
AS
BEGIN
BEGIN TRY
	
	IF(ISNULL(@VendorEmail,'') <> '' OR ISNULL(@VendorPhone,'') <> '')
	BEGIN
		DECLARE @ContactId BIGINT,@IsDefaultContact BIT;
		DECLARE @ContactEmail NVARCHAR(100),@ContactPhone NVARCHAR(50),@ContactWorkPhoneExtn NVARCHAR(50),@cContactId BIGINT;

		SELECT @ContactId = ContactId,@IsDefaultContact = IsDefaultContact FROM dbo.VendorContact vc WITH(NOLOCK) WHERE vc.VendorId = @VendorId AND ISNULL(vc.IsDefaultContact,0) = 1;

		SELECT @cContactId = ContactId,@ContactEmail = Email, @ContactPhone = WorkPhone,@ContactWorkPhoneExtn = WorkPhoneExtn FROM dbo.Contact C WITH(NOLOCK) WHERE C.ContactId = @ContactId AND ISNULL(@IsDefaultContact,0) = 1

		IF(@cContactId > 0)
		BEGIN
			IF(ISNULL(@ContactEmail,'') = '' AND ISNULL(@ContactPhone,'') = '')
			BEGIN
				UPDATE C
				SET Email = @VendorEmail,
					WorkPhone = @VendorPhone,
					UpdatedDate = GETUTCDATE(),
					UpdatedBy = @UpdatedBy,
					WorkPhoneExtn = CASE WHEN ISNULL(@ContactWorkPhoneExtn,'') = '' THEN @VendorPhoneExt ELSE @ContactWorkPhoneExtn END
				FROM dbo.Contact C WITH(NOLOCK)
				WHERE C.ContactId = @cContactId
			END
			ELSE
			BEGIN
				IF(ISNULL(@ContactEmail,'') = '' AND ISNULL(@VendorEmail,'') <> '')
				BEGIN
					UPDATE C
					SET Email = @VendorEmail,
						UpdatedDate = GETUTCDATE(),
						UpdatedBy = @UpdatedBy,
						WorkPhoneExtn = CASE WHEN ISNULL(@ContactWorkPhoneExtn,'') <> '' THEN @ContactWorkPhoneExtn ELSE @VendorPhoneExt END
					FROM dbo.Contact C WITH(NOLOCK)
					WHERE C.ContactId = @cContactId
				END
				ELSE IF(ISNULL(@ContactPhone,'') = '' OR ISNULL(@VendorPhoneExt,'') = '')
				BEGIN
					UPDATE C
					SET WorkPhone = CASE WHEN ISNULL(@ContactPhone,'') <> '' THEN @ContactPhone ELSE @VendorPhone END,
						UpdatedDate = GETUTCDATE(),
						UpdatedBy = @UpdatedBy,
						WorkPhoneExtn = CASE WHEN ISNULL(@ContactWorkPhoneExtn,'') <> '' THEN @ContactWorkPhoneExtn ELSE @VendorPhoneExt END
					FROM dbo.Contact C WITH(NOLOCK)
					WHERE C.ContactId = @cContactId
				END
			END
		END
	END
END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_UpdateVendorContact',
                @ProcedureParameters VARCHAR(3000) = '@VendorId = ' + CAST(@VendorId AS VARCHAR) + 
													 ',@VendorEmail = ' + CAST(@VendorEmail AS VARCHAR) +
													 ',@VendorPhone = ' + CAST(@VendorPhone AS VARCHAR) +
													 ',@VendorPhoneExt = ' + CAST(@VendorPhoneExt AS VARCHAR) +
													 ',@UpdatedBy = ' + CAST(@UpdatedBy AS VARCHAR),
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END
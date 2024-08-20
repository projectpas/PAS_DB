/******************************************
 ** File:   [USP_CheckEmailContactExistsForVendor]               
 ** Author:  AMIT GHEDIYA    
 ** Description:  This Store Procedure use to check vendor emial & phone is exists.   
 ** Purpose:             
 ** Date:   08/14/2024          
              
 ** RETURN VALUE:               
 ********************               
 ** check customer emial & phone exists.             
 ********************               
 ** PR   Date			Author					Change Description                
 ** --   --------		-------					--------------------------------              
    1    08/14/2024  	Devendra Shekh			Created     
    2    08/20/2024  	Devendra Shekh			added @VendorContactId param     
 
 EXEC [USP_CheckEmailContactExistsForVendor] 12
*********************************************/ 
CREATE   PROCEDURE [dbo].[USP_CheckEmailContactExistsForVendor]
	@VendorId BIGINT = 0,
	@VendorContactId BIGINT NULL = 0
AS
BEGIN
		BEGIN TRY
			
			DECLARE @ReturnStatus INT = 0,
					@ExistingCustomerPhone VARCHAR(100),
					@ExistingContactPhone VARCHAR(100),
					@ExistingEmail VARCHAR(100),
					@ExistingContactEmail VARCHAR(100),
					@ContactId BIGINT,
					@ReturnMsg VARCHAR(150) = 'Contact number or email details missing.';
			
			--Get Email & Phone from Customer Primary Comtact details.
			SELECT @ContactId = [ContactId] FROM [dbo].[VendorContact] WITH(NOLOCK) WHERE [VendorId] = @VendorId AND [IsDefaultContact] = 1;
			IF(ISNULL(@VendorContactId, 0) > 0)
			BEGIN
				SELECT @ExistingContactPhone = [WorkPhone], @ExistingContactEmail = [Email] FROM [dbo].[contact] WITH(NOLOCK) WHERE [ContactId] = @VendorContactId;
			END
			ELSE
			BEGIN
				SELECT @ExistingContactPhone = [WorkPhone], @ExistingContactEmail = [Email] FROM [dbo].[contact] WITH(NOLOCK) WHERE [ContactId] = @ContactId;
			END

			--Get Email & Phone from Customer details.
			SELECT @ExistingCustomerPhone = [VendorPhone], @ExistingEmail = [VendorEmail] FROM [dbo].[Vendor] WITH(NOLOCK) WHERE [VendorId] = @VendorId AND [IsActive] = 1 AND [IsDeleted] = 0;
			IF(ISNULL(@ExistingCustomerPhone,'') = '' OR ISNULL(@ExistingContactPhone,'') = '')
			BEGIN
				 SET @ReturnStatus = -1;
				 SET @ReturnMsg = @ReturnMsg;
			END
			ELSE IF(ISNULL(@ExistingEmail,'') = '' OR ISNULL(@ExistingContactEmail,'') = '')
			BEGIN
				 SET @ReturnStatus = -1;
				 SET @ReturnMsg = @ReturnMsg;
			END
			ELSE
			BEGIN
				 SET @ReturnStatus = 1;
				 SET @ReturnMsg = '';
			END

			SELECT @ReturnStatus AS Status, @ReturnMsg AS Msg;

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CheckEmailContactExistsForVendor' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END
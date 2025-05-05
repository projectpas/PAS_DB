/*************************************************************           
 ** File:		 [USP_SaveVendorRMASettings]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Save Vendor RMA Settings.
 ** Purpose:         
 ** Date:   22-April-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    22-April-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_SaveVendorRMASettings] @VendorRMASettingId=0,@EnforcePickTicketConfirmation=0,@MasterCompanyId=1,@CreatedBy=N'DANE PERK',@CreatedDate='2025-04-22 11:15:07.360',
 @UpdatedBy=N'DANE PERK',@UpdatedDate='2025-04-22 11:15:07.360',@IsActive=1,@IsDeleted=0
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_SaveVendorRMASettings]
@VendorRMASettingId BIGINT = 0,
@EnforcePickTicketConfirmation BIT = 0,
@MasterCompanyId INT,
@CreatedBy VARCHAR(256),
@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

		IF(ISNULL(@VendorRMASettingId, 0) = 0)
		BEGIN			
			
			INSERT INTO [DBO].[VendorRMASettings]([EnforcePickTicketConfirmation], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
			VALUES (@EnforcePickTicketConfirmation, @MasterCompanyId, @CreatedBy, GETUTCDATE(), @UpdatedBy,  GETUTCDATE(), 1, 0)		

		END
		ELSE
		BEGIN

			UPDATE [DBO].[VendorRMASettings] 
			SET	[EnforcePickTicketConfirmation]=@EnforcePickTicketConfirmation, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [VendorRMASettingId] = @VendorRMASettingId AND [MasterCompanyId] = @MasterCompanyId		

		END

	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0  
		PRINT 'ROLLBACK'  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_SaveVendorRMASettings'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END
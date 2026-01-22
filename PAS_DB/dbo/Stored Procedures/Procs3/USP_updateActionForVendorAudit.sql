/***************************************************************
 ** File:   [USP_updateActionForVendorAudit]
 ** Author:   Bhargav Saliya
 ** Description: This stored procedure is used to add update Vendor Audit Info
 ** Date:  24-03-2025
            
  ** Change History
 **************************************************************             
 ** PR   Date				Author  		Change Description              
 ** --   --------			-------			--------------------------------            
    1    24-03-2025			 Bhargav Saliya		Created

**************************************************************/
CREATE      PROCEDURE [dbo].[USP_updateActionForVendorAudit]
	@VendorAuditInfoId BIGINT,
	@ActionPerform VARCHAR(256) = NULL,
	@UpdatedBy VARCHAR(256) = NULL
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY
		
		IF(@ActionPerform = 'isDelete')
		BEGIN
			UPDATE VendorAuditInfo
			SET 
			IsDeleted = 1,
			UpdatedDate = GETUTCDATE(),
			UpdatedBy = CASE WHEN @UpdatedBy IS NOT NULL THEN @UpdatedBy ELSE UpdatedBy END
			WHERE VendorAuditInfoId = @VendorAuditInfoId;
		END
		ELSE IF(@ActionPerform = 'isRestore')
		BEGIN
			UPDATE VendorAuditInfo
			SET 
			IsDeleted = 0,
			UpdatedDate = GETUTCDATE(),
			UpdatedBy = CASE WHEN @UpdatedBy IS NOT NULL THEN @UpdatedBy ELSE UpdatedBy END
			WHERE VendorAuditInfoId = @VendorAuditInfoId;
		END
		ELSE IF(@ActionPerform = 'isActive')
		BEGIN
			UPDATE VendorAuditInfo
			SET 
			IsActive = 1,
			UpdatedDate = GETUTCDATE(),
			UpdatedBy = CASE WHEN @UpdatedBy IS NOT NULL THEN @UpdatedBy ELSE UpdatedBy END
			WHERE VendorAuditInfoId = @VendorAuditInfoId;
		END
		ELSE IF(@ActionPerform = 'isInActive')
		BEGIN
			UPDATE VendorAuditInfo
			SET 
			IsActive = 0,
			UpdatedDate = GETUTCDATE(),
			UpdatedBy = CASE WHEN @UpdatedBy IS NOT NULL THEN @UpdatedBy ELSE UpdatedBy END
			WHERE VendorAuditInfoId = @VendorAuditInfoId;
		END

	END TRY   
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_updateActionForVendorAudit'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = '', '
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);           
	END CATCH
END;
/*************************************************************           
 ** File:   [USP_UpdateROTemplateStatus]           
 ** Author:   Amit Ghediya
 ** Description: This stored procedure is used to add update Ro Template List
 ** Purpose:         
 ** Date:   06-05-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          -------------------           
    1    06-05-2025		Amit Ghediya       Created    

**************************************************************/ 
CREATE    PROCEDURE [dbo].[USP_UpdateROTemplateStatus]
	@RepairOrderTemplateId BIGINT,
	@ActionPerform VARCHAR(256) = NULL,
	@UpdatedBy VARCHAR(256) = NULL
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY
		
		IF(@ActionPerform = 'isDelete')
		BEGIN
			UPDATE [dbo].[RepairOrderTemplate]
			SET 
			IsDeleted = 1,
			UpdatedDate = GETUTCDATE(),
			UpdatedBy = CASE WHEN @UpdatedBy IS NOT NULL THEN @UpdatedBy ELSE UpdatedBy END
			WHERE [RepairOrderTemplateId] = @RepairOrderTemplateId;
		END
		ELSE IF(@ActionPerform = 'isRestore')
		BEGIN
			UPDATE [dbo].[RepairOrderTemplate]
			SET 
			IsDeleted = 0,
			UpdatedDate = GETUTCDATE(),
			UpdatedBy = CASE WHEN @UpdatedBy IS NOT NULL THEN @UpdatedBy ELSE UpdatedBy END
			WHERE [RepairOrderTemplateId] = @RepairOrderTemplateId;
		END
		ELSE IF(@ActionPerform = 'isActive')
		BEGIN
			UPDATE [dbo].[RepairOrderTemplate]
			SET 
			IsActive = 1,
			UpdatedDate = GETUTCDATE(),
			UpdatedBy = CASE WHEN @UpdatedBy IS NOT NULL THEN @UpdatedBy ELSE UpdatedBy END
			WHERE [RepairOrderTemplateId] = @RepairOrderTemplateId;
		END
		ELSE IF(@ActionPerform = 'isInActive')
		BEGIN
			UPDATE [dbo].[RepairOrderTemplate]
			SET 
			IsActive = 0,
			UpdatedDate = GETUTCDATE(),
			UpdatedBy = CASE WHEN @UpdatedBy IS NOT NULL THEN @UpdatedBy ELSE UpdatedBy END
			WHERE [RepairOrderTemplateId] = @RepairOrderTemplateId;
		END

	END TRY   
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_UpdateROTemplateStatus'
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
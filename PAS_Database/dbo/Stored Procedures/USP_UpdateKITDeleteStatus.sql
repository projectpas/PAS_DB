/*************************************************************           
 ** File:		[dbo].[USP_UpdateKITDeleteStatus]          
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used To Delete Kit in the Kit List 
 ** Purpose:         
 ** Date:    27-10-2025   
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
	1	 27-10-2025           Nakul Chandigra     Created 
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_UpdateKITDeleteStatus]
@KitId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		BEGIN TRANSACTION
	BEGIN
		
		UPDATE dbo.KitMaster
		SET 
			IsDeleted = 1,
			UpdatedDate = GETUTCDATE()
		WHERE KitId = @Kitid;

	EXEC [dbo].[usp_SaveKITMasterHistory] @Kitid 

	END
	COMMIT  TRANSACTION
    END TRY
	BEGIN CATCH
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = '[dbo].[USP_UpdateKITDeleteStatus]'
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
	END CATCH

END

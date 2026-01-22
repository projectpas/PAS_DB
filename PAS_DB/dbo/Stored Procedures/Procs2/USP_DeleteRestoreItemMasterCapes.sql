/*************************************************************           
 ** File:		 [USP_DeleteRestoreLegalEntityContact]           
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used To Delete Or Restore ItemMasterCapes
 ** Purpose:         
 ** Date:   26-09-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
	1	26-09-2025           Nakul Chandigra     Created 
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_DeleteRestoreItemMasterCapes]
@itemMasterCapesId BIGINT,
@updatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

	DECLARE @IsDELETE BIT

	SELECT @IsDELETE = ISNULL(IsDeleted, 0)
	FROM [dbo].[itemMasterCapes] WITH (NOLOCK)
	WHERE ItemMasterCapesId = @itemMasterCapesId

	IF (@IsDELETE = 0)
	BEGIN
		UPDATE [dbo].[itemMasterCapes]	
		SET [IsDeleted] = 1 ,
			[UpdatedDate] = GETUTCDATE(),
			[UpdatedBy] = @updatedBy
		WHERE ItemMasterCapesId = @itemMasterCapesId
	END
	ELSE
	BEGIN
		UPDATE [dbo].[itemMasterCapes]	
		SET [IsDeleted] = 0 ,
			[UpdatedDate] = GETUTCDATE(),
			[UpdatedBy] = @updatedBy
		WHERE ItemMasterCapesId = @itemMasterCapesId
	END
	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = '[dbo].[USP_DeleteRestoreItemMasterCapes]'
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
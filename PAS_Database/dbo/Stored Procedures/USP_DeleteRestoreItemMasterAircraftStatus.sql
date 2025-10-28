/*************************************************************           
 ** File:		 [dbo].[USP_DeleteRestoreItemMasterAircraftStatus]         
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used To Delete And Restore ItemMasterAircraft
 ** Purpose:         
 ** Date:   25-09-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
	1	 26-09-2025			 Nakul Chandigra	 Created
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_DeleteRestoreItemMasterAircraftStatus]
@MappingId BIGINT 
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

	DECLARE @DELETE BIT;
	SELECT @DELETE = ISNULL([IsDeleted], 0)
	FROM [dbo].[ItemMasterAircraftMapping] WITH (NOLOCK)
	WHERE ItemMasterAircraftMappingId = @MappingId
	
	IF (@DELETE = 0)
	BEGIN
		UPDATE [dbo].[ItemMasterAircraftMapping]	
		SET [IsDeleted] = 1 ,[UpdatedDate] = GETUTCDATE()
		WHERE [ItemMasterAircraftMappingId] = @MappingId
	END
	IF (@DELETE = 1)
	BEGIN 
		UPDATE [dbo].[ItemMasterAircraftMapping]	
		SET [IsDeleted] = 0 ,[UpdatedDate] = GETUTCDATE()
		WHERE [ItemMasterAircraftMappingId] = @MappingId
	END	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_DeleteRestoreItemMasterAircraftStatus'
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

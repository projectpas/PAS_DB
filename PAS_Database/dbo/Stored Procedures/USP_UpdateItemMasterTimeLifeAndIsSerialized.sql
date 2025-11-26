/*************************************************************           
 ** File:		[dbo].[USP_UpdateItemMasterTimeLifeAndIsSerialized]          
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used To updateItemMasterTimeLife And IsSerialized
 ** Purpose:         
 ** Date:   26-11-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
	1	26-11-2025           Nakul Chandigra     Created 
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_UpdateItemMasterTimeLifeAndIsSerialized]
@ItemMasterId BIGINT,
@Active BIT,    
@IsSerialize BIT 
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		
		IF( @IsSerialize = 1 )
		BEGIN
			UPDATE [dbo].[ItemMaster]
			SET 
				IsSerialized = @Active
			WHERE [ItemMasterId]  = @ItemMasterId
		END
		ELSE 	
		BEGIN 
			UPDATE [dbo].[ItemMaster]
			SET 
				IsTimeLife = @Active
			WHERE [ItemMasterId]  = @ItemMasterId
		END

    END TRY
	BEGIN CATCH
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = '[dbo].[USP_UpdateItemMasterTimeLifeAndIsSerialized]'
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
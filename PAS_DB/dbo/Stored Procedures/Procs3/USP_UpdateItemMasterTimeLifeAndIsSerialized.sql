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
	2	28-07-2026           Abhishek Jirawala   When IsTimeLife is turned on, cascade IsStkTimeLife = 1 to all StockLines of this ItemMaster with QuantityOnHand > 0
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_UpdateItemMasterTimeLifeAndIsSerialized]
@ItemMasterId BIGINT,
@ISActiveOrInActive BIT,
@IsSerializeOrIsTimeLife BIT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		IF( @IsSerializeOrIsTimeLife = 1 )
		BEGIN
			UPDATE [dbo].[ItemMaster]
			SET
				IsSerialized = @ISActiveOrInActive
			WHERE [ItemMasterId]  = @ItemMasterId
		END
		ELSE
		BEGIN
			UPDATE [dbo].[ItemMaster]
			SET
				IsTimeLife = @ISActiveOrInActive
			WHERE [ItemMasterId]  = @ItemMasterId

			IF (@ISActiveOrInActive = 1)
			BEGIN
				UPDATE sl
				SET sl.IsStkTimeLife = 1,
					sl.UpdatedDate = GETUTCDATE()
				FROM [dbo].[StockLine] sl
				WHERE sl.ItemMasterId = @ItemMasterId
				  AND sl.QuantityOnHand > 0
				  AND ISNULL(sl.IsDeleted, 0) = 0
				  AND ISNULL(sl.IsStkTimeLife, 0) = 0
			END
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
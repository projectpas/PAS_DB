/*************************************************************           
 ** File:		 [USP_DeleteNonStockItemMaster]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Delete NonStock ItemMaster by Id.
 ** Purpose:         
 ** Date:   26-September-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date					Author				Change Description            
 ** --   -----------------		----------------	--------------------------------          
    1    26-September-2025		Divyesh Kathiriya	Created	
    
 -- EXEC [USP_DeleteNonStockItemMaster] @ItemMasterNonStockId=1, @UpdatedBy=N'DANE PERK', @IsDeleted=1
**************************************************************/
Create   PROCEDURE [DBO].[USP_DeleteNonStockItemMaster]
@ItemMasterNonStockId BIGINT,
@UpdatedBy VARCHAR(256),
@IsDeleted BIT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

	DECLARE @MasterPartId AS BIGINT;
	SELECT @MasterPartId = [MasterPartId] FROM [DBO].[ItemMasterNonStock] WITH(NOLOCK) WHERE [ItemMasterNonStockId] = @ItemMasterNonStockId;	

		IF EXISTS (SELECT 1 FROM [DBO].[ItemMasterNonStock] WITH(NOLOCK) WHERE [ItemMasterNonStockId] = @ItemMasterNonStockId)
		BEGIN
			UPDATE [DBO].[MasterParts] 
			SET	[IsDeleted] = ISNULL(@IsDeleted, 0), [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [MasterPartId] = @MasterPartId;

			UPDATE [DBO].[ItemMasterNonStock] 
			SET	[IsDeleted] = ISNULL(@IsDeleted, 0), [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [ItemMasterNonStockId] = @ItemMasterNonStockId;			
		END	

	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_DeleteNonStockItemMaster'
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
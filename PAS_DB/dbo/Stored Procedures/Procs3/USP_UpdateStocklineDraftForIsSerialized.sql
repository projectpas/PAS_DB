/*************************************************************               
 ** File:   [USP_UpdateStocklineDraftForIsSerialized]              
 ** Author:   Shrey Chandegara   
 ** Description: This stored procedure is used to Update stockline draft for timelife
 ** Purpose:             
 ** Date:   11-04-2024            
              
 ** PARAMETERS:    
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author				Change Description                
 ** --   --------     -------			--------------------------------              
    1    11-04-2024   Shrey Chandegara		Created  


	EXEC [USP_UpdateStocklineDraftForIsSerialized] 158,0, 12084,11
    
**************************************************************/    
CREATE     PROCEDURE [dbo].[USP_UpdateStocklineDraftForIsSerialized]  
(    
 @ItemMasterId BIGINT NULL,
 @Active bit NULL,
 @PurchaseOrderId BIGINT NULL,
 @ItemTypeId INT NULL
)    
AS    
BEGIN    
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
  SET NOCOUNT ON  
 BEGIN TRY    
    BEGIN TRANSACTION    
	BEGIN
		DECLARE @StockItemId BIGINT;
		DECLARE @NonStockItemId BIGINT;
		DECLARE @AssetItemId BIGINT;

		SET @StockItemId = (SELECT ItemTypeId FROM ItemType WHERE Description = 'Stock')
		SET @NonStockItemId = (SELECT ItemTypeId FROM ItemType WHERE Description = 'Non-Stock') 
		SET @AssetItemId = (SELECT ItemTypeId FROM ItemType WHERE Description = 'Asset') 

		IF @ItemMasterId > 0
		BEGIN
			IF (@ItemTypeId = @StockItemId)
				BEGIN
					UPDATE [dbo].[StocklineDraft]
					SET isSerialized = @Active ,
					IsParent = CASE WHEN IsParent = 1 THEN 0 Else 1 END
					WHERE ItemMasterId = @ItemMasterId AND StockLineId IS NULL AND StockLineNumber IS NULL AND PurchaseOrderId = @PurchaseOrderId
				END
			IF (@ItemTypeId = @NonStockItemId)
				BEGIN
					UPDATE [dbo].[NonStockInventoryDraft]
					SET isSerialized = @Active ,
					IsParent = CASE WHEN IsParent = 1 THEN 0 Else 1 END
					WHERE MasterPartId = @ItemMasterId AND NonStockInventoryId IS NULL AND NonStockInventoryNumber IS NULL AND PurchaseOrderId = @PurchaseOrderId
				END
			IF(@ItemTypeId = @AssetItemId)
				BEGIN
					UPDATE [dbo].[AssetInventoryDraft]
					SET isSerialized = @Active ,
					IsParent = CASE WHEN IsParent = 1 THEN 0 Else 1 END
					WHERE AssetRecordId = @ItemMasterId AND PurchaseOrderId = @PurchaseOrderId
				END
		END
	END
    COMMIT TRANSACTION    
    
  END TRY    
  BEGIN CATCH    
    IF @@trancount > 0    
   ROLLBACK TRAN; 
    SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
	
   DECLARE @ErrorLogID int    
   ,@DatabaseName varchar(100) = DB_NAME()    
   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------    
   ,@AdhocComments varchar(150) = 'USP_UpdateStocklineDraftForIsSerialized'    
   ,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(@ItemMasterId, '') + ''    
   ,@ApplicationName varchar(100) = 'PAS'    
   -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
   EXEC spLogException @DatabaseName = @DatabaseName,    
    @AdhocComments = @AdhocComments,    
    @ProcedureParameters = @ProcedureParameters,    
    @ApplicationName = @ApplicationName,    
    @ErrorLogID = @ErrorLogID OUTPUT;    
   RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
   RETURN (1);    
  END CATCH    
END
/*************************************************************           
 ** File:   [USP_Assets_PostCheckBatchDetails]           
 ** Author: Amit Ghediya
 ** Description: This stored procedure is used add/update the status of Asset Inventory 
 ** Purpose:         
 ** Date:   08/08/2023 
 ** PARAMETERS:         
 ** RETURN VALUE:
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    11/29/2024   Abhishek Jirawla		Created
	2    31-Aug-2026   Ayushi Patel		[PN-16393] UOM Changes
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_Assets_AddAssetSaleorwriteoff]
(
	@AssetInventoryId BIGINT,
	@CashAmount DECIMAL(18,6),
	@Status VARCHAR(100)
)
AS
BEGIN 
	BEGIN TRY
		DECLARE @AssetInventoryStatusId BIGINT, @AssetInventorySoldStatus VARCHAR(100) = 'SOLD';
		SELECT @AssetInventoryStatusId = AssetInventoryStatusId FROM [DBO].[AssetInventoryStatus] WITH(NOLOCK) 
		WHERE Status = @Status;

		--Update Assets Status to Sold/WriteOff & Qty to 0
		UPDATE [DBO].[AssetInventory] 
		SET InventoryStatusId = @AssetInventoryStatusId , 
			Qty = 0 ,
			ReceivablesAmount = @CashAmount,
			IsActive = 0,
			StatusNote = CASE WHEN UPPER(@Status) = UPPER(@AssetInventorySoldStatus) THEN 'Inventory is Sold' ELSE '' END
		WHERE AssetInventoryId = @AssetInventoryId;

		

	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_Assets_PostCheckBatchDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END
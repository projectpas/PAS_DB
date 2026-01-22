-- =============================================
-- Author:		<Abhishek Jirawla>
-- Create date: <04-16-2024>
-- Description:	<This stored procedure is used to copy existing asset inventory accounting and depreciaation details to new Asset Inventory details>

/*************************************************************   
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author				Change Description              
 ** --   --------		 -------			--------------------------------            
    1    04-16-2024		Abhishek Jirawla		Created
************************************************************************/ 
-- =============================================
CREATE PROCEDURE [dbo].[USP_SaveAssetInventoryBatchAndDepreciationDetails]
@ReferenceId BIGINT,
@AssetInventoryId BIGINT
AS
BEGIN	
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY        
	BEGIN  
		-- Accounting Details Copied
		INSERT INTO StocklineBatchDetails
		SELECT JournalBatchDetailId, JournalBatchHeaderId, VendorId, VendorName, ItemMasterId, PartId,
			PartNumber, @AssetInventoryId, PONum, RoId, RONum, StocklineId, StocklineNumber, Consignment, Description, SiteId, Site, WarehouseId,
			Warehouse, LocationId, Location, BinId, Bin, ShelfId, Shelf, Stocktype, CommonJournalBatchDetailId, ReferenceId, ReferenceTypeId, ReferenceNumber FROM StocklineBatchDetails 
		WHERE PoId = @ReferenceId


		-- Depreciation Details Copied
		INSERT INTO AssetDepreciationHistory
		SELECT SerialNo, StklineNumber, InServiceDate, DepriciableStatus, CURRENCY, DepriciableLife, DepreciationMethod, DepreciationFrequency, AssetId
				, @AssetInventoryId, InstalledCost, DepreciationAmount, AccumlatedDepr, NetBookValue, NBVAfterDepreciation, LastDeprRunPeriod, AccountingCalenderId,
				MasterCompanyId, CreatedBy, CreatedDate, updatedBy, updatedDate, IsActive, IsDelete, DepreciationStartDate FROM AssetDepreciationHistory
		WHERE AssetInventoryId = @ReferenceId
	    
	END    
 END TRY    
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_SaveAssetInventoryBatchAndDepreciationDetails'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReferenceId, '') + ''    
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


/*************************************************************           
 ** File:   [GetReceivingPOMSData]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to get ManagementStructureId from StockLineDraft NonStockInventoryDraft  AssetInventoryDraft Tables
 ** Purpose:         
 ** Date:   02/02/2022        
          
 ** PARAMETERS: @PurchaseOrderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/02/2022  Moin Bloch     Created
     
-- EXEC [GetReceivingPOMSData] 1
************************************************************************/ 
CREATE PROCEDURE [dbo].[GetReceivingPOMSData]
@PurchaseOrderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

	SELECT 	part.PurchaseOrderPartRecordId,
			part.ManagementStructureId as partManagementStructureId,
			StockLineDraftId = sld.StockLineDraftId,
			sldManagementStructureEntityId = sld.ManagementStructureEntityId
	   FROM PurchaseOrderPart part WITH(NOLOCK) INNER JOIN StockLineDraft sld WITH(NOLOCK) on part.PurchaseOrderPartRecordId = sld.PurchaseOrderPartRecordId 
	  WHERE part.PurchaseOrderId = @PurchaseOrderId AND sld.isDeleted = 0 AND sld.isActive = 1 
			UNION
	 SELECT part.PurchaseOrderPartRecordId,
			part.ManagementStructureId as partManagementStructureId,
			StockLineDraftId = invd.AssetInventoryDraftId,
			sldManagementStructureEntityId = invd.ManagementStructureId
	   FROM PurchaseOrderPart part WITH(NOLOCK) INNER JOIN AssetInventoryDraft invd WITH(NOLOCK) on part.PurchaseOrderPartRecordId = invd.PurchaseOrderPartRecordId 
			WHERE part.PurchaseOrderId = @PurchaseOrderId AND invd.isDeleted = 0 and invd.isActive = 1
			UNION
	SELECT 	part.PurchaseOrderPartRecordId,
			part.ManagementStructureId as partManagementStructureId,
			StockLineDraftId = sld.NonStockInventoryDraftId,
			sldManagementStructureEntityId = sld.ManagementStructureId
	   FROM PurchaseOrderPart part WITH(NOLOCK) INNER JOIN NonStockInventoryDraft sld WITH(NOLOCK) on part.PurchaseOrderPartRecordId = sld.PurchaseOrderPartRecordId 
	  WHERE part.PurchaseOrderId = @PurchaseOrderId AND sld.isDeleted = 0 AND sld.isActive = 1

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetReceivingPOMSData' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PurchaseOrderId, '') + ''
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
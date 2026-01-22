CREATE PROCEDURE [dbo].[usp_GetReceivingRODraftData]
@repairOrderId  bigint
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

	SELECT 
			part.RepairOrderPartRecordId,
			part.ManagementStructureId as partManagementStructureId,
			StockLineDraftId=sld.StockLineDraftId,
			sldManagementStructureEntityId =sld.ManagementStructureEntityId
			FROM RepairOrderPart  part WITH(NOLOCK)
			INNER JOIN StockLineDraft sld WITH(NOLOCK) on part.RepairOrderPartRecordId = sld.RepairOrderPartRecordId 
			WHERE part.RepairOrderId =@repairOrderId  and sld.isDeleted=0 and sld.isActive=1 
			UNION
			SELECT 
			part.RepairOrderPartRecordId,
			part.ManagementStructureId as partManagementStructureId,
			StockLineDraftId=invd.AssetInventoryDraftId,
			sldManagementStructureEntityId =invd.ManagementStructureId
			FROM RepairOrderPart part WITH(NOLOCK)
			INNER JOIN AssetInventoryDraft invd WITH(NOLOCK) on part.RepairOrderPartRecordId = invd.RepairOrderPartRecordId 
			WHERE part.RepairOrderId =@repairOrderId and invd.isDeleted=0 and invd.isActive=1

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'usp_GetReceivingRODraftData' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@repairOrderId, '') + ''
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

-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.USP_DeleteWorkOrderMaterialkitStocklineById   (source: PAS_DB/dbo/Stored Procedures/Procs2/USP_DeleteWorkOrderMaterialkitStocklineById.sql)
-- ---------------------------------------------------------------------------------------------------
-- =============================================
-- Author:		HEMANT SALIYA	
-- Create date: 27-03-2025
-- Description:	This stored procedure is used to Detete kit Stockline 
-- =============================================

/*************************************************************   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    27-03-2025   HEMANT SALIYA			Created
	2    04/14/2025   HEMANT SALIYA			Added Work Order Work Flow Id for UpdateWOMaterialsCost
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

	EXEC USP_DeleteWorkOrderMaterialkitStocklineById 18573, 188319, 'Brandon  Taylor'
**************************************************************/

CREATE     PROC [dbo].[USP_DeleteWorkOrderMaterialkitStocklineById]
(
	@WorkOrderMaterialsKitId BIGINT = NULL,
	@StocklineId BIGINT = NULL,
	@UpdatedBy VARCHAR(100) = NULL
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		
		DECLARE @WorkOrderId BIGINT;
		DECLARE @WorkOrderPartNoId BIGINT;
		DECLARE @WorkFlowWorkOrderId BIGINT;
		DECLARE @PurchaseOrderId BIGINT;
		DECLARE @IsKit BIT = 1;
		DECLARE @IsSubWO BIT = 0;
		DECLARE @moduleId BIGINT;
		DECLARE @BodyTemplate NVARCHAR(MAX);
		DECLARE @PartNumber NVARCHAR(200);
		DECLARE @historyModuleId BIGINT;
		DECLARE @MasterCompanyId INT;
		DECLARE @CreatedBy VARCHAR(MAX);
		DECLARE @StatusCode VARCHAR(50)='DeleteKitPart';

		SET @CreatedBy = @UpdatedBy;
		

		--DELETE KIT STOCKLINE
		IF @StocklineId > 0
		BEGIN
			DELETE FROM dbo.WorkOrderMaterialStockLineKit
			WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsKitId AND StocklineId = @StocklineId;
		END

		--GET DATA FOR WO HISTORY  AND History
		SELECT @WorkOrderId = WMK.WorkOrderId, @WorkFlowWorkOrderId = wmk.WorkFlowWorkOrderId, @WorkOrderPartNoId = WMK.WOPartNoId, @MasterCompanyId = WMK.MasterCompanyId, @PartNumber = IM.partnumber, @PurchaseOrderId = POId
		FROM [dbo].WorkOrderMaterialsKit WMK WITH(NOLOCK)
		JOIN [dbo].ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WMK.ItemMasterId
		JOIN [dbo].Condition C WITH(NOLOCK) ON C.ConditionId = WMK.ConditionCodeId
		WHERE WMK.WorkOrderMaterialsKitId = @WorkOrderMaterialsKitId AND ISNULL(IM.IsNonStock,0) = 0 ;

		SELECT TOP 1 @historyModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'WORKORDER'

		SELECT @BodyTemplate = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE UPPER(TemplateCode) = 'DELETEKITPART';
		
		SET @BodyTemplate =   REPLACE(@BodyTemplate, '##PN##', ISNULL(@PartNumber,''));

		EXEC [dbo].[USP_History] @historyModuleId,@WorkOrderId,null,@WorkOrderPartNoId,'','Kit Part Deleted',@BodyTemplate,@StatusCode,@MasterCompanyId,@CreatedBy,NULL,@UpdatedBy,NULL;

		
		--DELETE WOM KIT FOR NO STOCKLINE EXIST
		IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.WorkOrderMaterialStockLineKit WITH(NOLOCK) WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsKitId)
		BEGIN
			DELETE FROM [dbo].WorkOrderMaterialsKit WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsKitId;
		END

		EXEC USP_UnMappedPOByWorkOrderMaterialsId @WorkOrderMaterialsKitId, @IsKit, @IsSubWO, @WorkOrderId, @PurchaseOrderId, @UpdatedBy;

		EXEC USP_UpdateWOMaterialsCost	@WorkOrderMaterialsKitId, @WorkFlowWorkOrderId;

	END
	COMMIT TRANSACTION
	END TRY    
	BEGIN CATCH      
		 IF @@trancount > 0
		 ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_DeleteWorkOrderMaterialkitStocklineById' 
            , @ProcedureParameters VARCHAR(3000)  = ''
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
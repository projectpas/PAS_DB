-- =============================================
-- Author:		RAJESH GAMI	
-- Create date: 28 Mar 2025
-- Description:	This stored procedure is used to Detete kit Stockline (Sub Work Order)
-- =============================================

/*************************************************************   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    28 Mar 2025   RAJESH GAMI			CREATED
**************************************************************/

CREATE     PROC [dbo].[USP_DeleteSubWorkOrderMaterialKitStocklineById]
(
	@SubWorkOrderMaterialsKitId BIGINT = NULL,
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
		
		DECLARE @SubWorkOrderId BIGINT;
		DECLARE @SubWOPartNoId BIGINT;
		DECLARE @PurchaseOrderId BIGINT;
		DECLARE @IsKit BIT = 1;
		DECLARE @IsSubWO BIT = 1;
		DECLARE @moduleId BIGINT;
		DECLARE @BodyTemplate NVARCHAR(MAX);
		DECLARE @PartNumber NVARCHAR(200);
		DECLARE @historyModuleId BIGINT = (SELECT TOP 1  ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'SubWorkOrder');
		DECLARE @MasterCompanyId INT;
		DECLARE @CreatedBy VARCHAR(MAX);
		DECLARE @StatusCode VARCHAR(50)='DeleteKitPart';
		SET @CreatedBy = @UpdatedBy;

		--DELETE KIT STOCKLINE
		IF @StocklineId > 0
		BEGIN
			DELETE FROM dbo.SubWorkOrderMaterialStockLineKit
			WHERE SubWorkOrderMaterialsKitId = @SubWorkOrderMaterialsKitId AND StocklineId = @StocklineId;
		END

		--GET DATA FOR WO HISTORY  AND History
		SELECT @SubWorkOrderId = WMK.SubWorkOrderId, @SubWOPartNoId = WMK.SubWOPartNoId, @MasterCompanyId = WMK.MasterCompanyId, @PartNumber = IM.partnumber, @PurchaseOrderId = POId
		FROM [dbo].SubWorkOrderMaterialsKit WMK WITH(NOLOCK)
		JOIN [dbo].ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WMK.ItemMasterId
		JOIN [dbo].Condition C WITH(NOLOCK) ON C.ConditionId = WMK.ConditionCodeId
		WHERE WMK.SubWorkOrderMaterialsKitId = @SubWorkOrderMaterialsKitId;

		SELECT @BodyTemplate = TemplateBody FROM dbo.HistoryTemplate WITH(NOLOCK) WHERE UPPER(TemplateCode) = 'DELETEKITPART';
		
		SET @BodyTemplate =   REPLACE(@BodyTemplate, '##PN##', ISNULL(@PartNumber,''));

		EXEC [dbo].[USP_History] @historyModuleId,@SubWorkOrderId,null,@SubWOPartNoId,'','Kit Part Deleted',@BodyTemplate,@StatusCode,@MasterCompanyId,@CreatedBy,NULL,@UpdatedBy,NULL;
		
		--DELETE WOM KIT FOR NO STOCKLINE EXIST
		IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.SubWorkOrderMaterialStockLineKit WITH(NOLOCK) WHERE SubWorkOrderMaterialsKitId = @SubWorkOrderMaterialsKitId)
		BEGIN
			DELETE FROM [dbo].SubWorkOrderMaterialsKit WHERE SubWorkOrderMaterialsKitId = @SubWorkOrderMaterialsKitId;
		END

		EXEC USP_UnMappedPOByWorkOrderMaterialsId @SubWorkOrderMaterialsKitId, @IsKit, @IsSubWO, @SubWorkOrderId, @PurchaseOrderId, @UpdatedBy;

	END
	COMMIT TRANSACTION
	END TRY    
	BEGIN CATCH      
		 IF @@trancount > 0
		 ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_DeleteSubWorkOrderMaterialKitStocklineById' 
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
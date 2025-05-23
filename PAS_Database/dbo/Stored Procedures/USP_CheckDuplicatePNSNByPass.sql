/*************************************************************           
 ** File:   [USP_CheckDuplicatePNSNByPass]           
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to Check Duplicate PN - Serial Number before create stockLine(on receive Customer, PO, RO)
 ** Date:   22-May-2025        
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    22-May-2025   Devendra Shekh		Created
	 
exec dbo.USP_CheckDuplicatePNSNByPass @ItemMasterId=318,@SerialNumber=N'TDGRGRDG',@ModuleId=27,@MasterCompanyId=1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CheckDuplicatePNSNByPass]
@ItemMasterId BIGINT = NULL,
@SerialNumber VARCHAR(50) = NULL,
@ModuleId BIGINT = NULL,
@MasterCompanyId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @IsPNSNWarning BIT, @IsPNSNRestriction BIT;
		DECLARE @WOType BIGINT, @ManufacturerId BIGINT, @AllowByPass BIT;
		DECLARE @RecWOModuleId INT, @RecPOModuleId INT, @RecROModuleId INT;

		SELECT @RecWOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ReceivingCustomerWork';
		SELECT @RecPOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ReceivingPurchaseOrder';
		SELECT @RecROModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ReceivingRepairOrder';

		SELECT @ManufacturerId = [ManufacturerId] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @ItemMasterId AND [MasterCompanyId] = @MasterCompanyId;

		IF EXISTS(SELECT 1 FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [QuantityOnHand] > 0 AND [ItemMasterId] = @ItemMasterId AND [ManufacturerId] = @ManufacturerId AND UPPER(TRIM([SerialNumber])) = UPPER(TRIM(@SerialNumber)) AND [MasterCompanyId] = @MasterCompanyId)
		BEGIN
			SET @AllowByPass = 0;			
		END

		IF(@RecWOModuleId = @ModuleId)
		BEGIN
			SELECT @WOType = [Id] FROM [WorkOrderType] WITH(NOLOCK) WHERE [Description] = 'Customer';
			SELECT @IsPNSNWarning = ISNULL(IsPNSNWarning, 0), @IsPNSNRestriction = ISNULL(IsPNSNRestriction, 0) FROM [dbo].[WorkOrderSettings] WITH(NOLOCK) WHERE [WorkOrderTypeId] = @WOType AND [MasterCompanyId] = @MasterCompanyId;
		END
		ELSE IF(@RecPOModuleId = @ModuleId)
		BEGIN
			SELECT @IsPNSNWarning = ISNULL(IsPNSNWarning, 0), @IsPNSNRestriction = ISNULL(IsPNSNRestriction, 0) FROM [dbo].[PurchaseOrderSettingMaster] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;
		END
		ELSE IF(@RecROModuleId = @ModuleId)
		BEGIN
			SELECT @IsPNSNWarning = ISNULL(IsPNSNWarning, 0), @IsPNSNRestriction = ISNULL(IsPNSNRestriction, 0) FROM [dbo].[RepairOrderSettingMaster] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;
		END

		IF(@AllowByPass = 0)
		BEGIN
			SELECT @IsPNSNWarning AS IsPNSNWarning, @IsPNSNRestriction AS IsPNSNRestriction
		END
		ELSE
		BEGIN
			SELECT 0 AS IsPNSNWarning, 0 AS IsPNSNRestriction
		END
		
	END TRY    
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_CheckDuplicatePNSNByPass' 
		, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
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
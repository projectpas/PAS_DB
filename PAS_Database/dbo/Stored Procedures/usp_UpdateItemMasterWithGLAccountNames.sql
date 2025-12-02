/***************************************************************  
 ** File:  [usp_UpdateItemMasterWithGLAccountNames]            
 ** Author:   Devendra Shekh
 ** Description: Update Item Master with default values
 ** Date:  23-Dec-2024
 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    22-July-2025		Ayushi Patel			Created
    2    27-OCt-2025		Devendra Shekh			Added Missing GLAccountIds Update for ItemMaster
    3 	 20-Nov-2025        Divyesh Kathiriya		Added Default Value for "OEM/PMA/DER"

**************************************************************/
CREATE PROCEDURE [dbo].[usp_UpdateItemMasterWithGLAccountNames]
    @ItemMasterId BIGINT,
    @PartSourceVal VARCHAR(256) = NULL,
    @MasterCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        DECLARE @InventoryGLSettingId INT;
		DECLARE @MasterPartId BIGINT;

		INSERT INTO dbo.MasterParts (
			Description,
			PartNumber,
			ManufacturerId,
			MasterCompanyId,
			CreatedBy,
			UpdatedBy,
			CreatedDate,
			UpdatedDate,
			IsActive,
			IsDeleted
		)
		SELECT
			IM.PartDescription,
			IM.PartNumber,
			IM.ManufacturerId,
			IM.MasterCompanyId,
			IM.CreatedBy,
			IM.UpdatedBy,
			GETUTCDATE(),
			GETUTCDATE(),
			IM.IsActive,
			IM.IsDeleted
		FROM dbo.ItemMaster IM WITH (NOLOCK)
		WHERE IM.ItemMasterId = @ItemMasterId AND IM.MasterCompanyId = @MasterCompanyId;

		SET @MasterPartId = SCOPE_IDENTITY();

        SELECT TOP 1 @InventoryGLSettingId = InventoryGLSettingId
        FROM dbo.InventoryGLSetting WITH (NOLOCK)
        WHERE MasterCompanyId = @MasterCompanyId;

        DECLARE @IsPma BIT = 0, @IsDER BIT = 0, @IsOEM BIT = 0;

        IF UPPER(LTRIM(RTRIM(@PartSourceVal))) = 'PMA'
        BEGIN
            SET @IsPma = 1;
        END
        ELSE IF UPPER(LTRIM(RTRIM(@PartSourceVal))) = 'DER'
        BEGIN
            SET @IsDER = 1;
        END
        ELSE IF UPPER(LTRIM(RTRIM(@PartSourceVal))) = 'OEM'
        BEGIN
            SET @IsOEM = 1;
        END
        ELSE
        BEGIN
            SET @IsOEM = 1;
        END

        UPDATE IM
        SET
			IM.MasterPartId = @MasterPartId,
			IM.IsUpdated = 1,
            IM.ItemGroup = IG.ItemGroupCode,
            IM.ManufacturerName = M.Name,
            IM.ItemClassificationName = IC.ItemClassificationCode,
            IM.GLAccountId = I.InventoryGLAccId,
            IM.InventoryGLSettingId = @InventoryGLSettingId,
            IM.GoodsReceivedNotInvoicesGLAccName = CONCAT(GL2.AccountCode, '-', GL2.AccountName),
            IM.WorkInProgressGLAccName = CONCAT(GL3.AccountCode, '-', GL3.AccountName),
            IM.InventoryToBillGLAccName = CONCAT(GL4.AccountCode, '-', GL4.AccountName),
            IM.FinishedGoodsGLAccName = CONCAT(GL5.AccountCode, '-', GL5.AccountName),
            IM.InventoryExchAgreementGLAccName = CONCAT(GL6.AccountCode, '-', GL6.AccountName),
            IM.InventoryReserveGLAccName = CONCAT(GL7.AccountCode, '-', GL7.AccountName),
            IM.COGS_WorkOrderGLAccName = CONCAT(GL8.AccountCode, '-', GL8.AccountName),
            IM.COGS_SalesOrderGLAccName = CONCAT(GL9.AccountCode, '-', GL9.AccountName),
            IM.COGS_QtyVarianceGLAccName = CONCAT(GL10.AccountCode, '-', GL10.AccountName),
            IM.COGS_UnitCostVarianceGLAccName = CONCAT(GL11.AccountCode, '-', GL11.AccountName),
            IM.RevenueMroGLAccName = CONCAT(GL12.AccountCode, '-', GL12.AccountName),
            IM.RevenueSoGLAccName = CONCAT(GL13.AccountCode, '-', GL13.AccountName),
            IM.RevenueExchGLAccName = CONCAT(GL14.AccountCode, '-', GL14.AccountName),
            IM.COGS_ExchSalesOrderGLAccName = CONCAT(GL15.AccountCode, '-', GL15.AccountName),
            IM.IsPma = @IsPma,
            IM.IsDER = @IsDER,
            IM.IsOEM = @IsOEM,
			IM.GoodsReceivedNotInvoicesGLAccId = I.GoodsReceivedNotInvoicesGLAccId,
			IM.WorkInProgressGLAccId = I.WorkInProgressGLAccId,
			IM.InventoryToBillGLAccId = I.InventoryToBillGLAccId,
			IM.FinishedGoodsGLAccId = I.FinishedGoodsGLAccId,
			IM.InventoryExchAgreementGLAccId = I.InventoryExchAgreementGLAccId,
			IM.InventoryReserveGLAccId = I.InventoryReserveGLAccId,
			IM.COGS_WorkOrderGLAccId = I.COGS_WorkOrderGLAccId,
			IM.COGS_SalesOrderGLAccId = I.COGS_SalesOrderGLAccId,
			IM.COGS_QtyVarianceGLAccId = I.COGS_QtyVarianceGLAccId,
			IM.COGS_UnitCostVarianceGLAccId = I.COGS_UnitCostVarianceGLAccId,
			IM.RevenueMroGLAccId = I.RevenueMroGLAccId,
			IM.RevenueSoGLAccId = I.RevenueSoGLAccId,
			IM.RevenueExchGLAccId = I.RevenueExchGLAccId,
			IM.COGS_ExchSalesOrderGLAccId = I.COGS_ExchSalesOrderGLAccId
        FROM dbo.ItemMaster IM WITH (NOLOCK)
        LEFT JOIN dbo.InventoryGLSetting I WITH (NOLOCK) ON I.InventoryGLSettingId = @InventoryGLSettingId
        LEFT JOIN dbo.GLAccount GL1 WITH (NOLOCK) ON GL1.GLAccountId = I.InventoryGLAccId
        LEFT JOIN dbo.GLAccount GL2 WITH (NOLOCK) ON GL2.GLAccountId = I.GoodsReceivedNotInvoicesGLAccId
        LEFT JOIN dbo.GLAccount GL3 WITH (NOLOCK) ON GL3.GLAccountId = I.WorkInProgressGLAccId
        LEFT JOIN dbo.GLAccount GL4 WITH (NOLOCK) ON GL4.GLAccountId = I.InventoryToBillGLAccId
        LEFT JOIN dbo.GLAccount GL5 WITH (NOLOCK) ON GL5.GLAccountId = I.FinishedGoodsGLAccId
        LEFT JOIN dbo.GLAccount GL6 WITH (NOLOCK) ON GL6.GLAccountId = I.InventoryExchAgreementGLAccId
        LEFT JOIN dbo.GLAccount GL7 WITH (NOLOCK) ON GL7.GLAccountId = I.InventoryReserveGLAccId
        LEFT JOIN dbo.GLAccount GL8 WITH (NOLOCK) ON GL8.GLAccountId = I.COGS_WorkOrderGLAccId
        LEFT JOIN dbo.GLAccount GL9 WITH (NOLOCK) ON GL9.GLAccountId = I.COGS_SalesOrderGLAccId
        LEFT JOIN dbo.GLAccount GL10 WITH (NOLOCK) ON GL10.GLAccountId = I.COGS_QtyVarianceGLAccId
        LEFT JOIN dbo.GLAccount GL11 WITH (NOLOCK) ON GL11.GLAccountId = I.COGS_UnitCostVarianceGLAccId
        LEFT JOIN dbo.GLAccount GL12 WITH (NOLOCK) ON GL12.GLAccountId = I.RevenueMroGLAccId
        LEFT JOIN dbo.GLAccount GL13 WITH (NOLOCK) ON GL13.GLAccountId = I.RevenueSoGLAccId
        LEFT JOIN dbo.GLAccount GL14 WITH (NOLOCK) ON GL14.GLAccountId = I.RevenueExchGLAccId
        LEFT JOIN dbo.GLAccount GL15 WITH (NOLOCK) ON GL15.GLAccountId = I.COGS_ExchSalesOrderGLAccId
        LEFT JOIN dbo.Manufacturer M WITH (NOLOCK) ON IM.ManufacturerId = M.ManufacturerId
        LEFT JOIN dbo.ItemClassification IC WITH (NOLOCK) ON IM.ItemClassificationId = IC.ItemClassificationId
        LEFT JOIN dbo.ItemGroup IG WITH (NOLOCK) ON IM.ItemGroupId = IG.ItemGroupId
        WHERE
            IM.ItemMasterId = @ItemMasterId AND
            IM.MasterCompanyId = @MasterCompanyId;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = '[usp_UpdateItemMasterWithGLAccountNames]',
                @ProcedureParameters VARCHAR(3000) = 
                    '@ItemMasterId = ' + CAST(@ItemMasterId AS VARCHAR(10)) + 
                    ', @MasterCompanyId = ' + CAST(@MasterCompanyId AS VARCHAR(10)),
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC dbo.spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in the database. Please let the support team know of the error number: %d', 16, 1, @ErrorLogID);
    END CATCH
END
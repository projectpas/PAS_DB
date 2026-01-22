/*********************************************************************************************           
 ** File:   [USP_UpdateInventoryGLSettingCode]           
 ** Author:  BHAVESH RAVAL 
 ** Description: This stored procedure is used to Update GLAccountCode
 ** Purpose: Insert id and GL code for future display 
 ** Date:   15/01/2024      
          
 ** PARAMETERS:  @InventoryGLSettingId BIGINT = 0 ,@Mode NVARCHAR(250)
         
 ** RETURN VALUE:           
  
 *********************************************************************************************           
  ** Change History           
 *********************************************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    15/01/2025  Bhavesh Raval 	Add or Update GLAccountCode
     
    EXEC [dbo].[USP_UpdateInventoryGLSettingCode1]  11,'Add'
************************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateInventoryGLSettingCode]
    @InventoryGLSettingId BIGINT,
	@Mode NVARCHAR(250)
AS
BEGIN
	
	IF(@Mode='Add')
	BEGIN
		DECLARE @EditInventoryGLSetting BIGINT = NULL;
		SELECT TOP 1 @EditInventoryGLSetting = InventoryGLSettingId 
		FROM dbo.InventoryGLSetting WITH (NOLOCK) 
		ORDER BY InventoryGLSettingId DESC;

		IF(ISNULL(@EditInventoryGLSetting, 0) != 0)
		BEGIN
			UPDATE IGLS
			SET
				InventoryGLAccCode = CONCAT(GLAccount.AccountCode, '-', GLAccount.AccountName),
				GoodsReceivedNotInvoicesGLAccCode = CONCAT(GLAccount1.AccountCode, '-', GLAccount1.AccountName),
				WorkInProgressGLAccCode = CONCAT(GLAccount2.AccountCode, '-', GLAccount2.AccountName),
				InventoryToBillGLAccCode = CONCAT(GLAccount3.AccountCode, '-', GLAccount3.AccountName),
				FinishedGoodsGLAccCode = CONCAT(GLAccount4.AccountCode, '-', GLAccount4.AccountName),
				InventoryExchAgreementGLAccCode = CONCAT(GLAccount5.AccountCode, '-', GLAccount5.AccountName),
				InventoryReserveGLAccCode = CONCAT(GLAccount6.AccountCode, '-', GLAccount6.AccountName),
				COGS_WorkOrderGLAccCode = CONCAT(GLAccount7.AccountCode, '-', GLAccount7.AccountName),
				COGS_SalesOrderGLAccCode = CONCAT(GLAccount8.AccountCode, '-', GLAccount8.AccountName),
				COGS_ExchSalesOrderGLAccCode = CONCAT(GLAccount9.AccountCode, '-', GLAccount9.AccountName),
				COGS_QtyVarianceGLAccCode = CONCAT(GLAccount10.AccountCode, '-', GLAccount10.AccountName),
				COGS_UnitCostVarianceGLAccCode = CONCAT(GLAccount11.AccountCode, '-', GLAccount11.AccountName),
				RevenueMroGLAccCode = CONCAT(GLAccount12.AccountCode, '-', GLAccount12.AccountName),
				RevenueSoGLAccCode = CONCAT(GLAccount13.AccountCode, '-', GLAccount13.AccountName),
				RevenueExchGLAccCode = CONCAT(GLAccount14.AccountCode, '-', GLAccount14.AccountName)
			FROM dbo.InventoryGLSetting  IGLS WITH (NOLOCK)
			LEFT JOIN dbo.GLAccount AS GLAccount ON GLAccount.GLAccountId =   IGLS.InventoryGLAccId 
			LEFT JOIN dbo.GLAccount AS GLAccount1 ON GLAccount1.GLAccountId = IGLS.GoodsReceivedNotInvoicesGLAccId
			LEFT JOIN dbo.GLAccount AS GLAccount2 ON GLAccount2.GLAccountId = IGLS.WorkInProgressGLAccId
			LEFT JOIN dbo.GLAccount AS GLAccount3 ON GLAccount3.GLAccountId = IGLS.InventoryToBillGLAccId 
			LEFT JOIN dbo.GLAccount AS GLAccount4 ON GLAccount4.GLAccountId = IGLS.FinishedGoodsGLAccId 
			LEFT JOIN dbo.GLAccount AS GLAccount5 ON GLAccount5.GLAccountId = IGLS.InventoryExchAgreementGLAccId
			LEFT JOIN dbo.GLAccount AS GLAccount6 ON GLAccount6.GLAccountId = IGLS.InventoryReserveGLAccId 
			LEFT JOIN dbo.GLAccount AS GLAccount7 ON GLAccount7.GLAccountId = IGLS.COGS_WorkOrderGLAccId 
			LEFT JOIN dbo.GLAccount AS GLAccount8 ON GLAccount8.GLAccountId = IGLS.COGS_SalesOrderGLAccId 
			LEFT JOIN dbo.GLAccount AS GLAccount9 ON GLAccount9.GLAccountId = IGLS.COGS_ExchSalesOrderGLAccId
			LEFT JOIN dbo.GLAccount AS GLAccount10 ON GLAccount10.GLAccountId = IGLS.COGS_QtyVarianceGLAccId
			LEFT JOIN dbo.GLAccount AS GLAccount11 ON GLAccount11.GLAccountId = IGLS.COGS_UnitCostVarianceGLAccId 
			LEFT JOIN dbo.GLAccount AS GLAccount12 ON GLAccount12.GLAccountId = IGLS.RevenueMroGLAccId
			LEFT JOIN dbo.GLAccount AS GLAccount13 ON GLAccount13.GLAccountId = IGLS.RevenueSoGLAccId 
			LEFT JOIN dbo.GLAccount AS GLAccount14 ON GLAccount14.GLAccountId = IGLS.RevenueExchGLAccId 
			WHERE IGLS.InventoryGLSettingId = @EditInventoryGLSetting;
		END;
	END
	ELSE
	BEGIN
		UPDATE IGLS
			SET
				InventoryGLAccCode = CONCAT(GLAccount.AccountCode, '-', GLAccount.AccountName),
				GoodsReceivedNotInvoicesGLAccCode = CONCAT(GLAccount1.AccountCode, '-', GLAccount1.AccountName),
				WorkInProgressGLAccCode = CONCAT(GLAccount2.AccountCode, '-', GLAccount2.AccountName),
				InventoryToBillGLAccCode = CONCAT(GLAccount3.AccountCode, '-', GLAccount3.AccountName),
				FinishedGoodsGLAccCode = CONCAT(GLAccount4.AccountCode, '-', GLAccount4.AccountName),
				InventoryExchAgreementGLAccCode = CONCAT(GLAccount5.AccountCode, '-', GLAccount5.AccountName),
				InventoryReserveGLAccCode = CONCAT(GLAccount6.AccountCode, '-', GLAccount6.AccountName),
				COGS_WorkOrderGLAccCode = CONCAT(GLAccount7.AccountCode, '-', GLAccount7.AccountName),
				COGS_SalesOrderGLAccCode = CONCAT(GLAccount8.AccountCode, '-', GLAccount8.AccountName),
				COGS_ExchSalesOrderGLAccCode = CONCAT(GLAccount9.AccountCode, '-', GLAccount9.AccountName),
				COGS_QtyVarianceGLAccCode = CONCAT(GLAccount10.AccountCode, '-', GLAccount10.AccountName),
				COGS_UnitCostVarianceGLAccCode = CONCAT(GLAccount11.AccountCode, '-', GLAccount11.AccountName),
				RevenueMroGLAccCode = CONCAT(GLAccount12.AccountCode, '-', GLAccount12.AccountName),
				RevenueSoGLAccCode = CONCAT(GLAccount13.AccountCode, '-', GLAccount13.AccountName),
				RevenueExchGLAccCode = CONCAT(GLAccount14.AccountCode, '-', GLAccount14.AccountName)
			FROM dbo.InventoryGLSetting  IGLS WITH (NOLOCK)
			LEFT JOIN dbo.GLAccount AS GLAccount ON GLAccount.GLAccountId =   IGLS.InventoryGLAccId 
			LEFT JOIN dbo.GLAccount AS GLAccount1 ON GLAccount1.GLAccountId = IGLS.GoodsReceivedNotInvoicesGLAccId
			LEFT JOIN dbo.GLAccount AS GLAccount2 ON GLAccount2.GLAccountId = IGLS.WorkInProgressGLAccId
			LEFT JOIN dbo.GLAccount AS GLAccount3 ON GLAccount3.GLAccountId = IGLS.InventoryToBillGLAccId 
			LEFT JOIN dbo.GLAccount AS GLAccount4 ON GLAccount4.GLAccountId = IGLS.FinishedGoodsGLAccId 
			LEFT JOIN dbo.GLAccount AS GLAccount5 ON GLAccount5.GLAccountId = IGLS.InventoryExchAgreementGLAccId
			LEFT JOIN dbo.GLAccount AS GLAccount6 ON GLAccount6.GLAccountId = IGLS.InventoryReserveGLAccId 
			LEFT JOIN dbo.GLAccount AS GLAccount7 ON GLAccount7.GLAccountId = IGLS.COGS_WorkOrderGLAccId 
			LEFT JOIN dbo.GLAccount AS GLAccount8 ON GLAccount8.GLAccountId = IGLS.COGS_SalesOrderGLAccId 
			LEFT JOIN dbo.GLAccount AS GLAccount9 ON GLAccount9.GLAccountId = IGLS.COGS_ExchSalesOrderGLAccId
			LEFT JOIN dbo.GLAccount AS GLAccount10 ON GLAccount10.GLAccountId = IGLS.COGS_QtyVarianceGLAccId
			LEFT JOIN dbo.GLAccount AS GLAccount11 ON GLAccount11.GLAccountId = IGLS.COGS_UnitCostVarianceGLAccId 
			LEFT JOIN dbo.GLAccount AS GLAccount12 ON GLAccount12.GLAccountId = IGLS.RevenueMroGLAccId
			LEFT JOIN dbo.GLAccount AS GLAccount13 ON GLAccount13.GLAccountId = IGLS.RevenueSoGLAccId 
			LEFT JOIN dbo.GLAccount AS GLAccount14 ON GLAccount14.GLAccountId = IGLS.RevenueExchGLAccId 
			WHERE IGLS.InventoryGLSettingId = @InventoryGLSettingId;
	END
END;
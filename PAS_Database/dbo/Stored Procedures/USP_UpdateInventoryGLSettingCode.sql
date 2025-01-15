/*********************************************************************************************           
 ** File:   [USP_UpdateInventoryGLSettingCode]           
 ** Author:  BHAVESH RAVAL 
 ** Description: This stored procedure is used Update GLAccountCode
 ** Purpose: Insert id and glcode for in feature disply 
 ** Date:   15/01/2024      
          
 ** PARAMETERS:  @InventoryGLSettingId BIGINT = 0 ,@Mode NVARCHAR(250)
         
 ** RETURN VALUE:           
  
 *********************************************************************************************           
  ** Change History           
 *********************************************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    15/01/2025  Bhavesh Raval 	Add or Update GLAccountCode
     
    EXEC [dbo].[USP_UpdateInventoryGLSettingCode]  33 'Edit'
************************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateInventoryGLSettingCode]
    @InventoryGLSettingId BIGINT,
	@Mode NVARCHAR(250)
AS
BEGIN
	
	IF(@Mode='Add')
	BEGIN
		DECLARE @EditInventoryGLSetting BIGINT=NULL;
		SELECT TOP 1 @EditInventoryGLSetting=InventoryGLSettingId FROM InventoryGLSetting ORDER BY InventoryGLSettingId DESC
			IF(ISNULL(@EditInventoryGLSetting,0)!=0)
			BEGIN
				UPDATE InventoryGLSetting 
				SET
					InventoryGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
										  FROM GLAccount 
										  WHERE GLAccountId = InventoryGLAccId),
					GoodsReceivedNotInvoicesGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
														 FROM GLAccount 
														 WHERE GLAccountId = GoodsReceivedNotInvoicesGLAccId),
					WorkInProgressGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
											   FROM GLAccount 
											   WHERE GLAccountId = WorkInProgressGLAccId),
					InventoryToBillGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
												FROM GLAccount 
												WHERE GLAccountId = InventoryToBillGLAccId),
					FinishedGoodsGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
											  FROM GLAccount 
											  WHERE GLAccountId = FinishedGoodsGLAccId),
					InventoryExchAgreementGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
													   FROM GLAccount 
													   WHERE GLAccountId = InventoryExchAgreementGLAccId),
					InventoryReserveGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
												 FROM GLAccount 
												 WHERE GLAccountId = InventoryReserveGLAccId),
					COGS_WorkOrderGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
											   FROM GLAccount 
											   WHERE GLAccountId = COGS_WorkOrderGLAccId),
					COGS_SalesOrderGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
												FROM GLAccount 
												WHERE GLAccountId = COGS_SalesOrderGLAccId),
					COGS_ExchSalesOrderGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
													FROM GLAccount 
													WHERE GLAccountId = COGS_ExchSalesOrderGLAccId),
					COGS_QtyVarianceGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
												 FROM GLAccount 
												 WHERE GLAccountId = COGS_QtyVarianceGLAccId),
					COGS_UnitCostVarianceGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
													  FROM GLAccount 
													  WHERE GLAccountId = COGS_UnitCostVarianceGLAccId),
					RevenueMroGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
										   FROM GLAccount 
										   WHERE GLAccountId = RevenueMroGLAccId),
					RevenueSoGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
										  FROM GLAccount 
										  WHERE GLAccountId = RevenueSoGLAccId),
					RevenueExchGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
											FROM GLAccount 
											WHERE GLAccountId = RevenueExchGLAccId)
				WHERE InventoryGLSettingId = @EditInventoryGLSetting;
		END;
	END;
	ELSE
	BEGIN
	-- Update InventoryGLSetting table with the corresponding AccountCodes and AccountNames
			UPDATE InventoryGLSetting 
			SET
				InventoryGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
									  FROM GLAccount 
									  WHERE GLAccountId = InventoryGLAccId),
				GoodsReceivedNotInvoicesGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
													 FROM GLAccount 
													 WHERE GLAccountId = GoodsReceivedNotInvoicesGLAccId),
				WorkInProgressGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
										   FROM GLAccount 
										   WHERE GLAccountId = WorkInProgressGLAccId),
				InventoryToBillGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
											FROM GLAccount 
											WHERE GLAccountId = InventoryToBillGLAccId),
				FinishedGoodsGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
										  FROM GLAccount 
										  WHERE GLAccountId = FinishedGoodsGLAccId),
				InventoryExchAgreementGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
												   FROM GLAccount 
												   WHERE GLAccountId = InventoryExchAgreementGLAccId),
				InventoryReserveGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
											 FROM GLAccount 
											 WHERE GLAccountId = InventoryReserveGLAccId),
				COGS_WorkOrderGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
										   FROM GLAccount 
										   WHERE GLAccountId = COGS_WorkOrderGLAccId),
				COGS_SalesOrderGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
											FROM GLAccount 
											WHERE GLAccountId = COGS_SalesOrderGLAccId),
				COGS_ExchSalesOrderGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
												FROM GLAccount 
												WHERE GLAccountId = COGS_ExchSalesOrderGLAccId),
				COGS_QtyVarianceGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
											 FROM GLAccount 
											 WHERE GLAccountId = COGS_QtyVarianceGLAccId),
				COGS_UnitCostVarianceGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
												  FROM GLAccount 
												  WHERE GLAccountId = COGS_UnitCostVarianceGLAccId),
				RevenueMroGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
									   FROM GLAccount 
									   WHERE GLAccountId = RevenueMroGLAccId),
				RevenueSoGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
									  FROM GLAccount 
									  WHERE GLAccountId = RevenueSoGLAccId),
				RevenueExchGLAccCode = (SELECT TOP 1 AccountCode + '-' + AccountName 
										FROM GLAccount 
										WHERE GLAccountId = RevenueExchGLAccId)
			WHERE InventoryGLSettingId = @InventoryGLSettingId;
	END;
END;
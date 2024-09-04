/*************************************************************             
 ** File:   [udfGetModuleReferenceByModuleId]            
 ** Author:   Unknown
 ** Description: This function is used to get reference number based on ModuleId and ReferenceId 
 ** Purpose:           
 ** Date:   Unknown

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History             
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    Unknown     Unknown		    Created
	2    20-03-2024  Abhishek Jirawla   Adding detail regarding BulStockAdjustment Module
	2    20-03-2024  Rajesh Gami        Added StockAdjustments 
	
**************************************************************/
CREATE   FUNCTION [dbo].[udfGetModuleReferenceByModuleId]
(  
   @ModuleId BIGINT = NULL,
   @ReferenceId BIGINT = NULL,
   @ModuleOrSubModule INT = NULL --  1 for Module, 2 for SubModule
)
RETURNS VARCHAR(100)
AS
BEGIN
	DECLARE @ModuleName VARCHAR(100) = '';
	DECLARE @SubModuleName VARCHAR(100) = '';
	DECLARE @ReferenceNumber VARCHAR(100) = '';

	IF (@ModuleOrSubModule = 1)
	BEGIN
		SELECT @ModuleName = M.ModuleName FROM DBO.Module M WITH (NOLOCK) WHERE M.ModuleId = @ModuleId;
	END

	IF (@ModuleOrSubModule = 2)
	BEGIN
		SELECT @SubModuleName = M.ModuleName FROM DBO.Module M WITH (NOLOCK) WHERE M.ModuleId = @ModuleId;
	END

	IF (@ModuleOrSubModule = 1)
	BEGIN
		IF (@ModuleName = 'WorkOrder')
		BEGIN
			SELECT @ReferenceNumber = WO.WorkOrderNum FROM DBO.WorkOrder WO WITH (NOLOCK) WHERE WO.WorkOrderId = @ReferenceId;
		END
		IF (@ModuleName = 'SalesOrder')
		BEGIN
			SELECT @ReferenceNumber = SO.SalesOrderNumber FROM DBO.SalesOrder SO WITH (NOLOCK) WHERE SO.SalesOrderId = @ReferenceId;
		END
		IF (@ModuleName = 'StockLine' OR @ModuleName = 'StockAdjustments')
		BEGIN
			SELECT @ReferenceNumber = Stk.StockLineNumber FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.StockLineId = @ReferenceId;
		END
		IF (@ModuleName = 'RepairOrder' OR @ModuleName = 'ReceivingRepairOrder')
		BEGIN
			SELECT @ReferenceNumber = RO.RepairOrderNumber FROM DBO.RepairOrder RO WITH (NOLOCK) WHERE RO.RepairOrderId = @ReferenceId;
		END
		IF (@ModuleName = 'PurchaseOrder' OR @ModuleName = 'ReceivingPurchaseOrder')
		BEGIN
			SELECT @ReferenceNumber = PO.PurchaseOrderNumber FROM DBO.PurchaseOrder PO WITH (NOLOCK) WHERE PO.PurchaseOrderId = @ReferenceId;
		END
		IF (@ModuleName = 'ReceivingCustomerWork')
		BEGIN
			SELECT @ReferenceNumber = RCW.ReceivingNumber FROM DBO.ReceivingCustomerWork RCW WITH (NOLOCK) WHERE RCW.ReceivingCustomerWorkId = @ReferenceId;
		END
		IF (@ModuleName = 'SubWorkOrder' OR @ModuleName = 'SubWO')
		BEGIN
			SELECT @ReferenceNumber = SWO.SubWorkOrderNo FROM DBO.SubWorkOrder SWO WITH (NOLOCK) WHERE SWO.SubWorkOrderId = @ReferenceId;
		END
		IF (UPPER(@ModuleName) = UPPER('Lot'))
		BEGIN
			SELECT @ReferenceNumber = LT.LotNumber FROM DBO.LOT LT WITH (NOLOCK) WHERE LT.LotId = @ReferenceId;
		END
		IF (@ModuleName = 'ExchangeSalesOrder')
		BEGIN
			SELECT @ReferenceNumber = ESO.ExchangeSalesOrderNumber FROM DBO.ExchangeSalesOrder ESO WITH (NOLOCK) WHERE ESO.ExchangeSalesOrderId = @ReferenceId;
		END
		IF (@ModuleName = 'VendorRMA')
		BEGIN
			SELECT @ReferenceNumber = RMA.[RMANumber] FROM [dbo].[VendorRMA] RMA WITH (NOLOCK) WHERE RMA.VendorRMAId = @ReferenceId;
		END
		IF (@ModuleName = 'ReceivingVendorRMA')
		BEGIN
			SELECT @ReferenceNumber = RMA.[RMANumber] FROM [dbo].[VendorRMA] RMA WITH (NOLOCK) WHERE RMA.VendorRMAId = @ReferenceId;
		END
		IF (@ModuleName = 'BulkStockAdjustments')
		BEGIN
			SELECT @ReferenceNumber = Stk.StockLineNumber FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.StockLineId = @ReferenceId;
		END
		IF (@ModuleName = 'StockAdjustments')
		BEGIN
			SELECT @ReferenceNumber = Stk.BulkStkLineAdjNumber FROM DBO.BulkStockLineAdjustment Stk WITH (NOLOCK) WHERE Stk.BulkStkLineAdjId = @ReferenceId;
		END
	END

	IF (@ModuleOrSubModule = 2)
		BEGIN
		IF (@SubModuleName = 'WorkOrder')
		BEGIN
			SELECT @ReferenceNumber = WO.WorkOrderNum FROM DBO.WorkOrder WO WITH (NOLOCK) WHERE WO.WorkOrderId = @ReferenceId;
		END
		IF (@SubModuleName = 'SalesOrder')
		BEGIN
			SELECT @ReferenceNumber = SO.SalesOrderNumber FROM DBO.SalesOrder SO WITH (NOLOCK) WHERE SO.SalesOrderId = @ReferenceId;
		END
		IF (@SubModuleName = 'SalesQuote')
		BEGIN
			SELECT @ReferenceNumber = SOQ.SalesOrderQuoteNumber FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK) WHERE SOQ.SalesOrderQuoteId = @ReferenceId;
		END
		IF (@SubModuleName = 'WorkOrderMaterials')
		BEGIN
			SELECT @ReferenceNumber = IM.partnumber FROM DBO.WorkOrderMaterials WOM WITH (NOLOCK) INNER JOIN DBO.ItemMaster IM WITH (NOLOCK) ON WOM.ItemMasterId = IM.ItemMasterId WHERE WOM.WorkOrderMaterialsId = @ReferenceId;
		END
		IF (@SubModuleName = 'SubWorkOrderMaterials')
		BEGIN
			SELECT @ReferenceNumber = IM.partnumber FROM DBO.SubWorkOrderMaterials SWOM WITH (NOLOCK) INNER JOIN DBO.ItemMaster IM WITH (NOLOCK) ON SWOM.ItemMasterId = IM.ItemMasterId WHERE SWOM.SubWorkOrderMaterialsId = @ReferenceId;
		END
		IF (@SubModuleName = 'SalesOrderShipping')
		BEGIN
			SELECT @ReferenceNumber = SOS.SOShippingNum FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) WHERE SOS.SalesOrderShippingId = @ReferenceId;
		END
		IF (@SubModuleName = 'WorkOrderShipping')
		BEGIN
			SELECT @ReferenceNumber = WOS.WOShippingNum FROM DBO.WorkOrderShipping WOS WITH (NOLOCK) WHERE WOS.WorkOrderShippingId = @ReferenceId;
		END
		IF (@SubModuleName = 'ExchangeSalesOrderShipping')
		BEGIN
			SELECT @ReferenceNumber = ExchSOS.SOShippingNum FROM DBO.ExchangeSalesOrderShipping ExchSOS WITH (NOLOCK) WHERE ExchSOS.ExchangeSalesOrderShippingId = @ReferenceId;
		END
		IF (@SubModuleName = 'SubWorkOrder' OR @SubModuleName = 'SubWO')
		BEGIN
			SELECT @ReferenceNumber = SWO.SubWorkOrderNo FROM DBO.SubWorkOrder SWO WITH (NOLOCK) WHERE SWO.SubWorkOrderId = @ReferenceId;
		END
		IF (@SubModuleName = 'WorkOrderMPN')
		BEGIN
			SELECT @ReferenceNumber = WO.WorkOrderNum FROM DBO.WorkOrder WO WITH (NOLOCK) WHERE WO.WorkOrderId = @ReferenceId;
		END
		IF (UPPER(@ModuleName) = UPPER('Lot'))
		BEGIN
			SELECT @ReferenceNumber = LT.LotNumber FROM DBO.LOT LT WITH (NOLOCK) WHERE LT.LotId = @ReferenceId;
		END
		IF (UPPER(@SubModuleName) = UPPER('ExchangeSalesOrder'))
		BEGIN
			SELECT @ReferenceNumber = ESO.ExchangeSalesOrderNumber FROM DBO.ExchangeSalesOrder ESO WITH (NOLOCK) WHERE ESO.ExchangeSalesOrderId = @ReferenceId;
		END
	END

	RETURN @ReferenceNumber;
END
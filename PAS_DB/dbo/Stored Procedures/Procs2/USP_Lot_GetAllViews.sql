
/*************************************************************           
 ** File:   [USP_Lot_GetAllViews]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to Get all the views of LOT(All PN, PN IN Stock,PN SOLD, PN REPAIRED etc...
 ** Purpose:         
 ** Date:   15/042023      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    15/04/2023  Rajesh Gami   Created
     
-- EXEC USP_Lot_GetAllViews 2,'ALL',1
************************************************************************/

CREATE       PROCEDURE [dbo].[USP_Lot_GetAllViews]
@LotId VARCHAR(max) = '0', 
@Type VARCHAR(50) = NULL,
@MasterCompanyId int
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
		BEGIN		
			IF(UPPER(@Type) = UPPER('ALL'))
			BEGIN
				SELECT DISTINCT
				im.PartNumber
				,im.PartDescription
				,sl.SerialNumber
				,sl.StockLineNumber
				,ic.ItemClassificationCode
				,ig.Description AS ItemGroup
				,c.Description AS Condition
				,uom.Description AS UOM
				,ltCal.Type Status
				,ISNULL(ltCal.Qty,0) Qty
				,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
				,0 QtyRes
				,0 QtyIss
				,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
				,ISNULL(ltCal.TransferredInCost,0.00) TransUnitCost
				,ISNULL(ltin.UnitCost,0.00) UnitCost
				,(ISNULL(ltin.UnitCost,0)* ISNULL(sl.Quantity,0)) ExtCost
				,ISNULL(sl.RepairOrderUnitCost,0) RepairCost
				,(ISNULL(sl.RepairOrderUnitCost,0) + (ISNULL(ltin.UnitCost,0)* ISNULL(sl.Quantity,0))) TotalCost
				,0 UnitSalesPrice
				,0 ExtPrice
				, (( (ISNULL(sl.RepairOrderUnitCost,0) + (ISNULL(ltin.UnitCost,0)* ISNULL(sl.Quantity,0))) * ISNULL(per.PercentValue,0) ) /100) AS MarginAmt
				,ISNULL(per.PercentValue,0) MarginPer
				,'' HowAcquired
				,'' AcquiredRef
				,po.PurchaseOrderNumber
				,ro.RepairOrderNumber
				,'' WorkOrderNumber
				,'' QuoteNumber
				,'' SalesOrderNumber
				,'' InvoiceNo
				,ven.VendorName
				,lot.ReferenceNumber
				,sl.CustomerName
				,'' CO
				,'' BU
				,'' Div
				,'' Dept
				FROM DBO.LOT lot WITH(NOLOCK)
					 INNER JOIN DBO.LotTransInOutDetails ltin WITH(NOLOCK) on lot.LotId = ltin.LotId
					 INNER JOIN DBO.Stockline sl WITH(NOLOCK) on ltin.StockLineId = sl.StockLineId
					 INNER JOIN DBO.ItemMaster im WITH(NOLOCK) on sl.ItemMasterId = im.ItemMasterId
					 LEFT JOIN DBO.LotSetupMaster lsm WITH(NOLOCK) on lot.LotId = lsm.LotId
					 LEFT JOIN DBO.[Percent] per WITH(NOLOCK) on lsm.MarginPercentageId = per.PercentId
					 LEFT JOIN DBO.LotCalculationDetails ltCal WITH(NOLOCK) on ltin.LotTransInOutId = ltCal.LotTransInOutId
					 LEFT JOIN DBO.ItemClassification ic WITH(NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
					 LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
					 LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
					 LEFT JOIN DBO.UnitOfMeasure uom  WITH(NOLOCK) ON sl.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
					 LEFT JOIN DBO.PurchaseOrder po WITH(NOLOCK) ON sl.PurchaseOrderId = po.PurchaseOrderId 
					 LEFT JOIN DBO.RepairOrder ro WITH(NOLOCK) ON sl.RepairOrderId = ro.RepairOrderId 
					 LEFT JOIN DBO.WorkOrder wo WITH(NOLOCK) ON sl.WorkOrderId = wo.WorkOrderId 
					 LEFT JOIN DBO.Vendor ven WITH(NOLOCK) ON sl.VendorId = ven.VendorId
			END
			ELSE IF(UPPER(@Type) = UPPER('PNSTOCKVIEW'))
			BEGIN
				SELECT DISTINCT
				im.PartNumber
				,im.PartDescription
				,sl.SerialNumber
				,sl.StockLineNumber
				,ic.ItemClassificationCode
				,ig.Description AS ItemGroup
				,c.Description AS Condition
				,ISNULL(ltCal.Qty,0) Qty
				,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
				,0 QtyRes
				,0 QtyIss
				,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
				,ISNULL(ltin.UnitCost,0.00) UnitCost
				,(ISNULL(ltin.UnitCost,0)* ISNULL(sl.Quantity,0)) ExtCost
				,ISNULL(sl.RepairOrderUnitCost,0) RepairCost
				,(ISNULL(sl.RepairOrderUnitCost,0) + (ISNULL(ltin.UnitCost,0)* ISNULL(sl.Quantity,0))) TotalCost
				,ro.RepairOrderNumber
				,'' WorkOrderNumber
				,'' SalesOrderNumber
				,'' InvoiceNo
				,ven.VendorName
				,sl.Site AS Site
				,sl.Warehouse
				,sl.Location
				,sl.Shelf
				,sl.Bin
				FROM DBO.LOT lot WITH(NOLOCK)
					 INNER JOIN DBO.LotTransInOutDetails ltin WITH(NOLOCK) on lot.LotId = ltin.LotId
					 INNER JOIN DBO.Stockline sl WITH(NOLOCK) on ltin.StockLineId = sl.StockLineId
					 INNER JOIN DBO.ItemMaster im WITH(NOLOCK) on sl.ItemMasterId = im.ItemMasterId
					 LEFT JOIN DBO.LotSetupMaster lsm WITH(NOLOCK) on lot.LotId = lsm.LotId
					 LEFT JOIN DBO.[Percent] per WITH(NOLOCK) on lsm.MarginPercentageId = per.PercentId
					 LEFT JOIN DBO.LotCalculationDetails ltCal WITH(NOLOCK) on ltin.LotTransInOutId = ltCal.LotTransInOutId
					 LEFT JOIN DBO.ItemClassification ic WITH(NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
					 LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
					 LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
					 LEFT JOIN DBO.PurchaseOrder po WITH(NOLOCK) ON sl.PurchaseOrderId = po.PurchaseOrderId 
					 LEFT JOIN DBO.RepairOrder ro WITH(NOLOCK) ON sl.RepairOrderId = ro.RepairOrderId 
					 LEFT JOIN DBO.WorkOrder wo WITH(NOLOCK) ON sl.WorkOrderId = wo.WorkOrderId 
					 LEFT JOIN DBO.Vendor ven WITH(NOLOCK) ON sl.VendorId = ven.VendorId
			END
		END
	COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_Lot_GetAllViews' 
               , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@LotId, '') + ''',
														@Parameter2 = ' + ISNULL(@Type,'') + ', 
														@Parameter3 = ' + ISNULL(@MasterCompanyId,'') + ''
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
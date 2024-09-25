-- =============================================
-- Author:		Shrey Chandegara
-- Create date: 23-09-2024
-- Description:	This stored procedure is used to count UPdate Stockline Inventory mismatch.
-- =============================================

/*************************************************************   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    23-09-2024   Shrey Chandegara		Created
	
	EXEC [GetNewStocklineInventoryMismatch]
**************************************************************/

CREATE   PROCEDURE [dbo].[GetNewStocklineInventoryMismatch]

AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN
		SELECT DISTINCT Quantity,
              QuantityOnHand,	
			  (ISNULL(S.QuantityAvailable,0) + ISNULL(S.QuantityReserved,0)) as [AV_RES],
			  QuantityAvailable,
			  QuantityReserved,	
			  ((select ISNULL(SUM(QtyReserved),0) from dbo.WorkOrderMaterialstockline WMS  with (Nolock) WHERE WMS.Stocklineid = S.Stocklineid ) 
			    + (select ISNULL(SUM(QtyReserved),0) from dbo.WorkOrderMaterialstocklineKit WMSKIT  with (Nolock) WHERE WMSKIT.Stocklineid = S.Stocklineid )
				+ (select ISNULL(SUM(QuantityReserved),0) from dbo.RepairOrderPart ROP with (Nolock) WHERE ROP.Stocklineid = S.Stocklineid and ROP.QuantityOrdered = ROp.QuantityBackOrdered )
				+ (SELECT ISNULL(SUM(WOP.Quantity),0) FROM DBO.WorkOrderPartNumber WOP WITH (NOLOCK) INNER JOIN DBO.WorkOrder WO WITH (NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId WHERE WOP.StocklineId = S.Stocklineid AND WO.WorkOrderTypeId = 3)
				+ (SELECT ISNULL(SUM(VRMA.Qty),0) FROM DBO.VendorRMADetail VRMA WITH (NOLOCK) WHERE VRMA.StocklineId = S.Stocklineid)) as [AllReserve],
			  (select ISNULL(SUM(QtyReserved),0) from dbo.WorkOrderMaterialstockline WMS  with (Nolock) WHERE WMS.Stocklineid = S.Stocklineid ) as [ReserevinWOM],
			  (select ISNULL(SUM(WMSKIT.QtyReserved),0) from dbo.WorkOrderMaterialstocklineKit WMSKIT  with (Nolock) WHERE WMSKIT.Stocklineid = S.Stocklineid ) as [ReserevinWOKIT],			
			  (select ISNULL(SUM(QuantityReserved),0) from dbo.RepairOrderPart ROP with (Nolock) WHERE ROP.Stocklineid = S.Stocklineid ) as [ReserevinRO],
			  (SELECT ISNULL(SUM(WOP.Quantity),0) FROM DBO.WorkOrderPartNumber WOP WITH (NOLOCK) INNER JOIN DBO.WorkOrder WO WITH (NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId WHERE WOP.StocklineId = S.Stocklineid AND WO.WorkOrderTypeId = 3) AS Reserve_In_WO_MPN,
			  (SELECT ISNULL(SUM(VRMA.Qty),0) FROM DBO.VendorRMADetail VRMA WITH (NOLOCK) WHERE VRMA.StocklineId = S.Stocklineid) AS Reserve_In_VendorRMA,
			  QuantityIssued,
			  ((select ISNULL(SUM(QtyIssued),0) from dbo.WorkOrderMaterialstockline WMSI  with (Nolock) WHERE WMSI.Stocklineid = S.Stocklineid ) 
			    + (select ISNULL(SUM(QtyIssued),0) from dbo.WorkOrderMaterialstocklineKit WMSKITI  with (Nolock) WHERE WMSKITI.Stocklineid = S.Stocklineid ) ) as [AllIssue],
			  (select ISNULL(SUM(QtyIssued),0) from dbo.WorkOrderMaterialstockline WMSI  with (Nolock) WHERE WMSI.Stocklineid = S.Stocklineid ) as [IssueWOM],
			  (select ISNULL(SUM(QtyIssued),0) from dbo.WorkOrderMaterialstocklineKit WMSKITI  with (Nolock) WHERE WMSKITI.Stocklineid = S.Stocklineid ) as [IssueWOKIT],
			  S.StockLineId,
			  S.ParentId,
			  S.IsParent,
			  S.IsCustomerStock,
			  S.CreatedDate,
			  S.StockLineNumber,
			  S.SerialNumber,
			  S.PartNumber,
			  S.PNDescription,
			  S.ControlNumber,
			  S.MasterCompanyId,
			  S.IdNumber,
			  CASE WHEN ISNULL(S.WorkOrderNumber,'') != '' AND ISNULL(S.SubWorkOrderNumber,'') != '' THEN SubWorkOrderNumber
				   WHEN ISNULL(S.WorkOrderNumber,'') != '' THEN WorkOrderNumber
				   WHEN ISNULL(S.PurchaseOrderId,'') != '' THEN P.PurchaseOrderNumber
				   WHEN ISNULL(S.RepairOrderId,'') != '' THEN R.RepairOrderNumber ELSE '' END AS 'ReferenceNumber'
			  FROM  dbo.Stockline S with (Nolock) 
			  LEFT JOIN [dbo].[PurchaseOrder] P WITH(NOLOCK) ON P.PurchaseOrderId = S.PurchaseOrderId   
			  LEFT JOIN [dbo].[RepairOrder] R WITH(NOLOCK) ON R.RepairOrderId = S.RepairOrderId   
			  WHERE ParentId = 0
			  AND
			  (
			   --Quantity != (QuantityOnHand + QuantityIssued)
			   --OR

			   QuantityOnHand != (S.QuantityAvailable + S.QuantityReserved) 
			   OR
			   QuantityReserved !=  ((select ISNULL(SUM(QtyReserved),0) from dbo.WorkOrderMaterialstockline WMS  with (Nolock) WHERE WMS.Stocklineid = S.Stocklineid ) 
											+ (select ISNULL(SUM(QtyReserved),0) from dbo.WorkOrderMaterialstocklineKit WMSKIT  with (Nolock) WHERE WMSKIT.Stocklineid = S.Stocklineid )
											+ (select ISNULL(SUM(QuantityReserved),0) from dbo.RepairOrderPart ROP with (Nolock) WHERE ROP.Stocklineid = S.Stocklineid and ROP.QuantityOrdered = ROp.QuantityBackOrdered )
											+ (SELECT ISNULL(SUM(WOP.Quantity),0) FROM DBO.WorkOrderPartNumber WOP WITH (NOLOCK) INNER JOIN DBO.WorkOrder WO WITH (NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId WHERE WOP.StocklineId = S.Stocklineid AND WO.WorkOrderTypeId = 3)
											+ (SELECT ISNULL(SUM(VRMA.Qty),0) FROM DBO.VendorRMADetail VRMA WITH (NOLOCK) WHERE VRMA.StocklineId = S.Stocklineid))

			  --AND
			  --(select ISNULL(SUM(QuantityReserved),0) from dbo.RepairOrderPart ROP with (Nolock) WHERE ROP.Stocklineid = S.Stocklineid) = 0
      ----         OR
			   --QuantityIssued != ((select ISNULL(SUM(QtyIssued),0) from dbo.WorkOrderMaterialstockline WMSI  with (Nolock) WHERE WMSI.Stocklineid = S.Stocklineid ) 
			   -- + (select ISNULL(SUM(QtyIssued),0) from dbo.WorkOrderMaterialstocklineKit WMSKITI  with (Nolock) WHERE WMSKITI.Stocklineid = S.Stocklineid ) )
			  )
			  AND IsCustomerStock = 0
			  --AND Stocklineid NOT IN (182531, 182483, 176202, 172969, 172250, 171832, 161337, 159105, 138911, 122968, 151137, 139061, 128991, 119570, 129557, 146121, 154611, 154242, 149585, 149584)
			  order by Stocklineid DESC
	END
	END TRY    
	BEGIN CATCH    
	 SELECT 
            ERROR_MESSAGE() AS ErrorMessage, 
            ERROR_SEVERITY() AS ErrorSeverity,
            ERROR_STATE() AS ErrorState,
            ERROR_LINE() AS ErrorLine;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
			
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetNewStocklineInventoryMismatch' 
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
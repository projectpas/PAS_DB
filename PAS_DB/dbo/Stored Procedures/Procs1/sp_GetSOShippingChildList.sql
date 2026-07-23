-- ===== PROCEDURE: [dbo].[sp_GetSOShippingChildList]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs1/sp_GetSOShippingChildList.sql) =====
/*************************************************************           
 ** File:   [sp_GetSOShippingChildList]           
 ** Author:   
 ** Description: 
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
	1	01/31/2024		AMIT GHEDIYA		Added IsPerforma for Billing
	2	10/15/2024		VISHAL SUTHAR		Modified to make use of new SO part tables
	3   11/26/2024		Amit Ghediya		Get ECCN,HSCODE,Weight,LWH for billing.
 	4	16 Jun 2025	    RAJESH GAMI			Change the new billing invoicing table with old one (SO)    
	5	11 July 2025	RAJESH GAMI			Get SOShipping ID from the BIlling Invoicing If it's posted  
	6   10 Nov 2025		Rajesh Gami			Added [UPSPdfPath]	
	7   12 Jan 2026		VISHAL SUTHAR		Fixed issue populating duplicate shipping records for same stockline (specifically for SA to allow multiple invoice for posted one)
	8	25 APR 2026     RAJESH GAMI         Added MastercompanyId in the condition 
	9	09/July/2026 RAJESH GAMI     [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	10	20/July/2026 RAJESH GAMI     [PN-17350] - Removed IsNonStock=0 filter so Non-Stock stockline fields populate correctly on the shipping list.
 EXEC [dbo].[sp_GetSOShippingChildList] 1272, 318, 7  
**************************************************************/
CREATE   PROCEDURE [dbo].[sp_GetSOShippingChildList]  
 @SalesOrderId  bigint,  
 @SalesOrderPartId bigint,  
 @ConditionId bigint  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
 BEGIN TRY  
 BEGIN TRANSACTION  
 BEGIN  
 	 DECLARE @soModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'SalesOrder')
	 DECLARE @masterCompanyId BIGINT = (SELECT TOP 1 MasterCompanyId FROM dbo.SalesOrder WITH(NOLOCK) WHERE SalesOrderId = @SalesOrderId)
	  SELECT DISTINCT sopt.SOPickTicketId, sos.SalesOrderShippingId, CASE WHEN sosi.SalesOrderPartId IS NOT NULL THEN sos.ShipDate ELSE NULL END AS ShipDate,  
			 CASE WHEN sosi.SalesOrderPartId IS NOT NULL THEN sos.SOShippingNum ELSE NULL END AS SOShippingNum,  
			 sopt.SOPickTicketNumber, sopt.QtyToShip, so.SalesOrderNumber, imt.partnumber, imt.PartDescription, sl.StockLineNumber,  
			 sl.SerialNumber, cr.[Name] as CustomerName, soc.CustomsValue, soc.CommodityCode, ISNULL(sosi.QtyShipped,0) as QtyShipped, 0 AS ItemNo,-- sop.ItemNo,  
			 sos.SalesOrderId, (CASE WHEN sosi.SalesOrderPartId IS NOT NULL THEN sosi.SalesOrderPartId ELSE sop.SalesOrderPartId END) SalesOrderPartId,  
			 sos.AirwayBill, SPB.PackagingSlipNo, SPB.PackagingSlipId,   
			 CASE WHEN sos.SalesOrderShippingId IS NOT NULL THEN sos.SmentNum ELSE 0 END AS 'SmentNo',  
			 --(CASE WHEN ISNULL(BI.IsInvoicePosted,0) = 1 THEN SOBI.ShippingId ELSE 0 END) AS  SOShippingId,
			 (CASE WHEN ISNULL(InvoiceData.IsInvoicePosted,0) = 1 THEN InvoiceData.ShippingId ELSE 0 END) AS SOShippingId,
			 sosi.FedexPdfPath,
			 Stk.ECCN AS ECCN,
			 Stk.HSCODE AS HSCODE,
			 Stk.[Weight] AS [Weight],
			 Stk.SizeLength AS SizeLength,
			 Stk.SizeWidth AS SizeWidth,
			 Stk.SizeHeight AS SizeHeight,
			 ISNULL(sosi.UPSPdfPath,'') UpsPdfPath
	  FROM DBO.SOPickTicket sopt WITH (NOLOCK)   
	  INNER JOIN DBO.SalesOrderPartV1 sop WITH (NOLOCK) ON sop.SalesOrderId = sopt.SalesOrderId AND sop.SalesOrderPartId = sopt.SalesOrderPartId  
	  LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderStocklineId = sopt.SalesOrderPartStocklineId --stk.SalesOrderPartId = sop.SalesOrderPartId  
	  LEFT JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) ON sosi.SalesOrderPartId = sop.SalesOrderPartId   
		 AND sosi.SOPickTicketId = sopt.SOPickTicketId  
	  LEFT JOIN DBO.SalesOrderShipping sos WITH (NOLOCK) ON sos.SalesOrderShippingId = sosi.SalesOrderShippingId   
		 AND sos.SalesOrderId = sopt.SalesOrderId  
	  INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId  
	  LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId  
	  LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = stk.StockLineId  
	  LEFT JOIN DBO.SalesOrderCustomsInfo soc WITH (NOLOCK) ON soc.SalesOrderShippingId = sos.SalesOrderShippingId  
	  LEFT JOIN DBO.Customer cr WITH (NOLOCK)  on cr.CustomerId = so.CustomerId  
	  LEFT JOIN DBO.SalesOrderPackaginSlipItems SPI WITH (NOLOCK) ON sopt.SOPickTicketId = SPI.SOPickTicketId   
		 AND SPI.SalesOrderPartId = sop.SalesOrderPartId AND SPI.MasterCompanyId = @masterCompanyId AND ISNULL(SPI.IsDeleted,0) = 0
	  LEFT JOIN DBO.SalesOrderPackaginSlipHeader SPB WITH (NOLOCK) ON SPB.PackagingSlipId = SPI.PackagingSlipId  AND SPB.SalesOrderId = sopt.SalesOrderId AND ISNULL(SPB.IsDeleted,0) = 0
	  --LEFT JOIN DBO.BillingInvoicingItems SOBI  WITH (NOLOCK) ON sosi.SalesOrderShippingId = SOBI.ShippingId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0 AND SOBI.ModuleId = @soModuleId AND ISNULL(SOBI.IsVersionIncrease,0) = 0
	  --LEFT JOIN DBO.BillingInvoicing BI  WITH (NOLOCK) ON SOBI.BillingInvoicingId = BI.BillingInvoicingId AND BI.ModuleId = @soModuleId AND ISNULL(BI.IsVersionIncrease,0) = 0 
	  OUTER APPLY
	  ( SELECT TOP 1 SOBI.ShippingId, BI.IsInvoicePosted
		FROM DBO.BillingInvoicingItems SOBI WITH (NOLOCK) INNER JOIN DBO.BillingInvoicing BI WITH (NOLOCK) ON BI.BillingInvoicingId = SOBI.BillingInvoicingId
		WHERE SOBI.ShippingId = sosi.SalesOrderShippingId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0 AND SOBI.ModuleId = @soModuleId AND ISNULL(SOBI.IsVersionIncrease,0) = 0 AND BI.ModuleId = @soModuleId AND ISNULL(BI.IsVersionIncrease,0) = 0
		ORDER BY BI.BillingInvoicingId DESC
	  ) InvoiceData
	  WHERE sopt.SalesOrderId = @SalesOrderId  
	  AND sop.ItemMasterId = @SalesOrderPartId  
	  AND sop.ConditionId = @ConditionId  
	  AND ISNULL(sopt.IsConfirmed,0) = 1  AND sopt.MasterCompanyId = @masterCompanyId
 END  
 COMMIT  TRANSACTION  
  
 END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'sp_GetSOShippingChildList'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''',  
              @Parameter2 = ' + ISNULL(@SalesOrderPartId,'') + ''  
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
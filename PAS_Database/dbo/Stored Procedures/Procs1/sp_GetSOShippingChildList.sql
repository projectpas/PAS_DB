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
	8   31/03/2026      Moin Bloch	        Modified Added UOM Changes PN-15067

 EXEC [dbo].[sp_GetSOShippingChildList] 1272, 318, 7  
**************************************************************/
CREATE   Procedure [dbo].[sp_GetSOShippingChildList]  
 @SalesOrderId  bigint,  
 @SalesOrderPartId bigint,  
 @ConditionId bigint  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
 BEGIN TRY  
 --BEGIN TRANSACTION  
 --BEGIN  
 	 DECLARE @soModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'SalesOrder')
	  SELECT DISTINCT sopt.SOPickTicketId, sos.SalesOrderShippingId, CASE WHEN sosi.SalesOrderPartId IS NOT NULL THEN sos.ShipDate ELSE NULL END AS ShipDate,  
			 CASE WHEN sosi.SalesOrderPartId IS NOT NULL THEN sos.SOShippingNum ELSE NULL END AS SOShippingNum,  
			 sopt.SOPickTicketNumber, 
			 --sopt.QtyToShip, 
			 ISNULL([dbo].[fn_ConvertUOM](ISNULL(sopt.[QtyToShip],0),imt.[StockUnitOfMeasure], imt.[ConsumeUnitOfMeasure],0,so.[MasterCompanyId]),0) AS QtyToShip,		
			 so.SalesOrderNumber, 
			 imt.partnumber, 
			 imt.PartDescription, 
			 sl.StockLineNumber,  
			 sl.SerialNumber, 
			 cr.[Name] as CustomerName, 
			 soc.CustomsValue, 
			 soc.CommodityCode, 
			 --ISNULL(sosi.QtyShipped,0) as QtyShipped, 
			 ISNULL([dbo].[fn_ConvertUOM](ISNULL(sosi.[QtyShipped],0),imt.[StockUnitOfMeasure], imt.[ConsumeUnitOfMeasure],0,so.[MasterCompanyId]),0) AS QtyShipped,		
			 0 AS ItemNo,-- sop.ItemNo,  
			 sos.SalesOrderId, 
			 (CASE WHEN sosi.SalesOrderPartId IS NOT NULL THEN sosi.SalesOrderPartId ELSE sop.SalesOrderPartId END) SalesOrderPartId,  
			 sos.AirwayBill, 
			 SPB.PackagingSlipNo, 
			 SPB.PackagingSlipId,   
			 CASE WHEN sos.SalesOrderShippingId IS NOT NULL THEN sos.SmentNum ELSE 0 END AS 'SmentNo',  
			 (CASE WHEN ISNULL(InvoiceData.IsInvoicePosted,0) = 1 THEN InvoiceData.ShippingId ELSE 0 END) AS SOShippingId,
			 sosi.FedexPdfPath,
			 Stk.ECCN AS ECCN,
			 Stk.HSCODE AS HSCODE,
			 Stk.[Weight] AS [Weight],
			 Stk.SizeLength AS SizeLength,
			 Stk.SizeWidth AS SizeWidth,
			 Stk.SizeHeight AS SizeHeight,
			 ISNULL(sosi.UPSPdfPath,'') UpsPdfPath
	  FROM [dbo].[SOPickTicket] sopt WITH (NOLOCK)   
	  INNER JOIN [dbo].[SalesOrderPartV1] sop WITH (NOLOCK) ON sop.SalesOrderId = sopt.SalesOrderId AND sop.SalesOrderPartId = sopt.SalesOrderPartId  
	   LEFT JOIN [dbo].[SalesOrderStocklineV1] stk WITH (NOLOCK) ON stk.SalesOrderStocklineId = sopt.SalesOrderPartStocklineId --stk.SalesOrderPartId = sop.SalesOrderPartId  
	   LEFT JOIN [dbo].[SalesOrderShippingItem] sosi WITH (NOLOCK) ON sosi.SalesOrderPartId = sop.SalesOrderPartId AND sosi.SOPickTicketId = sopt.SOPickTicketId  
	   LEFT JOIN [dbo].[SalesOrderShipping] sos WITH (NOLOCK) ON sos.SalesOrderShippingId = sosi.SalesOrderShippingId AND sos.SalesOrderId = sopt.SalesOrderId  
	  INNER JOIN [dbo].[SalesOrder] so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId  
	   LEFT JOIN [dbo].[ItemMaster] imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId  
	   LEFT JOIN [dbo].[Stockline] sl WITH (NOLOCK) ON sl.StockLineId = stk.StockLineId  
	   LEFT JOIN [dbo].[SalesOrderCustomsInfo] soc WITH (NOLOCK) ON soc.SalesOrderShippingId = sos.SalesOrderShippingId  
	   LEFT JOIN [dbo].[Customer] cr WITH (NOLOCK) ON cr.CustomerId = so.CustomerId  
	   LEFT JOIN [dbo].[SalesOrderPackaginSlipItems] SPI WITH (NOLOCK) ON sopt.SOPickTicketId = SPI.SOPickTicketId AND SPI.SalesOrderPartId = sop.SalesOrderPartId  
	   LEFT JOIN [dbo].[SalesOrderPackaginSlipHeader] SPB WITH (NOLOCK) ON SPB.PackagingSlipId = SPI.PackagingSlipId  
	  OUTER APPLY
	  ( SELECT TOP 1 SOBI.ShippingId, BI.IsInvoicePosted
		FROM [dbo].[BillingInvoicingItems] SOBI WITH (NOLOCK) INNER JOIN [dbo].[BillingInvoicing] BI WITH (NOLOCK) ON BI.BillingInvoicingId = SOBI.BillingInvoicingId
		WHERE SOBI.ShippingId = sosi.SalesOrderShippingId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0 AND SOBI.ModuleId = @soModuleId AND ISNULL(SOBI.IsVersionIncrease,0) = 0 AND BI.ModuleId = @soModuleId AND ISNULL(BI.IsVersionIncrease,0) = 0
		ORDER BY BI.BillingInvoicingId DESC
	  ) InvoiceData
	  WHERE sopt.SalesOrderId = @SalesOrderId  
	  AND sop.ItemMasterId = @SalesOrderPartId  
	  AND sop.ConditionId = @ConditionId  
	  AND ISNULL(sopt.IsConfirmed,0) = 1  
 --END  
 --COMMIT  TRANSACTION  
  
 END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   --ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'sp_GetSOShippingChildList'   
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesOrderId, '') AS VARCHAR(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@SalesOrderPartId, '') AS VARCHAR(100)) 
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
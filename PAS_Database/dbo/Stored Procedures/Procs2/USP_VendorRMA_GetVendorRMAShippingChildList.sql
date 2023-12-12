/*************************************************************           
 ** File:   [USP_VendorRMA_GetVendorRMAShippingChildList]          
 ** Author:   Amit Ghediya
 ** Description: This stored procedure is used to get shipping child list data.
 ** Purpose:         
 ** Date:   06/27/2023        
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author					Change Description            
 ** --   --------     -------				--------------------------------          
    1    06/27/2023   Amit Ghediya			Created
     
 EXECUTE USP_VendorRMA_GetVendorRMAShippingChildList 
**************************************************************/
CREATE      Procedure [dbo].[USP_VendorRMA_GetVendorRMAShippingChildList]  
 @VendorRMAId  bigint,  
 @VendorRMADetailId bigint,  
 @ConditionId bigint  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
 BEGIN TRY  
 BEGIN TRANSACTION  
 BEGIN  
  SELECT DISTINCT sopt.RMAPickTicketId, sos.RMAShippingId, CASE WHEN sosi.VendorRMADetailId	 IS NOT NULL THEN sos.ShipDate ELSE NULL END AS ShipDate,  
	  CASE WHEN sosi.VendorRMADetailId IS NOT NULL THEN sos.RMAShippingNum ELSE NULL END AS RMAShippingNum,  
	  sopt.RMAPickTicketNumber, sopt.QtyToShip, so.RMANumber, imt.partnumber, imt.PartDescription, sl.StockLineNumber,  
	  sl.SerialNumber, cr.[VendorName] as CustomerName, soc.CustomsValue, soc.CommodityCode, 
	  ISNULL(sosi.QtyShipped,0) as QtyShipped , --sop.ItemNo,  
	  sos.VendorRMAId, (CASE WHEN sosi.VendorRMADetailId IS NOT NULL THEN sosi.VendorRMADetailId ELSE sop.VendorRMADetailId END) VendorRMADetailId,  
	  sos.AirwayBill, SPB.PackagingSlipNo, SPB.PackagingSlipId,   
	  CASE WHEN sos.RMAShippingId IS NOT NULL THEN sos.SmentNum ELSE 0 END AS 'SmentNo',  
	 -- SOBI.SalesOrderShippingId AS  SOShippingId,
	  sosi.FedexPdfPath 
	  FROM DBO.RMAPickTicket sopt WITH (NOLOCK)   
	  INNER JOIN DBO.VendorRMADetail sop WITH (NOLOCK) ON sop.VendorRMAId = sopt.VendorRMAId   
		 AND sop.VendorRMADetailId = sopt.VendorRMADetailId  
	  LEFT JOIN DBO.RMAShippingItem sosi WITH (NOLOCK) ON sosi.VendorRMADetailId = sop.VendorRMADetailId   
		 AND sosi.RMAPickTicketId = sopt.RMAPickTicketId  
	  LEFT JOIN DBO.RMAShipping sos WITH (NOLOCK) ON sos.RMAShippingId = sosi.RMAShippingId   
		 AND sos.VendorRMAId = sopt.VendorRMAId  
	  INNER JOIN DBO.VendorRMA so WITH (NOLOCK) ON so.VendorRMAId = sop.VendorRMAId  
	  LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId  
	  LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = sop.StockLineId  
	  LEFT JOIN DBO.VendorRMACustomsInfo soc WITH (NOLOCK) ON soc.RMAShippingId = sos.RMAShippingId  
	  LEFT JOIN DBO.Vendor cr WITH (NOLOCK)  on cr.VendorId = so.VendorId  
	  LEFT JOIN DBO.VendorRMAPackaginSlipItems SPI WITH (NOLOCK) ON sopt.RMAPickTicketId = SPI.RMAPickTicketId  AND SPI.VendorRMADetailId = sop.VendorRMADetailId  
	  LEFT JOIN DBO.VendorRMAPackaginSlipHeader SPB WITH (NOLOCK) ON SPB.PackagingSlipId = SPI.PackagingSlipId  
	  --LEFT JOIN DBO.SalesOrderBillingInvoicingItem SOBI  WITH (NOLOCK) ON sosi.SalesOrderShippingId = SOBI.SalesOrderShippingId  
	  WHERE sopt.VendorRMAId = @VendorRMAId  
	  AND sop.ItemMasterId = @VendorRMADetailId  
	  AND sl.ConditionId = @ConditionId  
	  AND sopt.IsConfirmed = 1  
 END  
 COMMIT  TRANSACTION  
  
 END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'USP_VendorRMA_GetVendorRMAShippingChildList'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRMAId, '') + ''',  
              @Parameter2 = ' + ISNULL(@VendorRMADetailId,'') + ''  
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
CREATE   Procedure [dbo].[sp_GetExchangeSOShippingChildList]  
@ExchangeSalesOrderId  bigint,  
@ExchangeSalesOrderPartId bigint  
AS  
BEGIN  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
 BEGIN TRY  
 BEGIN TRANSACTION  
 BEGIN  
  select DISTINCT sopt.SOPickTicketId, sos.ExchangeSalesOrderShippingId, CASE WHEN sosi.ExchangeSalesOrderPartId IS NOT NULL THEN sos.ShipDate ELSE NULL END AS ShipDate,  
  CASE WHEN sosi.ExchangeSalesOrderPartId IS NOT NULL THEN sos.SOShippingNum ELSE NULL END AS SOShippingNum,  
  sopt.SOPickTicketNumber, sopt.QtyToShip,so.ExchangeSalesOrderNumber,imt.partnumber,imt.PartDescription,sl.StockLineNumber,  
  sl.SerialNumber,cr.[Name] as CustomerName,soc.CustomsValue,soc.CommodityCode, ISNULL(sosi.QtyShipped,0) as QtyShipped,  
  '' as ItemNo,  
  sos.ExchangeSalesOrderId, (CASE WHEN sosi.ExchangeSalesOrderPartId IS NOT NULL THEN sosi.ExchangeSalesOrderPartId ELSE sop.ExchangeSalesOrderPartId END) ExchangeSalesOrderPartId  
  ,sos.AirwayBill, SPB.PackagingSlipNo, SPB.PackagingSlipId,
  sosi.FedexPdfPath
  from DBO.ExchangeSOPickTicket sopt WITH (NOLOCK)   
  INNER JOIN DBO.ExchangeSalesOrderPart sop WITH (NOLOCK) on sop.ExchangeSalesOrderId = sopt.ExchangeSalesOrderId   
  AND sop.ExchangeSalesOrderPartId = sopt.ExchangeSalesOrderPartId  
  LEFT JOIN DBO.ExchangeSalesOrderShippingItem sosi WITH (NOLOCK) on sosi.ExchangeSalesOrderPartId = sop.ExchangeSalesOrderPartId AND sosi.SOPickTicketId = sopt.SOPickTicketId  
  LEFT JOIN DBO.ExchangeSalesOrderShipping sos WITH (NOLOCK) on sos.ExchangeSalesOrderShippingId = sosi.ExchangeSalesOrderShippingId AND sos.ExchangeSalesOrderId = sopt.ExchangeSalesOrderId  
  INNER JOIN DBO.ExchangeSalesOrder so WITH (NOLOCK) on so.ExchangeSalesOrderId = sop.ExchangeSalesOrderId  
  LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId  
  LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = sop.StockLineId  
  LEFT JOIN DBO.ExchangeSalesOrderCustomsInfo soc on soc.ExchangeSalesOrderShippingId = sos.ExchangeSalesOrderShippingId  
  LEFT JOIN DBO.Customer cr WITH (NOLOCK) on cr.CustomerId = so.CustomerId  
  LEFT JOIN DBO.ExchangeSalesOrderPackaginSlipItems SPI WITH (NOLOCK) ON sopt.SOPickTicketId = SPI.SOPickTicketId AND SPI.ExchangeSalesOrderPartId = sop.ExchangeSalesOrderPartId  
  LEFT JOIN DBO.ExchangeSalesOrderPackaginSlipHeader SPB WITH (NOLOCK) ON SPB.PackagingSlipId = SPI.PackagingSlipId  
  WHERE sopt.ExchangeSalesOrderId=@ExchangeSalesOrderId   
  --AND sopt.SalesOrderPartId = @SalesOrderPartId  
  AND sop.ItemMasterId = @ExchangeSalesOrderPartId  
  AND sopt.IsConfirmed=1  
 END  
 COMMIT  TRANSACTION  
  
 END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'sp_GetExchangeSOShippingChildList'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ExchangeSalesOrderId, '') + ''',  
              @Parameter2 = ' + ISNULL(@ExchangeSalesOrderPartId,'') + ''  
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
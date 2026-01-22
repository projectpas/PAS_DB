/*************************************************************           
 ** File:   [sp_GetROShippingChildList]
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
	1	04/18/2025		Vishal Suthar		Created
	2	09/23/2025		Bhargav Saliya		Get Weight and Dimensions from ItemMaster
    3   14 OCT 2025		Rajesh Gami			Get UOM from the stockline instead of ItemMaster Weight UOM (PN-13622)
 EXEC [dbo].[sp_GetROShippingChildList] 2566, 14, 7  
**************************************************************/
CREATE   Procedure [dbo].[sp_GetROShippingChildList]  
	@RepairOrderId  bigint,  
	@RepairOrderPartId bigint
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
 BEGIN TRY  
 BEGIN TRANSACTION  
 BEGIN  
	  SELECT DISTINCT ropt.ROPickTicketId, Ros.RepairOrderShippingId, CASE WHEN rosi.RepairOrderPartId IS NOT NULL THEN ros.ShipDate ELSE NULL END AS ShipDate,
			 CASE WHEN rosi.RepairOrderPartId IS NOT NULL THEN ros.ROShippingNum ELSE NULL END AS ROShippingNum,  
			 ropt.ROPickTicketNumber, ropt.QtyToShip, Ro.RepairOrderNumber, imt.partnumber, imt.PartDescription, sl.StockLineNumber,  
			 sl.SerialNumber, vend.VendorName as VendorName, 
			 --roc.CustomsValue, 
			 0 CustomsValue, 
			 --roc.CommodityCode, 
			 '' CommodityCode, 
			 ISNULL(rosi.QtyShipped,0) as QtyShipped, 0 AS ItemNo,-- sop.ItemNo,  
			 ros.RepairOrderId, 
			 (CASE WHEN rosi.RepairOrderPartId IS NOT NULL THEN rosi.RepairOrderPartId ELSE rop.RepairOrderPartRecordId END) RepairOrderPartId,  
			 ros.AirwayBill, 
			 SPB.PackagingSlipNo, 
			 SPB.PackagingSlipId,   
			 CASE WHEN ros.RepairOrderShippingId IS NOT NULL THEN ros.SmentNum ELSE 0 END AS 'SmentNo',  
			 --SOBI.SalesOrderShippingId AS  SOShippingId,
			 0 AS ROShippingId,
			 rosi.FedexPdfPath,
			 '' AS ECCN,
			 '' AS HSCODE,
			 ISNULL(ime.ExportWeight,0) AS [Weight],
			 ISNULL(ime.ExportSizeLength,0) AS SizeLength,
			 ISNULL(ime.ExportSizeWidth,0) AS SizeWidth,
			 ISNULL(ime.ExportSizeHeight,0) AS SizeHeight,
			 ISNULL(sl.UnitOfMeasure,'') AS weightUom,
			 ISNULL(ime.ExportSizeUnitOfMeasureName,'') AS SizeUom
	  FROM DBO.ROPickTicket ropt WITH (NOLOCK)
	  INNER JOIN DBO.RepairOrderPart rop WITH (NOLOCK) ON rop.RepairOrderId = ropt.RepairOrderId AND rop.RepairOrderPartRecordId = ropt.RepairOrderPartId  
	  LEFT JOIN DBO.RepairOrderShippingItem rosi WITH (NOLOCK) ON rosi.RepairOrderPartId = rop.RepairOrderPartRecordId
		 AND rosi.ROPickTicketId = ropt.ROPickTicketId  
	  LEFT JOIN DBO.RepairOrderShipping ros WITH (NOLOCK) ON ros.RepairOrderShippingId = rosi.RepairOrderShippingId   
		 AND ros.RepairOrderId = ropt.RepairOrderId  
	  INNER JOIN DBO.RepairOrder ro WITH (NOLOCK) ON ro.RepairOrderId = rop.RepairOrderId  
	  LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = rop.ItemMasterId  
	  LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = rop.StockLineId  
	  LEFT JOIN DBO.RepairOrderCustomsInfo soc WITH (NOLOCK) ON soc.RepairOrderShippingId = ros.RepairOrderShippingId  
	  LEFT JOIN DBO.Vendor vend WITH (NOLOCK)  on vend.VendorId = ro.VendorId
	  LEFT JOIN DBO.RepairOrderPackaginSlipItems SPI WITH (NOLOCK) ON ropt.ROPickTicketId = SPI.ROPickTicketId  AND SPI.RepairOrderPartId = rop.RepairOrderPartRecordId
	  LEFT JOIN DBO.RepairOrderPackaginSlipHeader SPB WITH (NOLOCK) ON SPB.PackagingSlipId = SPI.PackagingSlipId  
	  LEFT JOIN dbo.ItemMasterExportInfo ime WITH (NOLOCK) ON imt.ItemMasterId = ime.ItemMasterId
	  WHERE ropt.RepairOrderId = @RepairOrderId  
	  AND rop.RepairOrderPartRecordId = @RepairOrderPartId  
	  AND ropt.IsConfirmed = 1  
 END  
 COMMIT  TRANSACTION  
  
 END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'sp_GetROShippingChildList'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RepairOrderId, '') + ''',  
              @Parameter2 = ' + ISNULL(@RepairOrderPartId,'') + ''  
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

/*************************************************************             
 ** File:   [GetWorkOrderPrintPdfData]             
 ** Author:   Subhash Saliya  
 ** Description: This stored procedure is used Work order Print  Details      
 ** Purpose:           
 ** Date:   12/30/2020          
            
 ** PARAMETERS:             
 @UserType varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    06/02/2020   Subhash Saliya Created  
	2    06/28/2021   Hemant Saliya  Added Transation & Content Managment  
	3    10/12/2021   Deep Patel     add ReceivingCustomerWork join for get customer reference.  
	4	 12/04/2022   Dipak Karena	 Need to display “ACTailNum” column value  as per ticket  “PR-4693”
       
--EXEC [GetWorkOrderPrintPdfData] 176,182  
**************************************************************/  
  
Create     PROCEDURE [dbo].[GetWorkOrderPrintPdfData]  
@WorkorderId bigint,  
@workOrderPartNoId bigint  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN    
    SELECT  wo.WorkOrderId,   
      wo.CustomerId,   
      wo.CustomerName,   
      wop.Quantity,   
      woq.QuoteNumber,  
      woq.OpenDate as qouteDate,  
      '1' as NoofItem,  
      wo.CreatedBy as Preparedby,  
	  wop.CustomerReference as ronum,
      getdate() as DatePrinted,  
      wo.CreatedDate as workreqDate,  
      p.Description as Priority,  
      CASE WHEN wop.IsPMA = 1 THEN 'Yes' else 'No' END AS RestrictPMA,  
      CASE WHEN wop.IsDER = 1 THEN 'Yes' else 'No' END AS RestrictDER,  
      '' as wty,  
      '' as wtyCode, 
      imt.partnumber as IncomingPN,  
      wop.RevisedPartNumber as RevisedPN,  
      imt.PartDescription as PNDesc,  
      sl.SerialNumber as SerialNum,  
	  CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN imtr.ItemGroup ELSE  imt.ItemGroup END as 'itemGroup',
      wop.ACTailNum as ACTailNum,  
      '' as TSN,  
      '' as CSN,  
      wop.ReceivedDate as Recd_Date,  
         woq.CreatedDate as Qte_Date,  
      woq.ApprovedDate as Qte_Appvd_Date,  
      wop.CustomerRequestDate as Req_d_Date,  
      wop.EstimatedShipDate as Est_Ship_Date,  
      el.firstName +' '+ el.LastName  as TechNum,  
      ws.Stage as WOStage,  
      wo.WorkOrderNum,  
      billsitename = CASE WHEN shippingInfo.WorkOrderId > 0  THEN  shippingInfo.SoldToSiteName else billToSite.SiteName END,  
      billAddressLine1 = CASE WHEN shippingInfo.WorkOrderId > 0  THEN shippingInfo.SoldToAddress1 else billToAddress.Line1 END,  
                        billAddressLine2 = CASE WHEN shippingInfo.WorkOrderId > 0  THEN shippingInfo.SoldToAddress2 else billToAddress.Line2 END,  
                        billCity = CASE WHEN shippingInfo.WorkOrderId > 0  THEN shippingInfo.SoldToCity else billToAddress.City END,  
                        billState = CASE WHEN shippingInfo.WorkOrderId > 0  THEN shippingInfo.SoldToState else billToAddress.StateOrProvince END,  
                        billPostalCode = CASE WHEN shippingInfo.WorkOrderId > 0  THEN shippingInfo.SoldToZip else billToAddress.PostalCode END,  
      billCountry = CASE WHEN shippingInfo.WorkOrderId > 0  THEN shippingInfo.SoldToCountryName else billToCountry.countries_name END,  
      billAttention = CASE WHEN shippingInfo.WorkOrderId > 0  THEN billToSiteatt.Attention else billToSite.Attention END,  
      shipSiteName = CASE WHEN shippingInfo.WorkOrderId > 0  THEN shippingInfo.ShipToSiteName else shipToSite.SiteName END,  
                        shipAttention = CASE WHEN shippingInfo.WorkOrderId > 0  THEN shipToSiteatt.Attention else shipToSite.Attention END,  
      shipAddressLine1 = CASE WHEN shippingInfo.WorkOrderId > 0  THEN shippingInfo.ShipToAddress1 else shipToAddress.Line1 END,  
                        shipAddressLine2 = CASE WHEN shippingInfo.WorkOrderId > 0  THEN shippingInfo.ShipToAddress2 else shipToAddress.Line2 END,  
                       shipCity = CASE WHEN shippingInfo.WorkOrderId > 0  THEN shippingInfo.ShipToCity else shipToAddress.City END,  
                        shipState = CASE WHEN shippingInfo.WorkOrderId > 0  THEN shippingInfo.ShipToState else shipToAddress.StateOrProvince END,  
                        shipPostalCode = CASE WHEN shippingInfo.WorkOrderId > 0  THEN shippingInfo.ShipToZip else shipToAddress.PostalCode END,  
                        shipCountry = CASE WHEN shippingInfo.WorkOrderId > 0  THEN shippingInfo.ShipToCountryName else shipToCountry.countries_name END,  
      wop.ManagementStructureId,  
      wf.WorkFlowWorkOrderId as WorkFlowWorkOrderId,  
      rc.Reference,  
      wo.UpdatedDate,  
      NHAPNs = STUFF((SELECT DISTINCT ', ' + imtt.partnumber   
       FROM Dbo.ItemMaster imtt WITH(NOLOCK) INNER JOIN Dbo.Nha_Tla_Alt_Equ_ItemMapping nhatae WITH(NOLOCK)   
       on nhatae.MappingItemMasterId = imtt.ItemMasterId   
       WHERE nhatae.ItemMasterId = imt.ItemMasterId  
       AND nhatae.IsActive = 1 AND nhatae.IsDeleted = 0  
       FOR XML PATH('')  
       ), 1, 1, ''  
      )  
    FROM Dbo.WorkOrder wo WITH(NOLOCK)  
	 INNER JOIN Dbo.WorkOrderWorkFlow wf WITH(NOLOCK) on wf.WorkOrderId = wo.WorkOrderId --and wf.WorkOrderPartNoId=wop.id
     INNER JOIN Dbo.WorkOrderPartNumber wop WITH(NOLOCK) on wop.ID = wf.WorkOrderPartNoId   
     LEFT JOIN Dbo.WorkOrderQuote woq WITH(NOLOCK) on wo.WorkOrderId = woq.WorkOrderId and woq.IsVersionIncrease=0  
     LEFT JOIN Dbo.WorkOrderShipping shippingInfo WITH(NOLOCK) on shippingInfo.WorkOrderId = wo.WorkOrderId and shippingInfo.WorkOrderPartNoId=wop.ID   
     LEFT JOIN Dbo.CustomerBillingAddress  billToSiteatt WITH(NOLOCK) on shippingInfo.SoldToSiteId = billToSiteatt.CustomerBillingAddressId  
     LEFT JOIN Dbo.CustomerDomensticShipping  shipToSiteatt WITH(NOLOCK) on shippingInfo.ShipToSiteId = shipToSiteatt.CustomerDomensticShippingId  
     LEFT JOIN Dbo.Customer billToCustomer WITH(NOLOCK) on wo.CustomerId = billToCustomer.CustomerId  
     LEFT JOIN Dbo.CustomerBillingAddress  billToSite WITH(NOLOCK) on wo.CustomerId = billToSite.CustomerId and billToSite.IsPrimary=1  
     LEFT JOIN Dbo.Address billToAddress WITH(NOLOCK) on billToSite.AddressId = billToAddress.AddressId  
     LEFT JOIN Dbo.Countries billToCountry WITH(NOLOCK) on billToCountry.countries_id = billToAddress.CountryId  
     LEFT JOIN Dbo.CustomerDomensticShipping shipToSite WITH(NOLOCK) on wo.CustomerId = shipToSite.CustomerId and shipToSite.IsPrimary=1  
     LEFT JOIN Dbo.Address shipToAddress WITH(NOLOCK) on shipToSite.AddressId = shipToAddress.AddressId  
     LEFT JOIN Dbo.Countries shipToCountry WITH(NOLOCK) on shipToAddress.CountryId = shipToCountry.countries_id  
     LEFT JOIN Dbo.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId  
     LEFT JOIN Dbo.ItemMaster rimt WITH(NOLOCK) on rimt.ItemMasterId = wop.RevisedPartId 
	 LEFT JOIN Dbo.ItemMaster imtr WITH(NOLOCK) on imtr.ItemMasterId = wop.RevisedItemmasterid 
     LEFT JOIN Dbo.Priority p WITH(NOLOCK) on p.PriorityId = wop.WorkOrderPriorityId  
     LEFT JOIN Dbo.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId  
     LEFT JOIN Dbo.Employee el WITH(NOLOCK) on el.EmployeeId = wop.TechnicianId  
     LEFT JOIN Dbo.WorkOrderStage ws WITH(NOLOCK) on ws.WorkOrderStageId = wop.WorkOrderStageId  
     LEFT JOIN Dbo.ReceivingCustomerWork rc WITH(NOLOCK) on rc.ReceivingCustomerWorkId = wop.ReceivingCustomerWorkId 
    WHERE wo.WorkOrderId = @WorkorderId AND wop.ID = @workOrderPartNoId  
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderPrintPdfData'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + '''  
                @Parameter2 = ' + ISNULL(@workOrderPartNoId ,'') +''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
              exec spLogException   
                       @DatabaseName           = @DatabaseName  
                     , @AdhocComments          = @AdhocComments  
                     , @ProcedureParameters    = @ProcedureParameters  
                     , @ApplicationName        = @ApplicationName  
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END
CREATE    PROCEDURE [dbo].[GetSubWorkOrderPrintPdfData]      
@subWorkOrderId bigint,      
@subWOPartNoId bigint      
AS      
BEGIN      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 SET NOCOUNT ON;      
      
  BEGIN TRY      
  BEGIN TRANSACTION      
   BEGIN     
       
    DECLARE @WorkScopeId AS BIGINT = 0;            
    DECLARE @ItemMasterId AS BIGINT = 0;            
    DECLARE @TravelerName AS varchar(250) = 0;            
    SELECT TOP 1 @ItemMasterId=ItemMasterId,@WorkScopeId=SubWorkOrderScopeId FROM dbo.SubWorkOrderPartNumber WITH(NOLOCK) WHERE SubWOPartNoId=@subWOPartNoId            
                 
     IF(EXISTS (SELECT 1 FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and ItemMasterId=ItemMasterId and IsVersionIncrease=0))            
     BEGIN            
        SELECT top 1 @TravelerName= TravelerId FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and ItemMasterId=ItemMasterId and IsVersionIncrease=0            
     END            
     else IF(EXISTS (SELECT 1 FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and IsVersionIncrease=0))            
     BEGIN            
        SELECT top 1 @TravelerName= TravelerId FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and ItemMasterId is null and IsVersionIncrease=0            
     END       
    
    SELECT  wo.WorkOrderId,       
      wo.CustomerId,       
      UPPER(wo.CustomerName) as CustomerName,     
      swo.SubWorkOrderId,     
   wop.SubWOPartNoId,     
      wop.Quantity,       
      UPPER(swo.SubWorkOrderNo) as QuoteNumber,      
      null as qouteDate,      
      '1' as NoofItem,      
      wo.CreatedBy as Preparedby,      
      '' as ronum,      
      getdate() as DatePrinted,      
      wo.CreatedDate as workreqDate,      
      CASE WHEN LEN(wo.notes) > 350 THEN LEFT(wo.notes,350) + '...' ELSE wo.notes END AS notes,  
      p.Description as Priority,     
      case when wop.IsPMA=1 then 'Yes' else 'No' end as RestrictPMA,      
      case when wop.IsDER=1 then 'Yes' else 'No' end as RestrictDER,      
      '' as wty,      
      '' as wtyCode,      
          UPPER(imt.partnumber) as IncomingPN,              
   CASE WHEN isnull(wosc.RevisedItemmasterid,0) >0 THEN  UPPER(rimt.partnumber) ELSE UPPER(imt.partnumber) END as RevisedPN,        
      UPPER(imt.PartDescription) as PNDesc,              
      UPPER(sl.SerialNumber) as SerialNum,              
   CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN UPPER(imtr.ItemGroup) ELSE  UPPER(imt.ItemGroup) END as 'itemGroup',      
      sl.AircraftTailNumber as ACTailNum,      
      '' as TSN,      
      '' as CSN,      
     FORMAT(wop.CustomerRequestDate, 'MM/dd/yyyy')  as Recd_Date,      
      '' as Qte_Date,      
      '' as Qte_Appvd_Date,      
      wop.CustomerRequestDate as Req_d_Date,      
      wop.EstimatedShipDate as Est_Ship_Date,      
      UPPER(el.EmployeeCode)  as TechNum,              
      UPPER(ws.Stage) as WOStage,              
      UPPER(wo.WorkOrderNum) as WorkOrderNum,       
      billsitename =  billToSite.SiteName,      
      billAddressLine1 =  billToAddress.Line1,      
                        billAddressLine2 =  billToAddress.Line2,      
                        billCity = billToAddress.City,      
                        billState = billToAddress.StateOrProvince,      
                        billPostalCode =billToAddress.PostalCode ,      
      billCountry =  billToCountry.countries_name ,      
      billAttention =  billToSite.Attention,      
      shipSiteName =  shipToSite.SiteName,      
                        shipAttention =  shipToSite.Attention,      
      shipAddressLine1 = shipToAddress.Line1,      
                        shipAddressLine2 = shipToAddress.Line2,      
                        shipCity =  shipToAddress.City,      
                        shipState =  shipToAddress.StateOrProvince,      
                        shipPostalCode = shipToAddress.PostalCode,      
   shipCountry = shipToCountry.countries_name,      
      ManagementStructureId = (select top 1 ManagementStructureId from WorkOrderPartNumber WITH(NOLOCK) where WorkOrderId=wo.WorkOrderId),      
      wop.WorkflowId as WorkFlowWorkOrderId,      
      swo.UpdatedDate,    
   UPPER(wop.CustomerReference) as Reference,              
   CASE WHEN ISNULL(wosc.conditionName,'') = '' THEN UPPER(con.Description) ELSE UPPER(wosc.conditionName) END as ReceivedCond,            
   UPPER(Wos.WorkScopeCode) as WorkScope,            
   UPPER(Pub.PublicationId) as PublicationName,            
   CASE WHEN ISNULL(sl.OEM, 0) = 0 THEN 'YES' ELSE 'NO' END as 'OEM',            
   @TravelerName as TravelerName,         
   Isnull(wop.IsManualForm,0) as IsManualForm,    
      NHAPNs = STUFF((SELECT DISTINCT ', ' + imtt.partnumber               
       FROM Dbo.ItemMaster imtt WITH(NOLOCK) INNER JOIN Dbo.Nha_Tla_Alt_Equ_ItemMapping nhatae WITH(NOLOCK)               
       on nhatae.MappingItemMasterId = imtt.ItemMasterId               
       WHERE nhatae.ItemMasterId = imt.ItemMasterId              
       AND nhatae.IsActive = 1 AND nhatae.IsDeleted = 0              
       FOR XML PATH('')              
       ), 1, 1, ''              
      )     
    FROM Dbo.SubWorkOrder swo WITH(NOLOCK)      
     INNER JOIN Dbo.SubWorkOrderPartNumber wop WITH(NOLOCK) on wop.SubWorkOrderId = swo.SubWorkOrderId --AND wop.ID = wopt.OrderPartId      
     inner join Dbo.WorkOrder wo WITH(NOLOCK) on wo.WorkOrderId= swo.WorkOrderId     
     LEFT JOIN Dbo.Customer billToCustomer WITH(NOLOCK) on wo.CustomerId = billToCustomer.CustomerId      
     LEFT JOIN Dbo.CustomerBillingAddress  billToSite WITH(NOLOCK) on wo.CustomerId = billToSite.CustomerId and billToSite.IsPrimary=1      
     LEFT JOIN Dbo.Address billToAddress WITH(NOLOCK) on billToSite.AddressId = billToAddress.AddressId      
     left JOIN Dbo.Countries billToCountry WITH(NOLOCK) on billToCountry.countries_id = billToAddress.CountryId      
     LEFT JOIN Dbo.CustomerDomensticShipping shipToSite WITH(NOLOCK) on wo.CustomerId = shipToSite.CustomerId and shipToSite.IsPrimary=1      
     LEFT JOIN Dbo.Address shipToAddress WITH(NOLOCK) on shipToSite.AddressId = shipToAddress.AddressId      
     LEFT JOIN Dbo.Countries shipToCountry WITH(NOLOCK) on shipToAddress.CountryId = shipToCountry.countries_id      
     LEFT JOIN Dbo.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId      
     LEFT JOIN Dbo.Priority p  WITH(NOLOCK) on p.PriorityId = wop.SubWorkOrderPriorityId      
     LEFT JOIN Dbo.WorkOrderStage ws WITH(NOLOCK) on ws.WorkOrderStageId = wop.SubWorkOrderStageId      
     LEFT JOIN Dbo.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId      
     LEFT JOIN Dbo.Employee el WITH(NOLOCK) on el.EmployeeId = wop.TechnicianId      
  LEFT JOIN Dbo.ItemMaster rimt WITH(NOLOCK) on rimt.ItemMasterId = wop.RevisedItemmasterid    
  LEFT JOIN dbo.SubWorkOrderSettlementDetails wosc WITH(NOLOCK) on wop.SubWorkOrderId = wosc.SubWorkOrderId AND wop.SubWOPartNoId = wosc.SubWOPartNoId AND wosc.WorkOrderSettlementId = 9     
  LEFT JOIN Dbo.ItemMaster imtr WITH(NOLOCK) on imtr.ItemMasterId = wop.RevisedItemmasterid     
  LEFT JOIN Dbo.Condition Rcon WITH(NOLOCK) on Rcon.ConditionId = wop.RevisedConditionId             
     LEFT JOIN Dbo.Condition con WITH(NOLOCK) on con.ConditionId = wop.ConditionId     
  LEFT JOIN Dbo.WorkScope Wos WITH(NOLOCK) on Wos.WorkScopeId = wop.SubWorkOrderScopeId    
  LEFT JOIN Dbo.Publication Pub WITH(NOLOCK) on Pub.PublicationRecordId = wop.CMMId       
    WHERE swo.SubWorkOrderId = @subWorkOrderId AND wop.SubWOPartNoId = @subWOPartNoId      
  END      
  COMMIT  TRANSACTION      
  END TRY          
  BEGIN CATCH            
   IF @@trancount > 0      
    PRINT 'ROLLBACK'      
    ROLLBACK TRAN;      
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
              , @AdhocComments     VARCHAR(150)    = 'GetSubWorkOrderPrintPdfData'       
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@subWorkOrderId, '') + '''      
                @Parameter2 = ' + ISNULL(@subWOPartNoId ,'') +''      
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
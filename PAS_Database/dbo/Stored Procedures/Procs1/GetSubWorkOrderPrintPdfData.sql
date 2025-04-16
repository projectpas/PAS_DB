/*************************************************************  
** Author:  <Hemant Saliya>  
** Create date: <01/23/2023>  
** Description: <Get Work order Release Form Data>  
 
EXEC [GetSubWorkorderReleaseFromData]
**************************************************************
** Change History
**************************************************************  
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    05/26/2023  HEMANT SALIYA    Updated For WorkOrder Settings
** 2    12/21/2023  Devendra Shekh   sub print form issue resolved
** 3    20/02/2024  Shrey Chandegara  Updated for Technum is getting wrong.
** 4    17/02/2025   Moin Bloch       Updated (Added Publication PublicationNo)
** 5    28/02/2025   RAJESH GAMI      Modify the SP WO Part details to Sub Wo Part detail (Previously showoing WO MPN Details instead of SubWOMPN detail)
** 6    04/16/2025   Devendra Shekh   Added IsLaborTrackingTurnedOff to select
EXEC GetSubWorkOrderPrintPdfData 573,559

**************************************************************/
CREATE   PROCEDURE [dbo].[GetSubWorkOrderPrintPdfData]              
@SubWorkorderId bigint,              
@SubWOPartNoId bigint              
AS              
	BEGIN              
	 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED              
	 SET NOCOUNT ON;              
             
	  BEGIN TRY              
	  BEGIN TRANSACTION              
	   BEGIN            
			DECLARE @WorkScopeId AS BIGINT = 0;            
			DECLARE @ItemMasterId AS BIGINT = 0;         
			DECLARE @WOPartNoId AS BIGINT = 0;  
			DECLARE @TravelerName AS varchar(250) = '';            
   
			SELECT TOP 1 @ItemMasterId=ItemMasterId,@WorkScopeId = SubWorkOrderScopeId FROM dbo.SubWorkOrderPartNumber WITH(NOLOCK) WHERE SubWOPartNoId = @SubWOPartNoId 
			--SELECT TOP 1 @ItemMasterId=ItemMasterId,@WorkScopeId=WorkOrderScopeId FROM dbo.WorkOrderPartNumber WITH(NOLOCK) WHERE ID=@WorkOrderPartNoId            
                 
			IF(EXISTS (SELECT 1 FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and ItemMasterId=@ItemMasterId and IsVersionIncrease=0))            
			BEGIN            
			SELECT top 1 @TravelerName= TravelerId FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and ItemMasterId=@ItemMasterId and IsVersionIncrease=0            
			END            
			ELSE IF(EXISTS (SELECT 1 FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and IsVersionIncrease=0))            
			BEGIN            
			SELECT top 1 @TravelerName= TravelerId FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and ISNULL(ItemMasterId,0)=0 and IsVersionIncrease=0            
			END            
           
			SELECT DISTINCT wo.WorkOrderId,              
				wo.CustomerId,              
				UPPER(wo.CustomerName) as CustomerName,              
				SWOPN.Quantity,              
				--woq.QuoteNumber,   
				SWO.SubWorkOrderNo as 'QuoteNumber',
				woq.OpenDate as qouteDate,              
				'1' as NoofItem,              
				wo.CreatedBy as Preparedby,              
				UPPER(wop.CustomerReference) as ronum,            
				getdate() as DatePrinted,              
				wo.CreatedDate as workreqDate,      
				CASE WHEN LEN(wo.notes) > 1370 THEN LEFT(wo.notes,1370) + '...' ELSE wo.notes END AS notes,    
				p.Description as Priority,              
				CASE WHEN SWOPN.IsPMA = 1 THEN 'YES' else 'NO' END AS RestrictPMA,              
				CASE WHEN SWOPN.IsDER = 1 THEN 'YES' else 'NO' END AS RestrictDER,              
				'' as wty,              
				'' as wtyCode,            
				UPPER(imt.partnumber) as IncomingPN,              
				CASE WHEN isnull(imtr.RevisedPartId,0) >0 THEN  UPPER(imtr.partnumber) ELSE UPPER(imt.partnumber) END as RevisedPN,        
				CASE WHEN LEN(UPPER(imt.PartDescription)) > 30 then LEFT(UPPER(imt.PartDescription), 30) + '...' else  UPPER(imt.PartDescription) end as PNDesc,              
				UPPER(sl.SerialNumber) as SerialNum,              
				CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN UPPER(imtr.ItemGroup) ELSE  UPPER(imt.ItemGroup) END as 'itemGroup',            
				wop.ACTailNum as ACTailNum,              
				'' as TSN,              
				'' as CSN,    
				--FORMAT(wop.ReceivedDate, 'MM/dd/yyyy') AS Recd_Date,
				CAST(CONVERT(VARCHAR(30), wop.ReceivedDate, 101) AS DATE) AS Recd_Date,
				wop.ReceivedDate,
				woq.CreatedDate as Qte_Date,              
				woq.ApprovedDate as Qte_Appvd_Date,              
				wop.CustomerRequestDate as Req_d_Date,              
				wop.EstimatedShipDate as Est_Ship_Date,              
				UPPER(el.EmployeeCode)  as TechNum,              
				UPPER(ws.Stage) as WOStage,              
				UPPER(wo.WorkOrderNum) as WorkOrderNum,              
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
				UPPER(rc.Reference) as Reference,              
				wo.UpdatedDate,            
				  CASE WHEN ISNULL(Rcon.ConditionId,0) = 0 THEN UPPER(con.Description) ELSE UPPER(Rcon.Description) END as ReceivedCond,            
				  UPPER(scope.WorkScopeCode) as WorkScope,            
				  --UPPER(Pub.PublicationId) as PublicationName, 
				  UPPER(SWOPN.PublicationNo) as PublicationName, 
				  CASE WHEN ISNULL(sl.OEM, 0) = 0 THEN 'YES' ELSE 'NO' END as 'OEM',            
				  @TravelerName as TravelerName,        
				  Isnull(wost.IsManualForm,0) as IsManualForm,    
				  NHAPNs = STUFF((SELECT DISTINCT ', ' + imtt.partnumber              
				FROM Dbo.ItemMaster imtt WITH(NOLOCK) INNER JOIN Dbo.Nha_Tla_Alt_Equ_ItemMapping nhatae WITH(NOLOCK)              
				   on nhatae.MappingItemMasterId = imtt.ItemMasterId              
				   WHERE nhatae.ItemMasterId = imt.ItemMasterId              
				   AND nhatae.IsActive = 1 AND nhatae.IsDeleted = 0              
				   FOR XML PATH('')              
				   ), 1, 1, '')
				   ,(SELECT TOP 1 ISNULL(SWLH.IsLaborTrackingTurnedOff, 0) FROM [dbo].[SubWorkOrderLaborHeader] SWLH WITH(NOLOCK) WHERE SWLH.SubWorkOrderId = SWOPN.SubWorkOrderId AND SWLH.SubWOPartNoId = SWOPN.SubWOPartNoId AND SWLH.WorkOrderId = SWOPN.WorkOrderId AND ISNULL(isDeleted, 0) = 0) AS IsLaborTrackingTurnedOff
			FROM dbo.SubWorkOrder SWO WITH(NOLOCK) 
				INNER JOIN dbo.SubWorkOrderPartNumber SWOPN WITH(NOLOCK) ON SWO.SubWorkOrderId = SWOPN.SubWorkOrderId
				INNER JOIN Dbo.WorkOrder wo WITH(NOLOCK) ON SWO.WorkOrderId = wo.WorkOrderId             
				LEFT JOIN Dbo.WorkOrderWorkFlow wf WITH(NOLOCK) on wf.WorkOrderId = wo.WorkOrderId --and wf.WorkOrderPartNoId=@workOrderPartNoId    
				INNER JOIN Dbo.WorkOrderPartNumber wop WITH(NOLOCK) on wop.ID = SWO.WorkOrderPartNumberId
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
				LEFT JOIN Dbo.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = SWOPN.ItemMasterId              
				LEFT JOIN Dbo.ItemMaster imtr WITH(NOLOCK) on imtr.ItemMasterId = SWOPN.RevisedItemmasterid            
				LEFT JOIN Dbo.Priority p WITH(NOLOCK) on p.PriorityId = SWOPN.SubWorkOrderPriorityId              
				LEFT JOIN Dbo.Stockline sl WITH(NOLOCK) on sl.StockLineId = SWOPN.StockLineId              
				LEFT JOIN Dbo.Employee el WITH(NOLOCK) on el.EmployeeId = SWOPN.TechnicianId              
				LEFT JOIN Dbo.WorkOrderStage ws WITH(NOLOCK) on ws.WorkOrderStageId = SWOPN.SubWorkOrderStageId              
				LEFT JOIN Dbo.ReceivingCustomerWork rc WITH(NOLOCK) on rc.ReceivingCustomerWorkId = wop.ReceivingCustomerWorkId            
				LEFT JOIN Dbo.Condition Rcon WITH(NOLOCK) on Rcon.ConditionId = SWOPN.RevisedConditionId            
				LEFT JOIN Dbo.Condition con WITH(NOLOCK) on con.ConditionId = SWOPN.ConditionId            
				LEFT JOIN Dbo.WorkOrderSettings wost WITH(NOLOCK) on wost.MasterCompanyId = wop.MasterCompanyId AND wo.WorkOrderTypeId = wost.WorkOrderTypeId
				LEFT JOIN dbo.WorkScope scope WITH(NOLOCK) on SWOPN.SubWorkOrderScopeId = scope.WorkScopeId
			WHERE SWO.SubWorkOrderId = @SubWorkorderId AND SWOPN.SubWOPartNoId = @SubWOPartNoId              
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
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWorkOrderId, '') + '''              
                @Parameter2 = ' + ISNULL(@SubWOPartNoId ,'') +''              
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
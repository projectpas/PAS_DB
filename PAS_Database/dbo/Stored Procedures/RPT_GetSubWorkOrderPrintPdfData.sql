/*************************************************************  
** Author:  <AMIT GHEDIYA>  
** Create date: <01/01/2024>  
** Description: <Get Work order Release Form Data>  
 
EXEC [RPT_GetSubWorkOrderPrintPdfData]
**************************************************************
** Change History
**************************************************************  
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    01/01/2024  AMIT GHEDIYA    Created
** 2    04/25/2024  Devendra Shekh  reading data for SubWOMpn in place of WOMpn
** 3    05/02/2024  Devendra Shekh  duplicate mpn for multiple wo mpn, issue resolved

EXEC RPT_GetSubWorkOrderPrintPdfData 208,186

**************************************************************/
CREATE   PROCEDURE [dbo].[RPT_GetSubWorkOrderPrintPdfData]              
	@SubWorkorderId BIGINT,              
	@SubWOPartNoId BIGINT              
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
			DECLARE @TravelerName AS varchar(250) = 0;            
   
			SELECT TOP 1 @ItemMasterId=ItemMasterId,@WorkScopeId = SubWorkOrderScopeId FROM dbo.SubWorkOrderPartNumber WITH(NOLOCK) WHERE SubWOPartNoId = @SubWOPartNoId 
			--SELECT TOP 1 @ItemMasterId=ItemMasterId,@WorkScopeId=WorkOrderScopeId FROM dbo.WorkOrderPartNumber WITH(NOLOCK) WHERE ID=@WorkOrderPartNoId            
                 
			IF(EXISTS (SELECT 1 FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and ItemMasterId=ItemMasterId and IsVersionIncrease=0))            
			BEGIN            
			SELECT top 1 @TravelerName= TravelerId FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and ItemMasterId=ItemMasterId and IsVersionIncrease=0            
			END            
			ELSE IF(EXISTS (SELECT 1 FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and IsVersionIncrease=0))            
			BEGIN            
			SELECT top 1 @TravelerName= TravelerId FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and ItemMasterId is null and IsVersionIncrease=0            
			END            
           
			SELECT DISTINCT wo.WorkOrderId,              
				wo.CustomerId,              
				UPPER(wo.CustomerName) as CustomerName,              
				SWOPN.Quantity,              
				--woq.QuoteNumber,   
				UPPER(SWO.SubWorkOrderNo) as 'QuoteNumber',
				woq.OpenDate as qouteDate,              
				'1' as NoofItem,              
				UPPER(wo.CreatedBy) as Preparedby,              
				UPPER(SWOPN.CustomerReference) as ronum,            
				getdate() as DatePrinted,              
				wo.CreatedDate as workreqDate,      
				CASE WHEN LEN(wo.notes) > 1370 THEN LEFT(wo.notes,1370) + '...' ELSE wo.notes END AS notes,    
				p.Description as Priority,              
				CASE WHEN SWOPN.IsPMA = 1 THEN 'YES' else 'NO' END AS RestrictPMA,              
				CASE WHEN SWOPN.IsDER = 1 THEN 'YES' else 'NO' END AS RestrictDER,              
				'' as wty,              
				'' as wtyCode,            
				UPPER(imt.partnumber) as IncomingPN,              
				CASE WHEN isnull(swosc.RevisedItemmasterid,0) >0 THEN  UPPER(rimt.partnumber) ELSE UPPER(imt.partnumber) END as RevisedPN,        
				CASE WHEN LEN(UPPER(imt.PartDescription)) > 15 then LEFT(UPPER(imt.PartDescription), 15) + '...' else  UPPER(imt.PartDescription) end as PNDesc,              
				UPPER(sl.SerialNumber) as SerialNum,              
				CASE WHEN ISNULL(SWOPN.RevisedItemmasterid, 0) > 0 THEN UPPER(imtr.ItemGroup) ELSE  UPPER(imt.ItemGroup) END as 'itemGroup',            
				UPPER(wop.ACTailNum) as ACTailNum,              
				'' as TSN,              
				'' as CSN,    
				FORMAT(wop.ReceivedDate, 'MM/dd/yyyy') AS Recd_Date,
				wop.ReceivedDate,
				woq.CreatedDate as Qte_Date,              
				woq.ApprovedDate as Qte_Appvd_Date,              
				SWOPN.CustomerRequestDate as Req_d_Date,              
				SWOPN.EstimatedShipDate as Est_Ship_Date,              
				UPPER(el.EmployeeCode)  as TechNum,              
				UPPER(ws.Stage) as WOStage,              
				UPPER(wo.WorkOrderNum) as WorkOrderNum,              
				billsitename = CASE WHEN shippingInfo.WorkOrderId > 0  THEN  shippingInfo.SoldToSiteName else billToSite.SiteName END,              
				billAddressLine1 = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToAddress1) else UPPER(billToAddress.Line1) END,              
				billAddressLine2 = CASE WHEN shippingInfo.WorkOrderId > 0  THEN shippingInfo.SoldToAddress2 else billToAddress.Line2 END,    
				
				billAddCombo = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToAddress1) + ', ' else UPPER(billToAddress.Line1) + ', ' END +
								CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToAddress2) else UPPER(billToAddress.Line2) END,
				
				billCity = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToCity) else UPPER(billToAddress.City) END,              
				  billState = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToState) else UPPER(billToAddress.StateOrProvince) END,              
				billPostalCode = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToZip) else UPPER(billToAddress.PostalCode) END,              
				
				billComboFileds = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToCity) + ', ' else UPPER(billToAddress.City) + ', ' END
					  + CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToState) else UPPER(billToAddress.StateOrProvince) END
					  + ' ' + CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToZip) else UPPER(billToAddress.PostalCode) END,
				
				billCountry = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToCountryName) else UPPER(billToCountry.countries_name) END,              
				billAttention = CASE WHEN shippingInfo.WorkOrderId > 0  THEN 'ATTN: ' + UPPER(billToSiteatt.Attention) else 'ATTN: ' + UPPER(billToSite.Attention) END,              
				shipSiteName = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToSiteName) else UPPER(shipToSite.SiteName) END,              
				shipAttention = CASE WHEN shippingInfo.WorkOrderId > 0  THEN 'ATTN: ' + UPPER(shipToSiteatt.Attention) else 'ATTN: ' + UPPER(shipToSite.Attention) END,              
				shipAddressLine1 = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToAddress1) else UPPER(shipToAddress.Line1) END,              
				shipAddressLine2 = CASE WHEN shippingInfo.WorkOrderId > 0  THEN shippingInfo.ShipToAddress2 else shipToAddress.Line2 END,  
				
				shipAddCombo = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToAddress1) + ', ' else UPPER(shipToAddress.Line1) + ', ' END +
							 CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToAddress2) else UPPER(shipToAddress.Line2) END,
				
				shipCity = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToCity) else UPPER(shipToAddress.City) END,              
				shipState = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToState) else UPPER(shipToAddress.StateOrProvince) END,              
				shipPostalCode = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToZip) else UPPER(shipToAddress.PostalCode) END,              
				
				shipComboFileds = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToCity) + ', ' else UPPER(shipToAddress.City) + ', ' END
					  + CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToState) else UPPER(shipToAddress.StateOrProvince) END
					  + ' ' + CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToZip) else UPPER(shipToAddress.PostalCode) END,

				shipCountry = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToCountryName) else UPPER(shipToCountry.countries_name) END,              
				wop.ManagementStructureId,              
				wf.WorkFlowWorkOrderId as WorkFlowWorkOrderId,              
				UPPER(rc.Reference) as Reference,              
				wo.UpdatedDate,            
				  CASE WHEN ISNULL(swosc.conditionName,'') = '' THEN UPPER(con.Description) ELSE UPPER(swosc.conditionName) END as ReceivedCond,            
				  UPPER(WSP.WorkScopeCodeNew) as WorkScope,            
				  UPPER(Pub.PublicationId) as PublicationName,            
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
			FROM dbo.SubWorkOrder SWO WITH(NOLOCK) 
				INNER JOIN dbo.SubWorkOrderPartNumber SWOPN WITH(NOLOCK) ON SWO.SubWorkOrderId = SWOPN.SubWorkOrderId
				INNER JOIN Dbo.WorkOrder wo WITH(NOLOCK) ON SWO.WorkOrderId = wo.WorkOrderId             
				INNER JOIN Dbo.WorkOrderPartNumber wop WITH(NOLOCK) on wop.ID = SWO.WorkOrderPartNumberId
				LEFT JOIN Dbo.WorkOrderWorkFlow wf WITH(NOLOCK) on wf.WorkOrderPartNoId = wop.ID --and wf.WorkOrderPartNoId=@workOrderPartNoId    
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
				--LEFT JOIN Dbo.Condition Rcon WITH(NOLOCK) on Rcon.ConditionId = wop.RevisedConditionId            
				LEFT JOIN Dbo.Condition con WITH(NOLOCK) on con.ConditionId = SWOPN.ConditionId            
				LEFT JOIN Dbo.Publication Pub WITH(NOLOCK) on Pub.PublicationRecordId = SWOPN.CMMId        
				--LEFT JOIN dbo.WorkOrderSettlementDetails wosc WITH(NOLOCK) on wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9        
				LEFT JOIN dbo.SubWorkOrderSettlementDetails swosc WITH(NOLOCK) on SWOPN.SubWorkOrderId = swosc.SubWorkOrderId AND SWOPN.SubWOPartNoId = swosc.SubWOPartNoId AND swosc.WorkOrderSettlementId = 9        
				LEFT JOIN Dbo.ItemMaster rimt WITH(NOLOCK) on rimt.ItemMasterId = swosc.RevisedItemmasterid    
				LEFT JOIN Dbo.WorkOrderSettings wost WITH(NOLOCK) on wost.MasterCompanyId = wop.MasterCompanyId AND wo.WorkOrderTypeId = wost.WorkOrderTypeId    
				LEFT JOIN Dbo.WorkScope WSP WITH(NOLOCK) on WSP.WorkScopeId = SWOPN.SubWorkOrderScopeId 
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
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetSubWorkOrderPrintPdfData'              
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
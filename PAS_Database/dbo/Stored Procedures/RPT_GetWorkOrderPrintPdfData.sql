
/*************************************************************  
** Author:  <AMIT GHEDIYA>  
** Create date: <01/01/2024>  
** Description: <Get Work order Release Form Data>  
 
EXEC [RPT_GetWorkOrderPrintPdfData]
**************************************************************
** Change History
**************************************************************  
** PR   Date        Author				Change Description  
** --   --------    -------				--------------------------------
** 1    01/01/2024  AMIT GHEDIYA		Created
** 2    02/13/2024  Vishal Suthar		Modified the WOFPrintDate field
** 3    06/28/2024  Vishal Suthar		Added IsActive and IsDeleted check in WorkOrderQuote join
** 4    09/03/2024  Ekta Chandegra		Retrieve merged address using common function
** 5	17 Sep 2024 Bhargav Saliya      address convert into single string value
** 6    08 Nov 2024 Sahdev Saliya       Added New Field RevisedSerialNumber
** 7    11 Feb 2025 RAJESH GAMI         Change the call function to store procedure (For the merge address) due to performance
** 8    17/02/2025  Moin Bloch          Updated (Added Publication PublicationNo)
** 9	13/May/2025 Bhargav Saliya	    Added IsDisplayFooter to select
** 10	15/Aug/2025 Vishal Suthar	    Changed the condition to populate current serial number
** 11	13/Nov/2025 Rajesh Gami			Added CustReqCertType
** 12   23/12/2025  Ayushi Patel		return wty(warranty) based on IsWarranty and IsAccepted field
** 13	22/JAN/2026 Priyansh Patel      Added CSN and TSN values

EXEC RPT_GetWorkOrderPrintPdfData 9747,9850

**************************************************************/
CREATE      PROCEDURE [dbo].[RPT_GetWorkOrderPrintPdfData]              
	@WorkorderId BIGINT,              
	@workOrderPartNoId BIGINT              
AS              
BEGIN              
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED              
 SET NOCOUNT ON;              
             
  BEGIN TRY              
  --BEGIN TRANSACTION              
  -- BEGIN            
		DECLARE @WorkScopeId AS BIGINT = 0;            
		DECLARE @ItemMasterId AS BIGINT = 0;            
		DECLARE @TravelerName AS varchar(250) = '';            
		DECLARE @WOFPrintDate AS DATETIME, @MergedBillToAddress AS varchar(max),@MergedShipToAddress AS varchar(max), @MergedShipAddress AS varchar(max);           
		DECLARE @Address1 NVARCHAR(255),@Address2 NVARCHAR(255),@City NVARCHAR(100),@StateOrProvince NVARCHAR(100),@PostalCode NVARCHAR(20);
		DECLARE @Country NVARCHAR(100),@PhoneNumber NVARCHAR(50),@PhoneExt NVARCHAR(10),@Email NVARCHAR(255);

		DECLARE @BAddress1 NVARCHAR(255),@BAddress2 NVARCHAR(255),@BCity NVARCHAR(100),@BStateOrProvince NVARCHAR(100),@BPostalCode NVARCHAR(20);
		DECLARE @BCountry NVARCHAR(100),@BPhoneNumber NVARCHAR(50),@BPhoneExt NVARCHAR(10),@BEmail NVARCHAR(255);

		DECLARE @SAddress1 NVARCHAR(255),@SAddress2 NVARCHAR(255),@SCity NVARCHAR(100),@SStateOrProvince NVARCHAR(100),@SPostalCode NVARCHAR(20);
		DECLARE @SCountry NVARCHAR(100),@SPhoneNumber NVARCHAR(50),@SPhoneExt NVARCHAR(10),@SEmail NVARCHAR(255);

   
		SELECT TOP 1 @ItemMasterId=ItemMasterId,@WorkScopeId=WorkOrderScopeId, @WOFPrintDate = WOFPrintDate FROM dbo.WorkOrderPartNumber WITH(NOLOCK) WHERE ID=@WorkOrderPartNoId            
                 
		IF(EXISTS (SELECT 1 FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and ItemMasterId=ItemMasterId and IsVersionIncrease=0))            
		BEGIN            
			SELECT top 1 @TravelerName= TravelerId FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and ItemMasterId=@ItemMasterId and IsVersionIncrease=0            
		END            
		ELSE IF(EXISTS (SELECT 1 FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and IsVersionIncrease=0))            
		BEGIN            
			SELECT top 1 @TravelerName= TravelerId FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and ItemMasterId is null and IsVersionIncrease=0            
		END 
		IF OBJECT_ID(N'tempdb..#TempTableData') IS NOT NULL
			BEGIN
				DROP TABLE #TempTableData
			END
        SELECT * INTO #TempTableData 
			FROM (   
			SELECT  wo.WorkOrderId,              
			wo.CustomerId,              
			UPPER(wo.CustomerName) as CustomerName,              
			wop.Quantity,              
			woq.QuoteNumber,              
			woq.OpenDate as qouteDate,              
			'1' as NoofItem,              
			UPPER(wo.CreatedBy) as Preparedby,              
			UPPER(wop.CustomerReference) as ronum,            
			@WOFPrintDate as DatePrinted,              
			wo.CreatedDate as workreqDate,      
			CASE WHEN LEN(wo.notes) > 1370 THEN LEFT(wo.notes,1370) + '...' ELSE wo.notes END AS notes,    
			p.Description as Priority,              
			CASE WHEN wop.IsPMA = 1 THEN 'YES' else 'NO' END AS RestrictPMA,              
			CASE WHEN wop.IsDER = 1 THEN 'YES' else 'NO' END AS RestrictDER,   
			CASE 
				WHEN wo.IsWarranty = 1 THEN 
					CASE 
						WHEN wo.IsAccepted = 1 THEN 'YES' 
						ELSE 'NO' 
					END
				ELSE ''
			END AS wty,
			'' as wtyCode,            
			UPPER(imt.partnumber) as IncomingPN,              
			CASE WHEN isnull(wosc.RevisedPartId,0) >0 THEN  UPPER(rimt.partnumber) ELSE UPPER(imt.partnumber) END as RevisedPN,        
			CASE WHEN LEN(UPPER(imt.PartDescription)) > 15 then LEFT(UPPER(imt.PartDescription), 15) + '...' else  UPPER(imt.PartDescription) end as PNDesc,              
			CASE WHEN WOP.CurrentSerialNumber IS NOT NULL THEN WOP.CurrentSerialNumber ELSE UPPER(sl.SerialNumber) END as SerialNum,
			CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN UPPER(imtr.ItemGroup) ELSE  UPPER(imt.ItemGroup) END as 'itemGroup',            
			UPPER(wop.ACTailNum) as ACTailNum,              
			wop.TSN as TSN,              
			wop.CSN as CSN,    
			FORMAT(wop.ReceivedDate, 'MM/dd/yyyy') AS Recd_Date,
			wop.ReceivedDate,
			woq.CreatedDate as Qte_Date,              
			woq.ApprovedDate as Qte_Appvd_Date,              
			wop.CustomerRequestDate as Req_d_Date,              
			wop.EstimatedShipDate as Est_Ship_Date,              
			UPPER(el.EmployeeCode)  as TechNum,              
			UPPER(ws.Stage) as WOStage,              
			UPPER(wo.WorkOrderNum) as WorkOrderNum,              
			billsitename = CASE WHEN shippingInfo.WorkOrderId > 0  THEN  UPPER(shippingInfo.SoldToSiteName) else UPPER(billToSite.SiteName) END,              
			billAddressLine1 = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToAddress1) else UPPER(billToAddress.Line1) END,              
			billAddressLine2 = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToAddress2) else UPPER(billToAddress.Line2) END,
		
			billAddCombo = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToAddress1) + ', ' else UPPER(billToAddress.Line1)  + ', ' END +
							CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToAddress2) else UPPER(billToAddress.Line2) END,	

			billCity = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToCity) else UPPER(billToAddress.City) END,              
			billState = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToState) else UPPER(billToAddress.StateOrProvince) END,              
			billPostalCode = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToZip) else UPPER(billToAddress.PostalCode) END,
		
			billComboFileds = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToCity) + ', ' else UPPER(billToAddress.City) + ', ' END
						  + CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToState) else UPPER(billToAddress.StateOrProvince) END
						  + ' ' + CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToZip) else UPPER(billToAddress.PostalCode) END,
					  
			billCountry = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToCountryName) else UPPER(billToCountry.countries_name) END,              
			billAttention = CASE WHEN shippingInfo.WorkOrderId > 0  THEN 'ATTN: ' + UPPER(billToSiteatt.Attention) else 'ATTN: ' + UPPER(billToSite.Attention) END,   

			--MergedBillToAddress = (SELECT [dbo].[ValidatePDFAddress](CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToAddress1) else UPPER(billToAddress.Line1) END,
			--														CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToAddress2) else UPPER(billToAddress.Line2) END,NULL,
			--														CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToCity) else UPPER(billToAddress.City) END,
			--														CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToState) else UPPER(billToAddress.StateOrProvince) END,
			--														CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToZip) else UPPER(billToAddress.PostalCode) END,
			--														CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.SoldToCountryName) else UPPER(billToCountry.countries_name) END,
			--														NULL,NULL,NULL)),

			shipSiteName = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToSiteName) else UPPER(shipToSite.SiteName) END,              
			shipAttention = CASE WHEN shippingInfo.WorkOrderId > 0  THEN 'ATTN: ' + UPPER(shipToSiteatt.Attention) else 'ATTN: ' + UPPER(shipToSite.Attention) END,              
			shipAddressLine1 = CASE WHEN shippingInfo.WorkOrderId > 0  THEN  UPPER(shippingInfo.ShipToAddress1) else UPPER(shipToAddress.Line1) END,              
			shipAddressLine2 = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToAddress2) else UPPER(shipToAddress.Line2) END, 

			shipAddCombo = CASE WHEN shippingInfo.WorkOrderId > 0  THEN (UPPER(shippingInfo.ShipToAddress1)) ELSE (UPPER(shipToAddress.Line1)) END +             
						   CASE WHEN shippingInfo.WorkOrderId > 0 THEN (CASE WHEN ISNULL(shippingInfo.ShipToAddress2, '') <> '' THEN ', ' + UPPER(ISNULL(shippingInfo.ShipToAddress2, '')) ELSE '' END) ELSE 
						   (CASE WHEN ISNULL(shipToAddress.Line2, '') <> '' THEN ', ' + UPPER(ISNULL(shipToAddress.Line2, '')) ELSE '' END) END,
		
			shipCity = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToCity) else UPPER(ISNULL(shipToAddress.City,'')) END,              
			shipState = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToState) else UPPER(ISNULL(shipToAddress.StateOrProvince,'')) END,              
			shipPostalCode = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToZip) else UPPER(shipToAddress.PostalCode) END,              

			shipComboFileds = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToCity) + ', ' else UPPER(shipToAddress.City) END
						  + CASE WHEN shippingInfo.WorkOrderId > 0  THEN 
							CASE WHEN ISNULL(shippingInfo.SoldToState, '') = '' THEN '' ELSE ', ' + UPPER(TRIM(shippingInfo.SoldToState)) END 
						  else 
							CASE WHEN ISNULL(shipToAddress.StateOrProvince, '') = '' THEN '' ELSE ', ' + UPPER(TRIM(shipToAddress.StateOrProvince)) END 
						  END
						  + CASE WHEN shippingInfo.WorkOrderId > 0  THEN 
							CASE WHEN ISNULL(shippingInfo.SoldToZip, '') = '' THEN '' ELSE ', ' + UPPER(shippingInfo.SoldToZip) END
						  ELSE 
							CASE WHEN ISNULL(shipToAddress.PostalCode, '') = '' THEN '' ELSE ', ' + UPPER(shipToAddress.PostalCode) END
						END,
			--MergedShipToAddress = (SELECT [dbo].[ValidatePDFAddress](CASE WHEN shippingInfo.WorkOrderId > 0  THEN  UPPER(shippingInfo.ShipToAddress1) else UPPER(shipToAddress.Line1) END,
			--														CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToAddress2) else UPPER(shipToAddress.Line2) END,NULL,
			--														CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToCity) else UPPER(ISNULL(shipToAddress.City,'')) END,
			--														CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToState) else UPPER(ISNULL(shipToAddress.StateOrProvince,'')) END,
			--														CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToZip) else UPPER(shipToAddress.PostalCode) END,
			--														CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToCountryName) else UPPER(shipToCountry.countries_name) END,
			--														NULL,NULL,NULL)),

			shipCountry = CASE WHEN shippingInfo.WorkOrderId > 0  THEN UPPER(shippingInfo.ShipToCountryName) else UPPER(shipToCountry.countries_name) END,  
			shipToAddress.Line1 as shipToAddressLine1,shipToAddress.Line2 as shipToAddressLine2,shipToAddress.City as shipToAddressCity, shipToAddress.StateOrProvince as shipToAddressStateOrProvince,
			shipToAddress.PostalCode as shipToAddressPostalCode,shipToCountry.countries_name as shipToCountrycountries_name,
			--MergedShipAddress = (SELECT [dbo].[ValidatePDFAddress](shipToAddress.Line1,shipToAddress.Line2,NULL,shipToAddress.City,shipToAddress.StateOrProvince,shipToAddress.PostalCode,shipToCountry.countries_name,NULL,NULL,NULL)),
			wop.ManagementStructureId,              
			wf.WorkFlowWorkOrderId as WorkFlowWorkOrderId,              
			UPPER(rc.Reference) as Reference,              
			wo.UpdatedDate,            
			  CASE WHEN ISNULL(wosc.conditionName,'') = '' THEN UPPER(con.Description) ELSE UPPER(wosc.conditionName) END as ReceivedCond,            
			  UPPER(wop.WorkScope) as WorkScope,            
			  --UPPER(Pub.PublicationId) as PublicationName, 
			  UPPER(wop.PublicationNo) as PublicationName, 			  
			  CASE WHEN ISNULL(sl.OEM, 0) = 0 THEN 'YES' ELSE 'NO' END as 'OEM',            
			  @TravelerName as TravelerName        
			  ,Isnull(wost.IsManualForm,0) as IsManualForm    
			  ,NHAPNs = STUFF((SELECT DISTINCT ', ' + imtt.partnumber              
			FROM Dbo.ItemMaster imtt WITH(NOLOCK) INNER JOIN Dbo.Nha_Tla_Alt_Equ_ItemMapping nhatae WITH(NOLOCK)              
			   on nhatae.MappingItemMasterId = imtt.ItemMasterId              
			   WHERE nhatae.ItemMasterId = imt.ItemMasterId              
			   AND nhatae.IsActive = 1 AND nhatae.IsDeleted = 0              
			   FOR XML PATH('')              
			   ), 1, 1, '')     
			   ,ISNULL(wop.RevisedSerialNumber, '') as RevisedSerialNumber
			   ,Isnull(wost.IsDisplayFooter,0) as IsDisplayFooter ,
			   ISNULL(rc.CustReqCertType,'') AS CustReqCertType
			FROM Dbo.WorkOrder wo WITH(NOLOCK)              
			INNER JOIN Dbo.WorkOrderWorkFlow wf WITH(NOLOCK) on wf.WorkOrderId = wo.WorkOrderId and wf.WorkOrderPartNoId=@workOrderPartNoId    
			INNER JOIN Dbo.WorkOrderPartNumber wop WITH(NOLOCK) on wop.ID = wf.WorkOrderPartNoId
			LEFT JOIN Dbo.WorkOrderQuote woq WITH(NOLOCK) on wo.WorkOrderId = woq.WorkOrderId and woq.IsVersionIncrease=0 AND woq.IsActive = 1 AND woq.IsDeleted = 0       
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
			LEFT JOIN Dbo.ItemMaster imtr WITH(NOLOCK) on imtr.ItemMasterId = wop.RevisedItemmasterid            
			LEFT JOIN Dbo.Priority p WITH(NOLOCK) on p.PriorityId = wop.WorkOrderPriorityId              
			LEFT JOIN Dbo.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId              
			LEFT JOIN Dbo.Employee el WITH(NOLOCK) on el.EmployeeId = wop.TechnicianId              
			LEFT JOIN Dbo.WorkOrderStage ws WITH(NOLOCK) on ws.WorkOrderStageId = wop.WorkOrderStageId              
			LEFT JOIN Dbo.ReceivingCustomerWork rc WITH(NOLOCK) on rc.ReceivingCustomerWorkId = wop.ReceivingCustomerWorkId            
			LEFT JOIN Dbo.Condition Rcon WITH(NOLOCK) on Rcon.ConditionId = wop.RevisedConditionId            
			LEFT JOIN Dbo.Condition con WITH(NOLOCK) on con.ConditionId = wop.ConditionId            
			--LEFT JOIN Dbo.Publication Pub WITH(NOLOCK) on Pub.PublicationRecordId = wop.CMMId        
			LEFT JOIN dbo.WorkOrderSettlementDetails wosc WITH(NOLOCK) on wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9        
			LEFT JOIN Dbo.ItemMaster rimt WITH(NOLOCK) on rimt.ItemMasterId = wosc.RevisedPartId    
			LEFT JOIN Dbo.WorkOrderSettings wost WITH(NOLOCK) on wost.MasterCompanyId = wop.MasterCompanyId AND wo.WorkOrderTypeId = wost.WorkOrderTypeId    
			WHERE wo.WorkOrderId = @WorkorderId AND wop.ID = @workOrderPartNoId) Result  
			

			SELECT 	@Address1 = shipToAddressLine1, @Address2 = shipToAddressLine2, @City = shipToAddressCity, @StateOrProvince = shipToAddressStateOrProvince, @PostalCode = shipToAddressPostalCode,
					@Country = shipToCountrycountries_name,
					@BAddress1 = billAddressLine1, @BAddress2 = billAddressLine2, @BCity = billCity, @BStateOrProvince = billState, @BPostalCode = billPostalCode,
					@BCountry = billCountry,
					@SAddress1 = shipAddressLine1, @SAddress2 = shipAddressLine2, @SCity = shipCity, @SStateOrProvince = shipState, @SPostalCode = shipPostalCode,
					@SCountry = shipCountry FROM #TempTableData

			EXEC [dbo].[SP_ValidatePDFAddress] 
                @Address1 = @Address1,
                @Address2 = @Address2,
                @Address3 = NULL,
                @City = @City,
                @StateOrProvince = @StateOrProvince,
                @PostalCode = @PostalCode,
                @Country = @Country,
                @PhoneNumber = @PhoneNumber,
                @PhoneExt = @PhoneExt,
                @Email = @Email,
                @AddressOutput = @MergedShipAddress OUTPUT;
			EXEC [dbo].[SP_ValidatePDFAddress] 
                @Address1 = @BAddress1,
                @Address2 = @BAddress2,
                @Address3 = NULL,
                @City = @BCity,
                @StateOrProvince = @BStateOrProvince,
                @PostalCode = @BPostalCode,
                @Country = @BCountry,
                @PhoneNumber = @BPhoneNumber,
                @PhoneExt = @BPhoneExt,
                @Email = @BEmail,
                @AddressOutput = @MergedBillToAddress OUTPUT;
			EXEC [dbo].[SP_ValidatePDFAddress] 
                @Address1 = @SAddress1,
                @Address2 = @SAddress2,
                @Address3 = NULL,
                @City = @SCity,
                @StateOrProvince = @SStateOrProvince,
                @PostalCode = @SPostalCode,
                @Country = @SCountry,
                @PhoneNumber = @SPhoneNumber,
                @PhoneExt = @SPhoneExt,
                @Email = @SEmail,
                @AddressOutput = @MergedShipToAddress OUTPUT;
				Select @MergedShipAddress as MergedShipAddress,@MergedBillToAddress as MergedBillToAddress,@MergedShipToAddress as MergedShipToAddress,* FROM #TempTableData
   --END              
  --COMMIT  TRANSACTION              
             
  END TRY                  
  BEGIN CATCH                    
   IF @@trancount > 0              
    PRINT 'ROLLBACK'              
    --ROLLBACK TRAN;              
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()              
             
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------              
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetWorkOrderPrintPdfData'              
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
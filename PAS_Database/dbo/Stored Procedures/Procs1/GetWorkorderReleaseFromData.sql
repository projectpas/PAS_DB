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
** 2    09/29/2023  HEMANT SALIYA    Updated For Notes in Remarks
** 3    01/01/2024  Devendra Shekh   updated for SerialNumber(Batchnumber)
** 4    02/08/2024  Shrey Chandegara Updated for status (add case condition in status)
** 5    07/29/2024  HEMANT SALIYA    Updated For Get Part Number, Serial NUmber and Condition from Work Order Part table

 EXEC [dbo].[GetWorkorderReleaseFromData] 3553,3023,1
**************************************************************/ 

CREATE   PROC [dbo].[GetWorkorderReleaseFromData]  
@WorkorderId bigint,  
@workOrderPartNumberId bigint,  
@IsEasaLicense bit = 0  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
		DECLARE @WorkOrderSettlementId INT;  
		DECLARE @CommonTeardownTypeId INT;
		DECLARE @MSModuleId INT;  
		DECLARE @MasterCompanyId INT;  
		DECLARE @MTIMasterCompanyId INT; 

		SET @MSModuleId = 12 ; -- For WO PART NUMBER  
		SET @MTIMasterCompanyId = 11; -- For MTI
		SELECT @WorkOrderSettlementId = WS.WorkOrderSettlementId FROM DBO.WorkOrderSettlement WS WITH (NOLOCK)   
		WHERE  WS.WorkOrderSettlementName like '%Cond%' 
	  	  
		SELECT @MasterCompanyId = [MasterCompanyId] FROM [DBO].[WorkOrder] CTT WITH(NOLOCK) WHERE [WorkorderId] = @WorkorderId;
		SELECT @CommonTeardownTypeId = [CommonTeardownTypeId] FROM [DBO].[CommonTeardownType] CTT WITH(NOLOCK) 
		WHERE CTT.[MasterCompanyId] = @MasterCompanyId AND UPPER(CTT.[TearDownCode]) = UPPER('MODIFICATIONSERVICE');
	   
	    SELECT 'UNITED STATES' AS Country,  
			  '' AS trackingNo,  
			  le.CompanyName AS OrganizationName,  
			  ad.Line1 +' '+ ad.City +' '+ ad.StateOrProvince AS OrganizationAddress ,  
			  wo.WorkOrderNum AS InvoiceNo,  
			  '1' AS ItemName,  
			  --Commented By Hemant to Get Updated Details From Work Order Part Number
			  --CASE WHEN ISNULL(wosc.RevisedPartId,0) >0 THEN  UPPER(ims.PartDescription) ELSE UPPER(im.PartDescription) END AS Description,  
			  --CASE WHEN ISNULL(wosc.RevisedPartId,0) >0 THEN  UPPER(ims.partnumber) ELSE UPPER(im.partnumber) END AS PartNumber,  
			  wop.RevisedPartDescription AS [Description],
			  wop.RevisedPartNumber AS PartNumber,  
			  wop.CustomerReference AS Reference,  
			  wop.Quantity AS Quantity,  
			  CASE WHEN ISNULL(wop.RevisedSerialNumber , '') = '' THEN UPPER(CASE WHEN ISNULL(sl.SerialNumber,'') = '' THEN 'NA' ELSE sl.SerialNumber END)
						ELSE UPPER(wop.RevisedSerialNumber) END AS Batchnumber,  
			  CASE WHEN ISNULL(wop.RevisedConditionId,0) > 0 THEN C.Memo ELSE wosc.conditionName END AS [status],
			  '' as Certifies,   
			  0 AS approved ,  
			  0 AS Nonapproved,  
			  '' AS AuthorisedSign,   
			  UPPER(le.FAALicense) AS AuthorizationNo,  
			  '' as PrintedName,GETDATE() AS [Date],  
			  '' as AuthorisedSign2,  
			  UPPER(le.FAALicense) AS ApprovalCertificate,  
			  '' AS PrintedName2,GETDATE() Date2,  
			  0 AS CFR,  
			  0 Otherregulation,  
			  1 AS is8130from ,  
			  wop.ReceivedDate,  
			  wop.ManagementStructureId AS ManagementStructureId,  
			  ('<div style = "position:relative; height:180px; font-family: Arial, Helvetica, sans-serif!important; letter-spacing: 1px!important; font-size:13px">' 
				+ (CASE WHEN wop.CMMId is not null and wop.CMMId > 0 THEN   
						CASE WHEN wo.MasterCompanyId != @MTIMasterCompanyId THEN '<p>' + ('Publication ID: ' + ISNULL(UPPER(pub.PublicationId),0)) +'</p>'   
								+'<p>'+(CASE WHEN pub.PublishedById = 2 THEN 'Published By: ' + ISNULL(UPPER(ven.VendorName),'-')  
											 WHEN pub.PublishedById = 3 THEN 'Published By: ' +  ISNULL(UPPER(mf.Name),'-')  
											 WHEN pub.PublishedById = 4 THEN 'Published By: ' +  isnull(UPPER(pub.PublishedByOthers),'-')  
										ELSE '' END) + '</p>'   
								+ '<p>' +'Revision No: ' + ISNULL(CONVERT(VARCHAR(20),pub.RevisionNum),'-') + '</p>'  
								+ '<p>' +'Revision Date: ' + ISNULL(CONVERT(VARCHAR(100),pub.revisionDate,103),'-') + '</p> <p style="height:15px"></p>'  	 
						ELSE  '<p>' + ('Unit ' + ISNULL(UPPER(wosc.conditionName),'-')) + ' I/A/W CMM ATA: ' + ISNULL(UPPER(pub.PublicationId),0) + ' REV: ' + ISNULL(CONVERT(VARCHAR(20),UPPER(pub.RevisionNum)),'-')  + ' DATED: ' + UPPER(ISNULL(REPLACE(CONVERT(VARCHAR(100),pub.revisionDate,106),' ','/'),'-')) +'</p>'   
								+'<p>No FAA or EASA S/B and AD`s complied with at this shop visit.</p>'   
								+ '<p>' +'Full details of work carried out held on Work Order: ' + ISNULL(CONVERT(VARCHAR(20),UPPER(wo.WorkOrderNum)),'-') + '</p>  <br/>'  
						END ELSE '' END)   	  
			  + (CASE WHEN cwt.Memo IS NOT NULL THEN (CASE WHEN ISNULL(cwt.Memo,'') = '' THEN '' ELSE ISNULL(cwt.Memo,'') END) + '<p>&nbsp;</p>' ELSE '' END) 			 
			  + (CASE WHEN @IsEasaLicense = 1 THEN '<p style='+ '"bottom : 5px; position:absolute;font-size: 15px !important;"'+'>' +(ISNULL(wos.Dualreleaselanguage,'-') +'</p>') ELSE ''  END)        
			  + '</div>') Remarks,  
			   Upper(le.EASALicense) AS EASALicense  
		FROM [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK)   
			  LEFT JOIN [dbo].[WorkOrder] wo  WITH(NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId  
			  LEFT JOIN [dbo].[WorkOrderSettings] wos  WITH(NOLOCK) ON wos.MasterCompanyId = wop.MasterCompanyId AND wo.WorkOrderTypeId = wos.WorkOrderTypeId
			  LEFT JOIN [dbo].[ItemMaster] im  WITH(NOLOCK) ON im.ItemMasterId = wop.ItemMasterId  
			  LEFT JOIN [dbo].[Stockline] sl  WITH(NOLOCK) ON sl.StockLineId = wop.StockLineId  
			  LEFT JOIN [dbo].[ReceivingCustomerWork] rc  WITH(NOLOCK) ON rc.StockLineId = wop.StockLineId  
			  LEFT JOIN [dbo].[WorkOrderManagementStructureDetails] MSD  WITH(NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = wop.Id  
			  LEFT JOIN [dbo].[ManagementStructurelevel] MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id  
			  LEFT JOIN [dbo].[LegalEntity] le  WITH(NOLOCK) ON le.LegalEntityId   = MSL.LegalEntityId  
			  LEFT JOIN [dbo].[Address] ad  WITH(NOLOCK) ON ad.AddressId = le.AddressId   
			  LEFT JOIN [dbo].[WorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9  
			  LEFT JOIN [dbo].[ItemMaster] ims WITH(NOLOCK) ON ims.ItemMasterId = wosc.RevisedPartId  
			  LEFT JOIN [dbo].[Publication] pub WITH(NOLOCK) ON wop.CMMId = pub.PublicationRecordId  
			  LEFT JOIN [dbo].[Vendor] ven WITH(NOLOCK) ON pub.PublishedByRefId = ven.VendorId  
			  LEFT JOIN [dbo].[Manufacturer] mf WITH(NOLOCK) ON pub.PublishedByRefId = mf.ManufacturerId 
			  LEFT JOIN [dbo].[CommonWorkOrderTearDown] cwt WITH(NOLOCK) ON wo.WorkOrderId = cwt.WorkOrderId AND [CommonTeardownTypeId] = @CommonTeardownTypeId
			  LEFT JOIN [dbo].[Condition] C WITH(NOLOCK) ON C.ConditionId = wop.RevisedConditionId
		 WHERE wop.WorkOrderId = @WorkOrderId AND wop.ID=@workOrderPartNumberId  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'GetWorkorderReleaseFromData'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkorderId, '') + '''  
                @Parameter2 = ' + ISNULL(@workOrderPartNumberId ,'') +''  
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
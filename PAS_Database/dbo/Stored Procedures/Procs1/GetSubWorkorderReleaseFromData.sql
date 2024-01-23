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
   2    09/28/2023  BHARGAV SALIYA   In Sub WO 8130 form remove header Notes text from block 12. 
    
EXEC USP_AutoReserveIssueWorkOrderMaterials 4933,'ADMIN ADMIN'    
    
**************************************************************/     
CREATE   PROC [dbo].[GetSubWorkorderReleaseFromData]    
@SubWorkOrderId bigint = null,    
@SubWOPartNoId bigint = null,    
@IsEasaLicense bit = 0    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
    
  BEGIN TRY    
		DECLARE @WorkOrderSettlementId INT;    
		DECLARE @ManagementStructureId INT;    
		DECLARE @WopartId INT;    
		DECLARE @MSModuleId INT;    
		DECLARE @CommonTeardownTypeId INT;    
		DECLARE @MasterCompanyId INT;      
		DECLARE @MTIMasterCompanyId INT;     
    
		SET @MSModuleId = 12 ; -- For WO PART NUMBER    
		SET @MTIMasterCompanyId = 11; -- For MTI    
		SELECT @WorkOrderSettlementId = WS.WorkOrderSettlementId FROM DBO.WorkOrderSettlement WS WITH (NOLOCK)     
		WHERE WS.WorkOrderSettlementName like '%Cond%'    
    
		SELECT @WopartId = WS.ID,@ManagementStructureId=ws.ManagementStructureId, @MasterCompanyId = sWS.MasterCompanyId FROM DBO.SubWorkOrderPartNumber sWS WITH (NOLOCK) INNER JOIN WorkOrderPartNumber ws ON sws.WorkOrderId=ws.WorkOrderId     
		WHERE sWS.SubWorkOrderId = @SubWorkOrderId    
    
		SELECT @CommonTeardownTypeId = [CommonTeardownTypeId] FROM [DBO].[CommonTeardownType] CTT WITH(NOLOCK)     
		WHERE CTT.[MasterCompanyId] = @MasterCompanyId AND UPPER(CTT.[TearDownCode]) = UPPER('MODIFICATIONSERVICE');    
                        
		SELECT     
			  'UNITED STATES' AS Country,    
			  '' as trackingNo,    
			  le.CompanyName AS OrganizationName,    
			  ad.Line1 +' '+ ad.City +' '+ ad.StateOrProvince AS OrganizationAddress ,    
			  swo.SubWorkOrderNo AS SWOInvoiceNo,    
			  wo.WorkOrderNum AS InvoiceNo,    
			  '1' as ItemName,    
			  CASE WHEN isnull(wosc.RevisedItemmasterid,0) >0 THEN  UPPER(ims.PartDescription) ELSE UPPER(im.PartDescription) END AS Description,      
			  CASE WHEN isnull(wosc.RevisedItemmasterid,0) >0 THEN  UPPER(ims.partnumber) ELSE UPPER(im.partnumber) END as PartNumber,      
			  wopn.CustomerReference as Reference,    
			  wop.Quantity as Quantity,    
			  CASE WHEN ISNULL(wop.RevisedSerialNumber, '') = '' THEN UPPER(case when isnull(sl.SerialNumber,'') = '' then 'NA' ELSE sl.SerialNumber END) ELSE UPPER(wop.RevisedSerialNumber) END AS Batchnumber,    
			  wosc.conditionName AS [status],    
			  '' AS Certifies,     
			  0 AS approved ,    
			  0 AS Nonapproved,    
			  '' AS AuthorisedSign,     
			  UPPER(le.FAALicense) AS AuthorizationNo,    
			  '' AS PrintedName,GETDATE() AS [Date],    
			  '' AS AuthorisedSign2,    
			  UPPER(le.FAALicense) AS ApprovalCertificate,    
			  '' AS PrintedName2,GETDATE() Date2,    
			  0 AS CFR,    
			  0 Otherregulation,    
			  1 AS is8130from ,    
			  wopn.ReceivedDate AS ReceivedDate,    
			  @ManagementStructureId AS ManagementStructureId,    
			  ('<div style = "position:relative; height:180px; font-family: Arial, Helvetica, sans-serif!important; letter-spacing: 1px!important; font-size:13px">'
			     + (CASE WHEN wop.CMMId is not null and wop.CMMId >0 THEN       
						 CASE WHEN wo.MasterCompanyId != @MTIMasterCompanyId THEN '<p>' + ('Publication ID: ' + isnull(UPPER(pub.PublicationId),0)) +'</p>'       
								 +'<p>'+(CASE WHEN pub.PublishedById = 2 THEN 'Published By: ' + isnull(UPPER(ven.VendorName),'-')      
											  WHEN pub.PublishedById = 3 THEN 'Published By: ' +  isnull(UPPER(mf.Name),'-')      
											  WHEN pub.PublishedById = 4 THEN 'Published By: ' +  isnull(UPPER(pub.PublishedByOthers),'-')      
										 ELSE '' END) + '</p>'       
								 + '<p>' +'Revision No: ' + ISNULL(convert(varchar(20),pub.RevisionNum),'-') + '</p>'      
								 + '<p>' +'Revision Date: ' + ISNULL(convert(varchar(100),pub.revisionDate,103),'-') + '</p> <p style="height:15px"></p>'      
      
						 ELSE  '<p>' + ('Unit ' + isnull(UPPER(wosc.conditionName),'-')) + ' I/A/W CMM ATA: ' + isnull(UPPER(pub.PublicationId),0) + ' REV: ' + ISNULL(convert(varchar(20),UPPER(pub.RevisionNum)),'-')  + ' DATED: ' + UPPER(ISNULL(replace(convert(varchar(100),pub.revisionDate,106),' ','/'),'-')) +'</p>'       
				                     +'<p>No FAA or EASA S/B and AD`s complied with at this shop visit.</p>'       
				                     + '<p>' +'Full details of work carried out help on Work Order: ' + ISNULL(convert(varchar(20),UPPER(wo.WorkOrderNum)),'-') + '</p>  <br/>'      
						END ELSE '' END)          
	            + (CASE WHEN cwt.Memo IS NOT NULL THEN (CASE WHEN ISNULL(cwt.Memo,'') = '' THEN '' ELSE ISNULL(cwt.Memo,'') END) + '<p>&nbsp;</p>' ELSE '' END)     
			    +(CASE WHEN @IsEasaLicense = 1 THEN '<p style='+ '"bottom : 5px; position:absolute;font-size: 15px !important;"'+'>' +(ISNULL(wos.Dualreleaselanguage,'-') +'</p>') else ''  end)            
		        +'</div>') Remarks,       
		          UPPER(le.EASALicense)  as EASALicense    
         FROM [dbo].[SubWorkOrderPartNumber] wop WITH(NOLOCK)     
               LEFT JOIN [dbo].[SubWorkOrder] swo  WITH(NOLOCK) ON swo.SubWorkOrderId = wop.SubWorkOrderId    
               LEFT JOIN [dbo].[WorkOrder] wo  WITH(NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId    
               LEFT JOIN [dbo].[WorkOrderSettings] wos  WITH(NOLOCK) ON wos.MasterCompanyId = wop.MasterCompanyId AND wos.WorkOrderTypeId =  wo.WorkOrderTypeId    
               LEFT JOIN [dbo].[ItemMaster] im  WITH(NOLOCK) ON im.ItemMasterId = wop.ItemMasterId    
               LEFT JOIN [dbo].[Stockline] sl  WITH(NOLOCK) ON sl.StockLineId = wop.StockLineId    
               LEFT JOIN [dbo].[ReceivingCustomerWork] rc  WITH(NOLOCK) ON rc.WorkOrderId = wo.WorkOrderId --rc.StockLineId = wop.StockLineId    
               LEFT JOIN [dbo].[WorkOrderManagementStructureDetails] MSD  WITH(NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = @WopartId    
               LEFT JOIN [dbo].[ManagementStructurelevel] MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id    
               LEFT JOIN [dbo].[LegalEntity]  le  WITH(NOLOCK) ON le.LegalEntityId   = MSL.LegalEntityId     
               LEFT JOIN [dbo].[Address]  ad  WITH(NOLOCK) ON ad.AddressId = le.AddressId     
               LEFT JOIN [dbo].[SubWorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.SubWOPartNoId = wosc.SubWOPartNoId AND wosc.WorkOrderSettlementId = 9    
               LEFT JOIN [dbo].[ItemMaster] ims WITH(NOLOCK) ON ims.ItemMasterId = wosc.RevisedItemmasterid      
               LEFT JOIN [dbo].[Publication] pub WITH(NOLOCK) ON wop.CMMId = pub.PublicationRecordId    
               LEFT JOIN [dbo].[Vendor] ven WITH(NOLOCK) on pub.PublishedById = ven.VendorId    
               LEFT JOIN [dbo].[Manufacturer] mf WITH(NOLOCK) ON pub.PublishedById = mf.ManufacturerId    
               LEFT JOIN [dbo].[WorkOrderPartNumber] wopn  WITH(NOLOCK) ON wopn.ID = swo.WorkOrderPartNumberId    
               LEFT JOIN [dbo].[CommonWorkOrderTearDown] cwt WITH(NOLOCK) ON wo.WorkOrderId = cwt.WorkOrderId AND [CommonTeardownTypeId] = @CommonTeardownTypeId               
         WHERE wop.SubWorkOrderId = @SubWorkOrderId AND wop.SubWOPartNoId=@SubWOPartNoId    
  END TRY        
  BEGIN CATCH          
   IF @@trancount > 0    
    PRINT 'ROLLBACK'    
    ROLLBACK TRAN;    
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
              , @AdhocComments     VARCHAR(150)    = 'GetSubWorkorderReleaseFromData'     
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWorkOrderId, '') + '''    
                @Parameter2 = ' + ISNULL(@SubWOPartNoId ,'') +''    
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
/*************************************************************   
** Author:  <Devendra Shekh>  
** Create date: <12/26/2023>  
** Description: <Get Release Form Data by stocklineid>  
  
EXEC [USP_GetReleaseFromDataByStockLineId] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date			Author				Change Description  
** --   --------		-------				--------------------------------
** 1    12/26/2023		Devendra Shekh		created
** 2    10/02/2024		AMIT GHEDIYA		Updated For Get EASA UK Dualreleaselanguage message.

 EXEC [dbo].[USP_GetReleaseFromDataByStockLineId] 3553,1,0
**************************************************************/ 

CREATE   PROC [dbo].[USP_GetReleaseFromDataByStockLineId]  
@StockLineId BIGINT,  
@WorkOrderPartNumberId BIGINT,
@IsEasaLicense bit = 0 ,
@IsEasaUKLicense bit = 0 
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
		DECLARE @CommonTeardownTypeId INT;
		DECLARE @MSModuleId INT;  
		DECLARE @MasterCompanyId INT;  
		DECLARE @MTIMasterCompanyId INT; 
		DECLARE @UkCountryISOCode VARCHAR(100) = 'GB';
		DECLARE @UkCountryId BIGINT = 0;

		SET @MSModuleId = 2 ; -- For WO PART NUMBER  
		SET @MTIMasterCompanyId = 11; -- For MTI
	  	  
		SELECT @MasterCompanyId = [MasterCompanyId] FROM [DBO].[Stockline] CTT WITH(NOLOCK) WHERE [StockLineId] = @StockLineId;
		SELECT @CommonTeardownTypeId = [CommonTeardownTypeId] FROM [DBO].[CommonTeardownType] CTT WITH(NOLOCK) 
		WHERE CTT.[MasterCompanyId] = @MasterCompanyId AND UPPER(CTT.[TearDownCode]) = UPPER('MODIFICATIONSERVICE');
	   
	   --GET UK code id
		SELECT @UkCountryId = countries_id FROM [DBO].[Countries] WITH(NOLOCK) WHERE countries_iso_code = @UkCountryISOCode AND MasterCompanyId = @MasterCompanyId;
	    
		SELECT 'UNITED STATES' AS Country,  
			  '' AS trackingNo,  
			  le.CompanyName AS OrganizationName,  
			  ad.Line1 +' '+ ad.City +' '+ ad.StateOrProvince AS OrganizationAddress ,  
			  wo.WorkOrderNum AS InvoiceNo,  
			  '1' AS ItemName,  
			  UPPER(im.PartDescription) AS Description,  
			  UPPER(im.partnumber) AS PartNumber,  
			  wop.CustomerReference AS Reference,  
			  sl.Quantity AS Quantity,  
			  UPPER(CASE WHEN ISNULL(sl.SerialNumber,'') = '' THEN 'NA' ELSE sl.SerialNumber END) AS Batchnumber,  
			  ISNULL(sl.Condition, '') AS [status],  
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
			  0 AS Otherregulation,  
			  1 AS is8130from ,  
			  sl.ReceivedDate,  
			  sl.ManagementStructureId AS ManagementStructureId,  
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
								+'<p>No FAA or '+ CASE WHEN @IsEasaUKLicense = 1 THEN 'UK' ELSE 'EASA' END +' S/B and AD`s complied with at this shop visit.</p>'   
								+ '<p>' +'Full details of work carried out held on Work Order: ' + ISNULL(CONVERT(VARCHAR(20),UPPER(wo.WorkOrderNum)),'-') + '</p>  <br/>'  
						END ELSE '' END)   	  
			  + (CASE WHEN cwt.Memo IS NOT NULL THEN (CASE WHEN ISNULL(cwt.Memo,'') = '' THEN '' ELSE ISNULL(cwt.Memo,'') END) + '<p>&nbsp;</p>' ELSE '' END) 			 
			  + (CASE WHEN @IsEasaLicense = 1 THEN '<p style='+ '"bottom : 5px; position:absolute;font-size: 15px !important;"'+'>' +(ISNULL(wos.Dualreleaselanguage,'-') +' '+ le.EASALicense +'</p>') ELSE ''  END)        
			  + (CASE WHEN @IsEasaUKLicense = 1 THEN '<p style='+ '"bottom : 5px; position:absolute;font-size: 15px !important;"'+'>' +(REPLACE(REPLACE(ISNULL(wods.Dualreleaselanguage,'-'),'<p>',''),'</p>','') +' '+ le.UKCAALicense +'</p>') ELSE ''  END)        
			  + '</div>') Remarks,  
			   Upper(le.EASALicense) AS EASALicense,
			   0 AS [IsClosed],
			   wop.[islocked],
			   CASE WHEN @IsEasaLicense = 1 THEN 1 ELSE 0 END AS 'IsEASALicense',
			   '8130 Form' as FormType,
			   wo.EmployeeId,
			   0 AS 'ReleaseFromId',
			   ISNULL(SL.[WorkorderId], 0) AS [WorkorderId],
			   ISNULL(wop.ID, 0) AS [workOrderPartNoId],
			   SL.[MasterCompanyId],
			   '' AS 'PDFPath',
			   wop.IsFinishGood
		FROM [dbo].[Stockline] sl WITH(NOLOCK)   
			  LEFT JOIN [dbo].[WorkOrder] wo  WITH(NOLOCK) ON wo.WorkOrderId = sl.WorkOrderId 
			  LEFT JOIN [dbo].[WorkOrderPartNumber] wop  WITH(NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId AND wop.ID = @WorkOrderPartNumberId
			  LEFT JOIN [dbo].[WorkOrderSettings] wos  WITH(NOLOCK) ON wos.MasterCompanyId = wop.MasterCompanyId AND wo.WorkOrderTypeId = wos.WorkOrderTypeId
			  LEFT JOIN [dbo].[WorkOrderDualReleaseSettings] wods  WITH(NOLOCK) ON wods.MasterCompanyId = wop.MasterCompanyId AND wo.WorkOrderTypeId = wods.WorkOrderTypeId AND wods.CountriesId = @UkCountryId
			  LEFT JOIN [dbo].[WorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9 
			  LEFT JOIN [dbo].[ItemMaster] im  WITH(NOLOCK) ON im.ItemMasterId = sl.ItemMasterId  
			  LEFT JOIN [dbo].[StocklineManagementStructureDetails] MSD  WITH(NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = sl.StockLineId  
			  LEFT JOIN [dbo].[ManagementStructurelevel] MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id  
			  LEFT JOIN [dbo].[LegalEntity] le  WITH(NOLOCK) ON le.LegalEntityId   = MSL.LegalEntityId  
			  LEFT JOIN [dbo].[Address] ad  WITH(NOLOCK) ON ad.AddressId = le.AddressId   
			  LEFT JOIN [dbo].[Publication] pub WITH(NOLOCK) ON wop.CMMId = pub.PublicationRecordId  
			  LEFT JOIN [dbo].[Vendor] ven WITH(NOLOCK) ON sl.VendorId = ven.VendorId  
			  LEFT JOIN [dbo].[Manufacturer] mf WITH(NOLOCK) ON sl.ManufacturerId = mf.ManufacturerId 
			  LEFT JOIN [dbo].[CommonWorkOrderTearDown] cwt WITH(NOLOCK) ON wo.WorkOrderId = cwt.WorkOrderId AND [CommonTeardownTypeId] = @CommonTeardownTypeId
		 WHERE sl.StockLineId = @StockLineId
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_GetReleaseFromDataByStockLineId'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@StockLineId, '') +''  
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
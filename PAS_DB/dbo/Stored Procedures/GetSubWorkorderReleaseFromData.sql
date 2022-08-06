
CREATE PROC [dbo].[GetSubWorkorderReleaseFromData]
@SubWorkOrderId bigint = null,
@SubWOPartNoId bigint = null,
@IsEasaLicense bit = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				   DECLARE @WorkOrderSettlementId INT;
				   DECLARE @ManagementStructureId INT;
				   DECLARE @WopartId INT;
				   DECLARE @MSModuleId INT;
				   SET @MSModuleId = 12 ; -- For WO PART NUMBER

					SELECT @WorkOrderSettlementId = WS.WorkOrderSettlementId FROM DBO.WorkOrderSettlement WS WITH (NOLOCK) 
					WHERE WS.WorkOrderSettlementName like '%Cond%'

					SELECT @WopartId = WS.ID,@ManagementStructureId=ws.ManagementStructureId FROM DBO.SubWorkOrderPartNumber sWS WITH (NOLOCK) inner join WorkOrderPartNumber ws on sws.WorkOrderId=ws.WorkOrderId 
					WHERE sWS.SubWorkOrderId = @SubWorkOrderId
			       
				   SELECT 
						'UNITED STATES' as Country,
						'' as trackingNo,
						le.CompanyName as OrganizationName,
						ad.Line1 +' '+ ad.City +' '+ ad.StateOrProvince as OrganizationAddress ,
						swo.SubWorkOrderNo as SWOInvoiceNo,
						wo.WorkOrderNum as InvoiceNo,
						'1' as ItemName,
						UPPER(im.PartDescription) as Description,
						UPPER(im.partnumber) as PartNumber,
						--rc.Reference as Reference,
						wopn.CustomerReference as Reference,
						wop.Quantity as Quantity,
						UPPER(case when isnull(sl.SerialNumber,'') = '' then 'NA' else sl.SerialNumber end) as Batchnumber,
						--wop.WorkScope as [status],
						wosc.conditionName as [status],
						--wo.Notes as Remarks,
						'' as Certifies, 
						0 as approved ,
						0 as Nonapproved,
						'' as AuthorisedSign, 
						UPPER(le.FAALicense) as AuthorizationNo,
						'' as PrintedName,Getdate() as [Date],
						'' as AuthorisedSign2,
						UPPER(le.FAALicense) as ApprovalCertificate,
						'' as PrintedName2,Getdate() Date2,
						0 as CFR,
						0 Otherregulation,
						1 as is8130from ,
						wop.CustomerRequestDate as ReceivedDate,
						@ManagementStructureId as ManagementStructureId,
						((CASE WHEN wop.CMMId is not null and wop.CMMId >0 THEN 
						
						'<p>' + ('Publication Id: ' + isnull(pub.PublicationId,0)) +'</p>' 
					   +'<p>'+(CASE WHEN pub.PublishedById = 2 THEN 'Published By: ' + isnull(ven.VendorName,'-')
								WHEN pub.PublishedById = 3 THEN 'Published By: ' +  isnull(mf.Name,'-')
								WHEN pub.PublishedById = 4 THEN 'Published By: ' +  isnull(pub.PublishedByOthers,'-')
								ELSE '' END) + '</p>' 
						+ '<p>' +'Revision No: ' + ISNULL(convert(varchar(20),pub.RevisionNum),'-') + '</p>'
						+ '<p>' +'Revision Date: ' + ISNULL(convert(varchar(100),pub.revisionDate,103),'-') + '</p>'
							ELSE '' END) 
						    + (case when @IsEasaLicense = 1 then (isnull(le.CompanyName,'-') +' '+isnull(wos.Dualreleaselanguage,'-') +' '+Upper(isnull(le.EASALicense,'-')) +'</br>') else ''end)+
							+ (case when isnull(wo.Notes,'') = '' then '' else 'Notes: '+ isnull(wo.Notes,'') end)
						 ) Remarks,
						 Upper(le.EASALicense)  as EASALicense
					FROM dbo.SubWorkOrderPartNumber wop WITH(NOLOCK) 
					    LEFT JOIN DBO.SubWorkOrder swo  WITH(NOLOCK) on swo.SubWorkOrderId = wop.SubWorkOrderId
						LEFT JOIN DBO.WorkOrder wo  WITH(NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
						LEFT JOIN DBO.WorkOrderSettings wos  WITH(NOLOCK) on wos.MasterCompanyId = wop.MasterCompanyId
						LEFT JOIN DBO.ItemMaster im  WITH(NOLOCK) on im.ItemMasterId = wop.ItemMasterId
						LEFT JOIN DBO.Stockline sl  WITH(NOLOCK) on sl.StockLineId = wop.StockLineId
						LEFT JOIN dbo.ReceivingCustomerWork rc  WITH(NOLOCK) on rc.WorkOrderId = wo.WorkOrderId --rc.StockLineId = wop.StockLineId
						LEFT JOIN DBO.WorkOrderManagementStructureDetails MSD  WITH(NOLOCK) on MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = @WopartId
					    LEFT JOIN DBO.ManagementStructurelevel MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id
						LEFT JOIN DBO.LegalEntity  le  WITH(NOLOCK) on le.LegalEntityId   = MSL.LegalEntityId 
						LEFT JOIN DBO.Address  ad  WITH(NOLOCK) on ad.AddressId = le.AddressId 
						LEFT JOIN dbo.SubWorkOrderSettlementDetails wosc WITH(NOLOCK) on wop.WorkOrderId = wosc.WorkOrderId AND wop.SubWOPartNoId = wosc.SubWOPartNoId AND wosc.WorkOrderSettlementId = 9
						--LEFT JOIN DBO.Condition c WITH(NOLOCK) on c.ConditionId = wop.RevisedConditionId --c.ConditionId = ws.ConditionId
						LEFT JOIN DBO.Publication pub WITH(NOLOCK) on wop.CMMId = pub.PublicationRecordId
						LEFT JOIN DBO.Vendor ven WITH(NOLOCK) on pub.PublishedById = ven.VendorId
						LEFT JOIN DBO.Manufacturer mf WITH(NOLOCK) on pub.PublishedById = mf.ManufacturerId
						LEFT JOIN DBO.WorkOrderPartNumber wopn  WITH(NOLOCK) on wopn.ID = swo.WorkOrderPartNumberId
					WHERE wop.SubWorkOrderId = @SubWorkOrderId and wop.SubWOPartNoId=@SubWOPartNoId
			END
		COMMIT  TRANSACTION
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
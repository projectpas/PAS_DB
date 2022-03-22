CREATE PROC [dbo].[GetWorkorderReleaseFromData]
@WorkorderId bigint,
@workOrderPartNumberId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				   DECLARE @WorkOrderSettlementId INT;

					SELECT @WorkOrderSettlementId = WS.WorkOrderSettlementId FROM DBO.WorkOrderSettlement WS WITH (NOLOCK) 
					WHERE  WS.WorkOrderSettlementName like '%Cond%'
			       
				   SELECT 
						'UNITED STATES' as Country,
						'' as trackingNo,
						le.CompanyName as OrganizationName,
						ad.Line1 +' '+ ad.City +' '+ ad.StateOrProvince as OrganizationAddress ,
						wo.WorkOrderNum as InvoiceNo,
						'1' as ItemName,
						im.PartDescription as Description,
						im.partnumber as PartNumber,
						--rc.Reference as Reference,
						wop.CustomerReference as Reference,
						wop.Quantity as Quantity,
						case when isnull(sl.SerialNumber,'') = '' then 'NA' else sl.SerialNumber end as Batchnumber,
						--wop.WorkScope as [status],
						c.Description as [status],
						--wo.Notes as Remarks,
						'' as Certifies, 
						0 as approved ,
						0 as Nonapproved,
						'' as AuthorisedSign, 
						le.FAALicense as AuthorizationNo,
						'' as PrintedName,Getdate() as [Date],
						'' as AuthorisedSign2,
						le.FAALicense as ApprovalCertificate,
						'' as PrintedName2,Getdate() Date2,
						0 as CFR,
						0 Otherregulation,
						1 as is8130from ,
						wop.ReceivedDate,
						wop.ManagementStructureId as ManagementStructureId,

						((CASE WHEN wop.CMMId is not null and wop.CMMId >0 THEN 
						
						'<p>' + ('Publication ID: ' + isnull(pub.PublicationId,0)) +'</p>' 
					   +'<p>'+(CASE WHEN pub.PublishedById = 2 THEN 'Published By: ' + isnull(ven.VendorName,'-')
								WHEN pub.PublishedById = 3 THEN 'Published By: ' +  isnull(mf.Name,'-')
								WHEN pub.PublishedById = 4 THEN 'Published By: ' +  isnull(pub.PublishedByOthers,'-')
								ELSE '' END) + '</p>' 
						+ '<p>' +'Revision No: ' + ISNULL(convert(varchar(20),pub.RevisionNum),'-') + '</p>'
						+ '<p>' +'Revision Date: ' + ISNULL(convert(varchar(100),pub.revisionDate,103),'-') + '</p>'
						ELSE '' END) 	
						+  
						(case when isnull(wo.Notes,'') = '' then '' else 'Notes: '+ isnull(wo.Notes,'') end)
						 ) Remarks

					FROM dbo.WorkOrderPartNumber wop WITH(NOLOCK) 
						LEFT JOIN DBO.WorkOrder wo  WITH(NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
						LEFT JOIN DBO.ItemMaster im  WITH(NOLOCK) on im.ItemMasterId = wop.ItemMasterId
						LEFT JOIN DBO.Stockline sl  WITH(NOLOCK) on sl.StockLineId = wop.StockLineId
						left join dbo.ReceivingCustomerWork rc  WITH(NOLOCK) on rc.StockLineId = wop.StockLineId
						LEFT JOIN DBO.ManagementStructure ms  WITH(NOLOCK) on ms.ManagementStructureId  = wop.ManagementStructureId
						LEFT JOIN DBO.LegalEntity  le  WITH(NOLOCK) on le.LegalEntityId   = ms.LegalEntityId 
						LEFT JOIN DBO.Address  ad  WITH(NOLOCK) on ad.AddressId = le.AddressId 
						--LEFT JOIN DBO.WorkOrderSettlementDetails ws WITH(NOLOCK) ON ws.workOrderPartNoId = wop.ID AND ws.WorkOrderId = wop.WorkOrderId AND ws.WorkOrderSettlementId = @WorkOrderSettlementId
						LEFT JOIN DBO.Condition c WITH(NOLOCK) on c.ConditionId = wop.RevisedConditionId --c.ConditionId = wop.RevisedConditionId
						LEFT JOIN DBO.Publication pub WITH(NOLOCK) on wop.CMMId = pub.PublicationRecordId
						LEFT JOIN DBO.Vendor ven WITH(NOLOCK) on pub.PublishedByRefId = ven.VendorId
						LEFT JOIN DBO.Manufacturer mf WITH(NOLOCK) on pub.PublishedByRefId = mf.ManufacturerId
					WHERE wop.WorkOrderId = @WorkOrderId and wop.ID=@workOrderPartNumberId
			END
		COMMIT  TRANSACTION
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
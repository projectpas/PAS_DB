
CREATE PROC [dbo].[GetWorkorderReleaseEasaFromData]
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
				DECLARE @MSModuleId INT;
				SET @MSModuleId = 12 ; -- For WO PART NUMBER

				SELECT @WorkOrderSettlementId = WS.WorkOrderSettlementId FROM DBO.WorkOrderSettlement WS WITH (NOLOCK) JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.MasterCompanyId = WS.MasterCompanyId
				WHERE Wo.WorkOrderId = @WorkorderId AND WS.WorkOrderSettlementName like '%Cond%'

				SELECT 
						le.CompanyName as OrganizationName, 
						ad.Line1 +' '+ ad.City +' '+ ad.StateOrProvince as OrganizationAddress ,
						wo.WorkOrderNum as InvoiceNo,
					    '1' as ItemName,
					    im.PartDescription as Description,
					    im.partnumber as PartNumber,
					    rc.Reference as Reference,
					    wop.Quantity as Quantity,
					    sl.SerialNumber as Batchnumber,
						c.Description as [status],
						'' as Certifies, 
					    0 as approved ,
					    0 as Nonapproved,
					    '' as AuthorisedSign, 
					    le.FAALicense as AuthorizationNo,
					    '' as PrintedName,
						Getdate() as [Date],
					    '' as AuthorisedSign2,
					    le.FAALicense as ApprovalCertificate,					    
						Getdate() Date2,
					    0 as CFR,
						0 Otherregulation,
					    0 as is8130from,
						wop.ReceivedDate,
					    wop.ManagementStructureId as ManagementStructureId,						
						((CASE WHEN wop.CMMId is not null and wop.CMMId >0 THEN 
						
						'<p>' + ('Publication Id: ' + isnull(pub.PublicationId,0)) +'</p>' 
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
					   LEFT JOIN DBO.WorkOrderManagementStructureDetails MSD  WITH(NOLOCK) on MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = wop.Id
					   LEFT JOIN DBO.ManagementStructurelevel MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id
					   LEFT JOIN DBO.LegalEntity  le  WITH(NOLOCK) on le.LegalEntityId   = MSL.LegalEntityId 
					   LEFT JOIN DBO.Address  ad  WITH(NOLOCK) on ad.AddressId = le.AddressId 
					   LEFT JOIN DBO.Condition c WITH(NOLOCK) on c.ConditionId = wop.RevisedConditionId --c.ConditionId = ws.ConditionId
					   LEFT JOIN DBO.Publication pub WITH(NOLOCK) on wop.CMMId = pub.PublicationRecordId
					   LEFT JOIN DBO.Vendor ven WITH(NOLOCK) on pub.PublishedById = ven.VendorId
					   LEFT JOIN DBO.Manufacturer mf WITH(NOLOCK) on pub.PublishedById = mf.ManufacturerId
				WHERE wop.WorkOrderId = @WorkOrderId and wop.ID = @workOrderPartNumberId 
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkorderReleaseEasaFromData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkorderId, '') + '''
													   @Parameter4 = ' + ISNULL(@workOrderPartNumberId ,'') +''
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
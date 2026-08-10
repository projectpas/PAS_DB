
/*************************************************************
** Change History
**************************************************************
** PR   Date         Author			Change Description
	1    09/July/2026   RAJESH GAMI   [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	2    07/August/2026 Abhishek Jirawala [PN-17260] - Added Fleet field in Section 12 Remarks
	3    07/August/2026 Abhishek Jirawala [PN-17260] - Excluded Fleet field for MasterCompanyCode PAR
**************************************************************/
CREATE PROC [dbo].[GetSubWorkorderReleaseEasaFromData]
@SubWorkOrderId bigint = null,
@SubWOPartNoId bigint = null
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		--BEGIN TRANSACTION
		--	BEGIN  
				    DECLARE @WorkOrderSettlementId INT;
				    DECLARE @ManagementStructureId INT;
					DECLARE @WopartId INT;
				    DECLARE @MSModuleId INT;
					DECLARE @CMMIds VARCHAR(200) = NULL;			
					DECLARE @IsMultiple BIT = NULL;
					DECLARE @EmailBody NVARCHAR(MAX)=''
					DECLARE @MasterCompanyId INT;
					DECLARE @MasterCompanyCode VARCHAR(20);
				    SET @MSModuleId = 12 ; -- For WO PART NUMBER

					SELECT @WorkOrderSettlementId = WS.WorkOrderSettlementId FROM DBO.WorkOrderSettlement WS WITH (NOLOCK)
					WHERE WS.WorkOrderSettlementName like '%Cond%'

			        SELECT @WopartId = WS.ID,@ManagementStructureId=ws.ManagementStructureId,@MasterCompanyId = sWS.MasterCompanyId FROM DBO.SubWorkOrderPartNumber sWS WITH (NOLOCK) inner join WorkOrderPartNumber ws on sws.WorkOrderId=ws.WorkOrderId
					WHERE sWS.SubWorkOrderId = @SubWorkOrderId

					SELECT @MasterCompanyCode = [MasterCompanyCode] FROM [dbo].[MasterCompany] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;

					IF OBJECT_ID(N'tempdb..#tmprCMMIDsDetails') IS NOT NULL
					BEGIN
						DROP TABLE #tmprCMMIDsDetails
					END		
		
					CREATE TABLE #tmprCMMIDsDetails
					(
						[ID] BIGINT NOT NULL IDENTITY, 
						[CMMId] BIGINT NULL
					)

					SELECT @CMMIds = wop.[CMMIds]
					FROM [dbo].[SubWorkOrderPartNumber] wop WITH(NOLOCK) 
					WHERE wop.[SubWOPartNoId]=@SubWOPartNoId 

					IF(@CMMIds IS NOT NULL)
					BEGIN
						INSERT INTO #tmprCMMIDsDetails ([CMMId])
						SELECT [PublicationRecordId] --(SELECT Item FROM DBO.SPLITSTRING(wop.CMMIds, ',')) AS cmmids 
						FROM [dbo].[Publication] WHERE [PublicationRecordId] IN (SELECT Item FROM DBO.SPLITSTRING(@CMMIds, ','))  
					END	

					IF(@CMMIds IS NOT NULL)
					BEGIN			
						IF CHARINDEX(',', @CMMIds) > 0
						BEGIN
							SET @IsMultiple = 1
						END
						ELSE
						BEGIN
							SET @IsMultiple = 0
						END
					END

					IF(@CMMIds IS NOT NULL)
					BEGIN
						IF(@IsMultiple = 1)
						BEGIN
							SELECT @EmailBody = [EmailBody] FROM 
								[dbo].[PublicationTemplate] PT WITH(NOLOCK) 
								WHERE [MasterCompanyId] = @MasterCompanyId AND [PublicationTypeId] = 0
						END
						ELSE
						BEGIN
							SELECT @EmailBody = [EmailBody]
								FROM [dbo].[Publication] PC WITH(NOLOCK)
								LEFT JOIN [dbo].[PublicationTemplate] PT WITH(NOLOCK) ON PT.[PublicationTypeId] = PC.[PublicationTypeId] and PT.[IsActive] = 1 AND PT.[IsDeleted] = 0
								WHERE PC.[PublicationRecordId] = CAST(@CMMIds AS BIGINT) AND PC.[MasterCompanyId] = @MasterCompanyId 
						END		
					END

					IF(@IsMultiple IS NULL OR @IsMultiple = 0 )
					BEGIN

					SELECT 
						le.CompanyName as OrganizationName, 
						ad.Line1 +' '+ ad.City +' '+ ad.StateOrProvince as OrganizationAddress ,
						swo.SubWorkOrderNo as InvoiceNo,
					    '1' as ItemName,
					    CASE WHEN isnull(wosc.RevisedItemmasterid,0) >0 THEN  UPPER(ims.PartDescription) ELSE UPPER(im.PartDescription) END as Description,  
                        CASE WHEN isnull(wosc.RevisedItemmasterid,0) >0 THEN  UPPER(ims.partnumber) ELSE UPPER(im.partnumber) END as PartNumber,  
					    rc.Reference as Reference,
					    wop.Quantity as Quantity,
					    UPPER(case when isnull(sl.SerialNumber,'') = '' then 'NA' else sl.SerialNumber end) as Batchnumber,
						wosc.conditionName as [status],
						'' as Certifies, 
					    0 as approved ,
					    0 as Nonapproved,
					    '' as AuthorisedSign, 
					    UPPER(le.EASALicense) as AuthorizationNo,
					    '' as PrintedName,
						Getdate() as [Date],
					    '' as AuthorisedSign2,
					    UPPER(le.EASALicense) as ApprovalCertificate,					    
						Getdate() Date2,
					    0 as CFR,
						0 Otherregulation,
					    0 as is8130from,
					    wop.CustomerRequestDate as ReceivedDate,
						@ManagementStructureId as ManagementStructureId,
						((CASE WHEN @CMMIds IS NOT NULL THEN 						
						'<p>' + ('Publication Id: ' + isnull(pub.PublicationId,0)) +'</p>' 
					   +'<p>'+(CASE WHEN pub.PublishedById = 2 THEN 'Published By: ' + isnull(ven.VendorName,'-')
								WHEN pub.PublishedById = 3 THEN 'Published By: ' +  isnull(mf.Name,'-')
								WHEN pub.PublishedById = 4 THEN 'Published By: ' +  isnull(pub.PublishedByOthers,'-')
								ELSE '' END) + '</p>'
						+ (CASE WHEN @MasterCompanyCode = 'PAR' THEN '' ELSE '<p>' +'Fleet: ' + isnull(UPPER(pub.Fleet),'-') + '</p>' END)
						+ '<p>' +'Revision No: ' + ISNULL(convert(varchar(20),pub.RevisionNum),'-') + '</p>'
						+ '<p>' +'Revision Date: ' + ISNULL(convert(varchar(100),pub.revisionDate,103),'-') + '</p>'
						ELSE '' END) 	
							+  
						(case when isnull(wo.Notes,'') = '' then '' else 'Notes: '+ isnull(wo.Notes,'') end)
						 ) Remarks
					FROM dbo.SubWorkOrderPartNumber wop WITH(NOLOCK) 
					    LEFT JOIN DBO.SubWorkOrder swo  WITH(NOLOCK) on swo.SubWorkOrderId = wop.SubWorkOrderId
						LEFT JOIN DBO.WorkOrder wo  WITH(NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
					    LEFT JOIN DBO.ItemMaster im  WITH(NOLOCK) on im.ItemMasterId = wop.ItemMasterId
					     AND ISNULL(im.IsNonStock,0) = 0
					     LEFT JOIN DBO.Stockline sl  WITH(NOLOCK) on sl.StockLineId = wop.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
						LEFT JOIN dbo.ReceivingCustomerWork rc  WITH(NOLOCK) on rc.StockLineId = wop.StockLineId
					    LEFT JOIN DBO.WorkOrderManagementStructureDetails MSD  WITH(NOLOCK) on MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = @WopartId
					    LEFT JOIN DBO.ManagementStructurelevel MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id
					    LEFT JOIN DBO.LegalEntity  le  WITH(NOLOCK) on le.LegalEntityId   = MSL.LegalEntityId 
						LEFT JOIN DBO.Address  ad  WITH(NOLOCK) on ad.AddressId = le.AddressId 
						LEFT JOIN dbo.SubWorkOrderSettlementDetails wosc WITH(NOLOCK) on wop.WorkOrderId = wosc.WorkOrderId AND wop.SubWOPartNoId = wosc.SubWOPartNoId AND wosc.WorkOrderSettlementId = 9
						LEFT JOIN dbo.ItemMaster ims WITH(NOLOCK) on ims.ItemMasterId = wosc.RevisedItemmasterid  
						 AND ISNULL(ims.IsNonStock,0) = 0
						 LEFT JOIN DBO.Publication pub WITH(NOLOCK) on  pub.PublicationRecordId = @CMMIds
					    LEFT JOIN DBO.Vendor ven WITH(NOLOCK) on pub.PublishedById = ven.VendorId
					    LEFT JOIN DBO.Manufacturer mf WITH(NOLOCK) on pub.PublishedById = mf.ManufacturerId
					WHERE wop.SubWorkOrderId = @SubWorkOrderId and wop.SubWOPartNoId=@SubWOPartNoId

					END
		--	END
		--COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'				
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetSubWorkorderReleaseEasaFromData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWorkOrderId, '') + '''
													   @Parameter4 = ' + ISNULL(@SubWOPartNoId ,'') +''
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
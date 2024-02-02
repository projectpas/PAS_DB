/*************************************************************           
 ** File:   [sp_subworkOrderReleaseFromPDFData]           
 ** Author:   Subhash Saliya
 ** Description: Get Search Data for GetSubWOAsset List    
 ** Purpose:         
 ** Date:   23-march-2020        
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    03/23/2020   Subhash Saliya Created
	2    06/25/2020   Hemant  Saliya Added Transation & Content Management
	3    02/02/2024   Devendra Shekh	Updated for revised Part Panry and Condition

     
 EXECUTE [sp_subworkOrderReleaseFromPDFData] 10, 1, null, -1, '',null, '','','',null,null,null,null,null,null,0,1
**************************************************************/ 

CREATE   Procedure [dbo].[sp_subworkOrderReleaseFromPDFData]
@ReleaseFromId bigint

AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
			
				    DECLARE @ManagementStructureId INT;
					DECLARE @MSModuleId INT;
					DECLARE @WopartId INT;
				    SET @MSModuleId = 12 ; -- For WO PART NUMBER

					SELECT @WopartId = WS.ID,@ManagementStructureId = WS.ManagementStructureId FROM DBO.SubWorkOrderPartNumber sWS WITH (NOLOCK) inner join WorkOrderPartNumber ws on sws.WorkOrderId=ws.WorkOrderId 
					WHERE sWS.SubWorkOrderId = (select top 1 wop.SubWorkOrderId FROM [dbo].SubWorkOrder_ReleaseFrom_8130 wro WITH(NOLOCK)
				      LEFT JOIN dbo.SubWorkOrderPartNumber wop WITH(NOLOCK) on wro.SubWOPartNoId = wop.SubWOPartNoId where wro.SubReleaseFromId =  @ReleaseFromId )
				 SELECT 
					   wro.[SubReleaseFromId]
					  ,wo.[WorkorderId]
					  ,wro.[SubWorkOrderId]
					  ,wro.[SubWOPartNoId]
					  ,wro.[Country]
					  ,wro.[OrganizationName]
					  ,wro.[InvoiceNo] as SWOInvoiceNo
					  ,wo.WorkOrderNum [InvoiceNo]
					  ,wro.[ItemName]
					 --,UPPER(wro.[Description]) as Description
					  ,CASE WHEN ISNULL(wop.RevisedItemmasterid,0) > 0 THEN  UPPER(ims.partnumber) ELSE UPPER(im.partnumber) END AS PartNumber
					  ,CASE WHEN ISNULL(wop.RevisedItemmasterid,0) > 0 THEN  UPPER(ims.PartDescription) ELSE UPPER(im.PartDescription) END AS Description
					  --,UPPER(wro.[PartNumber]) as PartNumber
					  ,wro.[Reference]
					  ,wro.[Quantity]
					  --,UPPER(wro.[Batchnumber]) as Batchnumber
					   ,CASE WHEN ISNULL(wop.RevisedItemmasterid,0) > 0 THEN  UPPER(wop.RevisedSerialNumber) ELSE UPPER(wro.[Batchnumber]) END AS Batchnumber
					  ,wosc.conditionName as [status]
					  ,wro.[Remarks]
					  ,wro.[Certifies]
					  ,wro.[approved]
					  ,wro.[Nonapproved]
					  ,wro.[AuthorisedSign]
					  ,UPPER(case when wro.[is8130from] = 1 then le.FAALicense else le.EASALicense end) as [AuthorizationNo]
					  ,wro.[PrintedName]
					  ,wro.[Date]
					  ,wro.[AuthorisedSign2]
					  ,UPPER(case when wro.[is8130from] = 1 then le.FAALicense else le.EASALicense end) as [ApprovalCertificate]
					  ,wro.[PrintedName2]
					  ,wro.[Date2]
					  ,wro.[CFR]
					  ,wro.[Otherregulation]
					  ,wro.[MasterCompanyId]
					  ,wro.[CreatedBy]
					  ,wro.[UpdatedBy]
					  ,wro.[CreatedDate]
					  ,wro.[UpdatedDate]
					  ,wro.[IsActive]
					  ,wro.[IsDeleted]
					  ,wro.[trackingNo]
					  ,wro.[OrganizationAddress]
					  ,wro.[is8130from]
					  ,wro.[IsClosed]
					  ,wop.[islocked]
					  ,wop.[IsFinishGood]
					  ,wro.[PDFPath]
					  ,case when wro.[is8130from] = 1 then '8130 Form' else '9130 Form' end as FormType 
					  ,wop.CustomerRequestDate as ReceivedDate,
					@ManagementStructureId as ManagementStructureId
				FROM [dbo].SubWorkOrder_ReleaseFrom_8130 wro WITH(NOLOCK)
				      LEFT JOIN dbo.SubWorkOrderPartNumber wop WITH(NOLOCK) on wro.SubWOPartNoId = wop.SubWOPartNoId
					  LEFT JOIN [dbo].[ItemMaster] im  WITH(NOLOCK) ON im.ItemMasterId = wop.ItemMasterId  
					  LEFT JOIN [dbo].[ItemMaster] ims WITH(NOLOCK) ON ims.ItemMasterId = wop.RevisedItemmasterid  				      LEFT JOIN dbo.WorkOrder wo WITH(NOLOCK) on wo.WorkorderId = wop.WorkOrderId
					  LEFT JOIN DBO.WorkOrderManagementStructureDetails MSD  WITH(NOLOCK) on MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = @WopartId
					  LEFT JOIN DBO.ManagementStructurelevel MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id
					  LEFT JOIN dbo.SubWorkOrderSettlementDetails wosc WITH(NOLOCK) on wop.WorkOrderId = wosc.WorkOrderId AND wop.SubWOPartNoId = wosc.SubWOPartNoId AND wosc.WorkOrderSettlementId = 9
					  LEFT JOIN DBO.LegalEntity  le  WITH(NOLOCK) on le.LegalEntityId   = MSL.LegalEntityId 
				WHERE wro.SubReleaseFromId=@ReleaseFromId
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_subworkOrderReleaseFromPDFData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReleaseFromId, '') + ''
													  
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
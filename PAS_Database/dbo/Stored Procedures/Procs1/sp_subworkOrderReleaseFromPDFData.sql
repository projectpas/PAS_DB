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
	3    02/02/2024   Devendra Shekh Updated for revised Part Panry and Condition
	4    07/14/2024   Hemant  Saliya Updated for Condition Is not populating in 8130
	5    12/31/2024   Devendra Shekh Updated For Get FormType and Batchnumber Name
	6    02/24/2025   Moin Bloch     Updated For Get Is813013aeOr14ae
 	7   14/May/2026  Rajesh Gami	 Return EmployeeId [PN-16405 :  Generate Multiple Release Forms for Teardown Work Orders]       
	8    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
 EXECUTE [sp_subworkOrderReleaseFromPDFData] 10, 1, null, -1, '',null, '','','',null,null,null,null,null,null,0,1
**************************************************************/ 

CREATE   Procedure [dbo].[sp_subworkOrderReleaseFromPDFData]
@ReleaseFromId bigint

AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		--BEGIN TRANSACTION
		--	BEGIN
			
				    DECLARE @ManagementStructureId INT;
					DECLARE @MSModuleId INT;
					DECLARE @WopartId INT;
				    SET @MSModuleId = 12 ; -- For WO PART NUMBER

					SELECT @WopartId = WS.ID,@ManagementStructureId = WS.ManagementStructureId FROM [dbo].[SubWorkOrderPartNumber] sWS WITH (NOLOCK) INNER JOIN [dbo].[WorkOrderPartNumber] ws WITH (NOLOCK) ON sws.WorkOrderId=ws.WorkOrderId 
					WHERE sWS.SubWorkOrderId = (select top 1 wop.SubWorkOrderId FROM [dbo].SubWorkOrder_ReleaseFrom_8130 wro WITH(NOLOCK)
				      LEFT JOIN dbo.SubWorkOrderPartNumber wop WITH(NOLOCK) ON wro.SubWOPartNoId = wop.SubWOPartNoId WHERE wro.SubReleaseFromId =  @ReleaseFromId )
				 SELECT 
					   wro.[SubReleaseFromId]
					  ,wo.[WorkorderId]
					  ,wro.[SubWorkOrderId]
					  ,wro.[SubWOPartNoId]
					  ,wro.[Country]
					  ,wro.[OrganizationName]
					  ,wro.[InvoiceNo] AS SWOInvoiceNo
					  ,wo.WorkOrderNum [InvoiceNo]
					  ,wro.[ItemName]
					 --,UPPER(wro.[Description]) as Description
					  ,CASE WHEN ISNULL(wop.RevisedItemmasterid,0) > 0 THEN  UPPER(ims.partnumber) ELSE UPPER(im.partnumber) END AS PartNumber
					  ,CASE WHEN ISNULL(wop.RevisedItemmasterid,0) > 0 THEN  UPPER(ims.PartDescription) ELSE UPPER(im.PartDescription) END AS Description
					  --,UPPER(wro.[PartNumber]) as PartNumber
					  ,wro.[Reference]
					  ,wro.[Quantity]
					  --,UPPER(wro.[Batchnumber]) as Batchnumber
					  ,CASE WHEN ISNULL(UPPER(wro.[Batchnumber]), '') != '' THEN UPPER(wro.[Batchnumber]) ELSE CASE WHEN ISNULL(wop.RevisedItemmasterid,0) > 0 THEN  UPPER(wop.RevisedSerialNumber) ELSE UPPER(wro.[Batchnumber]) END END AS Batchnumber
					  --,CASE WHEN ISNULL(wop.RevisedItemmasterid,0) > 0 THEN  UPPER(wop.RevisedSerialNumber) ELSE UPPER(wro.[Batchnumber]) END AS Batchnumber
					  ,wosc.conditionName AS [status]
					  ,wro.[Remarks]
					  ,wro.[Certifies]
					  ,wro.[approved]
					  ,wro.[Nonapproved]
					  ,wro.[AuthorisedSign]
					  ,UPPER(CASE WHEN wro.[is8130from] = 1 THEN le.FAALicense ELSE le.EASALicense END) AS [AuthorizationNo]
					  ,wro.[PrintedName]
					  ,wro.[Date]
					  ,wro.[AuthorisedSign2]
					  ,UPPER(CASE WHEN wro.[is8130from] = 1 THEN le.FAALicense ELSE le.EASALicense END) AS [ApprovalCertificate]
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
					  ,CASE WHEN wro.[is8130from] = 1 THEN '8130 Certificate' ELSE '9130 Form' END AS FormType 
					  ,wop.CustomerRequestDate AS ReceivedDate
					  ,@ManagementStructureId AS ManagementStructureId
					  ,wro.Is813013aeOr14ae,
					  wro.EmployeeId
				FROM [dbo].[SubWorkOrder_ReleaseFrom_8130] wro WITH(NOLOCK)
				      LEFT JOIN [dbo].[SubWorkOrderPartNumber] wop WITH(NOLOCK) ON wro.SubWOPartNoId = wop.SubWOPartNoId
					  LEFT JOIN [dbo].[ItemMaster] im  WITH(NOLOCK) ON im.ItemMasterId = wop.ItemMasterId  
					   AND ISNULL(im.IsNonStock,0) = 0
					  LEFT JOIN [dbo].[ItemMaster] ims WITH(NOLOCK) ON ims.ItemMasterId = wop.RevisedItemmasterid  	
					   AND ISNULL(ims.IsNonStock,0) = 0
					  LEFT JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON wo.WorkorderId = wop.WorkOrderId
					  LEFT JOIN [dbo].[WorkOrderManagementStructureDetails] MSD  WITH(NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = @WopartId
					  LEFT JOIN [dbo].[ManagementStructurelevel] MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id
					  LEFT JOIN [dbo].[SubWorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.SubWOPartNoId = wosc.SubWOPartNoId AND wosc.WorkOrderSettlementId = 9
					  LEFT JOIN [dbo].[LegalEntity]  le  WITH(NOLOCK) ON le.LegalEntityId   = MSL.LegalEntityId 
				WHERE wro.SubReleaseFromId=@ReleaseFromId
			--END
		--COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				--ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_subworkOrderReleaseFromPDFData'              
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReleaseFromId, '') AS VARCHAR(100)) 													  
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
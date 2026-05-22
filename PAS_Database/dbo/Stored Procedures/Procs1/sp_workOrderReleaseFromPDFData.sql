/*************************************************************           
 ** File:   [sp_workOrderReleaseFromListData]           
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
	4    07/14/2024   Hemant  Saliya Updated for Condition Is not populating in 8130
	5    12/31/2024   Devendra Shekh Updated For Get FormType and Batchnumber Name
	6    02/13/2025   Moin Bloch     Updated For Get Is813013aeOr14ae Flag 
	7    10/10/2025   Moin Bloch     Updated For Get VersionNo & IsVersionIncrease Flag
	8    13/10/2025   Moin Bloch     Updated to Dynamic VersionNo
	9    12/11/2025   Moin Bloch     Updated trackingNo For PAR Company
	10   14/May/2026  Rajesh Gami	 Return EmployeeId [PN-16405 :  Generate Multiple Release Forms for Teardown Work Orders]     
 EXECUTE [sp_workOrderReleaseFromPDFData] 482
**************************************************************/ 

CREATE   Procedure [dbo].[sp_workOrderReleaseFromPDFData]
@ReleaseFromId bigint
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
			BEGIN  
			    DECLARE @MSModuleId INT,@MasterCompanyId INT;
				DECLARE @MasterCompanyCode VARCHAR(100)='', @PARMasterCompanyCode VARCHAR(100)=''
				
				SET @MSModuleId = 12 ; -- For WO PART NUMBER

				SELECT @MasterCompanyId = [MasterCompanyId] FROM [DBO].[Work_ReleaseFrom_8130] CTT WITH(NOLOCK) WHERE [ReleaseFromId]=@ReleaseFromId;

				SELECT @MasterCompanyCode = [MasterCompanyCode] FROM [DBO].[MasterCompany] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;
				-- PAR COMPANY
				SELECT @PARMasterCompanyCode = [MasterCompanyCode] FROM [DBO].[MasterCompany] WITH(NOLOCK) WHERE [MasterCompanyCode] = 'PAR';				

				DECLARE @VerCodePrefix NVARCHAR(50),@VerCode INT

				SELECT @VerCode  = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='Version';
		
				SELECT TOP 1 @VerCodePrefix = [CodePrefix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @VerCode AND [MasterCompanyId] = @MasterCompanyId;

				DECLARE @VersionNo VARCHAR(50) = NULL

				SET @VersionNo = (SELECT * FROM [dbo].[udfGenerateCodeNumber](1, ISNULL(@VerCodePrefix,''),''));

				 SELECT 
					   wro.[ReleaseFromId]
					  ,wro.[WorkorderId]
					  ,wro.[workOrderPartNoId]
					  ,wro.[Country]
					  ,wro.[OrganizationName]
					  ,wro.[InvoiceNo]
					  ,wro.[ItemName]
					  ,CASE WHEN isnull(wop.RevisedItemmasterid,0) > 0 THEN  UPPER(ims.partnumber) ELSE UPPER(im.partnumber) END AS PartNumber
					  ,CASE WHEN isnull(wop.RevisedItemmasterid,0) > 0 THEN  UPPER(ims.PartDescription) ELSE UPPER(im.PartDescription) END AS Description
					  ,wro.[Reference]
					  ,wro.[Quantity]
					  ,CASE WHEN ISNULL(wop.RevisedSerialNumber , '') != '' THEN UPPER(wop.RevisedSerialNumber) 
								ELSE CASE WHEN ISNULL(wro.[Batchnumber], '') != '' THEN UPPER(wro.[Batchnumber])
									   ELSE CASE WHEN ISNULL(sl.SerialNumber,'') != '' THEN UPPER(sl.SerialNumber) ELSE '' END 
								END
						END AS Batchnumber
					  ,CASE WHEN ISNULL(wop.RevisedConditionId,0) > 0 THEN C.Memo ELSE wosc.conditionName END AS [status]
					   --,CASE WHEN ISNULL(wosc.ConditionId,0) > 0 THEN wosc.conditionName ELSE C.Memo END AS [status]
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
					  ,CASE WHEN @MasterCompanyCode = @PARMasterCompanyCode THEN wro.[InvoiceNo] ELSE wro.[trackingNo] END AS [trackingNo]
					  ,wro.[OrganizationAddress]
					  ,wro.[is8130from]
					  ,wro.[IsClosed]
					  ,wop.ReceivedDate
					  ,wop.[islocked]
					  ,wro.[PDFPath]
					  ,wop.[IsFinishGood] AS IsFinishGood
					  ,CASE WHEN wro.[is8130from] = 1 THEN '8130 Certificate' ELSE '9130 Form' END AS FormType 
					  ,wop.ManagementStructureId AS ManagementStructureId   
					  ,ISNULL(wro.Is813013aeOr14ae,1) Is813013aeOr14ae
					  ,ISNULL(wro.[VersionNo],@VersionNo) VersionNo
					  ,ISNULL(wro.[IsVersionIncrease],0) IsVersionIncrease
					  ,wro.[EmployeeId]
				FROM [dbo].[Work_ReleaseFrom_8130] wro WITH(NOLOCK)
				      LEFT JOIN [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) on wro.workOrderPartNoId = wop.Id
					  LEFT JOIN [dbo].[Stockline] sl  WITH(NOLOCK) ON sl.StockLineId = wop.StockLineId  
					  LEFT JOIN [dbo].[ItemMaster] im  WITH(NOLOCK) ON im.ItemMasterId = wop.ItemMasterId  
					  LEFT JOIN [dbo].[ItemMaster] ims WITH(NOLOCK) ON ims.ItemMasterId = wop.RevisedItemmasterid  
					  LEFT JOIN [dbo].[WorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId and WorkOrderSettlementId=9
				      LEFT JOIN [dbo].[WorkOrderManagementStructureDetails] MSD  WITH(NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = wop.Id
					  LEFT JOIN [dbo].[ManagementStructurelevel] MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id
					  LEFT JOIN [dbo].[LegalEntity]  le  WITH(NOLOCK) ON le.LegalEntityId   = MSL.LegalEntityId 
					  LEFT JOIN [dbo].[Condition] C WITH(NOLOCK) ON C.ConditionId = wop.RevisedConditionId
				WHERE wro.[ReleaseFromId]=@ReleaseFromId
			END

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_workOrderReleaseFromPDFData' 
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
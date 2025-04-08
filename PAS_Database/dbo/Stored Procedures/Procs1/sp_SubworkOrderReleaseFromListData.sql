/*************************************************************           
 ** File:   [sp_SubworkOrderReleaseFromListData]           
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
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    03/23/2020   Subhash Saliya	Created
	2    02/01/2024   Devendra Shekh	Updated for revised Part Panry and Condition
	3    07/09/2024   Abhishek Jirawla	Added Batchnumber to the script
	4    07/14/2024   Hemant  Saliya    Updated for Condition Is not populating in 8130
	5    12/12/2024   Moin Bloch        Updated For Get FormTypeId
	6    12/16/2024   Moin Bloch        Updated For Get FormType Name
	7    12/23/2024   Moin Bloch        Updated For Get Batchnumber from SubWorkOrderPartNumber
	8    12/31/2024   Devendra Shekh	Updated For Get FormType and WOFormType Name
	9    02/20/2025   Moin Bloch        Updated For Get Is813013aeOr14ae
	4	 07/Mar/2025  Bhargav Saliya	 UTC Date Changes 
     
 EXECUTE [sp_SubworkOrderReleaseFromListData] 10, 1, null, -1, '',null, '','','',null,null,null,null,null,null,0,1
**************************************************************/ 

CREATE   Procedure [dbo].[sp_SubworkOrderReleaseFromListData]
@SubWorkOrderId bigint,
@SubWOPartNoId bigint,
@EmployeeId bigint= 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY		

					DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
					SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
						LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
						LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
						LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
					WHERE E.EmployeeId = @EmployeeId; 

				   DECLARE @ManagementStructureId INT;
				   DECLARE @WopartId INT;
				   DECLARE @MSModuleId INT;
				   SET @MSModuleId = 0 ; -- For WO PART NUMBER
				   SELECT @MSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'WORKORDERMPN';
				   SELECT @WopartId = WS.[ID],@ManagementStructureId = ws.[ManagementStructureId] FROM [dbo].[SubWorkOrderPartNumber] sWS WITH (NOLOCK) 
				   INNER JOIN [dbo].[WorkOrderPartNumber] ws WITH (NOLOCK) ON sws.[WorkOrderId]=ws.[WorkOrderId] 
					WHERE sWS.[SubWorkOrderId] = @SubWorkOrderId

				 SELECT 
					   wro.[SubReleaseFromId]
					  ,wro.[WorkorderId]
					  ,wro.[SubWorkOrderId]
					  ,wro.[SubWOPartNoId]
					  ,wro.[Country]
					  ,wro.[OrganizationName]
					  ,wro.[InvoiceNo]
					  ,wro.[ItemName]
					  ,CASE WHEN ISNULL(wop.RevisedItemmasterid,0) > 0 THEN  UPPER(ims.partnumber) ELSE UPPER(im.partnumber) END AS PartNumber
					  ,CASE WHEN ISNULL(wop.RevisedItemmasterid,0) > 0 THEN  UPPER(ims.PartDescription) ELSE UPPER(im.PartDescription) END AS [Description]
					  ,wro.[Reference]
					  ,wro.[Quantity]
					  ,CASE WHEN ISNULL(UPPER(wro.[Batchnumber]), '') != '' AND UPPER(wro.[Batchnumber]) != '' --ISNULL(UPPER(wro.[Batchnumber]), '') != ''
					        THEN UPPER(wro.[Batchnumber]) 
							ELSE 
								CASE WHEN ISNULL(wop.RevisedItemmasterid,0) > 0 
								THEN UPPER(wop.RevisedSerialNumber) 
									ELSE 
										UPPER(wro.[Batchnumber]) 
									END 
					   END AS Batchnumber
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
					  ,CASE WHEN CAST(wro.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(wro.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END CreatedDate
					  ,CASE WHEN CAST(wro.[UpdatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(wro.[UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME))END [UpdatedDate]
					  ,wro.[IsActive]
					  ,wro.[IsDeleted]
					  ,wro.[trackingNo]
					  ,wro.[OrganizationAddress]
					  ,wro.[is8130from]
					  ,wro.[IsClosed]
					  --,wop.CustomerRequestDate  AS ReceivedDate
					  ,wopn.ReceivedDate
					  ,wro.[islocked]
					  ,wro.[IsEASALicense]
					  ,CASE WHEN wro.[is8130from] = 1 THEN '8130 Certificate' ELSE '9130 Form' END AS FormType 
					  ,@ManagementStructureId AS  ManagementStructureId 
					  ,wro.[EmployeeId]
					  ,wro.[FormTypeId]
					  ,CASE WHEN wro.[FormTypeId] = 1 THEN '8130 ONLY' WHEN wro.[FormTypeId] = 2 THEN 'EASA' WHEN wro.[FormTypeId] = 3 THEN 'UK-CAA' ELSE '' END WOFormType
				      ,wro.Is813013aeOr14ae
				FROM [dbo].[SubWorkOrder_ReleaseFrom_8130] wro WITH(NOLOCK)
				      LEFT JOIN [dbo].[SubWorkOrderPartNumber] wop WITH(NOLOCK) ON wro.SubWOPartNoId = wop.SubWOPartNoId
					  LEFT JOIN [dbo].[SubWorkOrder] swo  WITH(NOLOCK) ON swo.SubWorkOrderId = wop.SubWorkOrderId   
					  LEFT JOIN [dbo].[ItemMaster] im  WITH(NOLOCK) ON im.ItemMasterId = wop.ItemMasterId  
					  LEFT JOIN [dbo].[ItemMaster] ims WITH(NOLOCK) ON ims.ItemMasterId = wop.RevisedItemmasterid  
				      LEFT JOIN [dbo].[WorkOrderManagementStructureDetails] MSD  WITH(NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = @WopartId
					  LEFT JOIN [dbo].[ManagementStructurelevel] MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id
					  LEFT JOIN [dbo].[SubWorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.SubWOPartNoId = wosc.SubWOPartNoId AND wosc.WorkOrderSettlementId = 9
					  LEFT JOIN [dbo].[Condition] c WITH(NOLOCK) ON c.ConditionId = wop.RevisedConditionId 
					  LEFT JOIN [dbo].[LegalEntity]  le  WITH(NOLOCK) ON le.LegalEntityId   = MSL.LegalEntityId 
				      LEFT JOIN [dbo].[WorkOrderPartNumber] wopn  WITH(NOLOCK) ON wopn.ID = swo.WorkOrderPartNumberId 
				WHERE wro.SubWorkOrderId=@SubWorkOrderId AND wro.SubWOPartNoId =@SubWOPartNoId  
		
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'				
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_SubworkOrderReleaseFromListData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWorkOrderId, '') + '''
													   @Parameter2 = ' + ISNULL(CAST(@SubWOPartNoId AS varchar(10)) ,'') +''
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
/*************************************************************           
 ** File:   [sp_workOrderReleaseFromListData]           
 ** Author:   Subhash Saliya
 ** Description: Get Search Data for GetSubWOAsset List    
 ** Purpose:         
 ** Date:   23-march-2020 
 ** PARAMETERS:                   
 ** RETURN VALUE:         
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    03/23/2020   Subhash Saliya Created
	2    06/25/2020   Hemant  Saliya Added Transation & Content Management
	3    05/12/2023   Hemant  Saliya Updated for revised Part Panry and Condition
	4    07/14/2024   Hemant  Saliya Updated for Condition Is not populating in 8130
    5    07/29/2024   HEMANT SALIYA  Updated For Get Part Number, Serial NUmber and Condition from Work Order Part table
	6    12/11/2024   Moin Bloch     Updated For Get FormTypeId
	7    12/13/2024   Moin Bloch     Removed Static Value
	8    12/16/2024   Moin Bloch     Updated For Get FormType Name
	9    12/31/2024   Devendra Shekh Updated For Get FormType and WOFormType Name
	10   02/12/2025   Moin Bloch     Updated For Get Is813013aeOr14ae
	11   02/14/2025   Bhargav Saliya UTC Date Changes
	12   08/25/2025   Moin Bloch     Updated For Get [FormStatus]
	13   10/10/2025   Moin Bloch     Updated For Get VersionNo & IsVersionIncrease Flag
	14   14/10/2025   Moin Bloch     Updated For Type Wise Order
	

 EXECUTE [sp_workOrderReleaseFromListData] 4655,4218
**************************************************************/ 

CREATE   Procedure [dbo].[sp_workOrderReleaseFromListData]
@WorkorderId bigint,
@workOrderPartNoId bigint,
@ReleaseFromId bigint,
@EmployeeId bigint = 0
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
			LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId; 

		BEGIN TRY
			    DECLARE @MSModuleId INT;
				SET @MSModuleId = 0; -- For WO PART NUMBER

				DECLARE @WorkOrderSettlementId BIGINT

				SELECT @MSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'WORKORDERMPN';
				
				SELECT @WorkOrderSettlementId = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH(NOLOCK) WHERE UPPER([WorkOrderSettlementName]) = UPPER('FINAL COND/CERT');

				IF(ISNULL(@ReleaseFromId,0) = 0)
				BEGIN
				 SELECT 
					   wro.[ReleaseFromId]
					  ,wro.[WorkorderId]
					  ,wro.[workOrderPartNoId]
					  ,wro.[Country]
					  ,wro.[OrganizationName]
					  ,wro.[InvoiceNo]
					  ,wro.[ItemName]
					  ,CASE WHEN ISNULL(wop.RevisedItemmasterid,0) > 0 THEN  UPPER(ims.partnumber) ELSE UPPER(im.partnumber) END AS [PartNumber]
					  ,CASE WHEN ISNULL(wop.RevisedItemmasterid,0) > 0 THEN  UPPER(ims.PartDescription) ELSE UPPER(im.PartDescription) END AS [Description]
					  ,wro.[Reference]
					  ,wro.[Quantity]
					  ,CASE WHEN ISNULL(wop.RevisedSerialNumber , '') != '' THEN UPPER(wop.RevisedSerialNumber) 
								ELSE CASE WHEN ISNULL(wro.[Batchnumber], '') != '' THEN UPPER(wro.[Batchnumber])
									   ELSE CASE WHEN ISNULL(sl.SerialNumber,'') != '' THEN UPPER(sl.SerialNumber) ELSE '' END 
								END
						END AS Batchnumber
					  ,CASE WHEN ISNULL(wop.RevisedConditionId,0) > 0 THEN C.Memo ELSE wosc.conditionName END AS [status]
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
					  ,CASE WHEN CAST(wro.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(wro.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATE))END CreatedDate
					  ,CASE WHEN CAST(wro.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(wro.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATE))END UpdatedDate
					  ,wro.[IsActive]
					  ,wro.[IsDeleted]
					  ,wro.[trackingNo]
					  ,wro.[OrganizationAddress]
					  ,wro.[is8130from]
					  ,wro.[IsClosed]
					  ,wop.ReceivedDate
					  ,wro.[islocked]
					  ,wro.[IsEASALicense]
					  ,CASE WHEN wro.[is8130from] = 1 THEN '8130 Certificate' ELSE '9130 Form' END AS FormType 
					  ,wop.[ManagementStructureId]
					  ,wro.[EmployeeId]
					  ,wro.[FormTypeId]
					  ,CASE WHEN wro.[FormTypeId] = 1 THEN '8130 ONLY' WHEN wro.[FormTypeId] = 2 THEN 'EASA' WHEN wro.[FormTypeId] = 3 THEN 'UK-CAA' ELSE '' END WOFormType
				      ,wro.Is813013aeOr14ae
					  ,CASE WHEN wro.[IsLocked] = 1 THEN 'Locked' ELSE 'Unlock' END AS [FormStatus]
					  ,wro.[VersionNo]
					  ,ISNULL(wro.[IsVersionIncrease],0) [IsVersionIncrease]
				FROM [dbo].[Work_ReleaseFrom_8130] wro WITH(NOLOCK)
				      LEFT JOIN [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) ON wro.workOrderPartNoId = wop.Id
					  LEFT JOIN [dbo].[Stockline] sl  WITH(NOLOCK) ON sl.StockLineId = wop.StockLineId  
					  LEFT JOIN [dbo].[ItemMaster] im  WITH(NOLOCK) ON im.ItemMasterId = wop.ItemMasterId  
					  LEFT JOIN [dbo].[ItemMaster] ims WITH(NOLOCK) ON ims.ItemMasterId = wop.RevisedItemmasterid  
					  LEFT JOIN [dbo].[WorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = @WorkOrderSettlementId
				      LEFT JOIN [dbo].[WorkOrderManagementStructureDetails] MSD  WITH(NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = wop.Id
					  LEFT JOIN [dbo].[ManagementStructurelevel] MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id
					  LEFT JOIN [dbo].[LegalEntity]  le  WITH(NOLOCK) ON le.LegalEntityId   = MSL.LegalEntityId 
					  LEFT JOIN [dbo].[Condition] C WITH(NOLOCK) ON C.ConditionId = wop.RevisedConditionId
				WHERE wro.[WorkOrderId]=@WorkorderId AND wro.[workOrderPartNoId] =@workOrderPartNoId  
					ORDER BY [WOFormType],wro.[ReleaseFromId] DESC
				END
				ELSE
				BEGIN
					SELECT 
					   wro.[ReleaseFromId]
					  ,wro.[WorkorderId]
					  ,wro.[workOrderPartNoId]
					  ,wro.[Country]
					  ,wro.[OrganizationName]
					  ,wro.[InvoiceNo]
					  ,wro.[ItemName]
					  ,CASE WHEN ISNULL(wop.RevisedItemmasterid,0) > 0 THEN  UPPER(ims.partnumber) ELSE UPPER(im.partnumber) END AS [PartNumber]
					  ,CASE WHEN ISNULL(wop.RevisedItemmasterid,0) > 0 THEN  UPPER(ims.PartDescription) ELSE UPPER(im.PartDescription) END AS [Description]
					  ,wro.[Reference]
					  ,wro.[Quantity]
					  ,CASE WHEN ISNULL(wop.RevisedSerialNumber , '') != '' THEN UPPER(wop.RevisedSerialNumber) 
								ELSE CASE WHEN ISNULL(wro.[Batchnumber], '') != '' THEN UPPER(wro.[Batchnumber])
									   ELSE CASE WHEN ISNULL(sl.SerialNumber,'') != '' THEN UPPER(sl.SerialNumber) ELSE 'NA' END 
								END
						END AS Batchnumber
					  ,CASE WHEN ISNULL(wop.RevisedConditionId,0) > 0 THEN C.Memo ELSE wosc.conditionName END AS [status]
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
					  ,CASE WHEN CAST(wro.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(wro.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATE))END CreatedDate
					  ,CASE WHEN CAST(wro.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(wro.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATE))END UpdatedDate
					  ,wro.[IsActive]
					  ,wro.[IsDeleted]
					  ,wro.[trackingNo]
					  ,wro.[OrganizationAddress]
					  ,wro.[is8130from]
					  ,wro.[IsClosed]
					  ,wop.ReceivedDate
					  ,wro.[islocked]
					  ,wro.[IsEASALicense]
					  ,CASE WHEN wro.[is8130from] = 1 THEN '8130 Form' ELSE '9130 Form' END AS FormType 
					  ,wop.[ManagementStructureId]
					  ,wro.[EmployeeId]
					  ,wro.[FormTypeId]
					  ,CASE WHEN wro.[FormTypeId] = 1 THEN '8130 ONLY' WHEN wro.[FormTypeId] = 2 THEN 'EASA' WHEN wro.[FormTypeId] = 3 THEN 'UK' ELSE '' END WOFormType
				      ,wro.Is813013aeOr14ae
					  ,CASE WHEN wro.[IsLocked] = 1 THEN 'Locked' ELSE 'Unlock' END AS [FormStatus]
					  ,wro.[VersionNo]
					  ,ISNULL(wro.[IsVersionIncrease],0) [IsVersionIncrease]
				FROM [dbo].[Work_ReleaseFrom_8130] wro WITH(NOLOCK)
				      LEFT JOIN [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) ON wro.workOrderPartNoId = wop.Id
					  LEFT JOIN [dbo].[Stockline] sl  WITH(NOLOCK) ON sl.StockLineId = wop.StockLineId  
					  LEFT JOIN [dbo].[ItemMaster] im  WITH(NOLOCK) ON im.ItemMasterId = wop.ItemMasterId  
					  LEFT JOIN [dbo].[ItemMaster] ims WITH(NOLOCK) ON ims.ItemMasterId = wop.RevisedItemmasterid  
					  LEFT JOIN [dbo].[WorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = @WorkOrderSettlementId
				      LEFT JOIN [dbo].[WorkOrderManagementStructureDetails] MSD  WITH(NOLOCK) ON MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = wop.Id
					  LEFT JOIN [dbo].[ManagementStructurelevel] MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id
					  LEFT JOIN [dbo].[LegalEntity]  le  WITH(NOLOCK) ON le.LegalEntityId   = MSL.LegalEntityId 
					  LEFT JOIN [dbo].[Condition] C WITH(NOLOCK) ON C.ConditionId = wop.RevisedConditionId
				WHERE wro.[WorkOrderId]=@WorkorderId 
				  AND wro.[workOrderPartNoId] =@workOrderPartNoId 
				  AND wro.[ReleaseFromId] = @ReleaseFromId				 
				  ORDER BY [WOFormType],wro.[ReleaseFromId] DESC
				END
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'				
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_workOrderReleaseFromListData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@WorkorderId AS VARCHAR(10)) ,'') + '''
													   @Parameter2 = ' + ISNULL(CAST(@workOrderPartNoId AS VARCHAR(10)) ,'') +''
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
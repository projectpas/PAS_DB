/************************************************************             
 ** File:   [GetVendorPaymentAccountingBatchDetailsById]             
 ** Author:  Seema Mansuri  
 ** Description: This stored procedure is used VendorPaymentAccountingBatchDetailsById  
 ** Purpose:           
 ** Date:   27/11/2023             
 ** PARAMETERS: @ReadyToPayId bigint  

 eXEC dbo].[GetVendorPaymentAccountingBatchDetailsById]  213
  **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------  
	1    09/02/2024   Seema Mansuri			 CREATED
	2    25/10/2024   Devendra Shekh	     Modifed(added case to select MS Level Details)
 ************************/

CREATE   PROCEDURE [dbo].[GetVendorPaymentAccountingBatchDetailsById]  
@ReadyToPayId bigint
AS  
BEGIN 
 BEGIN TRY  
 DECLARE @CPModuleID INT= 63 
				--PRINT 'CKS'
  
				SELECT JBD.CommonJournalBatchDetailId
					  ,JBD.[JournalBatchDetailId]  
					  ,JBH.[JournalBatchHeaderId]  
					  ,JBH.[BatchName]  
					  ,JBD.[LineNumber]  
					  ,JBD.[GlAccountId]  
					  ,JBD.[GlAccountNumber]  
					  ,JBD.[GlAccountName]  
					  ,GLC.[GLAccountClassName]
					  ,JBD.[TransactionDate]  
					  ,JBD.[EntryDate]  
					  ,SBD.ReferenceId AS [ReferenceId]  
					  ,JBD.[JournalTypeId]  
					  ,JBD.[JournalTypeName] AS JournalTypeName  
					  ,JBD.[IsDebit]  
					  ,JBD.[DebitAmount]  
					  ,JBD.[CreditAmount]  
					  ,SBD.[VendorId]  
					  ,V.VendorName AS [VendorName]  
					  ,SBD.DocumentNo AS [DocumentNumber]  
					  ,JBD.[ManagementStructureId]  
					  ,JBD.[ModuleName]  
					  ,JBD.[MasterCompanyId]  
					  ,JBD.[CreatedBy]  
					  ,JBD.[UpdatedBy]  
					  ,JBD.[CreatedDate]  
					  ,JBD.[UpdatedDate]  
					  ,JBD.[IsActive]  
					  ,JBD.[IsDeleted]  
					  ,GL.AllowManualJE  
					  ,JBD.LastMSLevel  
					  ,JBD.AllMSlevels  
					  ,JBD.IsManualEntry  
					  ,jbd.DistributionSetupId  
					  ,jbd.DistributionName  
					  ,le.CompanyName AS LegalEntityName  
					  ,BD.JournalTypeNumber,BD.CurrentNumber  
					  ,BS.Name AS 'Status'
					  ,CASE WHEN UPPER(MSD.Level1Name) IS NOT NULL THEN UPPER(MSD.Level1Name) ELSE UPPER(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description]) END AS level1,    
					   CASE WHEN UPPER(MSD.Level2Name) IS NOT NULL THEN UPPER(MSD.Level2Name) ELSE UPPER(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description]) END AS level2,   
					   CASE WHEN UPPER(MSD.Level3Name) IS NOT NULL THEN UPPER(MSD.Level3Name) ELSE UPPER(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description]) END AS level3,   
					   CASE WHEN UPPER(MSD.Level4Name) IS NOT NULL THEN UPPER(MSD.Level4Name) ELSE UPPER(CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description]) END AS level4,   
					   CASE WHEN UPPER(MSD.Level5Name) IS NOT NULL THEN UPPER(MSD.Level5Name) ELSE UPPER(CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description]) END AS level5,   
					   CASE WHEN UPPER(MSD.Level6Name) IS NOT NULL THEN UPPER(MSD.Level6Name) ELSE UPPER(CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description]) END AS level6,   
					   CASE WHEN UPPER(MSD.Level7Name) IS NOT NULL THEN UPPER(MSD.Level7Name) ELSE UPPER(CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description]) END AS level7,   
					   CASE WHEN UPPER(MSD.Level8Name) IS NOT NULL THEN UPPER(MSD.Level8Name) ELSE UPPER(CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description]) END AS level8,   
					   CASE WHEN UPPER(MSD.Level9Name) IS NOT NULL THEN UPPER(MSD.Level9Name) ELSE UPPER(CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description]) END AS level9,   
					   CASE WHEN UPPER(MSD.Level10Name) IS NOT NULL THEN UPPER(MSD.Level10Name) ELSE UPPER(CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description]) END  AS level10
			   FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
					INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId    
					INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId    
					LEFT JOIN [dbo].[VendorPaymentBatchDetails] SBD WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId=SBD.CommonJournalBatchDetailId  
					LEFT JOIN [dbo].[AccountingManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CPModuleID AND MSD.ReferenceID = SBD.ReferenceId  
					LEFT JOIN [dbo].[Vendor] V WITH(NOLOCK) ON SBD.VendorId=V.VendorId  
					LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId   
					LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GL.GLAccountTypeId 
					LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] ESP WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = ESP.[ReferenceId] AND JBD.[ManagementStructureId] = ESP.[EntityMSID]
					LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID  
					LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId  
					LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id
					LEFT JOIN [dbo].[ManagementStructureLevel] MSL1 WITH (NOLOCK) ON ESP.Level1Id = MSL1.ID
					LEFT JOIN [dbo].[ManagementStructureLevel] MSL2 WITH (NOLOCK) ON ESP.Level2Id = MSL2.ID
					LEFT JOIN [dbo].[ManagementStructureLevel] MSL3 WITH (NOLOCK) ON ESP.Level3Id = MSL3.ID
					LEFT JOIN [dbo].[ManagementStructureLevel] MSL4 WITH (NOLOCK) ON ESP.Level4Id = MSL4.ID
					LEFT JOIN [dbo].[ManagementStructureLevel] MSL5 WITH (NOLOCK) ON ESP.Level5Id = MSL5.ID
					LEFT JOIN [dbo].[ManagementStructureLevel] MSL6 WITH (NOLOCK) ON ESP.Level6Id = MSL6.ID
					LEFT JOIN [dbo].[ManagementStructureLevel] MSL7 WITH (NOLOCK) ON ESP.Level7Id = MSL7.ID
					LEFT JOIN [dbo].[ManagementStructureLevel] MSL8 WITH (NOLOCK) ON ESP.Level8Id = MSL8.ID
					LEFT JOIN [dbo].[ManagementStructureLevel] MSL9 WITH (NOLOCK) ON ESP.Level9Id = MSL9.ID
					LEFT JOIN [dbo].[ManagementStructureLevel] MSL10 WITH (NOLOCK) ON ESP.Level10Id = MSL10.ID
				WHERE SBD.ReferenceId =@ReadyToPayId AND JBD.IsDeleted = 0  

				
    END TRY  
 BEGIN CATCH        
  --IF @@trancount > 0  
   --PRINT 'ROLLBACK'  
   --ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'GetJournalBatchDetailsViewpopupById'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReadyToPayId, '') + ''  
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
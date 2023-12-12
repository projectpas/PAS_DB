/************************************************************             
 ** File:   [GetVendorPaymentAccountingBatchDetailsById]             
 ** Author:  Seema Mansuri  
 ** Description: This stored procedure is used VendorPaymentAccountingBatchDetailsById  
 ** Purpose:           
 ** Date:   27/11/2023             
 ** PARAMETERS: @ReadyToPayId bigint  

 eXEC dbo].[GetVendorPaymentAccountingBatchDetailsById]  213

 ************************/

CREATE      PROCEDURE [dbo].[GetVendorPaymentAccountingBatchDetailsById]  
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
					  ,UPPER(MSD.Level1Name) AS level1,    
					   UPPER(MSD.Level2Name) AS level2,   
					   UPPER(MSD.Level3Name) AS level3,   
					   UPPER(MSD.Level4Name) AS level4,   
					   UPPER(MSD.Level5Name) AS level5,   
					   UPPER(MSD.Level6Name) AS level6,   
					   UPPER(MSD.Level7Name) AS level7,   
					   UPPER(MSD.Level8Name) AS level8,   
					   UPPER(MSD.Level9Name) AS level9,   
					   UPPER(MSD.Level10Name) AS level10   
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
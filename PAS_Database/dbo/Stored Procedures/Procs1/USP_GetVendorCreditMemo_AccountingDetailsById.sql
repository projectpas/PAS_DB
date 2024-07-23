/*********************             
 ** File:   [USP_GetVendorCreditMemo_AccountingDetailsById]             
 ** Author:  Devendra Shekh 
 ** Description: This stored procedure is used to GetJournalBatchDetailsById for vendor credit memo
 ** Purpose:           
 ** Date:   09/11/2023      
            
 ** PARAMETERS: @ReferenceId bigint  
           
 ** RETURN VALUE:             
 **********************             
 ** Change History             
 **********************             
 ** PR   Date			 Author				Change Description              
 ** --   --------		 -------			--------------------------------            
    1    09/11/2023		Devendra Shekh			Created  
    3    20/10/2023     Bhargav Saliya         Export Data Convert Into Upper Case   
	4    20-03-2024     Shrey Chandegara       Add @VendorCMIds
	5    10/05/2023     Moin Bloch             Added IsUpdated
	6    16/07/2024     Sahdev Saliya          Added (AccountingPeriod)

-- exec USP_GetVendorCreditMemo_AccountingDetailsById 90
************************/   
 CREATE      PROCEDURE [dbo].[USP_GetVendorCreditMemo_AccountingDetailsById]    
@ReferenceId bigint
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY        
   BEGIN       

	DECLARE @AccountMSModuleId INT = 0
	SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';
	DECLARE @VendorCMIds VARCHAR(50) = '';

	SELECt @VendorCMIds = STUFF(
		 (SELECT ',' + CAST(VendorCreditMemoId AS VARCHAR) FROM [dbo].[VendorCreditMemo] VCM
		  WHERE VCM.VendorRMAId = VRM.VendorRMAId FOR XML PATH ('')), 1, 1, '') 
		  FROM [dbo].[VendorRMA] VRM
		  WHERE VRM.VendorRMAId = @ReferenceId
		  GROUP BY vrm.VendorRMAId

     SELECT JBD.CommonJournalBatchDetailId  
		  ,VPBD.VendorRMAPaymentBatchDetilsId
          ,JBD.[JournalBatchDetailId]  
          ,JBH.[JournalBatchHeaderId]  
          ,JBH.[BatchName]  
          ,JBD.[LineNumber]  
          ,JBD.[GlAccountId]  
          ,JBD.[GlAccountNumber]  
          ,UPPER(JBD.[GlAccountName]) AS [GlAccountName]
          ,JBD.[TransactionDate]  
          ,JBD.[EntryDate]  
		  ,VPBD.ReferenceId
          ,JBD.[JournalTypeId]  
          ,uPPER(JBD.[JournalTypeName]) AS  [JournalTypeName] 
          ,JBD.[IsDebit]  
          ,JBD.[DebitAmount]  
          ,JBD.[CreditAmount]
          ,JBD.[ManagementStructureId]  
          ,JBD.[ModuleName]                 
          ,JBD.[MasterCompanyId]  
          ,JBD.[CreatedBy]  
          ,JBD.[UpdatedBy]  
          ,JBD.[CreatedDate]  
          ,JBD.[UpdatedDate]  
          ,JBD.[IsActive]  
          ,JBD.[IsDeleted]  
          ,GLA.[AllowManualJE]  
          ,JBD.[LastMSLevel]  
          ,JBD.[AllMSlevels]  
          ,JBD.[IsManualEntry]  
          ,JBD.[DistributionSetupId]  
          ,JBD.[DistributionName]  
          ,LET.[CompanyName] AS LegalEntityName  
		  ,VDR.VendorName AS [VendorName]  
          ,BD.JournalTypeNumber
		  ,BD.CurrentNumber 
		  ,BD.AccountingPeriod AS 'AcctingPeriod'
		  ,UPPER(BS.Name) AS 'Status'
		  ,UPPER(CR.Code) AS Currency  
		  --,'' AS [Currency]  
		  ,'' AS [DocumentNumber] 
		  ,0 AS [CustomerId],'' AS [CustomerName],0 AS [InvoiceId],'' AS [InvoiceName],'' AS [ARControlNumber],'' AS [CustomerRef]
          ,CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description] AS level1
		  ,CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description] AS level2
		  ,CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description] AS level3
		  ,CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description] AS level4
		  ,CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description] AS level5
		  ,CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description] AS level6
		  ,CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description] AS level7
		  ,CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description] AS level8
		  ,CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description] AS level9
		  ,CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description] AS level10
		  ,CASE WHEN JBD.IsUpdated = 1 THEN 1 ELSE 0 END AS IsUpdated
   FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
		INNER JOIN [dbo].[DistributionSetup] DS WITH(NOLOCK) ON JBD.DistributionSetupId=DS.ID  
		INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId  
		INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId  
		LEFT JOIN [dbo].[VendorRMAPaymentBatchDetails] VPBD WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId = VPBD.CommonJournalBatchDetailId  
		LEFT JOIN [dbo].[Vendor] VDR WITH(NOLOCK) ON VDR.VendorId = VPBD.VendorId  	
		LEFT JOIN [dbo].[GLAccount] GLA WITH(NOLOCK) ON GLA.[GLAccountId] = JBD.[GLAccountId]  
		LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = MSD.[ReferenceId] AND 
		JBD.[ManagementStructureId] = MSD.[EntityMSID] AND MSD.ModuleId = @AccountMSModuleId
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL1 WITH (NOLOCK) ON MSD.Level1Id = MSL1.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL2 WITH (NOLOCK) ON MSD.Level2Id = MSL2.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL3 WITH (NOLOCK) ON MSD.Level3Id = MSL3.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL4 WITH (NOLOCK) ON MSD.Level4Id = MSL4.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL5 WITH (NOLOCK) ON MSD.Level5Id = MSL5.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL6 WITH (NOLOCK) ON MSD.Level6Id = MSL6.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL7 WITH (NOLOCK) ON MSD.Level7Id = MSL7.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL8 WITH (NOLOCK) ON MSD.Level8Id = MSL8.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL9 WITH (NOLOCK) ON MSD.Level9Id = MSL9.ID
		LEFT JOIN [dbo].[ManagementStructureLevel] MSL10 WITH (NOLOCK) ON MSD.Level10Id = MSL10.ID
		LEFT JOIN [dbo].[LegalEntity] LET WITH(NOLOCK) ON MSL1.LegalEntityId = LET.LegalEntityId  
		LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id
		LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = VDR.CurrencyId  
     WHERE VPBD.ReferenceID IN (SELECT value FROM STRING_SPLIT(@VendorCMIds, ',')) OR VPBD.ReferenceID = @ReferenceId
  END    
  END TRY    
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK' 
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorCreditMemo_AccountingDetailsById'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReferenceId, '') + ''    
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
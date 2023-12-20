/*************************************************************             
 ** File:   [GetAccountingDetailsViewById]             
 ** Author:  Shrey Chandegara  
 ** Description: This stored procedure is used GetJournalBatchDetailsById for customer receipt batch  
 ** Purpose:           
 ** Date:   09/o5/2023       
            
 ** PARAMETERS: @SalesOrderId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author				Change Description              
 ** --   --------		 -------			--------------------------------            
    1    09/o5/2023		Devendra Shekh			Created  
       
-- exec USP_GetCustomerReceipt_AccountingDetailsById 81  
************************************************************************/   
CREATE   PROCEDURE [dbo].[USP_GetCustomerReceipt_AccountingDetailsById]    
@ReferenceId bigint    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY        
   BEGIN       

	DECLARE @AccountMSModuleId INT = 0
	SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';
	--DECLARE @CPModuleID INT=59;

     SELECT JBD.CommonJournalBatchDetailId
		   ,CRB.CustomerReceiptBatchDetailId
	      ,JBD.[JournalBatchDetailId]  
          ,JBH.[JournalBatchHeaderId]  
          ,JBH.[BatchName]  
          ,JBD.[LineNumber]  
          ,JBD.[GlAccountId]  
          ,JBD.[GlAccountNumber]  
          ,JBD.[GlAccountName]  
          ,JBD.[TransactionDate]  
          ,JBD.[EntryDate]  
          ,CRB.ReferenceId AS [ReferenceId]  
          ,CRB.ReferenceNumber AS [ReferenceNumber]  
          ,CRB.ReferenceInvId AS [ReferenceInvId]  
          ,CRB.ReferenceInvNumber AS [ReferenceInvNumber]  
          ,CRB.PaymentId AS [PaymentId]  
          ,JBD.[JournalTypeId]  
          ,(JBD.[JournalTypeName] +' - '+ UPPER(CRB.[ReferenceNumber])) as JournalTypeName  
          ,JBD.[IsDebit]  
          ,JBD.[DebitAmount]  
          ,JBD.[CreditAmount]  
          ,CRB.[CustomerId]  
          ,CRB.CustomerName AS [CustomerName]  
          ,CRB.DocumentId AS [InvoiceId]  
          ,CRB.DocumentNumber AS [InvoiceName]  
          ,CRB.ARControlNumber
          ,CRB.CustomerRef
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
		  ,CR.Code AS Currency  
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
   FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
		INNER JOIN [dbo].[DistributionSetup] DS WITH(NOLOCK) ON JBD.DistributionSetupId=DS.ID  
		INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId = BD.JournalBatchDetailId    
		INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId = JBH.JournalBatchHeaderId    
		LEFT JOIN [dbo].[CustomerReceiptBatchDetails] CRB WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId = CRB.CommonJournalBatchDetailId  
		--LEFT JOIN [dbo].[CustomerManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CPModuleID AND MSD.ReferenceID = CRB.ReferenceId  
		LEFT JOIN [dbo].[Customer] C WITH(NOLOCK) ON CRB.CustomerId=C.CustomerId  
		LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId   
		LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = MSD.[ReferenceId] AND 
		JBD.[ManagementStructureId] = MSD.[EntityMSID] AND MSD.ModuleId = @AccountMSModuleId
		LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON MSD.Level1Id = MSL1.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL2 WITH (NOLOCK) ON MSD.Level2Id = MSL2.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL3 WITH (NOLOCK) ON MSD.Level3Id = MSL3.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL4 WITH (NOLOCK) ON MSD.Level4Id = MSL4.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL5 WITH (NOLOCK) ON MSD.Level5Id = MSL5.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL6 WITH (NOLOCK) ON MSD.Level6Id = MSL6.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL7 WITH (NOLOCK) ON MSD.Level7Id = MSL7.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL8 WITH (NOLOCK) ON MSD.Level8Id = MSL8.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL9 WITH (NOLOCK) ON MSD.Level9Id = MSL9.ID
		LEFT JOIN dbo.ManagementStructureLevel MSL10 WITH (NOLOCK) ON MSD.Level10Id = MSL10.ID
		LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON MSL1.LegalEntityId = le.LegalEntityId  
		LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id
		LEFT JOIN  [dbo].[CustomerFinancial] CF WITH(NOLOCK) ON CF.CustomerId = CRB.CustomerId  
		LEFT JOIN  [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = CF.CurrencyId  
     WHERE CRB.ReferenceID = @ReferenceId     
  END    
  END TRY    
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetCustomerReceipt_AccountingDetailsById'     
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
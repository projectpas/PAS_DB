/*********************             
 ** File:   [USP_GetCreditMemo_AccountingDetailsById]             
 ** Author:  Devendra Shekh 
 ** Description: This stored procedure is used to GetJournalBatchDetailsById for customer credit memo
 ** Purpose:           
 ** Date:   09/06/2023       
            
 ** PARAMETERS: @ReferenceId bigint  
           
 ** RETURN VALUE:             
 **********************             
 ** Change History             
 **********************             
 ** PR   Date			 Author				Change Description              
 ** --   --------		 -------			--------------------------------            
    1    09/06/2023		Devendra Shekh			Created  
	2    22/04/2024		Moin Bloch			    Added  Acconting Detail For StandAloneCMModuleId
	3    23/04/2024     Moin Bloch	            Updated Added Document Number For List 
	4    16/07/2024     Sahdev Saliya           Added (AccountingPeriod)
       
-- exec USP_GetCreditMemo_AccountingDetailsById 225,0
************************/   
CREATE   PROCEDURE [dbo].[USP_GetCreditMemo_AccountingDetailsById]    
@ReferenceId bigint,
@ModuleId bigint
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY        
   BEGIN  
   
    DECLARE @IsWorkOrder BIT = 0
	SELECT @IsWorkOrder = IsWorkOrder from [dbo].[CreditMemo] WITH(NOLOCK) WHERE [CreditMemoHeaderId] = @ReferenceId;

	DECLARE	@StandAloneCreditMemoDetailId Varchar(MAX)=''

	DECLARE @AccountMSModuleId INT = 0
	SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';

	DECLARE @StandAloneCMModuleId INT = 0
	SELECT @StandAloneCMModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] ='StandAloneCM';

	DECLARE @CMModuleId INT = 0
	
	 IF(@ModuleId = @StandAloneCMModuleId)
	 BEGIN
	       SELECT @StandAloneCreditMemoDetailId = STRING_AGG(CONVERT(NVARCHAR(max), [StandAloneCreditMemoDetailId]), ',')    
		     FROM [dbo].[StandAloneCreditMemoDetails] WITH(NOLOCK) 
		    WHERE [CreditMemoHeaderId] = @ReferenceId
	 END

	 IF(@IsWorkOrder = 1 AND @ModuleId != @StandAloneCMModuleId)
	 BEGIN
	 	SELECT @CMModuleId = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='WorkOrderMPN';
	 END
	 ELSE IF(@IsWorkOrder = 0 AND @ModuleId != @StandAloneCMModuleId)
	 BEGIN
	 	SELECT @CMModuleId = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Stockline';
	 END

	 IF(@ModuleId = @StandAloneCMModuleId)
	 BEGIN
		SELECT JBD.CommonJournalBatchDetailId  
			  ,CPD.CreditMemoPaymentBatchDetilsId
			  ,JBD.[JournalBatchDetailId]  
			  ,JBH.[JournalBatchHeaderId]  
			  ,JBH.[BatchName]  
			  ,JBD.[LineNumber]  
			  ,JBD.[GlAccountId]  
			  ,JBD.[GlAccountNumber]  
			  ,JBD.[GlAccountName]  
			  ,JBD.[TransactionDate]  
			  ,JBD.[EntryDate]  
			  ,CPD.[ReferenceID] AS [ReferenceId]
			  ,CPD.[DocumentNo] AS [ReferenceName]
			  ,JBD.[JournalTypeId]  
			  ,JBD.[JournalTypeName]  
			  ,JBD.[IsDebit]  
			  ,JBD.[DebitAmount]  
			  ,JBD.[CreditAmount]
			  ,CM.[CustomerId]
			  ,CM.[CustomerName]
			  ,'' AS [ARControlNumber]  
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
			  ,BTD.[JournalTypeNumber]  
			  ,JBH.AccountingPeriod AS 'AcctingPeriod'
			  ,BTD.[CurrentNumber]  
			  ,BS.Name AS 'Status'
			  --,'' AS [Currency]  
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
			INNER JOIN [dbo].[BatchDetails] BTD WITH(NOLOCK) ON JBD.[JournalBatchDetailId] = BTD.[JournalBatchDetailId]    
			INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BTD.[JournalBatchHeaderId] = JBH.[JournalBatchHeaderId]       
			 LEFT JOIN [dbo].[CreditMemoPaymentBatchDetails] CPD WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = CPD.[CommonJournalBatchDetailId]  
			 LEFT JOIN [dbo].[GLAccount] GLA WITH(NOLOCK) ON GLA.[GLAccountId] = JBD.[GLAccountId]  
			 LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = MSD.[ReferenceId] AND JBD.[ManagementStructureId] = MSD.[EntityMSID] AND MSD.ModuleId = @AccountMSModuleId
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
			 LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BTD.StatusId = BS.Id
		     INNER JOIN [dbo].[CreditMemo] CM WITH(NOLOCK) ON CPD.ReferenceID = CM.CreditMemoHeaderId 
			 LEFT JOIN [dbo].[CustomerFinancial] CF WITH(NOLOCK) ON CF.CustomerId = CM.CustomerId  
			 LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = CF.CurrencyId  
		 WHERE CPD.ReferenceID IN (SELECT item from SplitString(@StandAloneCreditMemoDetailId,',')) AND CPD.ModuleId  = @ModuleId
	 END
	 ELSE
	 BEGIN
		SELECT JBD.CommonJournalBatchDetailId  
			  ,CPD.CreditMemoPaymentBatchDetilsId
			  ,JBD.[JournalBatchDetailId]  
			  ,JBH.[JournalBatchHeaderId]  
			  ,JBH.[BatchName]  
			  ,JBD.[LineNumber]  
			  ,JBD.[GlAccountId]  
			  ,JBD.[GlAccountNumber]  
			  ,JBD.[GlAccountName]  
			  ,JBD.[TransactionDate]  
			  ,JBD.[EntryDate]  
			  ,CPD.ReferenceID AS [ReferenceId]
			  ,CPD.[DocumentNo] AS [ReferenceName]
			  ,JBD.[JournalTypeId]  
			  ,JBD.[JournalTypeName]  
			  ,JBD.[IsDebit]  
			  ,JBD.[DebitAmount]  
			  ,JBD.[CreditAmount]
			  ,CM.[CustomerId]
			  ,CM.[CustomerName]
			  ,'' AS [ARControlNumber]  
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
			  ,BTD.[JournalTypeNumber]  
			  ,BTD.[CurrentNumber]  
			  ,JBH.AccountingPeriod AS 'AcctingPeriod'
			  ,BS.Name AS 'Status'
			  --,'' AS [Currency]  
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
			INNER JOIN [dbo].[BatchDetails] BTD WITH(NOLOCK) ON JBD.[JournalBatchDetailId] = BTD.[JournalBatchDetailId]    
			INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BTD.[JournalBatchHeaderId] = JBH.[JournalBatchHeaderId]       
			 LEFT JOIN [dbo].[CreditMemoPaymentBatchDetails] CPD WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = CPD.[CommonJournalBatchDetailId]  
			 LEFT JOIN [dbo].[GLAccount] GLA WITH(NOLOCK) ON GLA.[GLAccountId] = JBD.[GLAccountId]  
			 LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = MSD.[ReferenceId] AND JBD.[ManagementStructureId] = MSD.[EntityMSID] AND MSD.ModuleId = @AccountMSModuleId
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
			 LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BTD.StatusId = BS.Id
			INNER JOIN [dbo].[CreditMemo] CM WITH(NOLOCK) ON CPD.ReferenceID = CM.CreditMemoHeaderId
			LEFT JOIN  [dbo].[CustomerFinancial] CF WITH(NOLOCK) ON CF.CustomerId = CM.CustomerId  
			LEFT JOIN  [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = CF.CurrencyId  
		 WHERE CPD.ReferenceID = @ReferenceId AND CPD.ModuleId  = @CMModuleId 

	 END

  END    
  END TRY    
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetCreditMemo_AccountingDetailsById'     
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
/*********************             
 ** File:   [GetAccountingDetailsViewById]             
 ** Author:  Shrey Chandegara  
 ** Description: This stored procedure is used GetJournalBatchDetailsById  
 ** Purpose:           
 ** Date:  06/07/2023        
            
 ** PARAMETERS: @SalesOrderId bigint  
           
 ** RETURN VALUE:             
 **********************             
 ** Change History             
 **********************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    06/07/2023  Shrey Chandegara     Created  
	2    08/09/2023  Ayesha Sultana       Getting JE Status field changes  
    3    20/10/2023  Bhargav Saliya       Export Data Convert Into Upper Case   
	4    30/11/2023  Moin Bloch           Added Lot Number 
	5    10/05/2023  Moin Bloch           Added IsUpdated
	6    16/07/2024  Sahdev Saliya        Added (AccountingPeriod)
	7    25/07/2024  Sahdev Saliya        Set JournalTypeNumber Order by desc

-- exec GetAccountingDetailsViewById 531   
************************/   
CREATE   PROCEDURE [dbo].[GetAccountingDetailsViewById]    
@SalesOrderId bigint    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY        
   BEGIN       
     SELECT JBH.[BatchName]    
                 ,JBD.[LineNumber]    
                 ,JBD.[GlAccountId]    
                 ,JBD.[GlAccountNumber]    
                 ,UPPER(JBD.[GlAccountName]) AS [GlAccountName]    
                 ,JBD.[TransactionDate]    
                 ,JBD.[EntryDate]    
                 ,SBD.[SalesOrderId]    
                 ,SBD.[SalesOrderNumber]    
                 ,SBD.[PartId]    
                 ,SBD.[PartNumber]    
                 ,JBD.[JournalTypeId]    
                 ,UPPER(JBD.[JournalTypeName])  AS [JournalTypeName]  
                 ,JBD.[IsDebit]    
                 ,JBD.[DebitAmount]    
                 ,JBD.[CreditAmount]    
                 ,SBD.[CustomerId]    
                 ,UPPER(SBD.[CustomerName]) AS [CustomerName]
                 ,SBD.[ARControlNumber]    
                 ,SBD.[StocklineId]  
				 ,SBD.[StocklineNumber]  
				 ,SBD.[CustomerRef]  
				 ,SBD.[CommonJournalBatchDetailId]  
                 ,JBD.[ManagementStructureId]    
                 ,JBD.[ModuleName]    
                 ,SBD.[SalesOrderBatchDetailId]   
                 ,SBD.[JournalBatchDetailId]  
                 ,SBD.[JournalBatchHeaderId]    
                 ,SBD.[CustomerTypeId]    
                 ,SBD.[CustomerType]  
			   --,SBD.[CustomerId]  
               --,SBD.[CustomerName]  
				 ,SBD.[ItemMasterId]  
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
                 ,le.CompanyName as LegalEntityName    
                 ,BD.JournalTypeNumber 
				 ,UPPER(BS.[Name]) AS JEStatus
                 ,BD.CurrentNumber  
				 ,BD.AccountingPeriod AS 'AcctingPeriod'
                 ,CR.Code AS Currency  
          ,UPPER(SSD.Level1Name) AS level1,      
           UPPER(SSD.Level2Name) AS level2,     
           UPPER(SSD.Level3Name) AS level3,     
           UPPER(SSD.Level4Name) AS level4,     
           UPPER(SSD.Level5Name) AS level5,     
           UPPER(SSD.Level6Name) AS level6,     
           UPPER(SSD.Level7Name) AS level7,     
           UPPER(SSD.Level8Name) AS level8,     
           UPPER(SSD.Level9Name) AS level9,     
           UPPER(SSD.Level10Name) AS level10,
		   JBD.LotNumber,
		   CASE WHEN JBD.IsUpdated = 1 THEN 1 ELSE 0 END AS IsUpdated
     FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)    
     INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId    
     INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId         
     LEFT JOIN  [dbo].[SalesOrderBatchDetails] SBD WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId=SBD.CommonJournalBatchDetailId       
     LEFT JOIN  [dbo].[SalesOrderManagementStructureDetails] SSD WITH (NOLOCK) ON  SSD.ReferenceID = SBD.SalesOrderId    
     LEFT JOIN  [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId     
     LEFT JOIN  [dbo].[EntityStructureSetup] ESP WITH(NOLOCK) ON JBD.ManagementStructureId = ESP.EntityStructureId    
     LEFT JOIN  [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID    
     LEFT JOIN  [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId    
	 LEFT JOIN  [dbo].[CustomerFinancial] CF WITH(NOLOCK) ON CF.CustomerId = SBD.CustomerId  
	 LEFT JOIN  [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = CF.CurrencyId  
	 LEFT JOIN  [dbo].[BatchStatus] BS WITH(NOLOCK) ON BS.Id = BD.StatusId 
     WHERE SBD.SalesOrderId = @SalesOrderId 
	 order by BD.JournalTypeNumber desc
  END    
  END TRY    
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetAccountingDetailsViewById'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''    
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
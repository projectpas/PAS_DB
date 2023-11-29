/*************************************************************               
 ** File:   [GetJournalBatchHeaderById]               
 ** Author:  Shrey Chandegara    
 ** Description: This stored procedure is used to GetJournalBatchHeaderById    
 ** Purpose:             
 ** Date:   05/04/2023          
              
 ** PARAMETERS: @JournalBatchHeaderId     
             
 ** RETURN VALUE:               
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date         Author				Change Description                
 ** --   --------     -------			--------------------------------              
    1    08/10/2022  Shrey Chandegara     Created    
	2    05/09/2023  Amit Ghediya         Updated for add JE details with Batch detail
	3	 19/06/2023  Shrey Chandegara	  Updated for add JE Detail view like GLAccount,Credit,....
	3	 29/08/2023  Devendra Shekh		  added BatchStatus join for journal batchstatus
         
-- EXEC GetMultipleJournalBatchHeaderById '321'    
************************************************************************/    
CREATE   PROCEDURE [dbo].[GetMultipleJournalBatchHeaderById]  
@JournalBatchHeaderId varchar(MAX)  = null  
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY    
   SELECT   
   JBH.[JournalBatchHeaderId],  
   JBH.[BatchName],  
   JBH.[CurrentNumber],  
   JBH.[EntryDate],  
   JBH.[PostDate],  
   JBH.[AccountingPeriod],  
   JBH.[StatusId],  
   JBH.[StatusName],  
   JBH.[JournalTypeId],  
   JBH.[JournalTypeName],  
   JBH.[TotalDebit],  
   JBH.[TotalCredit],  
   JBH.[TotalBalance],  
   JBH.[MasterCompanyId],  
   JBH.[UpdatedBy],  
   JBD.[JournalBatchDetailId],  
   JBH.[Module],  
   ISNULL(JBD.[DebitAmount],0) AS DebitAmount,  
   ISNULL(JBD.[CreditAmount],0) AS CreditAmount,  
   JBD.[JournalTypeNumber] AS DJournalTypeNumber,  
   JBD.[EntryDate] AS DEntryDate,  
   JBD.[JournalTypeName] AS DJournalTypeName,  
   JT.[JournalTypeCode],  
   JBD.[CreatedDate],  
   JBD.[UpdatedDate],  
   JBD.[CreatedBy],  
   JBD.[UpdatedBy] AS DUpdatedBy,
   CD.CreditAmount as Cr,
   CD.DebitAmount as Dr,
   CD.GlAccountNumber + ' - ' + CD.GlAccountName as GLAccount,
   CD.TransactionDate as TDate,
    BS.[Name] AS 'BatchStatus'
  FROM [dbo].[BatchHeader] JBH WITH(NOLOCK)  
  LEFT JOIN [dbo].[BatchDetails] JBD WITH(NOLOCK) ON JBD.JournalBatchHeaderId=JBH.JournalBatchHeaderId AND JBD.IsDeleted=0  
  LEFT JOIN [dbo].[JournalType] JT WITH(NOLOCK) ON JBD.JournalTypeId = JT.ID  
  LEFT JOIN [dbo].CommonBatchDetails CD WITH(NOLOCK) ON JBH.JournalBatchHeaderId = CD.JournalBatchHeaderId AND JBD.JournalBatchDetailId = CD.JournalBatchDetailId AND CD.IsDeleted = 0  
  LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON JBD.StatusId = BS.ID  

  WHERE JBH.JournalBatchHeaderId in(SELECT * FROM STRING_SPLIT(@JournalBatchHeaderId , ','))    
  GROUP BY JBH.[JournalBatchHeaderId],JBH.[BatchName],JBH.[CurrentNumber],JBH.[EntryDate],JBH.[PostDate], JBH.[AccountingPeriod], JBH.[StatusId],  
   JBH.[StatusName],JBH.[JournalTypeId],JBH.[JournalTypeName], JBH.[TotalDebit],JBH.[TotalCredit], JBH.[TotalBalance],JBH.[MasterCompanyId],  
   JBH.[UpdatedBy],JBD.[JournalBatchDetailId],JBH.[Module],JBD.[DebitAmount],JBD.[CreditAmount],  
   JBD.[JournalTypeNumber],JBD.[EntryDate],JBD.[JournalTypeName],JT.[JournalTypeCode],JBD.[CreatedDate],  
   JBD.[UpdatedDate],JBD.[CreatedBy],JBD.[UpdatedBy], CD.CreditAmount,CD.DebitAmount,CD.GlAccountName,CD.GlAccountNumber,CD.TransactionDate,BS.[Name]
  ORDER BY JBH.[EntryDate],JBD.[JournalBatchDetailId] DESC;  
    END TRY        
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetMultipleJournalBatchHeaderById'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@JournalBatchHeaderId, '') + ''    
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
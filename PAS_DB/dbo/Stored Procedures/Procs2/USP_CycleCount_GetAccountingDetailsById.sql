-- ************************************************************************************
-- Author:		<Moin Bloch>
-- Create date: <13-11-2024>
-- Description:	<This stored procedure is used Get Batch Details for Cycle Count Batch>
/***************************************************************************************   
 ** RETURN VALUE:                           
 ** Change History                           
 ** PR   Date			 Author				Change Description              
 ** --   --------		 -------			--------------------------------            
    1    13-11-2024		 Moin Bloch		Created  
****************************************************************************************/ 
--  [dbo].[USP_CycleCount_GetAccountingDetailsById] 33,1
-- *************************************************************************************
create   PROCEDURE [dbo].[USP_CycleCount_GetAccountingDetailsById]
@CycleCountId BIGINT,
@MasterCompanyId INT
AS
BEGIN	
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY        
   BEGIN       
      SELECT CBD.[CommonJournalBatchDetailId]			
			,BTH.[BatchName]        
			,CBD.[GlAccountId]  
			,CBD.[GlAccountNumber]  
			,UPPER(CBD.[GlAccountName]) AS [GlAccountName] 
			,CBD.[TransactionDate]  
			,CBD.[EntryDate] 
            ,CBD.[IsDebit]  
            ,ISNULL(CBD.[DebitAmount],0) DebitAmount  
            ,ISNULL(CBD.[CreditAmount],0) CreditAmount
            ,CBD.[CreatedBy]              
            ,CBD.[CreatedDate]
			,CBD.[LastMSLevel]  
            ,CBD.[AllMSlevels]             
            ,CCD.[StocklineNumber]
            ,CCD.[PartNumber]
			,CCD.[Site]
			,CCD.[Warehouse]
			,CCD.[Location]
			,CCD.[Bin]
			,CCD.[Shelf]
			,CCD.[ReferenceNumber]
            ,GLA.[AllowManualJE]              
            ,BTD.[JournalTypeNumber]			
			,BTD.[AccountingPeriod] 
		    ,BTS.[Name] AS 'Status'            
    FROM [dbo].[CycleCount] CCC WITH(NOLOCK) 				
		INNER JOIN [dbo].[CommonBatchDetails] CBD WITH(NOLOCK) ON CCC.[CycleCountId] = CBD.[ReferenceId]
		INNER JOIN [dbo].[CycleCountBatchDetails] CCD WITH(NOLOCK) ON CCD.[CommonJournalBatchDetailId] = CBD.[CommonJournalBatchDetailId]
		INNER JOIN [dbo].[BatchDetails] BTD WITH(NOLOCK) ON CBD.[JournalBatchDetailId] = BTD.[JournalBatchDetailId]
		INNER JOIN [dbo].[BatchHeader] BTH WITH(NOLOCK) ON BTD.[JournalBatchHeaderId] = BTH.[JournalBatchHeaderId]
		 LEFT JOIN [dbo].[GLAccount] GLA WITH(NOLOCK) ON GLA.[GLAccountId] = CBD.[GLAccountId]
		 LEFT JOIN [dbo].[BatchStatus] BTS WITH(NOLOCK) ON BTD.[StatusId] = BTS.[Id]
     WHERE CCC.[CycleCountId] = @CycleCountId AND CCC.[MasterCompanyId] = @MasterCompanyId;     
	 
  END    
  END TRY    
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_CycleCount_GetAccountingDetailsById'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CycleCountId, '') + ''    
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
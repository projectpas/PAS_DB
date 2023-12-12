--===========================================
-- Author:		<Jevik Raiyani>
-- Create date: <27-11-2023>
-- Description:	<This stored procedure is used Get GetBulkStockLineAccountingDetailsViewById for Bulk stockline accounting list>
-- =============================================
/**************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author				Change Description              
 ** --   --------		 -------			--------------------------------            
    1    27-11-2023		Jevik Raiyani		Created  

EXEC GetBulkStockLineAccountingDetailsViewById 119
************************************************************************/   

CREATE       PROCEDURE  [dbo].[GetBulkStockLineAccountingDetailsViewById]  
@ReferenceId bigint    
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY        
   BEGIN  
     DECLARE @blkSTKModuleID INT = 2; 
				DECLARE @ManagementStructureModuleId BIGINT = 0;   
				--PRINT 'SADJ-QTY'

				SELECT @ManagementStructureModuleId = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName='EmployeeGeneralInfo';
  
				SELECT DISTINCT JBD.CommonJournalBatchDetailId
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
					  ,JBD.[JournalTypeId]  
					  ,JBD.[JournalTypeName]  
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
					  ,GL.AllowManualJE  
					  ,JBD.LastMSLevel  
					  ,JBD.AllMSlevels  
					  ,JBD.IsManualEntry  
					  ,jbd.DistributionSetupId  
					  ,jbd.DistributionName  
					  ,le.CompanyName AS LegalEntityName          
					  ,STKL.PartNumber
					  ,STKL.StockLineNumber
					  ,'' AS PONum  
					  ,'' AS RONum  
					  ,'' AS StocklineNumber  
					  ,'' AS [Description]  
					  ,'' AS Consignment  
					  ,JBH.[Module]  
					  ,0 AS PartId               
					  ,'' AS PartNumber         
					  ,'' AS [DocumentNumber]  
					  ,'' AS [SIte]  
					  ,'' AS [Warehouse]  
					  ,'' AS [Location]  
					  ,'' AS [Bin]  
					  ,'' AS [Shelf]  
					  ,BD.JournalTypeNumber
					  ,BD.CurrentNumber  
					  ,0 AS [CustomerId],'' AS [CustomerName],0 AS [InvoiceId],'' AS [InvoiceName],'' AS [ARControlNum],'' AS [CustRefNumber],0 AS [ReferenceId],'' AS [ReferenceName]  
					  ,BS.Name AS 'Status'
					  ,CASE WHEN stbd.StockLineId > 0 THEN UPPER(SMSD.Level1Name) ELSE UPPER(EMSD.Level1Name) END AS level1  
					  ,CASE WHEN stbd.StockLineId > 0 THEN UPPER(SMSD.Level2Name) ELSE UPPER(EMSD.Level2Name) END AS level2   
					  ,CASE WHEN stbd.StockLineId > 0 THEN UPPER(SMSD.Level3Name) ELSE UPPER(EMSD.Level3Name) END AS level3  
					  ,CASE WHEN stbd.StockLineId > 0 THEN UPPER(SMSD.Level4Name) ELSE UPPER(EMSD.Level4Name) END AS level4 
					  ,CASE WHEN stbd.StockLineId > 0 THEN UPPER(SMSD.Level5Name) ELSE UPPER(EMSD.Level5Name) END AS level5 
					  ,CASE WHEN stbd.StockLineId > 0 THEN UPPER(SMSD.Level6Name) ELSE UPPER(EMSD.Level6Name) END AS level6 
					  ,CASE WHEN stbd.StockLineId > 0 THEN UPPER(SMSD.Level7Name) ELSE UPPER(EMSD.Level7Name) END AS level7 
					  ,CASE WHEN stbd.StockLineId > 0 THEN UPPER(SMSD.Level8Name) ELSE UPPER(EMSD.Level8Name) END AS level8 
					  ,CASE WHEN stbd.StockLineId > 0 THEN UPPER(SMSD.Level9Name) ELSE UPPER(EMSD.Level9Name) END AS level9 
					  ,CASE WHEN stbd.StockLineId > 0 THEN UPPER(SMSD.Level10Name) ELSE UPPER(EMSD.Level10Name) END AS level10 
				 FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
					 INNER JOIN [dbo].[DistributionSetup] DS WITH(NOLOCK) ON JBD.DistributionSetupId=DS.ID  
					 INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId  
					 INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId  
					 LEFT JOIN [dbo].[BulkStocklineAdjPaymentBatchDetails] stbd WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId = stbd.CommonJournalBatchDetailId 
					 JOIN [dbo].[BulkStockLineAdjustmentDetails] BSAD WITH(NOLOCK) ON BSAD.BulkStkLineAdjId = stbd.ReferenceId
					 LEFT JOIN [dbo].[Stockline] STKL WITH(NOLOCK) ON STKL.StockLineId = stbd.StockLineId  	 	 
					 LEFT JOIN [dbo].[StocklineManagementStructureDetails] SMSD WITH (NOLOCK) ON SMSD.ModuleID = @blkSTKModuleID AND SMSD.ReferenceID = stbd.StockLineId 
					 LEFT JOIN [dbo].[EmployeeManagementStructureDetails] EMSD WITH (NOLOCK) ON EMSD.ReferenceID = stbd.EmployeeId AND EMSD.EntityMSID = stbd.ManagementStructureId AND EMSD.ModuleID = @ManagementStructureModuleId
					 LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId   
					 LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GL.GLAccountTypeId 
					 LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] ESP WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = ESP.[ReferenceId] AND JBD.[ManagementStructureId] = ESP.[EntityMSID]
					 LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID  
					 LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId  
					 LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id
		WHERE BSAD.BulkStkLineAdjId =@ReferenceId 
  END    
  END TRY    
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetBulkStockLineAccountingDetailsViewById'     
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
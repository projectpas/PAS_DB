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
	2    12-03-2024		AMIT GHEDIYA		Update join for mngmt get.

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
				DECLARE @JournalBatchDetailId BIGINT = 0;

				SELECT TOP 1 @JournalBatchDetailId = JournalBatchDetailId FROM [dbo].[BulkStocklineAdjPaymentBatchDetails] WITH(NOLOCK) WHERE ReferenceId = @ReferenceId;
				
				--PRINT 'SADJ-QTY'

				SELECT @ManagementStructureModuleId = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName='EmployeeGeneralInfo';
  
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
					  ,ESS.Level1Id,UPPER(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description]) AS Level1,
					ESS.Level2Id,UPPER(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description]) AS Level2,
					ESS.Level3Id,UPPER(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description]) AS Level3,
					ESS.Level4Id,UPPER(CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description]) AS Level4,
					ESS.Level5Id,UPPER(CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description]) AS Level5,
					ESS.Level6Id,UPPER(CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description]) AS Level6,
					ESS.Level7Id,UPPER(CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description]) AS Level7,
					ESS.Level8Id,UPPER(CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description]) AS Level8,
					ESS.Level9Id,UPPER(CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description]) AS Level9,
					ESS.Level10Id,UPPER(CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description]) AS Level10
				 FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
					 INNER JOIN [dbo].[DistributionSetup] DS WITH(NOLOCK) ON JBD.DistributionSetupId=DS.ID  
					 INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId  
					 INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId  
					 LEFT JOIN [dbo].[BulkStocklineAdjPaymentBatchDetails] stbd WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId = stbd.CommonJournalBatchDetailId 
					 LEFT JOIN [dbo].[Stockline] STKL WITH(NOLOCK) ON STKL.StockLineId = stbd.StockLineId  	 	 
					 LEFT JOIN [dbo].[EntityStructureSetup] ESS WITH (NOLOCK) ON stbd.ManagementStructureId = ESS.[EntityStructureId]
					 LEFT JOIN dbo.ManagementStructureLevel MSL1 WITH (NOLOCK) ON ESS.Level1Id = MSL1.ID
					 LEFT JOIN dbo.ManagementStructureLevel MSL2 WITH (NOLOCK) ON ESS.Level2Id = MSL2.ID
					 LEFT JOIN dbo.ManagementStructureLevel MSL3 WITH (NOLOCK) ON ESS.Level3Id = MSL3.ID
					 LEFT JOIN dbo.ManagementStructureLevel MSL4 WITH (NOLOCK) ON ESS.Level4Id = MSL4.ID
					 LEFT JOIN dbo.ManagementStructureLevel MSL5 WITH (NOLOCK) ON ESS.Level5Id = MSL5.ID
					 LEFT JOIN dbo.ManagementStructureLevel MSL6 WITH (NOLOCK) ON ESS.Level6Id = MSL6.ID
					 LEFT JOIN dbo.ManagementStructureLevel MSL7 WITH (NOLOCK) ON ESS.Level7Id = MSL7.ID
					 LEFT JOIN dbo.ManagementStructureLevel MSL8 WITH (NOLOCK) ON ESS.Level8Id = MSL8.ID
					 LEFT JOIN dbo.ManagementStructureLevel MSL9 WITH (NOLOCK) ON ESS.Level9Id = MSL9.ID
					 LEFT JOIN dbo.ManagementStructureLevel MSL10 WITH (NOLOCK) ON ESS.Level10Id = MSL10.ID
					 LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId   
					 LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GL.GLAccountTypeId 
					 LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] ESP WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = ESP.[ReferenceId] AND JBD.[ManagementStructureId] = ESP.[EntityMSID]
					 LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.Level1Id = msl.ID  
					 LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId  
					 LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id
				 WHERE JBD.JournalBatchDetailId = @JournalBatchDetailId AND JBD.IsDeleted = 0  
				 ORDER BY DS.DisplayNumber ASC;
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
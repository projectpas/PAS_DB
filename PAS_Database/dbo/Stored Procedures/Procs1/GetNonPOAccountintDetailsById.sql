/*************************************************************             
 ** File:   [GetNonPOAccountintDetailsById]             
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used GetNonPOAccountintDetailsById  
 ** Purpose:           
 ** Date:   08/10/2022        
            
 ** PARAMETERS: @JournalBatchHeaderId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------		--------------------------------            
 1    10/10/2022  Devendra Shekh		 Created  
 2    11/10/2022  Devendra Shekh		 added vendorname  
 3    30/10/2022  Devendra Shekh		 changes for curreny and managementstructure  
 4    31/10/2023  Bhargav Saliya		Export Data Convert In To Upper Case 
 5    01/11/2023  Devendra Shekh		added referenceName

  exec [GetNonPOAccountintDetailsById] 1
************************************************************************/  
CREATE   PROCEDURE [dbo].[GetNonPOAccountintDetailsById]  
	@NonPOInvoiceId BIGINT
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
  BEGIN
	
	DECLARE @NPOModuleId BIGINT = 0, @CurrencyId BIGINT = 0, @DocNum VARCHAR(250) = '';
	SELECT @NPOModuleId = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName ='NonPOInvoiceHeader';
	SELECT @CurrencyId = CurrencyId, @DocNum = ISNULL(InvoiceNumber, '') FROM [dbo].[NonPOInvoiceHeader] WITH(NOLOCK) WHERE NonPOInvoiceId = @NonPOInvoiceId;

	SELECT JBD.CommonJournalBatchDetailId
	      ,JBD.[JournalBatchDetailId]  
          ,JBH.[JournalBatchHeaderId]  
          ,JBH.[BatchName]  
          ,JBD.[LineNumber]  
          ,JBD.[GlAccountId]  
          ,JBD.[GlAccountNumber]  
          ,UPPER(JBD.[GlAccountName]) AS [GlAccountName]  
		  ,GLC.[GLAccountClassName]
          ,JBD.[TransactionDate]  
          ,JBD.[EntryDate]  
		  ,NPD.[NonPOInvoiceId] AS 'ReferenceId'
          ,JBD.[JournalTypeId]  
          ,UPPER(JBD.[JournalTypeName]) AS [JournalTypeName]  
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
		  ,BD.[JournalTypeNumber]  
          ,BD.[CurrentNumber] 
          ,le.CompanyName AS LegalEntityName  
		  ,BS.Name AS 'Status'
		  ,UPPER(@DocNum) AS 'ReferenceName'
		  ,UPPER(NPD.[VendorName]) AS [VendorName]
		  ,UPPER(CU.[Code]) AS 'Currency'
          ,UPPER(NPOMSD.Level1Name) AS level1    
	      ,UPPER(NPOMSD.Level2Name) AS level2   
		  ,UPPER(NPOMSD.Level3Name) AS level3   
		  ,UPPER(NPOMSD.Level4Name) AS level4   
		  ,UPPER(NPOMSD.Level5Name) AS level5   
		  ,UPPER(NPOMSD.Level6Name) AS level6   
		  ,UPPER(NPOMSD.Level7Name) AS level7   
		  ,UPPER(NPOMSD.Level8Name) AS level8   
		  ,UPPER(NPOMSD.Level9Name) AS level9   
		  ,UPPER(NPOMSD.Level10Name) AS level10   
		 
     FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
		INNER JOIN [dbo].[DistributionSetup] DS WITH(NOLOCK) ON JBD.DistributionSetupId=DS.ID  
		INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId=BD.JournalBatchDetailId  
		INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId=JBH.JournalBatchHeaderId  
		LEFT JOIN [dbo].[NonPOInvoiceBatchDetails] NPD WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId = NPD.CommonJournalBatchDetailId  
		LEFT JOIN [dbo].[NonPOInvoiceManagementStructureDetails] NPOMSD WITH (NOLOCK) ON NPOMSD.[ModuleID] = @NPOModuleId AND  NPOMSD.[ReferenceID] = NPD.[NonPOInvoiceId]
		LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=JBD.GLAccountId   
		LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GL.GLAccountTypeId 
      --LEFT JOIN [dbo].[EntityStructureSetup] ESP WITH(NOLOCK) ON JBD.ManagementStructureId = ESP.EntityStructureId  
		LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] AMS WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = AMS.[ReferenceId] AND JBD.[ManagementStructureId] = JBD.ManagementStructureId
		LEFT JOIN [dbo].[ManagementStructureLevel] msl1 WITH(NOLOCK) ON AMS.Level1Id = msl1.ID
		--LEFT JOIN [dbo].[ManagementStructureLevel] msl2 WITH(NOLOCK) ON AMS.Level2Id = msl2.ID 
		--LEFT JOIN [dbo].[ManagementStructureLevel] msl3 WITH(NOLOCK) ON AMS.Level3Id = msl3.ID 
		--LEFT JOIN [dbo].[ManagementStructureLevel] msl4 WITH(NOLOCK) ON AMS.Level4Id = msl4.ID 
		--LEFT JOIN [dbo].[ManagementStructureLevel] msl5 WITH(NOLOCK) ON AMS.Level5Id = msl5.ID 
		--LEFT JOIN [dbo].[ManagementStructureLevel] msl6 WITH(NOLOCK) ON AMS.Level6Id = msl6.ID 
		--LEFT JOIN [dbo].[ManagementStructureLevel] msl7 WITH(NOLOCK) ON AMS.Level7Id = msl7.ID 
		--LEFT JOIN [dbo].[ManagementStructureLevel] msl8 WITH(NOLOCK) ON AMS.Level8Id = msl8.ID 
		--LEFT JOIN [dbo].[ManagementStructureLevel] msl9 WITH(NOLOCK) ON AMS.Level9Id = msl9.ID 
		--LEFT JOIN [dbo].[ManagementStructureLevel] msl10 WITH(NOLOCK) ON AMS.Level10Id = msl10.ID 
		LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl1.LegalEntityId = le.LegalEntityId 
		LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id
		LEFT JOIN [dbo].[Currency] CU WITH(NOLOCK) ON CU.CurrencyId = @CurrencyId
		WHERE NPD.NonPOInvoiceId = @NonPOInvoiceId and JBD.IsDeleted = 0  
		ORDER BY DS.DisplayNumber ASC;  
	END

    END TRY  
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'GetNonPOAccountintDetailsById'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@NonPOInvoiceId, '') + ''  
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
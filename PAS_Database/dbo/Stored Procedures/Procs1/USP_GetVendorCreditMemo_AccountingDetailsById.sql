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
	7    25/07/2024     Sahdev Saliya          Set JournalTypeNumber Order by desc
	8    08/01/2024		Devendra Shekh		   Added @ModuleId to param and where
    9    07/07/2026		Nakul Chandigra 	   Optimized the query by using a temp table to prevent timeout issues.

-- exec USP_GetVendorCreditMemo_AccountingDetailsById 127, 80
************************/   
CREATE   PROCEDURE [dbo].[USP_GetVendorCreditMemo_AccountingDetailsById]    
@ReferenceId bigint,
@ModuleId int
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY        
   BEGIN       

	DECLARE @AccountMSModuleId INT = 0
	SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';
	DECLARE @VendorCMIds VARCHAR(50) = '';

	--SELECt @VendorCMIds = STUFF(
	--	 (SELECT ',' + CAST(VendorCreditMemoId AS VARCHAR) FROM [dbo].[VendorCreditMemo] VCM
	--	  WHERE VCM.VendorRMAId = VRM.VendorRMAId FOR XML PATH ('')), 1, 1, '') 
	--	  FROM [dbo].[VendorRMA] VRM
	--	  WHERE VRM.VendorRMAId = @ReferenceId
	--	  GROUP BY vrm.VendorRMAId


    IF OBJECT_ID('tempdb..#MSDResolved') IS NOT NULL DROP TABLE #MSDResolved;

    SELECT 
        MSD.ReferenceId,
        MSD.EntityMSID,
        MSD.ModuleId,
        CASE WHEN MSL1.ID IS NULL THEN NULL ELSE CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description] END AS level1,
        CASE WHEN MSL2.ID IS NULL THEN NULL ELSE CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description] END AS level2,
        CASE WHEN MSL3.ID IS NULL THEN NULL ELSE CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description] END AS level3,
        CASE WHEN MSL4.ID IS NULL THEN NULL ELSE CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description] END AS level4,
        CASE WHEN MSL5.ID IS NULL THEN NULL ELSE CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description] END AS level5,
        CASE WHEN MSL6.ID IS NULL THEN NULL ELSE CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description] END AS level6,
        CASE WHEN MSL7.ID IS NULL THEN NULL ELSE CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description] END AS level7,
        CASE WHEN MSL8.ID IS NULL THEN NULL ELSE CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description] END AS level8,
        CASE WHEN MSL9.ID IS NULL THEN NULL ELSE CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description] END AS level9,
        CASE WHEN MSL10.ID IS NULL THEN NULL ELSE CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description] END AS level10,
        MSL1.LegalEntityId
    INTO #MSDResolved
    FROM [dbo].[AccountingBatchManagementStructureDetails] MSD WITH (NOLOCK)
    LEFT JOIN [dbo].[ManagementStructureLevel] MSL1  WITH (NOLOCK) ON MSD.Level1Id  = MSL1.ID
    LEFT JOIN [dbo].[ManagementStructureLevel] MSL2  WITH (NOLOCK) ON MSD.Level2Id  = MSL2.ID
    LEFT JOIN [dbo].[ManagementStructureLevel] MSL3  WITH (NOLOCK) ON MSD.Level3Id  = MSL3.ID
    LEFT JOIN [dbo].[ManagementStructureLevel] MSL4  WITH (NOLOCK) ON MSD.Level4Id  = MSL4.ID
    LEFT JOIN [dbo].[ManagementStructureLevel] MSL5  WITH (NOLOCK) ON MSD.Level5Id  = MSL5.ID
    LEFT JOIN [dbo].[ManagementStructureLevel] MSL6  WITH (NOLOCK) ON MSD.Level6Id  = MSL6.ID
    LEFT JOIN [dbo].[ManagementStructureLevel] MSL7  WITH (NOLOCK) ON MSD.Level7Id  = MSL7.ID
    LEFT JOIN [dbo].[ManagementStructureLevel] MSL8  WITH (NOLOCK) ON MSD.Level8Id  = MSL8.ID
    LEFT JOIN [dbo].[ManagementStructureLevel] MSL9  WITH (NOLOCK) ON MSD.Level9Id  = MSL9.ID
    LEFT JOIN [dbo].[ManagementStructureLevel] MSL10 WITH (NOLOCK) ON MSD.Level10Id = MSL10.ID
    WHERE MSD.ModuleId = @AccountMSModuleId;

        -- Step 2: Main query joins the temp table ONCE instead of 10 live joins
    SELECT  JBD.CommonJournalBatchDetailId  
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
            ,BD.AccountingPeriod AS 'AccountingPeriod'
            ,UPPER(BS.Name) AS 'Status'
            ,UPPER(CR.Code) AS Currency  
            ,'' AS [DocumentNumber] 
            ,0 AS [CustomerId],'' AS [CustomerName],0 AS [InvoiceId],'' AS [InvoiceName],'' AS [ARControlNumber],'' AS [CustomerRef]
            ,MSDR.level1
            ,MSDR.level2
            ,MSDR.level3
            ,MSDR.level4
            ,MSDR.level5
            ,MSDR.level6
            ,MSDR.level7
            ,MSDR.level8
            ,MSDR.level9
            ,MSDR.level10
            ,CASE WHEN JBD.IsUpdated = 1 THEN 1 ELSE 0 END AS IsUpdated
    FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
        INNER JOIN [dbo].[DistributionSetup] DS WITH(NOLOCK) ON JBD.DistributionSetupId = DS.ID  
        INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON JBD.JournalBatchDetailId = BD.JournalBatchDetailId  
        INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BD.JournalBatchHeaderId = JBH.JournalBatchHeaderId  
        LEFT JOIN [dbo].[VendorRMAPaymentBatchDetails] VPBD WITH(NOLOCK) ON JBD.CommonJournalBatchDetailId = VPBD.CommonJournalBatchDetailId  
        LEFT JOIN [dbo].[Vendor] VDR WITH(NOLOCK) ON VDR.VendorId = VPBD.VendorId  	
        LEFT JOIN [dbo].[GLAccount] GLA WITH(NOLOCK) ON GLA.[GLAccountId] = JBD.[GLAccountId]  
        LEFT JOIN #MSDResolved MSDR ON JBD.[CommonJournalBatchDetailId] = MSDR.[ReferenceId] 
            AND JBD.[ManagementStructureId] = MSDR.[EntityMSID]
        LEFT JOIN [dbo].[LegalEntity] LET WITH(NOLOCK) ON MSDR.LegalEntityId = LET.LegalEntityId  
        LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id
        LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = VDR.CurrencyId  
    WHERE VPBD.ReferenceID = @ReferenceId AND ISNULL(VPBD.ModuleId, 0) = @ModuleId
    ORDER BY BD.JournalTypeNumber DESC;

    DROP TABLE #MSDResolved;

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
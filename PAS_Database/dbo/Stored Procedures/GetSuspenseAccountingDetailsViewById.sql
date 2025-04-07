/*************************************************************             
 ** File:   [GetPOAccountingDetailsViewById]             
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used Get Suspense Batch Details List
 ** Purpose:           
 ** Date:   19/07/2024
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author				Change Description              
 ** --   --------		 -------			--------------------------------            
    1    19/07/2024		Moin Bloch			Created  
	2    31/03/2025		Divyesh Kathiriya	Update TransactionDate and EntryDate based on Employee time zone

	EXEC [dbo].[GetSuspenseAccountingDetailsViewById] 11,226
************************************************************************/   
CREATE   PROCEDURE [dbo].[GetSuspenseAccountingDetailsViewById]    
@ReferenceId BIGINT,
@EmployeeId BIGINT
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY        
   BEGIN       
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
		SELECT 
			@CurrntEmpTimeZoneDesc = COALESCE(
				ETZ.[Description],  -- Prefer Employee's TimeZone description if available
				LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
			)
		FROM 
			dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN 
			dbo.TimeZone ETZ WITH (NOLOCK) 
			ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN 
			dbo.LegalEntity LE WITH (NOLOCK) 
			ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN 
			dbo.TimeZone LTZ WITH (NOLOCK) 
			ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE 
			E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

		DECLARE @SuspenseMSModuleId BIGINT;
		SELECT @SuspenseMSModuleId = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName ='SuspenseAndUnAppliedPayment';
				
		SELECT JBD.[LineNumber]  
			  ,JBH.[BatchName]  
			  ,BTD.[JournalTypeNumber]  
			  ,JBD.[JournalTypeName]  
			  ,JBD.[GlAccountNumber] 
			  ,JBD.[GlAccountName] 
			  ,ISNULL(JBD.[DebitAmount],0) [DebitAmount] 
			  ,ISNULL(JBD.[CreditAmount],0) [CreditAmount]  			 
			  --,JBD.[TransactionDate]  
			  --,JBD.[EntryDate]
			  ,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					CASE WHEN CAST(JBD.[TransactionDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(JBD.[TransactionDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			   ELSE (CAST(JBD.[TransactionDate] AS DATETIME)) END TransactionDate
			   ,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					CASE WHEN CAST(JBD.[EntryDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(JBD.[EntryDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			   ELSE (CAST(JBD.[EntryDate] AS DATETIME)) END EntryDate
			  ,ISNULL(SUPBD.CustomerName, '') as CustomerName			  
			  ,UPPER(MSD.Level1Name) AS level1 
			  ,UPPER(MSD.Level2Name) AS level2
			  ,UPPER(MSD.Level3Name) AS level3
			  ,UPPER(MSD.Level4Name) AS level4
			  ,UPPER(MSD.Level5Name) AS level5
			  ,UPPER(MSD.Level6Name) AS level6
			  ,UPPER(MSD.Level7Name) AS level7
			  ,UPPER(MSD.Level8Name) AS level8
			  ,UPPER(MSD.Level9Name) AS level9
			  ,UPPER(MSD.Level10Name) AS level10	
			  ,CASE WHEN JBD.[IsUpdated] = 1 THEN 1 ELSE 0 END AS IsUpdated
		 FROM [dbo].[CommonBatchDetails] JBD WITH(NOLOCK)  
			  INNER JOIN [dbo].[BatchDetails] BTD WITH(NOLOCK) ON JBD.[JournalBatchDetailId] = BTD.[JournalBatchDetailId]    
			  INNER JOIN [dbo].[BatchHeader] JBH WITH(NOLOCK) ON BTD.[JournalBatchHeaderId] = JBH.[JournalBatchHeaderId]       
			  LEFT JOIN [dbo].[SuspenseAndUnAppliedPaymentBatchDetails] SUPBD WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = SUPBD.[CommonJournalBatchDetailId] 
			  LEFT JOIN [dbo].[SuspenseAndUnAppliedPaymentMSDetails] MSD WITH (NOLOCK) ON MSD.[ModuleID] = @SuspenseMSModuleId AND SUPBD.[ReferenceId] = MSD.[ReferenceID]
			  LEFT JOIN [dbo].[GLAccount] GLA WITH(NOLOCK) ON GLA.[GLAccountId] = JBD.[GLAccountId]  
			  LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId=GLA.GLAccountTypeId 
			  LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] ESP WITH(NOLOCK) ON JBD.[CommonJournalBatchDetailId] = ESP.[ReferenceId] AND JBD.[ManagementStructureId] = ESP.[EntityMSID]
			  LEFT JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ESP.[Level1Id] = msl.[ID]  
			  LEFT JOIN [dbo].[LegalEntity] LET WITH(NOLOCK) ON msl.[LegalEntityId] = LET.[LegalEntityId] 
			  LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BTD.StatusId = BS.Id
		WHERE SUPBD.ReferenceId = @ReferenceId AND JBD.[IsDeleted] = 0;     
  END    
  END TRY    
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetSuspenseAccountingDetailsViewById'                 
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReferenceId, '') AS VARCHAR(100))  
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
-- =============================================
-- Author:		<AMIT GHEDIYA>
-- Create date: <04-10-2024>
-- Description:	<This stored procedure is used Get AccountingDetailsById for Stockline Batch>

/*********************   
 ** RETURN VALUE:             
 **********************             
 ** Change History             
 **********************             
 ** PR   Date			 Author				Change Description              
 ** --   --------		 -------			--------------------------------            
    1    04-10-2024		AMIT GHEDIYA		Created
	2    13/02/2025   Ayushi Patel      converted the date into utc (TransactionDate , EntryDate) , Added a case to get timeZone
************************/ 
--[dbo].[GetStocklineBatchAccountingDetailsById] 181156
-- =============================================
CREATE    PROCEDURE [dbo].[GetStocklineBatchAccountingDetailsById]
@ReferenceId BIGINT ,
@EmployeeId bigint
AS
BEGIN	
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY        
   BEGIN       

	DECLARE @STKMSModuleId INT = 0
	SELECT @STKMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';
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


	SELECT CBD.CommonJournalBatchDetailId
			,CBD.[JournalBatchDetailId] 
			,CBD.[LineNumber]  
			,CBD.[GlAccountId]  
			,CBD.[GlAccountNumber]  
			,UPPER(CBD.[GlAccountName]) AS [GlAccountName] 
			--,CBD.[TransactionDate]  
			--,CBD.[EntryDate]
			,case when CAST(CBD.[TransactionDate] as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(CBD.[TransactionDate], @CurrntEmpTimeZoneDesc) as Date))end TransactionDate
			,case when CAST(CBD.[EntryDate] as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(CBD.[EntryDate], @CurrntEmpTimeZoneDesc) as Date))end EntryDate
			,CBD.[JournalTypeId]  
            ,(UPPER(CBD.[JournalTypeName]) +' - '+ UPPER(CBD.JournalTypeNumber)) as JournalTypeName
			,UPPER(CBD.JournalTypeNumber) as JournalNumber
            ,CBD.[IsDebit]  
            ,CBD.[DebitAmount]  
            ,CBD.[CreditAmount]
			,CBD.[ManagementStructureId]  
            ,CBD.[ModuleName]  
            ,CBD.[MasterCompanyId]  
            ,CBD.[CreatedBy]  
            ,CBD.[UpdatedBy]  
            ,CBD.[CreatedDate]  
            ,CBD.[UpdatedDate]  
            ,CBD.[IsActive]  
            ,CBD.[IsDeleted]
			,CBD.LastMSLevel  
            ,CBD.AllMSlevels  
            ,CBD.IsManualEntry  
            ,CBD.DistributionSetupId  
            ,CBD.DistributionName
			,BH.[JournalBatchHeaderId]  
            ,BH.[BatchName]    			
		    ,SBD.CommonJournalBatchDetailId
            ,SBD.ReferenceId AS [ReferenceId]  
            ,GL.AllowManualJE              
            ,LE.CompanyName AS LegalEntityName  
            ,BD.JournalTypeNumber
			,BD.CurrentNumber  
			,BD.AccountingPeriod AS 'AccountingPeriod'
		    ,BS.[Name] AS 'Status'
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
   FROM DBO.Stockline STK WITH(NOLOCK) 				
		INNER JOIN DBO.StocklineBatchDetails  SBD WITH(NOLOCK) ON  STK.StockLineId = SBD.StocklineId 	
		INNER JOIN DBO.CommonBatchDetails  CBD WITH(NOLOCK) ON  SBD.CommonJournalBatchDetailId = CBD.CommonJournalBatchDetailId 	
		INNER JOIN dbo.BatchDetails BD WITH(NOLOCK) ON CBD.JournalBatchDetailId = BD.JournalBatchDetailId
		INNER JOIN dbo.BatchHeader BH WITH(NOLOCK) ON BD.JournalBatchHeaderId = BH.JournalBatchHeaderId
		LEFT JOIN dbo.GLAccount GL WITH(NOLOCK) ON GL.GLAccountId=CBD.GLAccountId
		LEFT JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH(NOLOCK) ON CBD.CommonJournalBatchDetailId = MSD.ReferenceId AND 
					CBD.ManagementStructureId = MSD.EntityMSID AND MSD.ModuleId = @STKMSModuleId
		LEFT JOIN dbo.BatchStatus BS WITH(NOLOCK) ON BD.StatusId = BS.Id  
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
		LEFT JOIN dbo.LegalEntity le WITH(NOLOCK) ON MSL1.LegalEntityId = le.LegalEntityId		
     WHERE SBD.StocklineId = @ReferenceId     
	 order by BD.JournalTypeNumber desc
  END    
  END TRY    
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetStocklineBatchAccountingDetailsById'     
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
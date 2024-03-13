-- =============================================
-- Author:		<Abhishek Jirawla>
-- Create date: <01-03-2024>
-- Description:	<This stored procedure is used Get JournalBatchDetailsById for Manual Journal Batch>

/*************************************************************   
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author				Change Description              
 ** --   --------		 -------			--------------------------------            
    1    01-03-2024		Abhishek Jirawla		Created
	2    13-03-2024     Abhishek Jirawla		Modified
************************************************************************/ 
--[dbo].[GetManualJournalBatchAccountingDetailsById] 328
-- =============================================
CREATE PROCEDURE [dbo].[GetManualJournalBatchAccountingDetailsById]
@ReferenceId bigint 
AS
BEGIN	
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY        
   BEGIN       

	DECLARE @POMSModuleId INT = 0
	SELECT @POMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='ManualJournalAccounting';
	--DECLARE @CPModuleID INT=59;

SELECT CBD.CommonJournalBatchDetailId
			,CBD.[JournalBatchDetailId] 
			,CBD.[LineNumber]  
			,CBD.[GlAccountId]  
			,CBD.[GlAccountNumber]  
			,UPPER(CBD.[GlAccountName]) AS [GlAccountName] 
			,CBD.[TransactionDate]  
			,CBD.[EntryDate] 
			,CBD.[JournalTypeId]  
            ,(UPPER(CBD.[JournalTypeName]) +' - '+ UPPER(MJH.JournalNumber)) as JournalTypeName  
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
		    ,MJPBD.ManualJournalPaymentBatchDetilsId
            ,MJPBD.ReferenceId AS [ReferenceId]  
            ,MJPBD.ReferenceDetailId AS [ReferenceNumber]
            ,GL.AllowManualJE              
            ,LE.CompanyName AS LegalEntityName  
            ,BD.JournalTypeNumber
			,BD.CurrentNumber  
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
   FROM DBO.ManualJournalHeader MJH WITH(NOLOCK) 				
		INNER JOIN DBO.CommonBatchDetails  CBD WITH(NOLOCK) ON  MJH.ManualJournalHeaderId = CBD.ReferenceId 	
		INNER JOIN DBO.ManualJournalPaymentBatchDetails MJPBD WITH(NOLOCK) ON MJPBD.CommonJournalBatchDetailId = CBD.CommonJournalBatchDetailId
		INNER JOIN dbo.BatchDetails BD WITH(NOLOCK) ON CBD.JournalBatchDetailId = BD.JournalBatchDetailId
		INNER JOIN dbo.BatchHeader BH WITH(NOLOCK) ON BD.JournalBatchHeaderId = BH.JournalBatchHeaderId
		LEFT JOIN dbo.GLAccount GL WITH(NOLOCK) ON GL.GLAccountId=CBD.GLAccountId
		LEFT JOIN dbo.AccountingBatchManagementStructureDetails MSD WITH(NOLOCK) ON CBD.CommonJournalBatchDetailId = MSD.ReferenceId AND 
					CBD.ManagementStructureId = MSD.EntityMSID AND MSD.ModuleId = @POMSModuleId
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
     WHERE MJH.ManualJournalHeaderId = @ReferenceId     
  END    
  END TRY    
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetManualJournalBatchAccountingDetailsById'     
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
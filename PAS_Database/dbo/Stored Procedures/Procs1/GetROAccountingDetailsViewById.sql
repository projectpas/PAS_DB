﻿/*******             
 ** File:   [GetROAccountingDetailsViewById]             
 ** Author:  Ayesha Sultana
 ** Description: This stored procedure is used Get JournalBatchDetailsById for RO List
 ** Purpose:           
 ** Date:   20/09/2023    
           
 ** RETURN VALUE:             
 ********             
 ** Change History             
 ********             
 ** PR   Date			 Author				Change Description              
 ** --   --------		 -------			--------------------------------            
    1    20-9-2023		Ayesha Sultana		Created  
	2    20/10/2023     Bhargav Saliya      Export Data Convert Into Upper Case
	3    27/11/2023     Moin Bloch          Added LotNumber
	4    10/05/2023     Moin Bloch          Added IsUpdated
	5    16/07/2024     Sahdev Saliya       Added (AccountingPeriod)
	6    23/07/2024     Sahdev Saliya       Set JournalTypeNumber Order by desc

********/   
CREATE   PROCEDURE [dbo].[GetROAccountingDetailsViewById]    
@ReferenceId bigint    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY        
   BEGIN       

	DECLARE @ROMSModuleId INT = 0
	SELECT @ROMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';

     SELECT CBD.CommonJournalBatchDetailId
			,CBD.[JournalBatchDetailId] 
			,CBD.[LineNumber]  
			,CBD.[GlAccountId]  
			,CBD.[GlAccountNumber]  
			,UPPER(CBD.[GlAccountName]) AS [GlAccountName]  
			,CBD.[TransactionDate]  
			,CBD.[EntryDate] 
			,CBD.[JournalTypeId]  
            ,(UPPER(CBD.[JournalTypeName]) +' - '+ UPPER(SLBD.RONum)) as JournalTypeName  
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
            ,UPPER(BH.[BatchName]) AS [BatchName]             
		    ,SLBD.StocklineBatchDetailId
            ,SLBD.RoId AS [ReferenceId]  
            ,SLBD.RONum AS [ReferenceNumber]  
            ,SLBD.StocklineId   
            ,SLBD.StocklineNumber 
            ,SLBD.PartId 		  
            ,SLBD.PartNumber  
            ,SLBD.VendorName  
            ,SLBD.VendorId 
            ,SLBD.ItemMasterId   
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
			,CBD.[LotNumber]
			,CASE WHEN CBD.IsUpdated = 1 THEN 1 ELSE 0 END AS IsUpdated
   FROM [dbo].[CommonBatchDetails] CBD WITH(NOLOCK)  
		INNER JOIN [dbo].[BatchDetails] BD WITH(NOLOCK) ON CBD.JournalBatchDetailId = BD.JournalBatchDetailId  		
		INNER JOIN [dbo].[BatchHeader] BH WITH(NOLOCK) ON BD.JournalBatchHeaderId = BH.JournalBatchHeaderId
		 LEFT JOIN [dbo].[StocklineBatchDetails] SLBD WITH(NOLOCK) ON CBD.CommonJournalBatchDetailId = SLBD.CommonJournalBatchDetailId  
		 LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId=CBD.GLAccountId
		 LEFT JOIN [dbo].[AccountingBatchManagementStructureDetails] MSD WITH(NOLOCK) ON CBD.CommonJournalBatchDetailId = MSD.ReferenceId AND CBD.ManagementStructureId = MSD.EntityMSID AND MSD.ModuleId = @ROMSModuleId
		 LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON BD.StatusId = BS.Id  
		 LEFT JOIN [dbo].[ManagementStructureLevel] MSL1 WITH (NOLOCK) ON MSD.Level1Id = MSL1.ID
		 LEFT JOIN [dbo].[ManagementStructureLevel] MSL2 WITH (NOLOCK) ON MSD.Level2Id = MSL2.ID
		 LEFT JOIN [dbo].[ManagementStructureLevel] MSL3 WITH (NOLOCK) ON MSD.Level3Id = MSL3.ID
		 LEFT JOIN [dbo].[ManagementStructureLevel] MSL4 WITH (NOLOCK) ON MSD.Level4Id = MSL4.ID
		 LEFT JOIN [dbo].[ManagementStructureLevel] MSL5 WITH (NOLOCK) ON MSD.Level5Id = MSL5.ID
		 LEFT JOIN [dbo].[ManagementStructureLevel] MSL6 WITH (NOLOCK) ON MSD.Level6Id = MSL6.ID
		 LEFT JOIN [dbo].[ManagementStructureLevel] MSL7 WITH (NOLOCK) ON MSD.Level7Id = MSL7.ID
		 LEFT JOIN [dbo].[ManagementStructureLevel] MSL8 WITH (NOLOCK) ON MSD.Level8Id = MSL8.ID
		 LEFT JOIN [dbo].[ManagementStructureLevel] MSL9 WITH (NOLOCK) ON MSD.Level9Id = MSL9.ID
		 LEFT JOIN [dbo].[ManagementStructureLevel] MSL10 WITH (NOLOCK) ON MSD.Level10Id = MSL10.ID
		 LEFT JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON MSL1.LegalEntityId = le.LegalEntityId  
     WHERE SLBD.RoId = @ReferenceId
	 order by BD.JournalTypeNumber desc
  END    
  END TRY    
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetROAccountingDetailsViewById'     
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
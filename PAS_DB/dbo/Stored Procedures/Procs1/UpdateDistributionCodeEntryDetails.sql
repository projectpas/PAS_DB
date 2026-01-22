
/*************************************************************           
 ** File:   [UpdateDistributionCodeEntryDetails]           
 ** Author:   Subhash Saliya
 ** Description: Get Customer DistributionCodeEntryDetails
 ** Purpose:         
 ** Date:   07/28/2022        
          
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/28/2022   Subhash Saliya Created
	
 -- exec [UpdateDistributionCodeEntryDetails] 1    
**************************************************************/ 

Create   PROCEDURE [dbo].[UpdateDistributionCodeEntryDetails]
@DistributionId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY
	BEGIN TRAN
	 
		UPDATE DC SET		
		DC.JournalTypeName = JT.JournalTypeName,
		DC.GLAccountName = ISNULL(GL.AccountCode,'') + '-' + ISNULL(GL.AccountName,''),
		[Level1Name] = CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + CAST(MSL1.[Description] AS VARCHAR(MAX)),
		[Level2Name] = CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + CAST(MSL2.[Description] AS VARCHAR(MAX)),
		[Level3Name] = CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + CAST(MSL3.[Description] AS VARCHAR(MAX)),
		[Level4Name] = CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + CAST(MSL4.[Description] AS VARCHAR(MAX)),
		[Level5Name] = CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + CAST(MSL5.[Description] AS VARCHAR(MAX)),
		[Level6Name] = CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + CAST(MSL6.[Description] AS VARCHAR(MAX)),
		[Level7Name] = CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + CAST(MSL7.[Description] AS VARCHAR(MAX)),
		[Level8Name] = CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + CAST(MSL8.[Description] AS VARCHAR(MAX)),
		[Level9Name] = CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + CAST(MSL9.[Description] AS VARCHAR(MAX)),
		[Level10Name] = CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + CAST(MSL10.[Description] AS VARCHAR(MAX))

		FROM dbo.DistributionCodeEntry DC WITH (NOLOCK)		
		LEFT JOIN dbo.GLAccount GL WITH (NOLOCK) on DC.GLAccountId = GL.GLAccountId
		LEFT JOIN dbo.JournalType JT WITH (NOLOCK) on JT.ID =  DC.JournalTypeID
		LEFT JOIN ManagementStructureLevel MSL1 WITH (NOLOCK) ON  DC.Level1Id = MSL1.ID
		LEFT JOIN ManagementStructureLevel MSL2 WITH (NOLOCK) ON  DC.Level2Id = MSL2.ID
		LEFT JOIN ManagementStructureLevel MSL3 WITH (NOLOCK) ON  DC.Level3Id = MSL3.ID
		LEFT JOIN ManagementStructureLevel MSL4 WITH (NOLOCK) ON  DC.Level4Id = MSL4.ID
		LEFT JOIN ManagementStructureLevel MSL5 WITH (NOLOCK) ON  DC.Level5Id = MSL5.ID
		LEFT JOIN ManagementStructureLevel MSL6 WITH (NOLOCK) ON  DC.Level6Id = MSL6.ID
		LEFT JOIN ManagementStructureLevel MSL7 WITH (NOLOCK) ON  DC.Level7Id = MSL7.ID
		LEFT JOIN ManagementStructureLevel MSL8 WITH (NOLOCK) ON  DC.Level8Id = MSL8.ID
		LEFT JOIN ManagementStructureLevel MSL9 WITH (NOLOCK) ON  DC.Level9Id = MSL9.ID
		LEFT JOIN ManagementStructureLevel MSL10 WITH (NOLOCK) ON DC.Level10Id = MSL10.ID	
		WHERE DC.DistributionId = @DistributionId 

	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateDistributionCodeEntryDetails' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@DistributionId, '') + ''
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
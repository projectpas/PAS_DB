
/*************************************************************           
 ** File:   [USP_GetMDDetailsById]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used to Mamagment Structure Details By ID.    
 ** Purpose:         
 ** Date:   02/17/2022        
          
 ** PARAMETERS:           
 @MSDetailsId BIGINT   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/17/2022   Hemant Saliya Created
     
-- EXEC [USP_GetMSDetailsById] 10003
**************************************************************/

CREATE PROCEDURE [dbo].[USP_GetMSDetailsById]
@MSDetailsId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				DECLARE @MasterCompanyId INT;
				DECLARE @MSLevel INT;
				DECLARE @LastMSName VARCHAR(200);
				DECLARE @Query VARCHAR(MAX);
				DECLARE @Level1 VARCHAR(50);
				DECLARE @Level2 VARCHAR(50);
				DECLARE @Level3 VARCHAR(50);
				DECLARE @Level4 VARCHAR(50);
				DECLARE @Level5 VARCHAR(50);
				DECLARE @Level6 VARCHAR(50);
				DECLARE @Level7 VARCHAR(50);
				DECLARE @Level8 VARCHAR(50);
				DECLARE @Level9 VARCHAR(50);
				DECLARE @Level10 VARCHAR(50);
				
				IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL
				BEGIN
				DROP TABLE #TempTable
				END

				CREATE TABLE #TempTable(LastMSName VARCHAR(MAX))  

				SELECT @MasterCompanyId = [MasterCompanyId]
				FROM [dbo].[ManagementStructureDetails] MSD WITH(NOLOCK) 
				WHERE MSD.MSDetailsId = @MSDetailsId

				SELECT @MSLevel = MC.ManagementStructureLevel
				FROM [dbo].[MasterCompany] MC WITH(NOLOCK) 
				WHERE MC.MasterCompanyId = @MasterCompanyId

				Select @Level1 = MST.[Description] FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 1
				Select @Level2 = MST.[Description] FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 2
				Select @Level3 = MST.[Description] FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 3
				Select @Level4 = MST.[Description] FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 4
				Select @Level5 = MST.[Description] FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 5
				Select @Level6 = MST.[Description] FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 6
				Select @Level7 = MST.[Description] FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 7
				Select @Level8 = MST.[Description] FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 8
				Select @Level9 = MST.[Description] FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 9
				Select @Level10 = MST.[Description] FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 10

				SET @Query = N'INSERT INTO #TempTable (LastMSName) SELECT DISTINCT TOP 1 CAST ( Level' + CAST( + @MSLevel AS VARCHAR(20)) + 'Name AS VARCHAR(MAX)) FROM [dbo].[ManagementStructureDetails] MSD WITH(NOLOCK) 
				WHERE MSD.MSDetailsId = CAST (' + CAST(@MSDetailsId AS VARCHAR(20)) + ' AS INT)'

				--PRINT @Query
				EXECUTE(@Query)  

				SELECT @LastMSName = LastMSName FROM #TempTable  

				SELECT 
					[MSDetailsId], [ModuleID], [ReferenceID], [EntityMSID], [Level1Id], [Level1Name], [Level2Id], [Level2Name], [Level3Id], [Level3Name], 
					[Level4Id], [Level4Name], [Level5Id], [Level5Name], [Level6Id], [Level6Name], [Level7Id], [Level7Name], [Level8Id], [Level8Name], 
					[Level9Id], [Level9Name], [Level10Id], [Level10Name], [MasterCompanyId], @LastMSName AS LastMSName,
					CASE	
						WHEN ISNULL([Level10Name], '') != '' THEN '<p> '+ @Level1 +' :   ' + ISNULL([Level1Name], '') + '</p><p> '+ @Level2 +' :   ' + ISNULL([Level2Name], '') + '</p><p> '+ @Level3 +' :   ' + ISNULL([Level3Name], '') + 
							'</p><p> '+ @Level4 +' :   ' + ISNULL([Level4Name], '') + '</p><p> '+ @Level5 +' :   ' + ISNULL([Level5Name], '') + '</p><p> '+ @Level6 +' :   ' 
							+ ISNULL([Level6Name], '') + '</p><p> '+ @Level7 +' :   ' + ISNULL([Level7Name], '') + '</p><p> '+ @Level8 +' :   ' + ISNULL([Level8Name], '') + 
							'</p><p> '+ @Level9 +' :   ' + ISNULL([Level9Name], '') + '</p><p> '+ @Level10 +' :   ' + ISNULL([Level10Name], '') + '</p>'

						WHEN ISNULL([Level9Name], '') != '' THEN '<p> '+ @Level1 +' :   ' + ISNULL([Level1Name], '') + '</p><p> '+ @Level2 +' :   ' + ISNULL([Level2Name], '') + '</p><p> '+ @Level3 +' :   ' + ISNULL([Level3Name], '') + 
							'</p><p> '+ @Level4 +' :   ' + ISNULL([Level4Name], '') + '</p><p> '+ @Level5 +' :   ' + ISNULL([Level5Name], '') + '</p><p> '+ @Level6 +' :   ' 
							+ ISNULL([Level6Name], '') + '</p><p> '+ @Level7 +' :   ' + ISNULL([Level7Name], '') + '</p><p> '+ @Level8 +' :   ' + ISNULL([Level8Name], '') + 
							'</p><p> '+ @Level9 +' :   ' + ISNULL([Level9Name], '') + '</p>'

						WHEN ISNULL([Level8Name], '') != '' THEN '<p> '+ @Level1 +' :   ' + ISNULL([Level1Name], '') + '</p><p> '+ @Level2 +' :   ' + ISNULL([Level2Name], '') + '</p><p> '+ @Level3 +' :   ' + ISNULL([Level3Name], '') + 
							'</p><p> '+ @Level4 +' :   ' + ISNULL([Level4Name], '') + '</p><p> '+ @Level5 +' :   ' + ISNULL([Level5Name], '') + '</p><p> '+ @Level6 +' :   ' 
							+ ISNULL([Level6Name], '') + '</p><p> '+ @Level7 +' :   ' + ISNULL([Level7Name], '') + '</p><p> '+ @Level8 +' :   ' + ISNULL([Level8Name], '') +  '</p>'

						WHEN ISNULL([Level7Name], '') != '' THEN '<p> '+ @Level1 +' :   ' + ISNULL([Level1Name], '') + '</p><p> '+ @Level2 +' :   ' + ISNULL([Level2Name], '') + '</p><p> '+ @Level3 +' :   ' + ISNULL([Level3Name], '') + 
							'</p><p> '+ @Level4 +' :   ' + ISNULL([Level4Name], '') + '</p><p> '+ @Level5 +' :   ' + ISNULL([Level5Name], '') + '</p><p> '+ @Level6 +' :   ' 
							+ ISNULL([Level6Name], '') + '</p><p> '+ @Level7 +' :   ' + ISNULL([Level7Name], '') + '</p>'

						WHEN ISNULL([Level6Name], '') != '' THEN '<p> '+ @Level1 +' :   ' + ISNULL([Level1Name], '') + '</p><p> '+ @Level2 +' :   ' + ISNULL([Level2Name], '') + '</p><p> '+ @Level3 +' :   ' + ISNULL([Level3Name], '') + 
							'</p><p> '+ @Level4 +' :   ' + ISNULL([Level4Name], '') + '</p><p> '+ @Level5 +' :   ' + ISNULL([Level5Name], '') + '</p><p> '+ @Level6 +' :   ' 
							+ ISNULL([Level6Name], '') + '</p>'

						WHEN ISNULL([Level5Name], '') != '' THEN '<p> '+ @Level1 +' :   ' + ISNULL([Level1Name], '') + '</p><p> '+ @Level2 +' :   ' + ISNULL([Level2Name], '') + '</p><p> '+ @Level3 +' :   ' + ISNULL([Level3Name], '') + 
							'</p><p> '+ @Level4 +' :   ' + ISNULL([Level4Name], '') + '</p><p> '+ @Level5 +' :   ' + ISNULL([Level5Name], '') + '</p>'

						WHEN ISNULL([Level4Name], '') != '' THEN '<p> '+ @Level1 +' :   ' + ISNULL([Level1Name], '') + '</p><p> '+ @Level2 +' :   ' + ISNULL([Level2Name], '') + '</p><p> '+ @Level3 +' :   ' + ISNULL([Level3Name], '') + 
							'</p><p> '+ @Level4 +' :   ' + ISNULL([Level4Name], '') + '</p>'

						WHEN ISNULL([Level3Name], '') != '' THEN '<p> '+ @Level1 +' :   ' + ISNULL([Level1Name], '') + '</p><p> '+ @Level2 +' :   ' + ISNULL([Level2Name], '') + '</p><p> '+ @Level3 +' :   ' + ISNULL([Level3Name], '') + '</p>'

						WHEN ISNULL([Level2Name], '') != '' THEN '<p> '+ @Level1 +' :   ' + ISNULL([Level1Name], '') + '</p><p> '+ @Level2 +' :   ' + ISNULL([Level2Name], '') + '</p>' 

						WHEN ISNULL([Level1Name], '') != '' THEN '<p> '+ @Level1 +' :   ' + ISNULL([Level1Name], '') + '</p>'
					END AS AllMSlevels
				FROM [dbo].[ManagementStructureDetails] MSD WITH(NOLOCK) 
				WHERE MSD.MSDetailsId = @MSDetailsId 

				IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL
				BEGIN
				DROP TABLE #TempTable
				END
				
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetMSDetailsById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@MSDetailsId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END
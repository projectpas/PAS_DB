﻿
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
     
-- EXEC [USP_GetEntityManagementStructureDetailsById] 21
**************************************************************/

CREATE PROCEDURE [dbo].[USP_GetEntityManagementStructureDetailsById]
@EntityStructureId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				DECLARE @MasterCompanyId INT;
				DECLARE @MSLevel INT;
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

				SELECT @MasterCompanyId = [MasterCompanyId]
				FROM [dbo].[EntityStructureSetup] ESS WITH(NOLOCK) 
				WHERE ESS.EntityStructureId = @EntityStructureId

				PRINT @MasterCompanyId

				SELECT @Level1 = MST.[Description] FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 1
				SELECT @Level2 = MST.[Description] FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 2
				SELECT @Level3 = MST.[Description] FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 3
				SELECT @Level4 = MST.[Description] FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 4
				SELECT @Level5 = MST.[Description] FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 5
				SELECT @Level6 = MST.[Description] FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 6
				SELECT @Level7 = MST.[Description] FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 7
				SELECT @Level8 = MST.[Description] FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 8
				SELECT @Level9 = MST.[Description] FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 9
				SELECT @Level10 = MST.[Description] FROM [dbo].[ManagementStructureType] MST WITH(NOLOCK) WHERE MST.MasterCompanyId = @MasterCompanyId AND MST.SequenceNo = 10

				SELECT DISTINCT ESS.EntityStructureId, ESS.[MasterCompanyId], 
					ESS.Level1Id,CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description] AS Level1Name,
					ESS.Level2Id,CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description] AS Level2Name,
					ESS.Level3Id,CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description] AS Level3Name,
					ESS.Level4Id,CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description] AS Level4Name,
					ESS.Level5Id,CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description] AS Level5Name,
					ESS.Level6Id,CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description] AS Level6Name,
					ESS.Level7Id,CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description] AS Level7Name,
					ESS.Level8Id,CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description] AS Level8Name,
					ESS.Level9Id,CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description] AS Level9Name,
					ESS.Level10Id,CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description] AS Level10Name,
					CASE	
						WHEN ISNULL(ESS.Level10Id, '') != '' THEN '<p> '+ @Level1 +' :   ' + ISNULL(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description], '') + '</p><p> '+ @Level2 +' :   ' + ISNULL(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description], '') + '</p><p> '+ @Level3 +' :   ' + ISNULL(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description], '') + 
							'</p><p> '+ @Level4 +' :   ' + ISNULL(CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description], '') + '</p><p> '+ @Level5 +' :   ' + ISNULL(CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description], '') + '</p><p> '+ @Level6 +' :   ' 
							+ ISNULL(CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description], '') + '</p><p> '+ @Level7 +' :   ' + ISNULL(CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description], '') + '</p><p> '+ @Level8 +' :   ' + ISNULL(CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description], '') + 
							'</p><p> '+ @Level9 +' :   ' + ISNULL(CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description], '') + '</p><p> '+ @Level10 +' :   ' + ISNULL(CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description], '') + '</p>'

						WHEN ISNULL(ESS.Level9Id, '') != '' THEN '<p> '+ @Level1 +' :   ' + ISNULL(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description], '') + '</p><p> '+ @Level2 +' :   ' + ISNULL(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description], '') + '</p><p> '+ @Level3 +' :   ' + ISNULL(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description], '') + 
							'</p><p> '+ @Level4 +' :   ' + ISNULL(CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description], '') + '</p><p> '+ @Level5 +' :   ' + ISNULL(CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description], '') + '</p><p> '+ @Level6 +' :   ' 
							+ ISNULL(CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description], '') + '</p><p> '+ @Level7 +' :   ' + ISNULL(CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description], '') + '</p><p> '+ @Level8 +' :   ' + ISNULL(CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description], '') + 
							'</p><p> '+ @Level9 +' :   ' + ISNULL(CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description], '') + '</p>'

						WHEN ISNULL(ESS.Level8Id, '') != '' THEN '<p> '+ @Level1 +' :   ' + ISNULL(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description], '') + '</p><p> '+ @Level2 +' :   ' + ISNULL(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description], '') + '</p><p> '+ @Level3 +' :   ' + ISNULL(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description], '') + 
							'</p><p> '+ @Level4 +' :   ' + ISNULL(CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description], '') + '</p><p> '+ @Level5 +' :   ' + ISNULL(CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description], '') + '</p><p> '+ @Level6 +' :   ' 
							+ ISNULL(CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description], '') + '</p><p> '+ @Level7 +' :   ' + ISNULL(CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description], '') + '</p><p> '+ @Level8 +' :   ' + ISNULL(CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description], '') + '</p>'

						WHEN ISNULL(ESS.Level7Id, '') != '' THEN '<p> '+ @Level1 +' :   ' + ISNULL(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description], '') + '</p><p> '+ @Level2 +' :   ' + ISNULL(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description], '') + '</p><p> '+ @Level3 +' :   ' + ISNULL(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description], '') + 
							'</p><p> '+ @Level4 +' :   ' + ISNULL(CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description], '') + '</p><p> '+ @Level5 +' :   ' + ISNULL(CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description], '') + '</p><p> '+ @Level6 +' :   ' 
							+ ISNULL(CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description], '') + '</p><p> '+ @Level7 +' :   ' + ISNULL(CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description], '') + '</p>'

						WHEN ISNULL(ESS.Level6Id, '') != '' THEN '<p> '+ @Level1 +' :   ' + ISNULL(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description], '') + '</p><p> '+ @Level2 +' :   ' + ISNULL(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description], '') + '</p><p> '+ @Level3 +' :   ' + ISNULL(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description], '') + 
							'</p><p> '+ @Level4 +' :   ' + ISNULL(CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description], '') + '</p><p> '+ @Level5 +' :   ' + ISNULL(CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description], '') + '</p><p> '+ @Level6 +' :   ' 
							+ ISNULL(CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description], '') + '</p>'

						WHEN ISNULL(ESS.Level5Id, '') != '' THEN '<p> '+ @Level1 +' :   ' + ISNULL(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description], '') + '</p><p> '+ @Level2 +' :   ' + ISNULL(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description], '') + '</p><p> '+ @Level3 +' :   ' + ISNULL(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description], '') + 
							'</p><p> '+ @Level4 +' :   ' + ISNULL(CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description], '') + '</p><p> '+ @Level5 +' :   ' + ISNULL(CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description], '') + '</p>'

						WHEN ISNULL(ESS.Level4Id, '') != '' THEN '<p> '+ @Level1 +' :   ' + ISNULL(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description], '') + '</p><p> '+ @Level2 +' :   ' + ISNULL(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description], '') + '</p><p> '+ @Level3 +' :   ' + ISNULL(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description], '') + 
							'</p><p> '+ @Level4 +' :   ' + ISNULL(CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description], '') + '</p>'

						WHEN ISNULL(ESS.Level3Id, '') != '' THEN '<p> '+ @Level1 +' :   ' + ISNULL(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description], '') + '</p><p> '+ @Level2 +' :   ' + ISNULL(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description], '') + '</p><p> '+ @Level3 +' :   ' + ISNULL(CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description], '') + '</p>'

						WHEN ISNULL(ESS.Level2Id, '') != '' THEN '<p> '+ @Level1 +' :   ' + ISNULL(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description], '') + '</p><p> '+ @Level2 +' :   ' + ISNULL(CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description], '') + '</p>'

						WHEN ISNULL(ESS.Level1Id, '') != '' THEN '<p> '+ @Level1 +' :   ' + ISNULL(CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description], '') + '</p>'
					END AS AllMSlevels,	
					CASE WHEN ISNULL(ESS.Level10Id, '') != '' THEN CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description] 
						 WHEN ISNULL(ESS.Level9Id, '') != '' THEN CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description] 
						 WHEN ISNULL(ESS.Level8Id, '') != '' THEN CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description] 
						 WHEN ISNULL(ESS.Level7Id, '') != '' THEN CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description] 
						 WHEN ISNULL(ESS.Level6Id, '') != '' THEN CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description] 
						 WHEN ISNULL(ESS.Level5Id, '') != '' THEN CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description] 
						 WHEN ISNULL(ESS.Level4Id, '') != '' THEN CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description] 
						 WHEN ISNULL(ESS.Level3Id, '') != '' THEN CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description] 
						 WHEN ISNULL(ESS.Level2Id, '') != '' THEN CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description] 
						 WHEN ISNULL(ESS.Level1Id, '') != '' THEN CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description] 
					END AS LastMSName					
				FROM dbo.EntityStructureSetup ESS WITH (NOLOCK)
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
				WHERE ESS.EntityStructureId = @EntityStructureId
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetEntityManagementStructureDetailsById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@EntityStructureId, '') + ''
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
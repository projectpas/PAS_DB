

CREATE FUNCTION [dbo].[GetAllMSLevelString]  
(  
   @MSDetailsId BIGINT
)  
RETURNS @Output TABLE (  
   AllMSlevels NVARCHAR(MAX)  
)  
AS  
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

				INSERT INTO @Output(AllMSlevels)
				SELECT 				
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
RETURN  
END
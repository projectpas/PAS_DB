
/*************************************************************           
 ** File:   [USP_GetRoleWiseEntityManagementStructureList]           
 ** Author:   Moin Bloch
 ** Description: Get Entity Structure Managment List  
 ** Purpose:         
 ** Date:   28/02/2022      
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    28/02/2022   Moin Bloch    Created
     
 EXEC USP_GetRoleWiseEntityManagementStructureList @PageSize=10,@PageNumber=1,@SortColumn=N'EntityStructureId',@SortOrder=1,@GlobalFilter=N'',
	@Level1Name=NULL,@Level2Name=NULL,@Level3Name=NULL,@Level4Name=NULL,@Level5Name=NULL,@Level6Name=NULL,@Level7Name=NULL,@Level8Name=NULL,
	@Level9Name=NULL,@Level10Name=NULL,@MasterCompanyId=2,@RoleId=2,@LoginUserRoleID = 2,@EmployeeId = 15,@EntityStructureId=12
**************************************************************/ 
CREATE PROCEDURE [dbo].[USP_GetRoleWiseEntityManagementStructureList]
	@PageNumber INT,
	@PageSize INT,
	@SortColumn VARCHAR(50)=null,
	@SortOrder INT,
	@GlobalFilter VARCHAR(50) = null,
	@Level1Name VARCHAR(50)=null,
	@Level2Name VARCHAR(50)=null,
	@Level3Name VARCHAR(50)=null,
	@Level4Name VARCHAR(50)=null,
    @Level5Name VARCHAR(50)=null,
	@Level6Name VARCHAR(50)=null,
	@Level7Name VARCHAR(50)=null,
    @Level8Name VARCHAR(50)=null,
    @Level9Name VARCHAR(50)=null,
	@Level10Name VARCHAR(50)=null,
	@MasterCompanyId INT = null,
	@RoleId INT = null,
	@LoginUserRoleID bigint=null,
	@EmployeeId bigint=null,
	@EntityStructureId INT = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @RecordFrom INT;
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

				SET @RecordFrom = (@PageNumber-1) * @PageSize;				
				
				IF @SortColumn is null
				BEGIN
					SET @SortColumn=Upper('CreatedDate')
				END 
				Else
				BEGIN 
					SET @SortColumn=Upper(@SortColumn)
				END

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
		
			;With Result AS(
				SELECT DISTINCT ESS.EntityStructureId,  
					--EMS.RoleId,
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
					END AS LastMSlevel					
				FROM dbo.EntityStructureSetup ESS WITH (NOLOCK)				    
					--LEFT JOIN dbo.RoleManagementStructure EMS WITH (NOLOCK) ON ESS.EntityStructureId =  EMS.EntityStructureId					
					--LEFT JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EMS.RoleId = EUR.RoleId 
					LEFT JOIN ManagementStructureLevel MSL1 WITH (NOLOCK) on ESS.Level1Id = MSL1.ID
					LEFT JOIN ManagementStructureLevel MSL2 WITH (NOLOCK) on ESS.Level2Id = MSL2.ID
					LEFT JOIN ManagementStructureLevel MSL3 WITH (NOLOCK) on ESS.Level3Id = MSL3.ID
					LEFT JOIN ManagementStructureLevel MSL4 WITH (NOLOCK) on ESS.Level4Id = MSL4.ID
					LEFT JOIN ManagementStructureLevel MSL5 WITH (NOLOCK) on ESS.Level5Id = MSL5.ID
					LEFT JOIN ManagementStructureLevel MSL6 WITH (NOLOCK) on ESS.Level6Id = MSL6.ID
					LEFT JOIN ManagementStructureLevel MSL7 WITH (NOLOCK) on ESS.Level7Id = MSL7.ID
					LEFT JOIN ManagementStructureLevel MSL8 WITH (NOLOCK) on ESS.Level8Id = MSL8.ID
					LEFT JOIN ManagementStructureLevel MSL9 WITH (NOLOCK) on ESS.Level9Id = MSL9.ID
					LEFT JOIN ManagementStructureLevel MSL10 WITH (NOLOCK) on ESS.Level10Id = MSL10.ID
				WHERE ((ESS.IsDeleted = 0) 
				        AND ESS.MasterCompanyId = @MasterCompanyId )),
						--AND EMS.RoleId = @LoginUserRoleID and EUR.EmployeeId = @EmployeeId) 
						--OR (ESS.EntityStructureId = @EntityStructureId)), 
						--AND EMS.RoleId = @LoginUserRoleID and EUR.EmployeeId = @EmployeeId)), 
				FinalResult AS (
				SELECT EntityStructureId, 
					   --RoleId, 
				       Level1Id, Level1Name, Level2Id, Level2Name, Level3Id, Level3Name, Level4Id, Level4Name, 
					   Level5Id, Level5Name, Level6Id, Level6Name, Level7Id, Level7Name, Level8Id, Level8Name,
					   Level9Id, Level9Name, Level10Id, Level10Name, AllMSlevels, LastMSlevel FROM Result
				WHERE (
					(@GlobalFilter <>'' AND ((Level1Name like '%' +@GlobalFilter+'%' ) OR 
							(Level2Name LIKE '%' +@GlobalFilter+'%') OR
							(Level3Name LIKE '%' +@GlobalFilter+'%') OR
							(Level4Name LIKE '%' +@GlobalFilter+'%') OR
							(Level5Name LIKE '%' +@GlobalFilter+'%') OR
							(Level6Name LIKE '%' +@GlobalFilter+'%') OR
							(Level7Name LIKE '%' +@GlobalFilter+'%') OR
							(Level8Name LIKE '%' +@GlobalFilter+'%') OR
							(Level9Name LIKE '%' +@GlobalFilter+'%') OR
							(Level10Name LIKE '%' +@GlobalFilter+'%')
							))
							OR   
							(@GlobalFilter='' AND (IsNull(@Level1Name,'') ='' OR Level1Name like  '%'+ @Level1Name+'%') AND 
							(IsNull(@Level2Name,'') ='' OR Level2Name like '%'+@Level2Name+'%') AND
							(IsNull(@Level3Name,'') ='' OR Level3Name like  '%'+@Level3Name+'%') AND
							(IsNull(@Level4Name,'') ='' OR Level4Name like '%'+@Level4Name+'%') AND
							(IsNull(@Level5Name,'') ='' OR Level5Name like '%'+ @Level5Name+'%') AND
							(IsNull(@Level6Name,'') ='' OR Level6Name like '%'+@Level6Name+'%') AND
							(IsNull(@Level7Name,'') ='' OR Level7Name like '%'+ @Level7Name+'%') AND
							(IsNull(@Level8Name,'') ='' OR Level8Name like '%'+ @Level8Name +'%') AND
							(IsNull(@Level9Name,'') ='' OR Level9Name like '%'+ @Level9Name +'%') AND
							(IsNull(@Level10Name,'') ='' OR Level10Name like '%'+@Level10Name+'%')))),
						ResultCount AS (Select COUNT(EntityStructureId) AS NumberOfItems FROM FinalResult)
					SELECT EntityStructureId,
					--RoleId, 
					Level1Id, Level1Name,Level2Id, Level2Name,Level3Id, Level3Name,Level4Id, Level4Name,Level5Id, Level5Name,
						Level6Id, Level6Name, Level7Id, Level7Name, Level8Id, Level8Name,Level9Id, Level9Name,Level10Id, Level10Name, AllMSlevels, LastMSlevel, NumberOfItems FROM FinalResult, ResultCount
					ORDER BY  
					CASE WHEN (@SortOrder=1 AND @SortColumn='ENTITYSTRUCTUREID')  THEN EntityStructureId END DESC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='LEVEL1NAME')  THEN Level1Name END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='LEVEL2NAME')  THEN Level2Name END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='LEVEL3NAME')  THEN Level3Name END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='LEVEL4NAME')  THEN Level4Name END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='LEVEL5NAME')  THEN Level5Name END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='LEVEL6NAME')  THEN Level6Name END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='LEVEL7NAME')  THEN Level7Name END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='LEVEL8NAME')  THEN Level8Name END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='LEVEL9NAME')  THEN Level9Name END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='LEVEL10NAME')  THEN Level10Name END ASC,

					CASE WHEN (@SortOrder=-1 AND @SortColumn='ENTITYSTRUCTUREID')  THEN EntityStructureId END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL1NAME')  THEN Level1Name END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL2NAME')  THEN Level2Name END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL3NAME')  THEN Level3Name END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL4NAME')  THEN Level4Name END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL5NAME')  THEN Level5Name END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL6NAME')  THEN Level6Name END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL7NAME')  THEN Level7Name END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL8NAME')  THEN Level8Name END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL9NAME')  THEN Level9Name END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='LEVEL10NAME')  THEN Level10Name END DESC
					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetEntityManagementStructureList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END
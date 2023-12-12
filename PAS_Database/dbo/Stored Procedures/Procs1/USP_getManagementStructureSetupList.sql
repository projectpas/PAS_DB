CREATE PROCEDURE [dbo].[USP_getManagementStructureSetupList]
	-- Add the parameters for the stored procedure here
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
    @CreatedDate DATETIME=null,
    @UpdatedDate  DATETIME=null,
    @IsDeleted BIT = null,
	@CreatedBy VARCHAR(50)=null,
	@UpdatedBy VARCHAR(50)=null,
	@MasterCompanyId INT = null,
	@OrganizationTagTypeName VARCHAR(50) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @RecordFrom INT;
				SET @RecordFrom = (@PageNumber-1) * @PageSize;
				IF @IsDeleted is null
				BEGIN
					SET @IsDeleted=0
				END
				
				IF @SortColumn is null
				BEGIN
					SET @SortColumn=Upper('CreatedDate')
				END 
				Else
				BEGIN 
					SET @SortColumn=Upper(@SortColumn)
				END
		
			-- Insert statements for procedure here
			;With Result AS(
				SELECT ESS.EntityStructureId, --LE.[Name] AS Level1Name,
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
					ESS.CreatedDate, ESS.UpdatedDate, ESS.CreatedBy, ESS.UpdatedBy,ISNULL(OTT.OrganizationTagTypeId,0)AS OrganizationTagTypeId,OTT.[Name] AS OrganizationTagTypeName
				FROM EntityStructureSetup ESS WITH (NOLOCK)
					--LEFT JOIN LegalEntity LE on LE.LegalEntityId = ESS.Level1Id
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
					LEFT JOIN OrganizationTagType OTT WITH (NOLOCK) on ESS.OrganizationTagTypeId = OTT.OrganizationTagTypeId
				WHERE (ESS.IsDeleted = @IsDeleted) AND ESS.MasterCompanyId = @MasterCompanyId),
				FinalResult AS (
				SELECT EntityStructureId, Level1Id, Level1Name, Level2Id, Level2Name, Level3Id, Level3Name, Level4Id, Level4Name, 
						Level5Id, Level5Name, Level6Id, Level6Name, Level7Id, Level7Name, Level8Id, Level8Name,
						Level9Id, Level9Name, Level10Id, Level10Name,CreatedDate, UpdatedDate, CreatedBy, UpdatedBy,OrganizationTagTypeId,OrganizationTagTypeName FROM Result
				WHERE (
					(@GlobalFilter <>'' AND ((Level1Name like '%' +@GlobalFilter+'%' ) OR 
							(Level2Name like '%' +@GlobalFilter+'%') OR
							(Level3Name like '%' +@GlobalFilter+'%') OR
							(Level4Name like '%' +@GlobalFilter+'%') OR
							(Level5Name like '%' +@GlobalFilter+'%') OR
							(Level6Name like '%'+@GlobalFilter+'%') OR
							(Level7Name like '%' +@GlobalFilter+'%') OR
							(Level8Name like '%' +@GlobalFilter+'%') OR
							(Level9Name like '%' +@GlobalFilter+'%') OR
							(Level10Name like '%' +@GlobalFilter+'%') OR
							(OrganizationTagTypeName like '%' +@GlobalFilter+'%')
							))
							OR   
							(@GlobalFilter='' AND (IsNull(@Level1Name,'') ='' OR Level1Name like  '%'+ @Level1Name+'%') and 
							(IsNull(@Level2Name,'') ='' OR Level2Name like '%'+@Level2Name+'%') and
							(IsNull(@Level3Name,'') ='' OR Level3Name like  '%'+@Level3Name+'%') and
							(IsNull(@Level4Name,'') ='' OR Level4Name like '%'+@Level4Name+'%') and
							(IsNull(@Level5Name,'') ='' OR Level5Name like '%'+ @Level5Name+'%') and
							(IsNull(@Level6Name,'') ='' OR Level6Name like '%'+@Level6Name+'%') and
							(IsNull(@Level7Name,'') ='' OR Level7Name like '%'+ @Level7Name+'%') and
							(IsNull(@Level8Name,'') ='' OR Level8Name like '%'+ @Level8Name +'%') and
							(IsNull(@Level9Name,'') ='' OR Level9Name like '%'+ @Level9Name +'%') and
							(IsNull(@Level10Name,'') ='' OR Level10Name like '%'+@Level10Name+'%') and
							(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%'+ @CreatedBy+'%') and
							(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%'+ @UpdatedBy+'%') and
							(IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) and
							(IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date))and
							(IsNull(@OrganizationTagTypeName,'') ='' OR OrganizationTagTypeName like '%'+@OrganizationTagTypeName+'%'))
							)),
						ResultCount AS (Select COUNT(EntityStructureId) AS NumberOfItems FROM FinalResult)
						SELECT EntityStructureId,Level1Id, Level1Name,Level2Id, Level2Name,Level3Id, Level3Name,Level4Id, Level4Name,Level5Id, Level5Name,
						Level6Id, Level6Name, Level7Id, Level7Name, Level8Id, Level8Name,Level9Id, Level9Name,Level10Id, Level10Name,CreatedDate, UpdatedDate, CreatedBy, UpdatedBy,
						NumberOfItems,OrganizationTagTypeId,OrganizationTagTypeName FROM FinalResult, ResultCount

						ORDER BY  
					CASE WHEN (@SortOrder=1 and @SortColumn='ENTITYSTRUCTUREID')  THEN EntityStructureId END DESC,
					CASE WHEN (@SortOrder=1 and @SortColumn='LEVEL1NAME')  THEN Level1Name END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='LEVEL2NAME')  THEN Level2Name END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='LEVEL3NAME')  THEN Level3Name END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='LEVEL4NAME')  THEN Level4Name END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='LEVEL5NAME')  THEN Level5Name END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='LEVEL6NAME')  THEN Level6Name END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='LEVEL7NAME')  THEN Level7Name END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='LEVEL8NAME')  THEN Level8Name END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='LEVEL9NAME')  THEN Level9Name END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='LEVEL10NAME')  THEN Level10Name END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ORGANIZATIONTAGTYPENAME')  THEN OrganizationTagTypeName END ASC,

					CASE WHEN (@SortOrder=-1 and @SortColumn='ENTITYSTRUCTUREID')  THEN EntityStructureId END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='LEVEL1NAME')  THEN Level1Name END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='LEVEL2NAME')  THEN Level2Name END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='LEVEL3NAME')  THEN Level3Name END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='LEVEL4NAME')  THEN Level4Name END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='LEVEL5NAME')  THEN Level5Name END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='LEVEL6NAME')  THEN Level6Name END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='LEVEL7NAME')  THEN Level7Name END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='LEVEL8NAME')  THEN Level8Name END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='LEVEL9NAME')  THEN Level9Name END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='LEVEL10NAME')  THEN Level10Name END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ORGANIZATIONTAGTYPENAME')  THEN OrganizationTagTypeName END DESC
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
              , @AdhocComments     VARCHAR(150)    = 'SearchSalesOrderPNViewData' 
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
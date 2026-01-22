CREATE     PROCEDURE [dbo].[USP_SaveReleaseNoteTitlesDetails]
	@tbl_ReleaseNoteTitles [ReleaseNoteTitlesType] READONLY
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY
		--Updated Existed Records
		Update RND SET 
			RND.Title = T.Title,
			RND.SprintName = T.SprintName,
			RND.TypeId = T.TypeId,
			RND.[Description] = T.TitleDescription,
			RND.UpdatedDate = GETUTCDATE()
		FROM [dbo].[ReleaseNotesTitleDetails] RND WITH(NOLOCK)
			JOIN @tbl_ReleaseNoteTitles T ON RND.TitleId = T.TitleId
		Where ISNULL(T.[IsDeleted],0) = 0 AND ISNULL(T.TitleId,0) > 0
		
		--Insert New Records
		INSERT INTO [dbo].[ReleaseNotesTitleDetails](
			[ReleaseNoteHeaderId],[Title],[SprintName], [TypeId],[Description],[MasterCompanyId],
			[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],[IsActive], [IsDeleted]
		)
		SELECT 
			[ReleaseNoteHeaderId],[Title], [SprintName], [TypeId],[TitleDescription],[MasterCompanyId],
			[CreatedBy], [UpdatedBy], GETUTCDATE(), GETUTCDATE(),[IsActive], [IsDeleted]
		FROM @tbl_ReleaseNoteTitles temp where ISNULL(temp.[TitleId],0) = 0 AND ISNULL(temp.[IsDeleted],0) = 0;  
		

	END TRY   
	BEGIN CATCH        
	IF @@trancount > 0  
    PRINT 'ROLLBACK'  
		ROLLBACK TRAN;  
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
		, @AdhocComments     VARCHAR(150)    = 'USP_SaveReleaseNoteTitlesDetails'   
		, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''  
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
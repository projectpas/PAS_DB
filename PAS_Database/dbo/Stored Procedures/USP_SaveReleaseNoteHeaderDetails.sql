 /*************************************************************           
 ** File:   [USP_SaveReleaseNoteHeaderDetails]      
 ** Author:   Bhargav Saliya 
 ** Description: This Store Procedure Use to add Release Note Headers
 ** Purpose:         
 ** Date:   22 May 2025
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author			Change Description            
 ** --   --------		 -------		--------------------------------          
    1    22 May 2025   Bhargav Saliya		Created

**************************************************************/
CREATE     PROCEDURE [dbo].[USP_SaveReleaseNoteHeaderDetails]
	@tbl_ReleaseNoteHeaderDetailsType [ReleaseNoteHeadersDetailsType] READONLY
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY
		
		Update RHD SET 
			RHD.SprintName = T.SprintName,
			RHD.SprinDescription = T.SprinDescription,
			RHD.[ReleaseDate] = T.ReleaseDate,
			RHD.[FileName] = T.[FileName],
			RHD.[DocumentPath] = T.DocumentPath,
			RHD.UpdatedDate = GETUTCDATE()
		FROM [dbo].[ReleaseNoteHeadersDetails] RHD WITH(NOLOCK)
			JOIN @tbl_ReleaseNoteHeaderDetailsType T ON RHD.ReleaseNoteHeaderId = T.ReleaseNoteHeaderId
		Where ISNULL(T.[IsDeleted],0) = 0 AND ISNULL(T.ReleaseNoteHeaderId,0) > 0

		INSERT INTO [dbo].[ReleaseNoteHeadersDetails](
			[SprintName], [SprinDescription],[ReleaseDate],[FileName],[DocumentPath],[MasterCompanyId], [CreatedBy],
			[UpdatedBy], [CreatedDate], [UpdatedDate],[IsActive], [IsDeleted]
		)
		SELECT 
			 [SprintName], [SprinDescription],[ReleaseDate],[FileName],[DocumentPath],[MasterCompanyId], [CreatedBy],
			 [UpdatedBy], GETUTCDATE(), GETUTCDATE(),[IsActive], [IsDeleted]
		FROM @tbl_ReleaseNoteHeaderDetailsType temp where ISNULL(temp.[ReleaseNoteHeaderId],0) = 0 AND ISNULL(temp.[IsDeleted],0) = 0;  


	END TRY   
	BEGIN CATCH        
	IF @@trancount > 0  
    PRINT 'ROLLBACK'  
		ROLLBACK TRAN;  
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
		, @AdhocComments     VARCHAR(150)    = 'USP_SaveReleaseNoteHeaderDetails'   
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
 /*************************************************************           
 ** File:   [USP_commonDeleteReleaseNoteById]      
 ** Author:   Bhargav Saliya 
 ** Description: This Store Procedure Use to Updated or Delete Record Of Release Note Listing Page
 ** Purpose:         
 ** Date:   02-June-2025
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author			Change Description            
 ** --   --------		 -------		--------------------------------          
    1    02-June-2025   Bhargav Saliya		Created

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_commonDeleteReleaseNoteById]
	@ReleaseNoteHeaderId bigint = 0,
	@TitleId bigint = 0,
	@FileName Varchar(500) = null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		IF((ISNULL(@ReleaseNoteHeaderId,0) > 0) AND (@FileName IS NULL))
		BEGIN
			DELETE [DBO].[ReleaseNoteHeadersDetails] WHERE  ReleaseNoteHeaderId = ISNULL(@ReleaseNoteHeaderId,0) AND ISNULL(IsDeleted,0) = 0;
		END
		ELSE IF(ISNULL(@TitleId,0) > 0)
		BEGIN
			DELETE [DBO].[ReleaseNotesTitleDetails] WHERE  TitleId = ISNULL(@TitleId,0) AND ISNULL(IsDeleted,0) = 0;
		END
		ELSE IF((ISNULL(@ReleaseNoteHeaderId,0) > 0) AND (@FileName IS NOT NULL))
		BEGIN
			UPDATE [DBO].[ReleaseNoteHeadersDetails] SET DocumentPath = NULL,[FileName] = NULL WHERE ReleaseNoteHeaderId = ISNULL(@ReleaseNoteHeaderId,0) AND ISNULL(IsDeleted,0) = 0; 
		END
	END TRY
	BEGIN CATCH  
   
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = 'USP_commonDeleteReleaseNoteById',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReleaseNoteHeaderId, '') AS varchar(100)) +    
            '@Parameter2 = ''' + CAST(ISNULL(@TitleId, '') AS varchar(100)) +  
            '@Parameter3 = ''' + CAST(ISNULL(@FileName, '') AS varchar(100)),  
            @ApplicationName varchar(100) = 'PAS'   
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR (  
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'  
    , 16, 1, @ErrorLogID)  
  
    RETURN (1);  
	END CATCH
END
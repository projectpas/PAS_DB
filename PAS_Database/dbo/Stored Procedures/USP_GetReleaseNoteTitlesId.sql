/*************************************************************
 ** File:   [USP_GetReleaseNoteTitlesId]
 ** Author: Bhargav Saliya
 ** Description: This stored procedure is used to get Release Note Titles Detailes by Id
 ** Purpose:
 ** Date:   23-May-2025
    
 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date				Author			Change Description
 ** --   --------			-------			--------------------------------
    1    23-May-2025		Bhargav Saliya		Created

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetReleaseNoteTitlesId]
	@ReleaseNoteHeaderId bigint = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT 
			[TitleId], [ReleaseNoteHeaderId], [Title], [SprintName], [Type], [TitleDescription]
		FROM
		(
			SELECT 
				rtd.[TitleId],
				rtd.[ReleaseNoteHeaderId],
				rtd.[Title],
				rtd.[SprintName],
				WT.[WorkType] AS [Type],
				rtd.[Description] AS TitleDescription
			FROM DBO.[ReleaseNotesTitleDetails] rtd WITH (NOLOCK) 
			LEFT JOIN DBO.[WorkType] WT WITH(NOLOCK) ON rtd.TypeId = WT.WorkTypeId
			WHERE rtd.[ReleaseNoteHeaderId] = @ReleaseNoteHeaderId
		) AS Titles;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetReleaseNoteTitlesId'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@ReleaseNoteHeaderId AS varchar(10)) ,'') +''
        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException
                @DatabaseName           =  @DatabaseName
                , @AdhocComments          =  @AdhocComments
                , @ProcedureParameters    =  @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID             =  @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
  END CATCH
END
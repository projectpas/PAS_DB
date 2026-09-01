 /***************************************************************  
 ** File:   [USP_SaveTaskInstructionMaster]             
 ** Author:   Bhargav Saliya
 ** Description: Returns the active image list for a Task Instruction.
 ** Date:  01-Sep-2026
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    01-Sep-2026		Bhargav Saliya			Created
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetTaskInstructionImages]
    @TaskInstructionId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY

        SELECT
            [TaskInstructionImageId],
            [TaskInstructionId],
            [FileName],
            [Link],
            [FileType],
            CAST([FileSize] AS VARCHAR(20)) + ' MB' AS [FileSize]
        FROM [dbo].[TaskInstructionImage] WITH (NOLOCK)
        WHERE [TaskInstructionId] = @TaskInstructionId
          AND ISNULL([IsActive],1) = 1
          AND ISNULL([IsDeleted],0) = 0
        ORDER BY [TaskInstructionImageId];
    END TRY   
    BEGIN CATCH      
        DECLARE @ErrorLogID INT
        ,@DatabaseName VARCHAR(100) = db_name()
        ,@AdhocComments VARCHAR(150) = 'USP_GetTaskInstructionImages'
        ,@ProcedureParameters VARCHAR(3000) =
                '@TaskInstructionImageId = ''' + ISNULL(CAST(@TaskInstructionId AS VARCHAR(100)), '') + ''''    
        ,@ApplicationName VARCHAR(100) = 'PAS'

        EXEC spLogException @DatabaseName = @DatabaseName
            ,@AdhocComments = @AdhocComments
            ,@ProcedureParameters = @ProcedureParameters
            ,@ApplicationName = @ApplicationName
            ,@ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR (
                'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
                ,16
                ,1
                ,@ErrorLogID
                )
        RETURN (1);           
    END CATCH
END;
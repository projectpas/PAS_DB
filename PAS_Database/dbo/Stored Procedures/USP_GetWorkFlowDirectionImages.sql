/***************************************************************  
 ** File:   [USP_GetWorkFlowDirectionImages]             
 ** Author:   SUMIT KUMAR
 ** Description: Returns the active image list for a Workflow Direction instruction.
 ** Date:  02-Sep-2026
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    02-Sep-2026		SUMIT KUMAR			Created
 **************************************************************/
CREATE PROCEDURE [dbo].[USP_GetWorkFlowDirectionImages]
    @WorkflowDirectionId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY

        SELECT
            [WorkflowDirectionImageId],
            [WorkflowDirectionId],
            [FileName],
            [Link],
            [FileType],
            CAST([FileSize] AS VARCHAR(20)) + ' MB' AS [FileSize]
        FROM [dbo].[WorkFlowDirectionImage] WITH (NOLOCK)
        WHERE [WorkflowDirectionId] = @WorkflowDirectionId
          AND ISNULL([IsActive], 1) = 1
          AND ISNULL([IsDeleted], 0) = 0
        ORDER BY [WorkflowDirectionImageId];
    END TRY   
    BEGIN CATCH      
        DECLARE @ErrorLogID INT
        ,@DatabaseName VARCHAR(100) = db_name()
        ,@AdhocComments VARCHAR(150) = 'USP_GetWorkFlowDirectionImages'
        ,@ProcedureParameters VARCHAR(3000) =
                '@WorkflowDirectionId = ''' + ISNULL(CAST(@WorkflowDirectionId AS VARCHAR(100)), '') + ''''    
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

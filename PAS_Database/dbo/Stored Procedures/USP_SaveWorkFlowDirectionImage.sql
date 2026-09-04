/***************************************************************  
 ** File:   [USP_SaveWorkFlowDirectionImage]             
 ** Author:   SUMIT KUMAR
 ** Description: Inserts a single Workflow Direction image (S3 metadata) row.
 ** Date:  02-Sep-2026
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    02-Sep-2026		SUMIT KUMAR			Created
 **************************************************************/
CREATE PROCEDURE [dbo].[USP_SaveWorkFlowDirectionImage]
    @WorkflowDirectionId BIGINT,
    @WorkflowId          BIGINT         = NULL,
    @TaskId              BIGINT         = NULL,
    @WorkFlowTaskId      BIGINT         = NULL,
    @FileName            VARCHAR(500)   = NULL,
    @Link                VARCHAR(1000)  = NULL,
    @FileType            VARCHAR(100)   = NULL,
    @FileSize            DECIMAL(18, 2) = NULL,
    @MasterCompanyId     INT,
    @CreatedBy           VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY

        IF ISNULL(@WorkflowId, 0) = 0 OR ISNULL(@TaskId, 0) = 0
        BEGIN
            SELECT @WorkflowId = ISNULL(@WorkflowId, WorkflowId), @TaskId = ISNULL(@TaskId, TaskId)
            FROM [dbo].[WorkFlowDirection] WITH (NOLOCK)
            WHERE [WorkflowDirectionId] = @WorkflowDirectionId;
        END

        IF ISNULL(@WorkFlowTaskId, 0) = 0 AND ISNULL(@WorkflowId, 0) > 0 AND ISNULL(@TaskId, 0) > 0
        BEGIN
            SELECT @WorkFlowTaskId = WorkFlowTaskId
            FROM [dbo].[WorkFlowTask] WITH (NOLOCK)
            WHERE [WorkFlowId] = @WorkflowId AND [TaskId] = @TaskId;
        END

        INSERT INTO [dbo].[WorkFlowDirectionImage]
            ([WorkflowDirectionId], [WorkflowId], [TaskId], [WorkFlowTaskId], [FileName], [Link], [FileType], [FileSize],
             [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
        VALUES
            (@WorkflowDirectionId, @WorkflowId, @TaskId, @WorkFlowTaskId, @FileName, @Link, @FileType, @FileSize,
             @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0);

        SELECT SCOPE_IDENTITY() AS WorkflowDirectionImageId;
    END TRY   
    BEGIN CATCH      
        DECLARE @ErrorLogID INT
        ,@DatabaseName VARCHAR(100) = db_name()
        ,@AdhocComments VARCHAR(150) = 'USP_SaveWorkFlowDirectionImage'
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

/***************************************************************  
 ** File:   [USP_DeleteWorkFlowDirectionImage]             
 ** Author:   SUMIT KUMAR
 ** Description: Soft-deletes a Workflow Direction image record.
 ** Date:  02-Sep-2026
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    02-Sep-2026		SUMIT KUMAR			Created
 **************************************************************/
CREATE PROCEDURE [dbo].[USP_DeleteWorkFlowDirectionImage]
    @WorkflowDirectionImageId BIGINT,
    @UpdatedBy                VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY

        UPDATE [dbo].[WorkFlowDirectionImage]
        SET [IsDeleted] = 1,
            [UpdatedBy] = ISNULL(@UpdatedBy, [UpdatedBy]),
            [UpdatedDate] = GETUTCDATE()
        WHERE [WorkflowDirectionImageId] = @WorkflowDirectionImageId;

    END TRY   
    BEGIN CATCH      
        DECLARE @ErrorLogID INT
        ,@DatabaseName VARCHAR(100) = db_name()
        ,@AdhocComments VARCHAR(150) = 'USP_DeleteWorkFlowDirectionImage'
        ,@ProcedureParameters VARCHAR(3000) =
                '@WorkflowDirectionImageId = ''' + ISNULL(CAST(@WorkflowDirectionImageId AS VARCHAR(100)), '') + ''', ' +
                '@UpdatedBy = ''' + ISNULL(@UpdatedBy, '') + ''''
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

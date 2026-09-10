/***************************************************************  
 ** File:   [USP_GetWorkOrderTaskInstructionImages]             
 ** Author:   SUMIT KUMAR
 ** Description: Returns active, non-deleted image records for a given WorkOrderTaskInstructionId [PN-17814].
 ** Date:  04-Sep-2026
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    04-Sep-2026		SUMIT KUMAR			Created [PN-17814]
 **************************************************************/
CREATE PROCEDURE [dbo].[USP_GetWorkOrderTaskInstructionImages]
    @WorkOrderTaskInstructionId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY
        SELECT
            [WorkOrderTaskInstructionImageId],
            [WorkOrderTaskInstructionId],
            [WorkOrderTaskId],
            [FileName],
            [Link],
            [FileType],
            [FileSize],
            [MasterCompanyId],
            [CreatedBy],
            [CreatedDate],
            [UpdatedBy],
            [UpdatedDate]
        FROM [dbo].[WorkOrderTaskInstructionImage] WITH (NOLOCK)
        WHERE [WorkOrderTaskInstructionId] = @WorkOrderTaskInstructionId
          AND ISNULL([IsDeleted], 0) = 0
          AND ISNULL([IsActive], 1) = 1
        ORDER BY [WorkOrderTaskInstructionImageId];
    END TRY   
    BEGIN CATCH      
        DECLARE @ErrorLogID INT
        ,@DatabaseName VARCHAR(100) = db_name()
        ,@AdhocComments VARCHAR(150) = 'USP_GetWorkOrderTaskInstructionImages'
        ,@ProcedureParameters VARCHAR(3000) =
                '@WorkOrderTaskInstructionId = ''' + ISNULL(CAST(@WorkOrderTaskInstructionId AS VARCHAR(100)), '') + ''''    
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

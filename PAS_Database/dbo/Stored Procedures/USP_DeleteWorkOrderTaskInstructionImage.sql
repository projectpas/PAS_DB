/***************************************************************  
 ** File:   [USP_DeleteWorkOrderTaskInstructionImage]             
 ** Author:   SUMIT KUMAR
 ** Description: Soft-deletes a Work Order Task Instruction image record [PN-17814].
 ** Date:  04-Sep-2026
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    04-Sep-2026		SUMIT KUMAR			Created [PN-17814]
 **************************************************************/
CREATE PROCEDURE [dbo].[USP_DeleteWorkOrderTaskInstructionImage]
    @WorkOrderTaskInstructionImageId BIGINT,
    @UpdatedBy VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY
        UPDATE [dbo].[WorkOrderTaskInstructionImage]
        SET [IsDeleted] = 1,
            [UpdatedBy] = @UpdatedBy,
            [UpdatedDate] = GETUTCDATE()
        WHERE [WorkOrderTaskInstructionImageId] = @WorkOrderTaskInstructionImageId;

        SELECT 1 AS Status;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT
        ,@DatabaseName VARCHAR(100) = db_name()
        ,@AdhocComments VARCHAR(150) = 'USP_DeleteWorkOrderTaskInstructionImage'
        ,@ProcedureParameters VARCHAR(3000) =
                '@WorkOrderTaskInstructionImageId = ''' + ISNULL(CAST(@WorkOrderTaskInstructionImageId AS VARCHAR(100)), '') + ''', ' +
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

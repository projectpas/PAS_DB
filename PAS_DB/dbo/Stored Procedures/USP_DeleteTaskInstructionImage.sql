 /***************************************************************  
 ** File:   [USP_SaveTaskInstructionMaster]             
 ** Author:   Bhargav Saliya
 ** Description: Soft-deletes a single Task Instruction image row.
 ** Date:  01-Sep-2026
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    01-Sep-2026		Bhargav Saliya			Created
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_DeleteTaskInstructionImage]
    @TaskInstructionImageId BIGINT,
    @UpdatedBy              VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY

        UPDATE [dbo].[TaskInstructionImage]
        SET [IsDeleted]   = 1,[IsActive]    = 0,[UpdatedBy]   = @UpdatedBy,[UpdatedDate] = GETUTCDATE()
        WHERE [TaskInstructionImageId] = @TaskInstructionImageId;
   END TRY   
    BEGIN CATCH      
        DECLARE @ErrorLogID INT
        ,@DatabaseName VARCHAR(100) = db_name()
        ,@AdhocComments VARCHAR(150) = 'USP_DeleteTaskInstructionImage'
        ,@ProcedureParameters VARCHAR(3000) =
                '@TaskInstructionImageId = ''' + ISNULL(CAST(@TaskInstructionImageId AS VARCHAR(100)), '') + ''', ' +
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
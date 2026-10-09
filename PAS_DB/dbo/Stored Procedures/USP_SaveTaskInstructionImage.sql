 /***************************************************************  
 ** File:   [USP_SaveTaskInstructionMaster]             
 ** Author:   Bhargav Saliya
 ** Description: Inserts a single Task Instruction image (S3 metadata) row.
 ** Date:  01-Sep-2026
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    01-Sep-2026		Bhargav Saliya			Created
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveTaskInstructionImage]
    @TaskInstructionId BIGINT,
    @FileName          VARCHAR(500)   = NULL,
    @Link              VARCHAR(1000)  = NULL,
    @FileType          VARCHAR(100)   = NULL,
    @FileSize          DECIMAL(18, 2) = NULL,
    @MasterCompanyId   INT,
    @CreatedBy         VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY

        INSERT INTO [dbo].[TaskInstructionImage]
            ([TaskInstructionId], [FileName], [Link], [FileType], [FileSize],
             [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
        VALUES
            (@TaskInstructionId, @FileName, @Link, @FileType, @FileSize,
             @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0);

        SELECT SCOPE_IDENTITY() AS TaskInstructionImageId;
    END TRY   
    BEGIN CATCH      
        DECLARE @ErrorLogID INT
        ,@DatabaseName VARCHAR(100) = db_name()
        ,@AdhocComments VARCHAR(150) = 'USP_SaveTaskInstructionImage'
        ,@ProcedureParameters VARCHAR(3000) =
                '@TaskInstructionId = ''' + ISNULL(CAST(@TaskInstructionId AS VARCHAR(100)), '') + ''''    
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
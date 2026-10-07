/***************************************************************  
 ** File:   [USP_SaveWorkOrderTaskInstructionImage]             
 ** Author:   SUMIT KUMAR
 ** Description: Inserts a single Work Order Task Instruction image (S3 metadata) row [PN-17814].
 ** Date:  04-Sep-2026
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    04-Sep-2026		SUMIT KUMAR			Created [PN-17814]
 **************************************************************/
CREATE PROCEDURE [dbo].[USP_SaveWorkOrderTaskInstructionImage]
    @WorkOrderTaskInstructionId BIGINT,
    @WorkOrderTaskId            BIGINT         = NULL,
    @FileName                   VARCHAR(500)   = NULL,
    @Link                       VARCHAR(1000)  = NULL,
    @FileType                   VARCHAR(100)   = NULL,
    @FileSize                   DECIMAL(18, 2) = NULL,
    @MasterCompanyId            INT,
    @CreatedBy                  VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY

        IF ISNULL(@WorkOrderTaskId, 0) = 0
        BEGIN
            SELECT @WorkOrderTaskId = WorkOrderTaskId
            FROM [dbo].[WorkOrderTaskInstruction] WITH (NOLOCK)
            WHERE [WorkOrderTaskInstructionId] = @WorkOrderTaskInstructionId;
        END

        INSERT INTO [dbo].[WorkOrderTaskInstructionImage]
            ([WorkOrderTaskInstructionId], [WorkOrderTaskId], [FileName], [Link], [FileType], [FileSize],
             [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
        VALUES
            (@WorkOrderTaskInstructionId, @WorkOrderTaskId, @FileName, @Link, @FileType, @FileSize,
             @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0);

        SELECT SCOPE_IDENTITY() AS WorkOrderTaskInstructionImageId;
    END TRY   
    BEGIN CATCH      
        DECLARE @ErrorLogID INT
        ,@DatabaseName VARCHAR(100) = db_name()
        ,@AdhocComments VARCHAR(150) = 'USP_SaveWorkOrderTaskInstructionImage'
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

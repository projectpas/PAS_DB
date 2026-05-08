
/*************************************************************           
 ** File:   [UpdateWorkflowDeletedStatus]           
 ** Author:   Priyansh Patel
 ** Description: Soft delete workflow by updating IsDeleted flag    
 ** Purpose:         
 ** Date:   05-May-2026        
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author            Change Description            
 ** --   --------     -------           --------------------------------          
    1    05/05/2026   Priyansh Patel    Created [PN-16276]
**************************************************************/ 

CREATE   PROCEDURE [dbo].[UpdateWorkflowDeletedStatus]
    @WorkFlowId BIGINT,
    @UpdatedBy VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validate Workflow existence
        IF NOT EXISTS (SELECT 1 FROM dbo.Workflow WITH (NOLOCK) WHERE WorkflowId = @WorkFlowId)
        BEGIN
            RAISERROR ('Workflow does not exist', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Soft Delete Update
        UPDATE dbo.Workflow
        SET 
            IsDeleted = 1,
            UpdatedBy = @UpdatedBy,
            UpdatedDate = GETUTCDATE()
        WHERE WorkflowId = @WorkFlowId;

        COMMIT TRANSACTION;
    END TRY    

    BEGIN CATCH      
        IF @@TRANCOUNT > 0
            PRINT 'ROLLBACK'
            ROLLBACK TRAN;

        DECLARE   
            @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME(),

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments VARCHAR(150) = 'UpdateWorkflowDeletedStatus',
            @ProcedureParameters VARCHAR(3000) = 
                '@WorkFlowId = ''' + ISNULL(CAST(@WorkFlowId AS VARCHAR), '') + ''', ' +
                '@UpdatedBy = ''' + ISNULL(@UpdatedBy, '') + '''',
            @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

        EXEC spLogException 
                @DatabaseName = @DatabaseName,
                @AdhocComments = @AdhocComments,
                @ProcedureParameters = @ProcedureParameters,
                @ApplicationName = @ApplicationName,
                @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR (
            'Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 
            16, 
            1, 
            @ErrorLogID
        );

        RETURN (1);
    END CATCH    
END
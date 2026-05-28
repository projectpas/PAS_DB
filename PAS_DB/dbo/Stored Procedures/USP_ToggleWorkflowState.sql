/*************************************************************           
 ** File:   [USP_ToggleWorkflowState]           
 ** Author:   Priyansh Patel
 ** Description: To toggle the active/inactive workflow state
 ** Purpose:         
 ** Date:   05-May-2026       
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date           Author		        Change Description            
 ** --   --------       -------		        --------------------------------          
    1    05-May-2026    Priyansh Patel      Created
 
**************************************************************/ 
CREATE PROCEDURE [dbo].[USP_ToggleWorkflowState]
    @WorkflowId BIGINT,
    @UpdatedBy VARCHAR(50),
    @returnOut VARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @returnOut = 'E';

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS ( SELECT 1  FROM dbo.Workflow WITH (NOLOCK)  WHERE WorkflowId = @WorkflowId
        )
        BEGIN
            SET @returnOut = 'Workflow does not exist';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE dbo.Workflow
        SET IsActive = CASE WHEN ISNULL(IsActive, 0) = 1 THEN 0 ELSE 1 END,
            UpdatedBy = @UpdatedBy,
            UpdatedDate = GETDATE()
        WHERE WorkflowId = @WorkflowId;

        SET @returnOut = 'S';

        COMMIT TRANSACTION;
    END TRY
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
            ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_ToggleWorkflowState' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkflowId, '') + ''', 
													   @Parameter2 = ' + ISNULL(@UpdatedBy,'') + ', 	'
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH    
END
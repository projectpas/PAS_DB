/*************************************************************           
 ** File:   [USP_UpdateWorkOrderPartNotes]       
 ** Author:   Rajesh Gami
 ** Description: This stored procedure is used to Update Work Order Part (MPN) Notes
 ** Purpose:         
 ** Date:   24/Sep/2025     
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author		Change Description            
 ** --   --------	   -------		--------------------------------          
    1    24/Sep/2025    Rajesh Gami		Created
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateWorkOrderPartNotes]
@WOMPNId BIGINT = NULL,
@Notes NVARCHAR(MAX) = NULL

AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
        UPDATE DBO.[WorkOrderPartNumber] set Notes = @Notes WHERE Id = @WOMPNId;
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
        ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateWorkOrderPartNotes' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WOMPNId, '') AS VARCHAR(100)) + 
			                                         '@Parameter2 = ''' + CAST(ISNULL(@Notes, '') AS VARCHAR(100))
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

/*************************************************************           
 ** File:   [UpdateWorkFlowColumnsWithId]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used Update Workflow Column based on ID    
 ** Purpose:         
 ** Date:   04/28/2020        
          
 ** PARAMETERS:           
 @WorkFlowId Int
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/28/2020   Hemant Saliya Created
     
--EXEC [UpdateWorkFlowColumnsWithId] 5
**************************************************************/

CREATE PROCEDURE [dbo].[UpdateWorkFlowColumnsWithId]
	@WorkFlowId int
AS
BEGIN
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				UPDATE WF SET 
					WF.Currency = c.Code,
					WF.WorkScope = WS.WorkScopeCode,
					WF.CustomerName = CUS.Name
				FROM [dbo].[Workflow] WF WITH (NOLOCK)
					JOIN [dbo].[Currency] C WITH (NOLOCK) ON WF.CurrencyId = C.CurrencyId
					JOIN [dbo].[WorkScope] WS WITH (NOLOCK) ON WF.WorkScopeId = WS.WorkScopeId 
					LEFT JOIN [dbo].[Customer] CUS WITH (NOLOCK) ON WF.CustomerId = CUS.CustomerId
				WHERE WF.WorkflowId = @WorkFlowId
			END
		COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
            ROLLBACK TRAN;
            DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateWorkFlowColumnsWithId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkFlowId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH    
END
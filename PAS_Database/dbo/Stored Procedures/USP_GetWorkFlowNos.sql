/*************************************************************           
 ** File:   [USP_GetWorkFlowNos]           
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to get the WorkFlowNumbers
 ** Date:   12-May-2025      
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				Author					Change Description            
 ** --   --------			-------				--------------------------------          
    1    12-May-2025		Devendra Shekh			Created

EXEC [USP_GetWorkFlowNos] 3, 10, 1, 101, 23
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWorkFlowNos]
 @PartId BIGINT = NULL,  
 @WorkScopeId BIGINT = NULL,
 @MasterCompanyId BIGINT = NULL,
 @CustomerId BIGINT = NULL,
 @workflowId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
			
			IF EXISTS(SELECT 1 FROM [dbo].[Workflow] WF WITH(NOLOCK) WHERE WF.CustomerId = @CustomerId AND WF.ItemMasterId = @PartId AND WF.WorkScopeId = @WorkScopeId AND WF.IsDeleted = 0 AND WF.IsActive = 1 AND ISNULL(WF.IsVersionIncrease, 0) = 0)
			BEGIN
				SELECT DISTINCT
					WorkFlowNo = wf.[WorkOrderNumber] + '_' + wf.[Version],
					WorkFlowId = wf.[WorkflowId],
					CustomerName = ISNULL(c.[Name], ''),
					PartNumber = im.[partnumber],
					im.[PartDescription],
					WorkScope = ws.[Description],
					Currency = cur.[DisplayName],
					ExpirationDate = wf.[WorkflowExpirationDate]
				FROM dbo.Workflow wf WITH (NOLOCK)
				LEFT JOIN dbo.Customer c WITH (NOLOCK) ON wf.CustomerId = c.CustomerId
				INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON wf.ItemMasterId = im.ItemMasterId
				INNER JOIN dbo.WorkScope ws WITH (NOLOCK) ON wf.WorkScopeId = ws.WorkScopeId
				INNER JOIN dbo.Currency cur WITH (NOLOCK) ON wf.CurrencyId = cur.CurrencyId
				WHERE	ISNULL(wf.IsDeleted, 0) = 0
						AND ISNULL(wf.IsVersionIncrease, 0) = 0
						AND wf.IsActive = 1
						AND wf.CustomerId = @CustomerId
						AND wf.ItemMasterId = @PartId
						AND wf.WorkScopeId = @WorkScopeId

				UNION

				SELECT DISTINCT
					WorkFlowNo = wf.[WorkOrderNumber] + '_' + wf.[Version],
					WorkFlowId = wf.[WorkflowId],
					CustomerName = ISNULL(c.[Name], ''),
					PartNumber = im.[partnumber],
					im.[PartDescription],
					WorkScope = ws.[Description],
					Currency = cur.[DisplayName],
					ExpirationDate = wf.[WorkflowExpirationDate]
				FROM dbo.Workflow wf WITH (NOLOCK)
				LEFT JOIN dbo.Customer c WITH (NOLOCK) ON wf.CustomerId = c.CustomerId
				INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON wf.ItemMasterId = im.ItemMasterId
				INNER JOIN dbo.WorkScope ws WITH (NOLOCK) ON wf.WorkScopeId = ws.WorkScopeId
				INNER JOIN dbo.Currency cur WITH (NOLOCK) ON wf.CurrencyId = cur.CurrencyId
				WHERE	ISNULL(wf.IsDeleted, 0) = 0
						AND wf.IsActive = 1
						AND wf.WorkflowId = @workflowId
			END
			ELSE
			BEGIN
				 SELECT DISTINCT
					WorkFlowNo = wf.[WorkOrderNumber] + '_' + wf.[Version],
					WorkFlowId = wf.[WorkflowId],
					CustomerName = ISNULL(c.[Name], ''),
					PartNumber = im.[partnumber],
					im.[PartDescription],
					WorkScope = ws.[Description],
					Currency = cur.[DisplayName],
					ExpirationDate = wf.[WorkflowExpirationDate]
				FROM dbo.Workflow wf WITH (NOLOCK)
				LEFT JOIN dbo.Customer c WITH (NOLOCK) ON wf.CustomerId = c.CustomerId
				INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON wf.ItemMasterId = im.ItemMasterId
				INNER JOIN dbo.WorkScope ws WITH (NOLOCK) ON wf.WorkScopeId = ws.WorkScopeId
				INNER JOIN dbo.Currency cur WITH (NOLOCK) ON wf.CurrencyId = cur.CurrencyId
				WHERE	ISNULL(wf.IsDeleted, 0) = 0
						AND ISNULL(wf.IsVersionIncrease, 0) = 0
						AND wf.IsActive = 1
						AND (wf.CustomerId IS NULL OR wf.CustomerId = @CustomerId)
						AND wf.ItemMasterId = @PartId
						AND wf.WorkScopeId = @WorkScopeId

				UNION

				SELECT DISTINCT
					WorkFlowNo = wf.[WorkOrderNumber] + '_' + wf.[Version],
					WorkFlowId = wf.[WorkflowId],
					CustomerName = ISNULL(c.[Name], ''),
					PartNumber = im.[partnumber],
					im.[PartDescription],
					WorkScope = ws.[Description],
					Currency = cur.[DisplayName],
					ExpirationDate = wf.[WorkflowExpirationDate]
				FROM dbo.Workflow wf WITH (NOLOCK)
				LEFT JOIN dbo.Customer c WITH (NOLOCK) ON wf.CustomerId = c.CustomerId
				INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON wf.ItemMasterId = im.ItemMasterId
				INNER JOIN dbo.WorkScope ws WITH (NOLOCK) ON wf.WorkScopeId = ws.WorkScopeId
				INNER JOIN dbo.Currency cur WITH (NOLOCK) ON wf.CurrencyId = cur.CurrencyId
				WHERE	ISNULL(wf.IsDeleted, 0) = 0
						AND wf.IsActive = 1
						AND wf.WorkflowId = @workflowId
			END

		END TRY    
		BEGIN CATCH      
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkFlowNos' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PartId, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

            exec spLogException 
                    @DatabaseName			= @DatabaseName
                    , @AdhocComments			= @AdhocComments
                    , @ProcedureParameters		= @ProcedureParameters
                    , @ApplicationName         = @ApplicationName
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END
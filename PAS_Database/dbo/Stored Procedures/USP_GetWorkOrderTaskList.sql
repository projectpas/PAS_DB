/*************************************************************             
** File:   [USP_GetWorkOrderTaskList]
** Author:   Vishal Suthar
** Description: This procedre is used to get work order task list data
** Purpose:
** Date:   12/18/2024
**************************************************************
** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------			----------------------
	1   12/18/2024   Vishal Suthar		Created

EXEC USP_GetWorkOrderTaskList 4670
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWorkOrderTaskList]
(
	@WorkOrderId BIGINT
)
AS
BEGIN
	BEGIN TRY 
	BEGIN
		
		;WITH CTE AS (
			SELECT 
			WOT.WorkOrderTaskId,
			WOT.TaskId,
			WOT.SequenceNumber,
			WOT.OpenDate,
			WOT.OpenBy,
			WOT.IsIncludeInPrint,
			WOT.HasInstruction,
			WOT.TaskName,
			WOT.MasterCompanyId,
			WOT.CreatedBy,
			WOT.CreatedDate,
			WOT.UpdatedBy,
			WOT.UpdatedDate
			FROM dbo.WorkOrderTask WOT WITH(NOLOCK)
			WHERE WOT.WorkOrderId = @WorkOrderId AND WOT.IsActive = 1 AND WOT.IsDeleted = 0
		)

		SELECT * INTO #LeafTempTbl FROM CTE

		SELECT * FROM #LeafTempTbl;
	END
	END TRY
	BEGIN CATCH
		SELECT        
		ERROR_NUMBER() AS ErrorNumber,        
		ERROR_STATE() AS ErrorState,        
		ERROR_SEVERITY() AS ErrorSeverity,        
		ERROR_PROCEDURE() AS ErrorProcedure,        
		ERROR_LINE() AS ErrorLine,        
		ERROR_MESSAGE() AS ErrorMessage;        
		IF @@trancount > 0        
		PRINT 'ROLLBACK'        
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()         
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------        
		, @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderTaskList'         
		, @ProcedureParameters VARCHAR(3000)  = '@WorkOrderId = ''' + CAST(ISNULL(@WorkOrderId, '') AS varchar(100))  
		, @ApplicationName VARCHAR(100) = 'PAS'        
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------        
		exec spLogException         
		@DatabaseName           = @DatabaseName        
		, @AdhocComments          = @AdhocComments        
		, @ProcedureParameters = @ProcedureParameters        
		, @ApplicationName        =  @ApplicationName        
		, @ErrorLogID             = @ErrorLogID OUTPUT ;        
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)        
		RETURN(1);
	END CATCH
END
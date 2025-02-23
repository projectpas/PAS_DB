/*************************************************************
 ** File:   [USP_GetWorkOrderTaskInstructionHistoryById]
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to GetWorkOrderTaskInstructionHistory by id
 ** Purpose:
 ** Date:   02/18/2025
    
 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    02/18/2025   Ekta Chandegra	Created

-- EXEC dbo.USP_GetWorkOrderTaskInstructionHistoryById @WorkOrderTaskInstructionId=1142
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWorkOrderTaskInstructionHistoryById]
@WorkOrderTaskInstructionId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
		BEGIN
			SELECT
				[WorkOrderTaskInstructionHistoryId]
				,[WorkOrderTaskInstructionId]
				,[WorkOrderTaskId]
				,[TaskId]
				,[TaskName]
				,[InstructionTitle]
				,[InstructionDetails]
				,[SequenceNumber]
				,[TechId]
				,[TechName]
				,[TechUpdatedDate]
				,[InspectorId]
				,[InspectorName]
				,[InspectorUpdatedDate]
				,[PrintInWO]
				,[PrintInWOQ]
				,[MasterCompanyId]
				,[UpdatedBy]
				,[UpdatedDate]
				,[IsActive]
				,[IsDeleted]
				,[ParentId]
				,[IsParent]
			FROM 
			[dbo].[WorkOrderTaskInstructionHistory] WITH(NOLOCK)
			WHERE WorkOrderTaskInstructionId = @WorkOrderTaskInstructionId
			ORDER BY UpdatedDate DESC
		END
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderTaskInstructionHistoryById'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@WorkOrderTaskInstructionId AS varchar(100)) ,'') +''

        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException
                @DatabaseName           =  @DatabaseName
                , @AdhocComments          =  @AdhocComments
                , @ProcedureParameters    =  @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID             =  @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END
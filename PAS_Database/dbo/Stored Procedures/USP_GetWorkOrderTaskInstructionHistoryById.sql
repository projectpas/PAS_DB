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
    2    04/28/2025   Ekta Chandegra	Retrieve ParentSequenceNumber

-- exec dbo.USP_GetWorkOrderTaskInstructionHistoryById @WorkOrderTaskInstructionId=2874
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
				WOTIH.[WorkOrderTaskInstructionHistoryId]
				,WOTIH.[WorkOrderTaskInstructionId]
				,WOTIH.[WorkOrderTaskId]
				,WOTIH.[TaskId]
				,WOTIH.[TaskName]
				,WOTIH.[InstructionTitle]
				,WOTIH.[InstructionDetails]
				,WOTIH.[SequenceNumber]
				,WOTIH.[TechId]
				,WOTIH.[TechName]
				,WOTIH.[TechUpdatedDate]
				,WOTIH.[InspectorId]
				,WOTIH.[InspectorName]
				,WOTIH.[InspectorUpdatedDate]
				,WOTIH.[PrintInWO]
				,WOTIH.[PrintInWOQ]
				,WOTIH.[MasterCompanyId]
				,WOTIH.[UpdatedBy]
				,WOTIH.[UpdatedDate]
				,WOTIH.[IsActive]
				,WOTIH.[IsDeleted]
				,WOTIH.[ParentId]
				,WOTIH.[IsParent]
				,WOTIH.[ParentSequenceNumber]
			FROM 
			[dbo].[WorkOrderTaskInstructionHistory] WOTIH WITH(NOLOCK)
			WHERE WOTIH.WorkOrderTaskInstructionId = @WorkOrderTaskInstructionId
			ORDER BY WOTIH.UpdatedDate DESC
			
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
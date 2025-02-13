/*************************************************************
 ** File:   [USP_AddWorkOrderTaskHistory]
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to AddWorkOrderTaskHistory by id
 ** Purpose:
 ** Date:   02/11/2025
    
 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    02/11/2025   Ekta Chandegra	Created

EXEC [dbo].[USP_AddWorkOrderTaskHistory] 95
**************************************************************/


CREATE   PROCEDURE [dbo].[USP_AddWorkOrderTaskHistory]
@WorkOrderTaskId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;
	BEGIN TRY  
		
		-- Insert data into WorkOrderTaskHistory
		INSERT INTO [dbo].[WorkOrderTaskHistory]
		(
			[WorkOrderTaskId], [TaskName], [Descrepancy], [Resolution], [TechId], 
			[TechName], [TechUpdatedDate], [InspectorId], [InspectorName], [InspectorUpdatedDate],
			[PrintInWO], [PrintInWOQ], [IsParent], [ParentId], [InstructionTitle], [InstructionDetails],
			[SequenceNumber],[IsActive], [IsDeleted], [UpdatedBy], [UpdatedDate]
		)
		SELECT 
			@WorkOrderTaskId, WOT.[TaskName], WOTD.[Descrepancy], WOTD.[Resolution], WOTD.[TechId],
			WOTD.[TechName], WOTD.[TechUpdatedDate], WOTD.[InspectorId], WOTD.[InspectorName], WOTD.[InspectorUpdatedDate],
			WOTD.[PrintInWO], WOTD.[PrintInWOQ], WOTI.[IsParent], WOTI.[ParentId], WOTI.[InstructionTitle], WOTI.[InstructionDetails],
			WOTI.[SequenceNumber],WOT.[IsActive], WOT.[IsDeleted], WOT.UpdatedBy, GETUTCDATE()
		FROM
			[dbo].[WorkOrderTask] WOT WITH (NOLOCK)
		LEFT JOIN [dbo].[WorkOrderTaskDetails] WOTD WITH (NOLOCK) ON WOTD.WorkOrderTaskId = WOT.WorkOrderTaskId
		LEFT JOIN [dbo].[WorkOrderTaskInstruction] WOTI WITH (NOLOCK) ON WOTI.WorkOrderTaskId = WOT.WorkOrderTaskId AND WOTI.IsParent = 1
		WHERE WOT.WorkOrderTaskId = @WorkOrderTaskId;

		SELECT Scope_Identity() AS 'WorkOrderTaskHistoryId';

	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_AddWorkOrderTaskHistory'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@WorkOrderTaskId AS varchar(10)) ,'') +''
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
END;
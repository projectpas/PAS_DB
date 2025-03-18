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
    2    03/17/2025   Ekta Chandegra	Add @CreatedBy parameter
    3    03/18/2025   Ekta Chandegra	Add Sequence number of Work order task instead of Work order task instruction

exec dbo.USP_AddWorkOrderTaskHistory @WorkOrderTaskId=978,@CreatedBy=N'EKTA CHANDEGRA'
**************************************************************/


CREATE   PROCEDURE [dbo].[USP_AddWorkOrderTaskHistory]
@WorkOrderTaskId BIGINT,
@CreatedBy VARCHAR(256)
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
			WOT.[SequenceNumber],WOT.[IsActive], WOT.[IsDeleted],@CreatedBy, GETUTCDATE()
		FROM
			[dbo].[WorkOrderTask] WOT WITH (NOLOCK)
		LEFT JOIN [dbo].[WorkOrderTaskDetails] WOTD WITH (NOLOCK) ON WOTD.WorkOrderTaskId = WOT.WorkOrderTaskId
		LEFT JOIN [dbo].[WorkOrderTaskInstruction] WOTI WITH (NOLOCK) ON WOTI.WorkOrderTaskId = WOT.WorkOrderTaskId AND (WOTI.IsParent = 1 OR (WOTI.IsParent = 0 AND WOTI.ParentId IS NULL))
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
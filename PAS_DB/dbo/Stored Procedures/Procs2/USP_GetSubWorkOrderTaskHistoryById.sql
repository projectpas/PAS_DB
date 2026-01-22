/*************************************************************
 ** File:   [USP_GetSubWorkOrderTaskHistoryById]
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to GetSubWorkOrderTaskHistoryById
 ** Purpose:
 ** Date:   03/28/2025
    
 ** PARAMETERS: @SubWorkOrderTaskId BIGINT 

 ** RETURN VALUE:

 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    03/28/2025   Ekta Chandegra	Created
    2    04/28/2025   Ekta Chandegra	Retrieve SubWorkOrderTaskInstructionSequence 

 exec dbo.USP_GetSubWorkOrderTaskHistoryById @SubWorkOrderTaskId=10
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetSubWorkOrderTaskHistoryById]
	@SubWorkOrderTaskId BIGINT 
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT 
			[SubWorkOrderTaskHistoryId],
			[SubWorkOrderTaskId],
			[TaskName],
			[Descrepancy],
			[Resolution],
			[TechId],
			[TechName],
			[TechUpdatedDate],
			[InspectorId],
			[InspectorName],
			[InspectorUpdatedDate],
			[PrintInWO],
			[PrintInWOQ],
			[IsParent],
			[ParentId],
			[InstructionTitle],
			[InstructionDetails],
			[SequenceNumber],
			[IsActive],
			[IsDeleted],
			[UpdatedBy],
			[UpdatedDate],
			[SubWorkOrderTaskInstructionId],
			[SubWorkOrderTaskInstructionTechId], 
			[SubWorkOrderTaskInstructionTechName],
			[SubWorkOrderTaskInstructionTechUpdatedDate],
			[SubWorkOrderTaskInstructionInspectorId], 
			[SubWorkOrderTaskInstructionInspectorName],
			[SubWorkOrderTaskInstructionInspectorUpdatedDate] ,
			[SubWorkOrderTaskInstructionPrintInWO], 
			[SubWorkOrderTaskInstructionPrintInWOQ],
			[SubWorkOrderTaskInstructionSequence]
		FROM [dbo].[SubWorkOrderTaskHistory] WITH(NOLOCK)
		WHERE SubWorkOrderTaskId = @SubWorkOrderTaskId
		ORDER BY SubWorkOrderTaskHistoryId DESC
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetSubWorkOrderTaskHistoryById'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@SubWorkOrderTaskId AS varchar(10)) ,'') +''
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
/*************************************************************
 ** File:   [USP_GetWorkOrderTaskHistoryById]
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to GetWorkOrderTaskHistoryById
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
	2    02/25/2025   Ekta Chandegra	Retrieve Task instruction details
	3    04/03/2025   Bhargav Saliya	UTC Date Changes
	4    04/28/2025   Ekta Chandegra	Retrieve WorkOrderTaskInstructionSequence 

 EXEC USP_GetWorkOrderTaskHistoryById 146
**************************************************************/

CREATE     PROCEDURE [dbo].[USP_GetWorkOrderTaskHistoryById]
	@WorkOrderTaskId BIGINT,
	@EmployeeId BIGINT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
			LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId; 

		SELECT 
			[WorkOrderTaskHistoryId],
			[WorkOrderTaskId],
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
			CASE WHEN CAST([UpdatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal([UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME))END [UpdatedDate],
			[WorkOrderTaskInstructionId],
			[WorkOrderTaskInstructionTechId], 
			[WorkOrderTaskInstructionTechName],
			[WorkOrderTaskInstructionTechUpdatedDate],
			[WorkOrderTaskInstructionInspectorId], 
			[WorkOrderTaskInstructionInspectorName],
			[WorkOrderTaskInstructionInspectorUpdatedDate] ,
			[WorkOrderTaskInstructionPrintInWO], 
			[WorkOrderTaskInstructionPrintInWOQ],
			[WorkOrderTaskInstructionSequence]
		FROM [dbo].[WorkOrderTaskHistory] WITH(NOLOCK)
		WHERE WorkOrderTaskId = @WorkOrderTaskId
		ORDER BY UpdatedDate DESC
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderTaskHistoryById'
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
END
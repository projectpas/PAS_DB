/*************************************************************             
** File:   [USP_GetWorkOrderTaskInstructionList]
** Author:   Vishal Suthar
** Description: This procedre is used to get work order task instruction list data
** Purpose:
** Date:   01/02/2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------			----------------------
	1   01/02/2025   Vishal Suthar		Created
	2   03/Fwb/2025  RAJESH GAMI		added @WorkOrderPartNumberId and their functionality
	4	04/Mar/2025	 Bhargav Saliya		UTC Date Changes
EXEC USP_GetWorkOrderTaskInstructionList 4674, 0, 0
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWorkOrderTaskInstructionList]
(
	@WorkOrderId BIGINT,
	@WorkOrderTaskId BIGINT = NULL,
	@FetchTaskOrInstruction BIT = 0,
	@WorkOrderPartNumberId BIGINT = 0,
	@EmployeeId BIGINT = 0
)
AS
BEGIN
	BEGIN TRY 
	BEGIN

		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
			LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId; 

		IF(@WorkOrderPartNumberId > 0)
		BEGIN
				IF (ISNULL(@FetchTaskOrInstruction, 0) = 0)
				BEGIN
					;WITH CTE AS (
						SELECT DISTINCT
						WOT.WorkOrderTaskId,
						WOT.WorkOrderId,
						WOT.WorkOrderPartNumberId,
						WOT.WorkFlowWorkOrderId,
						WOT.TaskId,
						WOT.SequenceNumber,
						WOT.OpenDate,
						WOT.OpenBy,
						WOT.IsIncludeInPrint,
						WOT.HasInstruction,
						WOT.TaskName,
						WOTD.TechId,
						WOTD.TechName,
						WOTD.TechUpdatedDate,
						WOTD.InspectorId,
						WOTD.InspectorName,
						WOTD.InspectorUpdatedDate,
						WOTD.Descrepancy,
						WOTD.Resolution,
						WOT.MasterCompanyId,
						WOT.CreatedBy,
						CASE WHEN CAST(WOT.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(WOT.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END CreatedDate,
						WOT.UpdatedBy,
						CASE WHEN CAST(WOT.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(WOT.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END UpdatedDate
						FROM dbo.WorkOrderTask WOT WITH(NOLOCK)
						INNER JOIN dbo.WorkOrderTaskDetails WOTD WITH(NOLOCK) ON WOT.WorkOrderTaskId = WOTD.WorkOrderTaskId
						INNER JOIN dbo.WorkOrderTaskInstruction WOTI WITH(NOLOCK) ON WOTI.WorkOrderTaskId = WOT.WorkOrderTaskId
						WHERE WOT.WorkOrderId = @WorkOrderId AND WOT.IsActive = 1 AND WOT.IsDeleted = 0 AND WOT.WorkOrderPartNumberId = @WorkOrderPartNumberId
					)

					SELECT * INTO #LeafTaskTempTbl FROM CTE

					SELECT * FROM #LeafTaskTempTbl ORDER BY SequenceNumber;
				END
				ELSE
				BEGIN
					;WITH CTE AS (
						SELECT 
						WOTI.WorkOrderTaskInstructionId,
						WOTI.WorkOrderTaskId,
						WOTI.ParentId,
						WOTI.IsParent,
						WOT.TaskId,
						WOT.TaskName,
						WOTI.InstructionTitle,
						WOTI.SequenceNumber,
						WOTI.InstructionDetails,
						WOTI.TechId,
						WOTI.TechName,
						WOTI.TechUpdatedDate,
						WOTI.InspectorId,
						WOTI.InspectorName,
						WOTI.InspectorUpdatedDate,
						WOTI.PrintInWO,
						WOTI.PrintInWOQ,
						WOTI.MasterCompanyId,
						WOTI.CreatedBy,
						WOTI.UpdatedBy,
						CASE WHEN CAST(WOT.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(WOT.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END CreatedDate,
						CASE WHEN CAST(WOT.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(WOT.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END UpdatedDate,
						WOTI.IsActive,
						WOTI.IsDeleted 
						FROM dbo.WorkOrderTaskInstruction WOTI WITH(NOLOCK)
						INNER JOIN dbo.WorkOrderTask WOT WITH(NOLOCK) ON WOT.WorkOrderTaskId = WOTI.WorkOrderTaskId
						WHERE WOT.WorkOrderId = @WorkOrderId
						AND WOTI.WorkOrderTaskId = @WorkOrderTaskId
						AND WOT.IsActive = 1 AND WOT.IsDeleted = 0 AND WOT.WorkOrderPartNumberId = @WorkOrderPartNumberId
					)

					SELECT * INTO #LeafTempTbl FROM CTE

					SELECT * FROM #LeafTempTbl ORDER BY SequenceNumber;
			END
		END
		ELSE
		BEGIN
			IF (ISNULL(@FetchTaskOrInstruction, 0) = 0)
				BEGIN
					;WITH CTE AS (
						SELECT DISTINCT
						WOT.WorkOrderTaskId,
						WOT.WorkOrderId,
						WOT.WorkOrderPartNumberId,
						WOT.WorkFlowWorkOrderId,
						WOT.TaskId,
						WOT.SequenceNumber,
						WOT.OpenDate,
						WOT.OpenBy,
						WOT.IsIncludeInPrint,
						WOT.HasInstruction,
						WOT.TaskName,
						WOTD.TechId,
						WOTD.TechName,
						WOTD.TechUpdatedDate,
						WOTD.InspectorId,
						WOTD.InspectorName,
						WOTD.InspectorUpdatedDate,
						WOTD.Descrepancy,
						WOTD.Resolution,
						WOT.MasterCompanyId,
						WOT.CreatedBy,
						WOT.CreatedDate,
						WOT.UpdatedBy,
						WOT.UpdatedDate
						FROM dbo.WorkOrderTask WOT WITH(NOLOCK)
						INNER JOIN dbo.WorkOrderTaskDetails WOTD WITH(NOLOCK) ON WOT.WorkOrderTaskId = WOTD.WorkOrderTaskId
						INNER JOIN dbo.WorkOrderTaskInstruction WOTI WITH(NOLOCK) ON WOTI.WorkOrderTaskId = WOT.WorkOrderTaskId
						WHERE WOT.WorkOrderId = @WorkOrderId AND WOT.IsActive = 1 AND WOT.IsDeleted = 0
					)

					SELECT * INTO #LeafTempTblELSETbls FROM CTE

					SELECT * FROM #LeafTempTblELSETbls ORDER BY SequenceNumber;
				END
				ELSE
				BEGIN
					;WITH CTE AS (
						SELECT 
						WOTI.WorkOrderTaskInstructionId,
						WOTI.WorkOrderTaskId,
						WOTI.ParentId,
						WOTI.IsParent,
						WOT.TaskId,
						WOT.TaskName,
						WOTI.InstructionTitle,
						WOTI.SequenceNumber,
						WOTI.InstructionDetails,
						WOTI.TechId,
						WOTI.TechName,
						WOTI.TechUpdatedDate,
						WOTI.InspectorId,
						WOTI.InspectorName,
						WOTI.InspectorUpdatedDate,
						WOTI.PrintInWO,
						WOTI.PrintInWOQ,
						WOTI.MasterCompanyId,
						WOTI.CreatedBy,
						WOTI.UpdatedBy,
						WOTI.CreatedDate,
						WOTI.UpdatedDate,
						WOTI.IsActive,
						WOTI.IsDeleted 
						FROM dbo.WorkOrderTaskInstruction WOTI WITH(NOLOCK)
						INNER JOIN dbo.WorkOrderTask WOT WITH(NOLOCK) ON WOT.WorkOrderTaskId = WOTI.WorkOrderTaskId
						WHERE WOT.WorkOrderId = @WorkOrderId
						AND WOTI.WorkOrderTaskId = @WorkOrderTaskId
						AND WOT.IsActive = 1 AND WOT.IsDeleted = 0
					)

					SELECT * INTO #LeafTempTblELSETbl FROM CTE

					SELECT * FROM #LeafTempTblELSETbl ORDER BY SequenceNumber;
				END
	
			END
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
		, @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderTaskInstructionList'         
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
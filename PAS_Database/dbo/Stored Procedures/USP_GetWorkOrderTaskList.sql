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
	2   03/Fwb/2025  RAJESH GAMI		added @WorkOrderPartNumberId and their functionality
	3   10/Feb/2025  RAJESH GAMI		Added Return IsPrintInspector,IsPrintTechnician
	4   10/Feb/2025  Devendra Shekh		Added WorkOrderTaskDetailsId to select
	5	04/Mar/2025	 Bhargav Saliya		UTC Date Changes

EXEC USP_GetWorkOrderTaskList 4670
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWorkOrderTaskList]
(
	@WorkOrderId BIGINT,
	@WorkOrderPartNumberId BIGINT = 0,
	@EmployeeId BIGINT = 0
)
AS
BEGIN
	BEGIN TRY 

		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
			LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId; 

	BEGIN
		IF(@WorkOrderPartNumberId > 0)
		BEGIN
			;WITH CTE AS (
			SELECT 
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
			CASE WHEN CAST(WOT.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(WOT.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END UpdatedDate,
			ISNULL(WOTD.PrintInWO,0) PrintInWO,
			ISNULL(WOTD.PrintInWOQ,0) PrintInWOQ,
			ISNULL(WOTD.IsPrintInspector,0) IsPrintInspector,
			ISNULL(WOTD.IsPrintTechnician,0)IsPrintTechnician,
			WOTD.WorkOrderTaskDetailsId,
				CASE WHEN EXISTS (SELECT TOP 1 1 FROM DBO.Attachment ATT WITH (NOLOCK) INNER JOIN DBO.AttachmentModule ATTM WITH (NOLOCK) ON ATTM.AttachmentModuleId = ATT.ModuleId WHERE ATTM.[Name] = 'WorkOrderTask' AND ATT.ReferenceId = WOT.WorkOrderTaskId) THEN 1 ELSE 0 END AS IsDocumentAdded
			FROM dbo.WorkOrderTask WOT WITH(NOLOCK)
			INNER JOIN dbo.WorkOrderTaskDetails WOTD WITH(NOLOCK) ON WOT.WorkOrderTaskId = WOTD.WorkOrderTaskId
			WHERE WOT.WorkOrderId = @WorkOrderId AND WOT.IsActive = 1 AND WOT.IsDeleted = 0 AND ISNULL(WOT.WorkOrderPartNumberId,0) = @WorkOrderPartNumberId
			)
			SELECT * INTO #LeafTempTbl FROM CTE
			SELECT * FROM #LeafTempTbl ORDER BY SequenceNumber;
		END
		ELSE
		BEGIN
			;WITH CTE AS (
			SELECT 
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
			CASE WHEN CAST(WOT.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(WOT.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END UpdatedDate,
			ISNULL(WOTD.PrintInWO,0) PrintInWO,
			ISNULL(WOTD.PrintInWOQ,0) PrintInWOQ,
			ISNULL(WOTD.IsPrintInspector,0) IsPrintInspector,
			ISNULL(WOTD.IsPrintTechnician,0)IsPrintTechnician,
			WOTD.WorkOrderTaskDetailsId,
				CASE WHEN EXISTS (SELECT TOP 1 1 FROM DBO.Attachment ATT WITH (NOLOCK) INNER JOIN DBO.AttachmentModule ATTM WITH (NOLOCK) ON ATTM.AttachmentModuleId = ATT.ModuleId WHERE ATTM.[Name] = 'WorkOrderTask' AND ATT.ReferenceId = WOT.WorkOrderTaskId) THEN 1 ELSE 0 END AS IsDocumentAdded
			FROM dbo.WorkOrderTask WOT WITH(NOLOCK)
			INNER JOIN dbo.WorkOrderTaskDetails WOTD WITH(NOLOCK) ON WOT.WorkOrderTaskId = WOTD.WorkOrderTaskId
			WHERE WOT.WorkOrderId = @WorkOrderId AND WOT.IsActive = 1 AND WOT.IsDeleted = 0
			)

			SELECT * INTO #LeafTempTblElse FROM CTE
			SELECT * FROM #LeafTempTblElse ORDER BY SequenceNumber;
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
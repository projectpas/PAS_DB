/*************************************************************             
** File:   [USP_GetSubWorkOrderTaskList]
** Author:   Vishal Suthar
** Description: This procedre is used to get work order task list data
** Purpose:
** Date:   03/18/2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------			----------------------
	1   03/18/2025   Vishal Suthar		Created

EXEC USP_GetSubWorkOrderTaskList 4670
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetSubWorkOrderTaskList]
(
	@SubWorkOrderId BIGINT,
	@SubWorkOrderPartNumberId BIGINT = 0
)
AS
BEGIN
	BEGIN TRY 
	BEGIN
		IF (@SubWorkOrderPartNumberId > 0)
		BEGIN
			;WITH CTE AS (
			SELECT 
			WOT.SubWorkOrderTaskId,
			WOT.WorkOrderId,
			WOT.SubWOPartNoId SubWorkOrderPartNumberId,
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
			WOT.UpdatedDate,
			ISNULL(WOTD.PrintInWO,0) PrintInWO,
			ISNULL(WOTD.PrintInWOQ,0) PrintInWOQ,
			ISNULL(WOTD.IsPrintInspector,0) IsPrintInspector,
			ISNULL(WOTD.IsPrintTechnician,0)IsPrintTechnician,
			WOTD.SubWorkOrderTaskDetailsId,
			CASE WHEN EXISTS (SELECT TOP 1 1 FROM DBO.Attachment ATT WITH (NOLOCK) INNER JOIN DBO.AttachmentModule ATTM WITH (NOLOCK) ON ATTM.AttachmentModuleId = ATT.ModuleId WHERE ATTM.[Name] = 'WorkOrderTask' AND ATT.ReferenceId = WOT.SubWorkOrderTaskId) THEN 1 ELSE 0 END AS IsDocumentAdded
			FROM dbo.SubWorkOrderTask WOT WITH(NOLOCK)
			INNER JOIN dbo.SubWorkOrderTaskDetails WOTD WITH(NOLOCK) ON WOT.SubWorkOrderTaskId = WOTD.SubWorkOrderTaskId
			WHERE WOT.SubWorkOrderId = @SubWorkOrderId AND WOT.IsActive = 1 AND WOT.IsDeleted = 0 AND ISNULL(WOT.SubWOPartNoId,0) = @SubWorkOrderPartNumberId
			)
			SELECT * INTO #LeafTempTbl FROM CTE
			SELECT * FROM #LeafTempTbl ORDER BY SequenceNumber;
		END
		ELSE
		BEGIN
			;WITH CTE AS (
			SELECT 
			WOT.SubWorkOrderTaskId,
			WOT.WorkOrderId,
			WOT.SubWOPartNoId SubWorkOrderPartNumberId,
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
			WOT.UpdatedDate,
			ISNULL(WOTD.PrintInWO,0) PrintInWO,
			ISNULL(WOTD.PrintInWOQ,0) PrintInWOQ,
			ISNULL(WOTD.IsPrintInspector,0) IsPrintInspector,
			ISNULL(WOTD.IsPrintTechnician,0)IsPrintTechnician,
			WOTD.SubWorkOrderTaskDetailsId,
				CASE WHEN EXISTS (SELECT TOP 1 1 FROM DBO.Attachment ATT WITH (NOLOCK) INNER JOIN DBO.AttachmentModule ATTM WITH (NOLOCK) ON ATTM.AttachmentModuleId = ATT.ModuleId WHERE ATTM.[Name] = 'WorkOrderTask' AND ATT.ReferenceId = WOT.SubWorkOrderTaskId) THEN 1 ELSE 0 END AS IsDocumentAdded
			FROM dbo.SubWorkOrderTask WOT WITH(NOLOCK)
			INNER JOIN dbo.SubWorkOrderTaskDetails WOTD WITH(NOLOCK) ON WOT.SubWorkOrderTaskId = WOTD.SubWorkOrderTaskId
			WHERE WOT.SubWorkOrderId = @SubWorkOrderId AND WOT.IsActive = 1 AND WOT.IsDeleted = 0
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
		, @AdhocComments     VARCHAR(150)    = 'USP_GetSubWorkOrderTaskList'         
		, @ProcedureParameters VARCHAR(3000)  = '@WorkOrderId = ''' + CAST(ISNULL(@SubWorkOrderId, '') AS varchar(100))  
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
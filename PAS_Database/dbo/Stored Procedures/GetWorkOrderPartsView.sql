/*************************************************************           
 ** File:   [USP_GetWorkOrderPartsView]           
 ** Author:   Abhishek Jirawla
 ** Description: Get work order parts view
 ** Purpose:         
 ** Date:   08-APR-2025  
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    08-APR-2025   Abhishek Jirawla	Created
    2    15-APR-2025   RAJESH GAMI 	    Added Order By (WO Part Id Ascending)
    3    17-APR-2025   Abhishek Jirawla Adding Item Group and other modifications
	4    10-JUL-2025   Moin Bloch       Added PublicationNotes
	5    11-Jul-2025   Devendra Shekh   added PartNumberLabel
	6    18-JUL-2025   Moin Bloch       Removed CorrectiveActionCode From Where clause No Need
	7    06-JAN-2026   Amit Ghediya     Return MAsterCompanyId for Previously, the memo was hidden only for the MTI company; it is now hidden for all other companies except NEO. 
	8    11-MAR-2026   Moin Bloch       added IncomingPartNumber For Quote MPN PN-15719
	9    23-MAR-2026   Ayushi Patel     PN-15825 added lineNum
	10    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	11    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
 EXECUTE [GetWorkOrderPartsView] 9756
**************************************************************/ 
CREATE PROCEDURE [dbo].[GetWorkOrderPartsView]
@WorkOrderId INT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @PendingStatusId INT, @PendingStatusName VARCHAR(20), @ApprovedStatusId INT, @WaitingForApprovalStatusId INT;
		DECLARE @CorrectiveActionCode VARCHAR(100) = 'CRA';

		SELECT @PendingStatusId = [ApprovalStatusId], @PendingStatusName = [Name] FROM [dbo].[ApprovalStatus] WITH (NOLOCK) WHERE [Name] = 'Pending'
		SELECT @ApprovedStatusId = [ApprovalStatusId] FROM [dbo].[ApprovalStatus] WITH (NOLOCK) WHERE [Name] = 'Approved'
		SELECT @WaitingForApprovalStatusId = [ApprovalStatusId] FROM [dbo].[ApprovalStatus] WITH (NOLOCK) WHERE [Name] = 'Waiting for Approval'

		DECLARE @SubmitInternalApprovalProcessId INT, @SubmitCustomerApprovalProcessId INT, @SentForInternalApprovalProcessId INT, @SentForCustomerApprovalProcessId INT, @ApprovedProcessId INT

		SELECT @SubmitInternalApprovalProcessId = [ApprovalProcessId] FROM [dbo].[ApprovalProcess] WITH (NOLOCK) WHERE  [Name] = 'SubmitInternalApproval'
		SELECT @SubmitCustomerApprovalProcessId = [ApprovalProcessId] FROM [dbo].[ApprovalProcess] WITH (NOLOCK) WHERE  [Name] = 'SubmitCustomerApproval'
		SELECT @SentForInternalApprovalProcessId = [ApprovalProcessId] FROM [dbo].[ApprovalProcess] WITH (NOLOCK) WHERE [Name] = 'SentForInternalApproval'
		SELECT @SentForCustomerApprovalProcessId = [ApprovalProcessId] FROM [dbo].[ApprovalProcess] WITH (NOLOCK) WHERE [Name] = 'SentForCustomerApproval'
		SELECT @ApprovedProcessId = [ApprovalProcessId] FROM [dbo].[ApprovalProcess] WITH (NOLOCK) WHERE [Name] = 'Approved'

		DECLARE @WorkOrderMPNModuleId INT

		SELECT @WorkOrderMPNModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH (NOLOCK) WHERE [ModuleName] = 'WorkOrderMPN'

		SELECT DISTINCT
		    Wop.[ID],
			wop.ManagementStructureId,
			wop.ItemMasterId AS itemMasterId,
			COALESCE(NULLIF(wop.[RevisedPartNumber], ''), im.[PartNumber]) AS [PartNumber],
			COALESCE(NULLIF(wop.[RevisedPartDescription], ''), im.[PartDescription]) AS [PartDescription],
			COALESCE(NULLIF(wop.[RevisedSerialNumber], ''), sl.[SerialNumber]) AS [SerialNumber],
			im.[ManufacturerName],
			im.[RevisedPart] AS [RevisedPartNo],
			ig.[Description] AS [ItemGroup],
			wop.[CMMIds],
			wop.[WorkflowId],
			wop.[NTE],
			con.[Description] AS [Condition],
			sl.[StockLineNumber] AS [StockLine],
			wop.[PublicationNo] AS [PublicationId],
			CONCAT(wos.[Code], '-', wos.[Stage]) AS [WorkOrderStage],
			CASE
				WHEN wopp.[ApprovalActionId] = CAST(@SubmitInternalApprovalProcessId AS INT) THEN appsI.[Description]
				WHEN wopp.[ApprovalActionId] = CAST(@SubmitCustomerApprovalProcessId AS INT) THEN appsC.[Description]
				WHEN wopp.[ApprovalActionId] = CAST(@ApprovedProcessId AS INT) THEN appsC.[Description]
				WHEN wopp.[ApprovalActionId] = CAST(@SentForInternalApprovalProcessId AS INT) THEN COALESCE(appsI.[Description], appsA.[Description])
				WHEN wopp.[ApprovalActionId] = CAST(@SentForCustomerApprovalProcessId AS INT) THEN COALESCE(appsC.[Description], appsA.[Description])
			ELSE CAST(@PendingStatusName AS VARCHAR(20))
			END AS [WorkOrderStatus],
			pr.[Description] AS [Priority],
			wop.[CustomerRequestDate],
			wop.[PromisedDate],
			wop.[EstimatedShipDate],
			wop.[EstimatedCompletionDate],
			wop.[IsDER],
			wop.[IsPMA],
			CONCAT(tech.[FirstName], ' ', tech.[LastName]) AS [Technician],
			wop.[TATDaysCurrent],
			wop.[TATDaysStandard],
			ws.[Description] AS [WorkScope],
			wop.[WorkOrderId],
			rc.[ReceivedDate],
			rc.[Reference] AS [RefNo],
			CASE WHEN wop.[IsMPNContract] = 1 THEN 'Yes' ELSE 'No' END AS [Contract],
			wop.[Quantity],
			CONCAT(wf.[WorkOrderNumber], '_', wf.[Version]) AS [WorkFlowNo],
			ts.[StationName] AS [TechStation],
			ISNULL(wop.[ContractNo], '') AS [ContractNo],
			wop.[PublicationNotes]  AS [NotesSection],
			wowf.[WorkFlowWorkOrderId],
			0 AS [CommonWorkOrderTearDownId],
			msd.[AllMSlevels],
			msd.[LastMSLevel],
			CASE	WHEN ISNULL(wop.[RevisedPartNumber], '') != '' AND ISNULL(wop.[RevisedSerialNumber], '') != '' THEN wop.[RevisedPartNumber] + '-' + wop.[RevisedSerialNumber]
					WHEN ISNULL(wop.[RevisedPartNumber], '') != '' THEN wop.[RevisedPartNumber] + '-' + sl.[ControlNumber] ELSE wop.[partnumber] + '-' + sl.[ControlNumber] END AS [PartNumberLabel],
			wop.MasterCompanyId,
			wop.IncomingPartNumber,
			ROW_NUMBER() OVER (ORDER BY wop.ID) AS lineNum
		FROM [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK)
		INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH (NOLOCK) ON wop.[ID] = wowf.[WorkOrderPartNoId]
		INNER JOIN [dbo].[WorkOrderManagementStructureDetails] msd WITH (NOLOCK) ON wop.[ID] = msd.[ReferenceID] AND msd.[ModuleID] = @WorkOrderMPNModuleId
		INNER JOIN [dbo].[Priority] pr WITH (NOLOCK) ON wop.[WorkOrderPriorityId] = pr.[PriorityId]
		INNER JOIN [dbo].[WorkScope] ws WITH (NOLOCK) ON wop.[WorkOrderScopeId] = ws.[WorkScopeId]
		INNER JOIN [dbo].[ItemMaster] im WITH (NOLOCK) ON wop.[ItemMasterId] = im.[ItemMasterId]
		 LEFT JOIN [dbo].[ItemMaster] im1 WITH (NOLOCK) ON im.[RevisedPartId] = im1.[ItemMasterId]
		  AND ISNULL(im1.IsNonStock,0) = 0
		  LEFT JOIN [dbo].[ItemGroup] ig WITH (NOLOCK) ON im.[ItemGroupId] = ig.[ItemGroupId]
		INNER JOIN [dbo].[WorkOrderStage] wos WITH (NOLOCK) ON wop.[WorkOrderStageId] = wos.[WorkOrderStageId]
		INNER JOIN [dbo].[WorkOrderStatus] wost WITH (NOLOCK) ON wop.[WorkOrderStatusId] = wost.[Id]
		 LEFT JOIN [dbo].[WorkOrderApproval] wopp WITH (NOLOCK) ON wop.[ID] = wopp.[WorkOrderPartNoId]
		 LEFT JOIN [dbo].[ApprovalStatus] appsI WITH (NOLOCK) ON wopp.[InternalStatusId] = appsI.[ApprovalStatusId]
		 LEFT JOIN [dbo].[ApprovalStatus] appsA WITH (NOLOCK) ON CAST(@WaitingForApprovalStatusId AS INT) = appsA.[ApprovalStatusId]
		 LEFT JOIN [dbo].[ApprovalStatus] appsC WITH (NOLOCK) ON wopp.[CustomerStatusId] = appsC.[ApprovalStatusId]
		 LEFT JOIN [dbo].[Condition] con WITH (NOLOCK) ON wop.[ConditionId] = con.[ConditionId]
		 LEFT JOIN [dbo].[StockLine] sl WITH (NOLOCK) ON wop.[StockLineId] = sl.[StockLineId] AND ISNULL(sl.IsNonStock,0) = 0
		 LEFT JOIN [dbo].[Employee] tech WITH (NOLOCK) ON wop.[TechnicianId] = tech.[EmployeeId]
		 LEFT JOIN [dbo].[ReceivingCustomerWork] rc WITH (NOLOCK) ON sl.[StockLineId] = rc.[StockLineId]
		 LEFT JOIN [dbo].[Workflow] wf WITH (NOLOCK) ON wop.[WorkflowId] = wf.[WorkflowId]
		 LEFT JOIN [dbo].[EmployeeStation] ts WITH (NOLOCK) ON wop.[TechStationId] = ts.[EmployeeStationId]
		--LEFT JOIN dbo.CommonWorkOrderTeardown cmot WITH (NOLOCK) ON wowf.WorkFlowWorkOrderId = cmot.WorkFlowWorkOrderId AND wop.WorkOrderId = cmot.WorkOrderId
		--LEFT JOIN dbo.CommonTeardownType cm WITH (NOLOCK) ON cmot.CommonTeardownTypeId = cm.CommonTeardownTypeId AND cmot.MasterCompanyId = cm.MasterCompanyId
		WHERE wop.WorkOrderId = @WorkOrderId
		  AND wop.IsDeleted = 0
		  --AND (cm.Name IS NULL OR cm.Code = @CorrectiveActionCode)
		 AND ISNULL(im.IsNonStock,0) = 0
		   ORDER BY Wop.ID

	END TRY    
	BEGIN CATCH      

		DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetWorkOrderPartsView'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS varchar(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END;
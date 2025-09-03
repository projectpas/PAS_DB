/************************************************************************************           
 ** File:   [USP_GetWorkOrderSettings]           
 ** Author: 
 ** Description: This stored procedure is used to get USP_GetWorkOrderSettings.
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************************************           
  ** Change History           
 **************************************************************************************           
 ** PR    Date					Author				Change Description            
 ** --    --------			-----------				--------------------------------          
	 1    4-29-2025			Amit Ghediya			Created
	 2	  05-MAY-2025		Divyesh Kathiriya		Add EnforceMpnPickTicketConfirmation Flag
	 3	  13-MAY-2025		Bhargav Saliya			Added IsDisplayFooter to select 
	 4	  23-MAY-2025		Devendra Shekh			Added isPNSNWarning, isPNSNRestriction to select 
	 5	  28-Aug-2025		Moin Bloch			    Added IsAllowEmployeeToMoreTask

	 EXEC [dbo].[USP_GetWorkOrderSettings] 1,1
****************************************************************************************/
CREATE    PROCEDURE [dbo].[USP_GetWorkOrderSettings]
	@WorkOrderTypeId BIGINT,
	@MasterCompanyId BIGINT = NULL
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY

				SELECT 
					wos.workOrderSettingId,
					wos.workOrderTypeId,
					wot.Description AS workOrderType,
					wos.tearDownTypes,
					wos.masterCompanyId,
					wos.isActive,
					wos.createdBy,
					wos.createdDate,
					wos.updatedBy,
					wos.updatedDate,
					wos.dualreleaselanguage,
					ISNULL(wos.IsApprovalRule, 0) AS isApprovalRule,
					ISNULL(wos.Isshortteardown, 0) AS isshortteardown,
					ISNULL(rlrb.ReceivingListRBId, 0) AS recivingListDefaultRB,
					rlrb.Description AS recivingListDefault,
					ISNULL(c.ConditionId, 0) AS defaultConditionId,
					c.Description AS defaultConditon,
					ISNULL(s.SiteId, 0) AS defaultSiteId,
					s.Name AS defaultSite,
					ISNULL(wh.WarehouseId, 0) AS defaultWearhouseId,
					wh.Name AS defaultWarehouse,
					ISNULL(l.LocationId, 0) AS defaultLocationId,
					l.Name AS defaultLocation,
					ISNULL(sh.ShelfId, 0) AS defaultShelfId,
					sh.Name AS defaultShelf,
					ISNULL(bn.BinId, 0) AS defaultBinId,
					bn.Name AS defaultBin,
					ISNULL(st.WorkOrderStageId, 0) AS defaultStageCodeId,
					st.Stage AS defaultStageCode,
					ISNULL(sc.WorkScopeId, 0) AS defaultScopeId,
					sc.Description AS defaultScope,
					ISNULL(sta.Id, 0) AS defaultStatusId,
					sta.Description AS defaultStatus,
					ISNULL(pr.PriorityId, 0) AS defaultPriorityId,
					pr.Description AS defaultPriority,
					ISNULL(df.ProvisionId, 0) AS defaultProvisionId,
					df.Description AS defaultProvision,
					ISNULL(dt.TaskId, 0) AS defaultTaskId,
					dt.Description AS defaultTask,
					ISNULL(wb.WOListRBId, 0) AS woListViewRBId,
					wb.Name AS woListDefault,
					ISNULL(ss.Id, 0) AS settingStatusId,
					ss.Description AS settingStatus,
					ISNULL(wb1.WOListRBId, 0) AS woListStatusRBId,
					wb1.Name AS woListStatusDefault,
					ISNULL(wos.LaborHoursMedthodId, 0) AS laborHoursMedthodId,
					wos.enforcePickTicket,
					wos.pickTicketEffectiveDate,
					wos.standardTurntimeDays,
					wos.standardTurntimecolour,
					wos.isTraveler,
					wos.isAutoReserve,
					wos.isAutoIssue,
					wos.isManualForm,
					wos.laborlogoffHours,
					ISNULL(wos.WOStages, '') AS woStages,
					ISNULL(wos.AllowInvoiceBeforeShipping, 0) AS allowInvoiceBeforeShipping,
					wos.capesRestrictionAtReceiving,
					wos.cmmRestrictionAtReceiving,
					wos.cmmWarningAtReceiving,
					wos.cmmWarningAtShipping,
					wos.cmmRestrictionAtShipping,
					CASE WHEN ISNULL(wos.CMMWarningAtShipping, 0) = 0 AND ISNULL(wos.CMMRestrictionAtShipping, 0) = 0 THEN 1 ELSE wos.byPassCMMSettingAtShipping END byPassCMMSettingAtShipping,
					wos.capesRestrictionAtShipping,
					wos.capesWarningAtReceiving,
					wos.capesWarningAtShipping,
					CASE WHEN ISNULL(wos.capesWarningAtShipping, 0) = 0 AND ISNULL(wos.capesRestrictionAtShipping, 0) = 0 THEN 1 ELSE wos.byPassCapesSettingAtShipping END byPassCapesSettingAtShipping,
					wos.workOrderFormTypeId,
					wos.taskTypes,
					wos.isWoAlwaysOrOndemandId,
					wos.is813013aeOr14ae,
					CASE WHEN ISNULL(wos.CMMWarningAtReceiving, 0) = 0 AND ISNULL(wos.CMMRestrictionAtReceiving, 0) = 0 THEN 1 ELSE wos.byPassCMMSettingAtReceiving END byPassCMMSettingAtReceiving,
					CASE WHEN ISNULL(wos.capesWarningAtReceiving, 0) = 0 AND ISNULL(wos.capesRestrictionAtReceiving, 0) = 0 THEN 1 ELSE wos.byPassCapesSettingAtReceiving END byPassCapesSettingAtReceiving,
					wos.isFlatRate,
					ISNULL(wos.EnforceMpnPickTicketConfirmation, 0) AS enforceMpnPickTicketConfirmation,
					Isnull(wos.isDisplayFooter,0) as isDisplayFooter,
					ISNULL(wos.IsPNSNWarning, 0) AS isPNSNWarning,
					ISNULL(wos.IsPNSNRestriction, 0) AS isPNSNRestriction,
					ISNULL(wos.IsAllowEmployeeToMoreTask, 0) AS isAllowEmployeeToMoreTask
				FROM [DBO].[WorkOrderSettings] wos WITH(NOLOCK)
				LEFT JOIN [DBO].[WorkOrderType] wot WITH(NOLOCK) ON wos.WorkOrderTypeId = wot.Id
				LEFT JOIN [DBO].[Condition] c WITH(NOLOCK) ON wos.DefaultConditionId = c.ConditionId
				LEFT JOIN [DBO].[Site] s WITH(NOLOCK) ON wos.DefaultSiteId = s.SiteId
				LEFT JOIN [DBO].[Warehouse] wh WITH(NOLOCK) ON wos.DefaultWearhouseId = wh.WarehouseId
				LEFT JOIN [DBO].[Location] l WITH(NOLOCK) ON wos.DefaultLocationId = l.LocationId
				LEFT JOIN [DBO].[Shelf] sh WITH(NOLOCK) ON wos.DefaultShelfId = sh.ShelfId
				LEFT JOIN [DBO].[Bin] bn WITH(NOLOCK) ON wos.DefaultBinId = bn.BinId
				LEFT JOIN [DBO].[WorkOrderStage] st WITH(NOLOCK) ON wos.DefaultStageCodeId = st.WorkOrderStageId
				LEFT JOIN [DBO].[WorkScope] sc WITH(NOLOCK) ON wos.DefaultScopeId = sc.WorkScopeId
				LEFT JOIN [DBO].[WorkOrderStatus] sta WITH(NOLOCK) ON st.StatusId = sta.Id
				LEFT JOIN [DBO].[Priority] pr WITH(NOLOCK) ON wos.DefaultPriorityId = pr.PriorityId
				LEFT JOIN [DBO].[ReceivingListRB] rlrb WITH(NOLOCK) ON wos.RecivingListDefaultRBId = rlrb.ReceivingListRBId
				LEFT JOIN [DBO].[WOListRB] wb WITH(NOLOCK) ON wos.WOListViewRBId = wb.WOListRBId
				LEFT JOIN [DBO].[WOListRB] wb1 WITH(NOLOCK) ON wos.WOListStatusRBId = wb1.WOListRBId
				LEFT JOIN [DBO].[SettingStatus] ss WITH(NOLOCK) ON wos.SettingStatusId = ss.Id
				LEFT JOIN [DBO].[Provision] df WITH(NOLOCK) ON wos.DefaultProvisionId = df.ProvisionId
				LEFT JOIN [DBO].[Task] dt WITH(NOLOCK) ON wos.DefaultTaskId = dt.TaskId
				WHERE wos.WorkOrderTypeId = @WorkOrderTypeId
				  AND wos.MasterCompanyId = @MasterCompanyId
				ORDER BY wos.UpdatedDate DESC;

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderSettings' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderTypeId, '')
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
		END CATCH
END
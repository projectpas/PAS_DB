/*************************************************************           
 ** File:   [USP_GetWorkOrderSettingsDetails] 
 ** Author:   Bhargav Saliya 
 ** Description: This Store Procedure Used To get Workorder Settings List
 ** Purpose:         
 ** Date:   09-May-2025     
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author			Change Description            
 ** --   --------		 -------		--------------------------------          
    1    09-May-2025   Bhargav Saliya		Created

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWorkOrderSettingsDetails]
    @MasterCompanyId INT
AS
BEGIN
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 SET NOCOUNT ON;
 BEGIN TRY

    SELECT 
        wos.WorkOrderSettingId,
        wos.WorkOrderTypeId,
        wot.Description AS workOrderType,
        wos.MasterCompanyId,
        wos.IsActive,
        wos.CreatedBy,
        wos.CreatedDate,
        wos.UpdatedBy,
        wos.Dualreleaselanguage,
        wos.UpdatedDate,
        wos.LaborlogoffHours,
        ISNULL(wos.Isshortteardown, 0) AS Isshortteardown,
        ISNULL(wos.IsApprovalRule, 0) AS IsApprovalRule,

        ISNULL(rlrb.ReceivingListRBId, 0) AS RecivingListDefaultRB,
        rlrb.Name AS RecivingListDefault,

        ISNULL(c.ConditionId, 0) AS DefaultConditionId,
        c.Description AS DefaultConditon,

        ISNULL(s.SiteId, 0) AS DefaultSiteId,
        s.Name AS DefaultSite,

        ISNULL(wh.WarehouseId, 0) AS DefaultWearhouseId,
        wh.Name AS DefaultWarehouse,

        ISNULL(l.WarehouseId, 0) AS DefaultLocationId,
        l.Name AS DefaultLocation,

        ISNULL(sh.ShelfId, 0) AS DefaultShelfId,
        sh.Name AS DefaultShelf,

        ISNULL(st.WorkOrderStageId, 0) AS DefaultStageCodeId,
        ISNULL(st.Code, '') + '-' + ISNULL(st.Stage, '') AS DefaultStageCode,

        ISNULL(sc.WorkScopeId, 0) AS DefaultScopeId,
        sc.Description AS DefaultScope,

        ISNULL(sta.Id, 0) AS DefaultStatusId,
        sta.Description AS DefaultStatus,

        ISNULL(pr.PriorityId, 0) AS DefaultPriorityId,
        pr.Description AS DefaultPriority,

        ISNULL(wb.WOListRBId, 0) AS WOListDefaultRB,
        wb.Name AS WOListDefault,

        ISNULL(ss.Id, 0) AS settingStatusId,
        ss.Description AS settingStatus,

        ISNULL(wb1.WOListRBId, 0) AS WOListStatusDefaultRB,
        wb1.Name AS WOListStatusDefault,

        ISNULL(wos.LaborHoursMedthodId, 0) AS LaborHoursMedthodId,
        wos.EnforcePickTicket,
        wos.PickTicketEffectiveDate,
        wos.IsFlatRate

    FROM [dbo].[WorkOrderSettings] wos WITH(NOLOCK)
		LEFT JOIN [dbo].[WorkOrderType] wot WITH(NOLOCK) ON wos.WorkOrderTypeId = wot.Id
		LEFT JOIN [dbo].[Condition] c WITH(NOLOCK) ON wos.DefaultConditionId = c.ConditionId
		LEFT JOIN [dbo].[Site] s WITH(NOLOCK) ON wos.DefaultSiteId = s.SiteId
		LEFT JOIN [dbo].[Warehouse] wh WITH(NOLOCK) ON wos.DefaultWearhouseId = wh.WarehouseId
		LEFT JOIN [dbo].[Location] l WITH(NOLOCK) ON wos.DefaultLocationId = l.LocationId
		LEFT JOIN [dbo].[Shelf] sh WITH(NOLOCK) ON wos.DefaultShelfId = sh.ShelfId
		LEFT JOIN [dbo].[WorkOrderStage] st WITH(NOLOCK) ON wos.DefaultStageCodeId = st.WorkOrderStageId
		LEFT JOIN [dbo].[WorkScope] sc WITH(NOLOCK) ON wos.DefaultScopeId = sc.WorkScopeId
		LEFT JOIN [dbo].[WorkOrderStatus] sta WITH(NOLOCK) ON wos.DefaultStatusId = sta.Id
		LEFT JOIN [dbo].[Priority] pr WITH(NOLOCK) ON wos.DefaultPriorityId = pr.PriorityId
		LEFT JOIN [dbo].[ReceivingListRB] rlrb WITH(NOLOCK) ON wos.RecivingListDefaultRBId = rlrb.ReceivingListRBId
		LEFT JOIN [dbo].[WOListRB] wb WITH(NOLOCK) ON wos.WOListViewRBId = wb.WOListRBId
		LEFT JOIN [dbo].[WOListRB] wb1 WITH(NOLOCK) ON wos.WOListStatusRBId = wb1.WOListRBId
		LEFT JOIN [dbo].[SettingStatus] ss WITH(NOLOCK) ON wos.SettingStatusId = ss.Id
    WHERE ISNULL(wos.IsDeleted,0) != 1 AND wos.MasterCompanyId = @MasterCompanyId
 END TRY
 BEGIN CATCH  
   
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = 'USP_GetWorkOrderSettingsDetails',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)),  
            @ApplicationName varchar(100) = 'PAS'   
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR (  
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'  
    , 16, 1, @ErrorLogID)  
  
    RETURN (1);  
	END CATCH
END
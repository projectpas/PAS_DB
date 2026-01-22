/*************************************************************           
 ** File:   [dbo].[USP_GetWorkOrderSettingsAudit]          
 ** Author:   BHARGAV SALIA
 ** Description: Get Work Order Setup History
 ** Date:   12/18/2024   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
	1    12/18/2024   BHARGAV SALIA			Created
	2    02/06/2025   Divyesh Kathiriya		Update CreatedDate and UpdateDate based on Employee time zone
	3    02/29/2025   Amit Ghediya		    Get IsFlatRate 

	exec USP_GetWorkOrderSettingsAudit @WorkOrderSettingsId = 2, @EmployeeId = 215
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetWorkOrderSettingsAudit]
    @WorkOrderSettingsId INT,
	@EmployeeId BIGINT
AS
BEGIN
		SET NOCOUNT ON;	
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
			DECLARE @EmpLegalEntiyId BIGINT = 0;
			DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
			SELECT @EmpLegalEntiyId = LegalEntityId FROM DBO.Employee WHERE EmployeeId = @EmployeeId;
			SELECT 
					@CurrntEmpTimeZoneDesc = COALESCE(
						ETZ.[Description],  -- Prefer Employee's TimeZone description if available
						LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
					)
				FROM 
					dbo.Employee E WITH (NOLOCK) 
				LEFT JOIN 
					dbo.TimeZone ETZ WITH (NOLOCK) 
					ON E.TimeZoneId = ETZ.TimeZoneId
				LEFT JOIN 
					dbo.LegalEntity LE WITH (NOLOCK) 
					ON E.LegalEntityId = LE.LegalEntityId
				LEFT JOIN 
					dbo.TimeZone LTZ WITH (NOLOCK) 
					ON LE.TimeZoneId = LTZ.TimeZoneId
				WHERE 
					E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee
				
				SELECT 
			    wos.AuditWorkOrderSettingId,
			    wos.WorkOrderSettingId,
			    wos.WorkOrderTypeId,
			    wot.Description AS WorkOrderType,
			    wos.MasterCompanyId,
			    wos.IsActive,
			    wos.CreatedBy,
			    --wos.CreatedDate,
				CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				CASE WHEN CAST(wos.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(wos.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				ELSE (CAST(wos.CreatedDate AS DATETIME)) END CreatedDate,
			    wos.UpdatedBy,
			    --wos.UpdatedDate,
				CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				CASE WHEN CAST(wos.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(wos.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				ELSE (CAST(wos.UpdatedDate AS DATETIME)) END UpdatedDate,
			    wos.Dualreleaselanguage,
			    wos.LaborlogoffHours,

			    -- Fixed TearDownTypes using Subquery for DISTINCT
			    ISNULL((
					SELECT STRING_AGG(Name, ', ') 
					FROM (
						   SELECT DISTINCT t.Name
						   FROM STRING_SPLIT(wos.TearDownTypes, ',') AS SplitIds
						   LEFT JOIN [DBO].TeardownType t WITH(NOLOCK) ON t.TeardownTypeId = CAST(SplitIds.value AS INT)
						   WHERE SplitIds.value IS NOT NULL
						 ) AS DistinctTearDownTypes
				), '') AS TearDownTypes,

			    -- TaskTypes Data
			    ISNULL((
			        SELECT STRING_AGG(ts.Description, ', ') 
			        FROM STRING_SPLIT(wos.TaskTypes, ',') AS TaskIds
			        LEFT JOIN [DBO].Task ts WITH(NOLOCK) ON ts.TaskId = CAST(TaskIds.value AS INT)
			        WHERE TaskIds.value IS NOT NULL
			    ), '') AS TaskTypes,

			    ISNULL(c.ConditionId, 0) AS DefaultConditionId,
			    c.Description AS DefaultCondition,
			    ISNULL(s.SiteId, 0) AS DefaultSiteId,
			    s.Name AS DefaultSite,
			    ISNULL(wh.WarehouseId, 0) AS DefaultWarehouseId,
			    wh.Name AS DefaultWarehouse,
			    ISNULL(l.LocationId, 0) AS DefaultLocationId,
			    l.Name AS DefaultLocation,
			    ISNULL(sh.ShelfId, 0) AS DefaultShelfId,
			    sh.Name AS DefaultShelf,
			    ISNULL(st.WorkOrderStageId, 0) AS DefaultStageCodeId,
			    st.Stage AS DefaultStageCode,
			    ISNULL(sc.WorkScopeId, 0) AS DefaultScopeId,
			    sc.Description AS DefaultScope,
			    ISNULL(sta.Id, 0) AS DefaultStatusId,
			    sta.Description AS DefaultStatus,
			    ISNULL(pr.PriorityId, 0) AS DefaultPriorityId,
			    pr.Description AS DefaultPriority,
			    ISNULL(ss.Id, 0) AS SettingStatusId,
			    ss.Description AS SettingStatus,

			    -- Work Order Form Type Mapping
			    CASE 
			        WHEN wos.WorkOrderFormTypeId = 1 THEN 'Work Order Form'
					WHEN wos.WorkOrderFormTypeId = 2 THEN 'TearDown Form'
			        ELSE ''
			    END AS WorkOrderFormType,

			    -- Work Order Always/OnDemand Mapping
			    CASE 
			        WHEN wos.IsWoAlwaysOrOndemandId = 1 THEN 'Always'
					WHEN wos.IsWoAlwaysOrOndemandId = 2 THEN 'OnDemand'
			        ELSE ''
			    END AS IsWoAlwaysOrOndemand,
				wos.IsFlatRate
			FROM [DBO].WorkOrderSettingsAudit wos WITH(NOLOCK)
			LEFT JOIN [DBO].WorkOrderType wot WITH(NOLOCK) ON wos.WorkOrderTypeId = wot.Id
			LEFT JOIN [DBO].Condition c WITH(NOLOCK) ON wos.DefaultConditionId = c.ConditionId
			LEFT JOIN [DBO].Site s WITH(NOLOCK) ON wos.DefaultSiteId = s.SiteId
			LEFT JOIN [DBO].Warehouse wh WITH(NOLOCK) ON wos.DefaultWearhouseId = wh.WarehouseId
			LEFT JOIN [DBO].Location l WITH(NOLOCK) ON wos.DefaultLocationId = l.LocationId
			LEFT JOIN [DBO].Shelf sh WITH(NOLOCK) ON wos.DefaultShelfId = sh.ShelfId
			LEFT JOIN [DBO].WorkOrderStage st WITH(NOLOCK) ON wos.DefaultStageCodeId = st.WorkOrderStageId
			LEFT JOIN [DBO].WorkScope sc WITH(NOLOCK) ON wos.DefaultScopeId = sc.WorkScopeId
			LEFT JOIN [DBO].WorkOrderStatus sta WITH(NOLOCK) ON wos.DefaultStatusId = sta.Id
			LEFT JOIN [DBO].Priority pr WITH(NOLOCK) ON wos.DefaultPriorityId = pr.PriorityId
			LEFT JOIN [DBO].SettingStatus ss WITH(NOLOCK) ON wos.SettingStatusId = ss.Id

			WHERE wos.WorkOrderSettingId = @WorkOrderSettingsId
			ORDER BY wos.AuditWorkOrderSettingId DESC;
		END TRY
		BEGIN CATCH      
			IF @@trancount > 0			
            DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderSettingsAudit' 
			  , @ProcedureParameters VARCHAR(3000) = '@SalesOrderId = ''' + CAST(ISNULL(@WorkOrderSettingsId, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters    = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH    
END
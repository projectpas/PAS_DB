CREATE VIEW [dbo].[vw_EngineDashNumber_Audit]
AS
	SELECT C.[EngineDashNumberAuditId] AS PkID, C.[EngineDashNumberId] AS ID, C.[EngineType] AS [Engine Type], C.[EngineModel] AS [Engine Model],
		   C.[DashNumber] AS [Dash Number], C.[CreatedBy] AS [Created By], C.[CreatedDate] AS [Created Date], C.[UpdatedBy] AS [Updated By],
		   C.[UpdatedDate] AS [Updated Date], C.[IsActive] AS [Is Active], C.[IsDeleted] AS [Is Deleted]
	FROM [dbo].[EngineDashNumberAudit] C WITH (NOLOCK)

CREATE VIEW [dbo].[vw_EngineModel_Audit]
AS
	SELECT C.[EngineModelAuditId] AS PkID, C.[EngineModelId] AS ID, C.[EngineType] AS [Engine Type], C.[ModelName] AS [Model Name],
		   C.[CreatedBy] AS [Created By], C.[CreatedDate] AS [Created Date], C.[UpdatedBy] AS [Updated By], C.[UpdatedDate] AS [Updated Date],
		   C.[IsActive] AS [Is Active], C.[IsDeleted] AS [Is Deleted]
	FROM [dbo].[EngineModelAudit] C WITH (NOLOCK)

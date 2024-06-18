CREATE   VIEW [dbo].[vw_DefaultMessageAudit]
AS
	SELECT ipor.DefaultMessageAuditId  AS PkID, ipor.DefaultMessageId AS ID, md.ModuleName as [Module Name],ipor.Description as Message,Ipor.Memo as Memo
	,ipor.CreatedBy AS [Created By],
	ipor.CreatedDate AS [Created Date], ipor.UpdatedBy AS [Updated By], ipor.UpdatedDate AS [Updated Date], ipor.IsActive AS [Is Active], ipor.IsDeleted AS [Is Deleted]
	FROM [DBO].DefaultMessageAudit ipor WITH (NOLOCK) INNER JOIN dbo.Module md WITH (NOLOCK) on ipor.ModuleID = md.ModuleId
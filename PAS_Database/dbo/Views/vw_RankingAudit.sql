CREATE   VIEW [dbo].[vw_RankingAudit]
AS
	SELECT tt.RankingAuditId  AS PkID, tt.RankingId AS ID	,tt.[Description]
	,tt.CreatedBy AS [Created By],
	tt.CreatedDate AS [Created Date],tt.UpdatedBy AS [Updated By], tt.UpdatedDate AS [Updated Date], tt.IsActive AS [Is Active], tt.IsDeleted AS [Is Deleted]
	FROM [DBO].RankingAudit tt WITH (NOLOCK)
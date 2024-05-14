CREATE   VIEW [dbo].[vw_DiscountAudit]
AS
	SELECT dis.AuditDiscountId  AS PkID, dis.DiscountId AS ID	,dis.DiscontValue  [Discount Value],dis.Description
	,dis.CreatedBy AS [Created By],
	dis.CreatedDate AS [Created Date], dis.UpdatedBy AS [Updated By], dis.UpdatedDate AS [Updated Date], dis.IsActive AS [Is Active], dis.IsDeleted AS [Is Deleted]
	FROM [DBO].DiscountAudit dis WITH (NOLOCK)
CREATE   VIEW [dbo].[vw_PriorityAudit]
AS
SELECT	PA.PriorityAuditId AS PkID, PriorityId AS ID, PA.PriorityId AS 'Priority Id', PA.Description as 'Name', PA.Memo, PA.CreatedBy as 'Created By', PA.UpdatedBy AS 'Updated By',
		PA.CreatedDate AS 'Created On', PA.UpdatedDate AS 'Updated On', PA.IsActive AS 'Active ?', PA.IsDeleted AS 'Deleted ?'
FROM	dbo.[PriorityAudit] PA WITH(NOLOCK)
CREATE     VIEW [dbo].[vw_RevisionTypeAudit] 
AS
	SELECT RTA.RevisionTypeAuditId AS PkID, RevisionTypeId AS ID, RevisionTypeName AS 'Revision Type',Description, Memo
	,RTA.CreatedDate AS 'Created On', RTA.UpdatedDate AS 'Updated On', RTA.IsActive AS 'Active ?', RTA.IsDeleted AS 'Deleted ?', RTA.CreatedBy as 'Created By', RTA.UpdatedBy AS 'Updated By'
	FROM dbo.RevisionTypeAudit AS RTA WITH (NOLOCK)
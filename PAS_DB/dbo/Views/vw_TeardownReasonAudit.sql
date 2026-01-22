CREATE     VIEW [dbo].[vw_TeardownReasonAudit] 
AS
	SELECT	TRA.AuditTeardownReasonId AS PkID, TeardownReasonId AS ID, TeardownReasonId AS 'Teardown Reason Id', CTT.Name AS 'Teardown Type', Reason as 'Default Entries', TRA.Memo
	,TRA.IsActive AS 'Active ?', TRA.IsDeleted AS 'Deleted ?', TRA.CreatedBy as 'Created By', TRA.UpdatedBy AS 'Updated By', TRA.CreatedDate AS 'Created On', TRA.UpdatedDate AS 'Updated On'--, TRA.MasterCompanyId
	FROM dbo.TeardownReasonAudit AS TRA WITH (NOLOCK)
	LEFT JOIN [dbo].[CommonTeardownType] CTT WITH(NOLOCK) ON CTT.CommonTeardownTypeId = TRA.CommonTeardownTypeId
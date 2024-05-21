CREATE     VIEW [dbo].[vw_chargeAudit]
AS
SELECT	CA.ChargeAuditId AS PkID, CA.ChargeId AS ID, CA.ChargeType, CA.Description, CA.ShortName AS 'UOM', CA.SequenceNo, CA.Memo,
		CA.CreatedBy as 'Created By', CA.UpdatedBy AS 'Updated By', CA.CreatedDate AS 'Created On', CA.UpdatedDate AS 'Updated On', 
		CA.IsActive AS 'Active ?', CA.IsDeleted AS 'Deleted ?'
FROM	dbo.[ChargeAudit] CA WITH(NOLOCK)
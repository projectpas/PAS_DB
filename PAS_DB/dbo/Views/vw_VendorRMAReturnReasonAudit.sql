CREATE   VIEW [dbo].[vw_VendorRMAReturnReasonAudit]
AS
	SELECT VRR.VendorRMAReturnReasonAuditId  AS PkID,
	VRR.VendorRMAReturnReasonId AS ID	,
	VRR.[Reason],
	VRR.Memo,
	VRR.CreatedBy AS [Created By],
	VRR.CreatedDate AS [Created On],
	VRR.UpdatedBy AS [Updated By],
	VRR.UpdatedDate AS [Updated On],
	VRR.IsActive AS [Is Active],
	VRR.IsDeleted AS [Is Deleted]
	FROM [DBO].[VendorRMAReturnReasonAudit] VRR WITH (NOLOCK)
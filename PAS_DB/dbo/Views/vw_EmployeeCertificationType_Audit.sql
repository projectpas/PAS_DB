CREATE   VIEW [dbo].[vw_EmployeeCertificationType_Audit]
AS
	SELECT C.EmployeeCertificationTypeAuditId AS PkID, C.EmployeeCertificationTypeId AS ID, Description AS [Employee Certification Type], C.CreatedBy AS [Created By],
	C.CreatedDate AS [Created Date], C.UpdatedBy AS [Updated By], C.UpdatedDate AS [Updated Date], C.IsActive AS [Is Active], C.IsDeleted AS [Is Deleted]
	FROM [DBO].[EmployeeCertificationTypeAudit] C WITH (NOLOCK)
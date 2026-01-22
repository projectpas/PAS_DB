CREATE VIEW [dbo].[vw_EmployeeTrainingType_Audit]
AS
	SELECT ipor.AuditEmployeeTrainingTypeId  AS PkID, ipor.EmployeeTrainingTypeId AS ID	,ipor.TrainingType AS [Training Type]
	,ipor.CreatedBy AS [Created By],
	ipor.CreatedDate AS [Created Date], ipor.UpdatedBy AS [Updated By], ipor.UpdatedDate AS [Updated Date], ipor.IsActive AS [Is Active], ipor.IsDeleted AS [Is Deleted]
	FROM [DBO].EmployeeTrainingTypeAudit ipor WITH (NOLOCK)
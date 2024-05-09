
CREATE   VIEW [dbo].[vw_CommonTeardownTypeAudit] 
AS
	SELECT	CTTA.CommonTeardownTypeAuditId AS PkID, CommonTeardownTypeId AS ID, Name, Description, IsTechnician AS 'Technician ?', CTTA.[IsDate] AS 'Technician Date ?', IsInspector AS 'Inspector ?', IsInspectorDate AS 'Inspector Date ?', IsDocument AS 'Document ?'
	,Sequence AS 'Sequence No', CTTA.IsActive AS 'Active ?', CTTA.IsDeleted AS 'Deleted ?', CTTA.CreatedBy as 'Created By', CTTA.UpdatedBy AS 'Updated By', CTTA.CreatedDate AS 'Created On', CTTA.UpdatedDate AS 'Updated On', CTTA.MasterCompanyId
	FROM dbo.CommonTeardownTypeAudit AS CTTA WITH (NOLOCK)
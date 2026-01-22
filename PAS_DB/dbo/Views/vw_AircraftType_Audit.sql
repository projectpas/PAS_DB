CREATE   VIEW [dbo].[vw_AircraftType_Audit]
AS
	SELECT C.AircraftTypeAuditId AS PkID, C.AircraftTypeId AS ID, Description AS [Aircraft Type], SequenceNo AS [Sequence Num], C.CreatedBy AS [Created By],
	C.CreatedDate AS [Created Date], C.UpdatedBy AS [Updated By], C.UpdatedDate AS [Updated Date], C.IsActive AS [Is Active], C.IsDeleted AS [Is Deleted]
	FROM [DBO].[AircraftTypeAudit] C WITH (NOLOCK)

CREATE   VIEW [dbo].[vw_AircraftModel_Audit]
AS
	SELECT C.AircraftModelAuditId AS PkID, C.AircraftModelId AS ID, AircraftTypeId AS [Aircraft Type], ModelName AS [Model Name], WingTypeId AS [Wing Type], SequenceNo AS [Sequence Num], C.CreatedBy AS [Created By],
	C.CreatedDate AS [Created Date], C.UpdatedBy AS [Updated By], C.UpdatedDate AS [Updated Date], C.IsActive AS [Is Active], C.IsDeleted AS [Is Deleted]
	FROM [DBO].[AircraftModelAudit] C WITH (NOLOCK)
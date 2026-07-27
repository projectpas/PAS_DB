
CREATE VIEW [dbo].[vw_MaintenanceType]
AS
SELECT
    MaintenanceTypeId as MaintenanceTypeId,
    MaintenanceType as MaintenanceType,
    MaintenanceType as Description,
    '' as Memo,
    MasterCompanyId,
    CreatedBy,
    UpdatedBy,
    CreatedDate,
    UpdatedDate,
    IsActive,
    IsDeleted
FROM dbo.MaintenanceType
WHERE ISNULL(IsDeleted, 0) = 0
    AND ISNULL(IsActive, 0) = 1;
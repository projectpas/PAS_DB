CREATE VIEW dbo.VW_AircraftCapabilityType
AS
SELECT
    CapabilityTypeId,
    Description,
    IsActive,
    IsDeleted,
    SequenceMemo,
    MasterCompanyId,
    CreatedBy,
    UpdatedBy,
    CreatedDate,
    UpdatedDate,
    SequenceNo,
    CapabilityTypeDesc,
    WorkScopeId,
    ConditionId,
    IsAircraft
FROM dbo.CapabilityType
WHERE IsAircraft = 1
    AND IsDeleted = 0
    AND IsActive = 1;
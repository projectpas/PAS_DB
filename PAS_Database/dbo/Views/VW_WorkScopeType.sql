CREATE VIEW dbo.VW_WorkScopeType
AS
SELECT
    WorkScopeId,
    WorkScopeCode,
    Description,
    Memo,
    MasterCompanyId,
    CreatedBy,
    UpdatedBy,
    CreatedDate,
    UpdatedDate,
    IsActive,
    IsDeleted,
    WorkScopeCodeNew,
    ConditionId,
    IsAircraft
FROM dbo.WorkScope WITH(NOLOCK)
WHERE IsAircraft = 1
    AND ISNULL(IsDeleted, 0) = 0
    AND ISNULL(IsActive, 0) = 1;
CREATE VIEW vw_KitMasterProvision
AS
SELECT 
    ProvisionId,
    Description,
    Memo,
    MasterCompanyId,
    CreatedBy,
    UpdatedBy,
    CreatedDate,
    UpdatedDate,
    IsActive,
    IsDeleted,
    StatusCode
FROM dbo.Provision
WHERE StatusCode IN ('REPAIR', 'REPLACE')
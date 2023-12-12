CREATE   VIEW [dbo].[vw_WOInspectionConditions]
AS
SELECT ConditionId, Description, Memo, CreatedDate, UpdatedDate, IsActive, MasterCompanyId, CreatedBy, UpdatedBy, IsDeleted, SequenceNo, Code
FROM dbo.Condition AS Cond WITH (NOLOCK)
WHERE (Code NOT IN ('INSPECTED', 'OVERHAULED', 'REPAIRED', 'SCRAPPED', 'SVC', 'RAI'))
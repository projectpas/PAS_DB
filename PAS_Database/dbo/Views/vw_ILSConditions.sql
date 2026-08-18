CREATE   VIEW [dbo].[vw_ILSConditions]
AS
	SELECT
		C.ConditionId,
		C.Description,
		C.Code,
		C.Memo,
		C.SequenceNo,
		C.MasterCompanyId,
		C.IsActive,
		C.IsDeleted,
		C.IsILSCondition
	FROM [dbo].[Condition] C WITH (NOLOCK)
	WHERE C.IsDeleted = 0 AND C.IsILSCondition = 1
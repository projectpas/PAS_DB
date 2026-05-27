CREATE    VIEW [dbo].[vw_TrainingName]
AS 
	SELECT 
		TN.TrainingNameId,
		TN.Name,
		TN.Memo,
		TN.MasterCompanyId,
		TN.CreatedBy,
		TN.UpdatedBy,
		TN.CreatedDate,
		TN.UpdatedDate,
		TN.IsActive,
		TN.IsDeleted
	FROM [dbo].[TrainingName] TN  WITH (NOLOCK)
CREATE  VIEW [dbo].[vw_CoreLetter]
AS 
	SELECT 
		CL.CoreLetterId,
		CL.LetterCode,
		CL.HeaderName,
		CL.LetterDescription,
		CL.IsActive,
		CL.IsDeleted,
		CL.MasterCompanyId,
		CL.CreatedBy,
		CL.UpdatedBy,
		CL.CreatedDate,
		CL.UpdatedDate
	FROM [dbo].[CoreLetter] CL  WITH (NOLOCK)
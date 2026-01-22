CREATE   VIEW [dbo].[vw_CodePrefix]
AS
	SELECT CP.*, CT.CodeType
	FROM [DBO].[CodePrefixes] CP WITH (NOLOCK)
	JOIN [DBO].[CodeTypes] CT WITH (NOLOCK)
	ON CP.CodeTypeId = CT.CodeTypeId
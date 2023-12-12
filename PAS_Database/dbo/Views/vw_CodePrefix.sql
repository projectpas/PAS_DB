

CREATE VIEW [dbo].[vw_CodePrefix]
AS

SELECT CP.*,CT.CodeType FROM CodePrefixes CP
JOIN CodeTypes CT ON CP.CodeTypeId=CT.CodeTypeId
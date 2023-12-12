


CREATE VIEW [dbo].[vw_ledger]
AS

SELECT L.*,LE.Name AS LegalEntity FROM Ledger L
JOIN LegalEntity LE ON L.LegalEntityId=LE.LegalEntityId
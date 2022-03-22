


CREATE VIEW [dbo].[vw_unitofmeasure]
AS

SELECT UM.*,ST.StandardName FROM UnitOfMeasure UM
JOIN Standard ST ON UM.StandardId=ST.StandardId
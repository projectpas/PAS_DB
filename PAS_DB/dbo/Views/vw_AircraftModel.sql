
CREATE VIEW [dbo].[vw_AircraftModel]
AS
SELECT am.*,ate.Description AS AircraftType,wt.WingTypeName as WingType  FROM AircraftModel am
JOIN AircraftType ate on am.AircraftTypeId=ate.AircraftTypeId
JOIN WingType wt on am.WingTypeId=wt.WingTypeId
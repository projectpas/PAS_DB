CREATE VIEW [dbo].[vw_AircraftDashNumbers]
AS
SELECT        dbo.AircraftDashNumber.DashNumberId, dbo.AircraftDashNumber.AircraftTypeId, dbo.AircraftDashNumber.AircraftModelId, dbo.AircraftDashNumber.DashNumber, dbo.AircraftDashNumber.Memo, 
                         dbo.AircraftDashNumber.MasterCompanyId, dbo.AircraftDashNumber.CreatedBy, dbo.AircraftDashNumber.UpdatedBy, dbo.AircraftDashNumber.CreatedDate, dbo.AircraftDashNumber.UpdatedDate, 
                         dbo.AircraftDashNumber.IsActive, dbo.AircraftDashNumber.IsDeleted, dbo.AircraftModel.ModelName AS AircraftModel, dbo.AircraftType.Description AS AircraftType
FROM            dbo.AircraftDashNumber INNER JOIN
                         dbo.AircraftModel ON dbo.AircraftDashNumber.AircraftModelId = dbo.AircraftModel.AircraftModelId INNER JOIN
                         dbo.AircraftType ON dbo.AircraftDashNumber.AircraftTypeId = dbo.AircraftType.AircraftTypeId
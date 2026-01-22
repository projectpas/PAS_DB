CREATE    VIEW  vw_AircraftDashNumbers
AS
SELECT ACD.[DashNumberId]
      ,ACD.[AircraftTypeId]
      ,ACD.[AircraftModelId]
      ,ACD.[DashNumber]
      ,ACD.[MasterCompanyId]
      ,ACD.[CreatedBy]
      ,ACD.[CreatedDate]
      ,ACD.[UpdatedBy]
      ,ACD.[UpdatedDate]
      ,ACD.[IsActive]
      ,ACD.[IsDeleted]
	  ,ACT.[Description] AS AircraftType
	  ,ACM.[ModelName] as AircraftModel
FROM [dbo].[AircraftDashNumber] ACD WITH (NOLOCK) 
JOIN [DBO].[AircraftType]       ACT WITH (NOLOCK) ON ACD.AircraftTypeId = ACT.AircraftTypeId
JOIN [DBO].[AircraftModel]      ACM WITH (NOLOCK) ON ACD.AircraftModelId = ACM.AircraftModelId
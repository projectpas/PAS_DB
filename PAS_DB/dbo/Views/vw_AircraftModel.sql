
CREATE    VIEW  vw_AircraftModel
AS
SELECT ACM.[AircraftModelId],
	   ACM.[AircraftTypeId],
	   ACM.[WingTypeId],
	   ACM.[ModelName],
	   ACM.[SequenceNo],
	   ACM.[MasterCompanyId],
	   ACM.[CreatedBy],
	   ACM.[CreatedDate],
	   ACM.[UpdatedBy],
	   ACM.[UpdatedDate],
	   ACM.[IsActive],
	   ACM.[IsDeleted],
	   ACT.[Description] AS AircraftType,
	   WGT.[WingTypeName] AS WingType
FROM [DBO].[AircraftModel] ACM WITH (NOLOCK) 
JOIN [DBO].[AircraftType]  ACT WITH (NOLOCK) ON ACM.AircraftTypeId = ACT.AircraftTypeId
JOIN [DBO].[WingType]      WGT WITH (NOLOCK) ON ACM.WingTypeId = WGT.WingTypeId
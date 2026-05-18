CREATE TYPE [dbo].[AircraftEffectivityTableType] AS TABLE (
    [AircraftEffectivityId]  BIGINT         NULL,
    [AircraftPublicationsId] BIGINT         NULL,
    [MakeTypeId]             BIGINT         NULL,
    [AircraftModelId]        BIGINT         NULL,
    [AircraftSubModel]       VARCHAR (100)  NULL,
    [FromSerialNumber]       VARCHAR (100)  NULL,
    [ToSerialNumber]         VARCHAR (100)  NULL,
    [ItemMasterId]           BIGINT         NULL,
    [PartNumber]             VARCHAR (50)   NULL,
    [PartDescription]        NVARCHAR (MAX) NULL,
    [Notes]                  VARCHAR (MAX)  NULL,
    [MasterCompanyId]        INT            NULL,
    [CreatedBy]              VARCHAR (256)  NULL,
    [UpdatedBy]              VARCHAR (256)  NULL,
    [CreatedDate]            DATETIME2 (7)  NULL);


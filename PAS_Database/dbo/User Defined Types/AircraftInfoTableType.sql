CREATE TYPE [dbo].[AircraftInfoTableType] AS TABLE (
    [AircraftInfoId]   BIGINT        NULL,
    [MakeTypeId]       BIGINT        NULL,
    [MakeType]         VARCHAR (100) NULL,
    [AircraftModelId]  BIGINT        NULL,
    [AircraftModel]    VARCHAR (100) NULL,
    [AircraftSubModel] VARCHAR (100) NULL,
    [ItemMasterId]     BIGINT        NULL,
    [IsActive]         BIT           NULL,
    [IsDeleted]        BIT           NULL,
    [MasterCompanyId]  INT           NULL,
    [CreatedBy]        VARCHAR (256) NULL,
    [UpdatedBy]        VARCHAR (256) NULL,
    [CreatedDate]      DATETIME2 (7) NULL,
    [UpdatedDate]      DATETIME2 (7) NULL);


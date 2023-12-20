CREATE TYPE [dbo].[UpdateTimeLifeReceivingPOType] AS TABLE (
    [TimeLifeDraftCyclesId] BIGINT       NULL,
    [StockLineDraftId]      BIGINT       NULL,
    [CyclesRemaining]       VARCHAR (20) NULL,
    [CyclesSinceNew]        VARCHAR (20) NULL,
    [CyclesSinceOVH]        VARCHAR (20) NULL,
    [CyclesSinceInspection] VARCHAR (20) NULL,
    [CyclesSinceRepair]     VARCHAR (20) NULL,
    [TimeRemaining]         VARCHAR (20) NULL,
    [TimeSinceNew]          VARCHAR (20) NULL,
    [TimeSinceOVH]          VARCHAR (20) NULL,
    [TimeSinceInspection]   VARCHAR (20) NULL,
    [TimeSinceRepair]       VARCHAR (20) NULL,
    [LastSinceNew]          VARCHAR (20) NULL,
    [LastSinceOVH]          VARCHAR (20) NULL,
    [LastSinceInspection]   VARCHAR (20) NULL,
    [DetailsNotProvided]    BIT          NULL);


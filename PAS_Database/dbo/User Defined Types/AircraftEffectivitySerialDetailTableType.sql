CREATE TYPE [dbo].[AircraftEffectivitySerialDetailTableType] AS TABLE (
    [AircraftEffectivitySerialDetailId] BIGINT        NULL,
    [IsAircraftSerialNum]               BIT           NULL,
    [IsAffect]                          BIT           NULL,
    [SerialType]                        VARCHAR (20)  NULL,
    [FromSerial]                        VARCHAR (100) NULL,
    [ToSerial]                          VARCHAR (100) NULL);


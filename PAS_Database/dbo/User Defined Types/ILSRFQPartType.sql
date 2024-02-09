CREATE TYPE [dbo].[ILSRFQPartType] AS TABLE (
    [ILSRFQPartId]   BIGINT        NULL,
    [ILSRFQDetailId] BIGINT        NULL,
    [PartNumber]     VARCHAR (70)  NULL,
    [AltPartNumber]  VARCHAR (70)  NULL,
    [Exchange]       VARCHAR (70)  NULL,
    [Description]    VARCHAR (MAX) NULL,
    [Qty]            INT           NULL,
    [Condition]      VARCHAR (20)  NULL,
    [IsEmail]        BIT           NULL,
    [IsFax]          BIT           NULL);


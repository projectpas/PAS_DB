CREATE TYPE [dbo].[UOMConvertionType] AS TABLE (
    [UOMConversionId] BIGINT          NULL,
    [FromUOM]         VARCHAR (100)   NULL,
    [ToUOM]           VARCHAR (100)   NULL,
    [Factor]          DECIMAL (18, 8) NULL,
    [CreatedBy]       VARCHAR (100)   NULL,
    [CreatedDate]     DATETIME2 (7)   NULL,
    [UpdatedBy]       VARCHAR (256)   NULL,
    [UpdatedDate]     DATETIME2 (7)   NULL,
    [IsActive]        BIT             NULL,
    [IsDeleted]       BIT             NULL,
    [MasterCompanyId] INT             NULL);


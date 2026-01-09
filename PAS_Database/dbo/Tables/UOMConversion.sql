CREATE TABLE [dbo].[UOMConversion] (
    [UOMConversionId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [FromUOM]         VARCHAR (100)   NULL,
    [ToUOM]           VARCHAR (100)   NULL,
    [Factor]          DECIMAL (18, 8) NULL,
    [IsMultiply]      BIT             NULL,
    [DecimalPlaces]   INT             NULL,
    [MasterCompanyId] INT             NULL,
    [CreatedBy]       VARCHAR (256)   NULL,
    [UpdatedBy]       VARCHAR (256)   NULL,
    [CreatedDate]     DATETIME2 (7)   NULL,
    [UpdatedDate]     DATETIME2 (7)   NULL,
    [IsActive]        BIT             NULL,
    [IsDeleted]       BIT             NULL,
    CONSTRAINT [PK_UOMConversion] PRIMARY KEY CLUSTERED ([UOMConversionId] ASC)
);


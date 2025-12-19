CREATE TABLE [dbo].[UOMConversion] (
    [UOMConversionId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [FromUOM]         VARCHAR (100)   NULL,
    [ToUOM]           VARCHAR (100)   NULL,
    [Factor]          DECIMAL (18, 8) NULL,
    [IsMultiply]      BIT             NULL,
    [DecimalPlaces]   INT             NULL,
    CONSTRAINT [PK_UOMConversion] PRIMARY KEY CLUSTERED ([UOMConversionId] ASC)
);


CREATE TABLE [dbo].[Part] (
    [PartId]           BIGINT        IDENTITY (1, 1) NOT NULL,
    [PartNumber]       VARCHAR (50)  NOT NULL,
    [Description]      VARCHAR (200) NULL,
    [ManufacturerCode] VARCHAR (50)  NULL,
    [Manufacturer]     VARCHAR (100) NULL,
    [Comments]         VARCHAR (500) NULL,
    [MasterCompanyId]  INT           NOT NULL,
    [CreatedBy]        VARCHAR (256) NULL,
    [UpdatedBy]        VARCHAR (256) NULL,
    [CreatedDate]      DATETIME2 (7) NOT NULL,
    [UpdatedDate]      DATETIME2 (7) NOT NULL,
    [IsActive]         BIT           NULL,
    [ParentPartId]     VARCHAR (256) NULL,
    CONSTRAINT [PK_PartId] PRIMARY KEY CLUSTERED ([PartId] ASC)
);


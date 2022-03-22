CREATE TABLE [dbo].[POROCategoryMapping] (
    [POROCategoryMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [POROCategoryId]        BIGINT        NOT NULL,
    [ReferenceId]           BIGINT        NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) NOT NULL,
    [IsActive]              BIT           NOT NULL,
    [IsDeleted]             BIT           NOT NULL,
    CONSTRAINT [PK_POROCategoryMapping] PRIMARY KEY CLUSTERED ([POROCategoryMappingId] ASC)
);


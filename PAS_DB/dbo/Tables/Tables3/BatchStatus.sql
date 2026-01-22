CREATE TABLE [dbo].[BatchStatus] (
    [Id]              BIGINT        IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (100) NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (30)  NOT NULL,
    [UpdatedBy]       VARCHAR (30)  NOT NULL,
    [CreatedDate]     DATETIME2 (7) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) NOT NULL,
    [IsActive]        BIT           NOT NULL,
    [IsDeleted]       BIT           NOT NULL,
    CONSTRAINT [PK_BatchStatus] PRIMARY KEY CLUSTERED ([Id] ASC)
);


CREATE TABLE [dbo].[GLAccountNodeShareWithEntityMapper] (
    [GLAccountNodeShareWithEntityMapperId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [GLAccountNodeId]                      BIGINT        NOT NULL,
    [MasterCompanyId]                      INT           NOT NULL,
    [CreatedBy]                            VARCHAR (256) NULL,
    [UpdatedBy]                            VARCHAR (256) NULL,
    [CreatedDate]                          DATETIME2 (7) NOT NULL,
    [UpdatedDate]                          DATETIME2 (7) NOT NULL,
    [IsActive]                             BIT           NULL,
    [ShareWithEntityId]                    BIGINT        NOT NULL,
    CONSTRAINT [PK_GLAccountNodeShareWithEntityMapper] PRIMARY KEY CLUSTERED ([GLAccountNodeShareWithEntityMapperId] ASC),
    CONSTRAINT [FK_GLAccountNodeShareWithEntityMapper_GLAccountNode] FOREIGN KEY ([GLAccountNodeId]) REFERENCES [dbo].[GLAccountNode] ([GLAccountNodeId]),
    CONSTRAINT [FK_GLAccountNodeShareWithEntityMapper_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


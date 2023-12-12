CREATE TABLE [dbo].[LegalEntityConfiguration] (
    [ConfigurationId]    BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityId]      BIGINT        NOT NULL,
    [ModuleId]           BIGINT        NOT NULL,
    [TermsandConditions] VARCHAR (MAX) NULL,
    [MasterCompanyId]    INT           NOT NULL,
    [CreatedBy]          VARCHAR (256) NOT NULL,
    [UpdatedBy]          VARCHAR (256) NOT NULL,
    [CreatedDate]        DATETIME2 (7) NOT NULL,
    [UpdatedDate]        DATETIME2 (7) NOT NULL,
    [IsActive]           BIT           CONSTRAINT [DF_LEC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT           CONSTRAINT [DF_LEC_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LegalEntityConfiguration] PRIMARY KEY CLUSTERED ([ConfigurationId] ASC),
    CONSTRAINT [FK_LegalEntityConfiguration_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


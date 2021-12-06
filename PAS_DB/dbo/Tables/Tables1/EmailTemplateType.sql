CREATE TABLE [dbo].[EmailTemplateType] (
    [EmailTemplateTypeId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [EmailTemplateType]   VARCHAR (250) NULL,
    [MasterCompanyId]     INT           NULL,
    [CreatedBy]           VARCHAR (256) NULL,
    [UpdatedBy]           VARCHAR (256) NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [DF_EmailTemplateType_CreatedDate] DEFAULT (getdate()) NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [DF_EmailTemplateType_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]            BIT           CONSTRAINT [DF_EmailTemplateType_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]           BIT           CONSTRAINT [DF_EmailTemplateType_IsDeleted] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_EmailTemplateType] PRIMARY KEY CLUSTERED ([EmailTemplateTypeId] ASC)
);


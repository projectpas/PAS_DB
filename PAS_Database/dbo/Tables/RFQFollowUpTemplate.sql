CREATE TABLE [dbo].[RFQFollowUpTemplate] (
    [TemplateId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [TemplateName]    VARCHAR (200)  NOT NULL,
    [Description]     VARCHAR (400)  NULL,
    [Subject]         VARCHAR (200)  NULL,
    [EmailBody]       NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (50)   NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_RFQFollowUpTemplate_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (50)   NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_RFQFollowUpTemplate_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF__RFQFollowUpTemplate__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF__RFQFollowUpTemplate__IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_RFQFollowUpTemplate] PRIMARY KEY CLUSTERED ([TemplateId] ASC)
);


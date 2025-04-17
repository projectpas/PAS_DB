CREATE TABLE [dbo].[CommonTeardownTemplate] (
    [CommonTeardownTemplateId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CommonTeardownTypeId]     BIGINT        NOT NULL,
    [TemplateName]             VARCHAR (100) NULL,
    [TemplateCode]             VARCHAR (50)  NULL,
    [Description]              VARCHAR (500) NULL,
    [TemplateBody]             VARCHAR (MAX) NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [CreatedBy]                VARCHAR (50)  NOT NULL,
    [CreatedDate]              DATETIME2 (7) CONSTRAINT [DF_CommonTeardownTemplate_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                VARCHAR (50)  NOT NULL,
    [UpdatedDate]              DATETIME2 (7) CONSTRAINT [DF_CommonTeardownTemplate_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                 BIT           CONSTRAINT [DF__CommonTeardownTemplate__IsActi__59FA5E80] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT           CONSTRAINT [DF__CommonTeardownTemplate__IsDele__5AEE82B9] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CommonTeardownTemplate] PRIMARY KEY CLUSTERED ([CommonTeardownTemplateId] ASC)
);


GO

--select * from CommonTeardownTemplateAudit
--drop table CommonTeardownTemplateAudit



--trigger


CREATE   TRIGGER [dbo].[Trg_CommonTeardownTemplateAudit]

   ON  [dbo].[CommonTeardownTemplate]

   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN	

	INSERT INTO [CommonTeardownTemplateAudit]

	SELECT * FROM INSERTED

END
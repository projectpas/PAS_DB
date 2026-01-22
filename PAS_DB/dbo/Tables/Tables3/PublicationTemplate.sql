CREATE TABLE [dbo].[PublicationTemplate] (
    [PublicationTemplateId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [PublicationTypeId]     BIGINT         NULL,
    [EmailBody]             NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  CONSTRAINT [DF_PublicationTemplate_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  CONSTRAINT [DF_PublicationTemplate_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT            CONSTRAINT [DF_PublicationTemplate_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            CONSTRAINT [DF_PublicationTemplate_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_PublicationTemplate] PRIMARY KEY CLUSTERED ([PublicationTemplateId] ASC)
);


GO

CREATE TRIGGER [dbo].[Trg_PublicationTemplateAudit]

   ON  [dbo].[PublicationTemplate]

   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN	
	DECLARE @PublicationTemplateId BIGINT 

	SELECT  @PublicationTemplateId = PublicationTemplateId FROM INSERTED

	INSERT INTO [dbo].[PublicationTemplateAudit]
	SELECT * FROM [dbo].[PublicationTemplate] WHERE PublicationTemplateId = @PublicationTemplateId;

END
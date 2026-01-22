CREATE TABLE [dbo].[TermsCondition] (
    [TermsConditionId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]         NVARCHAR (MAX) NOT NULL,
    [Memo]                NVARCHAR (MAX) NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  CONSTRAINT [TermsCondition_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  CONSTRAINT [TermsCondition_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT            CONSTRAINT [TermsCondition_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT            CONSTRAINT [TermsCondition_DC_Delete] DEFAULT ((0)) NOT NULL,
    [EmailTemplateTypeId] BIGINT         NULL,
    CONSTRAINT [PK_TermsCondition] PRIMARY KEY CLUSTERED ([TermsConditionId] ASC),
    CONSTRAINT [FK_TermsCondition_EmailTemplateTypeId] FOREIGN KEY ([EmailTemplateTypeId]) REFERENCES [dbo].[EmailTemplateType] ([EmailTemplateTypeId]),
    CONSTRAINT [FK_TermsCondition_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO


CREATE TRIGGER [dbo].[Trg_TermsConditionAudit]
   ON  [dbo].[TermsCondition]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
    DECLARE @EmailTemplateTypeId INT
	DECLARE @EmailTemplateType VARCHAR(256)
	SELECT @EmailTemplateTypeId = EmailTemplateTypeId FROM INSERTED
	SELECT @EmailTemplateType = EmailTemplateType FROM DBO.EmailTemplateType WITH (NOLOCK) WHERE EmailTemplateTypeId = @EmailTemplateTypeId
	
	INSERT INTO TermsConditionAudit
	SELECT *, @EmailTemplateType FROM INSERTED
	
	SET NOCOUNT ON;
END
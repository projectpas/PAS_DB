CREATE TABLE [dbo].[EmailTemplate] (
    [EmailTemplateId]     INT            IDENTITY (1, 1) NOT NULL,
    [TemplateName]        VARCHAR (100)  NULL,
    [TemplateDescription] NVARCHAR (MAX) NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  CONSTRAINT [D_ET_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  CONSTRAINT [D_ET_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT            CONSTRAINT [D_ET_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT            CONSTRAINT [D_ET_Deleted] DEFAULT ((0)) NOT NULL,
    [EmailBody]           NVARCHAR (MAX) NULL,
    [EmailTemplateTypeId] BIGINT         NULL,
    [SubjectName]         VARCHAR (50)   NULL,
    [RevNo]               NVARCHAR (50)  NULL,
    [RevDate]             NVARCHAR (50)  NULL,
    CONSTRAINT [PK_EmailTemplate] PRIMARY KEY CLUSTERED ([EmailTemplateId] ASC)
);




GO




CREATE TRIGGER [dbo].[Trg_EmailTemplateAudit]

   ON  [dbo].[EmailTemplate]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN

	--INSERT INTO [dbo].[EmailTemplateAudit]

	--SELECT * FROM INSERTED



	--SET NOCOUNT ON;



	DECLARE @EmailTemplateId BIGINT 

	DECLARE @EmailTemplateTypeId BIGINT 

	

	SELECT  @EmailTemplateTypeId=EmailTemplateTypeId,@EmailTemplateId=EmailTemplateId FROM INSERTED

	

	UPDATE [dbo].[EmailTemplate] SET TemplateName = (SELECT EmailTemplateType FROM [dbo].[EmailTemplateType] WHERE 

													        EmailTemplateTypeId=@EmailTemplateTypeId) WHERE EmailTemplateId=@EmailTemplateId;



	INSERT INTO [dbo].[EmailTemplateAudit]

	SELECT * FROM [dbo].[EmailTemplate] WHERE EmailTemplateId=@EmailTemplateId;



END
CREATE TABLE [dbo].[OrganizationTagType] (
    [OrganizationTagTypeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]                  VARCHAR (100)  NOT NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  CONSTRAINT [DF_OrganizationTagType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  CONSTRAINT [DF_OrganizationTagType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT            CONSTRAINT [DF_OrganizationTagType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            CONSTRAINT [DF_OrganizationTagType_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_OrganizationTagType] PRIMARY KEY CLUSTERED ([OrganizationTagTypeId] ASC),
    CONSTRAINT [FK_OrganizationTagType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO


CREATE TRIGGER [dbo].[Trg_OrganizationTagTypeAudit]

   ON  [dbo].[OrganizationTagType]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO OrganizationTagTypeAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
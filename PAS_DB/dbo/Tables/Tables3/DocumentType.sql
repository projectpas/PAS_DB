CREATE TABLE [dbo].[DocumentType] (
    [DocumentTypeId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (50)   NOT NULL,
    [Description]     VARCHAR (256)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DocumentType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DocumentType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DocumentType_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DocumentType_DC_Delete] DEFAULT ((0)) NOT NULL,
    [RevNum]          INT            CONSTRAINT [DF_DocumentType_RevNum] DEFAULT ((0)) NOT NULL,
    [IsDefault]       BIT            CONSTRAINT [DEFAULT_IsDefault] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_DocumentType] PRIMARY KEY CLUSTERED ([DocumentTypeId] ASC),
    CONSTRAINT [FK_DocumentType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_DocumentType] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


GO


Create TRIGGER [dbo].[Trg_DocumentTypeAudit]

   ON  [dbo].[DocumentType]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[DocumentTypeAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
CREATE TABLE [dbo].[TaxType] (
    [TaxTypeId]       TINYINT        IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (100)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [TaxType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [TaxType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [D_TaxType_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [D_TaxType_Delete] DEFAULT ((0)) NOT NULL,
    [Code]            VARCHAR (100)  NULL,
    CONSTRAINT [PK_TaxType] PRIMARY KEY CLUSTERED ([TaxTypeId] ASC),
    CONSTRAINT [FK_TaxType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_TaxType] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_TaxTypeAudit]

   ON  [dbo].[TaxType]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN

	INSERT INTO TaxTypeAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
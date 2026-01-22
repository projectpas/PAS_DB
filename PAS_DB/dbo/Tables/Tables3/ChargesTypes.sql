CREATE TABLE [dbo].[ChargesTypes] (
    [Id]              INT            IDENTITY (1, 1) NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME       CONSTRAINT [ChargesTypes_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_ChargesTypes_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [D_ChargesTypes_Delete] DEFAULT ((0)) NOT NULL,
    [Name]            VARCHAR (256)  NOT NULL,
    [Description]     VARCHAR (MAX)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [IsActive]        BIT            CONSTRAINT [D_ChargesTypes_Active] DEFAULT ((1)) NOT NULL,
    [MasterCompanyId] INT            NOT NULL,
    CONSTRAINT [PK__ChargesT__3214EC07652AB0B8] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_ChargesTypes_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_ChargesTypes] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_ChargesTypesAudit]

   ON  [dbo].[ChargesTypes]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO ChargesTypesAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END
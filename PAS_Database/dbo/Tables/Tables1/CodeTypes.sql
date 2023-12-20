CREATE TABLE [dbo].[CodeTypes] (
    [CodeTypeId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [CodeType]        VARCHAR (100)  NOT NULL,
    [Description]     VARCHAR (250)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_CodeTypes_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_CodeTypes_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_CodeTypes_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_CodeTypes_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CodeType] PRIMARY KEY CLUSTERED ([CodeTypeId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_CodeTypesAudit]

   ON  [dbo].[CodeTypes]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO CodeTypesAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END
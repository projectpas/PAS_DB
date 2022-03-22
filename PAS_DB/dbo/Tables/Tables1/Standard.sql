CREATE TABLE [dbo].[Standard] (
    [StandardId]      INT            IDENTITY (1, 1) NOT NULL,
    [StandardName]    VARCHAR (256)  NOT NULL,
    [Description]     VARCHAR (256)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [IsActive]        BIT            CONSTRAINT [Standard_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [Standard_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [Standard_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [Standard_DC_UDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_Standard] PRIMARY KEY CLUSTERED ([StandardId] ASC),
    CONSTRAINT [FK_Standard_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO


CREATE TRIGGER [dbo].[Trg_StandardAudit]

   ON  [dbo].[Standard]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO StandardAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END
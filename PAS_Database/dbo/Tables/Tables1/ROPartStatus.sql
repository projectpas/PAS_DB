CREATE TABLE [dbo].[ROPartStatus] (
    [ROPartStatusId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [PartStatus]      VARCHAR (256)  NOT NULL,
    [Description]     VARCHAR (MAX)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [ROPartStatus_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [ROPartStatus_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [ROPartStatus_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [ROPartStatus_DC_Delete] DEFAULT ((0)) NOT NULL,
    [SequenceNo]      INT            NULL,
    CONSTRAINT [PK_ROPartStatus] PRIMARY KEY CLUSTERED ([ROPartStatusId] ASC),
    CONSTRAINT [FK_ROPartStatus_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_ROPartStatus] UNIQUE NONCLUSTERED ([PartStatus] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_ROPartStatusAudit]

   ON  [dbo].[ROPartStatus]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO ROPartStatusAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END
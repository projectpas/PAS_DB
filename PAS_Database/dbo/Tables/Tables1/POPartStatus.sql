CREATE TABLE [dbo].[POPartStatus] (
    [POPartStatusId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [PartStatus]      VARCHAR (256)  NOT NULL,
    [Description]     VARCHAR (MAX)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [POPartStatus_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [POPartStatus_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [POPartStatus_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [POPartStatus_DC_Delete] DEFAULT ((0)) NOT NULL,
    [SequenceNo]      INT            NULL,
    CONSTRAINT [PK_POPartStatus] PRIMARY KEY CLUSTERED ([POPartStatusId] ASC),
    CONSTRAINT [FK_POPartStatus_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_POPartStatus] UNIQUE NONCLUSTERED ([PartStatus] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_POPartStatusAudit]

   ON  [dbo].[POPartStatus]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO POPartStatusAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END
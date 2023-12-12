CREATE TABLE [dbo].[WOPartStatus] (
    [WOPartStatusId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [PartStatus]      VARCHAR (256)  NOT NULL,
    [Description]     VARCHAR (MAX)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [WOPartStatus_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [WOPartStatus_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [WOPartStatus_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [WOPartStatus_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WOPartStatus] PRIMARY KEY CLUSTERED ([WOPartStatusId] ASC),
    CONSTRAINT [FK_WOPartStatus_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_WOPartStatus] UNIQUE NONCLUSTERED ([PartStatus] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_WOPartStatusAudit]

   ON  [dbo].[WOPartStatus]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO WOPartStatusAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END
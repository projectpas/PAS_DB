CREATE TABLE [dbo].[Finding] (
    [FindingId]       BIGINT         IDENTITY (1, 1) NOT NULL,
    [FindingCode]     VARCHAR (30)   NOT NULL,
    [Description]     VARCHAR (MAX)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [Finding_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [Finding_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [Finding_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [Finding_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Finding] PRIMARY KEY CLUSTERED ([FindingId] ASC),
    CONSTRAINT [FK_Finding_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_Finding] UNIQUE NONCLUSTERED ([FindingCode] ASC, [MasterCompanyId] ASC),
    CONSTRAINT [UQ_FindingCode_codes] UNIQUE NONCLUSTERED ([FindingCode] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_FindingAudit]

   ON  [dbo].[Finding]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO FindingAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END
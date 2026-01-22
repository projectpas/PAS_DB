CREATE TABLE [dbo].[Warning] (
    [WarningId]       BIGINT        IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (100) NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_Warning_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_Warning_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [Warning_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [Warning_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Warning] PRIMARY KEY CLUSTERED ([WarningId] ASC),
    CONSTRAINT [FK_Warning_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_WarningDescription] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_WarningAudit]

   ON  [dbo].[Warning]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WarningAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
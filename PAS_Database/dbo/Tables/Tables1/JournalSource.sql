CREATE TABLE [dbo].[JournalSource] (
    [ID]              BIGINT        IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (50)  NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [JournalSource_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [JournalSource_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [JournalSource_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [JournalSource_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_JournalBatchSource] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_JournalSource_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_JournalSource] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_JournalSourceAudit]

   ON  [dbo].[JournalSource]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO JournalSourceAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
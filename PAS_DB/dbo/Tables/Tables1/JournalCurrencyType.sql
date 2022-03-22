CREATE TABLE [dbo].[JournalCurrencyType] (
    [ID]                      BIGINT        IDENTITY (1, 1) NOT NULL,
    [Description]             VARCHAR (50)  NOT NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [JournalCurrencyType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [JournalCurrencyType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT           CONSTRAINT [JournalCurrencyType_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           CONSTRAINT [JournalCurrencyType_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    [JournalCurrencyTypeName] VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_JournalCurrencyType] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_JournalCurrencyType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_JournalCurrencyType] UNIQUE NONCLUSTERED ([JournalCurrencyTypeName] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_JournalCurrencyTypeAudit]

   ON  [dbo].[JournalCurrencyType]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[JournalCurrencyTypeAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
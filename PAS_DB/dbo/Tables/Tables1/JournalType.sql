CREATE TABLE [dbo].[JournalType] (
    [ID]              BIGINT        IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (50)  NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [JournalType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [JournalType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [JournalType_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [JournalType_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    [JournalTypeName] VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_JournalType] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_JournalType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_JournalType] UNIQUE NONCLUSTERED ([JournalTypeName] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_JournalTypeAudit]

   ON  [dbo].[JournalType]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[JournalTypeAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
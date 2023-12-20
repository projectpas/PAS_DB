CREATE TABLE [dbo].[JournalPeriod] (
    [ID]              BIGINT        IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (50)  NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [JournalPeriod_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [JournalPeriod_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [JournalPeriod_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [JournalPeriod_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_JournalPeriod] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [Unique_JournalPeriod] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_JournalPeriodAudi]

   ON  [dbo].[JournalPeriod]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[JournalPeriodAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
GO


CREATE TRIGGER [dbo].[Trg_JournalPeriodAudit]

   ON  [dbo].[JournalPeriod]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[JournalPeriodAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
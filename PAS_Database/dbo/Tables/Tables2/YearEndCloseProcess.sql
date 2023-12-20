CREATE TABLE [dbo].[YearEndCloseProcess] (
    [YearEndCloseProcessId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [Year]                  INT             NOT NULL,
    [StartPeriodId]         BIGINT          NULL,
    [EndPeriodId]           BIGINT          NULL,
    [ExecuteDate]           DATETIME2 (7)   NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NOT NULL,
    [CreatedDate]           DATETIME2 (7)   CONSTRAINT [YearEndCloseProcess_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   CONSTRAINT [YearEndCloseProcess_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT             CONSTRAINT [YearEndCloseProcess_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT             CONSTRAINT [YearEndCloseProcess_DC_Delete] DEFAULT ((0)) NOT NULL,
    [LegalEntity]           VARCHAR (100)   NULL,
    [LegalEntityId]         VARCHAR (100)   NULL,
    [Memo]                  VARCHAR (MAX)   NULL,
    [VersionNumber]         VARCHAR (50)    NULL,
    [CurrentVersionNumber]  BIGINT          NULL,
    [IsVersionIncrease]     BIT             NULL,
    [YearEndDate]           DATETIME        NULL,
    [Revenue]               DECIMAL (18, 2) NULL,
    [Expenses]              DECIMAL (18, 2) NULL,
    [NetEarning]            DECIMAL (18, 2) NULL,
    [PreviousYearRevenue]   DECIMAL (18, 2) NULL,
    [NetRevenue]            DECIMAL (18, 2) NULL,
    CONSTRAINT [PK_YearEndCloseProcess] PRIMARY KEY CLUSTERED ([YearEndCloseProcessId] ASC)
);


GO

CREATE TRIGGER [dbo].[Trg_YearEndCloseProcessAudit]

   ON  [dbo].[YearEndCloseProcess]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[YearEndCloseProcessAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;
END
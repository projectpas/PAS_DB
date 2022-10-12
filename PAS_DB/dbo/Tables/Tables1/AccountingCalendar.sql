CREATE TABLE [dbo].[AccountingCalendar] (
    [AccountingCalendarId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]                  VARCHAR (30)   NULL,
    [Description]           VARCHAR (200)  NULL,
    [FiscalName]            VARCHAR (30)   NOT NULL,
    [FiscalYear]            INT            NULL,
    [Quater]                TINYINT        NOT NULL,
    [Period]                TINYINT        NOT NULL,
    [FromDate]              DATE           NULL,
    [ToDate]                DATE           NULL,
    [PeriodName]            VARCHAR (30)   NULL,
    [Notes]                 NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  CONSTRAINT [DF_AccountingCalendar_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  CONSTRAINT [DF_AccountingCalendar_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT            CONSTRAINT [DF_AccountingCalendar_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            CONSTRAINT [DF_AccountingCalendar_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Status]                VARCHAR (256)  NULL,
    [LegalEntityId]         BIGINT         NULL,
    [isUpdate]              BIT            NOT NULL,
    [IsAdjustPeriod]        BIT            NOT NULL,
    [NoOfPeriods]           VARCHAR (50)   NULL,
    [PeriodType]            VARCHAR (50)   NULL,
    [ledgerId]              INT            NULL,
    [IsCurrentActivePeriod] BIT            NULL,
    [StartDate]             DATETIME       NULL,
    [EndDate]               DATETIME       NULL,
    CONSTRAINT [PK_AccountingCalendar] PRIMARY KEY CLUSTERED ([AccountingCalendarId] ASC),
    CONSTRAINT [FK_AccountingCalendar_LegalEntity] FOREIGN KEY ([LegalEntityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId]),
    CONSTRAINT [FK_AccountingCalendar_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);








GO

CREATE TRIGGER [dbo].[Trg_AccountingCalendarAudit] ON [dbo].[AccountingCalendar]

   AFTER INSERT,UPDATE  

AS   

BEGIN  



 INSERT INTO [dbo].[AccountingCalendarAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END
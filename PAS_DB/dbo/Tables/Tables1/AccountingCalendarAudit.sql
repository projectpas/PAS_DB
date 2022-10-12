﻿CREATE TABLE [dbo].[AccountingCalendarAudit] (
    [AccountingCalendarAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AccountingCalendarId]      BIGINT         NOT NULL,
    [Name]                      VARCHAR (30)   NULL,
    [Description]               VARCHAR (200)  NULL,
    [FiscalName]                VARCHAR (30)   NOT NULL,
    [FiscalYear]                INT            NULL,
    [Quater]                    TINYINT        NOT NULL,
    [Period]                    TINYINT        NOT NULL,
    [FromDate]                  DATE           NULL,
    [ToDate]                    DATE           NULL,
    [PeriodName]                VARCHAR (30)   NULL,
    [Notes]                     NVARCHAR (MAX) NULL,
    [MasterCompanyId]           INT            NOT NULL,
    [CreatedBy]                 VARCHAR (256)  NOT NULL,
    [UpdatedBy]                 VARCHAR (256)  NOT NULL,
    [CreatedDate]               DATETIME2 (7)  NOT NULL,
    [UpdatedDate]               DATETIME2 (7)  NOT NULL,
    [IsActive]                  BIT            NOT NULL,
    [IsDeleted]                 BIT            NOT NULL,
    [Status]                    VARCHAR (256)  NULL,
    [LegalEntityId]             BIGINT         NULL,
    [isUpdate]                  BIT            NOT NULL,
    [IsAdjustPeriod]            BIT            NOT NULL,
    [NoOfPeriods]               VARCHAR (50)   NULL,
    [PeriodType]                VARCHAR (50)   NULL,
    [ledgerId]                  INT            NULL,
    [IsCurrentActivePeriod]     BIT            NULL,
    CONSTRAINT [PK__Accounti__4985CDB8D98355DE] PRIMARY KEY CLUSTERED ([AccountingCalendarAuditId] ASC),
    CONSTRAINT [FK_AccountingCalendarAudit_AccountingCalendar] FOREIGN KEY ([AccountingCalendarId]) REFERENCES [dbo].[AccountingCalendar] ([AccountingCalendarId])
);






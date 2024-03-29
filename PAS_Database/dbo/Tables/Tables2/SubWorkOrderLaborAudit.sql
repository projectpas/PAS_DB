﻿CREATE TABLE [dbo].[SubWorkOrderLaborAudit] (
    [SubWorkOrderLaborAuditId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [SubWorkOrderLaborId]       BIGINT          NOT NULL,
    [SubWorkOrderLaborHeaderId] BIGINT          NOT NULL,
    [TaskId]                    BIGINT          NOT NULL,
    [ExpertiseId]               SMALLINT        NULL,
    [EmployeeId]                BIGINT          NULL,
    [Hours]                     DECIMAL (10, 2) NULL,
    [Adjustments]               DECIMAL (10, 2) NULL,
    [AdjustedHours]             DECIMAL (10, 2) NULL,
    [Memo]                      NVARCHAR (MAX)  NULL,
    [StartDate]                 DATETIME2 (7)   NULL,
    [EndDate]                   DATETIME2 (7)   NULL,
    [BillableId]                INT             NULL,
    [IsFromWorkFlow]            BIT             NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   NOT NULL,
    [IsActive]                  BIT             NOT NULL,
    [IsDeleted]                 BIT             NOT NULL,
    [MasterCompanyId]           INT             NULL,
    [DirectLaborOHCost]         DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [BurdaenRatePercentageId]   BIGINT          NULL,
    [BurdenRateAmount]          DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [TotalCostPerHour]          DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [TotalCost]                 DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [TaskStatusId]              BIGINT          NULL,
    [StatusChangedDate]         DATETIME2 (7)   NULL,
    [TaskInstruction]           VARCHAR (MAX)   NULL,
    [IsBegin]                   BIT             NULL,
    CONSTRAINT [PK_SubWorkOrderLaborAudit] PRIMARY KEY CLUSTERED ([SubWorkOrderLaborAuditId] ASC)
);


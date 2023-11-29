﻿CREATE TABLE [dbo].[WorkOrderLaborAudit] (
    [WorkOrderLaborAuditId]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderLaborId]            BIGINT          NOT NULL,
    [WorkOrderLaborAuditHeaderId] BIGINT          NOT NULL,
    [TaskId]                      BIGINT          NOT NULL,
    [ExpertiseId]                 SMALLINT        NULL,
    [EmployeeId]                  BIGINT          NULL,
    [Hours]                       DECIMAL (10, 2) NULL,
    [Adjustments]                 DECIMAL (10, 2) NULL,
    [AdjustedHours]               DECIMAL (10, 2) NULL,
    [Memo]                        NVARCHAR (MAX)  NULL,
    [CreatedBy]                   VARCHAR (256)   NOT NULL,
    [UpdatedBy]                   VARCHAR (256)   NOT NULL,
    [CreatedDate]                 DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)   NOT NULL,
    [IsActive]                    BIT             NOT NULL,
    [IsDeleted]                   BIT             NOT NULL,
    [StartDate]                   DATETIME2 (7)   NULL,
    [EndDate]                     DATETIME2 (7)   NULL,
    [BillableId]                  INT             NULL,
    [IsFromWorkFlow]              BIT             NULL,
    [MasterCompanyId]             INT             NOT NULL,
    [TaskName]                    VARCHAR (256)   NOT NULL,
    [LabourExpertise]             VARCHAR (256)   NOT NULL,
    [LabourEmployee]              VARCHAR (256)   NULL,
    [Billable]                    VARCHAR (10)    NOT NULL,
    [DirectLaborOHCost]           DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [BurdaenRatePercentageId]     BIGINT          NULL,
    [BurdenRateAmount]            DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [TotalCostPerHour]            DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [TotalCost]                   DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [TaskStatusId]                BIGINT          NULL,
    [StatusChangedDate]           DATETIME2 (7)   NULL,
    [IsBegin]                     BIT             NULL,
    CONSTRAINT [PK_WorkOrderLaborAudit] PRIMARY KEY CLUSTERED ([WorkOrderLaborAuditId] ASC)
);




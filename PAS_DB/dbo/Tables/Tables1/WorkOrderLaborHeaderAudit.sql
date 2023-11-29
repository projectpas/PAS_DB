﻿CREATE TABLE [dbo].[WorkOrderLaborHeaderAudit] (
    [WorkOrderLaborAuditId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderLaborHeaderId] BIGINT          NOT NULL,
    [WorkOrderId]            BIGINT          NOT NULL,
    [WorkFlowWorkOrderId]    BIGINT          NOT NULL,
    [DataEnteredBy]          BIGINT          NOT NULL,
    [HoursorClockorScan]     INT             NULL,
    [IsTaskCompletedByOne]   BIT             NULL,
    [WorkOrderHoursType]     INT             NULL,
    [LabourMemo]             NVARCHAR (MAX)  NULL,
    [MasterCompanyId]        INT             NOT NULL,
    [CreatedBy]              VARCHAR (256)   NOT NULL,
    [UpdatedBy]              VARCHAR (256)   NOT NULL,
    [CreatedDate]            DATETIME2 (7)   NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   NOT NULL,
    [IsActive]               BIT             NOT NULL,
    [IsDeleted]              BIT             NOT NULL,
    [ExpertiseId]            SMALLINT        NULL,
    [EmployeeId]             BIGINT          NULL,
    [TotalWorkHours]         DECIMAL (20, 2) NULL,
    [WOPartNoId]             BIGINT          NOT NULL,
    [Expertise]              VARCHAR (256)   NOT NULL,
    [Employee]               VARCHAR (256)   NULL,
    [DataEnteredByName]      VARCHAR (256)   NOT NULL,
    [HoursType]              VARCHAR (50)    NOT NULL,
    [TaskCompletedBy]        VARCHAR (10)    NULL,
    [TaskType]               VARCHAR (256)   NOT NULL,
    CONSTRAINT [PK_WorkOrderLaborHeaderAudit] PRIMARY KEY CLUSTERED ([WorkOrderLaborAuditId] ASC)
);




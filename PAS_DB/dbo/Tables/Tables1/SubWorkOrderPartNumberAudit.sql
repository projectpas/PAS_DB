﻿CREATE TABLE [dbo].[SubWorkOrderPartNumberAudit] (
    [SubWOPartNoAuditId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [SubWOPartNoId]           BIGINT         NOT NULL,
    [WorkOrderId]             BIGINT         NOT NULL,
    [SubWorkOrderId]          BIGINT         NOT NULL,
    [ItemMasterId]            BIGINT         NOT NULL,
    [SubWorkOrderScopeId]     BIGINT         NOT NULL,
    [EstimatedShipDate]       DATETIME2 (7)  NOT NULL,
    [CustomerRequestDate]     DATETIME2 (7)  NOT NULL,
    [PromisedDate]            DATETIME2 (7)  NOT NULL,
    [EstimatedCompletionDate] DATETIME2 (7)  NOT NULL,
    [NTE]                     INT            NULL,
    [Quantity]                INT            NOT NULL,
    [StockLineId]             BIGINT         NULL,
    [CMMId]                   BIGINT         NULL,
    [WorkflowId]              BIGINT         NULL,
    [SubWorkOrderStageId]     BIGINT         NOT NULL,
    [SubWorkOrderStatusId]    BIGINT         NOT NULL,
    [SubWorkOrderPriorityId]  BIGINT         NOT NULL,
    [IsPMA]                   BIT            NULL,
    [IsDER]                   BIT            NULL,
    [TechStationId]           BIGINT         NULL,
    [TATDaysStandard]         INT            NULL,
    [TechnicianId]            BIGINT         NULL,
    [ConditionId]             BIGINT         NOT NULL,
    [TATDaysCurrent]          INT            NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [CreatedBy]               VARCHAR (256)  NOT NULL,
    [UpdatedBy]               VARCHAR (256)  NOT NULL,
    [CreatedDate]             DATETIME2 (7)  NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  NOT NULL,
    [IsActive]                BIT            NOT NULL,
    [IsDeleted]               BIT            NOT NULL,
    [IsClosed]                BIT            NULL,
    [PDFPath]                 NVARCHAR (MAX) NULL,
    [islocked]                BIT            NULL,
    [IsFinishGood]            BIT            DEFAULT ((0)) NULL,
    [RevisedConditionId]      BIGINT         NULL,
    [CustomerReference]       VARCHAR (256)  NULL,
    [RevisedItemmasterid]     BIGINT         NULL,
    [IsTraveler]              BIT            NULL,
    [IsManualForm]            BIT            NULL,
    [IsTransferredToParentWO] BIT            NULL,
    CONSTRAINT [PK_SubWorkOrderPartNumberAudit] PRIMARY KEY CLUSTERED ([SubWOPartNoAuditId] ASC)
);




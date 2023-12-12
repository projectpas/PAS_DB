﻿CREATE TABLE [dbo].[WorkOrderWorkFlowAudit] (
    [WorkFlowWorkOrderAuditId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkFlowWorkOrderId]       BIGINT          NOT NULL,
    [WorkOrderId]               BIGINT          NOT NULL,
    [WorkflowDescription]       VARCHAR (500)   NULL,
    [Version]                   VARCHAR (10)    NULL,
    [WorkScopeId]               BIGINT          NULL,
    [ItemMasterId]              BIGINT          NULL,
    [CustomerId]                BIGINT          NULL,
    [CurrencyId]                INT             NULL,
    [WorkflowExpirationDate]    DATETIME2 (7)   NULL,
    [IsCalculatedBERThreshold]  BIT             NULL,
    [IsFixedAmount]             BIT             NULL,
    [FixedAmount]               NUMERIC (18, 2) NULL,
    [IsPercentageOfNew]         BIT             NULL,
    [CostOfNew]                 NUMERIC (18, 2) NULL,
    [PercentageOfNew]           INT             NULL,
    [IsPercentageOfReplacement] BIT             NULL,
    [CostOfReplacement]         NUMERIC (18, 2) NULL,
    [PercentageOfReplacement]   INT             NULL,
    [Memo]                      NVARCHAR (MAX)  NULL,
    [BERThresholdAmount]        NUMERIC (18, 2) NULL,
    [WorkOrderNumber]           VARCHAR (256)   NULL,
    [OtherCost]                 NUMERIC (18, 2) NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   NOT NULL,
    [IsActive]                  BIT             NOT NULL,
    [IsDeleted]                 BIT             NOT NULL,
    [WorkflowCreateDate]        DATETIME        NULL,
    [WorkflowId]                BIGINT          NULL,
    [WorkFlowWorkOrderNo]       VARCHAR (30)    NULL,
    [ChangedPartNumberId]       BIGINT          NULL,
    [MaterilaCost]              DECIMAL (20, 2) NULL,
    [ExpertiseCost]             DECIMAL (20, 2) NULL,
    [ChargesCost]               DECIMAL (20, 2) NULL,
    [Total]                     DECIMAL (20, 2) NULL,
    [PerOfBerThreshold]         INT             NULL,
    [WorkOrderPartNoId]         BIGINT          NOT NULL,
    CONSTRAINT [PK_WorkFlowWorkOrderAudit] PRIMARY KEY CLUSTERED ([WorkFlowWorkOrderAuditId] ASC)
);


﻿CREATE TABLE [dbo].[WorkOrderLineItemAudit] (
    [WorkOrderLineItemAuditId] INT           IDENTITY (1, 1) NOT NULL,
    [LineItemNumber]           INT           NOT NULL,
    [WorkOrderId]              BIGINT        NOT NULL,
    [PartNumber]               INT           NOT NULL,
    [PartNumberDescription]    VARCHAR (30)  NULL,
    [QuantityRequired]         SMALLINT      NULL,
    [QuantityReserved]         SMALLINT      NULL,
    [QuantityIssued]           SMALLINT      NULL,
    [QuantityTurnIn]           SMALLINT      NULL,
    [StockControlNumber]       INT           NULL,
    [SerialNumber]             VARCHAR (30)  NULL,
    [Condition]                VARCHAR (30)  NULL,
    [ProvisionId]              TINYINT       NULL,
    [SubWorkOrderId]           INT           NULL,
    [PurchaseOrderId]          INT           NULL,
    [RepairOrderId]            INT           NULL,
    [WorkFlowAssignment]       VARCHAR (30)  NULL,
    [MasterComapnyId]          INT           NOT NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedBy]                VARCHAR (256) NOT NULL,
    [CreatedDate]              DATETIME2 (7) NOT NULL,
    [UpdatedDate]              DATETIME2 (7) NOT NULL,
    [IsActive]                 BIT           NOT NULL,
    CONSTRAINT [PK_WorkOrderLineItemAudit] PRIMARY KEY CLUSTERED ([WorkOrderLineItemAuditId] ASC)
);


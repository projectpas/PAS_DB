﻿CREATE TABLE [dbo].[WorkOrderChargesAudit] (
    [WorkOrderChargesAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderChargesId]      BIGINT          NOT NULL,
    [WorkOrderId]             BIGINT          NOT NULL,
    [WorkFlowWorkOrderId]     BIGINT          NOT NULL,
    [ChargesTypeId]           BIGINT          NOT NULL,
    [VendorId]                BIGINT          NULL,
    [Quantity]                INT             NOT NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   NOT NULL,
    [IsActive]                BIT             NOT NULL,
    [IsDeleted]               BIT             NOT NULL,
    [TaskId]                  BIGINT          NOT NULL,
    [Description]             VARCHAR (256)   NULL,
    [UnitCost]                DECIMAL (20, 2) NOT NULL,
    [ExtendedCost]            DECIMAL (20, 2) NULL,
    [IsFromWorkFlow]          BIT             NULL,
    [ReferenceNo]             VARCHAR (20)    NULL,
    [WOPartNoId]              BIGINT          NOT NULL,
    [Task]                    VARCHAR (256)   NOT NULL,
    [ChargeType]              VARCHAR (256)   NOT NULL,
    [GlAccount]               VARCHAR (256)   NULL,
    [Vendor]                  VARCHAR (256)   NULL,
    [UOMId]                   BIGINT          NULL,
    CONSTRAINT [PK_WorkOrderChargesAudit] PRIMARY KEY CLUSTERED ([WorkOrderChargesAuditId] ASC)
);




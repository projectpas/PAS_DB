﻿CREATE TABLE [dbo].[WorkOrderSettlementDetailsAudit] (
    [WorkOrderSettlementDetailAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderSettlementDetailId]      BIGINT         NOT NULL,
    [WorkOrderId]                      BIGINT         NOT NULL,
    [WorkFlowWorkOrderId]              BIGINT         NOT NULL,
    [workOrderPartNoId]                BIGINT         NOT NULL,
    [WorkOrderSettlementId]            BIGINT         NOT NULL,
    [MasterCompanyId]                  INT            NOT NULL,
    [CreatedBy]                        VARCHAR (256)  NOT NULL,
    [UpdatedBy]                        VARCHAR (256)  NOT NULL,
    [CreatedDate]                      DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                      DATETIME2 (7)  NOT NULL,
    [IsActive]                         BIT            NOT NULL,
    [IsDeleted]                        BIT            NOT NULL,
    [IsMastervalue]                    BIT            NULL,
    [Isvalue_NA]                       BIT            NULL,
    [Memo]                             NVARCHAR (MAX) NULL,
    [ConditionId]                      BIGINT         NULL,
    [UserId]                           BIGINT         NULL,
    [UserName]                         VARCHAR (500)  NULL,
    [sattlement_DateTime]              DATETIME       NULL,
    [conditionName]                    VARCHAR (200)  NULL,
    [RevisedPartId]                    BIGINT         NULL,
    CONSTRAINT [PK_WorkOrderSettlementDetailsAudit] PRIMARY KEY CLUSTERED ([WorkOrderSettlementDetailAuditId] ASC)
);


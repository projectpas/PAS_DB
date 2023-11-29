CREATE TABLE [dbo].[SubWorkOrderSettlementDetailsAudit] (
    [SubWorkOrderSettlementDetailAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [SubWorkOrderSettlementDetailId]      BIGINT         NOT NULL,
    [WorkOrderId]                         BIGINT         NOT NULL,
    [SubWorkOrderId]                      BIGINT         NOT NULL,
    [SubWOPartNoId]                       BIGINT         NOT NULL,
    [WorkOrderSettlementId]               BIGINT         NOT NULL,
    [MasterCompanyId]                     INT            NOT NULL,
    [CreatedBy]                           VARCHAR (256)  NOT NULL,
    [UpdatedBy]                           VARCHAR (256)  NOT NULL,
    [CreatedDate]                         DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                         DATETIME2 (7)  NOT NULL,
    [IsActive]                            BIT            NOT NULL,
    [IsDeleted]                           BIT            NOT NULL,
    [IsMastervalue]                       BIT            NULL,
    [Isvalue_NA]                          BIT            NULL,
    [Memo]                                NVARCHAR (MAX) NULL,
    [ConditionId]                         BIGINT         NULL,
    [UserId]                              BIGINT         NULL,
    [UserName]                            VARCHAR (500)  NULL,
    [sattlement_DateTime]                 DATETIME       NULL,
    [conditionName]                       VARCHAR (200)  NULL,
    [RevisedItemmasterid]                 BIGINT         NULL,
    CONSTRAINT [PK_SubWorkOrderSettlementDetailsAudit] PRIMARY KEY CLUSTERED ([SubWorkOrderSettlementDetailAuditId] ASC)
);




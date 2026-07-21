CREATE TYPE [dbo].[SubWorkOrderSettlementDetailType] AS TABLE (
    [SubWorkOrderSettlementDetailId] BIGINT         NOT NULL,
    [WorkOrderId]                    BIGINT         NOT NULL,
    [WorkOrderSettlementId]          BIGINT         NULL,
    [SubWorkOrderId]                 BIGINT         NULL,
    [SubWOPartNoId]                  BIGINT         NULL,
    [IsMastervalue]                  BIT            NULL,
    [Isvalue_NA]                     BIT            NULL,
    [Memo]                           NVARCHAR (MAX) NULL,
    [ConditionId]                    BIGINT         NULL,
    [UserId]                         BIGINT         NULL,
    [UserName]                       NVARCHAR (200) NULL,
    [conditionName]                  NVARCHAR (200) NULL,
    [RevisedItemmasterid]            BIGINT         NULL,
    [UpdatedBy]                      NVARCHAR (100) NULL,
    [UpdatedById]                    BIGINT         NULL);


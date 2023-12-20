CREATE TABLE [dbo].[WorkOrderSettlementDetails] (
    [WorkOrderSettlementDetailId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]                 BIGINT         NOT NULL,
    [WorkFlowWorkOrderId]         BIGINT         NOT NULL,
    [workOrderPartNoId]           BIGINT         NOT NULL,
    [WorkOrderSettlementId]       BIGINT         NOT NULL,
    [MasterCompanyId]             INT            NOT NULL,
    [CreatedBy]                   VARCHAR (256)  NOT NULL,
    [UpdatedBy]                   VARCHAR (256)  NOT NULL,
    [CreatedDate]                 DATETIME2 (7)  CONSTRAINT [DF_WorkOrderSettlementDetails_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)  CONSTRAINT [WorkOrderSettlementDetails_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT            CONSTRAINT [WorkOrderSettlementDetailst_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT            CONSTRAINT [WorkOrderSettlementDetails_DC_Delete] DEFAULT ((0)) NOT NULL,
    [IsMastervalue]               BIT            NULL,
    [Isvalue_NA]                  BIT            NULL,
    [Memo]                        NVARCHAR (MAX) NULL,
    [ConditionId]                 BIGINT         NULL,
    [UserId]                      BIGINT         NULL,
    [UserName]                    VARCHAR (500)  NULL,
    [sattlement_DateTime]         DATETIME       NULL,
    [conditionName]               VARCHAR (200)  NULL,
    [RevisedPartId]               BIGINT         NULL,
    CONSTRAINT [PK_WorkOrderSettlementDetails] PRIMARY KEY CLUSTERED ([WorkOrderSettlementDetailId] ASC),
    CONSTRAINT [FK_WorkOrderSettlementDetails_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_WorkOrderSettlementDetails_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderSettlementDetails_WorkFlowWorkOrderId] FOREIGN KEY ([WorkFlowWorkOrderId]) REFERENCES [dbo].[WorkOrderWorkFlow] ([WorkFlowWorkOrderId]),
    CONSTRAINT [FK_WorkOrderSettlementDetails_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO




----------------------------------------------

Create TRIGGER [dbo].[Trg_WorkOrderSettlementDetailsAudit]

   ON  [dbo].[WorkOrderSettlementDetails]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[WorkOrderSettlementDetailsAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
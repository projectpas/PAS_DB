CREATE TABLE [dbo].[SubWorkOrderSettlementDetails] (
    [SubWorkOrderSettlementDetailId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]                    BIGINT         NOT NULL,
    [SubWorkOrderId]                 BIGINT         NOT NULL,
    [SubWOPartNoId]                  BIGINT         NOT NULL,
    [WorkOrderSettlementId]          BIGINT         NOT NULL,
    [MasterCompanyId]                INT            NOT NULL,
    [CreatedBy]                      VARCHAR (256)  NOT NULL,
    [UpdatedBy]                      VARCHAR (256)  NOT NULL,
    [CreatedDate]                    DATETIME2 (7)  CONSTRAINT [DF_SubWorkOrderSettlementDetails_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7)  CONSTRAINT [SubWorkOrderSettlementDetails_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                       BIT            CONSTRAINT [SubWorkOrderSettlementDetails_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                      BIT            CONSTRAINT [SubWorkOrderSettlementDetails_DC_Delete] DEFAULT ((0)) NOT NULL,
    [IsMastervalue]                  BIT            NULL,
    [Isvalue_NA]                     BIT            NULL,
    [Memo]                           NVARCHAR (MAX) NULL,
    [ConditionId]                    BIGINT         NULL,
    [UserId]                         BIGINT         NULL,
    [UserName]                       VARCHAR (500)  NULL,
    [sattlement_DateTime]            DATETIME       NULL,
    [conditionName]                  VARCHAR (200)  NULL,
    [RevisedItemmasterid]            BIGINT         NULL,
    CONSTRAINT [PK_SubWorkOrderSettlementDetails] PRIMARY KEY CLUSTERED ([SubWorkOrderSettlementDetailId] ASC),
    CONSTRAINT [FK_SubWorkOrderSettlementDetails_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_SubWorkOrderSettlementDetails_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SubWorkOrderSettlementDetails_SubWorkOrderId] FOREIGN KEY ([SubWorkOrderId]) REFERENCES [dbo].[SubWorkOrder] ([SubWorkOrderId]),
    CONSTRAINT [FK_SubWorkOrderSettlementDetails_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);




GO






----------------------------------------------

Create TRIGGER [dbo].[Trg_SubWorkOrderSettlementDetailsAudit]

   ON  [dbo].[SubWorkOrderSettlementDetails]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[SubWorkOrderSettlementDetailsAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
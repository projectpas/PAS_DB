CREATE TABLE [dbo].[WorkOrderQuoteExclusions] (
    [WorkOrderQuoteExclusionsId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderQuoteDetailsId]    BIGINT          NOT NULL,
    [ItemMasterId]               BIGINT          NULL,
    [ExstimtPercentOccuranceId]  INT             NULL,
    [Memo]                       NVARCHAR (MAX)  NULL,
    [Quantity]                   INT             CONSTRAINT [DF_WorkOrderQuoteExclusions_Quantity] DEFAULT ((0)) NULL,
    [UnitCost]                   DECIMAL (20, 3) CONSTRAINT [DF_WorkOrderQuoteExclusions_UnitCost] DEFAULT ((0)) NULL,
    [ExtendedCost]               DECIMAL (20, 3) CONSTRAINT [DF_WorkOrderQuoteExclusions_ExtendedCost] DEFAULT ((0)) NULL,
    [MarkUpPercentageId]         BIGINT          NULL,
    [MasterCompanyId]            INT             NOT NULL,
    [CreatedBy]                  VARCHAR (256)   NOT NULL,
    [UpdatedBy]                  VARCHAR (256)   NOT NULL,
    [CreatedDate]                DATETIME2 (7)   CONSTRAINT [DF_WorkOrderQuoteExclusions_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7)   CONSTRAINT [DF_WorkOrderQuoteExclusions_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                   BIT             DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT             DEFAULT ((0)) NOT NULL,
    [TaskId]                     BIGINT          NULL,
    [MarkupFixedPrice]           VARCHAR (15)    NULL,
    [HeaderMarkupId]             BIGINT          NULL,
    [BillingMethodId]            INT             NULL,
    [BillingRate]                DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderQuoteExclusions_BillingRate] DEFAULT ((0)) NULL,
    [BillingAmount]              DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderQuoteExclusions_BillingAmount] DEFAULT ((0)) NULL,
    [ConditionId]                BIGINT          NULL,
    CONSTRAINT [PK_WorkOrderQuoteExclusions] PRIMARY KEY CLUSTERED ([WorkOrderQuoteExclusionsId] ASC),
    CONSTRAINT [FK_WorkOrderQuoteExclusions_ConditionId] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_WorkOrderQuoteExclusions_ItemMasterId] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_WorkOrderQuoteExclusions_MasterCompanyId] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderQuoteExclusions_TaskId] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkOrderQuoteExclusions_WorkOrderQuoteDetails] FOREIGN KEY ([WorkOrderQuoteDetailsId]) REFERENCES [dbo].[WorkOrderQuoteDetails] ([WorkOrderQuoteDetailsId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderQuoteExclusionsAudit]

   ON  [dbo].[WorkOrderQuoteExclusions]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderQuoteExclusionsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
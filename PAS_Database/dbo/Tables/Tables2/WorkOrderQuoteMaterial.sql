CREATE TABLE [dbo].[WorkOrderQuoteMaterial] (
    [WorkOrderQuoteMaterialId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderQuoteDetailsId]  BIGINT          NOT NULL,
    [ItemMasterId]             BIGINT          NOT NULL,
    [ConditionCodeId]          BIGINT          NOT NULL,
    [ItemClassificationId]     BIGINT          NOT NULL,
    [Quantity]                 INT             NOT NULL,
    [UnitOfMeasureId]          BIGINT          NOT NULL,
    [UnitCost]                 DECIMAL (20, 2) NOT NULL,
    [ExtendedCost]             DECIMAL (20, 2) NOT NULL,
    [Memo]                     NVARCHAR (MAX)  NULL,
    [IsDefered]                BIT             NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_WorkOrderQuoteMaterial_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_WorkOrderQuoteMaterial_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [DF__tmp_ms_xx__IsAct__696EB0A8] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF__tmp_ms_xx__IsDel__6A62D4E1] DEFAULT ((0)) NOT NULL,
    [MarkupPercentageId]       BIGINT          NULL,
    [TaskId]                   BIGINT          NOT NULL,
    [MarkupFixedPrice]         VARCHAR (15)    NULL,
    [BillingAmount]            DECIMAL (20, 2) NULL,
    [BillingRate]              DECIMAL (20, 2) NULL,
    [HeaderMarkupId]           BIGINT          NULL,
    [ProvisionId]              INT             NOT NULL,
    [MaterialMandatoriesId]    INT             CONSTRAINT [DF__tmp_ms_xx__Mater__6B56F91A] DEFAULT ((0)) NULL,
    [BillingMethodId]          INT             NULL,
    [TaskName]                 VARCHAR (100)   NULL,
    [PartNumber]               VARCHAR (50)    NULL,
    [PartDescription]          VARCHAR (500)   NULL,
    [Provision]                VARCHAR (50)    NULL,
    [UomName]                  VARCHAR (50)    NULL,
    [Conditiontype]            VARCHAR (50)    NULL,
    [Stocktype]                VARCHAR (50)    NULL,
    [BillingName]              VARCHAR (50)    NULL,
    [MarkUp]                   VARCHAR (50)    NULL,
    CONSTRAINT [PK_WorkOrderQuoteMaterial] PRIMARY KEY CLUSTERED ([WorkOrderQuoteMaterialId] ASC),
    CONSTRAINT [FK_WorkOrderQuoteMaterial_Condition] FOREIGN KEY ([ConditionCodeId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_WorkOrderQuoteMaterial_ItemClassification] FOREIGN KEY ([ItemClassificationId]) REFERENCES [dbo].[ItemClassification] ([ItemClassificationId]),
    CONSTRAINT [FK_WorkOrderQuoteMaterial_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_WorkOrderQuoteMaterial_MarkupPercentage] FOREIGN KEY ([MarkupPercentageId]) REFERENCES [dbo].[Percent] ([PercentId]),
    CONSTRAINT [FK_WorkOrderQuoteMaterial_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderQuoteMaterial_Provision] FOREIGN KEY ([ProvisionId]) REFERENCES [dbo].[Provision] ([ProvisionId]),
    CONSTRAINT [FK_WorkOrderQuoteMaterial_Task] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkOrderQuoteMaterial_UnitOfMeasure] FOREIGN KEY ([UnitOfMeasureId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_WorkOrderQuoteMaterial_WorkOrderQuoteDetails] FOREIGN KEY ([WorkOrderQuoteDetailsId]) REFERENCES [dbo].[WorkOrderQuoteDetails] ([WorkOrderQuoteDetailsId])
);


GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_WorkOrderQuoteMaterialAudit]

   ON  [dbo].[WorkOrderQuoteMaterial]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[WorkOrderQuoteMaterialAudit] 

    SELECT * 

	FROM INSERTED 

	SET NOCOUNT ON;



END
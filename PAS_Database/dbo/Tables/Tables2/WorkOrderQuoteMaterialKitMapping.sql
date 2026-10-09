CREATE TABLE [dbo].[WorkOrderQuoteMaterialKitMapping] (
    [WOQMaterialKitMappingId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderQuoteId]        BIGINT          NOT NULL,
    [WorkflowWorkOrderId]     BIGINT          NOT NULL,
    [kitId]                   BIGINT          NOT NULL,
    [KitNumber]               VARCHAR (256)   NULL,
    [ItemMasterId]            BIGINT          NOT NULL,
    [TaskId]                  BIGINT          NULL,
    [Quantity]                DECIMAL (18, 6) NULL,
    [UnitCost]                DECIMAL (28, 6) NULL,
    [ExtendedCost]            DECIMAL (28, 6) NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_WorkOrderQuoteMaterialKitMapping_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [DF_WorkOrderQuoteMaterialKitMapping_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT             CONSTRAINT [DF__WorkOrderQuoteMaterialKitMapping__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT             CONSTRAINT [DF__WorkOrderQuoteMaterialKitMapping__IsDeleted] DEFAULT ((0)) NOT NULL,
    [Memo]                    NVARCHAR (MAX)  NULL,
    [MarkupPercentageId]      BIGINT          NULL,
    [MarkupFixedPrice]        VARCHAR (15)    NULL,
    [BillingAmount]           DECIMAL (28, 6) NULL,
    [BillingRate]             DECIMAL (28, 6) NULL,
    [HeaderMarkupId]          BIGINT          NULL,
    [BillingMethodId]         INT             NULL,
    [BillingName]             VARCHAR (50)    NULL,
    [MarkUp]                  VARCHAR (50)    NULL,
    CONSTRAINT [PK_WorkOrderQuoteMaterialKitMapping] PRIMARY KEY CLUSTERED ([WOQMaterialKitMappingId] ASC),
    CONSTRAINT [FK_WorkOrderQuoteMaterialKitMapping_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_WorkOrderQuoteMaterialKitMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);
GO

----------------------------------------------

CREATE TRIGGER [dbo].[Trg_WorkOrderQuoteMaterialKitMappingAudit]

   ON  [dbo].[WorkOrderQuoteMaterialKitMapping]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[WorkOrderQuoteMaterialKitMappingAudit] 
	(
		[WOQMaterialKitMappingId],
		[WorkOrderQuoteId],
		[WorkflowWorkOrderId],
		[kitId],
		[KitNumber],
		[ItemMasterId],
		[TaskId],
		[Quantity],
		[UnitCost],
		[ExtendedCost],
		[MasterCompanyId],
		[CreatedBy],
		[UpdatedBy],
		[CreatedDate],
		[UpdatedDate],
		[IsActive],
		[IsDeleted],
		[Memo],
		[MarkupPercentageId],
		[MarkupFixedPrice],
		[BillingAmount],
		[BillingRate],
		[HeaderMarkupId],
		[BillingMethodId],
		[BillingName],
		[MarkUp]
	)
    SELECT 
		i.[WOQMaterialKitMappingId],
		i.[WorkOrderQuoteId],
		i.[WorkflowWorkOrderId],
		i.[kitId],
		i.[KitNumber],
		i.[ItemMasterId],
		i.[TaskId],
		i.[Quantity],
		i.[UnitCost],
		i.[ExtendedCost],
		i.[MasterCompanyId],
		i.[CreatedBy],
		i.[UpdatedBy],
		CASE WHEN d.[WOQMaterialKitMappingId] IS NULL THEN GETUTCDATE() ELSE i.[CreatedDate] END,
		GETUTCDATE(),
		i.[IsActive],
		i.[IsDeleted],
		i.[Memo],
		i.[MarkupPercentageId],
		i.[MarkupFixedPrice],
		i.[BillingAmount],
		i.[BillingRate],
		i.[HeaderMarkupId],
		i.[BillingMethodId],
		i.[BillingName],
		i.[MarkUp]
	FROM INSERTED i
	LEFT JOIN DELETED d ON d.[WOQMaterialKitMappingId] = i.[WOQMaterialKitMappingId];

	SET NOCOUNT ON;

END



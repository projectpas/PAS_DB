CREATE TABLE [dbo].[PurchaseOrderSettingMaster] (
    [PurchaseOrderSettingId]         BIGINT        IDENTITY (1, 1) NOT NULL,
    [IsResale]                       BIT           CONSTRAINT [DF_PurchaseOrderSettingMaster_IsResale] DEFAULT ((0)) NOT NULL,
    [IsDeferredReceiver]             BIT           CONSTRAINT [DF_PurchaseOrderSettingMaster_IsDeferredReceiver] DEFAULT ((0)) NOT NULL,
    [IsEnforceApproval]              BIT           CONSTRAINT [DF_PurchaseOrderSettingMaster_IsEnforceApproval] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]                INT           NOT NULL,
    [CreatedBy]                      VARCHAR (256) NOT NULL,
    [UpdatedBy]                      VARCHAR (256) NOT NULL,
    [CreatedDate]                    DATETIME2 (7) CONSTRAINT [DF_PurchaseOrderSettingMaster_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7) CONSTRAINT [DF_PurchaseOrderSettingMaster_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                       BIT           CONSTRAINT [DF_PurchaseOrderSettingMaster_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                      BIT           CONSTRAINT [DF_PurchaseOrderSettingMaster_IsDelete] DEFAULT ((0)) NOT NULL,
    [Effectivedate]                  DATETIME2 (7) NULL,
    [PriorityId]                     BIGINT        NULL,
    [Priority]                       VARCHAR (100) NULL,
    [WorkOrderStageId]               BIGINT        NULL,
    [WorkOrderStage]                 VARCHAR (100) NULL,
    [IsRequestor]                    BIT           NULL,
    [IsEnforceNonPoApproval]         BIT           NULL,
    [IsAutoReserveReceivedStockline] BIT           NULL,
    [IsCreateStocklineWithoutDraft]  BIT           NULL,
    CONSTRAINT [PK_PurchaseOrderSettingMaster] PRIMARY KEY CLUSTERED ([PurchaseOrderSettingId] ASC),
    CONSTRAINT [FK_PurchaseOrderSettingMaster_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_PurchaseOrderSettingMasterAudit]

   ON  [dbo].[PurchaseOrderSettingMaster]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO PurchaseOrderSettingMasterAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
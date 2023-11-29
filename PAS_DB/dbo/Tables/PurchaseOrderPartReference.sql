CREATE TABLE [dbo].[PurchaseOrderPartReference] (
    [PurchaseOrderPartReferenceId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [PurchaseOrderId]              BIGINT        NULL,
    [PurchaseOrderPartId]          BIGINT        NULL,
    [ModuleId]                     INT           NULL,
    [ReferenceId]                  BIGINT        NULL,
    [Qty]                          INT           NULL,
    [RequestedQty]                 INT           NULL,
    [ReservedQty]                  INT           NULL,
    [MasterCompanyId]              INT           NOT NULL,
    [CreatedBy]                    VARCHAR (256) NOT NULL,
    [UpdatedBy]                    VARCHAR (256) NOT NULL,
    [CreatedDate]                  DATETIME2 (7) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7) NOT NULL,
    [IsActive]                     BIT           CONSTRAINT [PurchaseOrderPartReference_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                    BIT           CONSTRAINT [DF_PurchaseOrderPartReference_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_PurchaseOrderPartReferences] PRIMARY KEY CLUSTERED ([PurchaseOrderPartReferenceId] ASC),
    CONSTRAINT [FK_PurchaseOrderPartReference_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


CREATE TABLE [dbo].[VendorRFQPurchaseOrderPartReference] (
    [VendorRFQPurchaseOrderPartReferenceId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorRFQPurchaseOrderId]              BIGINT        NULL,
    [VendorRFQPOPartRecordId]               BIGINT        NULL,
    [ModuleId]                              INT           NULL,
    [ReferenceId]                           BIGINT        NULL,
    [Qty]                                   INT           NULL,
    [RequestedQty]                          INT           NULL,
    [IsReserved]                            BIT           NULL,
    [MasterCompanyId]                       INT           NOT NULL,
    [CreatedBy]                             VARCHAR (256) NOT NULL,
    [UpdatedBy]                             VARCHAR (256) NOT NULL,
    [CreatedDate]                           DATETIME2 (7) NOT NULL,
    [UpdatedDate]                           DATETIME2 (7) NOT NULL,
    [IsActive]                              BIT           CONSTRAINT [VendorRFQPurchaseOrderPartReference_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                             BIT           CONSTRAINT [DF_VendorRFQPurchaseOrderPartReference_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorRFQPurchaseOrderPartReference] PRIMARY KEY CLUSTERED ([VendorRFQPurchaseOrderPartReferenceId] ASC),
    CONSTRAINT [FK_VendorRFQPurchaseOrderPartReference_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


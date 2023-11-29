CREATE TABLE [dbo].[PurchaseOrder] (
    [PurchaseOrderId]          BIGINT          IDENTITY (1, 1) NOT NULL,
    [PurchaseOrderNumber]      VARCHAR (50)    NOT NULL,
    [OpenDate]                 DATETIME2 (7)   NOT NULL,
    [ClosedDate]               DATETIME2 (7)   NULL,
    [NeedByDate]               DATETIME        NOT NULL,
    [PriorityId]               BIGINT          NOT NULL,
    [Priority]                 VARCHAR (100)   NULL,
    [VendorId]                 BIGINT          NOT NULL,
    [VendorName]               VARCHAR (100)   NULL,
    [VendorCode]               VARCHAR (100)   NULL,
    [VendorContactId]          BIGINT          NOT NULL,
    [VendorContact]            VARCHAR (100)   NULL,
    [VendorContactPhone]       VARCHAR (50)    NULL,
    [CreditTermsId]            INT             NULL,
    [Terms]                    VARCHAR (500)   NULL,
    [CreditLimit]              DECIMAL (18)    NULL,
    [RequestedBy]              BIGINT          NOT NULL,
    [Requisitioner]            VARCHAR (100)   NULL,
    [StatusId]                 BIGINT          NOT NULL,
    [Status]                   VARCHAR (100)   NULL,
    [StatusChangeDate]         DATETIME2 (7)   NULL,
    [Resale]                   BIT             NOT NULL,
    [DeferredReceiver]         BIT             NOT NULL,
    [ApproverId]               BIGINT          CONSTRAINT [PurchaseOrder_ApproverId] DEFAULT ((0)) NULL,
    [ApprovedBy]               VARCHAR (100)   NULL,
    [DateApproved]             DATETIME2 (7)   NULL,
    [POMemo]                   NVARCHAR (MAX)  NULL,
    [Notes]                    NVARCHAR (MAX)  NULL,
    [ManagementStructureId]    BIGINT          NOT NULL,
    [Level1]                   VARCHAR (200)   NULL,
    [Level2]                   VARCHAR (200)   NULL,
    [Level3]                   VARCHAR (200)   NULL,
    [Level4]                   VARCHAR (200)   NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [PurchaseOrder_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF__PurchaseO__IsDel__7A1D154F] DEFAULT ((0)) NOT NULL,
    [IsEnforce]                BIT             NULL,
    [PDFPath]                  NVARCHAR (100)  NULL,
    [VendorRFQPurchaseOrderId] BIGINT          NULL,
    [FreightBilingMethodId]    INT             NULL,
    [TotalFreight]             DECIMAL (18, 2) NULL,
    [ChargesBilingMethodId]    INT             NULL,
    [TotalCharges]             DECIMAL (18, 2) NULL,
    [IsFromBulkPO]             BIT             NULL,
    [IsLotAssigned]            BIT             NULL,
    [LotId]                    BIGINT          NULL,
    [VendorContactEmail]       VARCHAR (50)    NULL,
    CONSTRAINT [PK_PurchaseOrder] PRIMARY KEY CLUSTERED ([PurchaseOrderId] ASC),
    CONSTRAINT [FK_PurchaseOrder_ApproverId] FOREIGN KEY ([ApproverId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_PurchaseOrder_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_PurchaseOrder_POStatus] FOREIGN KEY ([StatusId]) REFERENCES [dbo].[POStatus] ([POStatusId]),
    CONSTRAINT [FK_PurchaseOrder_Priority] FOREIGN KEY ([PriorityId]) REFERENCES [dbo].[Priority] ([PriorityId]),
    CONSTRAINT [FK_PurchaseOrder_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_PurchaseOrder_VendorContact] FOREIGN KEY ([VendorContactId]) REFERENCES [dbo].[VendorContact] ([VendorContactId])
);






GO


-- =============================================

CREATE TRIGGER [dbo].[Trg_PurchaseOrderAudit]

   ON  [dbo].[PurchaseOrder]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO PurchaseOrderAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
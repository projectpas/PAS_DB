CREATE TABLE [dbo].[VendorRFQPurchaseOrder] (
    [VendorRFQPurchaseOrderId]     BIGINT         IDENTITY (1, 1) NOT NULL,
    [VendorRFQPurchaseOrderNumber] VARCHAR (50)   NOT NULL,
    [OpenDate]                     DATETIME2 (7)  NOT NULL,
    [ClosedDate]                   DATETIME2 (7)  NULL,
    [NeedByDate]                   DATETIME       NOT NULL,
    [PriorityId]                   BIGINT         NOT NULL,
    [Priority]                     VARCHAR (100)  NULL,
    [VendorId]                     BIGINT         NOT NULL,
    [VendorName]                   VARCHAR (100)  NULL,
    [VendorCode]                   VARCHAR (100)  NULL,
    [VendorContactId]              BIGINT         NOT NULL,
    [VendorContact]                VARCHAR (100)  NULL,
    [VendorContactPhone]           VARCHAR (50)   NULL,
    [CreditTermsId]                INT            NULL,
    [Terms]                        VARCHAR (500)  NULL,
    [CreditLimit]                  DECIMAL (18)   NULL,
    [RequestedBy]                  BIGINT         NOT NULL,
    [Requisitioner]                VARCHAR (100)  NULL,
    [StatusId]                     BIGINT         NOT NULL,
    [Status]                       VARCHAR (100)  NULL,
    [StatusChangeDate]             DATETIME2 (7)  NULL,
    [Resale]                       BIT            NOT NULL,
    [DeferredReceiver]             BIT            NOT NULL,
    [Memo]                         NVARCHAR (MAX) NULL,
    [Notes]                        NVARCHAR (MAX) NULL,
    [ManagementStructureId]        BIGINT         NOT NULL,
    [Level1]                       VARCHAR (200)  NULL,
    [Level2]                       VARCHAR (200)  NULL,
    [Level3]                       VARCHAR (200)  NULL,
    [Level4]                       VARCHAR (200)  NULL,
    [MasterCompanyId]              INT            NOT NULL,
    [CreatedBy]                    VARCHAR (256)  NOT NULL,
    [UpdatedBy]                    VARCHAR (256)  NOT NULL,
    [CreatedDate]                  DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                  DATETIME2 (7)  NOT NULL,
    [IsActive]                     BIT            CONSTRAINT [VendorRFQPurchaseOrder_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                    BIT            CONSTRAINT [DF__VendorRFQPurchaseOrder__IsDel__7A1D154F] DEFAULT ((0)) NOT NULL,
    [PDFPath]                      NVARCHAR (100) NULL,
    CONSTRAINT [PK_VendorRFQPurchaseOrder] PRIMARY KEY CLUSTERED ([VendorRFQPurchaseOrderId] ASC),
    FOREIGN KEY ([StatusId]) REFERENCES [dbo].[VendorRFQStatus] ([VendorRFQStatusId]),
    FOREIGN KEY ([StatusId]) REFERENCES [dbo].[VendorRFQStatus] ([VendorRFQStatusId]),
    FOREIGN KEY ([StatusId]) REFERENCES [dbo].[VendorRFQStatus] ([VendorRFQStatusId]),
    CONSTRAINT [FK_VendorRFQPurchaseOrder_ManagementStructure] FOREIGN KEY ([ManagementStructureId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [FK_VendorRFQPurchaseOrder_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorRFQPurchaseOrder_Priority] FOREIGN KEY ([PriorityId]) REFERENCES [dbo].[Priority] ([PriorityId]),
    CONSTRAINT [FK_VendorRFQPurchaseOrder_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_VendorRFQPurchaseOrder_VendorContact] FOREIGN KEY ([VendorContactId]) REFERENCES [dbo].[VendorContact] ([VendorContactId])
);


GO


CREATE TRIGGER [dbo].[TrgVendorRFQPurchaseOrderAudit]
   ON [dbo].[VendorRFQPurchaseOrder]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	INSERT INTO [dbo].[VendorRFQPurchaseOrderAudit]
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END
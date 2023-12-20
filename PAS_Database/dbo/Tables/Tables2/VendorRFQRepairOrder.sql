CREATE TABLE [dbo].[VendorRFQRepairOrder] (
    [VendorRFQRepairOrderId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [VendorRFQRepairOrderNumber] VARCHAR (50)    NULL,
    [OpenDate]                   DATETIME2 (7)   NOT NULL,
    [ClosedDate]                 DATETIME2 (7)   NULL,
    [NeedByDate]                 DATETIME2 (7)   NOT NULL,
    [PriorityId]                 BIGINT          NOT NULL,
    [Priority]                   VARCHAR (100)   NULL,
    [VendorId]                   BIGINT          NOT NULL,
    [VendorName]                 VARCHAR (100)   NULL,
    [VendorCode]                 VARCHAR (100)   NULL,
    [VendorContactId]            BIGINT          NOT NULL,
    [VendorContact]              VARCHAR (100)   NULL,
    [VendorContactPhone]         VARCHAR (100)   NULL,
    [CreditTermsId]              INT             NULL,
    [Terms]                      VARCHAR (100)   NULL,
    [CreditLimit]                DECIMAL (18, 2) NULL,
    [RequisitionerId]            BIGINT          NOT NULL,
    [Requisitioner]              VARCHAR (100)   NULL,
    [StatusId]                   BIGINT          NOT NULL,
    [Status]                     VARCHAR (100)   NULL,
    [StatusChangeDate]           DATETIME2 (7)   NULL,
    [Resale]                     BIT             NULL,
    [DeferredReceiver]           BIT             NULL,
    [Memo]                       NVARCHAR (MAX)  NULL,
    [Notes]                      NVARCHAR (MAX)  NULL,
    [ManagementStructureId]      BIGINT          NOT NULL,
    [Level1]                     VARCHAR (200)   NULL,
    [Level2]                     VARCHAR (200)   NULL,
    [Level3]                     VARCHAR (200)   NULL,
    [Level4]                     VARCHAR (200)   NULL,
    [MasterCompanyId]            INT             CONSTRAINT [DF__VendorRFQRepairOrder__Maste__70429E0D] DEFAULT ((1)) NOT NULL,
    [CreatedBy]                  VARCHAR (256)   NOT NULL,
    [UpdatedBy]                  VARCHAR (256)   NOT NULL,
    [CreatedDate]                DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                DATETIME2 (7)   NULL,
    [IsActive]                   BIT             CONSTRAINT [VendorRFQRepairOrder_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT             CONSTRAINT [DF__VendorRFQRepairOrder__IsDel__7FD5EEA5] DEFAULT ((0)) NOT NULL,
    [PDFPath]                    NVARCHAR (100)  NULL,
    CONSTRAINT [PK_VendorRFQRepairOrder] PRIMARY KEY CLUSTERED ([VendorRFQRepairOrderId] ASC),
    CONSTRAINT [FK_VendorRFQRepairOrder_CreditTermsId] FOREIGN KEY ([CreditTermsId]) REFERENCES [dbo].[CreditTerms] ([CreditTermsId]),
    CONSTRAINT [FK_VendorRFQRepairOrder_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorRFQRepairOrder_PriorityId] FOREIGN KEY ([PriorityId]) REFERENCES [dbo].[Priority] ([PriorityId]),
    CONSTRAINT [FK_VendorRFQRepairOrder_RequisitionerId] FOREIGN KEY ([RequisitionerId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_VendorRFQRepairOrder_ROStatus] FOREIGN KEY ([StatusId]) REFERENCES [dbo].[VendorRFQStatus] ([VendorRFQStatusId]),
    CONSTRAINT [FK_VendorRFQRepairOrder_VendorContact] FOREIGN KEY ([VendorContactId]) REFERENCES [dbo].[VendorContact] ([VendorContactId]),
    CONSTRAINT [FK_VendorRFQRepairOrder_VendorId] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId])
);


GO




CREATE TRIGGER [dbo].[TrgVendorRFQRepairOrderAudit]
   ON [dbo].[VendorRFQRepairOrder]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	INSERT INTO [dbo].[VendorRFQRepairOrderAudit]
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END
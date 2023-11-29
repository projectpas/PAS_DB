CREATE TABLE [dbo].[CustomerRMAHeader] (
    [RMAHeaderId]           BIGINT          IDENTITY (1, 1) NOT NULL,
    [RMANumber]             VARCHAR (100)   NOT NULL,
    [CustomerId]            BIGINT          NOT NULL,
    [CustomerName]          VARCHAR (100)   NULL,
    [CustomerCode]          VARCHAR (100)   NULL,
    [CustomerContactId]     BIGINT          NULL,
    [ContactInfo]           VARCHAR (100)   NULL,
    [OpenDate]              DATETIME        NOT NULL,
    [InvoiceId]             BIGINT          NOT NULL,
    [InvoiceNo]             VARCHAR (50)    NOT NULL,
    [InvoiceDate]           DATETIME        NOT NULL,
    [RMAStatusId]           BIGINT          NOT NULL,
    [RMAStatus]             VARCHAR (100)   NULL,
    [Iswarranty]            BIT             CONSTRAINT [CustomerRMAHeader_DC_Iswarranty] DEFAULT ((0)) NOT NULL,
    [ValidDate]             DATETIME        NOT NULL,
    [RequestedId]           BIGINT          NOT NULL,
    [Requestedby]           VARCHAR (50)    NULL,
    [ApprovedbyId]          BIGINT          NULL,
    [Approvedby]            VARCHAR (100)   NULL,
    [ApprovedDate]          DATETIME        NULL,
    [ReturnDate]            DATETIME        NULL,
    [WorkOrderId]           BIGINT          NULL,
    [WorkOrderNum]          VARCHAR (50)    NULL,
    [ManagementStructureId] BIGINT          NOT NULL,
    [Notes]                 NVARCHAR (MAX)  NULL,
    [Memo]                  NVARCHAR (MAX)  NULL,
    [isWorkOrder]           BIT             CONSTRAINT [CustomerRMAHeader_DC_isWorkOrder] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NOT NULL,
    [CreatedDate]           DATETIME2 (7)   CONSTRAINT [DF_CustomerRMAHeader_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   CONSTRAINT [DF_CustomerRMAHeader_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT             CONSTRAINT [CustomerRMAHeader_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT             CONSTRAINT [CustomerRMAHeader_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ReferenceId]           BIGINT          NOT NULL,
    [PDFPath]               NVARCHAR (2000) NULL,
    [ReceiverNum]           VARCHAR (30)    NULL,
    CONSTRAINT [PK_CustomerRMAHeader] PRIMARY KEY CLUSTERED ([RMAHeaderId] ASC),
    CONSTRAINT [FK_CustomerRMAHeader_CustomerId] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CustomerRMAHeader_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_CustomerRMAHeader_RMAStatusId] FOREIGN KEY ([RMAStatusId]) REFERENCES [dbo].[RMAStatus] ([RMAStatusId])
);






GO




CREATE TRIGGER [dbo].[Trg_CustomerRMAHeaderAudit]

   ON  [dbo].[CustomerRMAHeader]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[CustomerRMAHeaderAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;



END
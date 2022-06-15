CREATE TABLE [dbo].[CreditMemo] (
    [CreditMemoHeaderId]    BIGINT          IDENTITY (1, 1) NOT NULL,
    [CreditMemoNumber]      VARCHAR (50)    NOT NULL,
    [RMAHeaderId]           BIGINT          NULL,
    [RMANumber]             VARCHAR (50)    NULL,
    [InvoiceId]             BIGINT          NULL,
    [InvoiceNumber]         VARCHAR (50)    NULL,
    [InvoiceDate]           DATETIME2 (7)   NULL,
    [StatusId]              INT             NOT NULL,
    [Status]                VARCHAR (50)    NULL,
    [CustomerId]            BIGINT          NOT NULL,
    [CustomerName]          VARCHAR (100)   NULL,
    [CustomerCode]          VARCHAR (50)    NULL,
    [CustomerContactId]     BIGINT          NULL,
    [CustomerContact]       VARCHAR (100)   NULL,
    [CustomerContactPhone]  VARCHAR (20)    NULL,
    [IsWarranty]            BIT             NULL,
    [IsAccepted]            BIT             NULL,
    [ReasonId]              BIGINT          NULL,
    [Reason]                VARCHAR (50)    NULL,
    [DeniedMemo]            NVARCHAR (MAX)  NULL,
    [RequestedById]         BIGINT          NOT NULL,
    [RequestedBy]           VARCHAR (100)   NULL,
    [ApproverId]            BIGINT          NULL,
    [ApprovedBy]            VARCHAR (100)   NULL,
    [WONum]                 VARCHAR (50)    NULL,
    [WorkOrderId]           BIGINT          NULL,
    [Originalwosonum]       VARCHAR (50)    NULL,
    [Memo]                  NVARCHAR (MAX)  NULL,
    [Notes]                 NVARCHAR (MAX)  NULL,
    [ManagementStructureId] BIGINT          NOT NULL,
    [IsEnforce]             BIT             NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NOT NULL,
    [CreatedDate]           DATETIME2 (7)   NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   NOT NULL,
    [IsActive]              BIT             CONSTRAINT [DF_CreditMemo_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT             CONSTRAINT [DF_CreditMemo_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsWorkOrder]           BIT             NULL,
    [DateApproved]          DATETIME2 (7)   NULL,
    [ReferenceId]           BIGINT          NULL,
    [ReturnDate]            DATETIME2 (7)   NULL,
    [PDFPath]               NVARCHAR (100)  NULL,
    [FreightBilingMethodId] INT             NULL,
    [TotalFreight]          DECIMAL (20, 2) NULL,
    [ChargesBilingMethodId] INT             NULL,
    [TotalCharges]          DECIMAL (18, 2) NULL,
    CONSTRAINT [PK_CreditMemo] PRIMARY KEY CLUSTERED ([CreditMemoHeaderId] ASC),
    CONSTRAINT [FK_CreditMemo_ApproverId] FOREIGN KEY ([ApproverId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_CREDITMEMO_CUSTOMER] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CreditMemo_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_CREDITMEMO_RequestedById] FOREIGN KEY ([RequestedById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_CreditMemo_Status] FOREIGN KEY ([StatusId]) REFERENCES [dbo].[CreditMemoStatus] ([Id])
);






GO







CREATE TRIGGER [dbo].[Trg_CreditMemoAudit]
ON  [dbo].[CreditMemo]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO [dbo].[CreditMemoAudit]
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END
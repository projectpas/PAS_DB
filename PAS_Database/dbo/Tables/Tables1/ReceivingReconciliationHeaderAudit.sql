CREATE TABLE [dbo].[ReceivingReconciliationHeaderAudit] (
    [AuditReceivingReconciliationId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ReceivingReconciliationId]      BIGINT          NOT NULL,
    [ReceivingReconciliationNumber]  VARCHAR (50)    NOT NULL,
    [InvoiceNum]                     VARCHAR (50)    NULL,
    [StatusId]                       INT             NOT NULL,
    [Status]                         VARCHAR (50)    NULL,
    [VendorId]                       BIGINT          NOT NULL,
    [VendorName]                     VARCHAR (100)   NULL,
    [CurrencyId]                     INT             NULL,
    [CurrencyName]                   VARCHAR (50)    NULL,
    [OpenDate]                       DATETIME        NULL,
    [OriginalTotal]                  DECIMAL (18, 2) NULL,
    [RRTotal]                        DECIMAL (18, 2) NULL,
    [InvoiceTotal]                   DECIMAL (18, 2) NULL,
    [DIfferenceAmount]               DECIMAL (18, 2) NULL,
    [TotalAdjustAmount]              DECIMAL (18, 2) NULL,
    [MasterCompanyId]                INT             NULL,
    [CreatedBy]                      VARCHAR (256)   NOT NULL,
    [UpdatedBy]                      VARCHAR (256)   NOT NULL,
    [CreatedDate]                    DATETIME2 (7)   CONSTRAINT [DF_ReceivingReconciliationHeaderAudit_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7)   CONSTRAINT [DF_ReceivingReconciliationHeaderAudit_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                       BIT             CONSTRAINT [DF_ReceivingReconciliationHeaderAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                      BIT             CONSTRAINT [DF_ReceivingReconciliationHeaderAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [InvoiceDate]                    DATETIME2 (7)   NULL,
    [AccountingCalendarId]           BIGINT          NULL,
    [IsInvoiceOnHold]                BIT             NULL,
    [ManagementStructureId]          BIGINT          NULL,
    [LegalEntityId]                  BIGINT          NULL,
    CONSTRAINT [PK_ReceivingReconciliationHeaderAudit] PRIMARY KEY CLUSTERED ([AuditReceivingReconciliationId] ASC)
);




﻿CREATE TABLE [dbo].[VendorRFQPurchaseOrderAudit] (
    [VendorRFQPurchaseOrderAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [VendorRFQPurchaseOrderId]      BIGINT          NOT NULL,
    [VendorRFQPurchaseOrderNumber]  VARCHAR (50)    NOT NULL,
    [OpenDate]                      DATETIME2 (7)   NOT NULL,
    [ClosedDate]                    DATETIME2 (7)   NULL,
    [NeedByDate]                    DATETIME        NOT NULL,
    [PriorityId]                    BIGINT          NOT NULL,
    [Priority]                      VARCHAR (100)   NULL,
    [VendorId]                      BIGINT          NOT NULL,
    [VendorName]                    VARCHAR (100)   NULL,
    [VendorCode]                    VARCHAR (100)   NULL,
    [VendorContactId]               BIGINT          NOT NULL,
    [VendorContact]                 VARCHAR (100)   NULL,
    [VendorContactPhone]            VARCHAR (50)    NULL,
    [CreditTermsId]                 INT             NULL,
    [Terms]                         VARCHAR (500)   NULL,
    [CreditLimit]                   DECIMAL (18)    NULL,
    [RequestedBy]                   BIGINT          NOT NULL,
    [Requisitioner]                 VARCHAR (100)   NULL,
    [StatusId]                      BIGINT          NOT NULL,
    [Status]                        VARCHAR (100)   NULL,
    [StatusChangeDate]              DATETIME2 (7)   NULL,
    [Resale]                        BIT             NOT NULL,
    [DeferredReceiver]              BIT             NOT NULL,
    [Memo]                          NVARCHAR (MAX)  NULL,
    [Notes]                         NVARCHAR (MAX)  NULL,
    [ManagementStructureId]         BIGINT          NOT NULL,
    [Level1]                        VARCHAR (200)   NULL,
    [Level2]                        VARCHAR (200)   NULL,
    [Level3]                        VARCHAR (200)   NULL,
    [Level4]                        VARCHAR (200)   NULL,
    [MasterCompanyId]               INT             NOT NULL,
    [CreatedBy]                     VARCHAR (256)   NOT NULL,
    [UpdatedBy]                     VARCHAR (256)   NOT NULL,
    [CreatedDate]                   DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   NOT NULL,
    [IsActive]                      BIT             CONSTRAINT [DF_VendorRFQPurchaseOrderAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT             CONSTRAINT [DF_VendorRFQPurchaseOrderAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [PDFPath]                       NVARCHAR (100)  NULL,
    [IsFromBulkPO]                  BIT             NULL,
    [FreightBilingMethodId]         INT             NULL,
    [TotalFreight]                  DECIMAL (18, 2) NULL,
    [ChargesBilingMethodId]         INT             NULL,
    [TotalCharges]                  DECIMAL (18, 2) NULL,
    [VendorReference]               VARCHAR (100)   NULL,
    [FunctionalCurrencyId]          INT             NULL,
    [ReportCurrencyId]              INT             NULL,
    [ForeignExchangeRate]           DECIMAL (18, 2) NULL,
    CONSTRAINT [PK_VendorRFQPurchaseOrderAudit] PRIMARY KEY CLUSTERED ([VendorRFQPurchaseOrderAuditId] ASC)
);










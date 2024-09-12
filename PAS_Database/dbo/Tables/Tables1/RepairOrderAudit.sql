﻿CREATE TABLE [dbo].[RepairOrderAudit] (
    [RepairOrderAuditId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [RepairOrderId]          BIGINT          NOT NULL,
    [RepairOrderNumber]      VARCHAR (50)    NULL,
    [OpenDate]               DATETIME2 (7)   NOT NULL,
    [ClosedDate]             DATETIME2 (7)   NULL,
    [NeedByDate]             DATETIME2 (7)   NOT NULL,
    [PriorityId]             BIGINT          NOT NULL,
    [Priority]               VARCHAR (100)   NULL,
    [VendorId]               BIGINT          NOT NULL,
    [VendorName]             VARCHAR (100)   NULL,
    [VendorCode]             VARCHAR (100)   NULL,
    [VendorContactId]        BIGINT          NOT NULL,
    [VendorContact]          VARCHAR (100)   NULL,
    [VendorContactPhone]     VARCHAR (100)   NULL,
    [CreditTermsId]          INT             NULL,
    [Terms]                  VARCHAR (100)   NULL,
    [CreditLimit]            DECIMAL (18, 2) NULL,
    [RequisitionerId]        BIGINT          NOT NULL,
    [Requisitioner]          VARCHAR (100)   NULL,
    [StatusId]               BIGINT          NOT NULL,
    [Status]                 VARCHAR (100)   NULL,
    [StatusChangeDate]       DATETIME2 (7)   NULL,
    [Resale]                 BIT             NULL,
    [DeferredReceiver]       BIT             NULL,
    [RoMemo]                 NVARCHAR (MAX)  NULL,
    [Notes]                  NVARCHAR (MAX)  NULL,
    [ApproverId]             BIGINT          NULL,
    [ApprovedBy]             VARCHAR (100)   NULL,
    [ApprovedDate]           DATETIME2 (7)   NULL,
    [ManagementStructureId]  BIGINT          NOT NULL,
    [Level1]                 VARCHAR (200)   NULL,
    [Level2]                 VARCHAR (200)   NULL,
    [Level3]                 VARCHAR (200)   NULL,
    [Level4]                 VARCHAR (200)   NULL,
    [MasterCompanyId]        INT             NOT NULL,
    [CreatedBy]              VARCHAR (256)   NOT NULL,
    [UpdatedBy]              VARCHAR (256)   NOT NULL,
    [CreatedDate]            DATETIME2 (7)   NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   NULL,
    [IsActive]               BIT             NOT NULL,
    [IsDeleted]              BIT             NOT NULL,
    [IsEnforce]              BIT             NULL,
    [PDFPath]                NVARCHAR (100)  NULL,
    [VendorRFQRepairOrderId] BIGINT          NULL,
    [FreightBilingMethodId]  INT             NULL,
    [TotalFreight]           DECIMAL (18, 2) NULL,
    [ChargesBilingMethodId]  INT             NULL,
    [TotalCharges]           DECIMAL (18, 2) NULL,
    [IsLotAssigned]          BIT             NULL,
    [LotId]                  BIGINT          NULL,
    [VendorContactEmail]     VARCHAR (50)    NULL,
    [FunctionalCurrencyId]   INT             NULL,
    [ReportCurrencyId]       INT             NULL,
    [ForeignExchangeRate]    DECIMAL (18, 2) NULL,
    CONSTRAINT [PK_RepairOrderAudit] PRIMARY KEY CLUSTERED ([RepairOrderAuditId] ASC)
);




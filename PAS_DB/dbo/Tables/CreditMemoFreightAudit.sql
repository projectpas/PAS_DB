﻿CREATE TABLE [dbo].[CreditMemoFreightAudit] (
    [CreditMemoFreightAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [CreditMemoFreightId]      BIGINT          NOT NULL,
    [CreditMemoHeaderId]       BIGINT          NOT NULL,
    [CreditMemoDetailId]       BIGINT          NOT NULL,
    [ItemMasterId]             BIGINT          NULL,
    [PartNumber]               VARCHAR (150)   NULL,
    [ShipViaId]                BIGINT          NOT NULL,
    [ShipViaName]              VARCHAR (100)   NULL,
    [MarkupPercentageId]       BIGINT          NULL,
    [MarkupFixedPrice]         DECIMAL (20, 2) NULL,
    [HeaderMarkupId]           BIGINT          NULL,
    [BillingMethodId]          INT             NULL,
    [BillingRate]              DECIMAL (20, 2) NULL,
    [BillingAmount]            DECIMAL (20, 2) NULL,
    [HeaderMarkupPercentageId] BIGINT          NULL,
    [Weight]                   VARCHAR (50)    NULL,
    [UOMId]                    BIGINT          NULL,
    [UOMName]                  VARCHAR (100)   NULL,
    [Length]                   DECIMAL (10, 2) NULL,
    [Width]                    DECIMAL (10, 2) NULL,
    [Height]                   DECIMAL (10, 2) NULL,
    [DimensionUOMId]           BIGINT          NULL,
    [DimensionUOMName]         VARCHAR (100)   NULL,
    [CurrencyId]               INT             NULL,
    [CurrencyName]             VARCHAR (100)   NULL,
    [Amount]                   DECIMAL (20, 3) NOT NULL,
    [Memo]                     NVARCHAR (MAX)  NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_CreditMemoFreightAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_CreditMemoFreightAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [DF_CreditMemoFreightAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF_CreditMemoFreightAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CreditMemoFreightAudit] PRIMARY KEY CLUSTERED ([CreditMemoFreightAuditId] ASC)
);


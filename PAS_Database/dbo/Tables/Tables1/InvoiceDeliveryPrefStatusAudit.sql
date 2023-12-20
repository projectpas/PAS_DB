CREATE TABLE [dbo].[InvoiceDeliveryPrefStatusAudit] (
    [InvDelPrefStatusAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [InvDelPrefStatusId]      BIGINT         NOT NULL,
    [Status]                  NVARCHAR (100) NOT NULL,
    [Memo]                    NVARCHAR (MAX) NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [CreatedBy]               VARCHAR (256)  NOT NULL,
    [UpdatedBy]               VARCHAR (256)  NOT NULL,
    [CreatedDate]             DATETIME2 (7)  CONSTRAINT [DF_InvoiceDeliveryPrefStatusAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  CONSTRAINT [DF_InvoiceDeliveryPrefStatusAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT            CONSTRAINT [DF_InvoiceDeliveryPrefStatusAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT            CONSTRAINT [DF_InvoiceDeliveryPrefStatusAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [SequenceNo]              INT            NULL,
    CONSTRAINT [PK_InvoiceDeliveryPrefStatusAudit] PRIMARY KEY CLUSTERED ([InvDelPrefStatusAuditId] ASC)
);


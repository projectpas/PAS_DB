CREATE TABLE [dbo].[CustomerRefund] (
    [CustomerRefundId]      BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerId]            BIGINT        NOT NULL,
    [CustomerCode]          VARCHAR (200) NULL,
    [RefundRequestDate]     DATETIME2 (7) NULL,
    [Status]                VARCHAR (100) NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [ManagementStructureId] BIGINT        NOT NULL,
    [CreatedBy]             VARCHAR (50)  NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [DF_CustomerRefund_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]             VARCHAR (50)  NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [DF_CustomerRefund_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [DF__CustomerRefund__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [DF__CustomerRefund__IsDeleted] DEFAULT ((0)) NOT NULL,
    [VendorId]              BIGINT        NULL,
    CONSTRAINT [PK_CustomerRefund] PRIMARY KEY CLUSTERED ([CustomerRefundId] ASC)
);




CREATE TABLE [dbo].[CustomerRfqPartMapping] (
    [CustomerRfqPartMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerRfqId]            BIGINT        NOT NULL,
    [Notes]                    VARCHAR (MAX) NULL,
    [PartNumber]               VARCHAR (250) NULL,
    [PartDescription]          VARCHAR (250) NULL,
    [AltPartNumber]            VARCHAR (250) NULL,
    [Quantity]                 INT           NULL,
    [Condition]                VARCHAR (250) NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [CreatedBy]                VARCHAR (50)  NOT NULL,
    [CreatedDate]              DATETIME2 (7) CONSTRAINT [DF_CustomerRfqPartMapping_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                VARCHAR (50)  NOT NULL,
    [UpdatedDate]              DATETIME2 (7) CONSTRAINT [DF_CustomerRfqPartMapping_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                 BIT           CONSTRAINT [DF_CustomerRfqPartMappingIsActi_59FA5E80] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT           CONSTRAINT [DF_CustomerRfqPartMappingIsDele_5AEE82B9] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CustomerRfqPartMapping] PRIMARY KEY CLUSTERED ([CustomerRfqPartMappingId] ASC),
    CONSTRAINT [FK_CustomerRfqPartMapping_CustomerRFQ] FOREIGN KEY ([CustomerRfqId]) REFERENCES [dbo].[CustomerRfq] ([CustomerRfqId]) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT [FK_CustomerRfqPartMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


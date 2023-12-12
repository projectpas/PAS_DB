CREATE TABLE [dbo].[CustomerCCPaymentsStatus] (
    [Id]              INT          IDENTITY (1, 1) NOT NULL,
    [StatusId]        INT          NOT NULL,
    [StatusName]      VARCHAR (50) NULL,
    [MasterCompanyId] INT          NOT NULL,
    [CreatedBy]       VARCHAR (50) NOT NULL,
    [CreatedDate]     DATETIME     CONSTRAINT [DF_CustomerCCPaymentsStatus_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (50) NULL,
    [UpdatedDate]     DATETIME     CONSTRAINT [DF_CustomerCCPaymentsStatus_UpdatedDate] DEFAULT (getutcdate()) NULL,
    [IsActive]        BIT          CONSTRAINT [DF_CustomerCCPaymentsStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT          CONSTRAINT [DF_CustomerCCPaymentsStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CustomerCCPaymentsStatus] PRIMARY KEY CLUSTERED ([Id] ASC)
);


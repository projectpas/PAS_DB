CREATE TABLE [dbo].[SupportedPaymentMethods] (
    [Id]                INT          IDENTITY (1, 1) NOT NULL,
    [PaymentMethodName] VARCHAR (50) NULL,
    [MasterCompanyId]   INT          NOT NULL,
    [CreatedBy]         VARCHAR (50) NOT NULL,
    [CreatedDate]       DATETIME     CONSTRAINT [DF_SupportedPaymentMethods_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]         VARCHAR (50) NULL,
    [UpdatedDate]       DATETIME     CONSTRAINT [DF_SupportedPaymentMethods_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]          BIT          CONSTRAINT [DF_SupportedPaymentMethods_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT          CONSTRAINT [DF_SupportedPaymentMethods_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SupportedPaymentMethods] PRIMARY KEY CLUSTERED ([Id] ASC)
);


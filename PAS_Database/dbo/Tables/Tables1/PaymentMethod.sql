CREATE TABLE [dbo].[PaymentMethod] (
    [PaymentMethodId] INT           IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (250) NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_PaymentMethod_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_PaymentMethod_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_PaymentMethod_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_PaymentMethod_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_PaymentMethod] PRIMARY KEY CLUSTERED ([PaymentMethodId] ASC)
);


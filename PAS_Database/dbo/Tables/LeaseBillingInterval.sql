CREATE TABLE [dbo].[LeaseBillingInterval] (
    [LeaseBillingIntervalId] INT            IDENTITY (1, 1) NOT NULL,
    [LeaseBillingInterval]   NVARCHAR (100) NOT NULL,
    [Code]                   VARCHAR (50)   NOT NULL,
    [Description]            NVARCHAR (500) NULL,
    [MasterCompanyId]        INT            NOT NULL,
    [CreatedBy]              VARCHAR (100)  NULL,
    [UpdatedBy]              VARCHAR (100)  NULL,
    [CreatedDate]            DATETIME       CONSTRAINT [DF_LeaseBillingInterval_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]            DATETIME       CONSTRAINT [DF_LeaseBillingInterval_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]               BIT            CONSTRAINT [DF_LeaseBillingInterval_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT            CONSTRAINT [DF_LeaseBillingInterval_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LeaseBillingInterval] PRIMARY KEY CLUSTERED ([LeaseBillingIntervalId] ASC)
);


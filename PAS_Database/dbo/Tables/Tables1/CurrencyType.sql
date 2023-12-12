﻿CREATE TABLE [dbo].[CurrencyType] (
    [CurrencyTypeId]  INT           IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (100) NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_CurrencyType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_CurrencyType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_CurrencyType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_CurrencyType_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CurrencyType] PRIMARY KEY CLUSTERED ([CurrencyTypeId] ASC)
);


﻿CREATE TABLE [dbo].[Contact] (
    [ContactId]       BIGINT         IDENTITY (1, 1) NOT NULL,
    [Prefix]          VARCHAR (20)   NULL,
    [FirstName]       VARCHAR (100)  NOT NULL,
    [LastName]        VARCHAR (30)   NOT NULL,
    [MiddleName]      VARCHAR (30)   NULL,
    [Suffix]          VARCHAR (20)   NULL,
    [ContactTitle]    VARCHAR (30)   NULL,
    [WorkPhone]       VARCHAR (20)   NULL,
    [WorkPhoneExtn]   VARCHAR (20)   NULL,
    [MobilePhone]     VARCHAR (20)   NULL,
    [AlternatePhone]  VARCHAR (20)   NULL,
    [Fax]             VARCHAR (20)   NULL,
    [Email]           VARCHAR (200)  NULL,
    [WebsiteURL]      VARCHAR (200)  NULL,
    [Notes]           NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Contact_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Contact_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [Contact_DC_Active] DEFAULT ((1)) NOT NULL,
    [Tag]             VARCHAR (255)  CONSTRAINT [DF__Contact__Tag__10416098] DEFAULT ('') NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_Contact_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ContactTagId]    BIGINT         NULL,
    [Attention]       VARCHAR (250)  NULL,
    CONSTRAINT [PK_Contact] PRIMARY KEY CLUSTERED ([ContactId] ASC),
    CONSTRAINT [FK_Contact_ContactTagId] FOREIGN KEY ([ContactTagId]) REFERENCES [dbo].[ContactTag] ([ContactTagId]),
    CONSTRAINT [FK_Contact_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


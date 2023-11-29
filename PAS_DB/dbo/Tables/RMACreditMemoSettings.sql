CREATE TABLE [dbo].[RMACreditMemoSettings] (
    [Id]                 BIGINT         IDENTITY (1, 1) NOT NULL,
    [RMAStatusId]        INT            NOT NULL,
    [RMAStatus]          VARCHAR (50)   NULL,
    [RMAReasonId]        INT            NULL,
    [RMAReason]          VARCHAR (1000) NULL,
    [RMAValiddate]       DATETIME2 (7)  NULL,
    [CreditMemoStatusId] INT            NOT NULL,
    [CreditMemoStatus]   VARCHAR (50)   NULL,
    [CreditMemoReasonId] INT            NULL,
    [CreditMemoReason]   VARCHAR (1000) NULL,
    [IsEnforceApproval]  BIT            CONSTRAINT [DF_RMACreditMemoSettings_IsEnforceApproval] DEFAULT ((0)) NOT NULL,
    [Effectivedate]      DATETIME2 (7)  NULL,
    [MasterCompanyId]    INT            NOT NULL,
    [CreatedBy]          VARCHAR (256)  NOT NULL,
    [UpdatedBy]          VARCHAR (256)  NOT NULL,
    [CreatedDate]        DATETIME2 (7)  CONSTRAINT [DF_RMACreditMemoSettings_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]        DATETIME2 (7)  CONSTRAINT [DF_RMACreditMemoSettings_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]           BIT            CONSTRAINT [DF_RMACreditMemoSettings_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT            CONSTRAINT [DF_RMACreditMemoSettings_IsDelete] DEFAULT ((0)) NOT NULL,
    [ValidDays]          INT            NULL,
    CONSTRAINT [PK_RMACreditMemoSettings] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_RMACreditMemoSettings_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




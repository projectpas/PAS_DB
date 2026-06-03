CREATE TABLE [dbo].[TrialBalanceUpload] (
    [TrialBalanceUploadId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Status]               VARCHAR (50)   NULL,
    [TotalRecords]         BIGINT         NULL,
    [ErrorDetails]         NVARCHAR (MAX) NULL,
    [FilePath]             NVARCHAR (MAX) NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [CreatedDate]          DATETIME2 (7)  CONSTRAINT [TrialBalanceUpload_DC_CDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  CONSTRAINT [TrialBalanceUpload_DC_UDate] DEFAULT (getutcdate()) NOT NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [IsActive]             BIT            CONSTRAINT [D_TrialBalanceUpload_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT            CONSTRAINT [D_TrialBalanceUpload_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_TrialBalanceUpload] PRIMARY KEY CLUSTERED ([TrialBalanceUploadId] ASC),
    CONSTRAINT [FK_TrialBalanceUpload_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


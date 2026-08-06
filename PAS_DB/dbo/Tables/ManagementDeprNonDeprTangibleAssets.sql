CREATE TABLE [dbo].[ManagementDeprNonDeprTangibleAssets] (
    [ManagementDeprNonDeprTangibleAssetsId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ManagementStructureId]                 BIGINT        NOT NULL,
    [DeprNonDeprTangibleAssetsId]           BIGINT        NOT NULL,
    [MasterCompanyId]                       INT           NOT NULL,
    [CreatedBy]                             VARCHAR (256) NOT NULL,
    [UpdatedBy]                             VARCHAR (256) NOT NULL,
    [CreatedDate]                           DATETIME2 (7) CONSTRAINT [DF_ManagementDeprNonDeprTangibleAssets_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                           DATETIME2 (7) CONSTRAINT [DF_ManagementDeprNonDeprTangibleAssets_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                              BIT           CONSTRAINT [DF_ManagementDeprNonDeprTangibleAssets_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                             BIT           CONSTRAINT [DF_ManagementDeprNonDeprTangibleAssets_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ManagementDeprNonDeprTangibleAssets] PRIMARY KEY CLUSTERED ([ManagementDeprNonDeprTangibleAssetsId] ASC),
    CONSTRAINT [FK_ManagementDeprNonDeprTangibleAssets_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


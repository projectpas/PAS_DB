CREATE TABLE [dbo].[DeprNonDeprTangibleAssets] (
    [DeprNonDeprTangibleAssetsId]    BIGINT        IDENTITY (1, 1) NOT NULL,
    [DeprNonDeprTangibleClassTypeId] BIGINT        NULL,
    [TangibleClassId]                BIGINT        NOT NULL,
    [Description]                    VARCHAR (500) NULL,
    [AssetDeprMethodId]              BIGINT        NULL,
    [CalibratedGLAccountId]          BIGINT        NULL,
    [AcquiredGLAccountId]            BIGINT        NULL,
    [DeprExpenseGLAccountId]         BIGINT        NULL,
    [AccumDeprGLAccountId]           BIGINT        NULL,
    [AssetSaleGLAccountId]           BIGINT        NULL,
    [AssetWriteOffGLAccountId]       BIGINT        NULL,
    [AssetWriteDownGLAccountId]      BIGINT        NULL,
    [ManagementStructureId]          BIGINT        NULL,
    [MasterCompanyId]                INT           NOT NULL,
    [CreatedBy]                      VARCHAR (256) NOT NULL,
    [UpdatedBy]                      VARCHAR (256) NOT NULL,
    [CreatedDate]                    DATETIME2 (7) CONSTRAINT [DF_DeprNonDeprTangibleAssets_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7) CONSTRAINT [DF_DeprNonDeprTangibleAssets_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                       BIT           NOT NULL,
    [IsDeleted]                      BIT           CONSTRAINT [DF_DeprNonDeprTangibleAssets_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ResidualPercentage]             BIGINT        NULL,
    [AssetLife]                      INT           NULL,
    [DepreciationFrequencyId]        BIGINT        NULL,
    CONSTRAINT [PK_DeprNonDeprTangibleAssets] PRIMARY KEY CLUSTERED ([DeprNonDeprTangibleAssetsId] ASC),
    CONSTRAINT [FK_DeprNonDeprTangibleAssets_ManagementStructure] FOREIGN KEY ([ManagementStructureId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [FK_DeprNonDeprTangibleAssets_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);
















GO



CREATE TRIGGER [dbo].[Trg_DeprNonDeprTangibleAssetsAudit]

   ON  [dbo].[DeprNonDeprTangibleAssets]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO dbo.DeprNonDeprTangibleAssetsAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END
GO

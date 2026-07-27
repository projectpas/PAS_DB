CREATE TABLE [dbo].[ManagementDeprNonDeprTangibleAssetsAudit] (
    [ManagementDeprNonDeprTangibleAssetsAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ManagementSiteId]                           BIGINT        NOT NULL,
    [ManagementStructureId]                      BIGINT        NOT NULL,
    [DeprNonDeprTangibleAssetsId]                BIGINT        NOT NULL,
    [MasterCompanyId]                            INT           NOT NULL,
    [CreatedBy]                                  VARCHAR (256) NOT NULL,
    [UpdatedBy]                                  VARCHAR (256) NOT NULL,
    [CreatedDate]                                DATETIME2 (7) NOT NULL,
    [UpdatedDate]                                DATETIME2 (7) NOT NULL,
    [IsActive]                                   BIT           NOT NULL,
    [IsDeleted]                                  BIT           NOT NULL,
    CONSTRAINT [PK_ManagementDeprNonDeprTangibleAssetsAudit] PRIMARY KEY CLUSTERED ([ManagementDeprNonDeprTangibleAssetsAuditId] ASC)
);


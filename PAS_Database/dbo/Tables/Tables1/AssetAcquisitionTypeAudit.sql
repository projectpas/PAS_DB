CREATE TABLE [dbo].[AssetAcquisitionTypeAudit] (
    [AssetAcquisitionTypeAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetAcquisitionTypeId]      BIGINT         NOT NULL,
    [Name]                        VARCHAR (256)  NOT NULL,
    [Memo]                        NVARCHAR (MAX) NULL,
    [IsDeleted]                   BIT            NOT NULL,
    [IsActive]                    BIT            NOT NULL,
    [CreatedBy]                   VARCHAR (256)  NOT NULL,
    [UpdatedBy]                   VARCHAR (256)  NOT NULL,
    [CreatedDate]                 DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)  NOT NULL,
    [MasterCompanyId]             INT            NOT NULL,
    [Code]                        VARCHAR (256)  NOT NULL,
    [Description]                 VARCHAR (500)  NULL,
    [SequenceNo]                  INT            NULL,
    PRIMARY KEY CLUSTERED ([AssetAcquisitionTypeAuditId] ASC)
);


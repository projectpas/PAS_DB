CREATE TABLE [dbo].[AssetDocumentDetailsAudit] (
    [AssetDocumentDetailAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetDocumentDetailId]      BIGINT         NOT NULL,
    [AssetRecordId]              BIGINT         NOT NULL,
    [AttachmentId]               BIGINT         NOT NULL,
    [DocName]                    VARCHAR (100)  NOT NULL,
    [DocMemo]                    NVARCHAR (MAX) NULL,
    [DocDescription]             VARCHAR (100)  NULL,
    [MasterCompanyId]            INT            NOT NULL,
    [CreatedBy]                  VARCHAR (256)  NOT NULL,
    [UpdatedBy]                  VARCHAR (256)  NOT NULL,
    [CreatedDate]                DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                DATETIME2 (7)  NOT NULL,
    [IsActive]                   BIT            NOT NULL,
    [IsDeleted]                  BIT            NOT NULL,
    [IsMaintenance]              BIT            NULL,
    [IsWarranty]                 BIT            NULL,
    CONSTRAINT [PK_AssetDocumentDetailsAudit] PRIMARY KEY CLUSTERED ([AssetDocumentDetailAuditId] ASC)
);


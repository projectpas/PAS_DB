CREATE TABLE [dbo].[CustomerContactATAMappingAudit] (
    [AuditCustomerContactATAMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerContactATAMappingId]      BIGINT        NOT NULL,
    [CustomerId]                       BIGINT        NOT NULL,
    [CustomerContactId]                BIGINT        NOT NULL,
    [ATAChapterId]                     BIGINT        NOT NULL,
    [ATAChapterCode]                   VARCHAR (256) NULL,
    [ATAChapterName]                   VARCHAR (250) NOT NULL,
    [ATASubChapterId]                  BIGINT        NULL,
    [ATASubChapterDescription]         VARCHAR (256) NULL,
    [MasterCompanyId]                  INT           NOT NULL,
    [CreatedBy]                        VARCHAR (256) NOT NULL,
    [UpdatedBy]                        VARCHAR (256) NOT NULL,
    [CreatedDate]                      DATETIME2 (7) NOT NULL,
    [UpdatedDate]                      DATETIME2 (7) NOT NULL,
    [IsActive]                         BIT           CONSTRAINT [CustomerContactATAMappingAudit_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                        BIT           CONSTRAINT [CustomerContactATAMappingAudit_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ATASubChapterCode]                VARCHAR (250) NULL,
    CONSTRAINT [PK_CustomerContactATAMappingAudit] PRIMARY KEY CLUSTERED ([AuditCustomerContactATAMappingId] ASC),
    CONSTRAINT [FK_CustomerContactATAMappingAudit_CustomerContactATAMapping] FOREIGN KEY ([CustomerContactATAMappingId]) REFERENCES [dbo].[CustomerContactATAMapping] ([CustomerContactATAMappingId])
);


CREATE TABLE [dbo].[AssetAmortizationIntervalAudit] (
    [AssetAmortizationIntervalAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetAmortizationIntervalId]      BIGINT         NOT NULL,
    [AssetAmortizationIntervalCode]    VARCHAR (30)   NULL,
    [AssetAmortizationIntervalName]    VARCHAR (50)   NULL,
    [AssetAmortizationIntervalMemo]    NVARCHAR (MAX) NULL,
    [MasterCompanyId]                  INT            NULL,
    [CreatedBy]                        VARCHAR (256)  NULL,
    [UpdatedBy]                        VARCHAR (256)  NULL,
    [CreatedDate]                      DATETIME2 (7)  NULL,
    [UpdatedDate]                      DATETIME2 (7)  NOT NULL,
    [IsActive]                         BIT            NULL,
    [IsDeleted]                        BIT            NULL,
    CONSTRAINT [PK_AssetAmortizationIntervalAudit] PRIMARY KEY CLUSTERED ([AssetAmortizationIntervalAuditId] ASC),
    CONSTRAINT [FK_AssetAmortizationIntervalAudit_AssetAmortizationInterval] FOREIGN KEY ([AssetAmortizationIntervalId]) REFERENCES [dbo].[AssetAmortizationInterval] ([AssetAmortizationIntervalId])
);


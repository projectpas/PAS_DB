CREATE TABLE [dbo].[VendorClassificationAudit] (
    [VendorClassificationAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [VendorClassificationId]      BIGINT         NOT NULL,
    [ClassificationName]          VARCHAR (256)  NOT NULL,
    [Memo]                        NVARCHAR (MAX) NULL,
    [MasterCompanyId]             INT            NOT NULL,
    [CreatedBy]                   VARCHAR (256)  NOT NULL,
    [UpdatedBy]                   VARCHAR (256)  NOT NULL,
    [CreatedDate]                 DATETIME2 (7)  CONSTRAINT [VendorClassificationAudit_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)  CONSTRAINT [VendorClassificationAudit_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT            CONSTRAINT [VendorClassificationAudit_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT            CONSTRAINT [VendorClassificationAudit_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorClassificationAudit] PRIMARY KEY CLUSTERED ([VendorClassificationAuditId] ASC)
);


CREATE TABLE [dbo].[CustomerClassificationAudit] (
    [CustomerClassificationAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [CustomerClassificationId]      BIGINT         NOT NULL,
    [Description]                   NVARCHAR (500) NULL,
    [Memo]                          NVARCHAR (MAX) NULL,
    [MasterCompanyId]               INT            NOT NULL,
    [CreatedBy]                     VARCHAR (256)  NOT NULL,
    [UpdatedBy]                     VARCHAR (256)  NOT NULL,
    [CreatedDate]                   DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)  NOT NULL,
    [IsActive]                      BIT            CONSTRAINT [CustomerClassificationAudit_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT            CONSTRAINT [CustomerClassificationAudit_DC_Delete] DEFAULT ((0)) NOT NULL,
    [SequenceNo]                    INT            NULL,
    CONSTRAINT [PK_CustomerClassificationAudit] PRIMARY KEY CLUSTERED ([CustomerClassificationAuditId] ASC)
);


CREATE TABLE [dbo].[CarrierAudit] (
    [CarrierAuditId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [CarrierId]       BIGINT         NOT NULL,
    [Description]     VARCHAR (100)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    CONSTRAINT [PK_CarrierAudit] PRIMARY KEY CLUSTERED ([CarrierAuditId] ASC)
);


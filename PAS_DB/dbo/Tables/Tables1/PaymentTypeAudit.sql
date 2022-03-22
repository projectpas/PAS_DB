CREATE TABLE [dbo].[PaymentTypeAudit] (
    [PaymentTypeAuditId] TINYINT       IDENTITY (1, 1) NOT NULL,
    [PaymentTypeId]      TINYINT       NOT NULL,
    [Description]        VARCHAR (50)  NOT NULL,
    [Comments]           VARCHAR (100) NULL,
    CONSTRAINT [PK_PaymentTypeAudit] PRIMARY KEY CLUSTERED ([PaymentTypeAuditId] ASC)
);


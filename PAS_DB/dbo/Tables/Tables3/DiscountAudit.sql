CREATE TABLE [dbo].[DiscountAudit] (
    [AuditDiscountId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [DiscountId]      BIGINT          NOT NULL,
    [DiscontValue]    DECIMAL (18, 2) NOT NULL,
    [MasterCompanyId] INT             NOT NULL,
    [CreatedBy]       NVARCHAR (256)  NOT NULL,
    [UpdatedBy]       NVARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)   NOT NULL,
    [UpdatedDate]     DATETIME2 (7)   NOT NULL,
    [IsActive]        BIT             NOT NULL,
    [IsDeleted]       BIT             NOT NULL,
    [Description]     VARCHAR (MAX)   NULL,
    [Memo]            NVARCHAR (MAX)  NULL,
    CONSTRAINT [PK__DiscountAudit] PRIMARY KEY CLUSTERED ([AuditDiscountId] ASC)
);


CREATE TABLE [dbo].[ItemMasterPurchaseSaleMasterAudit] (
    [AuditItemMasterPurchaseSaleMasterId] INT            IDENTITY (1, 1) NOT NULL,
    [ItemMasterPurchaseSaleMasterId]      INT            NOT NULL,
    [Name]                                VARCHAR (100)  NOT NULL,
    [Memo]                                NVARCHAR (MAX) NULL,
    [MasterCompanyId]                     INT            NOT NULL,
    [CreatedBy]                           NVARCHAR (256) NOT NULL,
    [UpdatedBy]                           NVARCHAR (256) NOT NULL,
    [CreatedDate]                         DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                         DATETIME2 (7)  NULL,
    [IsActive]                            BIT            NOT NULL,
    [IsDeleted]                           BIT            NOT NULL,
    CONSTRAINT [PK_ItemMasterPurchaseSaleMasterAudit] PRIMARY KEY CLUSTERED ([AuditItemMasterPurchaseSaleMasterId] ASC)
);


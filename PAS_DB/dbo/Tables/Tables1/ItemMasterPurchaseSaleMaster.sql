CREATE TABLE [dbo].[ItemMasterPurchaseSaleMaster] (
    [ItemMasterPurchaseSaleMasterId] INT            IDENTITY (1, 1) NOT NULL,
    [Name]                           VARCHAR (100)  NOT NULL,
    [Memo]                           NVARCHAR (MAX) NULL,
    [MasterCompanyId]                INT            NOT NULL,
    [CreatedBy]                      NVARCHAR (256) NOT NULL,
    [UpdatedBy]                      NVARCHAR (256) NOT NULL,
    [CreatedDate]                    DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                    DATETIME2 (7)  NULL,
    [IsActive]                       BIT            NOT NULL,
    [IsDeleted]                      BIT            NOT NULL,
    CONSTRAINT [PK_ItemMasterPurchaseSaleMaster] PRIMARY KEY CLUSTERED ([ItemMasterPurchaseSaleMasterId] ASC)
);


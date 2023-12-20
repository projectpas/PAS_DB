CREATE TABLE [dbo].[BalanceTypeAudit] (
    [BalanceTypeId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [ID]              BIGINT         NOT NULL,
    [Description]     VARCHAR (256)  NOT NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    [BalanceTypeName] VARCHAR (256)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_BalanceTypeAudit] PRIMARY KEY CLUSTERED ([BalanceTypeId] ASC)
);


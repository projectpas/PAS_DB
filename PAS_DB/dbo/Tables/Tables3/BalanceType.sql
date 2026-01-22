CREATE TABLE [dbo].[BalanceType] (
    [ID]              BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (256)  NOT NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [BalanceType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [BalanceType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [D_BalanceType_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [D_BalanceType_Delete] DEFAULT ((0)) NOT NULL,
    [BalanceTypeName] VARCHAR (256)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_BalanceType] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_BalanceType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_BalanceType] UNIQUE NONCLUSTERED ([BalanceTypeName] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_BalanceTypeAudit]

   ON  [dbo].[BalanceType]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO BalanceTypeAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END
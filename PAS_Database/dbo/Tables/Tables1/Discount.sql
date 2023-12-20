CREATE TABLE [dbo].[Discount] (
    [DiscountId]      BIGINT          IDENTITY (1, 1) NOT NULL,
    [DiscontValue]    DECIMAL (18, 2) NOT NULL,
    [MasterCompanyId] INT             NOT NULL,
    [CreatedBy]       NVARCHAR (256)  NOT NULL,
    [UpdatedBy]       NVARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)   CONSTRAINT [DF_Discount_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)   CONSTRAINT [DF_Discount_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]        BIT             CONSTRAINT [DF__Discount__IsActi__226010D3] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT             CONSTRAINT [DF__Discount__IsDele__2354350C] DEFAULT ((0)) NOT NULL,
    [Description]     VARCHAR (MAX)   NULL,
    [Memo]            NVARCHAR (MAX)  NULL,
    CONSTRAINT [PK__Discount__E43F6D963F493CDE] PRIMARY KEY CLUSTERED ([DiscountId] ASC),
    CONSTRAINT [FK_Discount_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_Discount] UNIQUE NONCLUSTERED ([DiscontValue] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_DiscountAudit]

   ON  [dbo].[Discount]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO DiscountAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END
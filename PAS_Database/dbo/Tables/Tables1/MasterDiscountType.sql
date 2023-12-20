CREATE TABLE [dbo].[MasterDiscountType] (
    [Id]              INT           IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (50)  NULL,
    [Description]     VARCHAR (250) NULL,
    [GLAccountId]     BIGINT        NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (50)  NOT NULL,
    [CreatedDate]     DATETIME      CONSTRAINT [DF__MasterDis__Creat__42439BD7] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (50)  NULL,
    [UpdatedDate]     DATETIME      CONSTRAINT [MasterDiscountType_DC_UDate] DEFAULT (getdate()) NULL,
    [IsActive]        BIT           CONSTRAINT [MasterDiscountType_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [MasterDiscountType_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_MasterDiscountType] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_MasterDiscountTypeAudit]
ON  [dbo].[MasterDiscountType]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO [dbo].[MasterDiscountTypeAudit]
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END
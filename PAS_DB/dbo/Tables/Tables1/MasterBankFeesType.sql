CREATE TABLE [dbo].[MasterBankFeesType] (
    [Id]              INT           IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (50)  NULL,
    [Description]     VARCHAR (250) NULL,
    [GLAccountId]     BIGINT        NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (50)  NOT NULL,
    [CreatedDate]     DATETIME      CONSTRAINT [DF__MasterBan__Creat__3C8AC281] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (50)  NULL,
    [UpdatedDate]     DATETIME      CONSTRAINT [MasterBankFeesType_DC_UDate] DEFAULT (getdate()) NULL,
    [IsActive]        BIT           CONSTRAINT [MasterBankFeesType_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [MasterBankFeesType_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_MasterBankFeesType] PRIMARY KEY CLUSTERED ([Id] ASC)
);




GO






CREATE TRIGGER [dbo].[Trg_MasterBankFeesTypeAudit]
ON  [dbo].[MasterBankFeesType]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO [dbo].[MasterBankFeesTypeAudit]
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END
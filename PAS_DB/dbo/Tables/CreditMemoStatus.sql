CREATE TABLE [dbo].[CreditMemoStatus] (
    [Id]              INT           IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (50)  NULL,
    [Description]     VARCHAR (250) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (50)  NOT NULL,
    [CreatedDate]     DATETIME      CONSTRAINT [DF_CreditMemoStatus_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (50)  NULL,
    [UpdatedDate]     DATETIME      CONSTRAINT [DF_CreditMemoStatus_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]        BIT           CONSTRAINT [DF_CreditMemoStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_CreditMemoStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CreditMemoStatus] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO



CREATE TRIGGER [dbo].[Trg_CreditMemoStatusAudit]
ON  [dbo].[CreditMemoStatus]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO [dbo].[CreditMemoStatusAudit]
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END
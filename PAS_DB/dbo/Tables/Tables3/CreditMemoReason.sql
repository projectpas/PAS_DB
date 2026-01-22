CREATE TABLE [dbo].[CreditMemoReason] (
    [Id]              INT           IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (50)  NULL,
    [Description]     VARCHAR (250) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (50)  NOT NULL,
    [CreatedDate]     DATETIME      CONSTRAINT [DF__CreditMemoReason__Creat__3B969E48] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (50)  NULL,
    [UpdatedDate]     DATETIME      CONSTRAINT [CreditMemoReason_DC_UDate] DEFAULT (getdate()) NULL,
    [IsActive]        BIT           CONSTRAINT [CreditMemoReason_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [CreditMemoReason_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CreditMemoReason] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_CreditMemoReasonAudit]
ON  [dbo].[CreditMemoReason]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO [dbo].[CreditMemoReasonAudit]
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END
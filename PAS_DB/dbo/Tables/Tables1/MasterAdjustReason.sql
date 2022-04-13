CREATE TABLE [dbo].[MasterAdjustReason] (
    [Id]              INT           IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (50)  NULL,
    [Description]     VARCHAR (250) NULL,
    [GLAccountId]     BIGINT        NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (50)  NOT NULL,
    [CreatedDate]     DATETIME      CONSTRAINT [DF__MasterAdj__Creat__3B969E48] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (50)  NULL,
    [UpdatedDate]     DATETIME      CONSTRAINT [MasterAdjustReason_DC_UDate] DEFAULT (getdate()) NULL,
    [IsActive]        BIT           CONSTRAINT [MasterAdjustReason_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [MasterAdjustReason_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_MasterAdjustReason] PRIMARY KEY CLUSTERED ([Id] ASC)
);




GO



Create TRIGGER [dbo].[Trg_MasterAdjustReasonAudit]
ON  [dbo].[MasterAdjustReason]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO [dbo].[MasterAdjustReasonAudit]
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END
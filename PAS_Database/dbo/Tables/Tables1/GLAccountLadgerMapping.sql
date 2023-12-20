CREATE TABLE [dbo].[GLAccountLadgerMapping] (
    [GLAccountLadgerMapperId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [GlAccountId]             BIGINT        NOT NULL,
    [LedgerId]                BIGINT        NOT NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [DF_GLAccountLadgerMapping_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_GLAccountLadgerMapping_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT           CONSTRAINT [DF_GLAccountLadgerMapping_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           NOT NULL,
    CONSTRAINT [PK_GLAccountLadgerMapping] PRIMARY KEY CLUSTERED ([GLAccountLadgerMapperId] ASC),
    CONSTRAINT [FK_GLAccountLadgerMapping_GLAccount] FOREIGN KEY ([GlAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_GLAccountLadgerMapping_Ladger] FOREIGN KEY ([LedgerId]) REFERENCES [dbo].[Ledger] ([LedgerId]),
    CONSTRAINT [FK_GLAccountLadgerMapping_MasterCompnay] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




-- =============================================

create TRIGGER [dbo].[Trg_GLAccountLadgerMappingAudit]

   ON  [dbo].[GLAccountLadgerMapping]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN



	INSERT INTO [dbo].[GLAccountLadgerMappingAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;



END
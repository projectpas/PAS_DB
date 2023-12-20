CREATE TABLE [dbo].[StocklineAdjustmentReason] (
    [AdjustmentReasonId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]        VARCHAR (200)  NOT NULL,
    [Memo]               NVARCHAR (MAX) NULL,
    [MasterCompanyId]    INT            NOT NULL,
    [CreatedBy]          VARCHAR (256)  NOT NULL,
    [UpdatedBy]          VARCHAR (256)  NOT NULL,
    [CreatedDate]        DATETIME2 (7)  CONSTRAINT [DF_StocklineAdjustmentReason_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]        DATETIME2 (7)  CONSTRAINT [DF_StocklineAdjustmentReason_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]           BIT            CONSTRAINT [DF_StocklineAdjustmentReason_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT            CONSTRAINT [DF_StocklineAdjustmentReason_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK__Stocklin__EED076554FC8936B] PRIMARY KEY CLUSTERED ([AdjustmentReasonId] ASC),
    CONSTRAINT [FK_StocklineAdjustmentReason_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_StocklineAdjustmentReason] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC)
);


GO




-- =============================================

CREATE TRIGGER [dbo].[Trg_StocklineAdjustmentReasonAudit]

   ON  [dbo].[StocklineAdjustmentReason]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN



INSERT INTO StocklineAdjustmentReasonAudit

SELECT * FROM INSERTED



SET NOCOUNT ON;



END
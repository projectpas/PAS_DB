CREATE TABLE [dbo].[CreditMemoFreight] (
    [CreditMemoFreightId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [CreditMemoHeaderId]  BIGINT          NOT NULL,
    [TaskId]              BIGINT          NOT NULL,
    [ShipViaId]           BIGINT          NOT NULL,
    [Weight]              VARCHAR (50)    NULL,
    [UOMId]               BIGINT          NULL,
    [Length]              DECIMAL (10, 2) NULL,
    [Width]               DECIMAL (10, 2) NULL,
    [Height]              DECIMAL (10, 2) NULL,
    [DimensionUOMId]      BIGINT          NULL,
    [CurrencyId]          INT             NULL,
    [Amount]              DECIMAL (20, 3) NOT NULL,
    [Memo]                NVARCHAR (MAX)  NULL,
    [MasterCompanyId]     INT             NOT NULL,
    [CreatedBy]           VARCHAR (256)   NOT NULL,
    [UpdatedBy]           VARCHAR (256)   NOT NULL,
    [CreatedDate]         DATETIME2 (7)   CONSTRAINT [DF_CreditMemoFreight_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)   CONSTRAINT [DF_CreditMemoFreight_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT             CONSTRAINT [DF_CreditMemoFreight_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT             CONSTRAINT [DF_CreditMemoFreight_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CreditMemoFreight] PRIMARY KEY CLUSTERED ([CreditMemoFreightId] ASC),
    CONSTRAINT [FK_CreditMemoFreight_CreditMemo] FOREIGN KEY ([CreditMemoHeaderId]) REFERENCES [dbo].[CreditMemo] ([CreditMemoHeaderId]),
    CONSTRAINT [FK_CreditMemoFreight_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_CreditMemoFreight_DimensionUOM] FOREIGN KEY ([DimensionUOMId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_CreditMemoFreight_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_CreditMemoFreight_ShipVia] FOREIGN KEY ([ShipViaId]) REFERENCES [dbo].[ShippingVia] ([ShippingViaId]),
    CONSTRAINT [FK_CreditMemoFreight_Task] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_CreditMemoFreight_UOM] FOREIGN KEY ([UOMId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId])
);


GO

CREATE TRIGGER [dbo].[Trg_CreditMemoFreightAudit]
   ON [dbo].[CreditMemoFreight]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	INSERT INTO CreditMemoFreightAudit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END
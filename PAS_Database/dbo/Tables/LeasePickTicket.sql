CREATE TABLE [dbo].[LeasePickTicket] (
    [LeasePickTicketId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [LeasePickTicketNumber] VARCHAR (50)    NOT NULL,
    [LeaseHeaderId]         BIGINT          NOT NULL,
    [LeaseStocklineId]      BIGINT          NULL,
    [StockLineId]           BIGINT          NULL,
    [ItemMasterId]          BIGINT          NULL,
    [ConditionId]           BIGINT          NULL,
    [QtyReserved]           DECIMAL (18, 6) NULL,
    [QtyPicked]             DECIMAL (18, 6) NULL,
    [QtyRemaining]          DECIMAL (18, 6) NULL,
    [Status]                INT             NULL,
    [PickedById]            BIGINT          NULL,
    [PickedDate]            DATETIME2 (7)   NULL,
    [ConfirmedById]         BIGINT          NULL,
    [IsConfirmed]           BIT             CONSTRAINT [DF_LeasePickTicket_IsConfirmed] DEFAULT ((0)) NULL,
    [ConfirmedDate]         DATETIME2 (7)   NULL,
    [Memo]                  NVARCHAR (MAX)  NULL,
    [PDFPath]               NVARCHAR (MAX)  NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [CreatedDate]           DATETIME2 (7)   CONSTRAINT [DF_LeasePickTicket_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   CONSTRAINT [DF_LeasePickTicket_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]              BIT             CONSTRAINT [DF_LeasePickTicket_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT             CONSTRAINT [DF_LeasePickTicket_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LeasePickTicket] PRIMARY KEY CLUSTERED ([LeasePickTicketId] ASC),
    CONSTRAINT [FK_LeasePickTicket_LeaseHeader] FOREIGN KEY ([LeaseHeaderId]) REFERENCES [dbo].[LeaseHeader] ([LeaseHeaderId]),
    CONSTRAINT [FK_LeasePickTicket_LeaseStockline] FOREIGN KEY ([LeaseStocklineId]) REFERENCES [dbo].[LeaseStockline] ([LeaseStocklineId]),
    CONSTRAINT [FK_LeasePickTicket_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO
CREATE NONCLUSTERED INDEX [IX_LeasePickTicket_LeaseHeaderId]
    ON [dbo].[LeasePickTicket]([LeaseHeaderId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_LeasePickTicket_LeaseStocklineId]
    ON [dbo].[LeasePickTicket]([LeaseStocklineId] ASC);


GO
CREATE TRIGGER [dbo].[Trg_LeasePickTicketAudit]
   ON  [dbo].[LeasePickTicket]
   AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON;

	-- Handles INSERT and UPDATE (rows exist in INSERTED)
	IF EXISTS (SELECT 1 FROM INSERTED)
	BEGIN
		INSERT INTO [dbo].[LeasePickTicketAudit]
		SELECT * FROM INSERTED
	END

	-- Handles DELETE (rows exist only in DELETED)
	IF EXISTS (SELECT 1 FROM DELETED) AND NOT EXISTS (SELECT 1 FROM INSERTED)
	BEGIN
		INSERT INTO [dbo].[LeasePickTicketAudit]
		SELECT * FROM DELETED
	END
END

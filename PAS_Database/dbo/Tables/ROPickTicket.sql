CREATE TABLE [dbo].[ROPickTicket] (
    [ROPickTicketId]     BIGINT         IDENTITY (1, 1) NOT NULL,
    [ROPickTicketNumber] VARCHAR (50)   NOT NULL,
    [RepairOrderId]      BIGINT         NOT NULL,
    [CreatedBy]          VARCHAR (256)  NOT NULL,
    [CreatedDate]        DATETIME2 (7)  CONSTRAINT [DF_ROPickTicket_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]          VARCHAR (256)  NOT NULL,
    [UpdatedDate]        DATETIME2 (7)  CONSTRAINT [DF_ROPickTicket_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]           BIT            CONSTRAINT [DF_ROPickTicket_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT            CONSTRAINT [DF_ROPickTicket_IsDeleted] DEFAULT ((0)) NOT NULL,
    [RepairOrderPartId]  BIGINT         NULL,
    [StocklineId]        BIGINT         NULL,
    [Qty]                INT            NULL,
    [QtyToShip]          INT            NULL,
    [MasterCompanyId]    INT            NOT NULL,
    [Status]             INT            NULL,
    [PickedById]         BIGINT         NULL,
    [ConfirmedById]      INT            NULL,
    [Memo]               NVARCHAR (MAX) NULL,
    [IsConfirmed]        BIT            NULL,
    [ConfirmedDate]      DATETIME2 (7)  NULL,
    [PDFPath]            NVARCHAR (MAX) NULL,
    [QtyRemaining]       INT            NULL,
    CONSTRAINT [PK_ROPickTicket] PRIMARY KEY CLUSTERED ([ROPickTicketId] ASC),
    CONSTRAINT [FK_ROPickTicket_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ROPickTicket_RepairOrderId] FOREIGN KEY ([RepairOrderId]) REFERENCES [dbo].[RepairOrder] ([RepairOrderId])
);


GO
CREATE   TRIGGER [dbo].[Trg_ROPickticketAudit] ON [dbo].[ROPickTicket]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO [dbo].[ROPickticketAudit]
	SELECT * FROM INSERTED
	
	SET NOCOUNT ON;
END
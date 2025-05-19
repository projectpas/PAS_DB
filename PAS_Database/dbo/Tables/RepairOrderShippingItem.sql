CREATE TABLE [dbo].[RepairOrderShippingItem] (
    [RepairOrderShippingItemId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [RepairOrderShippingId]     BIGINT         NOT NULL,
    [RepairOrderPartId]         BIGINT         NOT NULL,
    [QtyShipped]                INT            NULL,
    [ROPickTicketId]            BIGINT         NOT NULL,
    [MasterCompanyId]           INT            NOT NULL,
    [CreatedBy]                 VARCHAR (256)  NOT NULL,
    [UpdatedBy]                 VARCHAR (256)  NOT NULL,
    [CreatedDate]               DATETIME2 (7)  CONSTRAINT [DF_RepairOrderShippingItem_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7)  CONSTRAINT [DF_RepairOrderShippingItem_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT            CONSTRAINT [DF_ROSI_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT            CONSTRAINT [DF_ROSI_IsDeleted] DEFAULT ((0)) NOT NULL,
    [PDFPath]                   NVARCHAR (MAX) NULL,
    [FedexPdfPath]              VARCHAR (MAX)  NULL,
    CONSTRAINT [PK_RepairOrderShippingItem] PRIMARY KEY CLUSTERED ([RepairOrderShippingItemId] ASC),
    CONSTRAINT [FK_RepairOrderShippingItem_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_RepairOrderShippingItem_ROPickTicket] FOREIGN KEY ([ROPickTicketId]) REFERENCES [dbo].[ROPickTicket] ([ROPickTicketId])
);


GO
CREATE   TRIGGER [dbo].[Trg_RepairOrderShippingItemAudit]
   ON  [dbo].[RepairOrderShippingItem]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	INSERT INTO RepairOrderShippingItemAudit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END
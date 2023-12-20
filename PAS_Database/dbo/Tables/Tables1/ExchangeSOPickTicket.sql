CREATE TABLE [dbo].[ExchangeSOPickTicket] (
    [SOPickTicketId]           BIGINT         IDENTITY (1, 1) NOT NULL,
    [SOPickTicketNumber]       VARCHAR (50)   NOT NULL,
    [ExchangeSalesOrderId]     BIGINT         NOT NULL,
    [CreatedBy]                VARCHAR (256)  NOT NULL,
    [CreatedDate]              DATETIME2 (7)  CONSTRAINT [DF_ExchangeSOPickTicket_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                VARCHAR (256)  NOT NULL,
    [UpdatedDate]              DATETIME2 (7)  CONSTRAINT [DF_ExchangeSOPickTicket_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT            CONSTRAINT [DF_ExchangeSOPickTicket_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT            CONSTRAINT [DF_ExchangeSOPickTicket_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ExchangeSalesOrderPartId] BIGINT         NULL,
    [Qty]                      INT            NULL,
    [QtyToShip]                INT            NULL,
    [MasterCompanyId]          INT            NOT NULL,
    [Status]                   INT            NULL,
    [PickedById]               BIGINT         NULL,
    [ConfirmedById]            INT            NULL,
    [Memo]                     NVARCHAR (MAX) NULL,
    [IsConfirmed]              BIT            NULL,
    [ConfirmedDate]            DATETIME2 (7)  NULL,
    [PDFPath]                  NVARCHAR (MAX) NULL,
    [QtyRemaining]             INT            NULL,
    CONSTRAINT [PK_ExchangeSOPickTicket] PRIMARY KEY CLUSTERED ([SOPickTicketId] ASC),
    CONSTRAINT [FK_ExchangeSOPickTicket_ExchangeSalesOrder] FOREIGN KEY ([ExchangeSalesOrderId]) REFERENCES [dbo].[ExchangeSalesOrder] ([ExchangeSalesOrderId])
);


GO




CREATE TRIGGER [dbo].[Trg_ExchangeSOPickTicketAudit] ON [dbo].[ExchangeSOPickTicket]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  

  

 INSERT INTO [dbo].[ExchangeSOPickTicketAudit]  

 SELECT * FROM INSERTED  

  

 SET NOCOUNT ON;  

  

END
CREATE TABLE [dbo].[SOPickTicket] (
    [SOPickTicketId]     BIGINT         IDENTITY (1, 1) NOT NULL,
    [SOPickTicketNumber] VARCHAR (50)   NOT NULL,
    [SalesOrderId]       BIGINT         NOT NULL,
    [CreatedBy]          VARCHAR (256)  NOT NULL,
    [CreatedDate]        DATETIME2 (7)  CONSTRAINT [DF_SOPickTicket_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]          VARCHAR (256)  NOT NULL,
    [UpdatedDate]        DATETIME2 (7)  CONSTRAINT [DF_SOPickTicket_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]           BIT            CONSTRAINT [DF_SOPickTicket_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT            CONSTRAINT [DF_SOPickTicket_IsDeleted] DEFAULT ((0)) NOT NULL,
    [SalesOrderPartId]   BIGINT         NULL,
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
    CONSTRAINT [PK_SOPickTicket] PRIMARY KEY CLUSTERED ([SOPickTicketId] ASC),
    CONSTRAINT [FK_SOPickTicket_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SOPickTicket_SalesOrderId] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId])
);


GO




CREATE TRIGGER [dbo].[Trg_SOPickticketAudit] ON [dbo].[SOPickTicket]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  

  

 INSERT INTO [dbo].[SOPickticketAudit]  

 SELECT * FROM INSERTED  

  

 SET NOCOUNT ON;  

  

END
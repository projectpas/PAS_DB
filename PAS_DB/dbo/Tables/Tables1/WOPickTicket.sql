CREATE TABLE [dbo].[WOPickTicket] (
    [PickTicketId]        BIGINT         IDENTITY (1, 1) NOT NULL,
    [PickTicketNumber]    VARCHAR (50)   NOT NULL,
    [WorkorderId]         BIGINT         NOT NULL,
    [WorkFlowWorkOrderId] BIGINT         NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  NOT NULL,
    [IsActive]            BIT            NOT NULL,
    [IsDeleted]           BIT            NOT NULL,
    [OrderPartId]         BIGINT         NULL,
    [Qty]                 INT            NULL,
    [QtyToShip]           INT            NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [Status]              INT            NULL,
    [PickedById]          BIGINT         NULL,
    [ConfirmedById]       INT            NULL,
    [Memo]                NVARCHAR (MAX) NULL,
    [IsConfirmed]         BIT            NULL,
    [ConfirmedDate]       DATETIME2 (7)  NULL,
    [PDFPath]             NVARCHAR (MAX) NULL,
    [QtyRemaining]        INT            NULL,
    CONSTRAINT [PK_WOPickTicket] PRIMARY KEY CLUSTERED ([PickTicketId] ASC)
);




GO




CREATE TRIGGER [dbo].[Trg_WOPickTicketAudit]

   ON  [dbo].[WOPickTicket]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WOPickTicketAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
CREATE TABLE [dbo].[WorkorderPickTicket] (
    [PickTicketId]         BIGINT          IDENTITY (1, 1) NOT NULL,
    [PickTicketNumber]     VARCHAR (50)    NOT NULL,
    [WorkorderId]          BIGINT          NOT NULL,
    [WorkOrderMaterialsId] BIGINT          NOT NULL,
    [CreatedBy]            VARCHAR (256)   NOT NULL,
    [CreatedDate]          DATETIME2 (7)   NOT NULL,
    [UpdatedBy]            VARCHAR (256)   NOT NULL,
    [UpdatedDate]          DATETIME2 (7)   NOT NULL,
    [IsActive]             BIT             NOT NULL,
    [IsDeleted]            BIT             NOT NULL,
    [OrderPartId]          BIGINT          NULL,
    [Qty]                  DECIMAL (18, 6) NULL,
    [QtyToShip]            DECIMAL (18, 6) NULL,
    [MasterCompanyId]      INT             NOT NULL,
    [Status]               INT             NULL,
    [PickedById]           BIGINT          NULL,
    [ConfirmedById]        INT             NULL,
    [Memo]                 NVARCHAR (MAX)  NULL,
    [IsConfirmed]          BIT             NULL,
    [ConfirmedDate]        DATETIME2 (7)   NULL,
    [StocklineId]          BIGINT          NULL,
    [PDFPath]              NVARCHAR (MAX)  NULL,
    [IsKitType]            BIT             NULL,
    [QtyRemaining]         DECIMAL (18, 6) NULL,
    CONSTRAINT [PK_WorkorderPickTicket] PRIMARY KEY CLUSTERED ([PickTicketId] ASC)
);




GO

CREATE TRIGGER [dbo].[Trg_WorkorderPickTicketAudit]
   ON dbo.WorkorderPickTicket
   AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM INSERTED)
    BEGIN
        INSERT INTO [dbo].[WorkorderPickTicketAudit]
                   ([PickTicketId],[PickTicketNumber],[WorkorderId],[WorkOrderMaterialsId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],
                    [IsActive],[IsDeleted],[OrderPartId],[Qty],[QtyToShip],[MasterCompanyId],[Status],[PickedById],[ConfirmedById],
                    [Memo],[IsConfirmed],[ConfirmedDate],[StocklineId],[PDFPath],[IsKitType],[QtyRemaining])
        SELECT [PickTicketId],[PickTicketNumber],[WorkorderId],[WorkOrderMaterialsId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],
               [IsActive],[IsDeleted],[OrderPartId],[Qty],[QtyToShip],[MasterCompanyId],[Status],[PickedById],[ConfirmedById],
               [Memo],[IsConfirmed],[ConfirmedDate],[StocklineId],[PDFPath],[IsKitType],[QtyRemaining]
        FROM INSERTED;
    END
    ELSE IF EXISTS (SELECT 1 FROM DELETED)
    BEGIN
        INSERT INTO [dbo].[WorkorderPickTicketAudit]
                   ([PickTicketId],[PickTicketNumber],[WorkorderId],[WorkOrderMaterialsId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],
                    [IsActive],[IsDeleted],[OrderPartId],[Qty],[QtyToShip],[MasterCompanyId],[Status],[PickedById],[ConfirmedById],
                    [Memo],[IsConfirmed],[ConfirmedDate],[StocklineId],[PDFPath],[IsKitType],[QtyRemaining])
        SELECT [PickTicketId],[PickTicketNumber],[WorkorderId],[WorkOrderMaterialsId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],
               [IsActive], 1 ,[OrderPartId],[Qty],[QtyToShip],[MasterCompanyId],[Status],[PickedById],[ConfirmedById],
               [Memo],[IsConfirmed],[ConfirmedDate],[StocklineId],[PDFPath],[IsKitType],[QtyRemaining]
        FROM DELETED;
    END
END
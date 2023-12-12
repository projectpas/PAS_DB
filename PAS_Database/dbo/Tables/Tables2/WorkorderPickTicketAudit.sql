﻿CREATE TABLE [dbo].[WorkorderPickTicketAudit] (
    [PickTicketAuditId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [PickTicketId]         BIGINT         NOT NULL,
    [PickTicketNumber]     VARCHAR (50)   NOT NULL,
    [WorkorderId]          BIGINT         NOT NULL,
    [WorkOrderMaterialsId] BIGINT         NOT NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [CreatedDate]          DATETIME2 (7)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  NOT NULL,
    [IsActive]             BIT            NOT NULL,
    [IsDeleted]            BIT            NOT NULL,
    [OrderPartId]          BIGINT         NULL,
    [Qty]                  INT            NULL,
    [QtyToShip]            INT            NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [Status]               INT            NULL,
    [PickedById]           BIGINT         NULL,
    [ConfirmedById]        INT            NULL,
    [Memo]                 NVARCHAR (MAX) NULL,
    [IsConfirmed]          BIT            NULL,
    [ConfirmedDate]        DATETIME2 (7)  NULL,
    [StocklineId]          BIGINT         NULL,
    [PDFPath]              NVARCHAR (MAX) NULL,
    [IsKitType]            BIT            NULL,
    [QtyRemaining]         INT            NULL,
    CONSTRAINT [PK_WorkorderPickTicketAudit] PRIMARY KEY CLUSTERED ([PickTicketAuditId] ASC)
);


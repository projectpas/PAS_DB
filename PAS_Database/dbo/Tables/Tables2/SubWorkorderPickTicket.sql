﻿CREATE TABLE [dbo].[SubWorkorderPickTicket] (
    [PickTicketId]            BIGINT         IDENTITY (1, 1) NOT NULL,
    [PickTicketNumber]        VARCHAR (50)   NOT NULL,
    [WorkorderId]             BIGINT         NOT NULL,
    [SubWorkorderId]          BIGINT         NOT NULL,
    [SubWorkorderPartNoId]    BIGINT         NOT NULL,
    [SubWorkOrderMaterialsId] BIGINT         NOT NULL,
    [CreatedBy]               VARCHAR (256)  NOT NULL,
    [CreatedDate]             DATETIME2 (7)  NOT NULL,
    [UpdatedBy]               VARCHAR (256)  NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  NOT NULL,
    [IsActive]                BIT            NOT NULL,
    [IsDeleted]               BIT            NOT NULL,
    [OrderPartId]             BIGINT         NULL,
    [Qty]                     INT            NULL,
    [QtyToShip]               INT            NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [Status]                  INT            NULL,
    [PickedById]              BIGINT         NULL,
    [ConfirmedById]           INT            NULL,
    [Memo]                    NVARCHAR (MAX) NULL,
    [IsConfirmed]             BIT            NULL,
    [ConfirmedDate]           DATETIME2 (7)  NULL,
    [StocklineId]             BIGINT         NULL,
    [PDFPath]                 NVARCHAR (MAX) NULL,
    [QtyRemaining]            INT            NULL,
    [IsKitType]               BIT            NULL,
    CONSTRAINT [PK_SubWorkorderPickTicket] PRIMARY KEY CLUSTERED ([PickTicketId] ASC)
);




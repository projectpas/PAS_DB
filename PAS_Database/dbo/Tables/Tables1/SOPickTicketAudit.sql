﻿CREATE TABLE [dbo].[SOPickTicketAudit] (
    [AuditSOPickTicketId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [SOPickTicketId]      BIGINT         NOT NULL,
    [SOPickTicketNumber]  VARCHAR (50)   NOT NULL,
    [SalesOrderId]        BIGINT         NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  NOT NULL,
    [IsActive]            BIT            NOT NULL,
    [IsDeleted]           BIT            NOT NULL,
    [SalesOrderPartId]    BIGINT         NULL,
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
    CONSTRAINT [PK_SOPickTicketAudit] PRIMARY KEY CLUSTERED ([AuditSOPickTicketId] ASC)
);


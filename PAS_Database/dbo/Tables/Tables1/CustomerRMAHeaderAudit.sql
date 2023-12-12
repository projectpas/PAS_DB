﻿CREATE TABLE [dbo].[CustomerRMAHeaderAudit] (
    [RMAHeaderAuditId]      BIGINT          IDENTITY (1, 1) NOT NULL,
    [RMAHeaderId]           BIGINT          NOT NULL,
    [RMANumber]             VARCHAR (100)   NOT NULL,
    [CustomerId]            BIGINT          NOT NULL,
    [CustomerName]          VARCHAR (100)   NULL,
    [CustomerCode]          VARCHAR (100)   NULL,
    [CustomerContactId]     BIGINT          NULL,
    [ContactInfo]           VARCHAR (100)   NULL,
    [OpenDate]              DATETIME        NULL,
    [InvoiceId]             BIGINT          NOT NULL,
    [InvoiceNo]             VARCHAR (50)    NOT NULL,
    [InvoiceDate]           DATETIME        NOT NULL,
    [RMAStatusId]           INT             NULL,
    [RMAStatus]             VARCHAR (100)   NULL,
    [Iswarranty]            BIT             NULL,
    [ValidDate]             DATETIME        NULL,
    [RequestedId]           BIGINT          NULL,
    [Requestedby]           VARCHAR (50)    NULL,
    [ApprovedbyId]          BIGINT          NULL,
    [Approvedby]            VARCHAR (100)   NULL,
    [ApprovedDate]          DATETIME        NULL,
    [ReturnDate]            DATETIME        NULL,
    [WorkOrderId]           BIGINT          NULL,
    [WorkOrderNum]          VARCHAR (50)    NULL,
    [ManagementStructureId] BIGINT          NULL,
    [Notes]                 NVARCHAR (MAX)  NULL,
    [Memo]                  NVARCHAR (MAX)  NULL,
    [isWorkOrder]           BIT             NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NOT NULL,
    [CreatedDate]           DATETIME2 (7)   NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   NOT NULL,
    [IsActive]              BIT             NOT NULL,
    [IsDeleted]             BIT             NOT NULL,
    [ReferenceId]           BIGINT          NULL,
    [PDFPath]               NVARCHAR (2000) NULL,
    [ReceiverNum]           VARCHAR (30)    NULL,
    CONSTRAINT [PK_CustomerRMAHeaderAudit] PRIMARY KEY CLUSTERED ([RMAHeaderAuditId] ASC)
);


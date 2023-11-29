﻿CREATE TABLE [dbo].[WorkOrderAudit] (
    [WorkOrderAuditId]        BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]             BIGINT          NOT NULL,
    [WorkOrderNum]            VARCHAR (30)    NOT NULL,
    [IsSinglePN]              BIT             NOT NULL,
    [WorkOrderTypeId]         BIGINT          NOT NULL,
    [OpenDate]                DATETIME2 (7)   NOT NULL,
    [CustomerId]              BIGINT          NULL,
    [WorkOrderStatusId]       BIGINT          NOT NULL,
    [EmployeeId]              BIGINT          NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   NOT NULL,
    [IsActive]                BIT             NOT NULL,
    [IsDeleted]               BIT             NOT NULL,
    [SalesPersonId]           BIGINT          NULL,
    [CSRId]                   BIGINT          NULL,
    [ReceivingCustomerWorkId] BIGINT          NULL,
    [Memo]                    NVARCHAR (MAX)  NULL,
    [Notes]                   NVARCHAR (MAX)  NULL,
    [CustomerContactId]       BIGINT          NOT NULL,
    [Status]                  VARCHAR (256)   NULL,
    [CustomerName]            VARCHAR (256)   NULL,
    [ContactName]             VARCHAR (256)   NULL,
    [ContactPhone]            VARCHAR (30)    NULL,
    [CreditLimit]             DECIMAL (18, 2) NULL,
    [CreditTerms]             VARCHAR (200)   NULL,
    [SalesPerson]             VARCHAR (256)   NULL,
    [CSR]                     VARCHAR (256)   NULL,
    [Employee]                VARCHAR (256)   NULL,
    [TearDownTypes]           VARCHAR (300)   NULL,
    [RMAHeaderId]             BIGINT          NULL,
    [IsWarranty]              BIT             NULL,
    [IsAccepted]              BIT             NULL,
    [ReasonId]                BIGINT          NULL,
    [Reason]                  VARCHAR (500)   NULL,
    [CreditTermId]            INT             NULL,
    [IsManualForm]            BIT             NULL,
    CONSTRAINT [PK_WorkOrderAudit] PRIMARY KEY CLUSTERED ([WorkOrderAuditId] ASC)
);










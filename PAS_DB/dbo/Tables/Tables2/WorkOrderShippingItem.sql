CREATE TABLE [dbo].[WorkOrderShippingItem] (
    [WorkOrderShippingItemId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderShippingId]     BIGINT         NOT NULL,
    [WorkOrderPartNumId]      BIGINT         NOT NULL,
    [QtyShipped]              INT            NULL,
    [WOPickTicketId]          BIGINT         NOT NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [CreatedBy]               VARCHAR (256)  NOT NULL,
    [UpdatedBy]               VARCHAR (256)  NOT NULL,
    [CreatedDate]             DATETIME2 (7)  CONSTRAINT [DF_WorkOrderShippingItem_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  CONSTRAINT [DF_WorkOrderShippingItem_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT            CONSTRAINT [DF_WOSI_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT            CONSTRAINT [DF_WOSI_IsDeleted] DEFAULT ((0)) NOT NULL,
    [PDFPath]                 NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_WorkOrderShippingItem] PRIMARY KEY CLUSTERED ([WorkOrderShippingItemId] ASC),
    CONSTRAINT [FK_WorkOrderShippingItem_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderShippingItem_WOPickTicket] FOREIGN KEY ([WOPickTicketId]) REFERENCES [dbo].[WOPickTicket] ([PickTicketId])
);


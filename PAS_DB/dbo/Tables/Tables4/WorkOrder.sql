CREATE TABLE [dbo].[WorkOrder] (
    [WorkOrderId]                      BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderNum]                     VARCHAR (30)    NOT NULL,
    [IsSinglePN]                       BIT             NOT NULL,
    [WorkOrderTypeId]                  BIGINT          NOT NULL,
    [OpenDate]                         DATETIME2 (7)   NOT NULL,
    [CustomerId]                       BIGINT          NULL,
    [WorkOrderStatusId]                BIGINT          NOT NULL,
    [EmployeeId]                       BIGINT          NULL,
    [MasterCompanyId]                  INT             NOT NULL,
    [CreatedBy]                        VARCHAR (256)   NOT NULL,
    [UpdatedBy]                        VARCHAR (256)   NOT NULL,
    [CreatedDate]                      DATETIME2 (7)   CONSTRAINT [DF_WorkOrder_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                      DATETIME2 (7)   CONSTRAINT [DF_WorkOrder_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                         BIT             CONSTRAINT [DF_WO_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                        BIT             CONSTRAINT [DF_WO_IsDeleted] DEFAULT ((0)) NOT NULL,
    [SalesPersonId]                    BIGINT          NULL,
    [CSRId]                            BIGINT          NULL,
    [ReceivingCustomerWorkId]          BIGINT          NULL,
    [Memo]                             NVARCHAR (MAX)  NULL,
    [Notes]                            NVARCHAR (MAX)  NULL,
    [CustomerContactId]                BIGINT          NOT NULL,
    [CustomerName]                     VARCHAR (100)   NULL,
    [CustomerType]                     VARCHAR (200)   NULL,
    [CreditLimit]                      DECIMAL (18, 2) CONSTRAINT [DF_WorkOrder_CreditLimit] DEFAULT ((0)) NULL,
    [CreditTerms]                      VARCHAR (200)   NULL,
    [TearDownTypes]                    VARCHAR (300)   NULL,
    [RMAHeaderId]                      BIGINT          NULL,
    [IsWarranty]                       BIT             NULL,
    [IsAccepted]                       BIT             NULL,
    [ReasonId]                         BIGINT          NULL,
    [Reason]                           VARCHAR (500)   NULL,
    [CreditTermId]                     INT             NULL,
    [IsManualForm]                     BIT             NULL,
    [PercentId]                        BIGINT          NULL,
    [Days]                             INT             NULL,
    [NetDays]                          INT             NULL,
    [WorkOrderType]                    VARCHAR (50)    NULL,
    [FunctionalCurrencyId]             INT             NULL,
    [ReportCurrencyId]                 INT             NULL,
    [ForeignExchangeRate]              DECIMAL (18, 2) NULL,
    [WorkOrderFormTypeId]              BIT             NULL,
    [IsWoAlwaysOrOndemandId]           BIT             NULL,
    [EnforceMpnPickTicketConfirmation] BIT             NULL,
    [SecondarySalesPersonId]           BIGINT          NULL,
    [SalesAgentID]                     BIGINT          NULL,
    [PrimarySalesRevenue]              BIGINT          NULL,
    [PrimarySalesMargin]               BIGINT          NULL,
    [SecondarySalesRevenue]            BIGINT          NULL,
    [SecondarySalesMargin]             BIGINT          NULL,
    [CSRSalesRevenue]                  BIGINT          NULL,
    [CSRSalesMargin]                   BIGINT          NULL,
    [AgentSalesRevenue]                BIGINT          NULL,
    [AgentSalesMargin]                 BIGINT          NULL,
    [IsMigrated]                       BIT             NULL,
    [IsFromAircraft]                   BIT             NULL,
    [MtcCategoryId]                    BIGINT          NULL,
    CONSTRAINT [PK_WorkOrder] PRIMARY KEY CLUSTERED ([WorkOrderId] ASC),
    CONSTRAINT [FK_WorkOrder_CSR] FOREIGN KEY ([CSRId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrder_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_WorkOrder_CustomerContact] FOREIGN KEY ([CustomerContactId]) REFERENCES [dbo].[CustomerContact] ([CustomerContactId]),
    CONSTRAINT [FK_WorkOrder_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrder_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrder_ReceivingCustomerWork] FOREIGN KEY ([ReceivingCustomerWorkId]) REFERENCES [dbo].[ReceivingCustomerWork] ([ReceivingCustomerWorkId]),
    CONSTRAINT [FK_WorkOrder_SalesPerson] FOREIGN KEY ([SalesPersonId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrder_WorkOrderStatus] FOREIGN KEY ([WorkOrderStatusId]) REFERENCES [dbo].[WorkOrderStatus] ([Id]),
    CONSTRAINT [FK_WorkOrder_WorkOrderType] FOREIGN KEY ([WorkOrderTypeId]) REFERENCES [dbo].[WorkOrderType] ([Id]),
    CONSTRAINT [Unique_WorkOrder] UNIQUE NONCLUSTERED ([WorkOrderNum] ASC, [MasterCompanyId] ASC)
);




GO






Create TRIGGER [dbo].[Trg_WorkOrderQuoteMemoUpdate]

   ON  [dbo].[WorkOrder]

   AFTER INSERT,UPDATE

AS 

BEGIN

	DECLARE @WorkOrderId BIGINT, @Memo NVARCHAR(MAX)

	SELECT @WorkOrderId=WorkOrderId, @Memo=Memo

	FROM INSERTED



	Update [dbo].[WorkOrderQuote] set Memo = @Memo where WorkOrderId = @WorkOrderId



	SET NOCOUNT ON;



END
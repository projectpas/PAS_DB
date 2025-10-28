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
GO


GO
     

     
     CREATE     TRIGGER [dbo].[trg_Audit_dbo_WorkOrder]
        ON [dbo].[WorkOrder]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[WorkOrderId],d.[WorkOrderNum],d.[IsSinglePN],d.[WorkOrderTypeId],d.[OpenDate],d.[CustomerId],d.[WorkOrderStatusId],d.[EmployeeId],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[SalesPersonId],d.[CSRId],d.[ReceivingCustomerWorkId],d.[Memo],d.[Notes],d.[CustomerContactId],d.[CustomerName],d.[CustomerType],d.[CreditLimit],d.[CreditTerms],d.[TearDownTypes],d.[RMAHeaderId],d.[IsWarranty],d.[IsAccepted],d.[ReasonId],d.[Reason],d.[CreditTermId],d.[IsManualForm],d.[PercentId],d.[Days],d.[NetDays],d.[WorkOrderType],d.[FunctionalCurrencyId],d.[ReportCurrencyId],d.[ForeignExchangeRate],d.[WorkOrderFormTypeId],d.[IsWoAlwaysOrOndemandId],d.[EnforceMpnPickTicketConfirmation],d.[SecondarySalesPersonId],d.[SalesAgentID],d.[PrimarySalesRevenue],d.[PrimarySalesMargin],d.[SecondarySalesRevenue],d.[SecondarySalesMargin],d.[CSRSalesRevenue],d.[CSRSalesMargin],d.[AgentSalesRevenue],d.[AgentSalesMargin] FROM deleted d),
            i AS (SELECT i.[WorkOrderId],i.[WorkOrderNum],i.[IsSinglePN],i.[WorkOrderTypeId],i.[OpenDate],i.[CustomerId],i.[WorkOrderStatusId],i.[EmployeeId],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[SalesPersonId],i.[CSRId],i.[ReceivingCustomerWorkId],i.[Memo],i.[Notes],i.[CustomerContactId],i.[CustomerName],i.[CustomerType],i.[CreditLimit],i.[CreditTerms],i.[TearDownTypes],i.[RMAHeaderId],i.[IsWarranty],i.[IsAccepted],i.[ReasonId],i.[Reason],i.[CreditTermId],i.[IsManualForm],i.[PercentId],i.[Days],i.[NetDays],i.[WorkOrderType],i.[FunctionalCurrencyId],i.[ReportCurrencyId],i.[ForeignExchangeRate],i.[WorkOrderFormTypeId],i.[IsWoAlwaysOrOndemandId],i.[EnforceMpnPickTicketConfirmation],i.[SecondarySalesPersonId],i.[SalesAgentID],i.[PrimarySalesRevenue],i.[PrimarySalesMargin],i.[SecondarySalesRevenue],i.[SecondarySalesMargin],i.[CSRSalesRevenue],i.[CSRSalesMargin],i.[AgentSalesRevenue],i.[AgentSalesMargin] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.WorkOrderId, d.WorkOrderId ) AS WorkOrderId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.WorkOrderId IS NOT NULL AND d.WorkOrderId IS NOT NULL THEN 'U'
                        WHEN i.WorkOrderId IS NOT NULL AND d.WorkOrderId IS NULL     THEN 'I'
                        WHEN i.WorkOrderId IS NULL     AND d.WorkOrderId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.WorkOrderId, d.WorkOrderId) AS WorkOrderId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.WorkOrderId = d.WorkOrderId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.WorkOrderId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'WorkOrder'
                      AND ign.ColumnName = N'WorkOrderId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.WorkOrderId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'WorkOrder'
                      AND ign.ColumnName = N'WorkOrderId'
                )),
            merged AS (
                SELECT
                    COALESCE(n.PKJson, o.PKJson)                AS PKJson,
                    COALESCE(n.ColumnName, o.ColumnName)        AS ColumnName,
                    o.OldValue,
                    n.NewValue,
                    p.Action
                FROM paired p
                LEFT JOIN oldv o
                    ON o.WorkOrderId = p.WorkOrderId
                LEFT JOIN newv n
                    ON n.WorkOrderId = p.WorkOrderId
                   AND n.ColumnName = o.ColumnName
                UNION ALL
                SELECT
                    n.PKJson,
                    n.ColumnName,
                    NULL AS OldValue,
                    n.NewValue,
                    p.Action
                FROM paired p
                LEFT JOIN newv n
                    ON n.WorkOrderId = p.WorkOrderId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.WorkOrderId = p.WorkOrderId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'WorkOrder' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
                m.OldValue,
                m.NewValue
            FROM merged m
            WHERE
                (m.Action = 'U' AND (
                     (m.OldValue IS NULL AND m.NewValue IS NOT NULL)
                  OR (m.OldValue IS NOT NULL AND m.NewValue IS NULL)
                  OR (m.OldValue <> m.NewValue)
                ))
                OR
                (m.Action = 'I' AND m.NewValue IS NOT NULL)
                OR
                (m.Action = 'D' AND m.OldValue IS NOT NULL);
        END;
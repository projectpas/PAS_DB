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
    [PrimarySalesRevenue]              DECIMAL (18, 6) NULL,
    [PrimarySalesMargin]               DECIMAL (18, 6) NULL,
    [SecondarySalesRevenue]            DECIMAL (18, 6) NULL,
    [SecondarySalesMargin]             DECIMAL (18, 6) NULL,
    [CSRSalesRevenue]                  DECIMAL (18, 6) NULL,
    [CSRSalesMargin]                   DECIMAL (18, 6) NULL,
    [AgentSalesRevenue]                DECIMAL (18, 6) NULL,
    [AgentSalesMargin]                 DECIMAL (18, 6) NULL,
    [IsMigrated]                       BIT             NULL,
    [IsFromAircraft]                   BIT             DEFAULT ((0)) NULL,
    [MtcCategoryId]                    BIGINT          NULL,
    [HasPieceParts]                    BIT             CONSTRAINT [DF_WorkOrder_HasCSP] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrder] PRIMARY KEY CLUSTERED ([WorkOrderId] ASC),
    CONSTRAINT [FK_WorkOrder_CSR] FOREIGN KEY ([CSRId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrder_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_WorkOrder_CustomerContact] FOREIGN KEY ([CustomerContactId]) REFERENCES [dbo].[CustomerContact] ([CustomerContactId]),
    CONSTRAINT [FK_WorkOrder_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrder_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrder_ReceivingCustomerWork] FOREIGN KEY ([ReceivingCustomerWorkId]) REFERENCES [dbo].[ReceivingCustomerWork] ([ReceivingCustomerWorkId]),
    CONSTRAINT [FK_WorkOrder_SalesAgent] FOREIGN KEY ([SalesAgentID]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrder_SalesPerson] FOREIGN KEY ([SalesPersonId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrder_SecondarySalesPerson] FOREIGN KEY ([SecondarySalesPersonId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
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
CREATE   TRIGGER [dbo].[trg_Audit_dbo_WorkOrder]
    ON [dbo].[WorkOrder]
    AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH
    d AS (SELECT d.[WorkOrderId],d.[WorkOrderNum],d.[IsSinglePN],d.[WorkOrderTypeId],d.[OpenDate],d.[CustomerId],d.[WorkOrderStatusId],d.[EmployeeId],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[SalesPersonId],d.[CSRId],d.[ReceivingCustomerWorkId],d.[Memo],d.[Notes],d.[CustomerContactId],d.[CustomerName],d.[CustomerType],d.[CreditLimit],d.[CreditTerms],d.[TearDownTypes],d.[RMAHeaderId],d.[IsWarranty],d.[IsAccepted],d.[ReasonId],d.[Reason],d.[CreditTermId],d.[IsManualForm],d.[PercentId],d.[Days],d.[NetDays],d.[WorkOrderType],d.[FunctionalCurrencyId],d.[ReportCurrencyId],d.[ForeignExchangeRate],d.[WorkOrderFormTypeId],d.[IsWoAlwaysOrOndemandId],d.[EnforceMpnPickTicketConfirmation],d.[SecondarySalesPersonId],d.[SalesAgentID],d.[PrimarySalesRevenue],d.[PrimarySalesMargin],d.[SecondarySalesRevenue],d.[SecondarySalesMargin],d.[CSRSalesRevenue],d.[CSRSalesMargin],d.[AgentSalesRevenue],d.[AgentSalesMargin],d.[IsMigrated],d.[IsFromAircraft],d.[MtcCategoryId],d.[HasPieceParts] FROM deleted d),
    i AS (SELECT i.[WorkOrderId],i.[WorkOrderNum],i.[IsSinglePN],i.[WorkOrderTypeId],i.[OpenDate],i.[CustomerId],i.[WorkOrderStatusId],i.[EmployeeId],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[SalesPersonId],i.[CSRId],i.[ReceivingCustomerWorkId],i.[Memo],i.[Notes],i.[CustomerContactId],i.[CustomerName],i.[CustomerType],i.[CreditLimit],i.[CreditTerms],i.[TearDownTypes],i.[RMAHeaderId],i.[IsWarranty],i.[IsAccepted],i.[ReasonId],i.[Reason],i.[CreditTermId],i.[IsManualForm],i.[PercentId],i.[Days],i.[NetDays],i.[WorkOrderType],i.[FunctionalCurrencyId],i.[ReportCurrencyId],i.[ForeignExchangeRate],i.[WorkOrderFormTypeId],i.[IsWoAlwaysOrOndemandId],i.[EnforceMpnPickTicketConfirmation],i.[SecondarySalesPersonId],i.[SalesAgentID],i.[PrimarySalesRevenue],i.[PrimarySalesMargin],i.[SecondarySalesRevenue],i.[SecondarySalesMargin],i.[CSRSalesRevenue],i.[CSRSalesMargin],i.[AgentSalesRevenue],i.[AgentSalesMargin],i.[IsMigrated],i.[IsFromAircraft],i.[MtcCategoryId],i.[HasPieceParts] FROM inserted i),
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
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
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
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
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
        CASE
            WHEN m.ColumnName = 'SalesPersonId'   THEN SPOld.[FirstName] + ' ' + SPOld.[LastName]
            WHEN m.ColumnName = 'CSRId'   THEN CSROld.[FirstName] + ' ' + CSROld.[LastName]
            WHEN m.ColumnName = 'CustomerContactId'   THEN COld.[FirstName] + ' ' + COld.[LastName]
            WHEN m.ColumnName = 'ReasonId'   THEN ROld.[Reason]
            WHEN m.ColumnName = 'FunctionalCurrencyId'   THEN CfOld.[Code]
            WHEN m.ColumnName = 'ReportCurrencyId'   THEN CrOld.[Code]
            WHEN m.ColumnName = 'SecondarySalesPersonId'   THEN SSOld.[FirstName] + ' ' + SSOld.[LastName]
            WHEN m.ColumnName = 'SalesAgentID'   THEN SAOld.[FirstName] + ' ' + SAOld.[LastName]
            WHEN m.ColumnName = 'CustomerId'   THEN CustOld.[Name]
            WHEN m.ColumnName = 'WorkOrderStatusId'   THEN WosOld.[Status]
            WHEN m.ColumnName = 'EmployeeId'   THEN EmpOld.[FirstName] + ' ' + EmpOld.[LastName]
            WHEN m.ColumnName = 'CreditTermId'   THEN CrtOld.[Name]
            --WHEN m.ColumnName = 'WorkOrderFormTypeId'   THEN CASE m.OldValue WHEN '1' THEN 'Dynamic' WHEN '0' THEN 'Static' ELSE m.OldValue END
            WHEN m.ColumnName = 'WorkOrderFormTypeId'   THEN CASE m.OldValue WHEN 'true' THEN 'Dynamic' WHEN 'false' THEN 'Static' ELSE m.OldValue END
            WHEN m.ColumnName = 'WorkOrderTypeId'   THEN WotOld.[Description]
        ELSE m.OldValue
        END AS OldValue,
        CASE
            WHEN m.ColumnName = 'SalesPersonId' THEN SPNew.[FirstName] + ' ' + SPNew.[LastName]
            WHEN m.ColumnName = 'CSRId'   THEN CSRNew.[FirstName] + ' ' + CSRNew.[LastName]
            WHEN m.ColumnName = 'CustomerContactId'   THEN CNew.[FirstName] + ' ' + CNew.[LastName]
            WHEN m.ColumnName = 'ReasonId'   THEN RNew.[Reason]
            WHEN m.ColumnName = 'FunctionalCurrencyId'   THEN CfNew.[Code]
            WHEN m.ColumnName = 'ReportCurrencyId'   THEN CrNew.[Code]
            WHEN m.ColumnName = 'SecondarySalesPersonId' THEN SSNew.[FirstName] + ' ' + SSNew.[LastName]
            WHEN m.ColumnName = 'SalesAgentID'   THEN SANew.[FirstName] + ' ' + SANew.[LastName]
            WHEN m.ColumnName = 'CustomerId'   THEN CustNew.[Name]
            WHEN m.ColumnName = 'WorkOrderStatusId'   THEN WosNew.[Status]
            WHEN m.ColumnName = 'EmployeeId'   THEN EmpNew.[FirstName] + ' ' + EmpNew.[LastName]
            WHEN m.ColumnName = 'CreditTermId'   THEN CrtNew.[Name]
            --WHEN m.ColumnName = 'WorkOrderFormTypeId'   THEN CASE m.NewValue WHEN '1' THEN 'Dynamic' WHEN '0' THEN 'Static' ELSE m.NewValue END
            WHEN m.ColumnName = 'WorkOrderFormTypeId'   THEN CASE m.NewValue WHEN 'true' THEN 'Dynamic' WHEN 'false' THEN 'Static' ELSE m.NewValue END
            WHEN m.ColumnName = 'WorkOrderTypeId'   THEN WotNew.[Description]
            ELSE m.NewValue
        END AS NewValue
    FROM merged m
    LEFT JOIN DBO.Employee SPOld WITH (NOLOCK) ON m.ColumnName = 'SalesPersonId' AND TRY_CAST(m.OldValue AS bigint) = SPOld.EmployeeId
    LEFT JOIN DBO.Employee SPNew WITH (NOLOCK) ON m.ColumnName = 'SalesPersonId' AND TRY_CAST(m.NewValue AS bigint) = SPNew.EmployeeId
    LEFT JOIN DBO.Employee CSROld WITH (NOLOCK) ON m.ColumnName = 'CSRId' AND TRY_CAST(m.OldValue AS bigint) = CSROld.EmployeeId
    LEFT JOIN DBO.Employee CSRNew WITH (NOLOCK) ON m.ColumnName = 'CSRId' AND TRY_CAST(m.NewValue AS bigint) = CSRNew.EmployeeId
    LEFT JOIN DBO.CustomerContact CcOld WITH (NOLOCK) ON m.ColumnName = 'CustomerContactId' AND TRY_CAST(m.OldValue AS bigint) = CcOld.CustomerContactId
    LEFT JOIN DBO.CustomerContact CcNew WITH (NOLOCK) ON m.ColumnName = 'CustomerContactId' AND TRY_CAST(m.NewValue AS bigint) = CcNew.CustomerContactId
    LEFT JOIN DBO.Contact COld WITH (NOLOCK) ON CcOld.CustomerContactId = COld.ContactId AND TRY_CAST(m.OldValue AS bigint) = COld.ContactId
    LEFT JOIN DBO.Contact CNew WITH (NOLOCK) ON CcNew.CustomerContactId = CNew.ContactId AND TRY_CAST(m.NewValue AS bigint) = CNew.ContactId
    LEFT JOIN DBO.RMAReason ROld WITH (NOLOCK) ON m.ColumnName = 'ReasonId' AND TRY_CAST(m.OldValue AS bigint) = ROld.RMAReasonId
    LEFT JOIN DBO.RMAReason RNew WITH (NOLOCK) ON m.ColumnName = 'ReasonId' AND TRY_CAST(m.NewValue AS bigint) = RNew.RMAReasonId
    LEFT JOIN DBO.Currency CfOld WITH (NOLOCK) ON m.ColumnName = 'FunctionalCurrencyId' AND TRY_CAST(m.OldValue AS bigint) = CfOld.CurrencyId
    LEFT JOIN DBO.Currency CfNew WITH (NOLOCK) ON m.ColumnName = 'FunctionalCurrencyId' AND TRY_CAST(m.NewValue AS bigint) = CfNew.CurrencyId
    LEFT JOIN DBO.Currency CrOld WITH (NOLOCK) ON m.ColumnName = 'ReportCurrencyId' AND TRY_CAST(m.OldValue AS bigint) = CrOld.CurrencyId
    LEFT JOIN DBO.Currency CrNew WITH (NOLOCK) ON m.ColumnName = 'ReportCurrencyId' AND TRY_CAST(m.NewValue AS bigint) = CrNew.CurrencyId
    LEFT JOIN DBO.Employee SSOld WITH (NOLOCK) ON m.ColumnName = 'SecondarySalesPersonId' AND TRY_CAST(m.OldValue AS bigint) = SSOld.EmployeeId
    LEFT JOIN DBO.Employee SSNew WITH (NOLOCK) ON m.ColumnName = 'SecondarySalesPersonId' AND TRY_CAST(m.NewValue AS bigint) = SSNew.EmployeeId
    LEFT JOIN DBO.Employee SAOld WITH (NOLOCK) ON m.ColumnName = 'SalesAgentID' AND TRY_CAST(m.OldValue AS bigint) = SAOld.EmployeeId
    LEFT JOIN DBO.Employee SANew WITH (NOLOCK) ON m.ColumnName = 'SalesAgentID' AND TRY_CAST(m.NewValue AS bigint) = SANew.EmployeeId
    LEFT JOIN DBO.Customer CustOld WITH (NOLOCK) ON m.ColumnName = 'CustomerId' AND TRY_CAST(m.OldValue AS bigint) = CustOld.CustomerId
    LEFT JOIN DBO.Customer CustNew WITH (NOLOCK) ON m.ColumnName = 'CustomerId' AND TRY_CAST(m.NewValue AS bigint) = CustNew.CustomerId
    LEFT JOIN DBO.WorkOrderStatus WosOld WITH (NOLOCK) ON m.ColumnName = 'WorkOrderStatusId' AND TRY_CAST(m.OldValue AS bigint) = WosOld.Id
    LEFT JOIN DBO.WorkOrderStatus WosNew WITH (NOLOCK) ON m.ColumnName = 'WorkOrderStatusId' AND TRY_CAST(m.NewValue AS bigint) = WosNew.Id
    LEFT JOIN DBO.Employee EmpOld WITH (NOLOCK) ON m.ColumnName = 'EmployeeId' AND TRY_CAST(m.OldValue AS bigint) = EmpOld.EmployeeId
    LEFT JOIN DBO.Employee EmpNew WITH (NOLOCK) ON m.ColumnName = 'EmployeeId' AND TRY_CAST(m.NewValue AS bigint) = EmpNew.EmployeeId
    LEFT JOIN DBO.CreditTerms CrtOld WITH (NOLOCK) ON m.ColumnName = 'CreditTermId' AND TRY_CAST(m.OldValue AS int) = CrtOld.CreditTermsId
    LEFT JOIN DBO.CreditTerms CrtNew WITH (NOLOCK) ON m.ColumnName = 'CreditTermId' AND TRY_CAST(m.NewValue AS int) = CrtNew.CreditTermsId
    LEFT JOIN DBO.WorkOrderType WotOld WITH (NOLOCK) ON m.ColumnName = 'WorkOrderTypeId' AND TRY_CAST(m.OldValue AS bigint) = WotOld.Id
    LEFT JOIN DBO.WorkOrderType WotNew WITH (NOLOCK) ON m.ColumnName = 'WorkOrderTypeId' AND TRY_CAST(m.NewValue AS bigint) = WotNew.Id
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
GO

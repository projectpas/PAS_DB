CREATE TABLE [dbo].[SalesOrder] (
    [SalesOrderId]                  BIGINT          IDENTITY (1, 1) NOT NULL,
    [Version]                       INT             CONSTRAINT [DF__SalesOrde__Versi__05113BBC] DEFAULT ((1)) NOT NULL,
    [TypeId]                        INT             NOT NULL,
    [OpenDate]                      DATETIME2 (7)   NOT NULL,
    [ShippedDate]                   DATETIME2 (7)   NULL,
    [NumberOfItems]                 INT             CONSTRAINT [DF__SalesOrde__Numbe__06055FF5] DEFAULT ((0)) NOT NULL,
    [AccountTypeId]                 INT             NOT NULL,
    [CustomerId]                    BIGINT          NOT NULL,
    [CustomerContactId]             BIGINT          NOT NULL,
    [CustomerReference]             VARCHAR (100)   NOT NULL,
    [CurrencyId]                    INT             NULL,
    [TotalSalesAmount]              DECIMAL (18, 6) CONSTRAINT [DF__SalesOrde__Total__06F9842E] DEFAULT ((0)) NOT NULL,
    [CustomerHold]                  DECIMAL (18, 6) CONSTRAINT [DF__SalesOrde__Custo__07EDA867] DEFAULT ((0)) NOT NULL,
    [DepositAmount]                 DECIMAL (18, 6) CONSTRAINT [DF__SalesOrde__Depos__08E1CCA0] DEFAULT ((0)) NOT NULL,
    [BalanceDue]                    DECIMAL (18, 6) NULL,
    [SalesPersonId]                 BIGINT          NULL,
    [AgentId]                       BIGINT          NULL,
    [CustomerSeviceRepId]           BIGINT          NULL,
    [EmployeeId]                    BIGINT          NOT NULL,
    [ApprovedById]                  BIGINT          NULL,
    [ApprovedDate]                  DATETIME2 (7)   NULL,
    [Memo]                          NVARCHAR (MAX)  NULL,
    [StatusId]                      INT             CONSTRAINT [DF__SalesOrde__Statu__0ACA1512] DEFAULT ((1)) NOT NULL,
    [StatusChangeDate]              DATETIME2 (7)   CONSTRAINT [DF__SalesOrde__Statu__0BBE394B] DEFAULT (getdate()) NOT NULL,
    [Notes]                         NVARCHAR (MAX)  NULL,
    [RestrictPMA]                   BIT             CONSTRAINT [SalesOrder_RestrictPMA] DEFAULT ((0)) NOT NULL,
    [RestrictDER]                   BIT             CONSTRAINT [SalesOrder_RestrictDER] DEFAULT ((0)) NOT NULL,
    [ManagementStructureId]         BIGINT          NOT NULL,
    [CustomerWarningId]             BIGINT          NULL,
    [CreatedBy]                     VARCHAR (256)   NOT NULL,
    [CreatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_SalesOrder_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                     VARCHAR (256)   NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_SalesOrder_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [MasterCompanyId]               INT             NOT NULL,
    [IsDeleted]                     BIT             CONSTRAINT [DF__SalesOrde__IsDel__0CB25D84] DEFAULT ((0)) NOT NULL,
    [SalesOrderQuoteId]             BIGINT          NULL,
    [QtyRequested]                  DECIMAL (18, 6) CONSTRAINT [DF__SalesOrde__QtyRe__70C02A4C] DEFAULT ((0)) NULL,
    [QtyToBeQuoted]                 DECIMAL (18, 6) CONSTRAINT [DF__SalesOrde__QtyTo__767903A2] DEFAULT ((0)) NULL,
    [SalesOrderNumber]              VARCHAR (50)    NOT NULL,
    [IsActive]                      BIT             CONSTRAINT [SalesOrder_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [ContractReference]             VARCHAR (100)   NULL,
    [TypeName]                      VARCHAR (50)    NULL,
    [AccountTypeName]               VARCHAR (256)   NULL,
    [CustomerName]                  VARCHAR (100)   NULL,
    [SalesPersonName]               VARCHAR (80)    NULL,
    [CustomerServiceRepName]        VARCHAR (80)    NULL,
    [EmployeeName]                  VARCHAR (80)    NULL,
    [CurrencyName]                  VARCHAR (50)    NULL,
    [CustomerWarningName]           VARCHAR (300)   NULL,
    [ManagementStructureName]       VARCHAR (286)   NULL,
    [CreditLimit]                   DECIMAL (18, 6) NULL,
    [CreditTermId]                  INT             NULL,
    [CreditLimitName]               VARCHAR (50)    NULL,
    [CreditTermName]                VARCHAR (50)    NULL,
    [VersionNumber]                 VARCHAR (50)    NULL,
    [TotalFreight]                  DECIMAL (18, 6) NULL,
    [TotalCharges]                  DECIMAL (18, 6) NULL,
    [FreightBilingMethodId]         INT             NULL,
    [ChargesBilingMethodId]         INT             NULL,
    [EnforceEffectiveDate]          DATETIME2 (7)   NULL,
    [IsEnforceApproval]             BIT             NULL,
    [Level1]                        VARCHAR (200)   NULL,
    [Level2]                        VARCHAR (200)   NULL,
    [Level3]                        VARCHAR (200)   NULL,
    [Level4]                        VARCHAR (200)   NULL,
    [ATAPDFPath]                    VARCHAR (MAX)   NULL,
    [LotId]                         BIGINT          NULL,
    [IsLotAssigned]                 BIT             NULL,
    [AllowInvoiceBeforeShipping]    BIT             NULL,
    [PercentId]                     BIGINT          NULL,
    [Days]                          INT             NULL,
    [NetDays]                       INT             NULL,
    [COCManufacturingPDFPath]       VARCHAR (MAX)   NULL,
    [FunctionalCurrencyId]          INT             NULL,
    [ReportCurrencyId]              INT             NULL,
    [ForeignExchangeRate]           DECIMAL (18, 6) NULL,
    [EnforcePickTicketConfirmation] BIT             NULL,
    [ApprovalCode]                  VARCHAR (200)   NULL,
    [SecondarySalesPersonId]        BIGINT          NULL,
    [SalesAgentID]                  BIGINT          NULL,
    [PrimarySalesRevenue]           BIGINT          NULL,
    [PrimarySalesMargin]            BIGINT          NULL,
    [SecondarySalesRevenue]         BIGINT          NULL,
    [SecondarySalesMargin]          BIGINT          NULL,
    [CSRSalesRevenue]               BIGINT          NULL,
    [CSRSalesMargin]                BIGINT          NULL,
    [AgentSalesRevenue]             BIGINT          NULL,
    [AgentSalesMargin]              BIGINT          NULL,
    CONSTRAINT [PK_SalesOrder] PRIMARY KEY CLUSTERED ([SalesOrderId] ASC),
    CONSTRAINT [FK_SalesOrder_AccountTypeId] FOREIGN KEY ([AccountTypeId]) REFERENCES [dbo].[CustomerType] ([CustomerTypeId]),
    CONSTRAINT [FK_SalesOrder_AgentId] FOREIGN KEY ([AgentId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrder_ApprovedById] FOREIGN KEY ([ApprovedById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrder_CreditTerms] FOREIGN KEY ([CreditTermId]) REFERENCES [dbo].[CreditTerms] ([CreditTermsId]),
    CONSTRAINT [FK_SalesOrder_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_SalesOrder_CustomerId] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_SalesOrder_CustomerSeviceRepId] FOREIGN KEY ([CustomerSeviceRepId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrder_CustomerWarning] FOREIGN KEY ([CustomerWarningId]) REFERENCES [dbo].[CustomerWarning] ([CustomerWarningId]),
    CONSTRAINT [FK_SalesOrder_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrder_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrder_SalesOrderQuoteId] FOREIGN KEY ([SalesOrderQuoteId]) REFERENCES [dbo].[SalesOrderQuote] ([SalesOrderQuoteId]),
    CONSTRAINT [FK_SalesOrder_SalesPersonId] FOREIGN KEY ([SalesPersonId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrder_StatusId] FOREIGN KEY ([StatusId]) REFERENCES [dbo].[MasterSalesOrderQuoteStatus] ([Id])
);


















GO


CREATE TRIGGER [dbo].[trg_Audit_dbo_SalesOrder]

    ON  [dbo].[SalesOrder]

AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH
    d AS (SELECT d.[SalesOrderId],d.[Version],d.[TypeId],d.[OpenDate],d.[ShippedDate],d.[NumberOfItems],d.[AccountTypeId],d.[CustomerId],d.[CustomerContactId],d.[CustomerReference],d.[CurrencyId],d.[TotalSalesAmount],d.[CustomerHold],d.[DepositAmount],d.[BalanceDue],d.[SalesPersonId],d.[AgentId],d.[CustomerSeviceRepId],d.[EmployeeId],d.[ApprovedById],d.[ApprovedDate],d.[Memo],d.[StatusId],d.[StatusChangeDate],d.[Notes],d.[RestrictPMA],d.[RestrictDER],d.[ManagementStructureId],d.[CustomerWarningId],d.[CreatedBy],d.[CreatedDate],d.[UpdatedBy],d.[UpdatedDate],d.[MasterCompanyId],d.[IsDeleted],d.[SalesOrderQuoteId],d.[QtyRequested],d.[QtyToBeQuoted],d.[SalesOrderNumber],d.[IsActive],d.[ContractReference],d.[TypeName],d.[AccountTypeName],d.[CustomerName],d.[SalesPersonName],d.[CustomerServiceRepName],d.[EmployeeName],d.[CurrencyName],d.[CustomerWarningName],d.[ManagementStructureName],d.[CreditLimit],d.[CreditTermId],d.[CreditLimitName],d.[CreditTermName],d.[VersionNumber],d.[TotalFreight],d.[TotalCharges],d.[FreightBilingMethodId],d.[ChargesBilingMethodId],d.[EnforceEffectiveDate],d.[IsEnforceApproval],d.[Level1],d.[Level2],d.[Level3],d.[Level4],d.[ATAPDFPath],d.[LotId],d.[IsLotAssigned],d.[AllowInvoiceBeforeShipping],d.[PercentId],d.[Days],d.[NetDays],d.[COCManufacturingPDFPath],d.[FunctionalCurrencyId],d.[ReportCurrencyId],d.[ForeignExchangeRate],d.[EnforcePickTicketConfirmation],d.[ApprovalCode],d.[SecondarySalesPersonId],d.[SalesAgentID],d.[PrimarySalesRevenue],d.[PrimarySalesMargin],d.[SecondarySalesRevenue],d.[SecondarySalesMargin],d.[CSRSalesRevenue],d.[CSRSalesMargin],d.[AgentSalesRevenue],d.[AgentSalesMargin] FROM deleted d),
    i AS (SELECT i.[SalesOrderId],i.[Version],i.[TypeId],i.[OpenDate],i.[ShippedDate],i.[NumberOfItems],i.[AccountTypeId],i.[CustomerId],i.[CustomerContactId],i.[CustomerReference],i.[CurrencyId],i.[TotalSalesAmount],i.[CustomerHold],i.[DepositAmount],i.[BalanceDue],i.[SalesPersonId],i.[AgentId],i.[CustomerSeviceRepId],i.[EmployeeId],i.[ApprovedById],i.[ApprovedDate],i.[Memo],i.[StatusId],i.[StatusChangeDate],i.[Notes],i.[RestrictPMA],i.[RestrictDER],i.[ManagementStructureId],i.[CustomerWarningId],i.[CreatedBy],i.[CreatedDate],i.[UpdatedBy],i.[UpdatedDate],i.[MasterCompanyId],i.[IsDeleted],i.[SalesOrderQuoteId],i.[QtyRequested],i.[QtyToBeQuoted],i.[SalesOrderNumber],i.[IsActive],i.[ContractReference],i.[TypeName],i.[AccountTypeName],i.[CustomerName],i.[SalesPersonName],i.[CustomerServiceRepName],i.[EmployeeName],i.[CurrencyName],i.[CustomerWarningName],i.[ManagementStructureName],i.[CreditLimit],i.[CreditTermId],i.[CreditLimitName],i.[CreditTermName],i.[VersionNumber],i.[TotalFreight],i.[TotalCharges],i.[FreightBilingMethodId],i.[ChargesBilingMethodId],i.[EnforceEffectiveDate],i.[IsEnforceApproval],i.[Level1],i.[Level2],i.[Level3],i.[Level4],i.[ATAPDFPath],i.[LotId],i.[IsLotAssigned],i.[AllowInvoiceBeforeShipping],i.[PercentId],i.[Days],i.[NetDays],i.[COCManufacturingPDFPath],i.[FunctionalCurrencyId],i.[ReportCurrencyId],i.[ForeignExchangeRate],i.[EnforcePickTicketConfirmation],i.[ApprovalCode],i.[SecondarySalesPersonId],i.[SalesAgentID],i.[PrimarySalesRevenue],i.[PrimarySalesMargin],i.[SecondarySalesRevenue],i.[SecondarySalesMargin],i.[CSRSalesRevenue],i.[CSRSalesMargin],i.[AgentSalesRevenue],i.[AgentSalesMargin] FROM inserted i),
    paired AS (
        SELECT
            COALESCE(i.SalesOrderId, d.SalesOrderId ) AS SalesOrderId,
            (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
            (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
            CASE
                WHEN i.SalesOrderId IS NOT NULL AND d.SalesOrderId IS NOT NULL THEN 'U'
                WHEN i.SalesOrderId IS NOT NULL AND d.SalesOrderId IS NULL     THEN 'I'
                WHEN i.SalesOrderId IS NULL     AND d.SalesOrderId IS NOT NULL THEN 'D'
            END AS Action,

            (SELECT COALESCE(i.SalesOrderId, d.SalesOrderId) AS SalesOrderId
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
        FROM d
        FULL OUTER JOIN i
            ON i.SalesOrderId = d.SalesOrderId
    ),

    oldv AS (
        SELECT
            p.PKJson,
            p.SalesOrderId,
            v.[key]  AS ColumnName,
            v.value  AS OldValue
        FROM paired p
        CROSS APPLY OPENJSON(p.old_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'SalesOrder'
                AND ign.ColumnName = N'SalesOrderId'
        )),
    newv AS (
        SELECT
            p.PKJson,
            p.SalesOrderId ,
            v.[key]  AS ColumnName,
            v.value  AS NewValue
        FROM paired p
        CROSS APPLY OPENJSON(p.new_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'SalesOrder'
                AND ign.ColumnName = N'SalesOrderId'
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
            ON o.SalesOrderId = p.SalesOrderId
        LEFT JOIN newv n
            ON n.SalesOrderId = p.SalesOrderId
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
            ON n.SalesOrderId = p.SalesOrderId
        WHERE NOT EXISTS (
            SELECT 1
            FROM oldv o2
            WHERE o2.SalesOrderId = p.SalesOrderId
                AND o2.ColumnName    = n.ColumnName
        )
    )
    INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
    SELECT
        N'dbo' AS SchemaName,
        N'SalesOrder' AS TableName,
        m.PKJson,
        m.ColumnName,
        m.Action,
        CASE
            WHEN m.ColumnName = 'SalesOrderQuoteId' THEN soqOld.SalesOrderQuoteNumber   
            WHEN m.ColumnName = 'StatusId' THEN msoqOld.[Name]
            WHEN m.ColumnName = 'CustomerId' THEN cOld.[Name]
            WHEN m.ColumnName = 'AccountTypeId' THEN ctOld.CustomerTypeName                     
            ELSE m.OldValue
        END AS OldValue,        
        CASE 
            WHEN m.ColumnName = 'SalesOrderQuoteId' THEN soqNew.SalesOrderQuoteNumber   
            WHEN m.ColumnName = 'StatusId' THEN msoqNew.[Name]
            WHEN m.ColumnName = 'CustomerId' THEN cNew.[Name]
            WHEN m.ColumnName = 'AccountTypeId' THEN ctNew.CustomerTypeName                      
            ELSE m.NewValue
        END AS NewValue
    FROM merged m
    LEFT JOIN [dbo].[SalesOrderQuote] soqOld WITH(NOLOCK) ON m.ColumnName = 'SalesOrderQuoteId' AND TRY_CAST(m.OldValue AS BIGINT) = soqOld.SalesOrderQuoteId 
    LEFT JOIN [dbo].[SalesOrderQuote] soqNew WITH(NOLOCK) ON m.ColumnName = 'SalesOrderQuoteId' AND TRY_CAST(m.NewValue AS BIGINT) = soqNew.SalesOrderQuoteId 
    LEFT JOIN [dbo].[MasterSalesOrderQuoteStatus] msoqOld WITH(NOLOCK) ON m.ColumnName = 'StatusId' AND TRY_CAST(m.OldValue AS INT) = msoqOld.Id 
    LEFT JOIN [dbo].[MasterSalesOrderQuoteStatus] msoqNew WITH(NOLOCK) ON m.ColumnName = 'StatusId' AND TRY_CAST(m.NewValue AS INT) = msoqNew.Id
    LEFT JOIN [dbo].[Customer] cOld WITH(NOLOCK) ON m.ColumnName = 'CustomerId' AND TRY_CAST(m.OldValue AS BIGINT) = cOld.CustomerId 
    LEFT JOIN [dbo].[Customer] cNew WITH(NOLOCK) ON m.ColumnName = 'CustomerId' AND TRY_CAST(m.NewValue AS BIGINT) = cNew.CustomerId
    LEFT JOIN [dbo].[CustomerType] ctOld WITH(NOLOCK) ON m.ColumnName = 'AccountTypeId' AND TRY_CAST(m.OldValue AS INT) = ctOld.CustomerTypeId 
    LEFT JOIN [dbo].[CustomerType] ctNew WITH(NOLOCK) ON m.ColumnName = 'AccountTypeId' AND TRY_CAST(m.NewValue AS INT) = ctNew.CustomerTypeId 
    WHERE
        m.ColumnName <> 'SalesOrderId' and (
        (m.Action = 'U' AND (
                (m.OldValue IS NULL AND m.NewValue IS NOT NULL)
            OR (m.OldValue IS NOT NULL AND m.NewValue IS NULL)
            OR (m.OldValue <> m.NewValue)
        ))
        OR
        (m.Action = 'I' AND m.NewValue IS NOT NULL)
        OR
        (m.Action = 'D' AND m.OldValue IS NOT NULL));
END;
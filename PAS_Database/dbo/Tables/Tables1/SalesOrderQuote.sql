CREATE TABLE [dbo].[SalesOrderQuote] (
    [SalesOrderQuoteId]        BIGINT          IDENTITY (1, 1) NOT NULL,
    [QuoteTypeId]              INT             NOT NULL,
    [OpenDate]                 DATETIME2 (7)   NULL,
    [ValidForDays]             INT             NOT NULL,
    [QuoteExpireDate]          DATETIME2 (7)   NOT NULL,
    [AccountTypeId]            INT             NOT NULL,
    [CustomerId]               BIGINT          NOT NULL,
    [CustomerContactId]        BIGINT          NULL,
    [CustomerReference]        VARCHAR (100)   NULL,
    [ContractReference]        VARCHAR (100)   NULL,
    [SalesPersonId]            BIGINT          NULL,
    [AgentName]                VARCHAR (50)    NULL,
    [CustomerSeviceRepId]      BIGINT          NULL,
    [ProbabilityId]            BIGINT          NULL,
    [LeadSourceId]             INT             NULL,
    [CreditLimit]              DECIMAL (18, 2) NULL,
    [CreditTermId]             INT             NULL,
    [EmployeeId]               BIGINT          NOT NULL,
    [RestrictPMA]              BIT             CONSTRAINT [SalesOrderQuote_RestrictPMA] DEFAULT ((0)) NOT NULL,
    [RestrictDER]              BIT             CONSTRAINT [SalesOrderQuote_RestrictDER] DEFAULT ((0)) NOT NULL,
    [ApprovedDate]             DATETIME2 (7)   NULL,
    [CurrencyId]               INT             NULL,
    [CustomerWarningId]        BIGINT          NULL,
    [Memo]                     NVARCHAR (MAX)  NULL,
    [Notes]                    NVARCHAR (MAX)  NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_SalesOrderQuote_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_SalesOrderQuote_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF__SalesOrde__IsDel__40E5634A] DEFAULT ((0)) NOT NULL,
    [StatusId]                 INT             CONSTRAINT [DF__SalesOrde__Statu__41D98783] DEFAULT ((1)) NOT NULL,
    [StatusChangeDate]         DATETIME2 (7)   CONSTRAINT [DF__SalesOrde__Statu__42CDABBC] DEFAULT (getdate()) NOT NULL,
    [ManagementStructureId]    BIGINT          NOT NULL,
    [Version]                  INT             NOT NULL,
    [AgentId]                  BIGINT          NULL,
    [QtyRequested]             DECIMAL (18, 6) CONSTRAINT [DF__SalesOrde__QtyRe__43C1CFF5] DEFAULT ((0)) NULL,
    [QtyToBeQuoted]            DECIMAL (18, 6) CONSTRAINT [DF__SalesOrde__QtyTo__44B5F42E] DEFAULT ((0)) NULL,
    [SalesOrderQuoteNumber]    VARCHAR (50)    NOT NULL,
    [QuoteSentDate]            DATETIME2 (7)   NULL,
    [IsNewVersionCreated]      BIT             CONSTRAINT [DF__SalesOrde__IsNew__45AA1867] DEFAULT ((0)) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [SalesOrderQuote_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [QuoteParentId]            BIGINT          NULL,
    [QuoteTypeName]            VARCHAR (50)    NULL,
    [AccountTypeName]          VARCHAR (256)   NULL,
    [CustomerName]             VARCHAR (100)   NULL,
    [SalesPersonName]          VARCHAR (80)    NULL,
    [CustomerServiceRepName]   VARCHAR (80)    NULL,
    [ProbabilityName]          VARCHAR (50)    NULL,
    [LeadSourceName]           VARCHAR (50)    NULL,
    [CreditTermName]           VARCHAR (50)    NULL,
    [EmployeeName]             VARCHAR (80)    NULL,
    [CurrencyName]             VARCHAR (50)    NULL,
    [CustomerWarningName]      VARCHAR (500)   NULL,
    [ManagementStructureName]  VARCHAR (286)   NULL,
    [CustomerContactName]      VARCHAR (200)   NULL,
    [VersionNumber]            VARCHAR (50)    NULL,
    [CustomerCode]             VARCHAR (100)   NULL,
    [CustomerContactEmail]     VARCHAR (200)   NULL,
    [CreditLimitName]          VARCHAR (50)    NULL,
    [StatusName]               VARCHAR (50)    NULL,
    [ManagementStructureName1] VARCHAR (50)    NULL,
    [ManagementStructureName2] VARCHAR (50)    NULL,
    [ManagementStructureName3] VARCHAR (50)    NULL,
    [ManagementStructureName4] VARCHAR (50)    NULL,
    [EnforceEffectiveDate]     DATETIME2 (7)   NULL,
    [IsEnforceApproval]        BIT             NULL,
    [TotalFreight]             DECIMAL (20, 2) NULL,
    [TotalCharges]             DECIMAL (20, 2) NULL,
    [FreightBilingMethodId]    INT             NULL,
    [ChargesBilingMethodId]    INT             NULL,
    [FunctionalCurrencyId]     INT             NULL,
    [ReportCurrencyId]         INT             NULL,
    [ForeignExchangeRate]      DECIMAL (18, 2) NULL,
    [LotId]                    BIGINT          NULL,
    [IsLotAssigned]            BIT             NULL,
    [SourceBy]                 VARCHAR (50)    NULL,
    [MarketplaceRef]           VARCHAR (50)    NULL,
    [ApprovalCode]             VARCHAR (200)   NULL,
    CONSTRAINT [PK_SalesOrderQuote] PRIMARY KEY CLUSTERED ([SalesOrderQuoteId] ASC),
    CONSTRAINT [FK_SalesOrderQuote_CreditTerms] FOREIGN KEY ([CreditTermId]) REFERENCES [dbo].[CreditTerms] ([CreditTermsId]),
    CONSTRAINT [FK_SalesOrderQuote_CurrencyId] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_SalesOrderQuote_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_SalesOrderQuote_CustomerType] FOREIGN KEY ([AccountTypeId]) REFERENCES [dbo].[CustomerType] ([CustomerTypeId]),
    CONSTRAINT [FK_SalesOrderQuote_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrderQuote_Employee_Agent] FOREIGN KEY ([AgentId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrderQuote_Employee_CustomerSeviceRep] FOREIGN KEY ([CustomerSeviceRepId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrderQuote_Employee_SalesPerson] FOREIGN KEY ([SalesPersonId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrderQuote_LeadSource] FOREIGN KEY ([LeadSourceId]) REFERENCES [dbo].[LeadSource] ([LeadSourceId]),
    CONSTRAINT [FK_SalesOrderQuote_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderQuote_MasterSalesOrderQuoteStatus] FOREIGN KEY ([StatusId]) REFERENCES [dbo].[MasterSalesOrderQuoteStatus] ([Id]),
    CONSTRAINT [FK_SalesOrderQuote_MasterSalesOrderQuoteTypes] FOREIGN KEY ([QuoteTypeId]) REFERENCES [dbo].[MasterSalesOrderQuoteTypes] ([Id]),
    CONSTRAINT [FK_SalesOrderQuote_Percent] FOREIGN KEY ([ProbabilityId]) REFERENCES [dbo].[Percent] ([PercentId])
);


















GO

   
CREATE TRIGGER [dbo].[trg_Audit_dbo_SalesOrderQuote]
ON  [dbo].[SalesOrderQuote]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH
    d AS (SELECT d.[SalesOrderQuoteId],d.[QuoteTypeId],d.[OpenDate],d.[ValidForDays],d.[QuoteExpireDate],d.[AccountTypeId],d.[CustomerId],d.[CustomerContactId],d.[CustomerReference],d.[ContractReference],d.[SalesPersonId],d.[AgentName],d.[CustomerSeviceRepId],d.[ProbabilityId],d.[LeadSourceId],d.[CreditLimit],d.[CreditTermId],d.[EmployeeId],d.[RestrictPMA],d.[RestrictDER],d.[ApprovedDate],d.[CurrencyId],d.[CustomerWarningId],d.[Memo],d.[Notes],d.[MasterCompanyId],d.[CreatedBy],d.[CreatedDate],d.[UpdatedBy],d.[UpdatedDate],d.[IsDeleted],d.[StatusId],d.[StatusChangeDate],d.[ManagementStructureId],d.[Version],d.[AgentId],d.[QtyRequested],d.[QtyToBeQuoted],d.[SalesOrderQuoteNumber],d.[QuoteSentDate],d.[IsNewVersionCreated],d.[IsActive],d.[QuoteParentId],d.[QuoteTypeName],d.[AccountTypeName],d.[CustomerName],d.[SalesPersonName],d.[CustomerServiceRepName],d.[ProbabilityName],d.[LeadSourceName],d.[CreditTermName],d.[EmployeeName],d.[CurrencyName],d.[CustomerWarningName],d.[ManagementStructureName],d.[CustomerContactName],d.[VersionNumber],d.[CustomerCode],d.[CustomerContactEmail],d.[CreditLimitName],d.[StatusName],d.[ManagementStructureName1],d.[ManagementStructureName2],d.[ManagementStructureName3],d.[ManagementStructureName4],d.[EnforceEffectiveDate],d.[IsEnforceApproval],d.[TotalFreight],d.[TotalCharges],d.[FreightBilingMethodId],d.[ChargesBilingMethodId],d.[FunctionalCurrencyId],d.[ReportCurrencyId],d.[ForeignExchangeRate],d.[LotId],d.[IsLotAssigned],d.[SourceBy],d.[MarketplaceRef],d.[ApprovalCode] FROM deleted d),
    i AS (SELECT i.[SalesOrderQuoteId],i.[QuoteTypeId],i.[OpenDate],i.[ValidForDays],i.[QuoteExpireDate],i.[AccountTypeId],i.[CustomerId],i.[CustomerContactId],i.[CustomerReference],i.[ContractReference],i.[SalesPersonId],i.[AgentName],i.[CustomerSeviceRepId],i.[ProbabilityId],i.[LeadSourceId],i.[CreditLimit],i.[CreditTermId],i.[EmployeeId],i.[RestrictPMA],i.[RestrictDER],i.[ApprovedDate],i.[CurrencyId],i.[CustomerWarningId],i.[Memo],i.[Notes],i.[MasterCompanyId],i.[CreatedBy],i.[CreatedDate],i.[UpdatedBy],i.[UpdatedDate],i.[IsDeleted],i.[StatusId],i.[StatusChangeDate],i.[ManagementStructureId],i.[Version],i.[AgentId],i.[QtyRequested],i.[QtyToBeQuoted],i.[SalesOrderQuoteNumber],i.[QuoteSentDate],i.[IsNewVersionCreated],i.[IsActive],i.[QuoteParentId],i.[QuoteTypeName],i.[AccountTypeName],i.[CustomerName],i.[SalesPersonName],i.[CustomerServiceRepName],i.[ProbabilityName],i.[LeadSourceName],i.[CreditTermName],i.[EmployeeName],i.[CurrencyName],i.[CustomerWarningName],i.[ManagementStructureName],i.[CustomerContactName],i.[VersionNumber],i.[CustomerCode],i.[CustomerContactEmail],i.[CreditLimitName],i.[StatusName],i.[ManagementStructureName1],i.[ManagementStructureName2],i.[ManagementStructureName3],i.[ManagementStructureName4],i.[EnforceEffectiveDate],i.[IsEnforceApproval],i.[TotalFreight],i.[TotalCharges],i.[FreightBilingMethodId],i.[ChargesBilingMethodId],i.[FunctionalCurrencyId],i.[ReportCurrencyId],i.[ForeignExchangeRate],i.[LotId],i.[IsLotAssigned],i.[SourceBy],i.[MarketplaceRef],i.[ApprovalCode] FROM inserted i),
    paired AS (
        SELECT
            COALESCE(i.SalesOrderQuoteId, d.SalesOrderQuoteId ) AS SalesOrderQuoteId,
            (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
            (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
            CASE
                WHEN i.SalesOrderQuoteId IS NOT NULL AND d.SalesOrderQuoteId IS NOT NULL THEN 'U'
                WHEN i.SalesOrderQuoteId IS NOT NULL AND d.SalesOrderQuoteId IS NULL     THEN 'I'
                WHEN i.SalesOrderQuoteId IS NULL     AND d.SalesOrderQuoteId IS NOT NULL THEN 'D'
            END AS Action,

            (SELECT COALESCE(i.SalesOrderQuoteId, d.SalesOrderQuoteId) AS SalesOrderQuoteId
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
        FROM d
        FULL OUTER JOIN i
            ON i.SalesOrderQuoteId = d.SalesOrderQuoteId
    ),

    oldv AS (
        SELECT
            p.PKJson,
            p.SalesOrderQuoteId,
            v.[key]  AS ColumnName,
            v.value  AS OldValue
        FROM paired p
        CROSS APPLY OPENJSON(p.old_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'SalesOrderQuote'
                AND ign.ColumnName = N'SalesOrderQuoteId'
        )),
    newv AS (
        SELECT
            p.PKJson,
            p.SalesOrderQuoteId ,
            v.[key]  AS ColumnName,
            v.value  AS NewValue
        FROM paired p
        CROSS APPLY OPENJSON(p.new_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'SalesOrderQuote'
                AND ign.ColumnName = N'SalesOrderQuoteId'
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
            ON o.SalesOrderQuoteId = p.SalesOrderQuoteId
        LEFT JOIN newv n
            ON n.SalesOrderQuoteId = p.SalesOrderQuoteId
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
            ON n.SalesOrderQuoteId = p.SalesOrderQuoteId
        WHERE NOT EXISTS (
            SELECT 1
            FROM oldv o2
            WHERE o2.SalesOrderQuoteId = p.SalesOrderQuoteId
                AND o2.ColumnName    = n.ColumnName
        )
    )
    INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
    SELECT
        N'dbo' AS SchemaName,
        N'SalesOrderQuote' AS TableName,
        m.PKJson,
        m.ColumnName,
        m.Action,
        CASE             
            WHEN m.ColumnName = 'StatusId' THEN msoqOld.[Description]            
            WHEN m.ColumnName = 'AccountTypeId' THEN ctOld.CustomerTypeName                     
            ELSE m.OldValue
        END AS OldValue,        
        CASE            
            WHEN m.ColumnName = 'StatusId' THEN msoqNew.[Description]           
            WHEN m.ColumnName = 'AccountTypeId' THEN ctNew.CustomerTypeName                      
            ELSE m.NewValue
        END AS NewValue
    FROM merged m
    LEFT JOIN [dbo].[MasterSalesOrderQuoteStatus] msoqOld WITH(NOLOCK) ON m.ColumnName = 'StatusId' AND TRY_CAST(m.OldValue AS INT) = msoqOld.Id 
    LEFT JOIN [dbo].[MasterSalesOrderQuoteStatus] msoqNew WITH(NOLOCK) ON m.ColumnName = 'StatusId' AND TRY_CAST(m.NewValue AS INT) = msoqNew.Id    
    LEFT JOIN [dbo].[CustomerType] ctOld WITH(NOLOCK) ON m.ColumnName = 'AccountTypeId' AND TRY_CAST(m.OldValue AS BIGINT) = ctOld.CustomerTypeId 
    LEFT JOIN [dbo].[CustomerType] ctNew WITH(NOLOCK) ON m.ColumnName = 'AccountTypeId' AND TRY_CAST(m.NewValue AS BIGINT) = ctNew.CustomerTypeId 
    WHERE
         m.ColumnName <> 'SalesOrderQuoteId' and (
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
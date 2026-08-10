CREATE TABLE [dbo].[Customer] (
    [CustomerId]                BIGINT         IDENTITY (1, 1) NOT NULL,
    [CustomerAffiliationId]     INT            NULL,
    [CustomerTypeId]            INT            NOT NULL,
    [Name]                      VARCHAR (100)  NOT NULL,
    [CustomerCode]              VARCHAR (100)  NOT NULL,
    [DoingBuinessAsName]        VARCHAR (50)   NULL,
    [IsParent]                  BIT            CONSTRAINT [Customer_DC_IsParent] DEFAULT ((0)) NOT NULL,
    [ParentId]                  BIGINT         NULL,
    [CustomerPhone]             VARCHAR (20)   NULL,
    [CustomerPhoneExt]          VARCHAR (20)   NULL,
    [Email]                     VARCHAR (200)  NULL,
    [AddressId]                 BIGINT         NOT NULL,
    [IsAddressForBilling]       BIT            CONSTRAINT [DF__Customer__IsAddr__18D6A699] DEFAULT ((0)) NOT NULL,
    [IsAddressForShipping]      BIT            CONSTRAINT [DF__Customer__IsAddr__19CACAD2] DEFAULT ((0)) NOT NULL,
    [IsCustomerAlsoVendor]      BIT            NOT NULL,
    [ContractReference]         VARCHAR (100)  NULL,
    [IsPBHCustomer]             BIT            NOT NULL,
    [PBHCustomerMemo]           VARCHAR (MAX)  NULL,
    [CustomerURL]               NVARCHAR (500) NULL,
    [RestrictPMA]               BIT            NOT NULL,
    [RestrictDER]               BIT            CONSTRAINT [Customer_DC_RestrictBER] DEFAULT ((0)) NOT NULL,
    [ManagementStructureId]     BIGINT         NULL,
    [MasterCompanyId]           INT            NOT NULL,
    [CreatedBy]                 VARCHAR (256)  NOT NULL,
    [UpdatedBy]                 VARCHAR (256)  NOT NULL,
    [CreatedDate]               DATETIME2 (7)  CONSTRAINT [DF_Customer_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7)  CONSTRAINT [DF_Customer_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT            CONSTRAINT [Customer_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT            CONSTRAINT [Customer_DC_Delete] DEFAULT ((0)) NOT NULL,
    [IsCRMCustomer]             BIT            CONSTRAINT [Customer_DC_IsCRM] DEFAULT ((0)) NOT NULL,
    [BillingAddressId]          BIGINT         NULL,
    [ShippingAddressId]         BIGINT         NULL,
    [IsTradeRestricted]         BIT            NULL,
    [TradeRestrictedMemo]       NVARCHAR (MAX) NULL,
    [IsTrackScoreCard]          BIT            NULL,
    [CommunicationPreference]   INT            NULL,
    [Ismiscellaneous]           BIT            DEFAULT ((0)) NOT NULL,
    [IsStageChange]             BIT            NULL,
    [IsCommunicationPreference] BIT            NULL,
    [IsCustomerShipping]        BIT            DEFAULT ((0)) NULL,
    [QuickBooksReferenceId]     VARCHAR (200)  NULL,
    [IsUpdated]                 BIT            NULL,
    [LastSyncDate]              DATETIME2 (7)  NULL,
    [Memo]                      NVARCHAR (MAX) NULL,
    [SyncToken]                 VARCHAR (200)  NULL,
    [IntegrationTypeId]         INT            NULL,
    [ResaleNumber]              VARCHAR (200)  NULL,
    [VatNumber]                 VARCHAR (50)   NULL,
    CONSTRAINT [PK_Customer] PRIMARY KEY CLUSTERED ([CustomerId] ASC),
    CONSTRAINT [FK_Customer_Address] FOREIGN KEY ([AddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_Customer_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_Customer_CustomerAffiliation] FOREIGN KEY ([CustomerAffiliationId]) REFERENCES [dbo].[CustomerAffiliation] ([CustomerAffiliationId]),
    CONSTRAINT [FK_Customer_CustomerType] FOREIGN KEY ([CustomerTypeId]) REFERENCES [dbo].[CustomerType] ([CustomerTypeId]),
    CONSTRAINT [FK_Customer_ManagementStructure] FOREIGN KEY ([ManagementStructureId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [FK_Customer_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_CustomerCode] UNIQUE NONCLUSTERED ([CustomerCode] ASC, [MasterCompanyId] ASC)
);
GO
CREATE TRIGGER [dbo].[trg_Audit_dbo_Customer]
ON [dbo].[Customer]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH
    d AS (SELECT d.[CustomerId],d.[CustomerAffiliationId],d.[CustomerTypeId],d.[Name],d.[CustomerCode],d.[DoingBuinessAsName],d.[IsParent],d.[ParentId],d.[CustomerPhone],d.[CustomerPhoneExt],d.[Email],d.[AddressId],d.[IsAddressForBilling],d.[IsAddressForShipping],d.[IsCustomerAlsoVendor],d.[ContractReference],d.[IsPBHCustomer],d.[PBHCustomerMemo],d.[CustomerURL],d.[RestrictPMA],d.[RestrictDER],d.[ManagementStructureId],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[IsCRMCustomer],d.[BillingAddressId],d.[ShippingAddressId],d.[IsTradeRestricted],d.[TradeRestrictedMemo],d.[IsTrackScoreCard],d.[CommunicationPreference],d.[Ismiscellaneous],d.[IsStageChange],d.[IsCommunicationPreference],d.[IsCustomerShipping],d.[QuickBooksReferenceId],d.[IsUpdated],d.[LastSyncDate],d.[Memo],d.[SyncToken],d.[IntegrationTypeId],d.[ResaleNumber],d.[VatNumber] FROM deleted d),
    i AS (SELECT i.[CustomerId],i.[CustomerAffiliationId],i.[CustomerTypeId],i.[Name],i.[CustomerCode],i.[DoingBuinessAsName],i.[IsParent],i.[ParentId],i.[CustomerPhone],i.[CustomerPhoneExt],i.[Email],i.[AddressId],i.[IsAddressForBilling],i.[IsAddressForShipping],i.[IsCustomerAlsoVendor],i.[ContractReference],i.[IsPBHCustomer],i.[PBHCustomerMemo],i.[CustomerURL],i.[RestrictPMA],i.[RestrictDER],i.[ManagementStructureId],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[IsCRMCustomer],i.[BillingAddressId],i.[ShippingAddressId],i.[IsTradeRestricted],i.[TradeRestrictedMemo],i.[IsTrackScoreCard],i.[CommunicationPreference],i.[Ismiscellaneous],i.[IsStageChange],i.[IsCommunicationPreference],i.[IsCustomerShipping],i.[QuickBooksReferenceId],i.[IsUpdated],i.[LastSyncDate],i.[Memo],i.[SyncToken],i.[IntegrationTypeId],i.[ResaleNumber],i.[VatNumber] FROM inserted i),
    paired AS (
        SELECT
            COALESCE(i.CustomerId, d.CustomerId ) AS CustomerId,
            (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
            (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
            CASE
                WHEN i.CustomerId IS NOT NULL AND d.CustomerId IS NOT NULL THEN 'U'
                WHEN i.CustomerId IS NOT NULL AND d.CustomerId IS NULL     THEN 'I'
                WHEN i.CustomerId IS NULL     AND d.CustomerId IS NOT NULL THEN 'D'
            END AS Action,

            (SELECT COALESCE(i.CustomerId, d.CustomerId) AS CustomerId
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
        FROM d
        FULL OUTER JOIN i
            ON i.CustomerId = d.CustomerId
    ),

    oldv AS (
        SELECT
            p.PKJson,
            p.CustomerId,
            v.[key]  AS ColumnName,
            v.value  AS OldValue
        FROM paired p
        CROSS APPLY OPENJSON(p.old_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'Customer'
                AND ign.ColumnName = N'CustomerId'
        )),
    newv AS (
        SELECT
            p.PKJson,
            p.CustomerId ,
            v.[key]  AS ColumnName,
            v.value  AS NewValue
        FROM paired p
        CROSS APPLY OPENJSON(p.new_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'Customer'
                AND ign.ColumnName = N'CustomerId'
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
            ON o.CustomerId = p.CustomerId
        LEFT JOIN newv n
            ON n.CustomerId = p.CustomerId
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
            ON n.CustomerId = p.CustomerId
        WHERE NOT EXISTS (
            SELECT 1
            FROM oldv o2
            WHERE o2.CustomerId = p.CustomerId
                AND o2.ColumnName    = n.ColumnName
        )
    )
    INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
    SELECT
        N'dbo' AS SchemaName,
        N'Customer' AS TableName,
        m.PKJson,
        m.ColumnName,
        m.Action,
       CASE
            WHEN m.ColumnName = 'CustomerAffiliationId' THEN 
                CASE 
                    WHEN m.OldValue = '1' THEN 'Internal' 
                    WHEN m.OldValue = '2' THEN 'External' 
                    WHEN m.OldValue = '3' THEN 'Affiliate' 
                    ELSE m.OldValue
                END
            WHEN m.ColumnName = 'CustomerTypeId' THEN ctOld.CustomerTypeName  
            WHEN m.ColumnName = 'CommunicationPreference' THEN 
                CASE 
                    WHEN m.OldValue = '1' THEN 'Email' 
                    WHEN m.OldValue = '2' THEN 'Phone' 
                    WHEN m.OldValue = '3' THEN 'Text Message' 
                    ELSE m.OldValue
                END
            WHEN m.ColumnName = 'ParentId' THEN cOld.[Name]                               
            ELSE m.OldValue
        END AS OldValue,        
        CASE 
            WHEN m.ColumnName = 'CustomerAffiliationId' THEN 
                CASE 
                    WHEN m.NewValue = '1' THEN 'Internal' 
                    WHEN m.NewValue = '2' THEN 'External' 
                    WHEN m.NewValue = '3' THEN 'Affiliate' 
                    ELSE m.NewValue
                END
            WHEN m.ColumnName = 'CustomerTypeId' THEN ctNew.CustomerTypeName
            WHEN m.ColumnName = 'CommunicationPreference' THEN 
                CASE 
                    WHEN m.NewValue = '1' THEN 'Email' 
                    WHEN m.NewValue = '2' THEN 'Phone' 
                    WHEN m.NewValue = '3' THEN 'Text Message' 
                    ELSE m.NewValue
                END
            WHEN m.ColumnName = 'ParentId' THEN cNew.[Name]                         
            ELSE m.NewValue
        END AS NewValue
    FROM merged m
    LEFT JOIN [dbo].[CustomerType] ctOld WITH(NOLOCK) ON m.ColumnName = 'CustomerTypeId' AND TRY_CAST(m.OldValue AS INT) = ctOld.CustomerTypeId 
    LEFT JOIN [dbo].[CustomerType] ctNew WITH(NOLOCK) ON m.ColumnName = 'CustomerTypeId' AND TRY_CAST(m.NewValue AS INT) = ctNew.CustomerTypeId 
    LEFT JOIN [dbo].[Customer] cOld WITH(NOLOCK) ON m.ColumnName = 'ParentId' AND TRY_CAST(m.OldValue AS INT) = cOld.CustomerId 
    LEFT JOIN [dbo].[Customer] cNew WITH(NOLOCK) ON m.ColumnName = 'ParentId' AND TRY_CAST(m.NewValue AS INT) = cNew.CustomerId 
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
CREATE NONCLUSTERED INDEX [IX_Customer_MasterCompanyId_IsDeleted_IsActive_Perf]
    ON [dbo].[Customer]([MasterCompanyId] ASC, [IsDeleted] ASC, [IsActive] ASC)
    INCLUDE([CustomerTypeId], [CustomerAffiliationId], [AddressId], [Name], [CustomerCode], [Email], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [QuickBooksReferenceId], [LastSyncDate], [IsCustomerAlsoVendor], [IsUpdated], [IsTrackScoreCard], [ResaleNumber], [VatNumber]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);
-- Added 2026-08-03: supports GetCustomerList's tenant/soft-delete/active filter (see
-- UOM_GetCustomerList_Deploy.sql for the full review).
GO
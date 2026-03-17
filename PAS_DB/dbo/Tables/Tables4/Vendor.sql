CREATE TABLE [dbo].[Vendor] (
    [VendorId]                BIGINT          IDENTITY (1, 1) NOT NULL,
    [VendorTypeId]            INT             NOT NULL,
    [VendorName]              VARCHAR (100)   NOT NULL,
    [VendorCode]              VARCHAR (100)   NOT NULL,
    [DoingBusinessAsName]     VARCHAR (50)    NULL,
    [IsParent]                BIT             CONSTRAINT [DF_Vendor_IsParent] DEFAULT ((0)) NOT NULL,
    [VendorParentId]          BIGINT          NULL,
    [VendorPhone]             VARCHAR (256)   NULL,
    [VendorPhoneExt]          VARCHAR (10)    NULL,
    [VendorEmail]             VARCHAR (200)   NULL,
    [AddressId]               BIGINT          NOT NULL,
    [IsAddressForBilling]     BIT             CONSTRAINT [Vendor_DC_IsAddressForBilling] DEFAULT ((0)) NOT NULL,
    [IsAddressForShipping]    BIT             CONSTRAINT [Vendor_DC_IsAddressForShipping] DEFAULT ((0)) NOT NULL,
    [IsVendorAlsoCustomer]    BIT             CONSTRAINT [Vendor_DC_IsVendorAlsoCustomer] DEFAULT ((0)) NOT NULL,
    [RelatedCustomerId]       BIGINT          NULL,
    [IsAllowNettingAPAR]      BIT             CONSTRAINT [DF__Vendor__IsAllowN__54AC64D5] DEFAULT ((0)) NOT NULL,
    [VendorContractReference] VARCHAR (30)    NULL,
    [IsPreferredVendor]       BIT             CONSTRAINT [Vendor_DC_IsPreferredVendor] DEFAULT ((0)) NOT NULL,
    [LicenseNumber]           VARCHAR (30)    NULL,
    [VendorURL]               VARCHAR (100)   NULL,
    [IsCertified]             BIT             CONSTRAINT [Vendor_DC_IsCertified] DEFAULT ((0)) NOT NULL,
    [VendorAudit]             BIT             CONSTRAINT [Vendor_DC_VendorAudit] DEFAULT ((0)) NOT NULL,
    [EDI]                     BIT             CONSTRAINT [Vendor_DC_EDI] DEFAULT ((0)) NOT NULL,
    [EDIDescription]          VARCHAR (100)   NULL,
    [AeroExchange]            BIT             CONSTRAINT [Vendor_DC_AeroExchange] DEFAULT ((0)) NOT NULL,
    [AeroExchangeDescription] VARCHAR (100)   NULL,
    [CreditLimit]             DECIMAL (18, 2) NULL,
    [CreditTermsId]           INT             NULL,
    [CurrencyId]              INT             NULL,
    [DiscountId]              BIGINT          NULL,
    [Is1099Required]          BIT             NOT NULL,
    [IsAllow]                 BIT             CONSTRAINT [DF__Vendor__IsAllow__7A3EA78E] DEFAULT ((0)) NOT NULL,
    [IsWarning]               BIT             CONSTRAINT [DF__Vendor__IsWarnin__794A8355] DEFAULT ((0)) NOT NULL,
    [IsRestrict]              BIT             CONSTRAINT [DF__Vendor__IsRestri__78565F1C] DEFAULT ((0)) NOT NULL,
    [ManagementStructureId]   BIGINT          NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [Vendor_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [Vendor_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT             CONSTRAINT [Vendor_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT             CONSTRAINT [Vendor_DC_Delete] DEFAULT ((0)) NOT NULL,
    [BillingAddressId]        BIGINT          NULL,
    [ShippingAddressId]       BIGINT          NULL,
    [IsTradeRestricted]       BIT             NULL,
    [TradeRestrictedMemo]     NVARCHAR (MAX)  NULL,
    [IsTrackScoreCard]        BIT             NULL,
    [IsVendorOnHold]          BIT             CONSTRAINT [DF__Vendor__IsVendor__1790AA01] DEFAULT ((0)) NULL,
    [TaxIdNumber]             NVARCHAR (MAX)  NULL,
    [QuickBooksReferenceId]   VARCHAR (200)   NULL,
    [IsUpdated]               BIT             NULL,
    [LastSyncDate]            DATETIME2 (7)   NULL,
    [SyncToken]               VARCHAR (200)   NULL,
    [IsWarningRestriction]    INT             NULL,
    CONSTRAINT [PK_Vendor] PRIMARY KEY CLUSTERED ([VendorId] ASC),
    CONSTRAINT [FK_Vendor_Address] FOREIGN KEY ([AddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_Vendor_CreditTerms] FOREIGN KEY ([CreditTermsId]) REFERENCES [dbo].[CreditTerms] ([CreditTermsId]),
    CONSTRAINT [FK_Vendor_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_Vendor_Customer] FOREIGN KEY ([RelatedCustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_Vendor_Discount] FOREIGN KEY ([DiscountId]) REFERENCES [dbo].[Discount] ([DiscountId]),
    CONSTRAINT [FK_Vendor_ManagementStructure] FOREIGN KEY ([ManagementStructureId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [FK_Vendor_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_Vendor_Vendor] FOREIGN KEY ([VendorParentId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_Vendor_VendorType] FOREIGN KEY ([VendorTypeId]) REFERENCES [dbo].[VendorType] ([VendorTypeId]),
    CONSTRAINT [Unique_VendorCode] UNIQUE NONCLUSTERED ([VendorCode] ASC, [MasterCompanyId] ASC)
);




GO
  
     CREATE     TRIGGER [dbo].[trg_Audit_dbo_Vendor]
        ON [dbo].[Vendor]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[VendorId],d.[VendorTypeId],d.[VendorName],d.[VendorCode],d.[DoingBusinessAsName],d.[IsParent],d.[VendorParentId],d.[VendorPhone],d.[VendorPhoneExt],d.[VendorEmail],d.[AddressId],d.[IsAddressForBilling],d.[IsAddressForShipping],d.[IsVendorAlsoCustomer],d.[RelatedCustomerId],d.[IsAllowNettingAPAR],d.[VendorContractReference],d.[IsPreferredVendor],d.[LicenseNumber],d.[VendorURL],d.[IsCertified],d.[VendorAudit],d.[EDI],d.[EDIDescription],d.[AeroExchange],d.[AeroExchangeDescription],d.[CreditLimit],d.[CreditTermsId],d.[CurrencyId],d.[DiscountId],d.[Is1099Required],d.[IsAllow],d.[IsWarning],d.[IsRestrict],d.[ManagementStructureId],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[BillingAddressId],d.[ShippingAddressId],d.[IsTradeRestricted],d.[TradeRestrictedMemo],d.[IsTrackScoreCard],d.[IsVendorOnHold],d.[TaxIdNumber],d.[QuickBooksReferenceId],d.[IsUpdated],d.[LastSyncDate],d.[SyncToken],d.[IsWarningRestriction] FROM deleted d),
            i AS (SELECT i.[VendorId],i.[VendorTypeId],i.[VendorName],i.[VendorCode],i.[DoingBusinessAsName],i.[IsParent],i.[VendorParentId],i.[VendorPhone],i.[VendorPhoneExt],i.[VendorEmail],i.[AddressId],i.[IsAddressForBilling],i.[IsAddressForShipping],i.[IsVendorAlsoCustomer],i.[RelatedCustomerId],i.[IsAllowNettingAPAR],i.[VendorContractReference],i.[IsPreferredVendor],i.[LicenseNumber],i.[VendorURL],i.[IsCertified],i.[VendorAudit],i.[EDI],i.[EDIDescription],i.[AeroExchange],i.[AeroExchangeDescription],i.[CreditLimit],i.[CreditTermsId],i.[CurrencyId],i.[DiscountId],i.[Is1099Required],i.[IsAllow],i.[IsWarning],i.[IsRestrict],i.[ManagementStructureId],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[BillingAddressId],i.[ShippingAddressId],i.[IsTradeRestricted],i.[TradeRestrictedMemo],i.[IsTrackScoreCard],i.[IsVendorOnHold],i.[TaxIdNumber],i.[QuickBooksReferenceId],i.[IsUpdated],i.[LastSyncDate],i.[SyncToken],i.[IsWarningRestriction] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.VendorId, d.VendorId ) AS VendorId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.VendorId IS NOT NULL AND d.VendorId IS NOT NULL THEN 'U'
                        WHEN i.VendorId IS NOT NULL AND d.VendorId IS NULL     THEN 'I'
                        WHEN i.VendorId IS NULL     AND d.VendorId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.VendorId, d.VendorId) AS VendorId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.VendorId = d.VendorId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.VendorId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'Vendor'
                      AND ign.ColumnName = N'VendorId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.VendorId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'Vendor'
                      AND ign.ColumnName = N'VendorId'
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
                    ON o.VendorId = p.VendorId
                LEFT JOIN newv n
                    ON n.VendorId = p.VendorId
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
                    ON n.VendorId = p.VendorId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.VendorId = p.VendorId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'Vendor' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
                CASE             
                    WHEN m.ColumnName = 'VendorTypeId'   THEN VTOld.Description
                ELSE m.OldValue
                END AS OldValue,        
                CASE 
                    WHEN m.ColumnName = 'VendorTypeId' THEN VTNew.Description
                    ELSE m.NewValue
                END AS NewValue
            FROM merged m
            LEFT JOIN DBO.VendorType VTOld WITH (NOLOCK) ON m.ColumnName = 'VendorTypeId' AND TRY_CAST(m.OldValue AS bigint) = VTOld.VendorTypeId
            LEFT JOIN DBO.VendorType VTNew WITH (NOLOCK) ON m.ColumnName = 'VendorTypeId' AND TRY_CAST(m.NewValue AS bigint) = VTNew.VendorTypeId
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
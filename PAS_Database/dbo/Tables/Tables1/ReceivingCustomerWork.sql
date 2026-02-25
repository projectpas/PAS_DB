CREATE TABLE [dbo].[ReceivingCustomerWork] (
    [ReceivingCustomerWorkId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [EmployeeId]              BIGINT          NOT NULL,
    [CustomerId]              BIGINT          NOT NULL,
    [ReceivingNumber]         VARCHAR (50)    NOT NULL,
    [CustomerContactId]       BIGINT          NOT NULL,
    [ItemMasterId]            BIGINT          NOT NULL,
    [RevisePartId]            BIGINT          NULL,
    [IsSerialized]            BIT             CONSTRAINT [DF_ReceivingCustomerWork_IsSerialized] DEFAULT ((0)) NULL,
    [SerialNumber]            VARCHAR (100)   NULL,
    [Quantity]                DECIMAL (18, 6) NULL,
    [ConditionId]             BIGINT          NOT NULL,
    [SiteId]                  BIGINT          NOT NULL,
    [WarehouseId]             BIGINT          NULL,
    [LocationId]              BIGINT          NULL,
    [Shelfid]                 BIGINT          NULL,
    [BinId]                   BIGINT          NULL,
    [OwnerTypeId]             INT             NULL,
    [Owner]                   BIGINT          NULL,
    [IsCustomerStock]         BIT             CONSTRAINT [DF_ReceivingCustomerWork_IsCustomerStock] DEFAULT ((1)) NOT NULL,
    [TraceableToTypeId]       INT             NULL,
    [TraceableTo]             BIGINT          NULL,
    [ObtainFromTypeId]        INT             NULL,
    [ObtainFrom]              BIGINT          NULL,
    [IsMFGDate]               BIT             CONSTRAINT [DF_ReceivingCustomerWork_IsMFGDate] DEFAULT ((0)) NULL,
    [MFGDate]                 DATETIME2 (7)   NULL,
    [MFGTrace]                VARCHAR (100)   NULL,
    [MFGLotNo]                VARCHAR (100)   NULL,
    [IsExpDate]               BIT             CONSTRAINT [DF_ReceivingCustomerWork_IsExpDate] DEFAULT ((0)) NULL,
    [ExpDate]                 DATETIME2 (7)   NULL,
    [IsTimeLife]              BIT             CONSTRAINT [DF_ReceivingCustomerWork_IsTimeLife] DEFAULT ((0)) NULL,
    [TagDate]                 DATETIME2 (7)   NULL,
    [TagType]                 VARCHAR (8000)  NULL,
    [TagTypeIds]              BIGINT          NULL,
    [TimeLifeDate]            DATETIME2 (7)   NULL,
    [TimeLifeOrigin]          VARCHAR (MAX)   NULL,
    [TimeLifeCyclesId]        BIGINT          NULL,
    [Memo]                    NVARCHAR (MAX)  NULL,
    [PartCertificationNumber] VARCHAR (30)    NULL,
    [ManagementStructureId]   BIGINT          NOT NULL,
    [StockLineId]             BIGINT          NULL,
    [WorkOrderId]             BIGINT          NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_ReceivingCustomerWork_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [DF_ReceivingCustomerWork_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT             CONSTRAINT [DF_ReceivingCustomerWork_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT             CONSTRAINT [DF__Receiving__IsDel__0AB43B22] DEFAULT ((0)) NOT NULL,
    [IsSkipSerialNo]          BIT             CONSTRAINT [DF_ReceivingCustomerWork_IsSkipSerialNo] DEFAULT ((0)) NULL,
    [IsSkipTimeLife]          BIT             CONSTRAINT [DF_ReceivingCustomerWork_IsSkipTimeLife] DEFAULT ((0)) NULL,
    [Reference]               VARCHAR (256)   NOT NULL,
    [CertifiedBy]             VARCHAR (256)   NULL,
    [ReceivedDate]            DATETIME2 (7)   CONSTRAINT [DF__Receiving__Recei__5B7A294C] DEFAULT (getdate()) NOT NULL,
    [CustReqDate]             DATETIME2 (7)   CONSTRAINT [DF__Receiving__CustR__055B547F] DEFAULT (getdate()) NOT NULL,
    [Level1]                  VARCHAR (200)   NULL,
    [Level2]                  VARCHAR (200)   NULL,
    [Level3]                  VARCHAR (200)   NULL,
    [Level4]                  VARCHAR (200)   NULL,
    [EmployeeName]            VARCHAR (256)   NULL,
    [CustomerName]            VARCHAR (256)   NULL,
    [WorkScopeId]             BIGINT          NULL,
    [CustomerCode]            VARCHAR (100)   NULL,
    [ManufacturerName]        VARCHAR (100)   NULL,
    [InspectedById]           BIGINT          NULL,
    [CertifiedDate]           DATETIME2 (7)   NULL,
    [ObtainFromName]          VARCHAR (256)   NULL,
    [OwnerName]               VARCHAR (256)   NULL,
    [TraceableToName]         VARCHAR (256)   NULL,
    [PartNumber]              VARCHAR (250)   NULL,
    [WorkScope]               VARCHAR (250)   NULL,
    [Condition]               VARCHAR (100)   NULL,
    [Site]                    VARCHAR (250)   NULL,
    [Warehouse]               VARCHAR (250)   NULL,
    [Location]                VARCHAR (250)   NULL,
    [Shelf]                   VARCHAR (250)   NULL,
    [Bin]                     VARCHAR (250)   NULL,
    [InspectedBy]             VARCHAR (100)   NULL,
    [InspectedDate]           DATETIME        NULL,
    [TaggedById]              BIGINT          NULL,
    [TaggedBy]                VARCHAR (100)   NULL,
    [ACTailNum]               NVARCHAR (500)  NULL,
    [TaggedByType]            INT             NULL,
    [TaggedByTypeName]        VARCHAR (250)   NULL,
    [CertifiedById]           BIGINT          NULL,
    [CertifiedTypeId]         INT             NULL,
    [CertifiedType]           VARCHAR (250)   NULL,
    [CertTypeId]              VARCHAR (MAX)   NULL,
    [CertType]                VARCHAR (MAX)   NULL,
    [RemovalReasonId]         BIGINT          NULL,
    [RemovalReasons]          VARCHAR (200)   NULL,
    [RemovalReasonsMemo]      NVARCHAR (MAX)  NULL,
    [ExchangeSalesOrderId]    BIGINT          NULL,
    [CustReqTagTypeId]        BIGINT          NULL,
    [CustReqTagType]          VARCHAR (100)   NULL,
    [CustReqCertTypeId]       VARCHAR (MAX)   NULL,
    [CustReqCertType]         VARCHAR (MAX)   NULL,
    [RepairOrderPartRecordId] BIGINT          NULL,
    [IsExchangeBatchEntry]    BIT             NULL,
    [IsPiecePart]             BIT             CONSTRAINT [DF_ReceivingCustomerWork_IsPiecePart1] DEFAULT ((0)) NULL,
    [IsRepairManagement]      BIT             CONSTRAINT [Cnt_ReceivingCustomerWork_IsPiecePart] DEFAULT ((0)) NULL,
    [IsSkipShippingReference] BIT             NULL,
    [CSN]                     VARCHAR (50)    NULL,
    [TSN]                     VARCHAR (50)    NULL,
    [CSO]                     VARCHAR (50)    NULL,
    [TSO]                     VARCHAR (50)    NULL,
    CONSTRAINT [PK_ReceivingCustomerWork] PRIMARY KEY CLUSTERED ([ReceivingCustomerWorkId] ASC),
    CONSTRAINT [FK_ReceivingCustomerWork_Bin] FOREIGN KEY ([BinId]) REFERENCES [dbo].[Bin] ([BinId]),
    CONSTRAINT [FK_ReceivingCustomerWork_ConditionId] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_ReceivingCustomerWork_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_ReceivingCustomerWork_CustomerContact] FOREIGN KEY ([CustomerContactId]) REFERENCES [dbo].[CustomerContact] ([CustomerContactId]),
    CONSTRAINT [FK_ReceivingCustomerWork_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_ReceivingCustomerWork_InspectedById] FOREIGN KEY ([InspectedById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_ReceivingCustomerWork_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_ReceivingCustomerWork_Location] FOREIGN KEY ([LocationId]) REFERENCES [dbo].[Location] ([LocationId]),
    CONSTRAINT [FK_ReceivingCustomerWork_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ReceivingCustomerWork_OwnerType] FOREIGN KEY ([OwnerTypeId]) REFERENCES [dbo].[Module] ([ModuleId]),
    CONSTRAINT [FK_ReceivingCustomerWork_Shelf] FOREIGN KEY ([Shelfid]) REFERENCES [dbo].[Shelf] ([ShelfId]),
    CONSTRAINT [FK_ReceivingCustomerWork_Site] FOREIGN KEY ([SiteId]) REFERENCES [dbo].[Site] ([SiteId]),
    CONSTRAINT [FK_ReceivingCustomerWork_StockLine] FOREIGN KEY ([StockLineId]) REFERENCES [dbo].[Stockline] ([StockLineId]),
    CONSTRAINT [FK_ReceivingCustomerWork_TraceableToType] FOREIGN KEY ([TraceableToTypeId]) REFERENCES [dbo].[Module] ([ModuleId]),
    CONSTRAINT [FK_ReceivingCustomerWork_Warehouse] FOREIGN KEY ([WarehouseId]) REFERENCES [dbo].[Warehouse] ([WarehouseId]),
    CONSTRAINT [FK_ReceivingCustomerWork_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId]),
    CONSTRAINT [FK_ReceivingCustomerWork_WorkScopeId] FOREIGN KEY ([WorkScopeId]) REFERENCES [dbo].[WorkScope] ([WorkScopeId])
);


















GO
CREATE   TRIGGER [dbo].[trg_Audit_dbo_ReceivingCustomerWork]
ON [dbo].[ReceivingCustomerWork]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH
    d AS (SELECT d.[ReceivingCustomerWorkId],d.[EmployeeId],d.[CustomerId],d.[ReceivingNumber],d.[CustomerContactId],d.[ItemMasterId],d.[RevisePartId],d.[IsSerialized],d.[SerialNumber],d.[Quantity],d.[ConditionId],d.[SiteId],d.[WarehouseId],d.[LocationId],d.[Shelfid],d.[BinId],d.[OwnerTypeId],d.[Owner],d.[IsCustomerStock],d.[TraceableToTypeId],d.[TraceableTo],d.[ObtainFromTypeId],d.[ObtainFrom],d.[IsMFGDate],d.[MFGDate],d.[MFGTrace],d.[MFGLotNo],d.[IsExpDate],d.[ExpDate],d.[IsTimeLife],d.[TagDate],d.[TagType],d.[TagTypeIds],d.[TimeLifeDate],d.[TimeLifeOrigin],d.[TimeLifeCyclesId],d.[Memo],d.[PartCertificationNumber],d.[ManagementStructureId],d.[StockLineId],d.[WorkOrderId],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[IsSkipSerialNo],d.[IsSkipTimeLife],d.[Reference],d.[CertifiedBy],d.[ReceivedDate],d.[CustReqDate],d.[Level1],d.[Level2],d.[Level3],d.[Level4],d.[EmployeeName],d.[CustomerName],d.[WorkScopeId],d.[CustomerCode],d.[ManufacturerName],d.[InspectedById],d.[CertifiedDate],d.[ObtainFromName],d.[OwnerName],d.[TraceableToName],d.[PartNumber],d.[WorkScope],d.[Condition],d.[Site],d.[Warehouse],d.[Location],d.[Shelf],d.[Bin],d.[InspectedBy],d.[InspectedDate],d.[TaggedById],d.[TaggedBy],d.[ACTailNum],d.[TaggedByType],d.[TaggedByTypeName],d.[CertifiedById],d.[CertifiedTypeId],d.[CertifiedType],d.[CertTypeId],d.[CertType],d.[RemovalReasonId],d.[RemovalReasons],d.[RemovalReasonsMemo],d.[ExchangeSalesOrderId],d.[CustReqTagTypeId],d.[CustReqTagType],d.[CustReqCertTypeId],d.[CustReqCertType],d.[RepairOrderPartRecordId],d.[IsExchangeBatchEntry],d.[IsPiecePart],d.[IsRepairManagement],d.[IsSkipShippingReference],d.[CSN],d.[TSN],d.[CSO],d.[TSO] FROM deleted d),
    i AS (SELECT i.[ReceivingCustomerWorkId],i.[EmployeeId],i.[CustomerId],i.[ReceivingNumber],i.[CustomerContactId],i.[ItemMasterId],i.[RevisePartId],i.[IsSerialized],i.[SerialNumber],i.[Quantity],i.[ConditionId],i.[SiteId],i.[WarehouseId],i.[LocationId],i.[Shelfid],i.[BinId],i.[OwnerTypeId],i.[Owner],i.[IsCustomerStock],i.[TraceableToTypeId],i.[TraceableTo],i.[ObtainFromTypeId],i.[ObtainFrom],i.[IsMFGDate],i.[MFGDate],i.[MFGTrace],i.[MFGLotNo],i.[IsExpDate],i.[ExpDate],i.[IsTimeLife],i.[TagDate],i.[TagType],i.[TagTypeIds],i.[TimeLifeDate],i.[TimeLifeOrigin],i.[TimeLifeCyclesId],i.[Memo],i.[PartCertificationNumber],i.[ManagementStructureId],i.[StockLineId],i.[WorkOrderId],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[IsSkipSerialNo],i.[IsSkipTimeLife],i.[Reference],i.[CertifiedBy],i.[ReceivedDate],i.[CustReqDate],i.[Level1],i.[Level2],i.[Level3],i.[Level4],i.[EmployeeName],i.[CustomerName],i.[WorkScopeId],i.[CustomerCode],i.[ManufacturerName],i.[InspectedById],i.[CertifiedDate],i.[ObtainFromName],i.[OwnerName],i.[TraceableToName],i.[PartNumber],i.[WorkScope],i.[Condition],i.[Site],i.[Warehouse],i.[Location],i.[Shelf],i.[Bin],i.[InspectedBy],i.[InspectedDate],i.[TaggedById],i.[TaggedBy],i.[ACTailNum],i.[TaggedByType],i.[TaggedByTypeName],i.[CertifiedById],i.[CertifiedTypeId],i.[CertifiedType],i.[CertTypeId],i.[CertType],i.[RemovalReasonId],i.[RemovalReasons],i.[RemovalReasonsMemo],i.[ExchangeSalesOrderId],i.[CustReqTagTypeId],i.[CustReqTagType],i.[CustReqCertTypeId],i.[CustReqCertType],i.[RepairOrderPartRecordId],i.[IsExchangeBatchEntry],i.[IsPiecePart],i.[IsRepairManagement],i.[IsSkipShippingReference],i.[CSN],i.[TSN],i.[CSO],i.[TSO] FROM inserted i),
    paired AS (
        SELECT
            COALESCE(i.ReceivingCustomerWorkId, d.ReceivingCustomerWorkId ) AS ReceivingCustomerWorkId,
            (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
            (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
            CASE
                WHEN i.ReceivingCustomerWorkId IS NOT NULL AND d.ReceivingCustomerWorkId IS NOT NULL THEN 'U'
                WHEN i.ReceivingCustomerWorkId IS NOT NULL AND d.ReceivingCustomerWorkId IS NULL     THEN 'I'
                WHEN i.ReceivingCustomerWorkId IS NULL     AND d.ReceivingCustomerWorkId IS NOT NULL THEN 'D'
            END AS Action,

            (SELECT COALESCE(i.ReceivingCustomerWorkId, d.ReceivingCustomerWorkId) AS ReceivingCustomerWorkId
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
        FROM d
        FULL OUTER JOIN i
            ON i.ReceivingCustomerWorkId = d.ReceivingCustomerWorkId
    ),

    oldv AS (
        SELECT
            p.PKJson,
            p.ReceivingCustomerWorkId,
            v.[key]  AS ColumnName,
            v.value  AS OldValue
        FROM paired p
        CROSS APPLY OPENJSON(p.old_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'ReceivingCustomerWork'
                AND ign.ColumnName = N'ReceivingCustomerWorkId'
        )),
    newv AS (
        SELECT
            p.PKJson,
            p.ReceivingCustomerWorkId ,
            v.[key]  AS ColumnName,
            v.value  AS NewValue
        FROM paired p
        CROSS APPLY OPENJSON(p.new_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'ReceivingCustomerWork'
                AND ign.ColumnName = N'ReceivingCustomerWorkId'
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
            ON o.ReceivingCustomerWorkId = p.ReceivingCustomerWorkId
        LEFT JOIN newv n
            ON n.ReceivingCustomerWorkId = p.ReceivingCustomerWorkId
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
            ON n.ReceivingCustomerWorkId = p.ReceivingCustomerWorkId
        WHERE NOT EXISTS (
            SELECT 1
            FROM oldv o2
            WHERE o2.ReceivingCustomerWorkId = p.ReceivingCustomerWorkId
                AND o2.ColumnName    = n.ColumnName
        )
    )
    INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
    SELECT
        N'dbo' AS SchemaName,
        N'ReceivingCustomerWork' AS TableName,
        m.PKJson,
        m.ColumnName,
        m.Action,        
        CASE             
            WHEN m.ColumnName = 'RevisePartId' THEN rpOld.PartNumber
            WHEN m.ColumnName = 'CustomerContactId' THEN LTRIM(RTRIM(ISNULL(cOld.FirstName,'') + ' ' + ISNULL(cOld.LastName,''))) 
            WHEN m.ColumnName IN ('IsCustomerStock', 'IsPiecePart', 'IsRepairManagement') THEN
                CASE 
                    WHEN m.ColumnName = 'IsCustomerStock' AND m.OldValue = 'true' THEN 'Customer Repair'
                    WHEN m.ColumnName = 'IsPiecePart' AND m.OldValue = 'true' THEN 'Customer Supplied Materials'
                    WHEN m.ColumnName = 'IsRepairManagement' AND m.OldValue = 'true' THEN 'Manage Repair'
                    ELSE NULL
                END
            WHEN m.ColumnName = 'WorkOrderId' THEN woOld.WorkOrderNum
            ELSE m.OldValue
        END AS OldValue,        
        CASE            
            WHEN m.ColumnName = 'RevisePartId' THEN rpNew.PartNumber
            WHEN m.ColumnName = 'CustomerContactId' THEN LTRIM(RTRIM(ISNULL(cNew.FirstName,'') + ' ' + ISNULL(cNew.LastName,''))) 
            WHEN m.ColumnName IN ('IsCustomerStock', 'IsPiecePart', 'IsRepairManagement') THEN
                CASE 
                    WHEN m.ColumnName = 'IsCustomerStock' AND m.NewValue = 'true' THEN 'Customer Repair'
                    WHEN m.ColumnName = 'IsPiecePart' AND m.NewValue = 'true' THEN 'Customer Supplied Materials'
                    WHEN m.ColumnName = 'IsRepairManagement' AND m.NewValue = 'true' THEN 'Manage Repair'
                    ELSE NULL
                END
            WHEN m.ColumnName = 'WorkOrderId' THEN woNew.WorkOrderNum
            ELSE m.NewValue
        END AS NewValue
    FROM merged m    
    LEFT JOIN dbo.ItemMaster rpOld WITH(NOLOCK) ON m.ColumnName = 'RevisePartId' AND TRY_CAST(m.OldValue AS BIGINT) = rpOld.ItemMasterId 
    LEFT JOIN dbo.ItemMaster rpNew WITH(NOLOCK) ON m.ColumnName = 'RevisePartId' AND TRY_CAST(m.NewValue AS BIGINT) = rpNew.ItemMasterId
    LEFT JOIN dbo.WorkOrder woOld WITH(NOLOCK) ON m.ColumnName = 'WorkOrderId' AND TRY_CAST(m.OldValue AS BIGINT) = woOld.WorkOrderId 
    LEFT JOIN dbo.WorkOrder woNew WITH(NOLOCK) ON m.ColumnName = 'WorkOrderId' AND TRY_CAST(m.NewValue AS BIGINT) = woNew.WorkOrderId
    LEFT JOIN dbo.CustomerContact ccOld WITH(NOLOCK) ON m.ColumnName = 'CustomerContactId' AND TRY_CAST(m.OldValue AS INT) = ccOld.CustomerContactId
    LEFT JOIN dbo.Contact cOld WITH(NOLOCK) ON ccOld.ContactId = cOld.ContactId
    LEFT JOIN dbo.CustomerContact ccNew WITH(NOLOCK) ON m.ColumnName = 'CustomerContactId' AND TRY_CAST(m.NewValue AS INT) = ccNew.CustomerContactId
    LEFT JOIN dbo.Contact cNew WITH(NOLOCK) ON ccNew.ContactId = cNew.ContactId
    WHERE 
        m.ColumnName <> 'ReceivingCustomerWorkId' and (
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
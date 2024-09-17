CREATE TABLE [dbo].[ReceivingCustomerWork] (
    [ReceivingCustomerWorkId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [EmployeeId]              BIGINT         NOT NULL,
    [CustomerId]              BIGINT         NOT NULL,
    [ReceivingNumber]         VARCHAR (50)   NOT NULL,
    [CustomerContactId]       BIGINT         NOT NULL,
    [ItemMasterId]            BIGINT         NOT NULL,
    [RevisePartId]            BIGINT         NULL,
    [IsSerialized]            BIT            CONSTRAINT [DF_ReceivingCustomerWork_IsSerialized] DEFAULT ((0)) NULL,
    [SerialNumber]            VARCHAR (100)  NULL,
    [Quantity]                INT            NOT NULL,
    [ConditionId]             BIGINT         NOT NULL,
    [SiteId]                  BIGINT         NOT NULL,
    [WarehouseId]             BIGINT         NULL,
    [LocationId]              BIGINT         NULL,
    [Shelfid]                 BIGINT         NULL,
    [BinId]                   BIGINT         NULL,
    [OwnerTypeId]             INT            NULL,
    [Owner]                   BIGINT         NULL,
    [IsCustomerStock]         BIT            CONSTRAINT [DF_ReceivingCustomerWork_IsCustomerStock] DEFAULT ((1)) NOT NULL,
    [TraceableToTypeId]       INT            NULL,
    [TraceableTo]             BIGINT         NULL,
    [ObtainFromTypeId]        INT            NULL,
    [ObtainFrom]              BIGINT         NULL,
    [IsMFGDate]               BIT            CONSTRAINT [DF_ReceivingCustomerWork_IsMFGDate] DEFAULT ((0)) NULL,
    [MFGDate]                 DATETIME2 (7)  NULL,
    [MFGTrace]                VARCHAR (100)  NULL,
    [MFGLotNo]                VARCHAR (100)  NULL,
    [IsExpDate]               BIT            CONSTRAINT [DF_ReceivingCustomerWork_IsExpDate] DEFAULT ((0)) NULL,
    [ExpDate]                 DATETIME2 (7)  NULL,
    [IsTimeLife]              BIT            CONSTRAINT [DF_ReceivingCustomerWork_IsTimeLife] DEFAULT ((0)) NULL,
    [TagDate]                 DATETIME2 (7)  NULL,
    [TagType]                 VARCHAR (8000) NULL,
    [TagTypeIds]              BIGINT         NULL,
    [TimeLifeDate]            DATETIME2 (7)  NULL,
    [TimeLifeOrigin]          VARCHAR (MAX)  NULL,
    [TimeLifeCyclesId]        BIGINT         NULL,
    [Memo]                    NVARCHAR (MAX) NULL,
    [PartCertificationNumber] VARCHAR (30)   NULL,
    [ManagementStructureId]   BIGINT         NOT NULL,
    [StockLineId]             BIGINT         NULL,
    [WorkOrderId]             BIGINT         NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [CreatedBy]               VARCHAR (256)  NOT NULL,
    [UpdatedBy]               VARCHAR (256)  NOT NULL,
    [CreatedDate]             DATETIME2 (7)  CONSTRAINT [DF_ReceivingCustomerWork_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  CONSTRAINT [DF_ReceivingCustomerWork_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT            CONSTRAINT [DF_ReceivingCustomerWork_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT            CONSTRAINT [DF__Receiving__IsDel__0AB43B22] DEFAULT ((0)) NOT NULL,
    [IsSkipSerialNo]          BIT            CONSTRAINT [DF_ReceivingCustomerWork_IsSkipSerialNo] DEFAULT ((0)) NULL,
    [IsSkipTimeLife]          BIT            CONSTRAINT [DF_ReceivingCustomerWork_IsSkipTimeLife] DEFAULT ((0)) NULL,
    [Reference]               VARCHAR (256)  NOT NULL,
    [CertifiedBy]             VARCHAR (256)  NULL,
    [ReceivedDate]            DATETIME2 (7)  CONSTRAINT [DF__Receiving__Recei__5B7A294C] DEFAULT (getdate()) NOT NULL,
    [CustReqDate]             DATETIME2 (7)  CONSTRAINT [DF__Receiving__CustR__055B547F] DEFAULT (getdate()) NOT NULL,
    [Level1]                  VARCHAR (200)  NULL,
    [Level2]                  VARCHAR (200)  NULL,
    [Level3]                  VARCHAR (200)  NULL,
    [Level4]                  VARCHAR (200)  NULL,
    [EmployeeName]            VARCHAR (256)  NULL,
    [CustomerName]            VARCHAR (256)  NULL,
    [WorkScopeId]             BIGINT         NULL,
    [CustomerCode]            VARCHAR (100)  NULL,
    [ManufacturerName]        VARCHAR (100)  NULL,
    [InspectedById]           BIGINT         NULL,
    [CertifiedDate]           DATETIME2 (7)  NULL,
    [ObtainFromName]          VARCHAR (256)  NULL,
    [OwnerName]               VARCHAR (256)  NULL,
    [TraceableToName]         VARCHAR (256)  NULL,
    [PartNumber]              VARCHAR (250)  NULL,
    [WorkScope]               VARCHAR (250)  NULL,
    [Condition]               VARCHAR (100)  NULL,
    [Site]                    VARCHAR (250)  NULL,
    [Warehouse]               VARCHAR (250)  NULL,
    [Location]                VARCHAR (250)  NULL,
    [Shelf]                   VARCHAR (250)  NULL,
    [Bin]                     VARCHAR (250)  NULL,
    [InspectedBy]             VARCHAR (100)  NULL,
    [InspectedDate]           DATETIME       NULL,
    [TaggedById]              BIGINT         NULL,
    [TaggedBy]                VARCHAR (100)  NULL,
    [ACTailNum]               NVARCHAR (500) NULL,
    [TaggedByType]            INT            NULL,
    [TaggedByTypeName]        VARCHAR (250)  NULL,
    [CertifiedById]           BIGINT         NULL,
    [CertifiedTypeId]         INT            NULL,
    [CertifiedType]           VARCHAR (250)  NULL,
    [CertTypeId]              VARCHAR (MAX)  NULL,
    [CertType]                VARCHAR (MAX)  NULL,
    [RemovalReasonId]         BIGINT         NULL,
    [RemovalReasons]          VARCHAR (200)  NULL,
    [RemovalReasonsMemo]      NVARCHAR (MAX) NULL,
    [ExchangeSalesOrderId]    BIGINT         NULL,
    [CustReqTagTypeId]        BIGINT         NULL,
    [CustReqTagType]          VARCHAR (100)  NULL,
    [CustReqCertTypeId]       VARCHAR (MAX)  NULL,
    [CustReqCertType]         VARCHAR (MAX)  NULL,
    [RepairOrderPartRecordId] BIGINT         NULL,
    [IsExchangeBatchEntry]    BIT            NULL,
    [IsPiecePart]             BIT            CONSTRAINT [Cnt_ReceivingCustomerWork_IsPiecePart] DEFAULT ((0)) NULL,
    [IsSkipShippingReference] BIT            NULL,
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


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_ReceivingCustomerWorkAudit]

   ON  [dbo].[ReceivingCustomerWork]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[ReceivingCustomerWorkAudit] 

    SELECT *

	FROM INSERTED 

	SET NOCOUNT ON;



END
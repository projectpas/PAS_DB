CREATE TABLE [dbo].[Lot] (
    [LotId]                 BIGINT          IDENTITY (1, 1) NOT NULL,
    [LotNumber]             VARCHAR (200)   NOT NULL,
    [LotName]               VARCHAR (50)    NOT NULL,
    [VendorId]              BIGINT          NOT NULL,
    [ReferenceNumber]       VARCHAR (50)    NULL,
    [OpenDate]              DATETIME2 (7)   NOT NULL,
    [OriginalCost]          DECIMAL (18, 2) NULL,
    [LotStatusId]           INT             NULL,
    [ObtainFromTypeId]      INT             NULL,
    [ObtainFromId]          BIGINT          NULL,
    [TraceableToTypeId]     INT             NULL,
    [TraceableToId]         BIGINT          NULL,
    [ConsignmentId]         BIGINT          NULL,
    [EmployeeId]            BIGINT          NOT NULL,
    [ManagementStructureId] BIGINT          NOT NULL,
    [LegalEntityId]         BIGINT          NULL,
    [MasterCompanyId]       INT             CONSTRAINT [DF_Lot_MasterCompanyId] DEFAULT ((1)) NOT NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NOT NULL,
    [CreatedDate]           DATETIME2 (7)   NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   NULL,
    [IsActive]              BIT             CONSTRAINT [DF_Lot_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT             CONSTRAINT [DF_Lot_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsInitialPO]           BIT             NULL,
    [InitialPOId]           BIGINT          NULL,
    [InitialPOCost]         DECIMAL (18, 2) NULL,
    [StocklineTotalCost]    DECIMAL (18, 2) NULL,
    CONSTRAINT [PK_Lot] PRIMARY KEY CLUSTERED ([LotId] ASC),
    CONSTRAINT [FK_Lot_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId])
);




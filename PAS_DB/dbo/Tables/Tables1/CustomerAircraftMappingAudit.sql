CREATE TABLE [dbo].[CustomerAircraftMappingAudit] (
    [AuditCustomerAircraftMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerAircraftMappingId]      BIGINT        NOT NULL,
    [CustomerId]                     BIGINT        NOT NULL,
    [AircraftTypeId]                 INT           NOT NULL,
    [AircraftModelId]                BIGINT        NULL,
    [DashNumberId]                   BIGINT        NULL,
    [AircraftType]                   VARCHAR (250) NOT NULL,
    [AircraftModel]                  VARCHAR (250) NOT NULL,
    [DashNumber]                     VARCHAR (250) NOT NULL,
    [Inventory]                      INT           NOT NULL,
    [MasterCompanyId]                INT           NOT NULL,
    [CreatedBy]                      VARCHAR (256) NOT NULL,
    [UpdatedBy]                      VARCHAR (256) NOT NULL,
    [CreatedDate]                    DATETIME2 (7) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7) NOT NULL,
    [IsActive]                       BIT           CONSTRAINT [D_CAMA_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                      BIT           CONSTRAINT [CustomerAircraftMappingAudit_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AuditCACMapping] PRIMARY KEY CLUSTERED ([AuditCustomerAircraftMappingId] ASC),
    CONSTRAINT [FK_CustomerAircraftMappingAudit_CustomerAircraftMapping] FOREIGN KEY ([CustomerAircraftMappingId]) REFERENCES [dbo].[CustomerAircraftMapping] ([CustomerAircraftMappingId])
);


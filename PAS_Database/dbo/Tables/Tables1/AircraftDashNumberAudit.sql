CREATE TABLE [dbo].[AircraftDashNumberAudit] (
    [DashNumberAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [DashNumberId]      BIGINT         NOT NULL,
    [AircraftTypeId]    INT            NOT NULL,
    [AircraftModelId]   BIGINT         NOT NULL,
    [DashNumber]        VARCHAR (250)  NOT NULL,
    [Memo]              NVARCHAR (MAX) NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  NOT NULL,
    [IsActive]          BIT            NOT NULL,
    [IsDeleted]         BIT            NOT NULL,
    [AircraftType]      VARCHAR (256)  NULL,
    [AircraftModel]     VARCHAR (256)  NULL,
    CONSTRAINT [PK_AircraftDashNumberAudit] PRIMARY KEY CLUSTERED ([DashNumberAuditId] ASC),
    CONSTRAINT [FK_AircraftDashNumberAudit_AircraftDashNumberAudit] FOREIGN KEY ([DashNumberAuditId]) REFERENCES [dbo].[AircraftDashNumberAudit] ([DashNumberAuditId])
);


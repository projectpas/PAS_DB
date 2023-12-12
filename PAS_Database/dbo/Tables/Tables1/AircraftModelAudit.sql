CREATE TABLE [dbo].[AircraftModelAudit] (
    [AircraftModelAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AircraftModelId]      BIGINT         NOT NULL,
    [AircraftTypeId]       INT            NOT NULL,
    [ModelName]            VARCHAR (50)   NOT NULL,
    [Memo]                 NVARCHAR (MAX) NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [CreatedDate]          DATETIME2 (7)  NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  NOT NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [IsActive]             BIT            NOT NULL,
    [IsDeleted]            BIT            NOT NULL,
    [AircraftType]         VARCHAR (100)  NULL,
    [WingTypeId]           BIGINT         DEFAULT ((0)) NOT NULL,
    [WingType]             VARCHAR (256)  NULL,
    [SequenceNo]           INT            NULL,
    CONSTRAINT [PK_AircraftModelAudit] PRIMARY KEY CLUSTERED ([AircraftModelAuditId] ASC)
);


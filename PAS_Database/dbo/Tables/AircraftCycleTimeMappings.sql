CREATE TABLE [dbo].[AircraftCycleTimeMappings] (
    [AircraftCycleTimeMappingsId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ModuleId]                    BIGINT          NOT NULL,
    [RefrenceId]                  BIGINT          NOT NULL,
    [CycleDate]                   DATETIME2 (7)   NULL,
    [Hours]                       DECIMAL (18, 6) NULL,
    [CurruntHours]                DECIMAL (18, 6) NULL,
    [CumulativeHours]             DECIMAL (18, 6) NULL,
    [Cycles]                      DECIMAL (18, 6) NULL,
    [CurruntCycles]               DECIMAL (18, 6) NULL,
    [CumulativeCycles]            DECIMAL (18, 6) NULL,
    [Memo]                        NVARCHAR (MAX)  NULL,
    [MasterCompanyId]             INT             NOT NULL,
    [CreatedBy]                   VARCHAR (256)   NOT NULL,
    [UpdatedBy]                   VARCHAR (256)   NOT NULL,
    [CreatedDate]                 DATETIME2 (7)   DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)   NOT NULL,
    [IsActive]                    BIT             DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT             DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([AircraftCycleTimeMappingsId] ASC),
    CONSTRAINT [FK_AircraftCycleTimeMappings_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


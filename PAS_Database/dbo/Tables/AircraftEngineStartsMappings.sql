CREATE TABLE [dbo].[AircraftEngineStartsMappings] (
    [AircraftEngineStartsMappingsId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [AircraftCycleTimeMappingsId]    BIGINT          NULL,
    [EngineName]                     VARCHAR (50)    NULL,
    [Hours]                          DECIMAL (18, 6) NULL,
    [CurruntHours]                   DECIMAL (18, 6) NULL,
    [CumulativeHours]                DECIMAL (18, 6) NULL,
    [Starts]                         DECIMAL (18, 6) NULL,
    [CurruntStarts]                  DECIMAL (18, 6) NULL,
    [CumulativeStarts]               DECIMAL (18, 6) NULL,
    [Memo]                           NVARCHAR (MAX)  NULL,
    [MasterCompanyId]                INT             NOT NULL,
    [CreatedBy]                      VARCHAR (256)   NOT NULL,
    [UpdatedBy]                      VARCHAR (256)   NOT NULL,
    [CreatedDate]                    DATETIME2 (7)   DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7)   NOT NULL,
    [IsActive]                       BIT             DEFAULT ((1)) NOT NULL,
    [IsDeleted]                      BIT             DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([AircraftEngineStartsMappingsId] ASC),
    CONSTRAINT [FK_AircraftEngineStartsMappings_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


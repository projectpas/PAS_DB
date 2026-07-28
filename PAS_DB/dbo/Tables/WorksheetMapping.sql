CREATE TABLE [dbo].[WorksheetMapping] (
    [WorksheetMappingId]             BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorksheetHeaderId]              BIGINT        NOT NULL,
    [IsFromAircraft]                 BIT           NOT NULL,
    [RegistryId]                     BIGINT        NULL,
    [ProgramId]                      BIGINT        NULL,
    [AircraftInstalledPartDetailsId] BIGINT        NULL,
    [MasterCompanyId]                INT           NOT NULL,
    [CreatedBy]                      VARCHAR (256) NOT NULL,
    [UpdatedBy]                      VARCHAR (256) NOT NULL,
    [CreatedDate]                    DATETIME2 (7) CONSTRAINT [DF_WorksheetMapping_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7) CONSTRAINT [DF_WorksheetMapping_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                       BIT           CONSTRAINT [WorksheetMapping_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                      BIT           CONSTRAINT [WorksheetMapping_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorksheetMapping] PRIMARY KEY CLUSTERED ([WorksheetMappingId] ASC)
);


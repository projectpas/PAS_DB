CREATE TABLE [dbo].[CountriesAudit] (
    [AuditCountries_id]  SMALLINT       IDENTITY (1, 1) NOT NULL,
    [countries_id]       SMALLINT       NOT NULL,
    [countries_name]     VARCHAR (64)   NOT NULL,
    [nice_name]          VARCHAR (64)   NOT NULL,
    [countries_iso_code] VARCHAR (7)    NOT NULL,
    [countries_iso3]     VARCHAR (10)   NOT NULL,
    [countries_numcode]  VARCHAR (10)   NOT NULL,
    [countries_isd_code] VARCHAR (7)    NOT NULL,
    [CreatedBy]          VARCHAR (256)  NOT NULL,
    [UpdatedBy]          VARCHAR (256)  NOT NULL,
    [CreatedDate]        DATETIME2 (7)  NOT NULL,
    [UpdatedDate]        DATETIME2 (7)  NOT NULL,
    [IsActive]           BIT            NOT NULL,
    [IsDeleted]          BIT            NOT NULL,
    [Description]        VARCHAR (MAX)  NULL,
    [Memo]               NVARCHAR (MAX) NULL,
    [MasterCompanyId]    BIGINT         NULL,
    [SequenceNo]         INT            NULL,
    CONSTRAINT [PK__CountriesAudit] PRIMARY KEY CLUSTERED ([AuditCountries_id] ASC)
);




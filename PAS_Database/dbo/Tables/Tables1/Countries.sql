CREATE TABLE [dbo].[Countries] (
    [countries_id]       SMALLINT       IDENTITY (1, 1) NOT NULL,
    [countries_name]     VARCHAR (64)   NOT NULL,
    [nice_name]          VARCHAR (64)   NOT NULL,
    [countries_iso_code] VARCHAR (7)    NOT NULL,
    [countries_iso3]     VARCHAR (10)   NOT NULL,
    [countries_numcode]  VARCHAR (10)   NOT NULL,
    [countries_isd_code] VARCHAR (7)    NOT NULL,
    [CreatedBy]          VARCHAR (256)  NOT NULL,
    [UpdatedBy]          VARCHAR (256)  NOT NULL,
    [CreatedDate]        DATETIME2 (7)  CONSTRAINT [Countries_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]        DATETIME2 (7)  CONSTRAINT [Countries_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]           BIT            CONSTRAINT [DF_Countries_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT            CONSTRAINT [D_Countries_Delete] DEFAULT ((0)) NOT NULL,
    [Description]        VARCHAR (MAX)  NULL,
    [Memo]               NVARCHAR (MAX) NULL,
    [MasterCompanyId]    BIGINT         NULL,
    [SequenceNo]         INT            NULL,
    CONSTRAINT [PK__Countrie__671B21A98A4E395F] PRIMARY KEY CLUSTERED ([countries_id] ASC),
    CONSTRAINT [Unique_Countries] UNIQUE NONCLUSTERED ([countries_name] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_CountriesAudit]

   ON  [dbo].[Countries]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO CountriesAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END
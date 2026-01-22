CREATE TABLE [dbo].[AddressAudit] (
    [AddressAuditId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [AddressId]       BIGINT          NOT NULL,
    [POBox]           VARCHAR (30)    NULL,
    [Line1]           VARCHAR (50)    NOT NULL,
    [Line2]           VARCHAR (50)    NULL,
    [Line3]           VARCHAR (50)    NULL,
    [City]            VARCHAR (50)    NOT NULL,
    [StateOrProvince] VARCHAR (50)    NOT NULL,
    [PostalCode]      VARCHAR (20)    NOT NULL,
    [CountryId]       SMALLINT        NOT NULL,
    [Latitude]        DECIMAL (12, 9) NULL,
    [Longitude]       DECIMAL (12, 9) NULL,
    [MasterCompanyId] INT             NOT NULL,
    [CreatedBy]       VARCHAR (256)   NOT NULL,
    [UpdatedBy]       VARCHAR (256)   NOT NULL,
    [CreatedDate]     DATETIME2 (7)   NOT NULL,
    [UpdatedDate]     DATETIME2 (7)   NOT NULL,
    [IsActive]        BIT             NOT NULL,
    [IsDeleted]       BIT             NOT NULL,
    CONSTRAINT [PK_AddressAudit] PRIMARY KEY CLUSTERED ([AddressAuditId] ASC)
);


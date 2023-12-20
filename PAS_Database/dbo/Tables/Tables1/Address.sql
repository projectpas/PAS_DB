CREATE TABLE [dbo].[Address] (
    [AddressId]       BIGINT          IDENTITY (1, 1) NOT NULL,
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
    [CreatedDate]     DATETIME2 (7)   CONSTRAINT [DF_Address_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)   CONSTRAINT [DF_Address_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT             CONSTRAINT [DF_Address_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT             CONSTRAINT [DF_Address_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Address] PRIMARY KEY CLUSTERED ([AddressId] ASC),
    CONSTRAINT [FK_Address_Countries] FOREIGN KEY ([CountryId]) REFERENCES [dbo].[Countries] ([countries_id]),
    CONSTRAINT [FK_Address_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_AddressAudit] ON [dbo].[Address]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  

  

 INSERT INTO [dbo].[AddressAudit]  

 SELECT * FROM INSERTED  

  

 SET NOCOUNT ON;  

  

END
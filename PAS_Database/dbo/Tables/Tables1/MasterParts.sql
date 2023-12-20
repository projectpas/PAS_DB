CREATE TABLE [dbo].[MasterParts] (
    [MasterPartId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [PartNumber]      VARCHAR (100)  NULL,
    [Description]     NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_MasterParts_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [CreatedBy]       VARCHAR (256)  NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_MasterParts_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NULL,
    [IsActive]        BIT            CONSTRAINT [DF_MasterParts_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_MasterParts_IsDeleted] DEFAULT ((0)) NULL,
    [ManufacturerId]  BIGINT         NULL,
    [PartType]        VARCHAR (50)   NULL,
    CONSTRAINT [PK_MasterParts] PRIMARY KEY CLUSTERED ([MasterPartId] ASC),
    CONSTRAINT [FK_MasterParts_Manufacturer] FOREIGN KEY ([ManufacturerId]) REFERENCES [dbo].[Manufacturer] ([ManufacturerId]),
    CONSTRAINT [FK_MasterParts_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO








CREATE TRIGGER [dbo].[Trg_MasterPartsAudit]

   ON  [dbo].[MasterParts]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN



INSERT INTO [dbo].[MasterPartsAudit]

SELECT * FROM INSERTED



SET NOCOUNT ON;



END
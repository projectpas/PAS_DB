CREATE TABLE [dbo].[UOMFamilyTypeAudit] (
    [UOMFamilyTypeAuditID] INT           IDENTITY (1, 1) NOT NULL,
    [UOMFamilyTypeId]      INT           NOT NULL,
    [Code]                 VARCHAR (100) NULL,
    [Name]                 VARCHAR (100) NOT NULL,
    [Description]          VARCHAR (256) NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [IsActive]             BIT           NOT NULL,
    [IsDeleted]            BIT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_UOMFamilyTypeAudit] PRIMARY KEY CLUSTERED ([UOMFamilyTypeAuditID] ASC)
);


GO

     CREATE     TRIGGER [dbo].[TrgUOMFamilyTypeAudit]
        ON dbo.UOMFamilyType
        AFTER INSERT, UPDATE
        AS
        BEGIN
            SET NOCOUNT ON;
            INSERT INTO dbo.UOMFamilyTypeAudit (UOMFamilyTypeId, Code, Name, Description, MasterCompanyId, IsActive, IsDeleted, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate)
            SELECT UOMFamilyTypeId, Code, Name, Description, MasterCompanyId, IsActive, IsDeleted, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate
            FROM INSERTED;
        END;

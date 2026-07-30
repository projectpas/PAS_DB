CREATE TABLE [dbo].[DeprNonDeprTangibleClassTypes] (
    [DeprNonDeprTangibleClassTypeId]          BIGINT        IDENTITY (1, 1) NOT NULL,
    [DeprNonDeprTangibleClassTypeName]        VARCHAR (100) NOT NULL,
    [DeprNonDeprTangibleClassTypeDescription] VARCHAR (500) NOT NULL,
    [MasterCompanyId]                         INT           NOT NULL,
    [CreatedBy]                               VARCHAR (256) NOT NULL,
    [UpdatedBy]                               VARCHAR (256) NOT NULL,
    [CreatedDate]                             DATETIME2 (7) CONSTRAINT [DF_DeprNonDeprTangibleClassTypes_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                             DATETIME2 (7) CONSTRAINT [DF_DeprNonDeprTangibleClassTypes_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                                BIT           NOT NULL,
    [IsDeleted]                               BIT           CONSTRAINT [DF_DeprNonDeprTangibleClassTypes_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_DeprNonDeprTangibleClassTypes] PRIMARY KEY CLUSTERED ([DeprNonDeprTangibleClassTypeId] ASC)
);


GO

CREATE TRIGGER [dbo].[Trg_DeprNonDeprTangibleClassTypes] ON [dbo].[DeprNonDeprTangibleClassTypes] FOR INSERT, UPDATE, DELETE
AS
SET NOCOUNT ON;
INSERT [dbo].[DeprNonDeprTangibleClassTypesAudit] ([DeprNonDeprTangibleClassTypeId]
           ,[DeprNonDeprTangibleClassTypeName]
           ,[DeprNonDeprTangibleClassTypeDescription]
           ,[MasterCompanyId]
           ,[CreatedBy]
           ,[UpdatedBy]
           ,[CreatedDate]
           ,[UpdatedDate]
           ,[IsActive]
           ,[IsDeleted])
SELECT
    I.[DeprNonDeprTangibleClassTypeId],
    I.[DeprNonDeprTangibleClassTypeName],
    I.[DeprNonDeprTangibleClassTypeDescription],
    I.[MasterCompanyId],
    I.[CreatedBy],
    I.[UpdatedBy],
    I.[CreatedDate],
    I.[UpdatedDate],
    I.[IsActive],
    I.[IsDeleted]
FROM Inserted I
UNION ALL
SELECT
    D.[DeprNonDeprTangibleClassTypeId],
    D.[DeprNonDeprTangibleClassTypeName],
    D.[DeprNonDeprTangibleClassTypeDescription],
    D.[MasterCompanyId],
    D.[CreatedBy],
    D.[UpdatedBy],
    D.[CreatedDate],
    D.[UpdatedDate],
    D.[IsActive],
    D.[IsDeleted]
FROM Deleted D
WHERE NOT EXISTS (
   SELECT * FROM Inserted
);
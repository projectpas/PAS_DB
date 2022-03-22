CREATE TABLE [dbo].[WingType] (
    [WingTypeId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [WingTypeName]    VARCHAR (50)   NOT NULL,
    [Description]     VARCHAR (250)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_WingType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_WingType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_WingType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_WingType_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WingType] PRIMARY KEY CLUSTERED ([WingTypeId] ASC),
    CONSTRAINT [FK_WingTypeId_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_WingType] UNIQUE NONCLUSTERED ([WingTypeName] ASC, [MasterCompanyId] ASC)
);


GO






CREATE TRIGGER [dbo].[Trg_WingTypeAudit] 

ON [dbo].[WingType]

AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  





 INSERT INTO [dbo].[WingTypeAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END
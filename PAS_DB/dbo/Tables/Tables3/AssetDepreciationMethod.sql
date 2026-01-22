CREATE TABLE [dbo].[AssetDepreciationMethod] (
    [AssetDepreciationMethodId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetDepreciationMethodCode]  VARCHAR (30)   NOT NULL,
    [AssetDepreciationMethodName]  VARCHAR (30)   NOT NULL,
    [AssetDepreciationMethodBasis] VARCHAR (20)   NOT NULL,
    [AssetDepreciationMethodMemo]  NVARCHAR (MAX) NULL,
    [MasterCompanyId]              INT            NOT NULL,
    [CreatedBy]                    VARCHAR (256)  NOT NULL,
    [UpdatedBy]                    VARCHAR (256)  NOT NULL,
    [CreatedDate]                  DATETIME2 (7)  CONSTRAINT [AssetDepreciationMethod_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7)  CONSTRAINT [AssetDepreciationMethod_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                     BIT            CONSTRAINT [DF_AssetDepreciationMethod_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                    BIT            CONSTRAINT [DF_AssetDepreciationMethod_IsDeleted] DEFAULT ((0)) NOT NULL,
    [SequenceNo]                   INT            NOT NULL,
    CONSTRAINT [PK_AssetDepreciationMethod] PRIMARY KEY CLUSTERED ([AssetDepreciationMethodId] ASC),
    CONSTRAINT [FK_AssetDepreciationMethod_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_AssetDepreciationMethod] UNIQUE NONCLUSTERED ([AssetDepreciationMethodCode] ASC, [MasterCompanyId] ASC),
    CONSTRAINT [Unique_AssetDepreciationMethodName] UNIQUE NONCLUSTERED ([AssetDepreciationMethodName] ASC, [MasterCompanyId] ASC),
    CONSTRAINT [Unique_AssetDepreciationMethodSeqNo] UNIQUE NONCLUSTERED ([SequenceNo] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_AssetDepreciationMethodAudit] ON [dbo].[AssetDepreciationMethod]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  

  

 INSERT INTO [dbo].[AssetDepreciationMethodAudit]  

 SELECT * FROM INSERTED  

  

 SET NOCOUNT ON;  

  

END
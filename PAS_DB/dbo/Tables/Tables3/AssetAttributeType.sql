CREATE TABLE [dbo].[AssetAttributeType] (
    [AssetAttributeTypeId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [TangibleClassId]         BIGINT         NOT NULL,
    [AssetAttributeTypeName]  VARCHAR (30)   NOT NULL,
    [Description]             VARCHAR (100)  NULL,
    [ConventionType]          BIGINT         NOT NULL,
    [DepreciationMethod]      BIGINT         NOT NULL,
    [ResidualPercentage]      BIGINT         NOT NULL,
    [AssetLife]               INT            NOT NULL,
    [DepreciationFrequencyId] BIGINT         NOT NULL,
    [AcquiredGLAccountId]     BIGINT         NOT NULL,
    [DeprExpenseGLAccountId]  BIGINT         NOT NULL,
    [AdDepsGLAccountId]       BIGINT         NOT NULL,
    [AssetSale]               BIGINT         NOT NULL,
    [AssetWriteOff]           BIGINT         NOT NULL,
    [AssetWriteDown]          BIGINT         NOT NULL,
    [ManagementStructureId]   BIGINT         NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [CreatedBy]               VARCHAR (256)  NOT NULL,
    [UpdatedBy]               VARCHAR (256)  NOT NULL,
    [CreatedDate]             DATETIME2 (7)  CONSTRAINT [DF_AssetAttributeType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  CONSTRAINT [DF_AssetAttributeType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT            CONSTRAINT [DF_AssetAttributeType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT            CONSTRAINT [DF_AssetAttributeType_IsDeleted] DEFAULT ((0)) NOT NULL,
    [SelectedCompanyIds]      VARCHAR (1000) NOT NULL,
    CONSTRAINT [PK_AssetAttributeType] PRIMARY KEY CLUSTERED ([AssetAttributeTypeId] ASC),
    CONSTRAINT [FK_AssetAttributeType_ManagementStructure] FOREIGN KEY ([ManagementStructureId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [FK_AssetAttributeType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_AssetAttributeType_TangibleClass] FOREIGN KEY ([TangibleClassId]) REFERENCES [dbo].[TangibleClass] ([TangibleClassId]),
    CONSTRAINT [FK_AssetAttributeTypeAcq_GLAccount] FOREIGN KEY ([AcquiredGLAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_AssetAttributeTypeDeprExp_GLAccount] FOREIGN KEY ([DeprExpenseGLAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_AssetAttributeTypeDeps_AssetDepreciationMethod] FOREIGN KEY ([DepreciationMethod]) REFERENCES [dbo].[AssetDepreciationMethod] ([AssetDepreciationMethodId]),
    CONSTRAINT [FK_AssetAttributeTypeDeps_AssetSale] FOREIGN KEY ([AssetSale]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_AssetAttributeTypeDeps_AssetWriteDown] FOREIGN KEY ([AssetWriteDown]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_AssetAttributeTypeDeps_AssetWriteOff] FOREIGN KEY ([AssetWriteOff]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_AssetAttributeTypeDeps_ConventionType] FOREIGN KEY ([ConventionType]) REFERENCES [dbo].[ConventionType] ([ConventionTypeId]),
    CONSTRAINT [FK_AssetAttributeTypeDeps_DepreciationFrequency] FOREIGN KEY ([DepreciationFrequencyId]) REFERENCES [dbo].[AssetDepreciationFrequency] ([AssetDepreciationFrequencyId]),
    CONSTRAINT [FK_AssetAttributeTypeDeps_GLAccount] FOREIGN KEY ([AdDepsGLAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_AssetAttributeTypeDeps_ResidualPercentage] FOREIGN KEY ([ResidualPercentage]) REFERENCES [dbo].[Percent] ([PercentId]),
    CONSTRAINT [Unique_AssetAttributeType] UNIQUE NONCLUSTERED ([AssetAttributeTypeName] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_AssetAttributeTypeAudit] ON [dbo].[AssetAttributeType]

   AFTER INSERT,UPDATE,DELETE

AS   

BEGIN  



DECLARE @TangibleClass VARCHAR(100),@ConventionTypeName VARCHAR(100),@AssetDepreciationMethodName VARCHAR(100),

	@AssetDepreciationIntervalName VARCHAR(100),@PercentValue VARCHAR(100),@AcquiredGLAccount VARCHAR(100),@DeprExpenseGLAccount VARCHAR(100),

	@AdDepsGLAccount VARCHAR(100),@AssetSaleGLAccount VARCHAR(100),@AssetWriteOffGLAccount VARCHAR(100),@AssetWriteDownLAccount VARCHAR(100),

	@LegalEntity VARCHAR(MAX)



DECLARE @TangibleClassId BIGINT,@ConventionTypeId BIGINT,@AssetDepreciationMethodId BIGINT,

	@AssetDepreciationIntervalId BIGINT,@PercentId BIGINT,@AcquiredGLAccountId BIGINT,@DeprExpenseGLAccountId BIGINT,

	@AdDepsGLAccountId BIGINT,@AssetSaleGLAccountId BIGINT,@AssetWriteOffGLAccountId BIGINT,@AssetWriteDownLAccountId BIGINT,

	@LegalEntityIds VARCHAR(1000),@AssetAttributeTypeId BIGINT



	SELECT @TangibleClassId=TangibleClassId,@ConventionTypeId=ConventionType,@AssetDepreciationMethodId=DepreciationMethod,

	@AssetDepreciationIntervalId=DepreciationFrequencyId,@PercentId=ResidualPercentage,@AcquiredGLAccountId=AcquiredGLAccountId,

	@DeprExpenseGLAccountId=DeprExpenseGLAccountId,@AdDepsGLAccountId=AdDepsGLAccountId,@AssetSaleGLAccountId=AssetSale,

	@AssetWriteOffGLAccountId=AssetWriteOff,@AssetWriteDownLAccountId=AssetWriteDown,

	@LegalEntityIds=selectedCompanyIds,@AssetAttributeTypeId=AssetAttributeTypeId FROM INSERTED



	SELECT @TangibleClass=TangibleClassName FROM TangibleClass WHERE TangibleClassId=@TangibleClassId

	SELECT @ConventionTypeName=Name FROM ConventionType WHERE ConventionTypeId=@ConventionTypeId

	SELECT @AssetDepreciationMethodName=AssetDepreciationMethodName FROM AssetDepreciationMethod WHERE AssetDepreciationMethodId=@AssetDepreciationMethodId

	SELECT @AssetDepreciationIntervalName=AssetDepreciationIntervalName FROM AssetDepreciationInterval WHERE AssetDepreciationIntervalId=@AssetDepreciationIntervalId

	SELECT @PercentValue=PercentValue FROM [Percent] WHERE PercentId=@PercentId

	SELECT @AcquiredGLAccount= AccountName FROM GLAccount WHERE GLAccountId=@AcquiredGLAccountId

	SELECT @DeprExpenseGLAccount=AccountName FROM GLAccount WHERE GLAccountId=@DeprExpenseGLAccountId

	SELECT @AdDepsGLAccount=AccountName FROM GLAccount WHERE GLAccountId=@AdDepsGLAccountId

	SELECT @AssetSaleGLAccount= AccountName FROM GLAccount WHERE GLAccountId=@AssetSaleGLAccountId

	SELECT @AssetWriteOffGLAccount= AccountName FROM GLAccount WHERE GLAccountId=@AssetWriteOffGLAccountId

	SELECT @AssetWriteDownLAccount= AccountName FROM GLAccount WHERE GLAccountId=@AssetWriteDownLAccountId



	SELECT @AssetAttributeTypeId=AssetAttributeTypeId, @LegalEntity = 

		   STUFF((SELECT ', ' + Name

           FROM LegalEntityAssetAttributeType LEA 

		   JOIN LegalEntity LE ON LEA.LegalEntityId=LE.LegalEntityId

           WHERE LEA.AssetAttributeTypeId = AAT.AssetAttributeTypeId 

           FOR XML PATH('')), 1, 2, '')

	FROM AssetAttributeType AAT

	WHERE AAT.AssetAttributeTypeId=@AssetAttributeTypeId

	GROUP BY AssetAttributeTypeId



 INSERT INTO [dbo].[AssetAttributeTypeAudit]  

 SELECT *,@TangibleClass,@ConventionTypeName,@AssetDepreciationMethodName,@AssetDepreciationIntervalName,@PercentValue,

 @AcquiredGLAccount,@DeprExpenseGLAccount,@AdDepsGLAccount,@AssetSaleGLAccount,@AssetWriteOffGLAccount,@AssetWriteDownLAccount,

 @LegalEntity

 FROM INSERTED  



 SET NOCOUNT ON;  



END
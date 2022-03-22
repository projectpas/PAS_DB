CREATE TABLE [dbo].[AssetIntangibleAttributeType] (
    [AssetIntangibleAttributeTypeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetIntangibleTypeId]          BIGINT         NOT NULL,
    [AssetDepreciationMethodId]      BIGINT         NOT NULL,
    [IntangibleLifeYears]            INT            CONSTRAINT [DF_AssetIntangibleAttributeType_IntangibleLifeYears] DEFAULT ((0)) NOT NULL,
    [AssetAmortizationIntervalId]    BIGINT         NOT NULL,
    [IntangibleGLAccountId]          BIGINT         NOT NULL,
    [AmortExpenseGLAccountId]        BIGINT         NOT NULL,
    [AccAmortDeprGLAccountId]        BIGINT         NOT NULL,
    [IntangibleWriteDownGLAccountId] BIGINT         NOT NULL,
    [IntangibleWriteOffGLAccountId]  BIGINT         NOT NULL,
    [MasterCompanyId]                INT            NOT NULL,
    [CreatedBy]                      VARCHAR (256)  NOT NULL,
    [UpdatedBy]                      VARCHAR (256)  NOT NULL,
    [CreatedDate]                    DATETIME2 (7)  CONSTRAINT [AssetIntangibleAttributeType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7)  CONSTRAINT [AssetIntangibleAttributeType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                       BIT            CONSTRAINT [DF_AssetIntangibleAttributeType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                      BIT            CONSTRAINT [DF_AssetIntangibleAttributeType_IsDeleted] DEFAULT ((0)) NOT NULL,
    [SelectedCompanyIds]             VARCHAR (1000) NOT NULL,
    CONSTRAINT [PK_AssetIntangibleType] PRIMARY KEY CLUSTERED ([AssetIntangibleAttributeTypeId] ASC),
    CONSTRAINT [FK_AssetIntangibleAttributeType_AssetAmortizationInterval] FOREIGN KEY ([AssetAmortizationIntervalId]) REFERENCES [dbo].[AssetAmortizationInterval] ([AssetAmortizationIntervalId]),
    CONSTRAINT [FK_AssetIntangibleAttributeType_AssetDepreciationMethod] FOREIGN KEY ([AssetDepreciationMethodId]) REFERENCES [dbo].[AssetDepreciationMethod] ([AssetDepreciationMethodId]),
    CONSTRAINT [FK_AssetIntangibleAttributeType_AssetIntangibleType] FOREIGN KEY ([AssetIntangibleTypeId]) REFERENCES [dbo].[AssetIntangibleType] ([AssetIntangibleTypeId]),
    CONSTRAINT [FK_AssetIntangibleAttributeType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_AssetIntangibleAttributeTypeAccAmort_GLAccount] FOREIGN KEY ([AccAmortDeprGLAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_AssetIntangibleAttributeTypeAmortExp_GLAccount] FOREIGN KEY ([AmortExpenseGLAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_AssetIntangibleAttributeTypeIntangible_GLAccount] FOREIGN KEY ([IntangibleGLAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_AssetIntangibleAttributeTypeIntgWriteDown_GLAccount] FOREIGN KEY ([IntangibleWriteDownGLAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_AssetIntangibleAttributeTypeWriteOff_GLAccount] FOREIGN KEY ([IntangibleWriteOffGLAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId])
);


GO


create TRIGGER [dbo].[trg_AssetIntangibleAttributeType]

   ON  [dbo].[AssetIntangibleAttributeType]

   AFTER INSERT,UPDATE

AS 

BEGIN



	DECLARE @AssetIntangibleType VARCHAR(100),@AssetDepreciationMethod VARCHAR(100),@AssetAmortizationInterval VARCHAR(100),

	@IntangibleGLAccount VARCHAR(100),@AmortExpenseGLAccount VARCHAR(100),@AccAmortDeprGLAccount VARCHAR(100),@IntangibleWriteDownGLAccount VARCHAR(100),

	@IntangibleWriteOffGLAccount VARCHAR(100),@LegalEntity VARCHAR(MAX)



	DECLARE @AssetIntangibleTypeId BIGINT,@AssetDepreciationMethodId BIGINT,@AssetAmortizationIntervalId BIGINT,

	@IntangibleGLAccountId BIGINT,@AmortExpenseGLAccountId BIGINT,@AccAmortDeprGLAccountId BIGINT,@IntangibleWriteDownGLAccountId BIGINT,

	@IntangibleWriteOffGLAccountId BIGINT,@LegalEntityIds VARCHAR(1000),@AssetIntangibleAttributeTypeId BIGINT



	





	SET NOCOUNT ON;



	SELECT @AssetIntangibleTypeId=AssetIntangibleTypeId,@AssetDepreciationMethodId=AssetDepreciationMethodId,@AssetAmortizationIntervalId=AssetAmortizationIntervalId,

	@IntangibleGLAccountId=IntangibleGLAccountId,@AmortExpenseGLAccountId=AmortExpenseGLAccountId,@AccAmortDeprGLAccountId=AccAmortDeprGLAccountId,

	@IntangibleWriteDownGLAccountId=IntangibleWriteDownGLAccountId,@IntangibleWriteOffGLAccountId=IntangibleWriteOffGLAccountId,

	@LegalEntityIds=selectedCompanyIds,@AssetIntangibleAttributeTypeId=AssetIntangibleAttributeTypeId FROM INSERTED



	SELECT @AssetIntangibleType=AssetIntangibleName FROM AssetIntangibleType WHERE AssetIntangibleTypeId=@AssetIntangibleTypeId

	SELECT @AssetDepreciationMethod=AssetDepreciationMethodName FROM AssetDepreciationMethod WHERE AssetDepreciationMethodId=@AssetDepreciationMethodId

	SELECT @AssetAmortizationInterval=Name FROM AssetDepreciationFrequency WHERE AssetDepreciationFrequencyId=@AssetAmortizationIntervalId

	SELECT @IntangibleGLAccount= AccountName FROM GLAccount WHERE GLAccountId=@IntangibleGLAccountId

	SELECT @AmortExpenseGLAccount= AccountName FROM GLAccount WHERE GLAccountId=@AmortExpenseGLAccountId

	SELECT @AccAmortDeprGLAccount= AccountName FROM GLAccount WHERE GLAccountId=@AccAmortDeprGLAccountId

	SELECT @IntangibleWriteDownGLAccount= AccountName FROM GLAccount WHERE GLAccountId=@IntangibleWriteDownGLAccountId

	SELECT @IntangibleWriteOffGLAccount= AccountName FROM GLAccount WHERE GLAccountId=@IntangibleWriteOffGLAccountId



	SELECT @AssetIntangibleAttributeTypeId=AssetIntangibleAttributeTypeId, @LegalEntity = 

		   STUFF((SELECT ', ' + Name

           FROM LegalEntityAssetIntangibleAttributeType LEA 

		   JOIN LegalEntity LE ON LEA.LegalEntityId=LE.LegalEntityId

           WHERE LEA.AssetIntangibleAttributeTypeId = AAT.AssetIntangibleAttributeTypeId

           FOR XML PATH('')), 1, 2, '')

	FROM AssetIntangibleAttributeType AAT

	WHERE AAT.AssetIntangibleAttributeTypeId=@AssetIntangibleAttributeTypeId

	GROUP BY AssetIntangibleAttributeTypeId



    INSERT INTO AssetIntangibleAttributeTypeAudit

	SELECT *,

	@AssetIntangibleType,@AssetDepreciationMethod,@AssetAmortizationInterval,@IntangibleGLAccount,@AmortExpenseGLAccount,

	@AccAmortDeprGLAccount,@IntangibleWriteDownGLAccount,@IntangibleWriteOffGLAccount,@LegalEntity

	FROM INSERTED



END
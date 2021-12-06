CREATE TABLE [dbo].[AssetAmortizationInterval] (
    [AssetAmortizationIntervalId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetAmortizationIntervalCode] VARCHAR (30)   NOT NULL,
    [AssetAmortizationIntervalName] VARCHAR (50)   NOT NULL,
    [AssetAmortizationIntervalMemo] NVARCHAR (MAX) NULL,
    [MasterCompanyId]               INT            NOT NULL,
    [CreatedBy]                     VARCHAR (256)  NOT NULL,
    [UpdatedBy]                     VARCHAR (256)  NOT NULL,
    [CreatedDate]                   DATETIME2 (7)  CONSTRAINT [DF_AssetAmortizationInterval_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)  CONSTRAINT [DF_AssetAmortizationInterval_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                      BIT            CONSTRAINT [DF_AssetAmortizationInterval_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT            CONSTRAINT [DF_AssetAmortizationInterval_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AssetAmortizationIntervalType] PRIMARY KEY CLUSTERED ([AssetAmortizationIntervalId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_AssetAmortizationIntervalAudit]

   ON  [dbo].[AssetAmortizationInterval]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO AssetAmortizationIntervalAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
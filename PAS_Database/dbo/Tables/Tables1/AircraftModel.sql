CREATE TABLE [dbo].[AircraftModel] (
    [AircraftModelId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AircraftTypeId]  INT            NOT NULL,
    [ModelName]       VARCHAR (50)   NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF__AircraftM__Creat__41B035A8] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_AircraftModel_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_AircraftModel_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_AircraftModel_IsDeleted] DEFAULT ((0)) NOT NULL,
    [WingTypeId]      BIGINT         DEFAULT ((0)) NOT NULL,
    [SequenceNo]      INT            NULL,
    CONSTRAINT [PK_AircraftModel] PRIMARY KEY CLUSTERED ([AircraftModelId] ASC),
    CONSTRAINT [FK_AircraftModel_AircraftType] FOREIGN KEY ([AircraftTypeId]) REFERENCES [dbo].[AircraftType] ([AircraftTypeId]),
    CONSTRAINT [FK_AircraftModel_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_AircraftModel_WingType] FOREIGN KEY ([WingTypeId]) REFERENCES [dbo].[WingType] ([WingTypeId]),
    CONSTRAINT [Unique_AircraftTypeModel] UNIQUE NONCLUSTERED ([AircraftTypeId] ASC, [ModelName] ASC, [MasterCompanyId] ASC)
);


GO




-- =============================================

CREATE TRIGGER [dbo].[Trg_AircraftModel]

   ON  [dbo].[AircraftModel]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	DECLARE @AircraftId BIGINT,@AircraftType VARCHAR(100),@WingTypeId BIGINT,@WingType VARCHAR(256)



	SELECT @AircraftId=AircraftTypeId,@WingTypeId=WingTypeId FROM INSERTED



	SELECT @AircraftType=Description FROM AircraftType WHERE AircraftTypeId=@AircraftId



	SELECT @WingType=WingTypeName FROM WingType WHERE WingTypeId=@WingTypeId



	INSERT INTO AircraftModelAudit

	SELECT AircraftModelId,AircraftTypeId,ModelName,Memo,MasterCompanyId,CreatedDate,UpdatedDate,CreatedBy,UpdatedBy,IsActive,

	IsDeleted,@AircraftType,WingTypeId,@WingType,SequenceNo FROM INSERTED



	SET NOCOUNT ON;



END
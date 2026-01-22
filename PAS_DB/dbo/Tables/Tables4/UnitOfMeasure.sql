CREATE TABLE [dbo].[UnitOfMeasure] (
    [UnitOfMeasureId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (100)  NOT NULL,
    [ShortName]       VARCHAR (100)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_UnitofMeasure_IsActive] DEFAULT ((1)) NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [UnitOfMeasure_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [UnitOfMeasure_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]       BIT            DEFAULT ((0)) NOT NULL,
    [StandardId]      INT            DEFAULT ((0)) NOT NULL,
    [SequenceNo]      INT            NULL,
    CONSTRAINT [PK_UnitOfMeasure] PRIMARY KEY CLUSTERED ([UnitOfMeasureId] ASC),
    CONSTRAINT [FK_UnitOfMeasure_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_UnitOfMeasure_Standard] FOREIGN KEY ([StandardId]) REFERENCES [dbo].[Standard] ([StandardId]),
    CONSTRAINT [Unique_UnitOfMeasure_Description] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC),
    CONSTRAINT [Unique_UnitOfMeasure_ShortName] UNIQUE NONCLUSTERED ([ShortName] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_UnitOfMeasureAudit]

   ON  [dbo].[UnitOfMeasure]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



DECLARE @StandardId int , @UnitOfMeasureId bigint , @MasterCompanyId int ,@SequenceNo int;

DECLARE @Description varchar(100),@ShortName varchar(100),@Memo varchar(100),@CreatedBy varchar(256),@UpdatedBy varchar(256),@StandardName varchar(256);

DECLARE @IsActive bit,@IsDeleted bit

DECLARE @CreatedDate datetime, @UpdatedDate datetime;



SELECT @UnitOfMeasureId = UnitOfMeasureId , @Description = [Description] , @ShortName = ShortName , @Memo=Memo ,

 	   @MasterCompanyId = MasterCompanyId ,	@IsActive = IsActive , @CreatedBy = CreatedBy ,

	   @UpdatedBy = UpdatedBy , @CreatedDate = CreatedDate , @UpdatedDate = UpdatedDate , @IsDeleted = IsDeleted,

	   @StandardId = StandardId , @SequenceNo =  SequenceNo FROM INSERTED

SELECT @StandardName = StandardName FROM [dbo].[Standard] WHERE StandardId=@StandardId



	INSERT INTO UnitOfMeasureAudit

	SELECT @UnitOfMeasureId,@Description,@ShortName,@Memo,@MasterCompanyId,@IsActive,@CreatedBy,

	       @UpdatedBy,@CreatedDate,@UpdatedDate,@IsDeleted,@StandardId,@StandardName,@SequenceNo FROM INSERTED



	SET NOCOUNT ON;



END
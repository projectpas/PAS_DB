CREATE TABLE [dbo].[Charge] (
    [ChargeId]        BIGINT          IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (200)   NOT NULL,
    [GLAccountId]     BIGINT          NOT NULL,
    [MasterCompanyId] INT             NOT NULL,
    [Memo]            NVARCHAR (MAX)  NULL,
    [CreatedBy]       VARCHAR (256)   NOT NULL,
    [UpdatedBy]       VARCHAR (256)   NOT NULL,
    [CreatedDate]     DATETIME2 (7)   CONSTRAINT [Charge_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)   CONSTRAINT [Charge_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT             CONSTRAINT [DF_Charge_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT             CONSTRAINT [DF_Charge_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ChargeType]      VARCHAR (256)   NOT NULL,
    [Cost]            DECIMAL (10, 2) NULL,
    [Price]           DECIMAL (10, 2) NULL,
    [SequenceNo]      INT             NULL,
    [CurrencyId]      INT             NULL,
    [UnitOfMeasureId] BIGINT          NULL,
    CONSTRAINT [PK_Charge] PRIMARY KEY CLUSTERED ([ChargeId] ASC),
    CONSTRAINT [FK_Charge_GLAccount] FOREIGN KEY ([GLAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_Charge_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_Charge] UNIQUE NONCLUSTERED ([ChargeType] ASC, [GLAccountId] ASC, [MasterCompanyId] ASC)
);


GO








CREATE TRIGGER [dbo].[Trg_ChargeAudit]

   ON  [dbo].[Charge]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN

       DECLARE @ChargeId bigint ,@Description varchar(200), @GLAccountId bigint, @MasterCompanyId int, @GLAccount varchar(256);

       DECLARE @Memo varchar(100),@CreatedBy varchar(256),@UpdatedBy varchar(256),@Code varchar(100),@ShortName varchar(100)

       DECLARE @CreatedDate datetime, @UpdatedDate datetime;

       DECLARE @IsActive bit,@IsDeleted bit;

       DECLARE @ChargeType varchar(256);

       DECLARE @Cost decimal(10,2),@Price decimal(10,2);

       DECLARE @SequenceNo int, @CurrencyId int ,@UnitOfMeasureId bigint;



       

   	   SELECT @ChargeId= ChargeId, @Description= [Description] , @GLAccountId=GLAccountId,

	          @MasterCompanyId = MasterCompanyId,@Memo = Memo , @CreatedBy = CreatedBy,

			  @UpdatedBy = UpdatedBy, @CreatedDate = CreatedDate ,@UpdatedDate = UpdatedDate,

			  @IsActive = IsActive,@IsDeleted = IsDeleted,@ChargeType = ChargeType ,@Cost = Cost,

			  @Price = Price,@SequenceNo = SequenceNo,@CurrencyId = CurrencyId,@UnitOfMeasureId = UnitOfMeasureId



	   FROM INSERTED

   	   SELECT @GLAccount=AccountName FROM dbo.GLAccount WHERE GLAccountId=@GLAccountId

	   SELECT @Code=Code FROM dbo.Currency WHERE CurrencyId=@CurrencyId

	   SELECT @ShortName=ShortName FROM dbo.UnitOfMeasure WHERE UnitOfMeasureId=@UnitOfMeasureId

       

   	   INSERT INTO [dbo].[ChargeAudit]

   	   SELECT @ChargeId,@Description,@GLAccountId,@MasterCompanyId,@Memo,

			  @CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,@IsActive,@IsDeleted,

			  @ChargeType,@Cost,@Price,@SequenceNo,@CurrencyId,@UnitOfMeasureId,@GLAccount,@Code,@ShortName  

	    FROM INSERTED

       

	   SET NOCOUNT ON;



END
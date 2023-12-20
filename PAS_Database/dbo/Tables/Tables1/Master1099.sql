CREATE TABLE [dbo].[Master1099] (
    [Master1099Id]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (100)  NOT NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Master1099_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Master1099_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [IsActive]        BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            DEFAULT ((0)) NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [Name]            VARCHAR (150)  NULL,
    [SequenceNo]      INT            NULL,
    CONSTRAINT [PK_Master1099] PRIMARY KEY CLUSTERED ([Master1099Id] ASC),
    CONSTRAINT [FK_Master1099_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_Master1099] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC)
);


GO






--------------------------------



CREATE TRIGGER [dbo].[Trg_Master1099Audit]

   ON  [dbo].[Master1099]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[Master1099Audit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
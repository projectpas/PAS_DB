CREATE TABLE [dbo].[ApplicableAD] (
    [ApplicableADId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (50)   NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_ApplicationADs_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_ApplicationADs_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_ApplicationADs_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_ApplicationADs_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ApplicationADs] PRIMARY KEY CLUSTERED ([ApplicableADId] ASC)
);


GO




---------------------------------------------------------------------------------------------------------------------------



CREATE TRIGGER [dbo].[Trg_ApplicableADAudit]

   ON  [dbo].[ApplicableAD]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO [dbo].[ApplicableADAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
CREATE TABLE [dbo].[MaterialMandatories] (
    [Id]              INT          IDENTITY (1, 1) NOT NULL,
    [CreatedBy]       VARCHAR (50) CONSTRAINT [DF__MaterialM__Creat__1F1A5B2B] DEFAULT (NULL) NULL,
    [CreatedDate]     DATETIME     CONSTRAINT [DF_MaterialMandatories_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (50) CONSTRAINT [DF__MaterialM__Updat__200E7F64] DEFAULT (NULL) NULL,
    [UpdatedDate]     DATETIME     CONSTRAINT [DF__MaterialM__Updat__2102A39D] DEFAULT (getdate()) NULL,
    [IsDeleted]       BIT          CONSTRAINT [DF__MaterialM__IsDel__21F6C7D6] DEFAULT ((0)) NULL,
    [Name]            VARCHAR (50) CONSTRAINT [DF__MaterialMa__Name__22EAEC0F] DEFAULT (NULL) NULL,
    [IsActive]        BIT          NULL,
    [MasterCompanyId] BIGINT       NOT NULL,
    CONSTRAINT [PK__Material__3214EC07C9F071EA] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_MaterialMandatoriesAudit]

   ON  [dbo].[MaterialMandatories]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO MaterialMandatoriesAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
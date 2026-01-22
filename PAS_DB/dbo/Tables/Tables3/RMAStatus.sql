CREATE TABLE [dbo].[RMAStatus] (
    [RMAStatusId]     BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (MAX)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [RMAStatus_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [RMAStatus_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [RMAStatus_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [RMAStatus_DC_Delete] DEFAULT ((0)) NOT NULL,
    [Status]          VARCHAR (256)  NOT NULL,
    [SequenceNo]      INT            NULL,
    CONSTRAINT [PK_RMAStatus] PRIMARY KEY CLUSTERED ([RMAStatusId] ASC),
    CONSTRAINT [Unique_RMAStatus] UNIQUE NONCLUSTERED ([Status] ASC, [MasterCompanyId] ASC)
);


GO



CREATE TRIGGER [dbo].[Trg_RMAStatusAudit]

   ON  [dbo].[RMAStatus]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[RMAStatusAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;



END
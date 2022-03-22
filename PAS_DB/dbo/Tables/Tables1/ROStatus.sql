CREATE TABLE [dbo].[ROStatus] (
    [ROStatusId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (MAX)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [ROStatus_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [ROStatus_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [ROStatuss_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [ROStatuss_DC_Delete] DEFAULT ((0)) NOT NULL,
    [Status]          VARCHAR (256)  NOT NULL,
    [SequenceNo]      INT            NULL,
    CONSTRAINT [PK_ROStatus] PRIMARY KEY CLUSTERED ([ROStatusId] ASC),
    CONSTRAINT [Unique_ROStatus] UNIQUE NONCLUSTERED ([Status] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_ROStatusAudit]

   ON  [dbo].[ROStatus]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO ROStatusAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END
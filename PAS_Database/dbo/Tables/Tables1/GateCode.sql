CREATE TABLE [dbo].[GateCode] (
    [GateCodeId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [GateCode]        VARCHAR (30)   NOT NULL,
    [Description]     VARCHAR (256)  NOT NULL,
    [Sequence]        VARCHAR (30)   NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NULL,
    [UpdatedBy]       VARCHAR (256)  NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NULL,
    [IsDelete]        BIT            NULL,
    CONSTRAINT [PK_GateCode] PRIMARY KEY CLUSTERED ([GateCodeId] ASC),
    CONSTRAINT [UQ_GateCode_codes] UNIQUE NONCLUSTERED ([GateCode] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_GateCodeAudit]

   ON  [dbo].[GateCode]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO GateCodeAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
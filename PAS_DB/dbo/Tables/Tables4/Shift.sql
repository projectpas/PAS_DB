CREATE TABLE [dbo].[Shift] (
    [ShiftId]         BIGINT        IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (100) NOT NULL,
    [MasterCompanyId] INT           NULL,
    [CreatedBy]       VARCHAR (256) NULL,
    [UpdatedBy]       VARCHAR (256) NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_Shift_CreatedDate] DEFAULT (getdate()) NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_Shift_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]        BIT           CONSTRAINT [DF_Shift_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_Shift_IsDeleted] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_Shift] PRIMARY KEY CLUSTERED ([ShiftId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_ShiftAudit]

   ON  [dbo].[Shift]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ShiftAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
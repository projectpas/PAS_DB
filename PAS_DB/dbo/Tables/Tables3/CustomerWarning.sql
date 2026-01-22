CREATE TABLE [dbo].[CustomerWarning] (
    [CustomerWarningId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerId]            BIGINT        NOT NULL,
    [WarningMessage]        VARCHAR (300) NULL,
    [RestrictMessage]       VARCHAR (300) NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [DF_CustomerWarning_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [DF_CustomerWarning_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [CustomerWarning_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [D_CW_Delete] DEFAULT ((0)) NOT NULL,
    [Allow]                 BIT           CONSTRAINT [CustomerWarning_DC_Allow] DEFAULT ((0)) NOT NULL,
    [Warning]               BIT           CONSTRAINT [CustomerWarning_DC_Warning] DEFAULT ((0)) NOT NULL,
    [Restrict]              BIT           CONSTRAINT [CustomerWarning_DC_Restrict] DEFAULT ((0)) NOT NULL,
    [CustomerWarningTypeId] BIGINT        NULL,
    [CustomerWarningsId]    BIGINT        NULL,
    CONSTRAINT [PK_CustomerWarning] PRIMARY KEY CLUSTERED ([CustomerWarningId] ASC),
    CONSTRAINT [FK_CustomerWarning_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CustomerWarning_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UC_CustomerWarning_CustomerId_CustomerWarningTypeId] UNIQUE NONCLUSTERED ([CustomerId] ASC, [CustomerWarningTypeId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_CustomerWarningAudit]

   ON  [dbo].[CustomerWarning]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[CustomerWarningAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
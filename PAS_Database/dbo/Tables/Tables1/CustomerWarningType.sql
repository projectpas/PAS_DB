CREATE TABLE [dbo].[CustomerWarningType] (
    [CustomerWarningTypeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]                  VARCHAR (100)  NOT NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedDate]           DATETIME2 (7)  CONSTRAINT [DF_CustomerWarningList_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  CONSTRAINT [DF_CustomerWarningList_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [IsActive]              BIT            CONSTRAINT [CustomerWarningList_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            CONSTRAINT [CustomerWarningList_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CustomerWarningList] PRIMARY KEY CLUSTERED ([CustomerWarningTypeId] ASC),
    CONSTRAINT [UQ_CustomerWarningList_codes] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


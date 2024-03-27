CREATE TABLE [dbo].[ShortDateTimeFormat] (
    [ShortDateTimeFormatId] INT            IDENTITY (1, 1) NOT NULL,
    [DatetimeFormat]        VARCHAR (256)  NOT NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  CONSTRAINT [DF_ShortDateTimeFormat_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  CONSTRAINT [DF_ShortDateTimeFormat_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT            CONSTRAINT [D_ShortDateTimeFormat_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            CONSTRAINT [D_ShortDateTimeFormat_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ShortDateTimeFormat] PRIMARY KEY CLUSTERED ([ShortDateTimeFormatId] ASC)
);


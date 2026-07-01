CREATE TABLE [dbo].[LocationLabelSetting] (
    [LocationLabelSettingId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [FieldWidth]             DECIMAL (18, 2) NULL,
    [FieldHeight]            DECIMAL (18, 2) NULL,
    [FieldDPI]               DECIMAL (18, 2) NULL,
    [MarginLeft]             DECIMAL (18, 2) NULL,
    [MarginRight]            DECIMAL (18, 2) NULL,
    [MarginTop]              DECIMAL (18, 2) NULL,
    [MarginBottom]           DECIMAL (18, 2) NULL,
    [MasterCompanyId]        INT             NOT NULL,
    [CreatedBy]              VARCHAR (50)    NOT NULL,
    [CreatedDate]            DATETIME2 (7)   CONSTRAINT [DF_LocationLabelSetting_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]              VARCHAR (50)    NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   CONSTRAINT [DF_LocationLabelSetting_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]               BIT             CONSTRAINT [DF__LocationLabelSetting__IsActi__59FA5E80] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT             CONSTRAINT [DF__LocationLabelSetting__IsDele__5AEE82B9] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LocationLabelSetting] PRIMARY KEY CLUSTERED ([LocationLabelSettingId] ASC)
);


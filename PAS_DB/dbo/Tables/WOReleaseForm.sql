CREATE TABLE [dbo].[WOReleaseForm] (
    [WOReleaseFormId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [FormName]        VARCHAR (200) NOT NULL,
    [Description]     VARCHAR (500) NULL,
    [IsActive]        BIT           DEFAULT ((1)) NOT NULL,
    [MasterCompanyId] BIGINT        NOT NULL,
    [CreatedBy]       VARCHAR (256) NULL,
    [CreatedDate]     DATETIME2 (7) DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NULL,
    [UpdatedDate]     DATETIME2 (7) NULL,
    [IsDeleted]       BIT           NULL,
    CONSTRAINT [PK_WOReleaseForm] PRIMARY KEY CLUSTERED ([WOReleaseFormId] ASC)
);


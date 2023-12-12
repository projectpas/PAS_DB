CREATE TABLE [dbo].[PNLabelMapping] (
    [PNLabelMappingId]   BIGINT        IDENTITY (1, 1) NOT NULL,
    [PNLabelId]          BIGINT        NOT NULL,
    [Description]        VARCHAR (100) NOT NULL,
    [FieldWidth]         BIGINT        NOT NULL,
    [FieldHeight]        BIGINT        NOT NULL,
    [MasterCompanyId]    INT           NOT NULL,
    [CreatedBy]          VARCHAR (50)  NOT NULL,
    [CreatedDate]        DATETIME2 (7) CONSTRAINT [DF_PNLabelMapping_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]          VARCHAR (50)  NOT NULL,
    [UpdatedDate]        DATETIME2 (7) CONSTRAINT [DF_PNLabelMapping_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]           BIT           CONSTRAINT [DF__PNLabelMapping__IsActi__59FA5E80] DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT           CONSTRAINT [DF__PNLabelMapping__IsDele__5AEE82B9] DEFAULT ((0)) NOT NULL,
    [AllPNLabelSelected] BIT           NULL,
    CONSTRAINT [PK_PNLabelMapping] PRIMARY KEY CLUSTERED ([PNLabelMappingId] ASC)
);


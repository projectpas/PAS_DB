CREATE TABLE [dbo].[TextTransform] (
    [TextTransformId] INT            IDENTITY (1, 1) NOT NULL,
    [DisplayName]     VARCHAR (256)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_TextTransform_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_TextTransform_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [D_TextTransform_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [D_TextTransform_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_TextTransform] PRIMARY KEY CLUSTERED ([TextTransformId] ASC)
);


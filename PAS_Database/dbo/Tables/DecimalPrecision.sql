CREATE TABLE [dbo].[DecimalPrecision] (
    [DecimalPrecisionId] INT            IDENTITY (1, 1) NOT NULL,
    [Precision]          VARCHAR (10)   NOT NULL,
    [DisplayName]        VARCHAR (20)   NOT NULL,
    [Memo]               NVARCHAR (MAX) NULL,
    [MasterCompanyId]    INT            NOT NULL,
    [CreatedBy]          VARCHAR (256)  NOT NULL,
    [UpdatedBy]          VARCHAR (256)  NOT NULL,
    [CreatedDate]        DATETIME2 (7)  CONSTRAINT [DF_DecimalPrecision_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]        DATETIME2 (7)  CONSTRAINT [DF_DecimalPrecision_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]           BIT            CONSTRAINT [D_DecimalPrecision_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT            CONSTRAINT [D_DecimalPrecision_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_DecimalPrecision] PRIMARY KEY CLUSTERED ([DecimalPrecisionId] ASC)
);


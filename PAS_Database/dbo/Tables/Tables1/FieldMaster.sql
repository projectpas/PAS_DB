CREATE TABLE [dbo].[FieldMaster] (
    [FieldMasterId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [ModuleId]        BIGINT         NOT NULL,
    [FieldName]       NVARCHAR (100) NOT NULL,
    [HeaderName]      NVARCHAR (100) NOT NULL,
    [FieldWidth]      NVARCHAR (10)  NOT NULL,
    [FieldType]       NVARCHAR (50)  NULL,
    [FieldAlign]      INT            NULL,
    [FieldFormate]    NVARCHAR (50)  NULL,
    [FieldSortOrder]  INT            NULL,
    [IsMultiValue]    BIT            NULL,
    [IsToolTipShow]   BIT            NOT NULL,
    [IsRequired]      BIT            NULL,
    [IsHidden]        BIT            NULL,
    [IsNumString]     BIT            NOT NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [FieldMaster_DC_CD] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [FieldMaster_DC_UD] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [FieldMaster_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [FieldMaster_DC_Delete] DEFAULT ((0)) NOT NULL,
    [IsEditable]      BIT            DEFAULT ('FALSE') NULL,
    CONSTRAINT [PK_FieldMaster] PRIMARY KEY CLUSTERED ([FieldMasterId] ASC)
);




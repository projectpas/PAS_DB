﻿CREATE TABLE [dbo].[EmployeeFieldMaster] (
    [EmployeeFieldMasterId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ModuleId]              INT            NOT NULL,
    [EmployeeId]            BIGINT         NOT NULL,
    [FieldMasterId]         BIGINT         NOT NULL,
    [FieldName]             NVARCHAR (100) NOT NULL,
    [HeaderName]            NVARCHAR (100) NOT NULL,
    [FieldWidth]            NVARCHAR (10)  NOT NULL,
    [FieldType]             NVARCHAR (50)  NULL,
    [FieldFormate]          NVARCHAR (50)  NULL,
    [FieldSortOrder]        SMALLINT       NULL,
    [IsMultiValue]          BIT            NULL,
    [IsToolTipShow]         BIT            NOT NULL,
    [IsRequired]            BIT            NULL,
    [IsHidden]              BIT            NULL,
    [FieldAlign]            INT            NULL,
    [IsNumString]           BIT            NOT NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  CONSTRAINT [EmployeeFieldMaster_DC_CD] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  CONSTRAINT [EmployeeFieldMaster_DC_UD] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]              BIT            CONSTRAINT [EmployeeFieldMaster_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            CONSTRAINT [EmployeeFieldMaster_DC_Delete] DEFAULT ((0)) NOT NULL,
    [IsEditable]            BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_EmployeeFieldMaster] PRIMARY KEY CLUSTERED ([EmployeeFieldMasterId] ASC)
);






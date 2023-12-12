CREATE TABLE [dbo].[ManagementStructureType] (
    [TypeID]          BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]     NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_ManagmentStructureType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_ManagmentStructureType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_ManagmentStructureType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_ManagmentStructureType_IsDeleted] DEFAULT ((0)) NOT NULL,
    [SequenceNo]      INT            NULL,
    CONSTRAINT [PK_ManagmentStructureType] PRIMARY KEY CLUSTERED ([TypeID] ASC)
);


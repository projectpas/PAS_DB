CREATE TABLE [dbo].[GridModule] (
    [GridModuleId]    INT           IDENTITY (1, 1) NOT NULL,
    [ModuleName]      VARCHAR (100) NOT NULL,
    [CodePrefix]      VARCHAR (10)  NOT NULL,
    [CodeSufix]       VARCHAR (10)  NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [GridModule_DC_CD] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [GridModule_DC_UD] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [GridModule_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [GridModule_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_GridModule] PRIMARY KEY CLUSTERED ([GridModuleId] ASC)
);


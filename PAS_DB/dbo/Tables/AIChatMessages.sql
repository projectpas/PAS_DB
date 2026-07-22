CREATE TABLE [dbo].[AIChatMessages] (
    [Id]              INT            IDENTITY (1, 1) NOT NULL,
    [SessionId]       VARCHAR (64)   NOT NULL,
    [EmployeeId]      INT            NOT NULL,
    [Role]            VARCHAR (16)   NOT NULL,
    [Content]         NVARCHAR (MAX) NOT NULL,
    [MasterCompanyId] INT            DEFAULT ((0)) NOT NULL,
    [CreatedBy]       NVARCHAR (100) DEFAULT ('system') NOT NULL,
    [CreatedDate]     DATETIME       DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       NVARCHAR (100) DEFAULT ('system') NOT NULL,
    [UpdatedDate]     DATETIME       DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AIChatMessages] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_AIChatMessages_EmployeeId]
    ON [dbo].[AIChatMessages]([EmployeeId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_AIChatMessages_SessionId]
    ON [dbo].[AIChatMessages]([SessionId] ASC);


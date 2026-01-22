CREATE TABLE [dbo].[PartTimeLifeMapper] (
    [Id]                  BIGINT IDENTITY (1, 1) NOT NULL,
    [PurchaseOrderPartId] BIGINT NOT NULL,
    [TimeLifeCyclesId]    BIGINT NOT NULL,
    CONSTRAINT [PK__PartTime__3214EC07FEFEECC4] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK__PartTimeL__Purch__5C835C1E] FOREIGN KEY ([PurchaseOrderPartId]) REFERENCES [dbo].[PurchaseOrderPart] ([PurchaseOrderPartRecordId]),
    CONSTRAINT [FK__PartTimeL__TimeL__5D778057] FOREIGN KEY ([TimeLifeCyclesId]) REFERENCES [dbo].[TimeLife] ([TimeLifeCyclesId])
);


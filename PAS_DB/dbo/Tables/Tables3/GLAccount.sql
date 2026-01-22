CREATE TABLE [dbo].[GLAccount] (
    [GLAccountId]                 BIGINT          IDENTITY (1, 1) NOT NULL,
    [OldAccountCode]              VARCHAR (30)    NULL,
    [AccountCode]                 VARCHAR (50)    NOT NULL,
    [AccountName]                 VARCHAR (100)   NULL,
    [AccountDescription]          VARCHAR (500)   NULL,
    [AllowManualJE]               BIT             CONSTRAINT [GLAccount_DC_AllowManualJE] DEFAULT ((0)) NOT NULL,
    [GLAccountTypeId]             BIGINT          NOT NULL,
    [GLClassFlowClassificationId] BIGINT          NOT NULL,
    [MasterCompanyId]             INT             NOT NULL,
    [CreatedBy]                   VARCHAR (256)   NOT NULL,
    [UpdatedBy]                   VARCHAR (256)   NOT NULL,
    [CreatedDate]                 DATETIME2 (7)   CONSTRAINT [GLAccount_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)   CONSTRAINT [GLAccount_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT             CONSTRAINT [DF__GLAccount__IsAct__60A067CA] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT             CONSTRAINT [DF__GLAccount__IsDel__61948C03] DEFAULT ((0)) NOT NULL,
    [POROCategoryId]              BIGINT          NULL,
    [GLAccountNodeId]             BIGINT          NULL,
    [LedgerId]                    BIGINT          NULL,
    [LedgerName]                  VARCHAR (30)    NULL,
    [InterCompany]                BIT             CONSTRAINT [GLAccount_DC_InterCompany] DEFAULT ((0)) NOT NULL,
    [Category1099Id]              BIGINT          NULL,
    [Threshold]                   DECIMAL (18, 2) NULL,
    [IsManualJEReference]         BIT             NULL,
    [ReferenceTypeId]             INT             NULL,
    [SubLedgerId]                 INT             NULL,
    [QuickBooksReferenceId]       VARCHAR (200)   NULL,
    [IsUpdated]                   BIT             NULL,
    [LastSyncDate]                DATETIME2 (7)   NULL,
    [SyncToken]                   VARCHAR (200)   NULL,
    CONSTRAINT [PK_GLAccount] PRIMARY KEY CLUSTERED ([GLAccountId] ASC),
    CONSTRAINT [FK_GLAccount_Category1099Id] FOREIGN KEY ([Category1099Id]) REFERENCES [dbo].[Master1099] ([Master1099Id]),
    CONSTRAINT [FK_GLAccount_GLAccountClass] FOREIGN KEY ([GLAccountTypeId]) REFERENCES [dbo].[GLAccountClass] ([GLAccountClassId]),
    CONSTRAINT [FK_GLAccount_GLClassFlowClassification] FOREIGN KEY ([GLClassFlowClassificationId]) REFERENCES [dbo].[GLCashFlowClassification] ([GLClassFlowClassificationId]),
    CONSTRAINT [FK_GLAccount_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_GLAccount_poroCategory] FOREIGN KEY ([POROCategoryId]) REFERENCES [dbo].[POROCategory] ([POROCategoryId]),
    CONSTRAINT [Unique_GLAccount] UNIQUE NONCLUSTERED ([AccountCode] ASC, [MasterCompanyId] ASC)
);


GO
CREATE   TRIGGER [dbo].[Trg_GLAccountAudit]
ON dbo.GLAccount
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO GLAccountAudit
    SELECT * FROM Inserted;

    DECLARE @GLs TABLE (
        GLAccountId BIGINT,
        MasterCompanyId INT,
        NewName   NVARCHAR(400)
    );

    INSERT INTO @GLs (GLAccountId, MasterCompanyId, NewName)
    SELECT DISTINCT
        I.GLAccountId,
        I.MasterCompanyId,
        ISNULL(I.AccountCode,'') + ' - ' + ISNULL(I.AccountName,'')
    FROM Inserted I
    WHERE I.GLAccountId IS NOT NULL;

    --------------------------------------------------------------------
    -- Build list of ItemMaster rows that actually need update
    --------------------------------------------------------------------
    DECLARE @IMToUpdate TABLE (ItemMasterId BIGINT PRIMARY KEY);

    INSERT INTO @IMToUpdate (ItemMasterId)
    SELECT DISTINCT IM.ItemMasterId
    FROM dbo.ItemMaster IM with(nolock)
    INNER JOIN @GLs G
        ON IM.MasterCompanyId = G.MasterCompanyId
       AND (
			(IM.GLAccountId       = G.GLAccountId AND ISNULL(IM.GLAccount,'') <> ISNULL(G.NewName,'')) OR
            (IM.GoodsReceivedNotInvoicesGLAccId       = G.GLAccountId AND ISNULL(IM.goodsReceivedNotInvoicesGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (IM.WorkInProgressGLAccId                 = G.GLAccountId AND ISNULL(IM.WorkInProgressGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (IM.InventoryToBillGLAccId                = G.GLAccountId AND ISNULL(IM.InventoryToBillGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (IM.FinishedGoodsGLAccId                  = G.GLAccountId AND ISNULL(IM.FinishedGoodsGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (IM.InventoryExchAgreementGLAccId         = G.GLAccountId AND ISNULL(IM.InventoryExchAgreementGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (IM.InventoryReserveGLAccId               = G.GLAccountId AND ISNULL(IM.InventoryReserveGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (IM.COGS_WorkOrderGLAccId                 = G.GLAccountId AND ISNULL(IM.COGS_WorkOrderGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (IM.COGS_SalesOrderGLAccId                = G.GLAccountId AND ISNULL(IM.COGS_SalesOrderGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (IM.COGS_QtyVarianceGLAccId               = G.GLAccountId AND ISNULL(IM.COGS_QtyVarianceGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (IM.COGS_UnitCostVarianceGLAccId          = G.GLAccountId AND ISNULL(IM.COGS_UnitCostVarianceGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (IM.RevenueMroGLAccId                     = G.GLAccountId AND ISNULL(IM.RevenueMroGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (IM.RevenueSoGLAccId                      = G.GLAccountId AND ISNULL(IM.RevenueSoGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (IM.RevenueExchGLAccId                    = G.GLAccountId AND ISNULL(IM.RevenueExchGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (IM.COGS_ExchSalesOrderGLAccId            = G.GLAccountId AND ISNULL(IM.COGS_ExchSalesOrderGLAccName,'') <> ISNULL(G.NewName,''))
       );

    --------------------------------------------------------------------
    -- Update only those ItemMaster rows (do set-based update)
    --------------------------------------------------------------------
    UPDATE IM
    SET
		GLAccount =
            CASE WHEN IM.GLAccountId = G.GLAccountId THEN G.NewName ELSE IM.GLAccount END,
        goodsReceivedNotInvoicesGLAccName =
            CASE WHEN IM.GoodsReceivedNotInvoicesGLAccId = G.GLAccountId THEN G.NewName ELSE IM.goodsReceivedNotInvoicesGLAccName END,
        WorkInProgressGLAccName =
            CASE WHEN IM.WorkInProgressGLAccId = G.GLAccountId THEN G.NewName ELSE IM.WorkInProgressGLAccName END,
        InventoryToBillGLAccName =
            CASE WHEN IM.InventoryToBillGLAccId = G.GLAccountId THEN G.NewName ELSE IM.InventoryToBillGLAccName END,
        FinishedGoodsGLAccName =
            CASE WHEN IM.FinishedGoodsGLAccId = G.GLAccountId THEN G.NewName ELSE IM.FinishedGoodsGLAccName END,
        InventoryExchAgreementGLAccName =
            CASE WHEN IM.InventoryExchAgreementGLAccId = G.GLAccountId THEN G.NewName ELSE IM.InventoryExchAgreementGLAccName END,
        InventoryReserveGLAccName =
            CASE WHEN IM.InventoryReserveGLAccId = G.GLAccountId THEN G.NewName ELSE IM.InventoryReserveGLAccName END,
        COGS_WorkOrderGLAccName =
            CASE WHEN IM.COGS_WorkOrderGLAccId = G.GLAccountId THEN G.NewName ELSE IM.COGS_WorkOrderGLAccName END,
        COGS_SalesOrderGLAccName =
            CASE WHEN IM.COGS_SalesOrderGLAccId = G.GLAccountId THEN G.NewName ELSE IM.COGS_SalesOrderGLAccName END,
        COGS_QtyVarianceGLAccName =
            CASE WHEN IM.COGS_QtyVarianceGLAccId = G.GLAccountId THEN G.NewName ELSE IM.COGS_QtyVarianceGLAccName END,
        COGS_UnitCostVarianceGLAccName =
            CASE WHEN IM.COGS_UnitCostVarianceGLAccId = G.GLAccountId THEN G.NewName ELSE IM.COGS_UnitCostVarianceGLAccName END,
        RevenueMroGLAccName =
            CASE WHEN IM.RevenueMroGLAccId = G.GLAccountId THEN G.NewName ELSE IM.RevenueMroGLAccName END,
        RevenueSoGLAccName =
            CASE WHEN IM.RevenueSoGLAccId = G.GLAccountId THEN G.NewName ELSE IM.RevenueSoGLAccName END,
        RevenueExchGLAccName =
            CASE WHEN IM.RevenueExchGLAccId = G.GLAccountId THEN G.NewName ELSE IM.RevenueExchGLAccName END,
        COGS_ExchSalesOrderGLAccName =
            CASE WHEN IM.COGS_ExchSalesOrderGLAccId = G.GLAccountId THEN G.NewName ELSE IM.COGS_ExchSalesOrderGLAccName END
    FROM dbo.ItemMaster IM with(nolock)
    INNER JOIN @IMToUpdate T ON IM.ItemMasterId = T.ItemMasterId
    INNER JOIN @GLs G ON G.MasterCompanyId = IM.MasterCompanyId
        AND G.GLAccountId IN (
			IM.GLAccountId,
            IM.GoodsReceivedNotInvoicesGLAccId,
            IM.WorkInProgressGLAccId,
            IM.InventoryToBillGLAccId,
            IM.FinishedGoodsGLAccId,
            IM.InventoryExchAgreementGLAccId,
            IM.InventoryReserveGLAccId,
            IM.COGS_WorkOrderGLAccId,
            IM.COGS_SalesOrderGLAccId,
            IM.COGS_QtyVarianceGLAccId,
            IM.COGS_UnitCostVarianceGLAccId,
            IM.RevenueMroGLAccId,
            IM.RevenueSoGLAccId,
            IM.RevenueExchGLAccId,
            IM.COGS_ExchSalesOrderGLAccId
        );

    --------------------------------------------------------------------
    -- Same approach for StockLine
    --------------------------------------------------------------------
    DECLARE @SLToUpdate TABLE (StockLineId BIGINT PRIMARY KEY);

    INSERT INTO @SLToUpdate (StockLineId)
    SELECT DISTINCT SL.StockLineId
    FROM dbo.StockLine SL with(nolock)
    INNER JOIN @GLs G
        ON SL.MasterCompanyId = G.MasterCompanyId
       AND (
			(SL.GLAccountId    = G.GLAccountId AND ISNULL(SL.GlAccountName,'') <> ISNULL(G.NewName,'')) OR
            (SL.GoodsReceivedNotInvoicesGLAccId    = G.GLAccountId AND ISNULL(SL.goodsReceivedNotInvoicesGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (SL.WorkInProgressGLAccId              = G.GLAccountId AND ISNULL(SL.WorkInProgressGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (SL.InventoryToBillGLAccId             = G.GLAccountId AND ISNULL(SL.InventoryToBillGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (SL.FinishedGoodsGLAccId               = G.GLAccountId AND ISNULL(SL.FinishedGoodsGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (SL.InventoryExchAgreementGLAccId      = G.GLAccountId AND ISNULL(SL.InventoryExchAgreementGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (SL.InventoryReserveGLAccId            = G.GLAccountId AND ISNULL(SL.InventoryReserveGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (SL.COGS_WorkOrderGLAccId              = G.GLAccountId AND ISNULL(SL.COGS_WorkOrderGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (SL.COGS_SalesOrderGLAccId             = G.GLAccountId AND ISNULL(SL.COGS_SalesOrderGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (SL.COGS_QtyVarianceGLAccId            = G.GLAccountId AND ISNULL(SL.COGS_QtyVarianceGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (SL.COGS_UnitCostVarianceGLAccId       = G.GLAccountId AND ISNULL(SL.COGS_UnitCostVarianceGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (SL.RevenueMroGLAccId                  = G.GLAccountId AND ISNULL(SL.RevenueMroGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (SL.RevenueSoGLAccId                   = G.GLAccountId AND ISNULL(SL.RevenueSoGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (SL.RevenueExchGLAccId                 = G.GLAccountId AND ISNULL(SL.RevenueExchGLAccName,'') <> ISNULL(G.NewName,'')) OR
            (SL.COGS_ExchSalesOrderGLAccId         = G.GLAccountId AND ISNULL(SL.COGS_ExchSalesOrderGLAccName,'') <> ISNULL(G.NewName,''))
       )
	   WHERE ISNULL(SL.QuantityOnHand,0) > 0 or ISNULL(SL.QuantityAvailable,0) > 0;

    UPDATE SL
    SET
		GlAccountName =
            CASE WHEN SL.GLAccountId = G.GLAccountId THEN G.NewName ELSE SL.GlAccountName END,
        goodsReceivedNotInvoicesGLAccName =
            CASE WHEN SL.GoodsReceivedNotInvoicesGLAccId = G.GLAccountId THEN G.NewName ELSE SL.goodsReceivedNotInvoicesGLAccName END,
        WorkInProgressGLAccName =
            CASE WHEN SL.WorkInProgressGLAccId = G.GLAccountId THEN G.NewName ELSE SL.WorkInProgressGLAccName END,
        InventoryToBillGLAccName =
            CASE WHEN SL.InventoryToBillGLAccId = G.GLAccountId THEN G.NewName ELSE SL.InventoryToBillGLAccName END,
        FinishedGoodsGLAccName =
            CASE WHEN SL.FinishedGoodsGLAccId = G.GLAccountId THEN G.NewName ELSE SL.FinishedGoodsGLAccName END,
        InventoryExchAgreementGLAccName =
            CASE WHEN SL.InventoryExchAgreementGLAccId = G.GLAccountId THEN G.NewName ELSE SL.InventoryExchAgreementGLAccName END,
        InventoryReserveGLAccName =
            CASE WHEN SL.InventoryReserveGLAccId = G.GLAccountId THEN G.NewName ELSE SL.InventoryReserveGLAccName END,
        COGS_WorkOrderGLAccName =
            CASE WHEN SL.COGS_WorkOrderGLAccId = G.GLAccountId THEN G.NewName ELSE SL.COGS_WorkOrderGLAccName END,
        COGS_SalesOrderGLAccName =
            CASE WHEN SL.COGS_SalesOrderGLAccId = G.GLAccountId THEN G.NewName ELSE SL.COGS_SalesOrderGLAccName END,
        COGS_QtyVarianceGLAccName =
            CASE WHEN SL.COGS_QtyVarianceGLAccId = G.GLAccountId THEN G.NewName ELSE SL.COGS_QtyVarianceGLAccName END,
        COGS_UnitCostVarianceGLAccName =
            CASE WHEN SL.COGS_UnitCostVarianceGLAccId = G.GLAccountId THEN G.NewName ELSE SL.COGS_UnitCostVarianceGLAccName END,
        RevenueMroGLAccName =
            CASE WHEN SL.RevenueMroGLAccId = G.GLAccountId THEN G.NewName ELSE SL.RevenueMroGLAccName END,
        RevenueSoGLAccName =
            CASE WHEN SL.RevenueSoGLAccId = G.GLAccountId THEN G.NewName ELSE SL.RevenueSoGLAccName END,
        RevenueExchGLAccName =
            CASE WHEN SL.RevenueExchGLAccId = G.GLAccountId THEN G.NewName ELSE SL.RevenueExchGLAccName END,
        COGS_ExchSalesOrderGLAccName =
            CASE WHEN SL.COGS_ExchSalesOrderGLAccId = G.GLAccountId THEN G.NewName ELSE SL.COGS_ExchSalesOrderGLAccName END
    FROM dbo.StockLine SL with(nolock)
    INNER JOIN @SLToUpdate T ON SL.StockLineId = T.StockLineId
    INNER JOIN @GLs G ON G.MasterCompanyId = SL.MasterCompanyId
        AND G.GLAccountId IN (
			SL.GLAccountId,
            SL.GoodsReceivedNotInvoicesGLAccId,
            SL.WorkInProgressGLAccId,
            SL.InventoryToBillGLAccId,
            SL.FinishedGoodsGLAccId,
            SL.InventoryExchAgreementGLAccId,
            SL.InventoryReserveGLAccId,
            SL.COGS_WorkOrderGLAccId,
            SL.COGS_SalesOrderGLAccId,
            SL.COGS_QtyVarianceGLAccId,
            SL.COGS_UnitCostVarianceGLAccId,
            SL.RevenueMroGLAccId,
            SL.RevenueSoGLAccId,
            SL.RevenueExchGLAccId,
            SL.COGS_ExchSalesOrderGLAccId
        )
		WHERE ISNULL(SL.QuantityOnHand,0) > 0 or ISNULL(SL.QuantityAvailable,0) > 0;

END;
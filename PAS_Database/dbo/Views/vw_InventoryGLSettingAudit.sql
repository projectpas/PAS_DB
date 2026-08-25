CREATE   VIEW [dbo].[vw_InventoryGLSettingAudit]
AS
SELECT InventoryGLSettingAuditId AS PkID,
InventoryGLSettingId AS ID,
CASE WHEN IGS.IsStock = 1 THEN 'Stock' ELSE 'Non-Stock' END AS [Stock Type],
IGS.StockInventoryName AS [Item Accounting Type],
GLInv.AccountName AS [Acquired GL Account],
GLGoods.AccountName AS [GRNI],
GLWip.AccountName AS [WIP],
GLTobill.AccountName AS [Inventory To Bill],
GLFisnish.AccountName AS [Finished Goods],
GLExch.AccountName AS [Inventory-Exchange Agreement],
GLRes.AccountName AS [Inventory Reserve],
GLWo.AccountName AS [Cost Of Goods Sold (COGS)-Work Order],
GLSo.AccountName AS [Cost Of Goods Sold (COGS)-Sales Order],
GLExSo.AccountName AS [Cost Of Goods Sold (COGS)-Exchange Sales Order],
GLQty.AccountName AS [Cost Of Goods Sold (COGS)-Qty Variance],
GLUc.AccountName AS [Cost Of Goods Sold (COGS)-Unit Cost Variance],
GLMro.AccountName AS [Revenue-MRO],
GLRso.AccountName AS [Revenue-Sales Order],
GLMisc.AccountName AS [Revenue-Sales Order Exchange],
IGS.CreatedBy AS [Created By], IGS.UpdatedBy AS [Updated By],
IGS.CreatedDate AS [Created Date], IGS.UpdatedDate AS [Updated Date],
IGS.Memo, IGS.IsActive AS [Is Active], IGS.IsDeleted AS [Is Deleted]
FROM [DBO].[InventoryGLSettingAudit] IGS WITH (NOLOCK)  
 LEFT JOIN [DBO].[View_GLAccount] GLInv WITH (NOLOCK) ON IGS.InventoryGLAccId = GLInv.GLAccountId 
 LEFT JOIN [DBO].[View_GLAccount] GLGoods WITH (NOLOCK) ON IGS.GoodsReceivedNotInvoicesGLAccId = GLGoods.GLAccountId
 LEFT JOIN [DBO].[View_GLAccount] GLWip WITH (NOLOCK) ON IGS.WorkInProgressGLAccId = GLWip.GLAccountId
 LEFT JOIN [DBO].[View_GLAccount] GLTobill WITH (NOLOCK) ON IGS.InventoryToBillGLAccId = GLTobill.GLAccountId
 LEFT JOIN [DBO].[View_GLAccount] GLFisnish WITH (NOLOCK) ON IGS.FinishedGoodsGLAccId = GLFisnish.GLAccountId
 LEFT JOIN [DBO].[View_GLAccount] GLExch WITH (NOLOCK) ON IGS.InventoryExchAgreementGLAccId = GLExch.GLAccountId
 LEFT JOIN [DBO].[View_GLAccount] GLRes WITH (NOLOCK) ON IGS.InventoryReserveGLAccId = GLRes.GLAccountId
 LEFT JOIN [DBO].[View_GLAccount] GLWo WITH (NOLOCK) ON IGS.COGS_WorkOrderGLAccId = GLWo.GLAccountId
 LEFT JOIN [DBO].[View_GLAccount] GLSo WITH (NOLOCK) ON IGS.COGS_SalesOrderGLAccId = GLSo.GLAccountId
 LEFT JOIN [DBO].[View_GLAccount] GLExSo WITH (NOLOCK) ON IGS.COGS_ExchSalesOrderGLAccId = GLExSo.GLAccountId
 LEFT JOIN [DBO].[View_GLAccount] GLQty WITH (NOLOCK) ON IGS.COGS_QtyVarianceGLAccId = GLQty.GLAccountId
 LEFT JOIN [DBO].[View_GLAccount] GLUc WITH (NOLOCK) ON IGS.COGS_UnitCostVarianceGLAccId = GLUc.GLAccountId
 LEFT JOIN [DBO].[View_GLAccount] GLMro WITH (NOLOCK) ON IGS.RevenueMroGLAccId = GLMro.GLAccountId
 LEFT JOIN [DBO].[View_GLAccount] GLRso WITH (NOLOCK) ON IGS.RevenueSoGLAccId = GLRso.GLAccountId
 LEFT JOIN [DBO].[View_GLAccount] GLMisc WITH (NOLOCK) ON IGS.RevenueExchGLAccId = GLMisc.GLAccountId
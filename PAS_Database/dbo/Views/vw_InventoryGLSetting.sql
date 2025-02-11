





CREATE           VIEW [dbo].[vw_InventoryGLSetting]
AS
SELECT IGS.InventoryGLSettingId,
IGS.StockInventoryName,
IGS.InventoryGLAccId,
GLInv.AccountName AS InventoryGLAccName,
IGS.GoodsReceivedNotInvoicesGLAccId,
GLGoods.AccountName AS GoodsReceivedNotInvoicesGLAccName,
IGS.WorkInProgressGLAccId,
GLWip.AccountName AS WorkInProgressGLAccName,
IGS.InventoryToBillGLAccId,
GLTobill.AccountName AS InventoryToBillGLAccName,
IGS.FinishedGoodsGLAccId,
GLFisnish.AccountName AS FinishedGoodsGLAccName,
IGS.InventoryExchAgreementGLAccId,
GLExch.AccountName AS InventoryExchAgreementGLAccName,
IGS.InventoryReserveGLAccId,
GLRes.AccountName AS InventoryReserveGLAccName,
IGS.COGS_WorkOrderGLAccId,
GLWo.AccountName AS COGS_WorkOrderGLAccName,
IGS.COGS_SalesOrderGLAccId,
GLSo.AccountName AS COGS_SalesOrderGLAccName,
IGS.COGS_ExchSalesOrderGLAccId,
GLExSo.AccountName AS COGS_ExchSalesOrderGLAccName,
IGS.COGS_QtyVarianceGLAccId,
GLQty.AccountName AS COGS_QtyVarianceGLAccName,
IGS.COGS_UnitCostVarianceGLAccId,
GLUc.AccountName AS COGS_UnitCostVarianceGLAccName,
IGS.RevenueMroGLAccId,
GLMro.AccountName AS RevenueMroGLAccName,
IGS.RevenueSoGLAccId,
GLMisc.AccountName AS RevenueSoGLAccName,
IGS.RevenueExchGLAccId,
GLGoods.AccountName AS RevenueExchGLAccName,
IGS.MasterCompanyId, IGS.CreatedBy, IGS.UpdatedBy, IGS.CreatedDate, IGS.UpdatedDate,IGS.Memo, IGS.IsActive, IGS.IsDeleted
FROM [DBO].[InventoryGLSetting] IGS WITH (NOLOCK)  
 LEFT JOIN [DBO].[view_GLAccount] GLInv WITH (NOLOCK) ON IGS.InventoryGLAccId = GLInv.GLAccountId 
 LEFT JOIN [DBO].[view_GLAccount] GLGoods WITH (NOLOCK) ON IGS.GoodsReceivedNotInvoicesGLAccId = GLGoods.GLAccountId
 LEFT JOIN [DBO].[view_GLAccount] GLWip WITH (NOLOCK) ON IGS.WorkInProgressGLAccId = GLWip.GLAccountId
 LEFT JOIN [DBO].[view_GLAccount] GLTobill WITH (NOLOCK) ON IGS.InventoryToBillGLAccId = GLTobill.GLAccountId
 LEFT JOIN [DBO].[view_GLAccount] GLFisnish WITH (NOLOCK) ON IGS.FinishedGoodsGLAccId = GLFisnish.GLAccountId
 LEFT JOIN [DBO].[view_GLAccount] GLExch WITH (NOLOCK) ON IGS.InventoryExchAgreementGLAccId = GLExch.GLAccountId
 LEFT JOIN [DBO].[view_GLAccount] GLRes WITH (NOLOCK) ON IGS.InventoryReserveGLAccId = GLRes.GLAccountId
 LEFT JOIN [DBO].[view_GLAccount] GLWo WITH (NOLOCK) ON IGS.COGS_WorkOrderGLAccId = GLWo.GLAccountId
 LEFT JOIN [DBO].[view_GLAccount] GLSo WITH (NOLOCK) ON IGS.COGS_SalesOrderGLAccId = GLSo.GLAccountId
 LEFT JOIN [DBO].[view_GLAccount] GLExSo WITH (NOLOCK) ON IGS.COGS_SalesOrderGLAccId = GLExSo.GLAccountId
 LEFT JOIN [DBO].[view_GLAccount] GLQty WITH (NOLOCK) ON IGS.COGS_QtyVarianceGLAccId = GLQty.GLAccountId
 LEFT JOIN [DBO].[view_GLAccount] GLUc WITH (NOLOCK) ON IGS.COGS_UnitCostVarianceGLAccId = GLUc.GLAccountId
 LEFT JOIN [DBO].[view_GLAccount] GLMro WITH (NOLOCK) ON IGS.RevenueMroGLAccId = GLMro.GLAccountId
 LEFT JOIN [DBO].[view_GLAccount] GLRso WITH (NOLOCK) ON IGS.RevenueSoGLAccId = GLRso.GLAccountId
 LEFT JOIN [DBO].[view_GLAccount] GLMisc WITH (NOLOCK) ON IGS.RevenueExchGLAccId = GLMisc.GLAccountId
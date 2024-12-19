




CREATE     VIEW [dbo].[vw_InventoryGLSettingAudit]
AS
SELECT InventoryGLSettingAuditId  AS PkID,
InventoryGLSettingId AS ID,
IGS.StockInventoryName,
GLInv.AccountName AS InventoryGLAccName,
GLGoods.AccountName AS GoodsReceivedNotInvoicesGLAccName,
GLWip.AccountName AS WorkInProgressGLAccName,
GLTobill.AccountName AS InventoryToBillGLAccName,
GLFisnish.AccountName AS FinishedGoodsGLAccName,
GLExch.AccountName AS InventoryExchAgreementGLAccName,
GLRes.AccountName AS InventoryReserveGLAccName,
GLWo.AccountName AS COGS_WorkOrderGLAccName,
GLSo.AccountName AS COGS_SalesOrderGLAccName,
GLQty.AccountName AS COGS_QtyVarianceGLAccName,
GLUc.AccountName AS COGS_UnitCostVarianceGLAccName,
GLMro.AccountName AS RevenueMroGLAccName,
GLMisc.AccountName AS RevenueSoGLAccName,
GLGoods.AccountName AS RevenueMiscGLAccName,IGS.CreatedBy, IGS.UpdatedBy, IGS.CreatedDate, IGS.UpdatedDate,IGS.Memo, IGS.IsActive, IGS.IsDeleted
FROM [DBO].[InventoryGLSettingAudit] IGS WITH (NOLOCK)  
 LEFT JOIN [DBO].[GLAccount] GLInv WITH (NOLOCK) ON IGS.InventoryGLAccId = GLInv.GLAccountId 
 LEFT JOIN [DBO].[GLAccount] GLGoods WITH (NOLOCK) ON IGS.GoodsReceivedNotInvoicesGLAccId = GLGoods.GLAccountId
 LEFT JOIN [DBO].[GLAccount] GLWip WITH (NOLOCK) ON IGS.WorkInProgressGLAccId = GLWip.GLAccountId
 LEFT JOIN [DBO].[GLAccount] GLTobill WITH (NOLOCK) ON IGS.InventoryToBillGLAccId = GLTobill.GLAccountId
 LEFT JOIN [DBO].[GLAccount] GLFisnish WITH (NOLOCK) ON IGS.FinishedGoodsGLAccId = GLFisnish.GLAccountId
 LEFT JOIN [DBO].[GLAccount] GLExch WITH (NOLOCK) ON IGS.InventoryExchAgreementGLAccId = GLExch.GLAccountId
 LEFT JOIN [DBO].[GLAccount] GLRes WITH (NOLOCK) ON IGS.InventoryReserveGLAccId = GLRes.GLAccountId
 LEFT JOIN [DBO].[GLAccount] GLWo WITH (NOLOCK) ON IGS.COGS_WorkOrderGLAccId = GLWo.GLAccountId
 LEFT JOIN [DBO].[GLAccount] GLSo WITH (NOLOCK) ON IGS.COGS_SalesOrderGLAccId = GLSo.GLAccountId
 LEFT JOIN [DBO].[GLAccount] GLQty WITH (NOLOCK) ON IGS.COGS_QtyVarianceGLAccId = GLQty.GLAccountId
 LEFT JOIN [DBO].[GLAccount] GLUc WITH (NOLOCK) ON IGS.COGS_UnitCostVarianceGLAccId = GLUc.GLAccountId
 LEFT JOIN [DBO].[GLAccount] GLMro WITH (NOLOCK) ON IGS.RevenueMroGLAccId = GLMro.GLAccountId
 LEFT JOIN [DBO].[GLAccount] GLRso WITH (NOLOCK) ON IGS.RevenueSoGLAccId = GLRso.GLAccountId
 LEFT JOIN [DBO].[GLAccount] GLMisc WITH (NOLOCK) ON IGS.RevenueMiscGLAccId = GLMisc.GLAccountId
            
            
              
/*************************************************************                         
 ** File:   [[usp_GetGLDetailsByInventoryClass]]                         
 ** Author:   Bhavesh Raval                
 ** Description: Get GL Details By Inventory Class/Attribute               
 ** Purpose: Get GL Details By Inventory Class/Attribute                      
 ** Date:   19-Dec-2024                     
                        
 ** PARAMETERS:   @inventoryglsettingid int                        
                       
 ** RETURN VALUE:   query result                      
                
 **************************************************************                         
  ** Change History                         
 **************************************************************                         
 ** S NO   Date         Author    Change Description                          
 ** --   --------     -------    --------------------------------                        
     1    07-01-25    Bhavesh Raval   Get Glaaccount by InventoryGlSettingId    
     2    21-01-25    Bhavesh Raval   Remove Name and Notes Columns              
**************************************************************/              
--exec  [dbo].[usp_GetGLDetailsByInventoryClass] 1             
             
CREATE        PROCEDURE [dbo].[usp_GetGLDetailsByInventoryClass]             
@InventoryGLSettingId int            
AS              
BEGIN              
  SET NOCOUNT ON;              
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED              
              
  BEGIN TRY              
              
   SELECT           
   I.InventoryGLSettingId,           
   I.[StockInventoryName] AS InventoryGLSettingName,                    
 -- (select TOP 1 GLAccountId from ItemMaster IM where IM.InventoryGLSettingId =I.InventoryGLSettingId)       
  I.InventoryGLAccId AS InventoryGLAccId,      
 -- (select GLAccount from ItemMaster IM where IM.InventoryGLSettingId =I.InventoryGLSettingId)      
    GL1.AccountCode + '-' + GL1.AccountName AS InventoryGLAccName,              
   I.GoodsReceivedNotInvoicesGLAccId,           
   GL2.AccountCode + '-' + GL2.AccountName AS GoodsReceivedNotInvoicesGLAccName,              
   I.WorkInProgressGLAccId,           
   GL3.AccountCode + '-' + GL3.AccountName AS WorkInProgressGLAccName,              
   I.InventoryToBillGLAccId,           
   GL4.AccountCode + '-' + GL4.AccountName AS InventoryToBillGLAccName,              
   I.FinishedGoodsGLAccId,           
   GL5.AccountCode + '-' + GL5.AccountName AS FinishedGoodsGLAccName,              
   I.InventoryExchAgreementGLAccId,           
   GL6.AccountCode + '-' + GL6.AccountName AS InventoryExchAgreementGLAccName,              
   I.InventoryReserveGLAccId,            
   GL7.AccountCode + '-' + GL7.AccountName AS InventoryReserveGLAccName,              
   I.COGS_WorkOrderGLAccId,           
   GL8.AccountCode + '-' + GL8.AccountName AS COGS_WorkOrderGLAccName,              
   I.COGS_SalesOrderGLAccId,           
   GL9.AccountCode + '-' + GL9.AccountName AS COGS_SalesOrderGLAccName,              
   I.COGS_QtyVarianceGLAccId,           
   GL10.AccountCode + '-' + GL10.AccountName AS COGS_QtyVarianceGLAccName,              
   I.COGS_UnitCostVarianceGLAccId,           
   GL11.AccountCode + '-' + GL11.AccountName AS COGS_UnitCostVarianceGLAccName,              
   I.RevenueMroGLAccId,           
   GL12.AccountCode + '-' + GL12.AccountName AS RevenueMroGLAccName,              
   I.RevenueSoGLAccId,           
   GL13.AccountCode + '-' + GL13.AccountName AS RevenueSoGLAccName,              
   I.RevenueExchGLAccId,           
   GL14.AccountCode + '-' + GL14.AccountName AS RevenueExchGLAccName,      
   I.COGS_ExchSalesOrderGLAccId,           
   GL15.AccountCode + '-' + GL15.AccountName AS COGS_ExchSalesOrderGLAccName,      
   I.CreatedBy,          
   I.UpdatedBy,          
   I.CreatedDate,          
   I.UpdatedDate,          
   I.IsActive,          
   I.IsDeleted            
  FROM           
   InventoryGLSetting I WITH (NOLOCK)          
  LEFT JOIN          
   GLAccount GL1 WITH (NOLOCK) ON I.InventoryGLAccId = GL1.GLAccountId           
  LEFT JOIN           
   GLAccount GL2 WITH (NOLOCK) ON I.GoodsReceivedNotInvoicesGLAccId = GL2.GLAccountId           
  LEFT JOIN           
   GLAccount GL3 WITH (NOLOCK) ON I.WorkInProgressGLAccId = GL3.GLAccountId           
  LEFT JOIN           
   GLAccount GL4 WITH (NOLOCK) ON I.InventoryToBillGLAccId = GL4.GLAccountId           
  LEFT JOIN           
   GLAccount GL5 WITH (NOLOCK) ON I.FinishedGoodsGLAccId = GL5.GLAccountId           
  LEFT JOIN           
   GLAccount GL6 WITH (NOLOCK) ON I.InventoryExchAgreementGLAccId = GL6.GLAccountId           
  LEFT JOIN           
   GLAccount GL7 WITH (NOLOCK) ON I.InventoryReserveGLAccId = GL7.GLAccountId           
  LEFT JOIN           
   GLAccount GL8 WITH (NOLOCK) ON I.COGS_WorkOrderGLAccId = GL8.GLAccountId           
  LEFT JOIN           
   GLAccount GL9 WITH (NOLOCK) ON I.COGS_SalesOrderGLAccId = GL9.GLAccountId           
  LEFT JOIN           
   GLAccount GL10 WITH (NOLOCK) ON I.COGS_QtyVarianceGLAccId = GL10.GLAccountId           
  LEFT JOIN           
   GLAccount GL11 WITH (NOLOCK) ON I.COGS_UnitCostVarianceGLAccId = GL11.GLAccountId           
  LEFT JOIN           
   GLAccount GL12 WITH (NOLOCK) ON I.RevenueMroGLAccId = GL12.GLAccountId           
  LEFT JOIN           
   GLAccount GL13 WITH (NOLOCK) ON I.RevenueSoGLAccId = GL13.GLAccountId           
  LEFT JOIN           
   GLAccount GL14 WITH (NOLOCK) ON I.RevenueExchGLAccId = GL14.GLAccountId     
    LEFT JOIN           
   GLAccount GL15 WITH (NOLOCK) ON I.COGS_ExchSalesOrderGLAccId = GL15.GLAccountId     
  
  WHERE           
   I.InventoryGLSettingId = @InventoryGLSettingId          
          
  END TRY              
              
  BEGIN CATCH              
             
    DECLARE @ErrorLogID int,              
            @DatabaseName varchar(100) = DB_NAME()              
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------              
            ,              
            @AdhocComments varchar(150) = '[usp_GetGLDetailsByInventoryClass]',              
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@InventoryGLSettingId, '') AS varchar(100)) ,              
            @ApplicationName varchar(100) = 'PAS'              
              
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------              
    EXEC Splogexception @DatabaseName = @DatabaseName,              
                        @AdhocComments = @AdhocComments,              
                        @ProcedureParameters = @ProcedureParameters,              
                        @ApplicationName = @ApplicationName,              
                        @ErrorLogID = @ErrorLogID OUTPUT;              
              
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)              
              
    RETURN (1);              
  END CATCH              
              
END
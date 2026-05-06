/*************************************************************           
 ** File:   [usp_GetStockConsumeUOMByItemMasterId]           
 ** Author:   Rajesh Gami
 ** Description: This stored procedure is used get the Stock UOM, Consume UOM, Purchase UOM By ItemMasterId
 ** Purpose:         
 ** Date:  07-APR-2026
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    07-APR-2026		Rajesh Gami		Created [PN-15916]
	2    16-APR-2026		Ayushi Patel	Return StockUOMId,ConsumeUOMId [PN-16034]
	3    06-MAY-2026        Ayushi Patel    Return PurchaseUOMId [PN-15140]
EXEC [dbo].[usp_GetStockConsumeUOMByItemMasterId] 97625, 1
**************************************************************/
CREATE         PROCEDURE [dbo].[usp_GetStockConsumeUOMByItemMasterId]
@ItemMasterId BIGINT ,
@MasterCompanyId int 
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		
		SELECT 
				CASE WHEN ISNULL(StockUnitOfMeasure,'') = '' THEN  uomStock.ShortName ELSE ISNULL(StockUnitOfMeasure,'')END AS StockUOM,
			    CASE WHEN ISNULL(ConsumeUnitOfMeasure,'') = '' THEN  uomConsume.ShortName ELSE ISNULL(ConsumeUnitOfMeasure,'') END AS ConsumeUOM,
				CASE WHEN ISNULL(StockUnitOfMeasureId,'') = '' THEN uomStock.UnitOfMeasureId ELSE ISNULL(StockUnitOfMeasureId,'') END StockUOMId,
				CASE WHEN ISNULL(ConsumeUnitOfMeasureId,'') = '' THEN uomConsume.UnitOfMeasureId ELSE ISNULL(ConsumeUnitOfMeasureId,'') END ConsumeUOMId,
				CASE WHEN ISNULL(PurchaseUnitOfMeasureId,'') = '' THEN uomPurchase.UnitOfMeasureId ELSE ISNULL(PurchaseUnitOfMeasureId,'') END PurchaseUOMId,
				IM.PurchaseUnitOfMeasure as PurchaseUOM
				FROM DBO.ItemMaster IM  WITH(NOLOCK) 
									LEFT JOIN [dbo].[UnitOfMeasure] uomStock WITH(NOLOCK) ON uomStock.UnitOfMeasureId = IM.StockUnitOfMeasureId
									LEFT JOIN [dbo].[UnitOfMeasure] uomConsume WITH(NOLOCK) ON uomConsume.UnitOfMeasureId = IM.ConsumeUnitOfMeasureId
									LEFT JOIN [dbo].[UnitOfMeasure] uomPurchase WITH(NOLOCK) ON uomPurchase.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
									WHERE IM.MasterCompanyId = @MasterCompanyId AND IM.ItemMasterId = @ItemMasterId
			
	END TRY    
	BEGIN CATCH      
		DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments			VARCHAR(150)    = 'usp_GetStockConsumeUOMByItemMasterId'
		,@ProcedureParameters	VARCHAR(3000)	= ''
		,@ApplicationName		VARCHAR(100)	= 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1); 
	END CATCH
END
/*************************************************************           
 ** File:   [usp_GetStockConsumeUOMByStocklineId]           
 ** Author:   Rajesh Gami
 ** Description: This stored procedure is used get the Stock UOM, Consume UOM, Purchase UOM By StocklineId
 ** Purpose:         
 ** Date:  03-March-2026
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    03-March-2026		Rajesh Gami		Created [PN-14832]
EXEC [dbo].[usp_GetStockConsumeUOMByStocklineId]
**************************************************************/
CREATE       PROCEDURE [dbo].[usp_GetStockConsumeUOMByStocklineId]
@StocklineId BIGINT ,
@MasterCompanyId int 
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		
		SELECT 
				CASE WHEN ISNULL(StockUnitOfMeasure,'') = '' THEN  uomStock.ShortName ELSE ISNULL(StockUnitOfMeasure,'')END AS StockUOM,
			    CASE WHEN ISNULL(ConsumeUnitOfMeasure,'') = '' THEN  uomConsume.ShortName ELSE ISNULL(ConsumeUnitOfMeasure,'') END AS ConsumeUOM,
				UnitOfMeasure as PurchaseUOM
				FROM DBO.Stockline SL WITH(NOLOCK) 
									LEFT JOIN [dbo].[UnitOfMeasure] uomStock WITH(NOLOCK) ON uomStock.UnitOfMeasureId = SL.StockUnitOfMeasureId
									LEFT JOIN [dbo].[UnitOfMeasure] uomConsume WITH(NOLOCK) ON uomConsume.UnitOfMeasureId = SL.ConsumeUnitOfMeasureId
									WHERE SL.MasterCompanyId = @MasterCompanyId AND SL.StockLineId = @StocklineId
			
	END TRY    
	BEGIN CATCH      
		DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments			VARCHAR(150)    = 'usp_GetStockConsumeUOMByStocklineId'
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
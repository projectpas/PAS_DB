/*************************************************************           
 ** File:   [USP_GetWorkOrderFreightList]           
 ** Author:   Bhargav Saliya 
 ** Description: Get Data for WO MPN Data By Part Number Id   
 ** Purpose:         
 ** Date:   28-April-2025      
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author			Change Description            
 ** --   --------		 -------		--------------------------------          
    1    28-April-2025   Bhargav Saliya		Created

	
**************************************************************/
--EXEC [USP_GetWorkOrderFreightList] @WorkOrderQuoteDetailsId = 6778
CREATE   PROCEDURE [dbo].[USP_GetWorkOrderFreightList]
    @WorkOrderQuoteDetailsId BIGINT,
    @BuildMethodId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		-- First, get the WorkOrderId
		DECLARE @WorkOrderId BIGINT;

		SELECT TOP 1 @WorkOrderId = woq.WorkOrderId 
		FROM [dbo].[WorkOrderQuoteDetails] wq WITH(NOLOCK)
		INNER JOIN [dbo].[WorkOrderQuote] woq WITH(NOLOCK) ON wq.WorkOrderQuoteId = woq.WorkOrderQuoteId
		WHERE wq.IsDeleted = 0 AND wq.WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId;

		-- Now get the freight list
		SELECT DISTINCT
			wf.Amount,
			wf.CreatedBy,
			wf.CreatedDate,
			wf.IsActive,
			wf.IsDeleted,
			wf.MasterCompanyId,
			wf.Memo,
			wf.ShipViaId,
			wf.UpdatedBy,
			wf.UpdatedDate,
			wf.Weight,
			wf.WorkOrderQuoteDetailsId,
			wf.WorkOrderQuoteFreightId,
			ISNULL(cdss.ShipVia, '') AS ShipViaName,
			--(
			--	SELECT TOP 1 ShipVia 
			--	FROM CustomerDomensticShippingShipVia 
			--	WHERE CustomerDomensticShippingShipViaId = wf.ShipViaId
			--) AS ShipViaName,
			wf.MarkupPercentageId,
			wf.TaskId,
			CASE WHEN wof.WorkOrderFormTypeId = 1 THEN ISNULL(wot.TaskName, '') ELSE ISNULL(ts.Description, '') END AS TaskName,
			wf.HeaderMarkupId,
			wf.BillingMethodId,
			wf.BillingRate,
			wf.BillingAmount,
			wf.MarkupFixedPrice,
			wf.Length,
			wf.Width,
			wf.Height,
			wf.UOMId,
			wf.DimensionUOMId,
			wf.CurrencyId,
			ISNULL(uom.ShortName, '') AS UOM,
			ISNULL(duom.ShortName, '') AS DimensionUOM,
			ISNULL(cur.Code, '') AS Currency
		FROM [dbo].[WorkOrderQuoteFreight] wf WITH(NOLOCK)
			INNER JOIN [dbo].[WorkOrderQuoteDetails] wq WITH(NOLOCK) ON wf.WorkOrderQuoteDetailsId = wq.WorkOrderQuoteDetailsId
			LEFT JOIN [dbo].[Task] ts WITH(NOLOCK) ON wf.TaskId = ts.TaskId
			LEFT JOIN [dbo].[WorkOrderTask] wot WITH(NOLOCK) ON wf.TaskId = wot.WorkOrderTaskId
			INNER JOIN [dbo].[WorkOrderQuote] woq WITH(NOLOCK) ON wq.WorkOrderQuoteId = woq.WorkOrderQuoteId
			LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON wf.UOMId = uom.UnitOfMeasureId
			LEFT JOIN [dbo].[UnitOfMeasure] duom WITH(NOLOCK) ON wf.DimensionUOMId = duom.UnitOfMeasureId
			LEFT JOIN [dbo].[Currency] cur WITH(NOLOCK) ON wf.CurrencyId = cur.CurrencyId
			INNER JOIN [dbo].[WorkOrder] wof WITH(NOLOCK) ON woq.WorkOrderId = wof.WorkOrderId
			LEFT JOIN [dbo].[CustomerDomensticShippingShipVia] cdss WITH(NOLOCK) ON cdss.CustomerDomensticShippingShipViaId = wf.ShipViaId
		WHERE wf.IsDeleted = 0 AND wf.WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId;
	END TRY
	BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderFreightList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderQuoteDetailsId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH 
END
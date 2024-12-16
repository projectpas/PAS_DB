/*************************************************************             
 ** File:   [GetSalesOrderQuoteChargesAudit]            
 ** Author:  EKTA CHANDEGRA
 ** Description: This stored procedure is used GetSalesOrderQuoteChargesAudit
 ** Purpose:           
 ** Date:  16/12/2024        
            
 ** PARAMETERS: @SalesOrderQuoteChargesId bigint 
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    16/12/2024		EKTA CHANDEGRA	 Created  

 EXEC GetSalesOrderQuoteChargesAudit 281 
************************************************************************/  
CREATE   PROCEDURE [dbo].[GetSalesOrderQuoteChargesAudit]
    @SalesOrderQuoteChargesId BIGINT
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	SET NOCOUNT ON;   
	BEGIN TRY
		SELECT DISTINCT
			soc.AuditSalesOrderQuoteChargesId,
			soc.SalesOrderQuoteChargesId,
			soc.SalesOrderQuoteId,
			soc.SalesOrderQuotePartId,
			soc.ChargesTypeId,
			ct.ChargeType,
			ISNULL(soc.Description,'') AS Description,
			ISNULL(soc.Quantity,0) AS Quantity,
			ISNULL(soc.UnitCost,0) AS UnitCost,
			ISNULL(soc.ExtendedCost,0) AS ExtendedCost,
			ISNULL(soc.MarkupFixedPrice,0) AS MarkupFixedPrice,
			ISNULL(soc.VendorId,0) AS VendorId,
			ISNULL(soc.VendorName,'') AS VendorName,
			soc.BillingMethodId,
			'' AS BillingMethodName,
			ISNULL(soc.BillingRate,0) AS BillingRate,
			ISNULL(soc.BillingAmount,0) AS BillingAmount,
			ISNULL(soc.MarkupPercentageId,0) AS MarkupPercentageId,
			soc.CreatedBy,
			soc.CreatedDate,
			soc.IsActive,
			soc.IsDeleted,
			soc.MasterCompanyId,
			soc.HeaderMarkupId,
			soc.HeaderMarkupPercentageId,
			soc.UpdatedBy,
			soc.UpdatedDate,
			ISNULL(soc.RefNum,'') AS RefNum,
			ISNULL(gl.AccountName, '') AS GLAccountName,
			ISNULL(uom.ShortName, '') AS UOMName
		FROM [dbo].[SalesOrderQuoteChargesAudit] soc WITH(NOLOCK)
		INNER JOIN [dbo].[Charge] ct WITH(NOLOCK) ON soc.ChargesTypeId = ct.ChargeId
		LEFT JOIN [dbo].[GLAccount] gl WITH(NOLOCK) ON ct.GLAccountId = gl.GLAccountId
		LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON soc.UnitOfMeasureId = uom.UnitOfMeasureId
		WHERE soc.SalesOrderQuoteChargesId = @SalesOrderQuoteChargesId
		AND soc.ChargeName IS NOT NULL
		ORDER BY soc.AuditSalesOrderQuoteChargesId DESC;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetSalesOrderQuoteChargesAudit'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderQuoteChargesId, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
            RETURN(1); 
	END CATCH
END;
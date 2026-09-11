/*************************************************************             
 ** File:   [GetSalesOrderQuoteCharges]            
 ** Author:  EKTA CHANDEGRA
 ** Description: This stored procedure is used GetSalesOrderQuoteCharges
 ** Purpose:           
 ** Date:  16/12/2024        
            
 ** PARAMETERS: @SalesOrderQuoteId bigint  , @IsDeleted bit
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    16/12/2024		EKTA CHANDEGRA	 Created  
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    20/July/2026			 RAJESH GAMI						[PN-17350] - Allow Non-Stock Inventory Parts in Sales Order Quote and Sales Order: removed IsNonStock=0 filter from ItemMaster join.
	4    26/Aug/2026             Kishor Makwana                     [PN-17439] - Added Sequence Number  with Part Number 
 EXEC GetSalesOrderQuoteCharges 965 , 0
************************************************************************/  
CREATE   PROCEDURE [dbo].[GetSalesOrderQuoteCharges]
    @SalesOrderQuoteId BIGINT,
    @IsDeleted BIT
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	SET NOCOUNT ON;   
	BEGIN TRY
		SELECT DISTINCT
			soc.SalesOrderQuoteChargesId,
			soc.SalesOrderQuoteId,
			soc.SalesOrderQuotePartId,
			soc.ChargesTypeId,
			ct.ChargeType,
			soc.Description,
			soc.Quantity,
			soc.UnitCost,
			soc.ExtendedCost,
			soc.MarkupFixedPrice,
			ISNULL(soc.VendorId,0) AS VendorId,
			ISNULL(soc.VendorName,'') AS VendorName,
			soc.BillingMethodId,
			soc.BillingRate,
			soc.BillingAmount,
			soc.MarkupPercentageId,
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
			im.PartNumber,
			soc.ItemMasterId,
			--part.ItemNo,
			(CAST(part.SequenceNumber as VARCHAR(10) ) + ' - ' +im.PartNumber + ' - ' + cond.Description) AS ItemNo,
			im.PartNumber AS Pn,
			part.ConditionId,
			ISNULL(uom.ShortName, '') AS UOMName,
			ISNULL(soc.UnitOfMeasureId, 0) AS UnitOfMeasureId
		FROM [dbo].[SalesOrderQuoteCharges] soc WITH(NOLOCK)
		INNER JOIN [dbo].[Charge] ct WITH(NOLOCK) ON soc.ChargesTypeId = ct.ChargeId
		LEFT JOIN [dbo].[GLAccount] gl WITH(NOLOCK) ON ct.GLAccountId = gl.GLAccountId
		LEFT JOIN [dbo].[SalesOrderQuotePartV1] part WITH(NOLOCK) ON soc.SalesOrderQuotePartId = part.SalesOrderQuotePartId
		LEFT JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON soc.ItemMasterId = im.ItemMasterId
		LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON soc.UnitOfMeasureId = uom.UnitOfMeasureId
		INNER JOIN [dbo].[Condition] cond WITH(NOLOCK) ON soc.ConditionId = cond.ConditionId
		WHERE ISNULL(soc.IsDeleted,0) = @IsDeleted
		AND soc.SalesOrderQuoteId = @SalesOrderQuoteId;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetSalesOrderQuoteCharges'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderQuoteId, '') + '''
													 @Parameter2 = '''+ ISNULL(@IsDeleted, '') + ''
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
END
/*************************************************************           
 ** File:   [USP_GetExchangeSalesOrderChargesBySOId]          
 ** Author: EKTA CHANDEGRA
 ** Description: This stored procedure is used to USP_GetExchangeSalesOrderChargesBySOId
 ** Purpose:         
 ** Date:    06/02/2025  

 ** PARAMETERS: @ExchangeSalesOrderId BIGINT, @IsDeleted BIT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** -----------------------------------------------------------          
    1    06/02/2025  EKTA CHANDEGRA    Created
	     
 EXEC USP_GetExchangeSalesOrderChargesBySOId @ExchangeSalesOrderId = 150 , @IsDeleted = 0
************************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetExchangeSalesOrderChargesBySOId]
    @ExchangeSalesOrderId BIGINT,
    @IsDeleted BIT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT DISTINCT
			soc.ExchangeSalesOrderChargesId,
			ISNULL(soc.ExchangeSalesOrderPartId,0) AS ExchangeSalesOrderPartId,
			soc.ExchangeSalesOrderId,
			soc.ChargesTypeId,
			ct.ChargeType,
			soc.Description,
			soc.Quantity,
			soc.UnitCost,
			soc.ExtendedCost,
			ISNULL(soc.VendorId,0) AS VendorId,
			ISNULL(v.VendorName, '') AS VendorName,
			soc.HeaderMarkupPercentageId,
			soc.MarkupFixedPrice,
			soc.BillingAmount,
			soc.BillingMethodId,
			soc.HeaderMarkupId,
			soc.BillingRate,
			soc.MarkupPercentageId,
			soc.CreatedBy,
			soc.CreatedDate,
			ISNULL(soc.IsActive,0) AS IsActive,
			ISNULL(soc.IsDeleted,0) AS IsDeleted,
			soc.MasterCompanyId,
			soc.UpdatedBy,
			soc.UpdatedDate,
			ISNULL(soc.RefNum,'') AS RefNum,
			ISNULL(gl.AccountName, '') AS GLAccountName
		FROM [dbo].[ExchangeSalesOrderCharges] soc WITH(NOLOCK)
		INNER JOIN [dbo].[Charge] ct WITH(NOLOCK) ON soc.ChargesTypeId = ct.ChargeId
		LEFT JOIN [dbo].[Vendor] v WITH(NOLOCK) ON soc.VendorId = v.VendorId
		LEFT JOIN [dbo].[GLAccount] gl WITH(NOLOCK) ON ct.GLAccountId = gl.GLAccountId
		WHERE ISNULL(soc.IsDeleted,0) = @IsDeleted
		  AND soc.ExchangeSalesOrderId = @ExchangeSalesOrderId;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeSalesOrderChargesBySOId'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeSalesOrderId = ''' + CAST(ISNULL(@ExchangeSalesOrderId, '') AS VARCHAR(100)) + ''' ,
													@IsDeleted = ''' + CAST(ISNULL(@IsDeleted, '') AS VARCHAR(100)) 
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
            RETURN(1);  
	END CATCH
END
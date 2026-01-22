/*************************************************************           
    ** File:   [USP_GetCustomerTaxTypeRateMappingAudit]           
    ** Author:   Ekta Chandegra
    ** Description: This stored procedure is used to GetCustomerTaxTypeRateMapping
    ** Purpose:         
    ** Date:  03-May-2025 
            
    ** RETURN VALUE: 
    **************************************************************           
     ** Change History           
    **************************************************************           
    ** PR   Date			Author			Change Description            
    ** --   --------		-------			--------------------------------          
       1    03-May-2025   Ekta Chandegra	Created
        
    exec [dbo].[USP_GetCustomerTaxTypeRateMappingAudit] @CustomerTaxTypeRateMappingId
 **************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCustomerTaxTypeRateMappingAudit]
    @CustomerTaxTypeRateMappingId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT
			c.AuditCustomerTaxTypeRateMappingId,
			c.CustomerTaxTypeRateMappingId,
			c.CustomerId,
			ty.Description AS TaxType,
			ISNULL(tr.TaxRate, 0) AS TaxRate,
			c.CreatedBy,
			c.TaxRateId,
			c.TaxTypeId,
			c.MasterCompanyId,
			c.UpdatedBy,
			c.UpdatedDate,
			c.IsDeleted,
			c.SiteName,
			c.ShipFromSiteName,
			ISNULL(c.IsRepair, 0) AS IsRepair,
			ISNULL(c.IsProductSale, 0) AS IsProductSale,
			ISNULL(c.IsTaxExempt, 0) AS IsTaxExempt,
			c.TaxId
		FROM [dbo].[CustomerTaxTypeRateMappingAudit] c WITH(NOLOCK)
		LEFT JOIN [dbo].[TaxType] ty WITH(NOLOCK) ON c.TaxTypeId = ty.TaxTypeId
		LEFT JOIN [dbo].[TaxRate] tr WITH(NOLOCK) ON c.TaxRateId = tr.TaxRateId
		WHERE c.CustomerTaxTypeRateMappingId = @CustomerTaxTypeRateMappingId
		ORDER BY c.AuditCustomerTaxTypeRateMappingId DESC;
	END TRY
	BEGIN CATCH 
	DECLARE @ErrorLogID INT
    			,@DatabaseName VARCHAR(100) = db_name()
    			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
    			,@AdhocComments VARCHAR(150) = 'USP_GetCustomerTaxTypeRateMappingAudit'
    			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CustomerTaxTypeRateMappingId, '') AS varchar(100)) + ''
    			,@ApplicationName VARCHAR(100) = 'PAS'
    		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    		EXEC spLogException @DatabaseName = @DatabaseName
    			,@AdhocComments = @AdhocComments
    			,@ProcedureParameters = @ProcedureParameters
    			,@ApplicationName = @ApplicationName
    			,@ErrorLogID = @ErrorLogID OUTPUT;
    
    		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    
    		RETURN (1);
	END CATCH
END
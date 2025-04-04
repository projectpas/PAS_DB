/*************************************************************           
 ** File:   [GetSalesOrderChargesBySOId]           
 ** Author:   Abhishek Jirawla
 ** Description: Get Sales Order Charges By SOId
 ** Purpose:         
 ** Date:   05-Mar-2025  
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    05-Mar-2025   Abhishek Jirawla	Created
     
 EXECUTE [GetSalesOrderChargesBySOId] 1, 10
**************************************************************/ 
CREATE   PROCEDURE [dbo].[GetSalesOrderChargesBySOId]
    @SalesOrderId INT,
    @IsDeleted BIT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY

		SELECT DISTINCT 
			soc.SalesOrderChargesId,
			soc.SalesOrderQuoteId,
			soc.SalesOrderPartId,
			soc.SalesOrderId,
			soc.ChargesTypeId,
			ct.ChargeType AS ChargeType,
			soc.Description,
			soc.Quantity,
			soc.UnitCost,
			soc.ExtendedCost,
			soc.VendorId,
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
			soc.IsActive,
			soc.IsDeleted,
			soc.MasterCompanyId,
			soc.UpdatedBy,
			soc.UpdatedDate,
			soc.RefNum,
			ISNULL(gl.AccountName, '') AS GLAccountName,
			soc.ItemMasterId,
			soc.ConditionId
		FROM DBO.SalesOrderCharges soc WITH (NOLOCK)
		INNER JOIN DBO.Charge ct WITH (NOLOCK) ON soc.ChargesTypeId = ct.ChargeId
		LEFT JOIN DBO.Vendor v WITH (NOLOCK) ON soc.VendorId = v.VendorId
		LEFT JOIN DBO.GLAccount gl WITH (NOLOCK) ON ct.GLAccountId = gl.GLAccountId
		WHERE soc.IsDeleted = @IsDeleted
		  AND soc.SalesOrderId = @SalesOrderId;

	

	END TRY    
	BEGIN CATCH      

		DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetSalesOrderChargesBySOId'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesOrderId, '') AS varchar(100))  			                                           
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
END;
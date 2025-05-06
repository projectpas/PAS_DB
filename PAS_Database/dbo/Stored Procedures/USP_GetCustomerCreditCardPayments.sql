/*************************************************************           
    ** File:   [USP_GetCustomerCreditCardPayments]           
    ** Author:   Ekta Chandegra
    ** Description: This stored procedure is used to GetCustomerCreditCardPayments
    ** Purpose:         
    ** Date:  05-May-2025 
            
    ** RETURN VALUE: 
    **************************************************************           
     ** Change History           
    **************************************************************           
    ** PR   Date			Author			Change Description            
    ** --   --------		-------			--------------------------------          
       1    05-May-2025   Ekta Chandegra	Created
        
exec [dbo].[USP_GetCustomerCreditCardPayments] @MasterCompanyId=1,@IsDeleted=0,@CustomerId=4295,@CustomerFinancialId=5717
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCustomerCreditCardPayments]
    @MasterCompanyId INT,
    @IsDeleted BIT,
    @CustomerId BIGINT,
    @CustomerFinancialId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT 
			c.CreditCardPaymentId,
			c.PaymentMethodId,
			sp.PaymentMethodName,
			c.CardNumber,
			c.CardHolderName,
			c.Address,
			c.State,
			c.PostalCode,
			c.InActive,
			c.IsDefault,
			c.MasterCompanyId,
			c.IsDeleted,
			c.ExpirationDate,
			c.CreatedBy,
			c.CreatedDate,
			c.UpdatedBy,
			c.UpdatedDate,
			c.IsActive
		FROM [dbo].[CreditCardPayment] c WITH(NOLOCK)
		LEFT JOIN [dbo].[SupportedPaymentMethods] sp WITH(NOLOCK) ON c.PaymentMethodId = sp.Id
		WHERE 
			c.MasterCompanyId = @MasterCompanyId AND
			ISNULL(c.IsDeleted, 0) = @IsDeleted AND
			c.CustomerId = @CustomerId AND
			c.CustomerFinancialId = @CustomerFinancialId
		ORDER BY c.CreatedDate DESC;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT
    			,@DatabaseName VARCHAR(100) = db_name()
    			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
    			,@AdhocComments VARCHAR(150) = 'USP_GetCustomerCreditCardPayments'
    			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) + ''',
													   @Parameter2 = ''' + CAST(ISNULL(@IsDeleted, '') AS varchar(100)) + ''',
													   @Parameter3 = ''' + CAST(ISNULL(@CustomerId, '') AS varchar(100)) + ''',
													   @Parameter4 = ''' + CAST(ISNULL(@CustomerFinancialId, '') AS varchar(100)) + ''
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


-- EXEC GetPrintCheckVendorDetails 241,0
CREATE   PROCEDURE [dbo].[GetPrintCheckVendorDetails]
@ReadyToPayId BIGINT = NULL,
@ReadyToPayDetailsId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
		BEGIN TRY
			SELECT [VendorId],
			       [VendorName],
				   SUM([PaymentMade]) AS PaymentMade,
				   [PaymentMethodId], 
				   CASE WHEN [IsVoidedCheck] IS NULL THEN 0 ELSE [IsVoidedCheck] END AS IsVoidedCheck,
				   [CheckNumber]
		    FROM [dbo].[VendorReadyToPayDetails] WITH(NOLOCK)
			WHERE [ReadyToPayId] = @ReadyToPayId AND [ReadyToPayDetailsId] = CASE WHEN ISNULL(@ReadyToPayDetailsId,0) = 0 THEN [ReadyToPayDetailsId] ELSE @ReadyToPayDetailsId END
			GROUP BY [VendorId],[VendorName],[PaymentMethodId],[IsVoidedCheck],[CheckNumber]
	END TRY    
		BEGIN CATCH
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetPrintCheckVendorDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReadyToPayId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             = @ErrorLogID OUTPUT;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END
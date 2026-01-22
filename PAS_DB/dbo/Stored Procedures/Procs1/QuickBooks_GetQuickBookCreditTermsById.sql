 /*************************************************************           
 ** File:   [QuickBooks_GetQuickBookCreditTermsById]           
 ** Author:   Devendra Shekh
 ** Description: Get Credit Terms List for Update to QuickBook
 ** Purpose:         
 ** Date:   27-Nov-2024      
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				Author					Change Description            
 ** --   --------			-------				--------------------------------          
    1    27-Nov-2024		Devendra Shekh			Created
     
 EXECUTE [QuickBooks_GetQuickBookCreditTermsById] 6, 1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_GetQuickBookCreditTermsById]
	@QuickBooksReferenceId BIGINT = NULL,
	@MasterCompanyId BIGINT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		-- FOR QuickBooks
		SELECT  CT.CreditTermsId,
					CT.Name,
					CT.Memo,
					CT.PercentId,
					TR.TaxRate as PercentValue,
					CT.Days,
					CT.NetDays,
					CT.MasterCompanyId,
					CT.UpdatedBy,
					0 AS DiscountDays,
					'STANDARD' AS [Type],
					CT.IsActive,
					CT.QuickBooksReferenceId,
					CT.SyncToken
			FROM [dbo].[CreditTerms] CT WITH(NOLOCK) 
				LEFT JOIN [dbo].[TaxRate] TR WITH(NOLOCK) ON TR.TaxRateId = CT.PercentId
				 
			WHERE CT.QuickBooksReferenceId = @QuickBooksReferenceId AND CT.MasterCompanyId = @MasterCompanyId 

	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetQuickBookCreditTermsById'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@QuickBooksReferenceId, '') AS varchar(100))  			                                           
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
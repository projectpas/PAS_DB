 /*************************************************************           
 ** File:   [QuickBooks_GetCreditTermsSyncPendingList]           
 ** Author:   Devendra Shekh
 ** Description: Get Credit Terms List for Create to QuickBook
 ** Purpose:         
 ** Date:   27-Nov-2024      
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				Author					Change Description            
 ** --   --------			-------				--------------------------------          
    1    27-Nov-2024		Devendra Shekh			Created
	2    10-Jan-2025    Devendra Shekh	Modified(Added MasterCompanyId To Param)
     
 EXECUTE [QuickBooks_GetCreditTermsSyncPendingList] 1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_GetCreditTermsSyncPendingList]
	@IntegrationTypeId INT = NULL,
	@MasterCompanyId INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1) 
		BEGIN
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
				 
			WHERE ISNULL(CT.QuickBooksReferenceId, 0) = 0 AND ISNULL(CT.IsUpdated, 0) = 1 AND CT.MasterCompanyId = @MasterCompanyId
		END
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetCreditTermsSyncPendingList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@IntegrationTypeId, '') AS varchar(100))  			                                           
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
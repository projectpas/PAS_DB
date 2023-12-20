--  EXEC [dbo].[UpdateExchangeQuoteApprovalNameColumnsWithId] 5
CREATE PROCEDURE [dbo].[UpdateExchangeQuoteApprovalNameColumnsWithId]
	@ExchangeQuoteApprovalId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		Update SOQA
		SET CustomerName = C.Name,
		InternalApprovedBy = (SP.FirstName + ' ' + SP.LastName),
		CustomerApprovedBy = (Con.FirstName + ' ' + Con.LastName),
		RejectedByName = (Reg.FirstName + ' ' + Reg.LastName),
		InternalRejectedBy = (InReg.FirstName + ' ' + InReg.LastName),
		ApprovalAction = (CASE WHEN SOQA.ApprovalActionId = 1 THEN 'SentForInternalApproval'
								WHEN SOQA.ApprovalActionId = 2 THEN 'SubmitInternalApproval'
								WHEN SOQA.ApprovalActionId = 3 THEN 'SentForCustomerApproval'
								WHEN SOQA.ApprovalActionId = 4 THEN 'SubmitCustomerApproval'
								WHEN SOQA.ApprovalActionId = 5 THEN 'Approved' END),
		CustomerStatus = APSC.Name,
		InternalStatus = APSI.Name,
		InternalSentToName = (INST.FirstName + ' ' + INST.LastName)
		FROM [dbo].[ExchangeQuoteApproval] SOQA WITH (NOLOCK)
		LEFT JOIN DBO.Customer C WITH (NOLOCK) ON C.CustomerId = SOQA.CustomerId
		LEFT JOIN DBO.Employee SP WITH (NOLOCK) ON SP.EmployeeId = SOQA.InternalApprovedById
		LEFT JOIN DBO.Contact Con WITH (NOLOCK) ON Con.ContactId = SOQA.CustomerApprovedById
		LEFT JOIN DBO.Contact Reg WITH (NOLOCK) ON Reg.ContactId = SOQA.RejectedById
		LEFT JOIN DBO.Employee InReg WITH (NOLOCK) ON InReg.EmployeeId = SOQA.InternalRejectedById
		LEFT JOIN DBO.ApprovalStatus APSI WITH (NOLOCK) ON APSI.ApprovalStatusId = SOQA.InternalStatusId
		LEFT JOIN DBO.ApprovalStatus APSC WITH (NOLOCK) ON APSC.ApprovalStatusId = SOQA.CustomerStatusId
		LEFT JOIN DBO.Employee INST WITH (NOLOCK) ON INST.EmployeeId = SOQA.InternalSentToId
		Where SOQA.ExchangeQuoteApprovalId = @ExchangeQuoteApprovalId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateExchangeQuoteApprovalNameColumnsWithId' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ExchangeQuoteApprovalId, '') + ''
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
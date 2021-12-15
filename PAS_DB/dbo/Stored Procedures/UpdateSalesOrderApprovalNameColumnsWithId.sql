



--  EXEC [dbo].[UpdateSalesOrderApprovalNameColumnsWithId] 120
CREATE PROCEDURE [dbo].[UpdateSalesOrderApprovalNameColumnsWithId]
	@SalesOrderApprovalId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		Update SOA
		SET Customer = C.Name,
		InternalApprovedBy = (SP.FirstName + ' ' + SP.LastName),
		CustomerApprovedBy = (Con.FirstName + ' ' + Con.LastName),
		RejectedByName = (Reg.FirstName + ' ' + Reg.LastName),
		ApprovalAction = (CASE WHEN SOA.ApprovalActionId = 1 THEN 'SentForInternalApproval'
								WHEN SOA.ApprovalActionId = 2 THEN 'SubmitInternalApproval'
								WHEN SOA.ApprovalActionId = 3 THEN 'SentForCustomerApproval'
								WHEN SOA.ApprovalActionId = 4 THEN 'SubmitCustomerApproval'
								WHEN SOA.ApprovalActionId = 5 THEN 'Approved' END),
		CustomerStatus = APSC.Name,
		InternalStatus = APSI.Name
		FROM [dbo].[SalesOrderApproval] SOA WITH (NOLOCK)
		LEFT JOIN DBO.Customer C WITH (NOLOCK) ON C.CustomerId = SOA.CustomerId
		LEFT JOIN DBO.Employee SP WITH (NOLOCK) ON SP.EmployeeId = SOA.InternalApprovedById
		LEFT JOIN DBO.Contact Con WITH (NOLOCK) ON Con.ContactId = SOA.CustomerApprovedById
		LEFT JOIN DBO.Contact Reg WITH (NOLOCK) ON Reg.ContactId = SOA.RejectedById
		LEFT JOIN DBO.ApprovalStatus APSI WITH (NOLOCK) ON APSI.ApprovalStatusId = SOA.InternalStatusId
		LEFT JOIN DBO.ApprovalStatus APSC WITH (NOLOCK) ON APSC.ApprovalStatusId = SOA.CustomerStatusId
		Where SOA.SalesOrderApprovalId = @SalesOrderApprovalId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateSalesOrderApprovalNameColumnsWithId' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderApprovalId, '') + ''
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
/*************************************************************           
 ** File:   [USP_ApprovalRejectSalesQuotePartsByCustomer]           
 ** Author:   BHARGAV SALIYA
 ** Description: This stored procedure is used to Approval Reject Sales Quote Parts By Customer
 ** Purpose:         
 ** Date: 04/03/2025      
          
 ** PARAMETERS: 

 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    26-03-2025	 BHARGAV SALIYA	 Created  
	--CustomerApprovedById,InternalStatusId,CustomerApprovedBy
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_ApprovalRejectSalesQuotePartsByCustomer]
    @CustomerId BIGINT,
	@IsActive bit,
	@IsDeleted bit,
	@MasterCompanyId bigint,
	@SalesOrderQuoteId bigint,
	@SalesOrderQuotePartId bigint,
	@UpdatedBy varchar(250),
    @Action VARCHAR(100),
	@ApprovalActionId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		--For Approval Declairation
		DECLARE @ApprovalProcessId BIGINT, @ApprovalAction VARCHAR(100),@CustStatusId BIGINT,@CustomerStatus varchar(100);

		--For Reject Declairation
		DECLARE @RejectApprovalActionId BIGINT,@RejectApprovalAction VARCHAR(100),@RejectCustStatusId BIGINT,@RejectCustomerStatus varchar(100);
		DECLARE @ApproveCustName varchar(250) = (SELECT [Name] FROM [dbo].[Customer] WITH(NOLOCK) where CustomerId = @CustomerId and ISNULL(IsDeleted,0) = 0 AND IsActive = 1);

		--Selection For Approval
		(SELECT @CustStatusId = ApprovalStatusId, @CustomerStatus = [Description] FROM dbo.[ApprovalStatus] WITH(NOLOCK) WHERE [Description] = 'Approved');
		(SELECT @ApprovalProcessId = ApprovalProcessId, @ApprovalAction = [Description] FROM dbo.[ApprovalProcess] WITH(NOLOCK) WHERE	[Description] = 'Approved')

		--Selection For Reject
		(SELECT @RejectCustStatusId = ApprovalStatusId, @RejectCustomerStatus = [Description] FROM dbo.[ApprovalStatus] WITH(NOLOCK) WHERE [Description] = 'Rejected');
		(SELECT @RejectApprovalActionId = ApprovalProcessId, @RejectApprovalAction = [Description] FROM dbo.[ApprovalProcess] WITH(NOLOCK) WHERE	[Description] = 'SentForCustomerApproval')

		IF(UPPER(@Action) = 'APPROVE')
		BEGIN
			UPDATE [dbo].[SalesOrderQuoteApproval]
				SET CustomerApprovedDate = GETUTCDATE(),
					ApprovalActionId = @ApprovalProcessId,
					CustomerStatusId = @CustStatusId,
					UpdatedBy = @UpdatedBy,
					UpdatedDate = GETUTCDATE(),
					CustomerApprovedBy = @ApproveCustName,
					ApprovalAction = @ApprovalAction,
					CustomerStatus = @CustomerStatus
			WHERE SalesOrderQuoteId = @SalesOrderQuoteId AND SalesOrderQuotePartId = @SalesOrderQuotePartId 
				  AND IsDeleted = ISNULL(@IsDeleted,0) AND IsActive = ISNULL(@IsActive,0) AND MasterCompanyId = @MasterCompanyId

		    EXEC dbo.UpdateSalesOrderQuotePartsStatus @SalesOrderQuotePartId, @ApprovalActionId, @UpdatedBy
		END

		ELSE IF(UPPER(@Action) = 'REJECT')
		BEGIN
			UPDATE [dbo].[SalesOrderQuoteApproval]
				SET ApprovalActionId = @RejectApprovalActionId,
					CustomerStatusId = @RejectCustStatusId,
					UpdatedBy = @UpdatedBy,
					UpdatedDate = GETUTCDATE(),
					--CustomerApprovedBy = @ApproveCustName,
					ApprovalAction = @RejectApprovalAction,
					CustomerStatus = @RejectCustomerStatus,
					RejectedById = @CustomerId,
					RejectedByName = @ApproveCustName,
					RejectedDate = GETUTCDATE()
			WHERE SalesOrderQuoteId = @SalesOrderQuoteId AND SalesOrderQuotePartId = @SalesOrderQuotePartId 
				  AND IsDeleted = ISNULL(@IsDeleted,0) AND IsActive = ISNULL(@IsActive,0) AND MasterCompanyId = @MasterCompanyId

		    EXEC dbo.UpdateSalesOrderQuotePartsStatus @SalesOrderQuotePartId, @ApprovalActionId, @UpdatedBy
		END
		
	END TRY
	BEGIN CATCH
	DECLARE @ErrorLogID INT
	,@DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	,@AdhocComments VARCHAR(150) = 'USP_ApprovalRejectSalesQuotePartsByCustomer'
	, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@CustomerId, '') as Varchar(100)) + 
											  '@Parameter2 = '''+ CAST(ISNULL(@CustomerId, '') as Varchar(100))+		
											  '@Parameter3 = '''+ CAST(ISNULL(@IsActive, '') as Varchar(100))+		
											  '@Parameter4 = '''+ CAST(ISNULL(@IsDeleted, '') as Varchar(100))+		
											  '@Parameter5 = '''+ CAST(ISNULL(@MasterCompanyId, '') as Varchar(100))+		
											  '@Parameter6 = '''+ CAST(ISNULL(@SalesOrderQuoteId, '') as Varchar(100))+		
											  '@Parameter7 = '''+ CAST(ISNULL(@SalesOrderQuotePartId, '') as Varchar(100))+		
											  '@Parameter8 = '''+ CAST(ISNULL(@UpdatedBy, '') as Varchar(100))+		
											  '@Parameter9 = '''+ CAST(ISNULL(@ApprovalActionId, '') as Varchar(100))+	
											  '@Parameter10 = '''+  CAST(ISNULL(@Action, '') as Varchar(100))		
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
/*************************************************************           
 ** File:   [USP_ApprovalRejectSalesOrderPartsByCustomer]           
 ** Author:   BHARGAV SALIYA
 ** Description: This stored procedure is used to Approval Reject Sales Order Parts By Customer
 ** Purpose:         
 ** Date: 25-06-2025    
          
 ** PARAMETERS: 

 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    25-06-2025	 BHARGAV SALIYA	  Created 
	2    14-07-2025	 RAJESH GAMI	  Call the new SP for update the SO Header status  
	3    15-07-2025	 Devendra Shekh	  Added @ContactId param
	4    05-09-2025	 Amit Ghediya	  Update rejected data null after approved.
	5    10-09-2025	 Amit Ghediya	  Update for notes
	--CustomerApprovedById,InternalStatusId,CustomerApprovedBy
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_ApprovalRejectSalesOrderPartsByCustomer]
	@SalesOrderId BIGINT,
	@SalesOrderPartId BIGINT,
	@CustomerApprovedById BIGINT = NULL,
    @CustomerId BIGINT,
	@InternalStatusId BIGINT,
	@IsActive bit,
	@IsDeleted bit,
	@MasterCompanyId bigint,
	@UpdatedBy varchar(250),
    @Action VARCHAR(100),
	@ApprovalActionId BIGINT,
	@ContactId BIGINT = NULL,
	@Notes VARCHAR(MAX)
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
			UPDATE [dbo].[SalesOrderApproval]
				SET CustomerApprovedDate = GETUTCDATE(),
				    CustomerApprovedById = @ContactId,
					ApprovalActionId = @ApprovalProcessId,
					CustomerStatusId = @CustStatusId,
					InternalStatusId = @InternalStatusId,
					CustomerApprovedBy = @ApproveCustName,
					ApprovalAction = @ApprovalAction,
					CustomerStatus = @CustomerStatus,
					InternalStatus = @CustomerStatus,
					UpdatedBy = @UpdatedBy,
					UpdatedDate = GETUTCDATE(),
					RejectedById = NULL,
					RejectedByName = NULL,
					RejectedDate = NULL,
					CustomerMemo = @Notes
			WHERE SalesOrderId = @SalesOrderId AND SalesOrderPartId = @SalesOrderPartId 
				  AND IsDeleted = ISNULL(@IsDeleted,0) AND IsActive = ISNULL(@IsActive,0) AND MasterCompanyId = @MasterCompanyId

		    EXEC dbo.SP_UpdateSOHeaderStatusBySOId @SalesOrderId
		END

		ELSE IF(UPPER(@Action) = 'REJECT')
		BEGIN
			UPDATE [dbo].[SalesOrderApproval]
				SET 
					--CustomerApprovedById = @CustomerApprovedById,
					ApprovalActionId = @RejectApprovalActionId,
					CustomerStatusId = @RejectCustStatusId,
					UpdatedBy = @UpdatedBy,
					UpdatedDate = GETUTCDATE(),
					--CustomerApprovedBy = @ApproveCustName,
					ApprovalAction = @RejectApprovalAction,
					CustomerStatus = @RejectCustomerStatus,
					RejectedById = @ContactId,
					RejectedByName = @ApproveCustName,
					RejectedDate = GETUTCDATE(),
					CustomerMemo = @Notes
			WHERE SalesOrderId = @SalesOrderId AND SalesOrderPartId = @SalesOrderPartId  
				  AND IsDeleted = ISNULL(@IsDeleted,0) AND IsActive = ISNULL(@IsActive,0) AND MasterCompanyId = @MasterCompanyId

		    EXEC dbo.SP_UpdateSOHeaderStatusBySOId @SalesOrderId
		END
		
	END TRY
	BEGIN CATCH
	DECLARE @ErrorLogID INT
	,@DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	,@AdhocComments VARCHAR(150) = 'USP_ApprovalRejectSalesOrderPartsByCustomer'
	, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@SalesOrderId, '') as Varchar(100)) + 
											  '@Parameter2 = '''+ CAST(ISNULL(@SalesOrderPartId, '') as Varchar(100))+		
											  '@Parameter3 = '''+ CAST(ISNULL(@CustomerApprovedById, '') as Varchar(100))+		
											  '@Parameter4 = '''+ CAST(ISNULL(@CustomerId, '') as Varchar(100))+		
											  '@Parameter5 = '''+ CAST(ISNULL(@InternalStatusId, '') as Varchar(100))+		
											  '@Parameter6 = '''+ CAST(ISNULL(@IsActive, '') as Varchar(100))+		
											  '@Parameter7 = '''+ CAST(ISNULL(@IsDeleted, '') as Varchar(100))+		
											  '@Parameter8 = '''+ CAST(ISNULL(@MasterCompanyId, '') as Varchar(100))+		
											  '@Parameter9 = '''+ CAST(ISNULL(@UpdatedBy, '') as Varchar(100))+		
											  '@Parameter10 = '''+ CAST(ISNULL(@ApprovalActionId, '') as Varchar(100))+	
											  '@Parameter11 = '''+  CAST(ISNULL(@Action, '') as Varchar(100))		
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
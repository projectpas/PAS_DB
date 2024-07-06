/*****************************************************************************     
** Author:  <Abhishek Jirawla>    
** Create date: <07/05/2024>    
** Description: <Get Customer CreditPaymentList>   
**********************   
** Change History   
**********************     

	  (mm/dd/yyyy)
** PR   Date			Author				Change Description    
** --   --------		-------				--------------------------------  
** 1    07/05/2024		Abhishek Jirawla		created

*****************************************************************************/  
CREATE   PROCEDURE [dbo].[USP_GetCustomerCreditPaymentDetails]
	@CustomerCreditPaymentDetailId BIGINT
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		BEGIN TRY


				SELECT CCP.CustomerCreditPaymentDetailId,
						CCP.CustomerId,
						CCP.CustomerName,
						CCP.CustomerCode,
						CCP.CheckNumber AS 'ReferenceNumber',
						CCP.TotalAmount,
						CCP.RemainingAmount,
						CCP.PaidAmount,
						CCP.ReceiptId,
						CCP.IsActive,
						CCP.IsDeleted,
						CCP.CreatedDate,
						CCP.UpdatedDate,
						CCP.ReceiveDate,
						CP.ReceiptNo,
						CP.CntrlNum AS 'ControlNum',
						--CASE WHEN UPPER(CCP.CustomerName) = 'MISCELLANEOUS' OR UPPER(CCP.CustomerName) = 'MISCELLANEOUS CUSTOMER' THEN 'SUSPENSE' ELSE 'UNAPPLIED' END AS 'CustomerType',
						CASE WHEN ISNULL(CCP.IsMiscellaneous, '') = 1 THEN 'SUSPENSE' ELSE 'UNAPPLIED' END AS 'CustomerType',
						Upper(CCP.CreatedBy) CreatedBy,
						Upper(CCP.UpdatedBy) UpdatedBy,
						CCP.[StatusId],
						ISNULL(CCP.Memo, '') AS 'Memo',
						ISNULL(VA.VendorName, '') AS 'VendorName',
						ISNULL(CCP.VendorId, 0) AS 'VendorId',
						ISNULL(VA.VendorCode, '') AS 'VendorCode',
						ISNULL(CCP.SuspenseUnappliedNumber, '') AS 'SuspenseUnappliedNumber',
						ISNULL(CCP.IsMiscellaneous, '') AS 'IsMiscellaneous',
						ISNULL(CCP.MappingCustomerId, '') AS 'MappingCustomerId',
						ISNULL(CA.[Name], '') AS 'MappedCustomerName',
						ISNULL(CA.CustomerCode, '') AS 'MappedCustomerCode'
					FROM dbo.CustomerCreditPaymentDetail CCP WITH (NOLOCK)
					LEFT JOIN dbo.[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = CCP.ReceiptId
					LEFT JOIN [dbo].[Vendor] VA WITH(NOLOCK) ON VA.VendorId = CCP.VendorId
					LEFT JOIN [dbo].[Customer] CA WITH(NOLOCK) ON CA.CustomerId = CCP.MappingCustomerId
		 	  WHERE ccp.CustomerCreditPaymentDetailId = @CustomerCreditPaymentDetailId

	END TRY    
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetCustomerCreditPaymentList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CustomerCreditPaymentDetailId, '') AS varchar(100))			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);           
	END CATCH
END
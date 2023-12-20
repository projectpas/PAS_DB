


/*************************************************************           
 ** File:   [UpdateCreditMemoDetails]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to update Credit Memo Details
 ** Purpose:         
 ** Date:   18/04/2022      
          
 ** PARAMETERS: @CreditMemoHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    18/04/2022  Moin Bloch     Created
     
-- EXEC UpdateCreditMemoDetails 1
************************************************************************/

CREATE PROCEDURE [dbo].[UpdateCreditMemoDetails]
@CreditMemoHeaderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY
	BEGIN TRAN

		UPDATE dbo.CreditMemoApproval SET ApprovedById = null , ApprovedDate = null , ApprovedByName = null
		Where  CreditMemoHeaderId = @CreditMemoHeaderId and StatusId != (select ApprovalStatusId from  dbo.ApprovalStatus WHERE Name  =  'Approved') 
		
		UPDATE dbo.CreditMemoApproval SET RejectedBy = null , RejectedDate =  null , RejectedByName = null
		Where CreditMemoHeaderId = @CreditMemoHeaderId and StatusId != (select ApprovalStatusId from  dbo.ApprovalStatus WHERE Name  =  'Rejected') 

		UPDATE dbo.CreditMemoApproval
		SET ApprovedByName = AE.FirstName + ' ' + AE.LastName,
			RejectedByName = RE.FirstName + ' ' + RE.LastName,
			StatusName = ASS.Description,
			InternalSentToName = (INST.FirstName + ' ' + INST.LastName)
		FROM dbo.CreditMemoApproval PA
			 LEFT JOIN dbo.Employee AE on PA.ApprovedById = AE.EmployeeId
			 LEFT JOIN DBO.Employee INST WITH (NOLOCK) ON INST.EmployeeId = PA.InternalSentToId
			 LEFT JOIN dbo.Employee RE on PA.RejectedBy = RE.EmployeeId
			 LEFT JOIN dbo.ApprovalStatus ASS on PA.StatusId = ASS.ApprovalStatusId
	 
		UPDATE CM SET		
		CM.Status = CMS.[Name],
		CM.CustomerName = V.[Name],
		CM.CustomerCode = V.CustomerCode,
		CM.CustomerContact = ISNULL(C.FirstName,'') + ' ' + ISNULL(C.LastName,''),
		CM.CustomerContactPhone = ISNULL(C.WorkPhone,'') + '-' + ISNULL(C.WorkPhoneExtn,''),
		CM.RequestedBy = ISNULL(e.FirstName,'') + ' ' + ISNULL(e.LastName,''),		
		CM.ApprovedBy = ISNULL(AP.FirstName,'') + ' ' + ISNULL(AP.LastName,''),
	    CM.Reason = CMR.[Name]

		FROM dbo.CreditMemo CM WITH (NOLOCK)		
		LEFT JOIN dbo.CreditMemoStatus CMS WITH (NOLOCK) on CMS.Id = CM.StatusId
		LEFT JOIN dbo.CreditMemoReason CMR WITH (NOLOCK) on CMR.Id = CM.ReasonId
		LEFT JOIN dbo.Customer V WITH (NOLOCK) ON V.CustomerId = CM.CustomerId
		LEFT JOIN dbo.CustomerContact VC WITH (NOLOCK) ON VC.CustomerContactId = CM.CustomerContactId
		LEFT JOIN dbo.Contact C WITH (NOLOCK) ON  VC.ContactId =  C.ContactId		
		LEFT JOIN dbo.Employee E WITH (NOLOCK) on E.EmployeeId =  CM.RequestedById
		LEFT JOIN dbo.Employee AP WITH (NOLOCK) ON AP.EmployeeId = CM.ApproverId		
		WHERE CM.CreditMemoHeaderId = @CreditMemoHeaderId
		
		SELECT CreditMemoNumber as value FROM dbo.CreditMemo CM WITH (NOLOCK) WHERE CreditMemoHeaderId = @CreditMemoHeaderId;	

	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateCreditMemoDetails' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CreditMemoHeaderId, '') + ''
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
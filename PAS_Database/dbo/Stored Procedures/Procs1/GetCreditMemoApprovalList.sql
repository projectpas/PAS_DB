/*************************************************************           
 ** File:   [GetCreditMemoApprovalList]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to Get Credit Memo Approval List
 ** Purpose:         
 ** Date:   22/04/2022      
          
 ** PARAMETERS: @CreditMemoHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    22/04/2022  Moin Bloch     Created
	2    13/09/2023  Amit Ghediya   Update for Stand Alone CreditMemo approve.
     
-- EXEC GetCreditMemoApprovalList 38,1
************************************************************************/
CREATE       PROCEDURE [dbo].[GetCreditMemoApprovalList]
	@CreditMemoHeaderId bigint,
	@IsInternalApprove bit
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

	DECLARE @isStandAloneCM AS BIT;

	--IS StandAloneCreditMemo or not.
	SELECT @isStandAloneCM = IsStandAloneCM FROM dbo.CreditMemo WITH(NOLOCK) WHERE CreditMemoHeaderId = @CreditMemoHeaderId;

	IF @isStandAloneCM = 1
	BEGIN
		SELECT SACM.[StandAloneCreditMemoDetailId] AS 'CreditMemoDetailId'
			  ,SACM.[CreditMemoHeaderId]
			  ,'' AS 'PartNumber'
			  ,'' AS 'PartDescription'
			  ,'' AS 'AltPartNumber'                
			  ,SACM.[Qty]
			  ,SACM.[Rate] AS 'UnitPrice'
			  ,SACM.[Amount]
			  ,'' AS 'Notes'
			  ,SACM.[MasterCompanyId]	
			  ,SACM.[IsActive]
			  ,SACM.[IsDeleted]
			  ,ISNULL(CA.[CreditMemoApprovalId],0) 'CreditMemoApprovalId'
			  ,ISNULL(CA.[ApprovedDate],GETDATE()) 'ApprovedDate'
			  ,ISNULL(CA.[SentDate],GETDATE()) 'SentDate'		  
			  ,CA.[ApprovedByName] AS ApprovedBy		  
			  ,ISNULL(CA.[RejectedDate],GETDATE()) 'RejectedDate'		  	
			  ,CA.[RejectedByName] 'RejectedBy'
			  ,ISNULL(CA.[ApprovedById],0) 'ApprovedById'	
			  ,CA.Memo
			  ,CA.CreatedBy
			  ,CA.UpdatedBy
			  ,ISNULL(CA.[CreatedDate],GETDATE()) 'CreatedDate' 
			  ,ISNULL(CA.[UpdatedDate],GETDATE()) 'UpdatedDate'  
			  ,CASE WHEN @IsInternalApprove = 0 AND CA.CreditMemoApprovalId IS NULL THEN 1
					WHEN CA.CreditMemoApprovalId IS NULL THEN 1 ELSE CA.ActionId END 'ActionId' 
			  ,CASE WHEN @IsInternalApprove = 0 AND CA.CreditMemoApprovalId IS NULL THEN 'Send for Approval'
					WHEN CA.CreditMemoApprovalId IS NULL THEN 'Send for Approval'
					WHEN CA.ActionId = 1 AND CA.StatusId = 3 THEN 'Returned to Requisitioner'
					WHEN CA.ActionId = 1 THEN 'Send for Approval'
					WHEN CA.ActionId = 2 THEN 'Submit Approval'
					ELSE 'Approved' END 'ActionStatus'
			 ,CASE WHEN CA.CreditMemoApprovalId IS NULL THEN 1 ELSE CA.StatusId END  'StatusId'
			 ,CA.StatusName 'Status'
			 ,@IsInternalApprove 'IsInternalApprove'
			 ,ISNULL(CA.[InternalSentToId],0) 'InternalSentToId'	
			 ,ISNULL(CA.[InternalSentToName],'') 'InternalSentToName'	
			 ,ISNULL(CA.[InternalSentById],0) 'InternalSentById'			 		  
		  FROM [dbo].[StandAloneCreditMemoDetails] SACM WITH (NOLOCK) 
		  LEFT JOIN [dbo].[CreditMemoApproval] CA WITH (NOLOCK) ON SACM.StandAloneCreditMemoDetailId = CA.CreditMemoDetailId
					AND SACM.CreditMemoHeaderId = CA.CreditMemoHeaderId
		  WHERE SACM.CreditMemoHeaderId = @CreditMemoHeaderId AND SACM.IsDeleted = 0 
	END
	ELSE
	BEGIN
		SELECT CM.[CreditMemoDetailId]
			  ,CM.[CreditMemoHeaderId]
			  ,CM.[PartNumber]
			  ,CM.[PartDescription]
			  ,CM.[AltPartNumber]                
			  ,CM.[Qty]
			  ,CM.[UnitPrice]
			  ,CM.[Amount]
			  ,CM.[Notes]
			  ,CM.[MasterCompanyId]	
			  ,CM.[IsActive]
			  ,CM.[IsDeleted]
			  ,ISNULL(CA.[CreditMemoApprovalId],0) 'CreditMemoApprovalId'
			  ,ISNULL(CA.[ApprovedDate],GETDATE()) 'ApprovedDate'
			  ,ISNULL(CA.[SentDate],GETDATE()) 'SentDate'		  
			  ,CA.[ApprovedByName] AS ApprovedBy		  
			  ,ISNULL(CA.[RejectedDate],GETDATE()) 'RejectedDate'		  	
			  ,CA.[RejectedByName] 'RejectedBy'
			  ,ISNULL(CA.[ApprovedById],0) 'ApprovedById'	
			  ,CA.Memo
			  ,CA.CreatedBy
			  ,CA.UpdatedBy
			  ,ISNULL(CA.[CreatedDate],GETDATE()) 'CreatedDate' 
			  ,ISNULL(CA.[UpdatedDate],GETDATE()) 'UpdatedDate'  
			--,CASE WHEN @IsInternalApprove = 0 AND CA.CreditMemoApprovalId IS NULL THEN 0
			  ,CASE WHEN @IsInternalApprove = 0 AND CA.CreditMemoApprovalId IS NULL THEN 1
					WHEN CA.CreditMemoApprovalId IS NULL THEN 1 ELSE CA.ActionId END 'ActionId' 

			 --,CASE WHEN @IsInternalApprove = 0 AND CA.CreditMemoApprovalId IS NULL THEN 'No Approval Required'
			  ,CASE WHEN @IsInternalApprove = 0 AND CA.CreditMemoApprovalId IS NULL THEN 'Send for Approval'
					WHEN CA.CreditMemoApprovalId IS NULL THEN 'Send for Approval'
					WHEN CA.ActionId = 1 AND CA.StatusId = 3 THEN 'Returned to Requisitioner'
					WHEN CA.ActionId = 1 THEN 'Send for Approval'
					WHEN CA.ActionId = 2 THEN 'Submit Approval'
					ELSE 'Approved' END 'ActionStatus'
			 ,CASE WHEN CA.CreditMemoApprovalId IS NULL THEN 1 ELSE CA.StatusId END  'StatusId'
			 ,CA.StatusName 'Status'
			 ,@IsInternalApprove 'IsInternalApprove'
			 ,ISNULL(CA.[InternalSentToId],0) 'InternalSentToId'	
			 ,ISNULL(CA.[InternalSentToName],'') 'InternalSentToName'	
			 ,ISNULL(CA.[InternalSentById],0) 'InternalSentById'			 		  
		  FROM [dbo].[CreditMemoDetails] CM WITH (NOLOCK) 
		  LEFT JOIN [dbo].[CreditMemoApproval] CA WITH (NOLOCK) ON CM.CreditMemoDetailId = CA.CreditMemoDetailId
		  WHERE CM.CreditMemoHeaderId = @CreditMemoHeaderId AND CM.IsDeleted = 0 	 
	END
		
END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetCreditMemoApprovalList' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CreditMemoHeaderId, '') AS varchar(100))			   
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
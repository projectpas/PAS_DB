/*************************************************************           
 ** File:   [GetCreditMemoApprovalList]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to Get Cycle Count Approval List
 ** Purpose:         
 ** Date:   25/10/2024  
          
 ** PARAMETERS: @CycleCountId bigint,@IsInternalApprove bit
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    25/10/2024  Moin Bloch     Created
	2    30/10/2024  Moin Bloch     Added Employee Table Join
     
-- EXEC USP_CycleCount_ApprovalList 20,1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CycleCount_ApprovalList]
@CycleCountId BIGINT,
@IsInternalApprove BIT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	
		DECLARE @SentForInternalApproval INT = 1;
		DECLARE @SubmitInternalApproval INT = 2;
		DECLARE @Rejected INT = 3;
		DECLARE @Pending INT = 1;
	
		SELECT CD.[CycleCountDetailId],
			   CD.[CycleCountId],
			   CC.[CycleCountNumber],
 			   CD.[StockLineId],
			   CD.[PartNumber],
			   CD.[PartDescription],  
			   CD.[StockLineNumber],
			   CD.[ControlNumber],
			   CD.[IdNumber],
			   CD.[SerialNumber],			   
			   CD.[ManufacturerName],
			   CD.[ConditionName],
			   CD.[DifferenceQuantity],
			   CD.[DifferenceAmount],       
			   ISNULL(CA.[ApprovedDate], GETUTCDATE()) AS ApprovedDate,
			   ISNULL(CA.[SentDate], GETUTCDATE()) AS SentDate,
			   ISNULL(CE.FirstName +' '+ CE.LastName,'') AS ApprovedBy,
			   ISNULL(CA.[RejectedDate], GETUTCDATE()) AS RejectedDate,			   
			   ISNULL(RE.FirstName +' '+ RE.LastName,'') AS RejectedBy,
			   ISNULL(CA.[CycleCountApprovalId], 0) AS CycleCountApprovalId,
			   CD.[MasterCompanyId],
			   ISNULL(CA.[ApprovedById], 0) AS ApprovedById,			   
			   ISNULL(CA.[Memo], '') AS Memo,			  
			   CA.CreatedBy,
			   CA.UpdatedBy,
			   ISNULL(CA.[CreatedDate], GETUTCDATE()) AS CreatedDate,
			   ISNULL(CA.[UpdatedDate], GETUTCDATE()) AS UpdatedDate,       		   
			   CASE WHEN @IsInternalApprove = 0 AND CA.[CycleCountApprovalId] IS NULL THEN 1 WHEN CA.[CycleCountApprovalId] IS NULL THEN 1 ELSE CA.[ActionId] END 'ActionId',		   
			   CASE WHEN @IsInternalApprove = 0 AND CA.[CycleCountApprovalId] IS NULL THEN 'Send for Approval'
						WHEN CA.[CycleCountApprovalId] IS NULL THEN 'Send for Approval'
						WHEN CA.[ActionId] = @SentForInternalApproval AND CA.[StatusId] = @Rejected THEN 'Returned to Requisitioner'
						WHEN CA.[ActionId] = @SentForInternalApproval THEN 'Send for Approval'
						WHEN CA.[ActionId] = @SubmitInternalApproval THEN 'Submit Approval'
						ELSE 'Approved' END 'ActionStatus',
			  CASE WHEN CA.[CycleCountApprovalId] IS NULL THEN 1 ELSE CA.[StatusId] END  'StatusId',
			  CA.[StatusName] 'Status',			
			  @IsInternalApprove AS IsInternalApprove,        
			  ISNULL(CA.[InternalSentToId], 0) AS InternalSentToId,
			  ISNULL(CA.[InternalSentToName], '') AS InternalSentToName,
			  ISNULL(CA.[InternalSentById], 0) AS InternalSentById		
		FROM [dbo].[CycleCountDetail] CD WITH(NOLOCK)
		INNER JOIN [dbo].[CycleCount] CC WITH(NOLOCK) ON CD.[CycleCountId] = CC.[CycleCountId]
		 LEFT JOIN [dbo].[CycleCountApproval] CA WITH(NOLOCK) ON CD.[CycleCountDetailId] = CA.[CycleCountDetailId]
		 LEFT JOIN [dbo].[Employee] CE WITH(NOLOCK) ON CA.[ApprovedById] = CE.[EmployeeId]
		 LEFT JOIN [dbo].[Employee] RE WITH(NOLOCK) ON CA.[RejectedBy] = RE.[EmployeeId]
		  WHERE CD.[CycleCountId] = @CycleCountId 
		    AND CD.[IsDeleted] = 0; 
	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_CycleCount_ApprovalList' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CycleCountId, '') AS varchar(100))			   
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
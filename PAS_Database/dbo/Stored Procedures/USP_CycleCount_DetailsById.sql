/*************************************************************           
 ** File:   [USP_CycleCount_DetailsById]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used to Get Cycle Count Header Details
 ** Purpose:         
 ** Date:   16/10/2024     
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    16/10/2024   Moin Bloch    Created
	2    24/10/2024   Moin Bloch    Added RequestedById
	3    29/10/2024   Moin Bloch    Added ApproverId,ApprovedBy,DateApproved
    4    28/10/2024   Moin Bloch    Added @CountedById,@CountMethodId

  EXEC [dbo].[USP_CycleCount_DetailsById] 1,1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CycleCount_DetailsById]
@CycleCountId BIGINT,
@MasterCompanyId INT
AS  
BEGIN  
	SET NOCOUNT ON;	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED		    
	BEGIN TRY
		SELECT CC.[CycleCountId]
			  ,CC.[CycleCountNumber]
			  ,CC.[EntryDate]
			  ,CC.[EntryTime]
			  ,CC.[StatusId]
			  ,CC.[ManagementStructureId]
			  ,CASE WHEN CC.[IsEnforce] = 1 THEN 1 ELSE 0 END IsEnforce
			  ,CC.[RequestedById]			  
              ,CC.[ApproverId]
			  ,CC.[ApprovedBy]
			  ,CC.[DateApproved]			  
              ,CC.[CountedById]
			  ,ISNULL(EP.[FirstName],'') + ' ' + ISNULL(EP.[LastName],'') AS CountedBy
			  ,CC.[CountMethodId]
			  ,CC.[MasterCompanyId]
			  ,CC.[CreatedBy]
			  ,CC.[UpdatedBy]	
			  ,CC.[CreatedDate]
			  ,CC.[UpdatedDate]
			  ,CC.[IsActive]
			  ,CC.[IsDeleted]
		  FROM [dbo].[CycleCount] CC WITH(NOLOCK) 
	 LEFT JOIN [dbo].[Employee] EP ON CC.[CountedById] = EP.[EmployeeId]
		 WHERE [CycleCountId] = @CycleCountId AND CC.[MasterCompanyId] = @MasterCompanyId;	
	END TRY  
		BEGIN CATCH      
			IF @@trancount > 0			
            DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CycleCount_DetailsById' 
			  , @ProcedureParameters VARCHAR(3000) = '@CycleCountId = ''' + CAST(ISNULL(@CycleCountId, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters    = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH    
END
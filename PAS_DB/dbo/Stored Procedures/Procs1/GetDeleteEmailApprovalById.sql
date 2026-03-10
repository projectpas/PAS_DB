/*************************************************************           
 ** File:   [GetDeleteEmailApprovalById]           
 ** Author:  AMIT GHEDIYA
 ** Description: This stored procedure is used to Get GetDelete EmailApprovalById
 ** Purpose:         
 ** Date:   16/07/2025      
          
 ** PARAMETERS: @RefrenceId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    16/07/2025   AMIT GHEDIYA      Created
    2    10/03/2026   Bhargav Saliya    [PN-15717]Added MasterCompanyId in where clause

-- EXEC GetDeleteEmailApprovalById 769,1
************************************************************************/
CREATE   PROCEDURE [dbo].[GetDeleteEmailApprovalById]
	@RefrenceId BIGINT,
	@Mode INT = 0,
	@ModuleId BIGINT,
	@MasterCompanyId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

	IF(@Mode = 0) --For Select
	BEGIN
		  SELECT [PartNumber],
				 [PartDescription],
				 [Qty],
				 [TotalSales],
				 [RefrenceId],
				 [SubRefrenceId],
				 [CustomerApprovedById],
				 [CustomerId],
				 [InternalStatusId],
				 [IsActive],
				 [IsDeleted],
				 [MasterCompanyId],
				 [UpdatedBy],
				 [ApprovalActionId],
				 [Email],
				 [ContactId]		  
		  FROM  [DBO].[EmailApproval] WITH (NOLOCK) 
		  WHERE RefrenceId = @RefrenceId
		  AND ModuleId = @ModuleId AND MasterCompanyId = @MasterCompanyId;
	END
	IF(@Mode = 1) --For Delete
	BEGIN
		DELETE 
			FROM  [DBO].[EmailApproval] 
		 WHERE RefrenceId = @RefrenceId
		 AND ModuleId = @ModuleId and MasterCompanyId = @MasterCompanyId;
	END

END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetDeleteEmailApprovalById' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@Mode, '') AS varchar(100))			   
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
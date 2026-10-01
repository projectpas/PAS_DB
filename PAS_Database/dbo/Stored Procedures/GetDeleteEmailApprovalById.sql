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
    3    30/09/2026   Bhargav Saliya    [PN-18094]SO / SOQ: select only parts still waiting for customer approval
                                        (Submitted for Cust Approval + Waiting for Approval). Parts approved / rejected
                                        from the PAS Approval tab keep their EmailApproval row, so they were still shown
                                        on the customer approve / reject page.

-- EXEC GetDeleteEmailApprovalById 769,1
************************************************************************/
CREATE   PROCEDURE [dbo].[GetDeleteEmailApprovalById]
	@RefrenceId BIGINT,
	@Mode INT = 0,
	@ModuleId BIGINT,
	@MasterCompanyId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

	IF(@Mode = 0) --For Select
	BEGIN
		  DECLARE @SOModuleId BIGINT = 0,
				  @SOQModuleId BIGINT = 0,
				  @SubmitCustomerApproval INT = (SELECT ApprovalProcessId FROM dbo.[ApprovalProcess] WITH(NOLOCK) WHERE UPPER([Name]) = 'SUBMITCUSTOMERAPPROVAL'), -- ApprovalProcessEnum.SubmitCustomerApproval
				  @WaitingForApproval INT = (SELECT ApprovalStatusId FROM dbo.[ApprovalStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'WAITING FOR APPROVAL');     -- ApprovalStatusEnum.WaitingForApproval

		  SELECT @SOModuleId = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
		  SELECT @SOQModuleId = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesQuote';

		  SELECT EA.[PartNumber],
				 EA.[PartDescription],
				 EA.[Qty],
				 EA.[TotalSales],
				 EA.[RefrenceId],
				 EA.[SubRefrenceId],
				 EA.[CustomerApprovedById],
				 EA.[CustomerId],
				 EA.[InternalStatusId],
				 EA.[IsActive],
				 EA.[IsDeleted],
				 EA.[MasterCompanyId],
				 EA.[UpdatedBy],
				 EA.[ApprovalActionId],
				 EA.[Email],
				 EA.[ContactId]
		  FROM  [DBO].[EmailApproval] EA WITH (NOLOCK)
		  WHERE EA.RefrenceId = @RefrenceId
		  AND EA.ModuleId = @ModuleId AND EA.MasterCompanyId = @MasterCompanyId
		  AND (
				(@ModuleId = @SOModuleId AND EXISTS (SELECT 1 FROM [DBO].[SalesOrderApproval] SOA WITH (NOLOCK)
													 WHERE SOA.[SalesOrderId] = EA.RefrenceId AND SOA.[SalesOrderPartId] = EA.SubRefrenceId
													 AND ISNULL(SOA.[IsDeleted], 0) = 0
													 AND SOA.[ApprovalActionId] = @SubmitCustomerApproval AND SOA.[CustomerStatusId] = @WaitingForApproval))
			 OR (@ModuleId = @SOQModuleId AND EXISTS (SELECT 1 FROM [DBO].[SalesOrderQuoteApproval] SOQA WITH (NOLOCK)
													  WHERE SOQA.[SalesOrderQuoteId] = EA.RefrenceId AND SOQA.[SalesOrderQuotePartId] = EA.SubRefrenceId
													  AND ISNULL(SOQA.[IsDeleted], 0) = 0
													  AND SOQA.[ApprovalActionId] = @SubmitCustomerApproval AND SOQA.[CustomerStatusId] = @WaitingForApproval))
			 OR (@ModuleId NOT IN (@SOModuleId, @SOQModuleId))
		  );
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
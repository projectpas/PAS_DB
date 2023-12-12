/*************************************************************           
 ** File:   [USP_CreateUpdateStandAloneCreditMemoHeader]           
 ** Author:  AMIT GHEDIYA
 ** Description: This stored procedure is used to create and update Stand Alone Credit Memo Details
 ** Purpose:         
 ** Date:   29/08/2023      
          
 ** PARAMETERS: @RMAHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date           Author					Change Description            
 ** --   --------       -------				   --------------------------------          
    1    29/08/2023     AMIT GHEDIYA			Created
	2    06/09/2023     AMIT GHEDIYA			Update for Status add.
	2    11/09/2023     AMIT GHEDIYA			Update for Isforce add.
     
-- EXEC USP_CreateUpdateStandAloneCreditMemoHeader 1
************************************************************************/
CREATE        PROCEDURE [dbo].[USP_CreateUpdateStandAloneCreditMemoHeader]
	@CreditMemoHeaderId BIGINT=NULL,
	@CreditMemoNumber VARCHAR(50)=NULL,
	@StatusId INT=NULL,
	@Status VARCHAR(50)=NULL,
	@CustomerId BIGINT=NULL,
	@CustomerName VARCHAR(50)=NULL,
	@CustomerCode VARCHAR(50)=NULL, 
	@CustomerContactId BIGINT=NULL,
	@CustomerContact VARCHAR(50)=NULL, 
	@CustomerContactPhone VARCHAR(20)=NULL,
	@AcctingPeriod BIGINT = NULL,
	@RequestedById BIGINT=NULL,
	@RequestedBy VARCHAR(100)=NULL, 
	@Notes NVARCHAR(MAX)=NULL,
	@ManagementStructureId BIGINT=NULL,
	@IsEnforce bit=NULL,
	@MasterCompanyId INT=NULL,
	@CreatedBy VARCHAR(256)=NULL,
	@UpdatedBy VARCHAR(256)=NULL,
	@CreatedDate DATETIME2(7)=NULL,
	@UpdatedDate DATETIME2(7)=NULL,
	@IsActive BIT=NULL,
	@IsDeleted BIT=NULL,
	@IsWorkOrder BIT=NULL,
	@Result BIGINT OUTPUT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY 
		BEGIN TRANSACTION
		BEGIN
			IF (@CreditMemoHeaderId IS NULL OR @CreditMemoHeaderId=0)
			BEGIN 
				INSERT INTO [dbo].[CreditMemo]([CreditMemoNumber],[StatusId],[Status],
											   [CustomerId],[CustomerName],[CustomerCode],[CustomerContactId],[CustomerContact],[CustomerContactPhone],
											   [RequestedById],[RequestedBy],
											   [Notes],[ManagementStructureId],[IsEnforce],[MasterCompanyId],
                                               [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsWorkOrder],[IsStandAloneCM],[AcctingPeriodId])
										VALUES (@CreditMemoNumber,@StatusId,@Status,
												@CustomerId,@CustomerName,@CustomerCode,@CustomerContactId,@CustomerContact,@CustomerContactPhone,  
												@RequestedById,@RequestedBy,  
												@Notes,@ManagementStructureId,@IsEnforce,@MasterCompanyId,
												@CreatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),@IsActive,@IsDeleted,@IsWorkOrder,1,@AcctingPeriod);

				SELECT	@Result = IDENT_CURRENT('CreditMemo');

			END		
			ELSE
			BEGIN
				UPDATE [dbo].[CreditMemo] SET [StatusId]=@StatusId,
											  [Status] = @Status,
											  [RequestedById]=@RequestedById,
											  [Notes]=@Notes,[ManagementStructureId]=@ManagementStructureId,
											  [IsEnforce]=@IsEnforce,
											  [UpdatedBy]=@UpdatedBy,[UpdatedDate]=GETUTCDATE()
									    WHERE [CreditMemoHeaderId] = @CreditMemoHeaderId;
				SELECT	@Result = @CreditMemoHeaderId;

			END
		END
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CreateUpdateStandAloneCreditMemoHeader' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@CreditMemoHeaderId, '') AS varchar(100))
													+ '@Parameter2 = ''' + CAST(ISNULL(@CreditMemoNumber, '') AS varchar(100)) 
													+ '@Parameter3 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100)) 
													+ '@Parameter4 = ''' + CAST(ISNULL(@Status, '') AS varchar(100)) 
													+ '@Parameter5 = ''' + CAST(ISNULL(@CustomerId, '') AS varchar(100)) 
													+ '@Parameter6 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) 
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END